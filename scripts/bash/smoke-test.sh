
#!/usr/bin/env bash

set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost}"
TEMP_FILE=$(mktemp)

trap 'rm -f "$TEMP_FILE"' EXIT

PASS_COUNT=0
FAIL_COUNT=0

check_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="$3"

    echo "Checking: $name"

    local actual_status

    if ! actual_status=$(curl -sS \
        --max-time 10 \
        -o "$TEMP_FILE" \
        -w "%{http_code}" \
        "$url"); then
        echo "FAIL: $name - Connection error"
        ((FAIL_COUNT+=1))
        return
    fi

    if [[ "$actual_status" == "$expected_status" ]]; then
        echo "PASS: $name - HTTP $actual_status"
        ((PASS_COUNT+=1))
    else
        echo "FAIL: $name - Expected HTTP $expected_status, received $actual_status"
        ((FAIL_COUNT+=1))
    fi
}

echo "======================================"
echo "       CAP-46 SMOKE TEST"
echo "======================================"
echo "Base URL: $BASE_URL"
echo

check_endpoint "Nginx / Frontend" "$BASE_URL/" 200
check_endpoint "Backend Health API" "$BASE_URL/api/health" 200
check_endpoint "Application Info API" "$BASE_URL/api/info" 200
check_endpoint "Deployment Events API" "$BASE_URL/api/deployment-events" 200
check_endpoint "Spring Boot Actuator" "$BASE_URL/actuator/health" 200

echo
echo "======================================"
echo "             TEST SUMMARY"
echo "======================================"
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
echo "======================================"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
    echo "Smoke test FAILED."
    exit 1
fi

echo "Smoke test PASSED."
exit 0
