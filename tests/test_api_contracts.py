
def test_health_api_response_contract(http_session, base_url):
    response = http_session.get(
        f"{base_url}/api/health",
        timeout=10
    )

    assert response.status_code == 200
    assert "application/json" in response.headers.get("Content-Type", "")

    data = response.json()

    assert data["status"] == "UP"
    assert data["application"] == "CAP-46 Backend"
    assert data["message"] == "Backend is running successfully"


def test_deployment_events_response_contract(http_session, base_url):
    response = http_session.get(
        f"{base_url}/api/deployment-events",
        timeout=10
    )

    assert response.status_code == 200

    events = response.json()

    assert isinstance(events, list)

    if events:
        event = events[0]

        expected_fields = {
            "id",
            "version",
            "status",
            "message",
            "createdAt"
        }

        assert expected_fields.issubset(event.keys())


def test_actuator_database_health_contract(http_session, base_url):
    response = http_session.get(
        f"{base_url}/actuator/health",
        timeout=10
    )

    assert response.status_code == 200

    data = response.json()

    assert data["status"] == "UP"
    assert data["components"]["db"]["status"] == "UP"
