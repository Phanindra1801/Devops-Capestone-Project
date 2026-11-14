
#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

while true; do
    echo
    echo "=========================================="
    echo "       CAP-46 OPERATIONS MENU"
    echo "=========================================="
    echo "1. Check development environment"
    echo "2. Check Docker services"
    echo "3. Validate Nginx configuration"
    echo "4. Backup active Nginx configuration"
    echo "5. Rollback Nginx configuration"
    echo "6. Run application smoke tests"
    echo "7. Deploy Nginx configuration"
    echo "8. View Docker service status"
    echo "9. View active Nginx configuration"
    echo "0. Exit"
    echo "=========================================="

    read -rp "Select an option: " choice

    case "$choice" in
        1)
            ./scripts/bash/check-environment.sh
            ;;
        2)
            ./scripts/bash/check-services.sh
            ;;
        3)
            read -rp "Candidate path [nginx/candidates/baseline.conf]: " candidate
            candidate="${candidate:-nginx/candidates/baseline.conf}"
            ./scripts/bash/validate-nginx.sh "$candidate"
            ;;
        4)
            ./scripts/bash/backup-nginx.sh
            ;;
        5)
            ./scripts/bash/rollback-nginx.sh
            ;;
        6)
            ./scripts/bash/smoke-test.sh
            ;;
        7)
            read -rp "Candidate path [nginx/candidates/baseline.conf]: " candidate
            candidate="${candidate:-nginx/candidates/baseline.conf}"
            ./scripts/bash/deploy-nginx.sh "$candidate"
            ;;
        8)
            docker compose ps
            ;;
        9)
            cat nginx/active/nginx.conf
            ;;
        0)
            echo "Exiting CAP-46 Operations Menu."
            exit 0
            ;;
        *)
            echo "Invalid option. Please select a valid option."
            ;;
    esac

    echo
    read -rp "Press Enter to return to the menu..."
done
