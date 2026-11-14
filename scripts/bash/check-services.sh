
#!/usr/bin/env bash

set -euo pipefail

echo "======================================"
echo " CAP-46 Docker Service Verification"
echo "======================================"

# Verify Docker Engine.
if ! docker info >/dev/null 2>&1; then
    echo "[ERROR] Docker Engine is unavailable."
    exit 1
fi

# Verify Compose configuration.
echo "[INFO] Validating Docker Compose configuration..."

docker compose config -q

echo "[OK] Compose configuration is valid."

# Required services.
REQUIRED_SERVICES=(
    mysql
    backend
    nginx
)

FAILED=0

for service in "${REQUIRED_SERVICES[@]}"; do

    STATUS=$(docker compose ps --format json "$service" |
        python3 -c '
import json
import sys

data = sys.stdin.read().strip()

if not data:
    print("NOT_FOUND")
else:
    containers = json.loads(data)
    if isinstance(containers, dict):
        containers = [containers]
    print(containers[0].get("State", "UNKNOWN"))
')

    HEALTH=$(docker inspect \
        --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' \
        "$(docker compose ps -q "$service")" 2>/dev/null || echo "unknown")

    echo ""
    echo "Service: $service"
    echo "State:   $STATUS"
    echo "Health:  $HEALTH"

    if [[ "$STATUS" != "running" ]]; then
        echo "[ERROR] $service is not running."
        FAILED=1
    elif [[ "$service" == "mysql" && "$HEALTH" != "healthy" ]]; then
        echo "[ERROR] MySQL is not healthy."
        FAILED=1
    else
        echo "[OK] $service is running."
    fi

done

echo ""
echo "======================================"

if [[ "$FAILED" -eq 0 ]]; then
    echo "All required services are running."
else
    echo "One or more services failed verification."
    exit 1
fi

echo "======================================"
