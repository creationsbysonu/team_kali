"""
RAG Bridge - Pass files and queries to FastAPI

Sends notice data to FastAPI RAG server for:
1. Document ingestion (PDF/image → vector DB)
2. Chat queries (user question → RAG response)
"""
import logging
import httpx
from django.conf import settings

logger = logging.getLogger(__name__)

BASE_URL = getattr(settings, 'RAG_SERVER_URL', 'http://localhost:8001')


def send_file(
    file_url: str, 
    notice_id: str,
    title: str = None,
    ministry_name: str = None,
    service_name: str = None
):
    """
    Send file URL to FastAPI /ingest with metadata for better RAG responses.
    
    Args:
        file_url: Cloudinary URL of the PDF/image
        notice_id: UUID of the notice (for deep linking in chat sources)
        title: Title of the notice
        ministry_name: Name of the ministry (notice always belongs to a ministry)
        service_name: Name of the service (optional - if notice is for a specific service)
    
    Notice upload sources:
    - Ministry Admin Panel: notice has ministry, may have service
    - Staff Admin Panel: notice has ministry (via staff's ministry), has service (staff's assigned service)
    
    Returns:
        dict: Response from FastAPI
    """
    payload = {
        "file_url": file_url,
        "notice_id": notice_id,
    }
    
    # Add optional fields if provided
    if title:
        payload["title"] = title
    # ministry_name is always present (notice must belong to a ministry)
    if ministry_name:
        payload["ministry_name"] = ministry_name
    # service_name is optional (present if notice is linked to a specific service)
    if service_name:
        payload["service_name"] = service_name
    
    try:
        logger.info(f"Sending notice {notice_id} to RAG server: {BASE_URL}/ingest")
        r = httpx.post(
            f"{BASE_URL}/ingest",
            json=payload,
            timeout=120  # 2 minutes for large PDFs
        )
        result = r.json()
        logger.info(f"RAG ingestion response for {notice_id}: {result}")
        return result
    except httpx.TimeoutException:
        logger.error(f"RAG ingestion timeout for notice {notice_id}")
        return {"error": "timeout", "message": "FastAPI server timeout"}
    except Exception as e:
        logger.error(f"RAG ingestion failed for notice {notice_id}: {str(e)}")
        return {"error": "failed", "message": str(e)}


def send_query(query: str, session_id: str = None, use_websocket: bool = True):
    """
    Send chat query to FastAPI RAG server.
    
    PRIMARY: Uses WebSocket for fast, persistent connection
    FALLBACK: HTTP POST if WebSocket fails
    
    Args:
        query: User's question (Nepali or English)
        session_id: Optional session ID for conversation context
        use_websocket: Try WebSocket first (default True)
    
    Returns:
        {
            "response": "Answer text...",
            "sources": [
                {
                    "notice_id": "uuid-here",
                    "ministry_name": "Ministry Name",
                    "service_name": "Service Name",
                    "excerpt": "Relevant text snippet..."
                }
            ]
        }
    """
    # Try WebSocket first (fast)
    if use_websocket:
        try:
            from .ws_client import sync_send_chat_query
            result = sync_send_chat_query(query, session_id)
            if result.get('response') or result.get('sources'):
                logger.debug(f"Chat query via WebSocket succeeded")
                return result
            # If no response/sources but no error, still return
            if 'error' not in result:
                return result
            logger.warning(f"WebSocket returned error, falling back to HTTP: {result.get('error')}")
        except Exception as e:
            logger.warning(f"WebSocket chat failed, falling back to HTTP: {e}")
    
    # Fallback to HTTP
    try:
        logger.info(f"Sending chat query via HTTP: {BASE_URL}/chat")
        payload = {"query": query}
        if session_id:
            payload["session_id"] = session_id
        
        r = httpx.post(f"{BASE_URL}/chat", json=payload, timeout=30)
        return r.json()
    except httpx.TimeoutException:
        logger.error("Chat HTTP timeout")
        return {"error": "timeout", "response": "", "sources": []}
    except Exception as e:
        logger.error(f"Chat HTTP failed: {e}")
        return {"error": str(e), "response": "", "sources": []}


async def async_send_query(query: str, session_id: str = None):
    """
    Async version of send_query for use in async views/consumers.
    
    Uses WebSocket directly (no sync wrapper overhead).
    """
    try:
        from .ws_client import async_send_chat_query
        return await async_send_chat_query(query, session_id)
    except Exception as e:
        logger.error(f"Async chat query failed: {e}")
        return {"error": str(e), "response": "", "sources": []}

