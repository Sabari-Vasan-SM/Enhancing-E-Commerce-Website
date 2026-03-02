"""
Main FastAPI application entry point.
Configures CORS, routes, WebSocket, and lifecycle events.
"""
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from app.core.config import settings
from app.core.database import init_db, close_db, get_db
from app.core.security import decode_access_token
from app.api import auth_router, products_router, behavior_router, orders_router
from app.websocket.manager import manager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifecycle: startup and shutdown."""
    logger.info("Starting application...")
    await init_db()
    logger.info("Database initialized")
    yield
    logger.info("Shutting down...")
    await close_db()
    logger.info("Database connections closed")


# Create app
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description=(
        "Dynamic E-Commerce API with Multi-UI Personalization. "
        "Classifies users based on behavior and provides personalized product recommendations."
    ),
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, use settings.ALLOWED_ORIGINS
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routers
app.include_router(auth_router, prefix=settings.API_PREFIX)
app.include_router(products_router, prefix=settings.API_PREFIX)
app.include_router(behavior_router, prefix=settings.API_PREFIX)
app.include_router(orders_router, prefix=settings.API_PREFIX)


# ==================== WEBSOCKET ENDPOINT ====================

@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: int, token: str = Query(None)):
    """
    WebSocket endpoint for real-time user type notifications.

    Usage from Flutter:
        ws://localhost:8000/ws/{user_id}?token={jwt_token}

    Events sent to client:
        - user_type_changed: When user classification changes
        - new_recommendations: When new product recommendations are available
    """
    # Validate token
    if token:
        try:
            payload = decode_access_token(token)
            token_user_id = int(payload.get("sub", 0))
            if token_user_id != user_id:
                await websocket.close(code=4001, reason="User ID mismatch")
                return
        except Exception:
            await websocket.close(code=4001, reason="Invalid token")
            return

    await manager.connect(websocket, user_id)
    try:
        while True:
            # Keep connection alive, handle incoming messages
            data = await websocket.receive_text()
            # Client can send ping/pong or request reclassification
            if data == "ping":
                await websocket.send_json({"event": "pong"})
            elif data == "request_type":
                # Client explicitly requests their current type
                from sqlalchemy import select
                from app.models.user import User
                from app.core.database import AsyncSessionLocal

                async with AsyncSessionLocal() as db:
                    result = await db.execute(select(User).where(User.id == user_id))
                    user = result.scalar_one_or_none()
                    if user:
                        await websocket.send_json({
                            "event": "user_type_update",
                            "data": {
                                "user_type": user.user_type.value,
                                "confidence": user.user_type_confidence,
                            },
                        })
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)
        logger.info(f"WebSocket disconnected for user {user_id}")


# ==================== HEALTH CHECK ====================

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
    }


@app.get("/")
async def root():
    """Root endpoint with API info."""
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "docs": "/docs",
        "health": "/health",
    }
