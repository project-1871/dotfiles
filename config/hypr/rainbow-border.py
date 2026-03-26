#!/usr/bin/env python3
# Continuously cycles rainbow colors on the Hyprland active window border.
# Speed: full rainbow cycle takes ~20 seconds. Adjust STEP and SLEEP to taste.

import subprocess
import time

STEP = 1        # degrees to advance per frame (smaller = smoother/slower)
SLEEP = 0.05    # seconds between frames
NUM_STOPS = 6   # color stops in the gradient
SPREAD = 360 // NUM_STOPS


def hsv_to_rgb(h):
    h = h % 360
    s, v = 1.0, 1.0
    c = v * s
    x = c * (1 - abs((h / 60) % 2 - 1))
    m = v - c
    if   h < 60:  r, g, b = c, x, 0
    elif h < 120: r, g, b = x, c, 0
    elif h < 180: r, g, b = 0, c, x
    elif h < 240: r, g, b = 0, x, c
    elif h < 300: r, g, b = x, 0, c
    else:         r, g, b = c, 0, x
    return int((r + m) * 255), int((g + m) * 255), int((b + m) * 255)


hue = 0
while True:
    stops = []
    for i in range(NUM_STOPS):
        r, g, b = hsv_to_rgb(hue + i * SPREAD)
        stops.append(f"rgba({r:02x}{g:02x}{b:02x}ff)")
    color_str = " ".join(stops) + " 45deg"
    subprocess.run(
        ["hyprctl", "keyword", "general:col.active_border", color_str],
        capture_output=True
    )
    hue = (hue + STEP) % 360
    time.sleep(SLEEP)
