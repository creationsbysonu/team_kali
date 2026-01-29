"""
Database Connection Middleware

Ensures fresh database connections for each request to handle
Supabase Transaction Pooler connection instability.
"""
import logging
from django.db import connection, connections

logger = logging.getLogger(__name__)


class DatabaseConnectionMiddleware:
    """
    Middleware to handle database connection issues with Supabase pooler.
    
    Closes stale connections before each request to ensure fresh connections.
    This is necessary because Supabase's Transaction Pooler (port 6543)
    can return stale/dead connections when multiple requests come in parallel.
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        # Close stale connection before processing request
        try:
            if connection.connection is not None:
                if not connection.is_usable():
                    logger.debug("Closing stale database connection")
                    connection.close()
        except Exception as e:
            logger.warning(f"Error checking connection: {e}")
            try:
                connection.close()
            except:
                pass
        
        # Process the request
        response = self.get_response(request)
        
        # Close connection after request to prevent stale connections
        # This is important for Supabase Transaction Pooler
        try:
            connection.close()
        except Exception as e:
            logger.warning(f"Error closing connection after request: {e}")
        
        return response
