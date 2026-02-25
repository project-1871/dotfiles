#!/usr/bin/env bash
# screensaver-long-mode.sh
#
# What this does:
# - Switches Hypridle to your "long" screensaver/idle configuration by:
#     1) Copying hypridle-long.conf -> hypridle.conf
#     2) Restarting hypridle (systemd user service if present; otherwise manual restart)
#     3) Writing the selected mode ("long") to Omarchy state:
#        ~/.config/omarchy/state/screensaver_mode
#
# Dependencies / assumptions:
# - Assumes Hyprland config lives in ~/.config/hypr
# - Assumes hypridle-long.conf exists
# - Uses `rg` (ripgrep) to detect whether hypridle.service exists as a user unit

set -euo pipefail

CFG_DIR="$HOME/.config/hypr"
SRC="$CFG_DIR/hypridle-long.conf"
DST="$CFG_DIR/hypridle.conf"

STATE_DIR="$HOME/.config/omarchy/state"
MODE_FILE="$STATE_DIR/screensaver_mode"

echo "=== Screensaver: LONG mode ==="
echo "[1/3] Source:      $SRC"
echo "[1/3] Destination: $DST"
echo

# Ensure the source config exists before attempting to copy
if [[ ! -f "$SRC" ]]; then
  echo "ERROR: missing $SRC"
  command -v notify-send >/dev/null 2>&1 && notify-send "Screensaver" "Missing: hypridle-long.conf" || true
  exit 1
fi

# Copy long config into place as the active hypridle.conf
cp -f "$SRC" "$DST"
echo "[2/3] Copied long config -> hypridle.conf"

# Restart hypridle:
# - Prefer systemd user service if present
# - Otherwise kill + relaunch manually
if systemctl --user list-unit-files 2>/dev/null | rg -q '^hypridle\.service'; then
  systemctl --user restart hypridle.service
  echo "[3/3] Restarted hypridle.service (user)"
else
  pkill -x hypridle 2>/dev/null || true
  nohup hypridle -c "$DST" >/dev/null 2>&1 &
  disown || true
  echo "[3/3] Restarted hypridle (manual)"
fi

# Record selected mode so your status script can display it
mkdir -p "$STATE_DIR"
echo "long" > "$MODE_FILE"

# Notify user
command -v notify-send >/dev/null 2>&1 && notify-send "Screensaver" "Long mode enabled ✅" || true
echo
read -n 1 -r -s -p "Press any key to close…"
echo
