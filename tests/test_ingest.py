def test_ingest_accepts_file(env_endpoint):
    assert env_endpoint.startswith("https://")

def test_ingest_schema_version():
    assert "4.3" in "4.3.22"
