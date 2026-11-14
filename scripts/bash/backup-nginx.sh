
#!/usr/bin/env bash

set -euo pipefail

echo "======================================"
echo " CAP-46 Nginx Configuration Backup"
echo "======================================"

ACTIVE_CONFIG="nginx/active/nginx.conf"
BACKUP_DIR="nginx/backups"

# Verify active configuration exists.
if [[ ! -f "$ACTIVE_CONFIG" ]]; then
    echo "[ERROR] Active Nginx configuration not found."
    exit 1
fi

# Create backup directory if missing.
mkdir -p "$BACKUP_DIR"

# Generate timestamp.
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

BACKUP_FILE="$BACKUP_DIR/nginx.conf.$TIMESTAMP"

# Copy active configuration.
cp "$ACTIVE_CONFIG" "$BACKUP_FILE"

echo "[SUCCESS] Nginx configuration backed up."
echo "[INFO] Backup location: $BACKUP_FILE"

echo "======================================"
