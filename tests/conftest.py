import os
import pytest

@pytest.fixture
def env_endpoint():
    return os.environ.get("ENV_ENDPOINT", "https://intt-local.steelthread.example")
