"""
Chat HTTP View - Forward queries to FastAPI (REST API for Flutter)

This is the REST API endpoint for Flutter mobile app.
Uses WebSocket internally to communicate with FastAPI for speed.

POST /api/chat/
Request: {"query": "How to get passport?"}
Response: {
    "response": "You need citizenship certificate...",
    "sources": [
        {
            "notice_id": "550e8400-e29b-41d4-a716-446655440000",
            "ministry_name": "Ministry of Foreign Affairs",
            "service_name": "Passport Services",
            "excerpt": "Required documents include..."
        }
    ]
}

Flow:
1. Flutter sends POST to /api/chat/
2. Django forwards to FastAPI via WebSocket (fast persistent connection)
3. FastAPI returns RAG response with sources
4. Django returns response to Flutter
5. User taps source → Flutter uses notice_id for deep linking
"""
import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework.throttling import AnonRateThrottle
from rag_bridge.services import send_query

logger = logging.getLogger(__name__)


class ChatRateThrottle(AnonRateThrottle):
    """Rate limit for chat: 30 requests per minute"""
    rate = '30/min'


class ChatView(APIView):
    """
    REST API endpoint for citizen chat.
    
    Flutter uses this endpoint (not WebSocket) for simplicity.
    Django uses WebSocket internally to FastAPI for speed.
    """
    permission_classes = [AllowAny]
    throttle_classes = [ChatRateThrottle]
    
    def post(self, request):
        query = request.data.get('query', '').strip()
        session_id = request.data.get('session_id')  # Optional
        
        if not query:
            return Response({
                "success": False,
                "error": "Query is required",
                "response": "",
                "sources": []
            }, status=400)
        
        if len(query) > 1000:
            return Response({
                "success": False,
                "error": "Query too long (max 1000 characters)",
                "response": "",
                "sources": []
            }, status=400)
        
        logger.info(f"Chat API query: {query[:50]}...")
        
        # Forward to FastAPI (uses WebSocket internally)
        result = send_query(query, session_id, use_websocket=True)
        
        # Check for errors
        if result.get('error'):
            logger.warning(f"Chat query failed: {result.get('error')}")
            return Response({
                "success": False,
                "error": result.get('error'),
                "response": "",
                "sources": []
            }, status=503)
        
        # Success response
        return Response({
            "success": True,
            "response": result.get('response', ''),
            "sources": result.get('sources', [])
        })
