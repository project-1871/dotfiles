#!/bin/bash
# show-cheatsheet-pdf.sh
#
# What this does:
# - Regenerates your Hyprland keybind cheat sheet as:
#     - ASCII text (for alignment/debugging)
#     - PDF (for easy reading / fullscreen viewing)
# - Then opens the PDF in a viewer:
#     - Prefers zathura if installed
#     - Falls back to evince
#     - Otherwise uses xdg-open (system default)
#
# Notes:
# - You mentioned making the PDF viewer fullscreen via window rules
#   (e.g., Hyprland window rules for Zathura/Evince).
#
# Dependencies / assumptions:
# - hypr-cheatgen.py exists and can run (calls hyprctl)
# - ReportLab must be installed for PDF generation

set -euo pipefail

# Ensure Hypr can find your scripts even if it doesn't inherit your shell PATH
export PATH="$HOME/.config/omarchy/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:$PATH"

# Output directory + files
CHEAT_DIR="$HOME/.config/omarchy/cheats"
TXT="$CHEAT_DIR/hypr-binds.txt"
PDF="$CHEAT_DIR/hypr-binds.pdf"

# Cheat sheet generator
CHEATGEN="$HOME/.config/omarchy/bin/hypr-cheatgen.py"

# Ensure output directory exists
mkdir -p "$CHEAT_DIR"

# Regenerate (always current)
"$CHEATGEN" --format ascii --width 80 --out "$TXT" \
  --pdf "$PDF" --pdf-font-size 15 --pdf-line-height 17

# Open viewer (we'll make it fullscreen via window rules)
if command -v zathura >/dev/null 2>&1; then
  exec zathura "$PDF"
elif command -v evince >/dev/null 2>&1; then
  exec evince "$PDF"
else
  exec xdg-open "$PDF"
fi
