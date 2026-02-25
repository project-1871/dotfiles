#!/usr/bin/env bash
# vpn-nas-status.sh
#
# What this does:
# - Shows a quick "Customization Status" dashboard in the terminal:
#     - Current sound theme + whether startup/shutdown MP3 files exist
#     - Current screensaver mode (stock vs long)
#     - PIA VPN connection state (via piactl)
#     - PiVPN service active/inactive (systemd)
#     - NAS reachability (ping)
#     - Whether key mountpoints are mounted (using /proc/self/mountinfo — safe even if NFS is dead)
#
# Publish note:
# - NAS IP and mountpoint paths are obfuscated for privacy.

set -euo pipefail

# PIA's CLI (path may vary per system; not a secret)
PIACTL="/opt/piavpn/bin/piactl"

# PiVPN systemd service unit name (not a secret)
PIVPN_SERVICE="openvpn-client@pivpn"

# PRIVATE: NAS IP on your LAN (obfuscated for publishing)
NAS_IP="NAS_IP_HERE"

# PRIVATE: mount paths obfuscated for publishing
MOUNTS=(
  "/mnt/mount_point_1"
  "/mnt/mount_point_2"
  "/mnt/mount_point_3"
  "/mnt/mount_point_4"
)

# Omarchy customization state + sound assets
SOUND_DIR="$HOME/.config/omarchy/sounds"
STATE_DIR="$HOME/.config/omarchy/state"
MODE_FILE="$STATE_DIR/screensaver_mode"
CURRENT_SOUND_FILE="$STATE_DIR/current_sound"
STARTUP_MP3="$SOUND_DIR/startup.mp3"
SHUTDOWN_MP3="$SOUND_DIR/shutdown.mp3"

# Allow Ctrl+C to exit cleanly without an ugly stack of errors
trap 'echo; echo "[status] interrupted"; exit 0' INT TERM

is_mounted_mountinfo() {
  # Check mounted status by reading /proc/self/mountinfo
  # (safe even if a network mount is unresponsive)
  local target="$1"
  awk -v t="$target" '$5==t {found=1} END{exit(found?0:1)}' /proc/self/mountinfo
}

mounted_source_mountinfo() {
  # If mounted, extract filesystem type + source from /proc/self/mountinfo
  # Output example: "nfs4 10.0.0.118:/mnt/pool/share"
  local target="$1"
  awk -v t="$target" '
    $5==t {
      for (i=1; i<=NF; i++) if ($i=="-") {dash=i; break}
      fstype=$(dash+1); source=$(dash+2);
      printf("%s %s", fstype, source);
      exit 0
    }
    END { exit 1 }
  ' /proc/self/mountinfo
}

current_sound() {
  # Stored by your sound picker script (if set)
  if [[ -f "$CURRENT_SOUND_FILE" ]]; then
    head -n 1 "$CURRENT_SOUND_FILE" | tr -d '\r'
  else
    echo "Unknown (not set)"
  fi
}

screensaver_mode() {
  # Stored by your screensaver mode scripts (if set)
  if [[ -f "$MODE_FILE" ]]; then
    m="$(head -n 1 "$MODE_FILE" | tr -d '\r')"
    case "$m" in
      stock) echo "Stock" ;;
      long)  echo "Long" ;;
      *)     echo "Unknown ($m)" ;;
    esac
  else
    echo "Unknown (not set)"
  fi
}

echo "=== CUSTOMIZATION STATUS ==="
echo

echo "Sounds:"
echo "  Theme: $(current_sound)"
echo "  Startup Sound:  $([[ -f "$STARTUP_MP3" ]] && echo "present ✅" || echo "missing ❌")"
echo "  Shutdown Sound: $([[ -f "$SHUTDOWN_MP3" ]] && echo "present ✅" || echo "missing ❌")"
echo

echo "Screensaver:"
echo "  Mode: $(screensaver_mode)"
echo

echo "PIA:"
if [[ -x "$PIACTL" ]]; then
  # Print PIA connection state (ignore failures)
  "$PIACTL" get connectionstate 2>/dev/null || true
else
  echo "piactl not found at $PIACTL"
fi
echo

echo "PiVPN ($PIVPN_SERVICE):"
systemctl is-active --quiet "$PIVPN_SERVICE" && echo "active ✅" || echo "inactive ❌"
echo

echo "NAS reachability ($NAS_IP):"
if ping -c 1 -W 1 "$NAS_IP" >/dev/null 2>&1; then
  echo "reachable ✅"
else
  echo "not reachable ❌"
fi
echo

echo "Mountpoints (from /proc/self/mountinfo — safe even if NFS is dead):"
for m in "${MOUNTS[@]}"; do
  if is_mounted_mountinfo "$m"; then
    src="$(mounted_source_mountinfo "$m" || true)"
    [[ -n "$src" ]] && echo "✅ $m   ($src)" || echo "✅ $m"
  else
    echo "❌ $m"
  fi
done

echo
read -n 1 -r -s -p "Press any key to close…"
echo
