#!/usr/bin/env bash
# action-with-shutdown-sound.sh
#
# What this does:
# - Ensures a default sound "theme" exists in ~/.config/omarchy/state/
# - Ensures shutdown.mp3 exists (seeds it from a fallback sound if needed)
# - Plays the shutdown sound *blocking* (so it completes before powering off)
# - Then performs the requested system action:
#     - shutdown -> systemctl poweroff
#     - reboot   -> systemctl reboot
#     - halt     -> systemctl halt
#   Or:
#     -- <command...> -> play sound, then exec the command

set -euo pipefail

# Where your sounds live
SOUND_DIR="$HOME/.config/omarchy/sounds"

# Where your customization state lives (stores "current_sound" label)
STATE_DIR="$HOME/.config/omarchy/state"
CURRENT_FILE="$STATE_DIR/current_sound"

# Preferred "active" shutdown sound (selected by your menu/sound picker)
SOUND_SHUTDOWN="$SOUND_DIR/shutdown.mp3"

# Fallback sound (used if user hasn't selected anything yet)
FALLBACK_SHUTDOWN="$SOUND_DIR/winxpshutdown.mp3"

ensure_defaults() {
  # Ensure required directories exist
  mkdir -p "$SOUND_DIR" "$STATE_DIR"

  # If no theme has been selected yet, seed a default label
  if [[ ! -f "$CURRENT_FILE" ]]; then
    echo "Windows XP" > "$CURRENT_FILE"
  fi

  # If shutdown.mp3 doesn't exist yet, seed it from fallback (if available)
  if [[ ! -f "$SOUND_SHUTDOWN" && -f "$FALLBACK_SHUTDOWN" ]]; then
    cp -f "$FALLBACK_SHUTDOWN" "$SOUND_SHUTDOWN"
  fi
}

play_sound() {
  local f="$1"

  # Blocking play (important): we want the sound to finish before shutdown.
  # Try several players in order, using the first one found.
  if command -v mpv >/dev/null 2>&1; then
    mpv --no-video --really-quiet --keep-open=no "$f" >/dev/null 2>&1 || true
  elif command -v ffplay >/dev/null 2>&1; then
    ffplay -nodisp -autoexit -loglevel quiet "$f" >/dev/null 2>&1 || true
  elif command -v pw-play >/dev/null 2>&1; then
    pw-play "$f" >/dev/null 2>&1 || true
  elif command -v paplay >/dev/null 2>&1; then
    paplay "$f" >/dev/null 2>&1 || true
  fi
}

# Ensure default files/dirs are present before we proceed
ensure_defaults

# Choose which shutdown sound to play:
# - Prefer shutdown.mp3 if present
# - Otherwise fall back to the theme fallback sound
# - Otherwise play nothing
SOUND_TO_PLAY=""
if [[ -f "$SOUND_SHUTDOWN" ]]; then
  SOUND_TO_PLAY="$SOUND_SHUTDOWN"
elif [[ -f "$FALLBACK_SHUTDOWN" ]]; then
  SOUND_TO_PLAY="$FALLBACK_SHUTDOWN"
fi

case "${1-}" in
  shutdown)
    [[ -n "$SOUND_TO_PLAY" ]] && play_sound "$SOUND_TO_PLAY"
    exec systemctl poweroff
    ;;
  reboot)
    [[ -n "$SOUND_TO_PLAY" ]] && play_sound "$SOUND_TO_PLAY"
    exec systemctl reboot
    ;;
  halt)
    [[ -n "$SOUND_TO_PLAY" ]] && play_sound "$SOUND_TO_PLAY"
    exec systemctl halt
    ;;
  --)
    # Generic wrapper mode:
    #   action-with-shutdown-sound.sh -- <command ...>
    # Plays the sound, then execs whatever command you pass.
    shift
    [[ -n "$SOUND_TO_PLAY" ]] && play_sound "$SOUND_TO_PLAY"
    exec "$@"
    ;;
  *)
    echo "Usage: $0 {shutdown|reboot|halt|-- <command...>}" >&2
    exit 2
    ;;
esac
