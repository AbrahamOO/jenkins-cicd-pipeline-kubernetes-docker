"""
FastAPI Microservice for CI/CD Pipeline Demo
Production-grade health check and metrics endpoints
"""
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Dict, Any
import logging
import os
import time
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="DevOps Pipeline Demo API",
    description="Enterprise-grade microservice for CI/CD demonstration",
    version="1.0.0"
)

# Application metadata
APP_START_TIME = time.time()
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")


class HealthResponse(BaseModel):
    """Health check response model"""
    status: str
    timestamp: str
    uptime_seconds: float
    version: str
    environment: str


class MessageRequest(BaseModel):
    """Request model for message processing"""
    message: str


class MessageResponse(BaseModel):
    """Response model for message processing"""
    original: str
    processed: str
    length: int
    timestamp: str


@app.on_event("startup")
async def startup_event():
    """Application startup event handler"""
    logger.info(f"🚀 Starting {app.title} v{APP_VERSION}")
    logger.info(f"📍 Environment: {ENVIRONMENT}")
    logger.info("✅ Application started successfully")


@app.on_event("shutdown")
async def shutdown_event():
    """Application shutdown event handler"""
    logger.info("🛑 Shutting down application")


@app.get("/", response_model=Dict[str, str])
async def root():
    """Root endpoint with welcome message"""
    return {
        "message": "Welcome to DevOps Pipeline Demo API",
        "version": APP_VERSION,
        "docs": "/docs",
        "health": "/health"
    }


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """
    Health check endpoint for Kubernetes liveness/readiness probes
    Returns application status and uptime
    """
    uptime = time.time() - APP_START_TIME

    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow().isoformat(),
        uptime_seconds=round(uptime, 2),
        version=APP_VERSION,
        environment=ENVIRONMENT
    )


@app.get("/ready")
async def readiness_check():
    """
    Readiness probe endpoint for Kubernetes
    Checks if the application is ready to serve traffic
    """
    # In a real application, check database connections, cache availability, etc.
    try:
        # Simulate dependency checks
        return JSONResponse(
            status_code=200,
            content={
                "ready": True,
                "timestamp": datetime.utcnow().isoformat()
            }
        )
    except Exception as e:
        logger.error(f"Readiness check failed: {str(e)}")
        raise HTTPException(status_code=503, detail="Service not ready")


@app.get("/metrics")
async def metrics():
    """
    Basic metrics endpoint (Prometheus-compatible format)
    In production, use prometheus_client library
    """
    uptime = time.time() - APP_START_TIME

    metrics_output = f"""# HELP app_uptime_seconds Application uptime in seconds
# TYPE app_uptime_seconds gauge
app_uptime_seconds {uptime}

# HELP app_info Application information
# TYPE app_info gauge
app_info{{version="{APP_VERSION}",environment="{ENVIRONMENT}"}} 1
"""
    return JSONResponse(
        content=metrics_output,
        media_type="text/plain"
    )


@app.post("/api/process", response_model=MessageResponse)
async def process_message(request: MessageRequest):
    """
    Process a message and return transformed result
    Demonstrates business logic endpoint
    """
    try:
        original_message = request.message
        processed_message = original_message.upper().strip()

        logger.info(f"Processed message: {original_message} -> {processed_message}")

        return MessageResponse(
            original=original_message,
            processed=processed_message,
            length=len(processed_message),
            timestamp=datetime.utcnow().isoformat()
        )
    except Exception as e:
        logger.error(f"Error processing message: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@app.get("/api/info")
async def app_info():
    """Get application information and configuration"""
    return {
        "application": app.title,
        "version": APP_VERSION,
        "environment": ENVIRONMENT,
        "uptime_seconds": round(time.time() - APP_START_TIME, 2),
        "python_version": os.sys.version,
        "endpoints": {
            "health": "/health",
            "ready": "/ready",
            "metrics": "/metrics",
            "docs": "/docs",
            "process": "/api/process"
        }
    }


if __name__ == "__main__":
    import uvicorn

    # Run the application
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        log_level="info",
        access_log=True
    )
