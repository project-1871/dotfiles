#!/bin/bash
# show-cheatsheet.sh
#
# What this does:
# - Ensures your Hyprland keybind cheat sheet files exist in:
#     ~/.config/omarchy/cheats/
# - Regenerates the ASCII cheat sheet (fast) every time this runs
# - If called with --all, also generates:
#     - Markdown version
#     - PDF version (bigger font for readability)
# - Opens the ASCII cheat sheet in Alacritty using `less -SR`:
#     - -S: don't wrap long lines (keeps columns aligned)
#     - -R: allow raw control characters (color/formatting if ever used)
#
# Dependencies / assumptions:
# - hypr-cheatgen.py exists and is executable
# - alacritty exists at /usr/bin/alacritty
# - hyprctl is available (hypr-cheatgen.py calls it)

set -euo pipefail

# Ensure Hypr can find your scripts even if it doesn't inherit your shell PATH
# (common with graphical launchers / compositor environments).
export PATH="$HOME/.config/omarchy/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:$PATH"

# Output directory + files
CHEAT_DIR="$HOME/.config/omarchy/cheats"
TXT="$CHEAT_DIR/hypr-binds.txt"
MD="$CHEAT_DIR/hypr-binds.md"
PDF="$CHEAT_DIR/hypr-binds.pdf"

# Cheat sheet generator (the Python script you wrote)
CHEATGEN="$HOME/.config/omarchy/bin/hypr-cheatgen.py"

# Terminal used to display the cheat sheet
TERM_BIN="/usr/bin/alacritty"

# Ensure output directory exists
mkdir -p "$CHEAT_DIR"

# --- sanity checks with visible feedback ---------------------------------

# Ensure generator exists and is executable
if [[ ! -x "$CHEATGEN" ]]; then
  notify-send "Cheat sheet" "hypr-cheatgen.py not executable: $CHEATGEN"
  exit 1
fi

# Ensure terminal exists
if [[ ! -x "$TERM_BIN" ]]; then
  notify-send "Cheat sheet" "Alacritty not found at $TERM_BIN"
  exit 1
fi

# --- generate cheat sheets -----------------------------------------------

# Always regenerate TXT (fast)
"$CHEATGEN" --format ascii --width 80 --out "$TXT"

# Optional: regenerate MD + PDF when asked
if [[ "${1:-}" == "--all" ]]; then
  "$CHEATGEN" --format md --out "$MD"
  "$CHEATGEN" --format ascii --width 80 --out "$TXT" \
    --pdf "$PDF" --pdf-font-size 15 --pdf-line-height 17
fi

# --- display --------------------------------------------------------------

# Open in terminal with less (no wrap, keep alignment)
# exec "$TERM_BIN" --title "Hypr Cheat Sheet" -e bash -lc "less -SR '$TXT'"
exec "$TERM_BIN" --class CheatSheet -e bash -lc "less -SR '$TXT'"
