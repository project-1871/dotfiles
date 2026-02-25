#!/usr/bin/env bash
# nas-mount-smart.sh
#
# Smart NAS mounting script - detects available shares and mounts them.
# Customize NAS_HOST and SHARES array for your setup.

set -euo pipefail

# ─────────────────────────────────────────────────────────────
# CONFIGURATION - Edit these for your NAS
# ─────────────────────────────────────────────────────────────
NAS_HOST="nas.local"                    # Hostname or IP of your NAS
NAS_USER="${NAS_USER:-$(whoami)}"       # Username (defaults to current user)
MOUNT_BASE="/mnt"                       # Where to mount shares

# Shares to mount: "share_name:mount_point"
SHARES=(
  "media:media"
  "backups:backups"
  "documents:documents"
)

# Credentials file (optional, more secure than inline password)
# Create with: echo "password=yourpassword" > ~/.config/omarchy/.nas-credentials && chmod 600 ~/.config/omarchy/.nas-credentials
CREDENTIALS_FILE="$HOME/.config/omarchy/.nas-credentials"

# ─────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; }

# Check if NAS is reachable
echo "Checking if NAS ($NAS_HOST) is reachable..."
if ! ping -c 1 -W 2 "$NAS_HOST" &>/dev/null; then
  error "Cannot reach NAS at $NAS_HOST"
  echo
  read -n 1 -r -s -p "Press any key to exit..."
  exit 1
fi
info "NAS is reachable"

# Build mount options
MOUNT_OPTS="uid=$(id -u),gid=$(id -g),file_mode=0644,dir_mode=0755"
if [[ -f "$CREDENTIALS_FILE" ]]; then
  MOUNT_OPTS="credentials=$CREDENTIALS_FILE,$MOUNT_OPTS"
else
  warn "No credentials file found at $CREDENTIALS_FILE"
  echo "You may be prompted for password, or create the file with:"
  echo "  echo 'username=$NAS_USER' > $CREDENTIALS_FILE"
  echo "  echo 'password=yourpassword' >> $CREDENTIALS_FILE"
  echo "  chmod 600 $CREDENTIALS_FILE"
  echo
  MOUNT_OPTS="username=$NAS_USER,$MOUNT_OPTS"
fi

# Mount each share
mounted=0
for entry in "${SHARES[@]}"; do
  share="${entry%%:*}"
  mount_name="${entry##*:}"
  mount_point="$MOUNT_BASE/$mount_name"

  # Skip if already mounted
  if mountpoint -q "$mount_point" 2>/dev/null; then
    info "$mount_point already mounted"
    ((mounted++))
    continue
  fi

  # Create mount point if needed
  if [[ ! -d "$mount_point" ]]; then
    echo "Creating mount point: $mount_point"
    sudo mkdir -p "$mount_point"
  fi

  echo "Mounting //$NAS_HOST/$share -> $mount_point"
  if sudo mount -t cifs "//$NAS_HOST/$share" "$mount_point" -o "$MOUNT_OPTS" 2>/dev/null; then
    info "Mounted $share"
    ((mounted++))
  else
    error "Failed to mount $share"
  fi
done

echo
info "Mounted $mounted/${#SHARES[@]} shares"
echo
read -n 1 -r -s -p "Press any key to exit..."
