
#!/usr/bin/env bash

set -euo pipefail

echo "======================================"
echo " CAP-46 Nginx Configuration Rollback"
echo "======================================"

ACTIVE_CONFIG="nginx/active/nginx.conf"
BACKUP_DIR="nginx/backups"

# Verify backup directory.
if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "[ERROR] Backup directory does not exist."
    exit 1
fi

# Find the latest backup.
LATEST_BACKUP=$(
    find "$BACKUP_DIR" \
        -maxdepth 1 \
        -type f \
        -name 'nginx.conf.*' |
    sort |
    tail -n 1
)

if [[ -z "$LATEST_BACKUP" ]]; then
    echo "[ERROR] No Nginx backup found."
    exit 1
fi

echo "[INFO] Latest backup: $LATEST_BACKUP"

# Validate backup before restoring it.
echo "[INFO] Validating backup configuration..."

./scripts/bash/validate-nginx.sh "$LATEST_BACKUP"

# Restore the backup.
echo "[INFO] Restoring Nginx configuration..."

cp "$LATEST_BACKUP" "$ACTIVE_CONFIG"

# Validate restored active configuration.
echo "[INFO] Validating restored configuration..."

docker compose exec -T nginx nginx -t

# Gracefully reload Nginx.
echo "[INFO] Reloading Nginx..."

docker compose exec -T nginx nginx -s reload

echo ""
echo "[SUCCESS] Nginx rollback completed."
echo "[INFO] Restored from: $LATEST_BACKUP"

echo "======================================"
