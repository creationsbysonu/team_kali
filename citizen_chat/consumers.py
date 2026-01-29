"""
Chat WebSocket Consumer - Forward queries to FastAPI via WebSocket

Flow:
1. Flutter connects to ws://server/ws/chat/
2. Flutter sends: {"query": "How to get passport?"}
3. Django forwards to FastAPI via WebSocket (fast persistent connection)
4. FastAPI returns: {"response": "...", "sources": [{"notice_id": "uuid", ...}]}
5. Django sends back to Flutter
6. Flutter displays response and clickable sources
7. User clicks source → Flutter navigates to NoticeDetailScreen(notice_id)

Django-FastAPI connection: WebSocket (persistent, fast)
Django-Flutter connection: WebSocket (for this consumer) or REST API (for views.py)

MOBILE DEVICE SUPPORT:
- Works on physical Android/iOS devices over WiFi
- Flutter connects using server's LAN IP: ws://192.168.1.112:8000/ws/chat/
- Supports ping/pong for connection keep-alive
- Auto-handles reconnection on Flutter side
"""
import json
import logging
import asyncio
from channels.generic.websocket import AsyncWebsocketConsumer
from rag_bridge.services import async_send_query

logger = logging.getLogger(__name__)


class CitizenChatConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for citizen chat on mobile devices.
    
    Connection URL: ws://192.168.1.112:8000/ws/chat/
    Optional Auth: ws://host/ws/chat/?token=<jwt_access_token>
    
    Protocol:
    - Connect: Receives {"type": "connected", "message": "..."}
    - Send: {"query": "Your question here"}
    - Receive: {"response": "...", "sources": [...]}
    - Ping: {"type": "ping"} → {"type": "pong"} (for keep-alive)
    """
    
    async def connect(self):
        """Accept WebSocket connection from mobile device."""
        await self.accept()
        
        # Get user info if authenticated
        user = self.scope.get('user')
        user_info = "anonymous"
        if user and user.is_authenticated:
            user_info = user.email
        
        # Send welcome message
        await self.send(json.dumps({
            "type": "connected",
            "message": "Connected to Sewa Sathi AI Assistant!",
            "user": user_info
        }))
        logger.info(f"[chat-ws] Connected: {self.channel_name}, user={user_info}")
    
    async def disconnect(self, close_code):
        """Handle WebSocket disconnection."""
        logger.info(f"[chat-ws] Disconnected: {self.channel_name}, code={close_code}")
    
    async def receive(self, text_data):
        """Handle incoming messages from Flutter app."""
        try:
            data = json.loads(text_data)
        except json.JSONDecodeError:
            await self.send(json.dumps({
                "type": "error",
                "error": "Invalid JSON format",
                "response": "",
                "sources": []
            }))
            return
        
        # Handle ping for connection keep-alive (mobile networks need this)
        msg_type = data.get('type')
        if msg_type == 'ping':
            await self.send(json.dumps({"type": "pong"}))
            return
        
        query = data.get('query', '').strip()
        session_id = data.get('session_id')  # Optional for context
        
        if not query:
            await self.send(json.dumps({
                "type": "error",
                "error": "Query is required",
                "response": "",
                "sources": []
            }))
            return
        
        # Validate query length
        if len(query) > 1000:
            await self.send(json.dumps({
                "type": "error",
                "error": "Query too long (max 1000 characters)",
                "response": "",
                "sources": []
            }))
            return
        
        logger.info(f"[chat-ws] Query: {query[:50]}...")
        
        # Send "typing" indicator to Flutter
        await self.send(json.dumps({
            "type": "typing",
            "message": "AI is thinking..."
        }))
        
        try:
            # Forward to FastAPI via WebSocket (fast!)
            result = await async_send_query(query, session_id)
            
            # Add type field for Flutter to identify response
            result['type'] = 'response'
            
            # Send response back to Flutter
            await self.send(json.dumps(result))
            logger.info(f"[chat-ws] Response sent, sources={len(result.get('sources', []))}")
            
        except Exception as e:
            logger.error(f"[chat-ws] Error processing query: {e}")
            await self.send(json.dumps({
                "type": "error",
                "error": "Failed to process query. Please try again.",
                "response": "",
                "sources": []
            }))
