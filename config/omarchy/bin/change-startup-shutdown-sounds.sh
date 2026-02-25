#!/usr/bin/env bash
# change-startup-shutdown-sounds.sh
#
# What this does:
# - Lets you pick a "sound theme" (Windows 2000 / XP / Vista / 11) from a dmenu-style selector
# - Copies the selected theme's startup/shutdown MP3 files into:
#     - ~/.config/omarchy/sounds/startup.mp3
#     - ~/.config/omarchy/sounds/shutdown.mp3
# - Writes the selected theme name into:
#     - ~/.config/omarchy/state/current_sound
# - Shows a desktop notification + prints a summary in the terminal
#
# Dependencies / assumptions:
# - Requires `omarchy-launch-walker` (Omarchy's dmenu/launcher wrapper)
# - Assumes the MP3 files already exist in $SOUND_DIR

set -euo pipefail

# Where the sound files live
SOUND_DIR="$HOME/.config/omarchy/sounds"

# Where we store the selected theme name
STATE_DIR="$HOME/.config/omarchy/state"
CURRENT_FILE="$STATE_DIR/current_sound"

# Small helper for desktop notifications (silent fallback if notify-send isn't installed)
notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send "Omarchy Sounds" "$1" || true
}

# Ensure folders exist
mkdir -p "$SOUND_DIR" "$STATE_DIR"

# Menu options shown to the user
options='Windows 2000\nWindows XP\nWindows Vista\nWindows 11'

# Launch the picker (dmenu-style). If the user cancels, exit cleanly.
choice="$(printf '%s\n' "$options" | omarchy-launch-walker --dmenu --width 360 --minheight 1 --maxheight 300 -p "Sound theme…" 2>/dev/null || true)"
[[ -z "${choice:-}" || "$choice" == "CNCLD" ]] && exit 0

# Map theme choice -> the corresponding MP3 files in SOUND_DIR
case "$choice" in
  "Windows 2000")
    startup_src="$SOUND_DIR/win2000startup.mp3"
    shutdown_src="$SOUND_DIR/win2000shutdown.mp3"
    ;;
  "Windows XP")
    startup_src="$SOUND_DIR/winxpstartup.mp3"
    shutdown_src="$SOUND_DIR/winxpshutdown.mp3"
    ;;
  "Windows Vista")
    startup_src="$SOUND_DIR/winvistastartup.mp3"
    shutdown_src="$SOUND_DIR/winvistashutdown.mp3"
    ;;
  "Windows 11")
    startup_src="$SOUND_DIR/win11startup.mp3"
    shutdown_src="$SOUND_DIR/win11shutdown.mp3"
    ;;
  *)
    notify "Unknown selection: $choice"
    exit 1
    ;;
esac

# Validate the startup sound exists
if [[ ! -f "$startup_src" ]]; then
  notify "Missing file: $(basename "$startup_src")"
  echo "Missing: $startup_src" >&2
  exit 1
fi

# Validate the shutdown sound exists
if [[ ! -f "$shutdown_src" ]]; then
  notify "Missing file: $(basename "$shutdown_src")"
  echo "Missing: $shutdown_src" >&2
  exit 1
fi

# Copy the selected theme into the "active" sound filenames used by the other scripts
cp -f "$startup_src"  "$SOUND_DIR/startup.mp3"
cp -f "$shutdown_src" "$SOUND_DIR/shutdown.mp3"

# Record which theme is active
echo "$choice" > "$CURRENT_FILE"

# Notify + print a quick summary for the user
notify "Sound theme set to: $choice ✅"

echo "Sound theme set to: $choice ✅"
echo
echo "startup.mp3  <- $(basename "$startup_src")"
echo "shutdown.mp3 <- $(basename "$shutdown_src")"
echo
read -n 1 -r -s -p "Press any key to close…"
echo
