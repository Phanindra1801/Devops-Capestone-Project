
import subprocess
import time
import requests


def test_deployment_data_persists_after_backend_restart(
    http_session, base_url
):
    # Step 1: Capture existing deployment events.
    before_response = http_session.get(
        f"{base_url}/api/deployment-events",
        timeout=10
    )

    assert before_response.status_code == 200

    before_events = before_response.json()

    before_ids = {
        event["id"] for event in before_events
    }

    print(f"\nRecords before restart: {len(before_events)}")

    # Step 2: Restart only the Spring Boot backend.
    restart_result = subprocess.run(
        ["docker", "compose", "restart", "backend"],
        capture_output=True,
        text=True,
        timeout=60
    )

    assert restart_result.returncode == 0, restart_result.stderr

    # Step 3: Wait for backend recovery.
    deadline = time.time() + 120

    while time.time() < deadline:
        try:
            health = http_session.get(
                f"{base_url}/api/health",
                timeout=5
            )

            if (
                health.status_code == 200
                and health.json().get("status") == "UP"
            ):
                break

        except requests.RequestException:
            pass

        time.sleep(3)

    else:
        raise AssertionError(
            "Backend did not recover after restart."
        )

    # Step 4: Fetch deployment events again.
    after_response = http_session.get(
        f"{base_url}/api/deployment-events",
        timeout=10
    )

    assert after_response.status_code == 200

    after_events = after_response.json()

    after_ids = {
        event["id"] for event in after_events
    }

    print(f"Records after restart: {len(after_events)}")

    # Step 5: Verify existing database records survived.
    assert before_ids.issubset(after_ids)

    print("Deployment data successfully persisted.")
