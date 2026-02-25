#!/usr/bin/env bash
# hypr-startup-sound.sh
#
# What this does:
# - Ensures your Omarchy sound/state folders exist
# - Ensures a default "current sound theme" label exists (if not set yet)
# - Ensures startup.mp3 exists (seeds it from a fallback sound if needed)
# - Plays the startup sound (best effort) using the first available player:
#     mpv -> ffplay -> pw-play -> paplay

set -euo pipefail

# Where your sounds live
SOUND_DIR="$HOME/.config/omarchy/sounds"

# Where your customization state lives (stores "current_sound" label)
STATE_DIR="$HOME/.config/omarchy/state"
CURRENT_FILE="$STATE_DIR/current_sound"

# Preferred "active" startup sound (selected by your menu/sound picker)
SOUND_STARTUP="$SOUND_DIR/startup.mp3"

# Fallback sound (used if user hasn't selected anything yet)
FALLBACK_STARTUP="$SOUND_DIR/winxpstartup.mp3"

ensure_defaults() {
  # Ensure required directories exist
  mkdir -p "$SOUND_DIR" "$STATE_DIR"

  # If no theme has been selected yet, seed a default label
  if [[ ! -f "$CURRENT_FILE" ]]; then
    echo "Windows XP" > "$CURRENT_FILE"
  fi

  # If startup.mp3 doesn't exist yet, seed it from fallback (if available)
  if [[ ! -f "$SOUND_STARTUP" && -f "$FALLBACK_STARTUP" ]]; then
    cp -f "$FALLBACK_STARTUP" "$SOUND_STARTUP"
  fi
}

play_sound() {
  local f="$1"

  # Blocking play: the sound will play fully before the script exits.
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

# Prefer startup.mp3; fall back to theme fallback sound; otherwise do nothing
if [[ -f "$SOUND_STARTUP" ]]; then
  play_sound "$SOUND_STARTUP"
elif [[ -f "$FALLBACK_STARTUP" ]]; then
  play_sound "$FALLBACK_STARTUP"
fi
