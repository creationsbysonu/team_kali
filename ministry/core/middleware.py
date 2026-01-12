"""
Ministry Middleware

Sets the current ministry context from request headers or authenticated user.
"""
import logging
import jwt
from django.conf import settings
from django.utils.deprecation import MiddlewareMixin
from .context import set_current_ministry, clear_current_ministry

logger = logging.getLogger(__name__)


class MinistryMiddleware(MiddlewareMixin):
    """
    Middleware to set ministry context from request.
    
    Ministry is determined by (in order of priority):
    1. X-Ministry-ID header (for API clients)
    2. Authenticated user's ministry membership
    """
    
    def process_request(self, request):
        ministry = None
        
        # Log request details for debugging
        logger.info(f"[ministry] Processing request: {request.path}")
        logger.info(f"[ministry] Request method: {request.method}")
        logger.info(f"[ministry] User authenticated: {request.user.is_authenticated if hasattr(request, 'user') else 'No user'}")
        logger.info(f"[ministry] Request headers: {dict(request.headers)}")
        
        # Skip middleware for OPTIONS requests (CORS preflight)
        if request.method == 'OPTIONS':
            logger.info(f"[ministry] Skipping OPTIONS request")
            return None
        
        # 1. Try X-Ministry-ID header first (for API/dashboard)
        ministry_id = request.headers.get('X-Ministry-ID')
        if ministry_id:
            try:
                from ministry.models import Ministry
                ministry = Ministry.objects.get(id=ministry_id, status='active')
                logger.info(f"[ministry] Set from header: {ministry.slug}")
            except Exception as e:
                logger.warning(f"[ministry] Invalid ministry ID in header: {ministry_id}")
        
        # 2. Try from JWT token (for ministry admin authentication)
        # IMPORTANT: Don't check is_authenticated here because middleware runs BEFORE DRF JWT auth
        if not ministry:
            # Extract ministry_id from Authorization header JWT token
            auth_header = request.headers.get('Authorization', '')
            logger.info(f"[ministry] Auth header present: {bool(auth_header)}")
            
            if auth_header.startswith('Bearer '):
                token = auth_header.split(' ')[1]
                logger.info(f"[ministry] Extracted token (first 20 chars): {token[:20]}...")
                
                try:
                    # Decode JWT to get claims
                    decoded = jwt.decode(
                        token,
                        settings.SECRET_KEY,
                        algorithms=['HS256']
                    )
                    ministry_id = decoded.get('ministry_id')
                    logger.info(f"[ministry] Decoded ministry_id from JWT: {ministry_id}")
                    
                    if ministry_id:
                        from ministry.models import Ministry
                        ministry = Ministry.objects.get(id=ministry_id, status='active')
                        logger.info(f"[ministry] ✅ Set from JWT token: {ministry.slug}")
                except jwt.ExpiredSignatureError:
                    logger.warning(f"[ministry] ❌ Expired JWT token")
                except jwt.InvalidTokenError as e:
                    logger.warning(f"[ministry] ❌ Invalid JWT token: {str(e)}")
                except Exception as e:
                    logger.warning(f"[ministry] ❌ Error decoding JWT: {str(e)}")
        
        # 3. Try from authenticated user's membership (fallback)
        if not ministry and hasattr(request, 'user') and request.user.is_authenticated:
            membership = getattr(request.user, 'ministry_memberships', None)
            if membership:
                active_membership = membership.filter(is_active=True).first()
                if active_membership:
                    ministry = active_membership.ministry
                    logger.info(f"[ministry] Set from user membership: {ministry.slug}")
        
        # Set ministry in context
        if ministry:
            set_current_ministry(ministry)
            request.ministry = ministry
            logger.info(f"[ministry] ✅ Final ministry set: {ministry.slug}")
        else:
            request.ministry = None
            logger.warning(f"[ministry] ❌ No ministry context set for request")
    
    def process_response(self, request, response):
        clear_current_ministry()
        return response
