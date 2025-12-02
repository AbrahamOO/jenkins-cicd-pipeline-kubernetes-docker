"""
Comprehensive unit tests for FastAPI application
Demonstrates enterprise-grade testing practices
"""
import pytest
from fastapi.testclient import TestClient
from main import app, APP_VERSION, ENVIRONMENT
import time


# Create test client
client = TestClient(app)


class TestHealthEndpoints:
    """Test suite for health check endpoints"""

    def test_health_check_returns_200(self):
        """Test that health endpoint returns 200 status"""
        response = client.get("/health")
        assert response.status_code == 200

    def test_health_check_response_structure(self):
        """Test health check response contains required fields"""
        response = client.get("/health")
        data = response.json()

        assert "status" in data
        assert "timestamp" in data
        assert "uptime_seconds" in data
        assert "version" in data
        assert "environment" in data

    def test_health_check_status_healthy(self):
        """Test that health check returns healthy status"""
        response = client.get("/health")
        data = response.json()

        assert data["status"] == "healthy"
        assert data["version"] == APP_VERSION

    def test_readiness_probe(self):
        """Test readiness probe endpoint"""
        response = client.get("/ready")
        assert response.status_code == 200

        data = response.json()
        assert data["ready"] is True
        assert "timestamp" in data


class TestRootEndpoint:
    """Test suite for root endpoint"""

    def test_root_endpoint(self):
        """Test root endpoint returns welcome message"""
        response = client.get("/")
        assert response.status_code == 200

        data = response.json()
        assert "message" in data
        assert "version" in data
        assert data["version"] == APP_VERSION

    def test_root_contains_navigation(self):
        """Test root endpoint provides navigation links"""
        response = client.get("/")
        data = response.json()

        assert "docs" in data
        assert "health" in data


class TestMetricsEndpoint:
    """Test suite for metrics endpoint"""

    def test_metrics_endpoint_returns_200(self):
        """Test metrics endpoint is accessible"""
        response = client.get("/metrics")
        assert response.status_code == 200

    def test_metrics_format(self):
        """Test metrics endpoint returns Prometheus-compatible format"""
        response = client.get("/metrics")
        content = response.json()

        assert "app_uptime_seconds" in content
        assert "app_info" in content


class TestProcessEndpoint:
    """Test suite for message processing endpoint"""

    def test_process_message_success(self):
        """Test successful message processing"""
        payload = {"message": "hello world"}
        response = client.post("/api/process", json=payload)

        assert response.status_code == 200
        data = response.json()

        assert data["original"] == "hello world"
        assert data["processed"] == "HELLO WORLD"
        assert data["length"] == 11
        assert "timestamp" in data

    def test_process_empty_message(self):
        """Test processing empty message"""
        payload = {"message": ""}
        response = client.post("/api/process", json=payload)

        assert response.status_code == 200
        data = response.json()

        assert data["original"] == ""
        assert data["processed"] == ""
        assert data["length"] == 0

    def test_process_message_with_whitespace(self):
        """Test processing message with whitespace"""
        payload = {"message": "  test message  "}
        response = client.post("/api/process", json=payload)

        assert response.status_code == 200
        data = response.json()

        assert data["processed"] == "TEST MESSAGE"

    def test_process_invalid_payload(self):
        """Test processing with invalid payload"""
        response = client.post("/api/process", json={})
        assert response.status_code == 422  # Validation error


class TestAppInfoEndpoint:
    """Test suite for application info endpoint"""

    def test_app_info_endpoint(self):
        """Test app info endpoint returns configuration"""
        response = client.get("/api/info")
        assert response.status_code == 200

        data = response.json()
        assert "application" in data
        assert "version" in data
        assert "environment" in data
        assert "uptime_seconds" in data
        assert "endpoints" in data

    def test_app_info_endpoints_list(self):
        """Test app info includes endpoint list"""
        response = client.get("/api/info")
        data = response.json()

        endpoints = data["endpoints"]
        assert "health" in endpoints
        assert "ready" in endpoints
        assert "metrics" in endpoints
        assert "docs" in endpoints


class TestIntegration:
    """Integration tests for the application"""

    def test_full_workflow(self):
        """Test complete workflow from health check to processing"""
        # Check health
        health_response = client.get("/health")
        assert health_response.status_code == 200

        # Check readiness
        ready_response = client.get("/ready")
        assert ready_response.status_code == 200

        # Process message
        payload = {"message": "integration test"}
        process_response = client.post("/api/process", json=payload)
        assert process_response.status_code == 200
        assert process_response.json()["processed"] == "INTEGRATION TEST"

    def test_uptime_increases(self):
        """Test that uptime counter increases over time"""
        response1 = client.get("/health")
        uptime1 = response1.json()["uptime_seconds"]

        time.sleep(0.1)

        response2 = client.get("/health")
        uptime2 = response2.json()["uptime_seconds"]

        assert uptime2 > uptime1


# Pytest configuration
@pytest.fixture(scope="module")
def test_app():
    """Fixture to provide test application"""
    return client


def test_documentation_available():
    """Test that API documentation is accessible"""
    response = client.get("/docs")
    assert response.status_code == 200


def test_openapi_schema():
    """Test that OpenAPI schema is available"""
    response = client.get("/openapi.json")
    assert response.status_code == 200

    schema = response.json()
    assert "openapi" in schema
    assert "info" in schema
    assert "paths" in schema
