#!/usr/bin/env bash
# omarchy-menu-nas.sh
#
# What this does (high level):
# - Reads the upstream Omarchy menu script (the one shipped by Omarchy)
# - Patches it *in memory* to:
#     1) Add a new "Custom" entry to the main menu
#     2) Add routing so selecting Custom opens a new custom submenu
#     3) Inject show_custom_menu() (NAS mounts, VPN toggles, cheatsheets, etc.)
#     4) Wrap shutdown/reboot calls so your shutdown-sound wrapper runs first
# - Writes the patched result to a temp file and executes it
#
# Why this approach is nice:
# - You do NOT modify Omarchy's upstream script permanently
# - If Omarchy updates the menu, you can re-run this and re-patch on the fly
#
# SECURITY / PUBLISH NOTES:
# - This script contains *no passwords, tokens, or IP addresses*.
# - It DOES reveal some local paths (PIA path, Nautilus, your $HOME layout).
#   That's generally fine to publish. If you want it more generic, you *can*
#   mention in your blog that those paths may vary per system.

set -euo pipefail

# Upstream Omarchy menu script we will patch.
UPSTREAM="$HOME/.local/share/omarchy/bin/omarchy-menu"

# Temporary file where we write the patched copy of the upstream menu.
PATCHED="$(mktemp /tmp/omarchy-menu.patched.XXXXXX)"

# Desktop notification helper (silent fallback if notify-send isn't installed).
notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send "Omarchy Custom Menu" "$1" || true
}

# Hard fail if upstream menu cannot be read.
if [[ ! -r "$UPSTREAM" ]]; then
  notify "Can't read upstream menu: $UPSTREAM"
  exit 1
fi

# Patch the upstream menu using an embedded Python script.
# Arguments passed to Python:
#   $1 = upstream menu path
#   $2 = output path (PATCHED)
python3 - <<'PY' "$UPSTREAM" "$PATCHED"
import sys, re

src_path, out_path = sys.argv[1], sys.argv[2]
s = open(src_path, "r", encoding="utf-8").read()

# The label inserted into the Omarchy main menu.
# Note: requires Nerd Font support for the icon glyph to render nicely.
CUSTOM_LABEL = "󰠱  Custom"

# Wrapper script used to play shutdown sound before power actions.
ACTION = '"$HOME/.config/omarchy/bin/action-with-shutdown-sound.sh"'

# Menu action that lets you pick startup/shutdown sounds.
SOUND_PICKER = '"$HOME/.config/omarchy/bin/change-startup-shutdown-sounds.sh"'

# -----------------------------
# 1) Add Custom to main menu list (just above System)
# -----------------------------
# This regex finds the options text passed to the upstream "menu" call inside
# show_main_menu(). We then splice in CUSTOM_LABEL before "System".
main_menu_pat = r'(show_main_menu\(\)\s*\{\s*\n\s*go_to_menu "\$\(\s*menu "Go" "\s*)([^"]+)("\s*\)\s*"\s*\n\s*\}\s*)'
m = re.search(main_menu_pat, s, re.S)

# If upstream changed and the regex can't find what we expect:
# - write the original unmodified script out
# - exit cleanly (your wrapper will still run, but without custom menu)
if not m:
  open(out_path, "w", encoding="utf-8").write(s)
  sys.exit(0)

options = m.group(2)

# Only insert if Custom is not already present.
if ("Custom" not in options) and (CUSTOM_LABEL not in options):
  items = options.split("\\n")

  # Defensive cleanup: remove any existing Custom lines to avoid duplicates.
  items = [x for x in items if ("Custom" not in x and x != CUSTOM_LABEL)]

  # Find the first "System" entry and insert Custom just above it.
  sys_idx = None
  for i, it in enumerate(items):
    if "System" in it:
      sys_idx = i
      break

  # If "System" wasn't found, append Custom at the end.
  if sys_idx is None:
    items.append(CUSTOM_LABEL)
  else:
    items.insert(sys_idx, CUSTOM_LABEL)

  options = "\\n".join(items)

# Splice the updated options back into the upstream script text.
s = s[:m.start(2)] + options + s[m.end(2):]

# -----------------------------
# 2) Route in go_to_menu()
# -----------------------------
# Upstream routes menu selections like:
#   *trigger*) show_trigger_menu ;;
# We add:
#   *custom*) show_custom_menu ;;
if "show_custom_menu" not in s:
  if "*trigger*) show_trigger_menu ;;" in s:
    s = s.replace(
      "*trigger*) show_trigger_menu ;;",
      "*trigger*) show_trigger_menu ;;\n  *custom*) show_custom_menu ;;"
    )

# -----------------------------
# 3) Inject show_custom_menu()
# -----------------------------
# We locate "show_trigger_menu() {" and insert our custom menu function right
# after that function ends (after the next "}\n\n").
if "show_custom_menu()" not in s:
  inject_after = "show_trigger_menu() {"
  idx = s.find(inject_after)
  if idx != -1:
    insert_point = s.find("}\n\n", idx)
    if insert_point != -1:
      # This is the actual custom menu definition inserted into upstream.
      # It depends on upstream helper functions:
      # - menu
      # - present_terminal
      # - show_main_menu
      custom_fn = r'''

show_custom_menu() {
  case $(menu "Custom" "🗄  Mount NAS (smart)\n🧹  Unmount NAS\n📁  Open /mnt (choose mount)\n──────── VPN ────────\n🛡  PIA Connect\n🚫  PIA Disconnect\n🔒  PiVPN Connect\n🔓  PiVPN Disconnect\n────── Cheatsheets ──────\n📄  Show Binds (TXT)\n🖼  Show Binds (PDF)\n────── Screensaver ──────\n󰖨  Screensaver Stock Mode\n󰖨  Screensaver Long Mode\n────── Sounds ──────\n🎵  Change Startup/Shutdown Sounds\n──────── Status ────────\nℹ  Customization Status") in

    *"Mount NAS"*)
      present_terminal "$HOME/.config/omarchy/bin/nas-mount-smart.sh"
      ;;

    *"Unmount NAS"*)
      present_terminal "$HOME/.config/omarchy/bin/nas-unmount-all.sh"
      ;;

    *"Open /mnt"*)
      # Open file browser to /mnt (where mounts typically live).
      setsid nautilus /mnt >/dev/null 2>&1 &
      disown
      ;;

    *"PIA Connect"*)
      # Connect PIA VPN via piactl and show state, then wait for a keypress.
      present_terminal "bash -lc '/opt/piavpn/bin/piactl connect || true; /opt/piavpn/bin/piactl get connectionstate || true; echo; read -n 1 -r -s -p \"Press any key…\"'"
      ;;

    *"PIA Disconnect"*)
      present_terminal "bash -lc '/opt/piavpn/bin/piactl disconnect || true; /opt/piavpn/bin/piactl get connectionstate || true; echo; read -n 1 -r -s -p \"Press any key…\"'"
      ;;

    *"PiVPN Connect"*)
      # Your own local scripts (outside Omarchy).
      present_terminal "$HOME/.local/bin/pivpn-connect.sh"
      ;;

    *"PiVPN Disconnect"*)
      present_terminal "$HOME/.local/bin/pivpn-disconnect.sh"
      ;;

    *"Show Binds (TXT)"*)
      present_terminal "$HOME/.config/omarchy/bin/show-cheatsheet.sh --all"
      ;;

    *"Show Binds (PDF)"*)
      # PDF version runs in background (no terminal needed).
      bash -lc "$HOME/.config/omarchy/bin/show-cheatsheet-pdf.sh --all" >/dev/null 2>&1 &
      ;;

    *"Screensaver Stock Mode"*)
      present_terminal "$HOME/.config/omarchy/bin/screensaver-stock-mode.sh"
      ;;

    *"Screensaver Long Mode"*)
      present_terminal "$HOME/.config/omarchy/bin/screensaver-long-mode.sh"
      ;;

    *"Change Startup/Shutdown Sounds"*)
      # Launch sound picker script in a terminal.
      present_terminal ''' + SOUND_PICKER + r'''
      ;;

    *"Customization Status"*)
      present_terminal "$HOME/.config/omarchy/bin/vpn-nas-status.sh"
      ;;

    *"────"*|*"────────"*)
      # If user selects a divider line, just re-open the custom menu.
      show_custom_menu
      ;;

    *)
      # Anything else returns to the main menu.
      show_main_menu
      ;;
  esac
}
'''
      # Insert our function into upstream script text.
      s = s[:insert_point+3] + custom_fn + s[insert_point+3:]

# -----------------------------
# 4) Wrap Omarchy System menu shutdown/reboot tokens
# -----------------------------
# Omarchy uses tokens like "omarchy-cmd-shutdown" (not always literal commands).
# We replace those tokens so they go through your ACTION wrapper first.
def wrap_token(token: str, replacement: str):
  global s
  # Negative lookbehind tries to avoid double-wrapping.
  pat = rf'(?<!{re.escape("action-with-shutdown-sound.sh")} )\b{re.escape(token)}\b'
  s = re.sub(pat, replacement, s)

wrap_token("omarchy-cmd-shutdown", f"{ACTION} shutdown")
wrap_token("omarchy-cmd-reboot",   f"{ACTION} reboot")

# -----------------------------
# 5) Safety net: wrap any systemctl poweroff/reboot/halt
# -----------------------------
# If upstream ever directly calls systemctl poweroff/reboot/halt,
# we wrap it too: ACTION -- systemctl ...
def wrap_cmd(pattern, repl):
  global s
  s = re.sub(pattern, repl, s, flags=re.M)

wrap_cmd(
  rf'(^|[;&\(\)\n]\s*)(?!{re.escape(ACTION)}\s+--\s+)((?:/usr/bin/)?systemctl\b[^\n;&\)]*\b(?:poweroff|reboot|halt)\b[^\n;&\)]*)',
  rf'\1{ACTION} -- \2'
)

# Marker to confirm patch success (used by the bash wrapper below).
if "OMARCHY_CUSTOM_PATCH_MARKER" not in s and "show_custom_menu()" in s:
  s += "\n# OMARCHY_CUSTOM_PATCH_MARKER\n"

# Write patched script out.
open(out_path, "w", encoding="utf-8").write(s)
PY

# Ensure patched menu script is executable and then run it.
chmod +x "$PATCHED"

# Notify user whether our marker exists (basic success check).
if grep -q "OMARCHY_CUSTOM_PATCH_MARKER" "$PATCHED"; then
  notify "Custom menu patch applied ✅"
else
  notify "Patch didn't apply (upstream changed?) — running stock menu."
fi

# Execute patched menu, passing through any args
exec bash "$PATCHED" "$@"
