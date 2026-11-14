
import pytest
import requests

BASE_URL = "http://localhost"


@pytest.fixture
def base_url():
    return BASE_URL


@pytest.fixture
def http_session():
    session = requests.Session()
    yield session
    session.close()


@pytest.fixture
def healthy_backend(http_session, base_url):
    response = http_session.get(
        f"{base_url}/api/health",
        timeout=10
    )

    if response.status_code != 200:
        pytest.skip("Backend is not healthy. Skipping this test.")

    return response.json()
