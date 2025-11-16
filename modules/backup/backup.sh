#!/bin/sh
set -e

# Cross-platform backup script for Unix-like systems (Linux, macOS, Git Bash on Windows)

PRIVATE_KEY_PATH="${PRIVATE_KEY_PATH:-${TF_VAR_privatekeypath}}"
USER="${USER:-${TF_VAR_user}}"
INSTANCE_IP="${INSTANCE_IP:-${TF_VAR_instance_ip}}"
BACKUP_PATH="${BACKUP_PATH:-${TF_VAR_backup_path}}"

if [ -z "$PRIVATE_KEY_PATH" ] || [ -z "$USER" ] || [ -z "$INSTANCE_IP" ] || [ -z "$BACKUP_PATH" ]; then
  echo "Error: Required environment variables not set"
  exit 1
fi

# Find ssh command
if ! command -v ssh >/dev/null 2>&1; then
  echo "Error: ssh command not found. Please install OpenSSH."
  exit 1
fi

echo "Using SSH: $(command -v ssh)"

# Resolve backup directory path
if [ ! -d "$BACKUP_PATH" ]; then
  mkdir -p "$BACKUP_PATH"
fi

if [ ! -d "$BACKUP_PATH" ]; then
  echo "Error: Failed to create backup directory: $BACKUP_PATH"
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
YEAR=$(date +%Y)
YEAR_DIR="$BACKUP_PATH/$YEAR"

echo "Backup directory: $BACKUP_PATH"
echo "Starting backup at $TIMESTAMP"

# Create year directory if it doesn't exist
if [ ! -d "$YEAR_DIR" ]; then
  mkdir -p "$YEAR_DIR"
fi

# Download files from server (one connection per file)
echo "Downloading wg0.conf from server..."
if ssh -i "$PRIVATE_KEY_PATH" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$USER@$INSTANCE_IP" "sudo cat /home/$USER/.amnezia-wg-easy/wg0.conf" > "$BACKUP_PATH/wg0.conf" 2>/dev/null; then
  echo "wg0.conf downloaded"
  # Create timestamped copy in year directory
  cp "$BACKUP_PATH/wg0.conf" "$YEAR_DIR/wg0.conf.backup.$TIMESTAMP"
  echo "wg0.conf backup with timestamp created in $YEAR_DIR"
else
  echo "Warning: Failed to download wg0.conf"
fi

echo "Downloading wg0.json from server..."
if ssh -i "$PRIVATE_KEY_PATH" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$USER@$INSTANCE_IP" "sudo cat /home/$USER/.amnezia-wg-easy/wg0.json" > "$BACKUP_PATH/wg0.json" 2>/dev/null; then
  echo "wg0.json downloaded"
  # Create timestamped copy in year directory
  cp "$BACKUP_PATH/wg0.json" "$YEAR_DIR/wg0.json.backup.$TIMESTAMP"
  echo "wg0.json backup with timestamp created in $YEAR_DIR"
else
  echo "Warning: Failed to download wg0.json"
fi

echo "Backup completed"

