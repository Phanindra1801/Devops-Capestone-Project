
#!/usr/bin/env bash

set -Eeuo pipefail

CANDIDATE_CONFIG="${1:-nginx/candidates/baseline.conf}"
ACTIVE_CONFIG="nginx/active/nginx.conf"
BACKUP_DIR="nginx/backups"

echo "======================================"
echo "      CAP-46 NGINX DEPLOYMENT"
echo "======================================"

# 1. Verify required services
echo
echo "[1/7] Checking application services..."

./scripts/bash/check-services.sh

# 2. Check candidate file
if [[ ! -f "$CANDIDATE_CONFIG" ]]; then
    echo "ERROR: Candidate configuration not found: $CANDIDATE_CONFIG"
    exit 1
fi

# 3. Validate candidate
echo
echo "[2/7] Validating candidate configuration..."

./scripts/bash/validate-nginx.sh "$CANDIDATE_CONFIG"

# 4. Create backup
echo
echo "[3/7] Backing up active configuration..."

mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/nginx.conf.$TIMESTAMP"

if [[ -e "$BACKUP_FILE" ]]; then
    BACKUP_FILE="${BACKUP_FILE}.$$"
fi

cp "$ACTIVE_CONFIG" "$BACKUP_FILE"

echo "Backup created: $BACKUP_FILE"

# Rollback function
rollback_deployment() {
    echo
    echo "DEPLOYMENT FAILED. Starting rollback..."

    cp "$BACKUP_FILE" "$ACTIVE_CONFIG"

    docker compose exec -T nginx nginx -t
    docker compose exec -T nginx nginx -s reload

    echo "Previous configuration restored."
}

# 5. Promote candidate
echo
echo "[4/7] Promoting candidate configuration..."

if ! cp "$CANDIDATE_CONFIG" "$ACTIVE_CONFIG"; then
    echo "ERROR: Could not promote candidate."
    exit 1
fi

# 6. Test and reload Nginx
echo
echo "[5/7] Testing active Nginx configuration..."

if ! docker compose exec -T nginx nginx -t; then
    rollback_deployment
    exit 1
fi

echo
echo "[6/7] Reloading Nginx..."

if ! docker compose exec -T nginx nginx -s reload; then
    rollback_deployment
    exit 1
fi

# 7. Smoke test
echo
echo "[7/7] Running smoke tests..."

if ! ./scripts/bash/smoke-test.sh; then
    rollback_deployment

    echo "Checking restored configuration..."

    if ./scripts/bash/smoke-test.sh; then
        echo "Rollback successful. Previous deployment is healthy."
    else
        echo "WARNING: Rollback completed, but smoke tests still fail."
    fi

    exit 1
fi

echo
echo "======================================"
echo "       DEPLOYMENT SUCCESSFUL"
echo "======================================"
echo "Active configuration: $ACTIVE_CONFIG"
echo "Backup configuration: $BACKUP_FILE"
