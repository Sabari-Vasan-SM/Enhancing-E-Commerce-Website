"""
WebSocket manager for real-time user type updates.
When the user's classification changes, the frontend is notified instantly.
"""
from fastapi import WebSocket, WebSocketDisconnect
from typing import Dict, List
import json
import logging

logger = logging.getLogger(__name__)


class ConnectionManager:
    """
    Manages WebSocket connections per user.
    Supports multiple connections per user (e.g., multiple tabs/devices).
    """

    def __init__(self):
        # user_id -> list of active WebSocket connections
        self.active_connections: Dict[int, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, user_id: int):
        """Accept and register a new WebSocket connection."""
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)
        logger.info(f"WebSocket connected: user {user_id} (total: {len(self.active_connections[user_id])})")

    def disconnect(self, websocket: WebSocket, user_id: int):
        """Remove a WebSocket connection."""
        if user_id in self.active_connections:
            self.active_connections[user_id] = [
                ws for ws in self.active_connections[user_id] if ws != websocket
            ]
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
        logger.info(f"WebSocket disconnected: user {user_id}")

    async def send_personal_message(self, message: dict, user_id: int):
        """Send a message to all connections of a specific user."""
        if user_id in self.active_connections:
            disconnected = []
            for ws in self.active_connections[user_id]:
                try:
                    await ws.send_json(message)
                except Exception:
                    disconnected.append(ws)

            # Clean up disconnected
            for ws in disconnected:
                self.active_connections[user_id].remove(ws)

    async def notify_user_type_change(
        self, user_id: int, new_type: str, confidence: float, scores: dict
    ):
        """Notify user about their type classification change."""
        message = {
            "event": "user_type_changed",
            "data": {
                "user_type": new_type,
                "confidence": confidence,
                "scores": scores,
            },
        }
        await self.send_personal_message(message, user_id)
        logger.info(f"Notified user {user_id}: type changed to {new_type}")

    async def notify_product_recommendation(
        self, user_id: int, products: list, reason: str
    ):
        """Send new product recommendations to user."""
        message = {
            "event": "new_recommendations",
            "data": {
                "products": products,
                "reason": reason,
            },
        }
        await self.send_personal_message(message, user_id)

    async def broadcast(self, message: dict):
        """Broadcast a message to all connected users."""
        for user_id in list(self.active_connections.keys()):
            await self.send_personal_message(message, user_id)

    def get_connected_users(self) -> List[int]:
        """Get list of currently connected user IDs."""
        return list(self.active_connections.keys())

    def is_user_connected(self, user_id: int) -> bool:
        """Check if a user has any active connections."""
        return user_id in self.active_connections and len(self.active_connections[user_id]) > 0


# Global singleton instance
manager = ConnectionManager()
