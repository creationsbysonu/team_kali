"""
Ministry Middleware

Sets the current ministry context from request headers or authenticated user.
"""
import logging
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
        
        # 1. Try X-Ministry-ID header first (for API/dashboard)
        ministry_id = request.headers.get('X-Ministry-ID')
        if ministry_id:
            try:
                from ministry.models import Ministry
                ministry = Ministry.objects.get(id=ministry_id, status='active')
                logger.debug(f"[ministry] Set from header: {ministry.slug}")
            except Exception as e:
                logger.warning(f"[ministry] Invalid ministry ID in header: {ministry_id}")
        
        # 2. Try from authenticated user's membership
        if not ministry and hasattr(request, 'user') and request.user.is_authenticated:
            membership = getattr(request.user, 'ministry_memberships', None)
            if membership:
                active_membership = membership.filter(is_active=True).first()
                if active_membership:
                    ministry = active_membership.ministry
                    logger.debug(f"[ministry] Set from user membership: {ministry.slug}")
        
        # Set ministry in context
        if ministry:
            set_current_ministry(ministry)
            request.ministry = ministry
        else:
            request.ministry = None
    
    def process_response(self, request, response):
        clear_current_ministry()
        return response
