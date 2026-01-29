"""
RAG Bridge WebSocket Client

Persistent WebSocket connection to FastAPI RAG server for fast chat responses.
Uses connection pooling and auto-reconnect for reliability.

Flow:
1. Django opens WebSocket to FastAPI at startup
2. Chat queries go through the persistent connection (fast!)
3. Auto-reconnects if connection drops
"""
import json
import asyncio
import logging
from typing import Optional, Dict, Any
from django.conf import settings

logger = logging.getLogger(__name__)

# WebSocket URL derived from HTTP URL
# http://localhost:8001 -> ws://localhost:8001/ws/chat
HTTP_BASE = getattr(settings, 'RAG_SERVER_URL', 'http://localhost:8001')
WS_BASE = HTTP_BASE.replace('http://', 'ws://').replace('https://', 'wss://')
WS_CHAT_URL = f"{WS_BASE}/ws/chat"


class RAGWebSocketClient:
    """
    Async WebSocket client for FastAPI RAG server.
    Maintains a persistent connection for fast chat queries.
    """
    
    def __init__(self):
        self._ws = None
        self._lock = asyncio.Lock()
        self._connected = False
    
    async def connect(self) -> bool:
        """Establish WebSocket connection to FastAPI."""
        try:
            import websockets
            
            async with self._lock:
                if self._connected and self._ws:
                    return True
                
                logger.info(f"Connecting to RAG WebSocket: {WS_CHAT_URL}")
                self._ws = await websockets.connect(
                    WS_CHAT_URL,
                    ping_interval=30,
                    ping_timeout=10,
                    close_timeout=5
                )
                self._connected = True
                logger.info("RAG WebSocket connected successfully")
                return True
                
        except ImportError:
            logger.error("websockets library not installed. Run: pip install websockets")
            return False
        except Exception as e:
            logger.error(f"Failed to connect to RAG WebSocket: {e}")
            self._connected = False
            return False
    
    async def disconnect(self):
        """Close WebSocket connection."""
        async with self._lock:
            if self._ws:
                await self._ws.close()
                self._ws = None
                self._connected = False
                logger.info("RAG WebSocket disconnected")
    
    async def send_query(self, query: str, session_id: str = None) -> Dict[str, Any]:
        """
        Send chat query through WebSocket and wait for response.
        
        Args:
            query: User's question
            session_id: Optional session ID for context
        
        Returns:
            {
                "response": "Answer text...",
                "sources": [
                    {
                        "notice_id": "uuid",
                        "ministry_name": "Ministry Name",
                        "service_name": "Service Name",  
                        "excerpt": "Relevant text..."
                    }
                ]
            }
        """
        # Ensure connected
        if not self._connected:
            if not await self.connect():
                return {"error": "Connection failed", "response": "", "sources": []}
        
        try:
            # Build request payload
            payload = {"query": query}
            if session_id:
                payload["session_id"] = session_id
            
            # Send query
            await self._ws.send(json.dumps(payload))
            logger.debug(f"Sent query to RAG: {query[:50]}...")
            
            # Wait for response (with timeout)
            response_text = await asyncio.wait_for(
                self._ws.recv(),
                timeout=30.0  # 30 second timeout
            )
            
            result = json.loads(response_text)
            logger.debug(f"Received RAG response: {str(result)[:100]}...")
            return result
            
        except asyncio.TimeoutError:
            logger.error("RAG WebSocket query timeout")
            return {"error": "timeout", "response": "", "sources": []}
            
        except Exception as e:
            logger.error(f"RAG WebSocket query failed: {e}")
            # Mark as disconnected so next query reconnects
            self._connected = False
            return {"error": str(e), "response": "", "sources": []}


# Global client instance (singleton)
_client: Optional[RAGWebSocketClient] = None


def get_ws_client() -> RAGWebSocketClient:
    """Get or create the global WebSocket client."""
    global _client
    if _client is None:
        _client = RAGWebSocketClient()
    return _client


async def async_send_chat_query(query: str, session_id: str = None) -> Dict[str, Any]:
    """
    Async function to send chat query via WebSocket.
    
    Use this in async views or consumers.
    
    Returns:
        {
            "response": "...",
            "sources": [{"notice_id": "uuid", ...}]
        }
    """
    client = get_ws_client()
    return await client.send_query(query, session_id)


def sync_send_chat_query(query: str, session_id: str = None) -> Dict[str, Any]:
    """
    Sync wrapper for sending chat query via WebSocket.
    
    Use this in regular sync views.
    Creates a new event loop if needed.
    """
    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            # Running inside async context - use run_coroutine_threadsafe
            import concurrent.futures
            future = asyncio.run_coroutine_threadsafe(
                async_send_chat_query(query, session_id),
                loop
            )
            return future.result(timeout=35)
        else:
            # Not in async context - just run
            return loop.run_until_complete(async_send_chat_query(query, session_id))
    except RuntimeError:
        # No event loop - create new one
        return asyncio.run(async_send_chat_query(query, session_id))
    except Exception as e:
        logger.error(f"Sync chat query failed: {e}")
        return {"error": str(e), "response": "", "sources": []}
