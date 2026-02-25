#!/usr/bin/env bash
# nas-unmount-all.sh
#
# Unmounts all CIFS/SMB mounts under /mnt

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; }

echo "Finding mounted CIFS shares..."

# Find all CIFS mounts
mapfile -t mounts < <(mount | grep -E 'type cifs|type smb' | awk '{print $3}')

if [[ ${#mounts[@]} -eq 0 ]]; then
  warn "No CIFS/SMB mounts found"
  echo
  read -n 1 -r -s -p "Press any key to exit..."
  exit 0
fi

echo "Found ${#mounts[@]} mount(s):"
printf '  %s\n' "${mounts[@]}"
echo

unmounted=0
for mount_point in "${mounts[@]}"; do
  echo "Unmounting $mount_point..."
  if sudo umount "$mount_point" 2>/dev/null; then
    info "Unmounted $mount_point"
    ((unmounted++))
  else
    # Try lazy unmount if regular fails
    if sudo umount -l "$mount_point" 2>/dev/null; then
      warn "Lazy unmounted $mount_point (was busy)"
      ((unmounted++))
    else
      error "Failed to unmount $mount_point"
    fi
  fi
done

echo
info "Unmounted $unmounted/${#mounts[@]} shares"
echo
read -n 1 -r -s -p "Press any key to exit..."
