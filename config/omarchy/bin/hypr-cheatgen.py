#!/usr/bin/env python3
# hypr-cheatgen.py
#
# What this does:
# - Pulls your current Hyprland keybinds via:
#     hyprctl binds -j
# - Converts Hyprland's bind JSON into a readable cheat sheet:
#     - ASCII (aligned, fits ~80 columns by default)
#     - Markdown table
# - Optionally renders the ASCII cheat sheet to a landscape PDF (via ReportLab)
#
# Why this is useful:
# - Your Hyprland config can be complex; this generates a "living" cheatsheet
#   from the binds Hypr is actually using right now.
#
# Dependencies / assumptions:
# - Requires `hyprctl` in PATH and Hyprland running
# - For PDF output: requires ReportLab (python-reportlab package on Arch)

import argparse
import json
import subprocess
import textwrap
from collections import defaultdict

# Hyprland modmask bits (from your output):
# 64=SUPER, 8=ALT, 4=CTRL, 1=SHIFT
MOD_BITS = [
    (64, "SUPER"),
    (8,  "ALT"),
    (4,  "CTRL"),
    (1,  "SHIFT"),
]

# Optional: common X11 keycode mapping (works on typical US layouts)
# If your hyprctl JSON includes "keycode", this makes numbers readable.
X11_KEYCODE_MAP = {
    10: "1", 11: "2", 12: "3", 13: "4", 14: "5", 15: "6", 16: "7", 17: "8", 18: "9", 19: "0",
    24: "Q", 25: "W", 26: "E", 27: "R", 28: "T", 29: "Y", 30: "U", 31: "I", 32: "O", 33: "P",
    38: "A", 39: "S", 40: "D", 41: "F", 42: "G", 43: "H", 44: "J", 45: "K", 46: "L",
    52: "Z", 53: "X", 54: "C", 55: "V", 56: "B", 57: "N", 58: "M",
    65: "SPACE", 36: "RETURN", 22: "BACKSPACE", 9: "ESCAPE", 23: "TAB",
    107: "PRINT", 119: "DELETE",
    # Add more if you want
}

def run(cmd: list[str]) -> str:
    # Run a command and return stdout as text
    return subprocess.check_output(cmd, text=True)

def decode_modmask(modmask) -> str:
    """
    Hypr returns either:
      - 'mod' as a string (sometimes)
      - or 'modmask' as a number (what you're seeing)
    We decode numeric modmasks into "SUPER + SHIFT + ..." style strings.
    """
    try:
        m = int(modmask)
    except Exception:
        return str(modmask).strip()

    names = [name for bit, name in MOD_BITS if (m & bit)]
    return " + ".join(names)

def key_from_bind(b: dict) -> str:
    """
    Hypr versions differ; try a few fields.
    Prefer printable key names, fall back to keycode/code when needed.
    """
    k = b.get("key")
    if k and str(k).strip():
        return str(k).strip()

    # Some builds include keycode
    kc = b.get("keycode")
    if kc is not None:
        try:
            kc_i = int(kc)
            return X11_KEYCODE_MAP.get(kc_i, f"code:{kc_i}")
        except Exception:
            pass

    # Fallback: sometimes "code" exists
    code = b.get("code")
    if code is not None:
        return f"code:{code}"

    return ""  # truly unknown

def friendly_action(b: dict) -> str:
    # Dispatcher + arg combined into a single friendly string
    disp = (b.get("dispatcher") or "").strip()
    arg  = (b.get("arg") or "").strip()
    return f"{disp} {arg}".strip()

def combo_string(b: dict) -> str:
    # Build a human-readable key combo string like:
    #   SUPER + SHIFT + Q
    mods = b.get("mod")
    if not mods:
        mods = b.get("modmask", "")
    mods_s = decode_modmask(mods) if mods != "" else ""
    key = key_from_bind(b)

    if mods_s and key:
        return f"{mods_s} + {key}"
    if mods_s and not key:
        return mods_s
    return key

def to_ascii_sections(binds: list[dict], width: int = 80) -> str:
    """
    Produce a strict, aligned, <=width ASCII cheat sheet:
      [SECTION]
      KEYS... (fixed column) | ACTION... (wrapped)
    """
    groups = defaultdict(list)
    for b in binds:
        disp = (b.get("dispatcher") or "unknown").strip()
        groups[disp].append((combo_string(b), friendly_action(b)))

    out = []
    for disp in sorted(groups.keys()):
        out.append(f"[{disp.upper()}]")
        rows = sorted(groups[disp], key=lambda x: (x[0], x[1]))

        # Tuned for 80 columns:
        # - key_w: fixed width for the keys column
        # - act_w: remaining width for action wrapping
        key_w = 26
        act_w = max(10, width - (key_w + 3))  # " | "

        for keys, action in rows:
            keys = (keys or "").strip()
            action = (action or "").strip()

            keys_lines = textwrap.wrap(keys, width=key_w) or [""]
            act_lines  = textwrap.wrap(action, width=act_w) or [""]

            n = max(len(keys_lines), len(act_lines))
            keys_lines += [""] * (n - len(keys_lines))
            act_lines  += [""] * (n - len(act_lines))

            for i in range(n):
                out.append(f"{keys_lines[i]:<{key_w}} | {act_lines[i]}")

        out.append("")  # blank line between sections

    return "\n".join(out).rstrip() + "\n"

def to_markdown(binds: list[dict]) -> str:
    # Markdown output groups binds by dispatcher and renders a table per section.
    groups = defaultdict(list)
    for b in binds:
        disp = (b.get("dispatcher") or "unknown").strip()
        groups[disp].append((combo_string(b), friendly_action(b)))

    md = ["# Hyprland Keybinds Cheat Sheet\n"]
    for disp in sorted(groups.keys()):
        md.append(f"## {disp}\n")
        md.append("| Keys | Action |")
        md.append("|---|---|")
        for keys, action in sorted(groups[disp], key=lambda x: (x[0], x[1])):
            md.append(f"| {keys} | {action} |")
        md.append("")
    return "\n".join(md)

def write_pdf_ascii(content: str, pdf_path: str, *, font_size: int = 10, line_h: int = 11):
    """
    Render ASCII content to a landscape PDF without LaTeX (ReportLab).
    Larger font looks nicer, but may push content onto more pages. That's OK.
    """
    try:
        import reportlab  # noqa: F401
    except ModuleNotFoundError:
        raise SystemExit("PDF generation needs ReportLab. Install: sudo pacman -S python-reportlab")

    from reportlab.pdfgen import canvas
    from reportlab.lib.pagesizes import letter, landscape
    from reportlab.lib.units import inch
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont

    # Monospace font for perfect alignment
    font = "Courier"
    try:
        pdfmetrics.registerFont(TTFont("DejaVuMono", "/usr/share/fonts/TTF/DejaVuSansMono.ttf"))
        font = "DejaVuMono"
    except Exception:
        # Courier fallback is fine
        pass

    pagesize = landscape(letter)
    c = canvas.Canvas(pdf_path, pagesize=pagesize)
    w, h = pagesize

    left = 0.5 * inch
    right = 0.5 * inch
    top = h - 0.5 * inch
    bottom = 0.5 * inch

    # If you want even larger text, bump font_size to 11 and line_h to 12.
    c.setFont(font, font_size)

    y = top
    for line in content.splitlines():
        if y < bottom:
            c.showPage()
            c.setFont(font, font_size)
            y = top
        # Avoid drawing outside page width (ReportLab won't wrap automatically)
        c.drawString(left, y, line)
        y -= line_h

    c.save()

def main():
    # CLI flags:
    # --format ascii|md
    # --width 80 (for ascii formatting)
    # --out <file> (otherwise prints to stdout)
    # --pdf <path> (ASCII only; uses reportlab)
    ap = argparse.ArgumentParser()
    ap.add_argument("--format", choices=["ascii", "md"], default="ascii")
    ap.add_argument("--width", type=int, default=80)
    ap.add_argument("--out", default=None, help="Write to a file instead of stdout")
    ap.add_argument("--pdf", default=None, help="Also generate a PDF to this path (ASCII only; uses reportlab)")
    ap.add_argument("--pdf-font-size", type=int, default=10, help="PDF font size (default 10)")
    ap.add_argument("--pdf-line-height", type=int, default=11, help="PDF line height (default 11)")
    args = ap.parse_args()

    # Pull binds from hyprctl as JSON
    binds = json.loads(run(["hyprctl", "binds", "-j"]))

    # Render desired output format
    if args.format == "ascii":
        content = to_ascii_sections(binds, width=args.width)
    else:
        content = to_markdown(binds)

    # Write to a file or stdout
    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(content)
    else:
        print(content, end="")

    # Optional PDF generation (best with ASCII output)
    if args.pdf:
        if args.format != "ascii":
            raise SystemExit("--pdf is intended for --format ascii (so alignment stays perfect).")
        write_pdf_ascii(
            content,
            args.pdf,
            font_size=args.pdf_font_size,
            line_h=args.pdf_line_height,
        )

if __name__ == "__main__":
    main()
