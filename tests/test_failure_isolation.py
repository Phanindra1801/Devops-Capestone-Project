
import subprocess
import time
import requests
import pytest

BASE_URL = "http://localhost"


@pytest.fixture
def backend_stopped():
    print("\nStopping Spring Boot backend...")

    stop_result = subprocess.run(
        ["docker", "compose", "stop", "backend"],
        capture_output=True,
        text=True,
        timeout=30
    )

    if stop_result.returncode != 0:
        pytest.fail(f"Could not stop backend: {stop_result.stderr}")

    try:
        # Wait until Nginx returns HTTP 503.
        deadline = time.time() + 45
        last_status = None
        last_error = None

        while time.time() < deadline:
            try:
                response = requests.get(
                    f"{BASE_URL}/api/health",
                    timeout=5
                )

                last_status = response.status_code

                if last_status == 503:
                    print("Nginx returned the expected HTTP 503.")
                    break

            except requests.RequestException as error:
                last_error = str(error)

            time.sleep(2)

        else:
            pytest.fail(
                "Backend did not become unavailable. "
                f"Last HTTP status: {last_status}. "
                f"Last connection error: {last_error}"
            )

        yield

    finally:
        print("\nRestarting Spring Boot backend...")

        start_result = subprocess.run(
            ["docker", "compose", "start", "backend"],
            capture_output=True,
            text=True,
            timeout=30
        )

        if start_result.returncode != 0:
            pytest.fail(
                f"Could not restart backend: {start_result.stderr}"
            )

        # Wait until backend recovers.
        deadline = time.time() + 120

        while time.time() < deadline:
            try:
                response = requests.get(
                    f"{BASE_URL}/api/health",
                    timeout=5
                )

                if (
                    response.status_code == 200
                    and response.json().get("status") == "UP"
                ):
                    print("Backend successfully recovered.")
                    break

            except requests.RequestException:
                pass

            time.sleep(3)

        else:
            pytest.fail("Backend did not recover within 120 seconds.")


def test_nginx_isolates_backend_failure(backend_stopped):

    # Frontend must remain available.
    frontend = requests.get(f"{BASE_URL}/", timeout=10)

    assert frontend.status_code == 200
    assert "text/html" in frontend.headers.get("Content-Type", "")

    # API must return controlled HTTP 503.
    api = requests.get(f"{BASE_URL}/api/health", timeout=10)

    assert api.status_code == 503

    data = api.json()

    assert data["status"] == "DOWN"
    assert data["message"] == (
        "Backend service is temporarily unavailable"
    )
