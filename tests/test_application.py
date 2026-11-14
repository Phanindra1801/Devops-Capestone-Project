
import requests

BASE_URL = "http://localhost"
EXPECTED_CONFIG_MARKER = "candidate-v1"



def test_frontend_is_available(http_session, base_url):
    response = http_session.get(f"{base_url}/", timeout=10)

    assert response.status_code == 200
    assert "text/html" in response.headers.get("Content-Type", "")


def test_frontend_is_served_by_nginx(http_session, base_url):
    response = http_session.get(f"{base_url}/", timeout=10)

    assert response.headers.get("X-CAP46-Config") == "candidate-v1"


def test_backend_health_api(healthy_backend):
    assert healthy_backend["status"] == "UP"


def test_backend_info_api(http_session, base_url):
    response = http_session.get(f"{base_url}/api/info", timeout=10)

    assert response.status_code == 200
    assert isinstance(response.json(), dict)


def test_deployment_events_api(http_session, base_url):
    response = http_session.get(
        f"{base_url}/api/deployment-events",
        timeout=10
    )

    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_actuator_and_database_health(http_session, base_url):
    response = http_session.get(
        f"{base_url}/actuator/health",
        timeout=10
    )

    assert response.status_code == 200

    data = response.json()
    assert data["status"] == "UP"
    assert data["components"]["db"]["status"] == "UP"
