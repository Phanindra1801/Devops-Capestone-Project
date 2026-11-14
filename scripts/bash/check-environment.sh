
#!/usr/bin/env bash

set -euo pipefail

echo "======================================"
echo " CAP-46 Environment Verification"
echo "======================================"

# Check required commands.
REQUIRED_COMMANDS=(
    docker
    git
    java
    python3
)

for command_name in "${REQUIRED_COMMANDS[@]}"; do
    if command -v "$command_name" >/dev/null 2>&1; then
        echo "[OK] $command_name is installed"
    else
        echo "[ERROR] $command_name is not installed"
        exit 1
    fi
done

# Check Docker Compose.
if docker compose version >/dev/null 2>&1; then
    echo "[OK] Docker Compose is available"
else
    echo "[ERROR] Docker Compose is unavailable"
    exit 1
fi

# Check required project files.
REQUIRED_FILES=(
    "docker-compose.yml"
    "nginx/active/nginx.conf"
    "backend/Dockerfile"
    "frontend/package.json"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo "[OK] Found $file"
    else
        echo "[ERROR] Missing $file"
        exit 1
    fi
done

# Check whether Docker Engine is accessible.
if docker info >/dev/null 2>&1; then
    echo "[OK] Docker Engine is accessible"
else
    echo "[ERROR] Docker Engine is not accessible"
    exit 1
fi

echo "======================================"
echo " Environment verification successful!"
echo "======================================"
