"""
WebSocket Authentication Middleware

Handles JWT authentication for WebSocket connections.
Integrates with the existing SimpleJWT authentication used by the project.
"""

import logging
from urllib.parse import parse_qs
from channels.db import database_sync_to_async
from channels.middleware import BaseMiddleware
from django.contrib.auth.models import AnonymousUser
from django.conf import settings
from rest_framework_simplejwt.tokens import AccessToken
from rest_framework_simplejwt.exceptions import TokenError, InvalidToken

logger = logging.getLogger(__name__)


@database_sync_to_async
def get_user_from_jwt(token: str):
    """
    Retrieve user from JWT access token.
    Returns AnonymousUser if token is invalid.
    """
    from django.contrib.auth import get_user_model
    User = get_user_model()
    
    try:
        # Decode the access token
        access_token = AccessToken(token)
        user_id = access_token.get('user_id')
        
        if not user_id:
            logger.warning("JWT token has no user_id claim")
            return AnonymousUser()
        
        # Get user from database
        user = User.objects.get(id=user_id, is_active=True)
        logger.debug(f"JWT auth success: {user.email}")
        return user
        
    except TokenError as e:
        logger.warning(f"Invalid JWT token: {e}")
        return AnonymousUser()
    except User.DoesNotExist:
        logger.warning(f"User not found for JWT token")
        return AnonymousUser()
    except Exception as e:
        logger.error(f"JWT auth error: {e}")
        return AnonymousUser()


class JWTAuthMiddleware(BaseMiddleware):
    """
    JWT authentication middleware for Django Channels WebSocket connections.
    
    Supports two authentication methods:
    1. Query string: ws://host/ws/chat/?token=<jwt_access_token>
    2. Header: Authorization: Bearer <jwt_access_token>
    
    Usage:
        In asgi.py:
        from citizen_chat.middleware import JWTAuthMiddleware
        
        application = ProtocolTypeRouter({
            "websocket": JWTAuthMiddleware(URLRouter(websocket_urlpatterns))
        })
    """
    
    async def __call__(self, scope, receive, send):
        # Try to get token from query string first
        query_string = scope.get('query_string', b'').decode()
        query_params = parse_qs(query_string)
        token = query_params.get('token', [None])[0]
        
        # If not in query string, check headers
        if not token:
            headers = dict(scope.get('headers', []))
            auth_header = headers.get(b'authorization', b'').decode()
            
            if auth_header.startswith('Bearer '):
                token = auth_header[7:]
        
        # Authenticate
        if token:
            scope['user'] = await get_user_from_jwt(token)
            if scope['user'].is_authenticated:
                logger.debug(f"WebSocket authenticated: {scope['user'].email}")
        else:
            scope['user'] = AnonymousUser()
            logger.debug("No token provided for WebSocket connection")
        
        return await super().__call__(scope, receive, send)


# Backwards compatibility alias
TokenAuthMiddleware = JWTAuthMiddleware

def JWTAuthMiddlewareStack(inner):
    """
    Convenience function to wrap ASGI application with JWT auth.
    """
    return JWTAuthMiddleware(inner)
