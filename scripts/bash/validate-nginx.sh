
#!/usr/bin/env bash

set -euo pipefail

echo "======================================"
echo " CAP-46 Nginx Configuration Validation"
echo "======================================"

CANDIDATE_CONFIG="${1:-nginx/candidates/baseline.conf}"

if [[ ! -f "$CANDIDATE_CONFIG" ]]; then
    echo "[ERROR] Candidate configuration not found:"
    echo "$CANDIDATE_CONFIG"
    exit 1
fi

echo "[INFO] Candidate: $CANDIDATE_CONFIG"

# Find the running Nginx container.
NGINX_CONTAINER=$(docker compose ps -q nginx)

if [[ -z "$NGINX_CONTAINER" ]]; then
    echo "[ERROR] Nginx container is not running."
    exit 1
fi

# Identify the Nginx image.
NGINX_IMAGE=$(docker inspect \
    --format='{{.Config.Image}}' "$NGINX_CONTAINER")

# Identify the Docker network used by Nginx.
DOCKER_NETWORK=$(docker inspect \
    --format='{{range $name, $config := .NetworkSettings.Networks}}{{$name}}{{end}}' \
    "$NGINX_CONTAINER")

if [[ -z "$DOCKER_NETWORK" ]]; then
    echo "[ERROR] Could not identify Nginx Docker network."
    exit 1
fi

echo "[INFO] Nginx image: $NGINX_IMAGE"
echo "[INFO] Docker network: $DOCKER_NETWORK"

echo "[INFO] Testing candidate configuration..."

if docker run --rm \
    --network "$DOCKER_NETWORK" \
    -v "$(pwd)/$CANDIDATE_CONFIG:/etc/nginx/nginx.conf:ro" \
    "$NGINX_IMAGE" nginx -t; then

    echo ""
    echo "[SUCCESS] Nginx configuration is valid."

else
    echo ""
    echo "[ERROR] Nginx configuration validation failed."
    exit 1
fi

echo "======================================"
