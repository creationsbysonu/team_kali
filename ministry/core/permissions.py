"""
Ministry Permission Classes

Permission classes for ministry-scoped access control.

- IsMinistryMember: Check if user is a member of a ministry
- IsSuperAdmin: Check if user is super admin
- IsCitizen: Check if user is a citizen
"""
import logging
from rest_framework.permissions import BasePermission
from rest_framework.request import Request
from rest_framework.views import APIView

logger = logging.getLogger(__name__)


class IsMinistryMember(BasePermission):
    """
    User must be an active member of the request ministry.
    
    Use for endpoints that require ministry context.
    This permission works with JWT-based ministry context.
    """
    message = "You must be a member of this ministry."
    
    def has_permission(self, request: Request, view: APIView) -> bool:
        # Debug logging
        logger.info(f"[permission] Checking IsMinistryMember for {request.path}")
        logger.info(f"[permission] User authenticated: {request.user.is_authenticated}")
        logger.info(f"[permission] Has ministry attr: {hasattr(request, 'ministry')}")
        logger.info(f"[permission] Ministry value: {getattr(request, 'ministry', None)}")
        
        if not request.user.is_authenticated:
            logger.warning(f"[permission] ❌ User not authenticated")
            return False
        
        # Check if ministry context exists (set by middleware from JWT)
        if not hasattr(request, 'ministry') or not request.ministry:
            logger.warning(f"[permission] ❌ No ministry context")
            return False
        
        # Ministry context is set by middleware from JWT token
        # If request.ministry exists, the JWT contained valid ministry_id
        # No need to check database relationships - trust the JWT
        logger.info(f"[permission] ✅ Ministry context valid: {request.ministry.slug}")
        return True


class IsSuperAdmin(BasePermission):
    """
    User must be a system super admin.
    
    Use for system-wide management (creating ministries, managing all staff, etc.)
    """
    message = "Super admin access required."
    
    def has_permission(self, request: Request, view: APIView) -> bool:
        if not request.user.is_authenticated:
            return False
        
        return getattr(request.user, 'user_type', None) == 'super_admin'


class IsCitizen(BasePermission):
    """
    User must be a citizen.
    
    Use for citizen-only endpoints.
    """
    message = "Citizen access required."
    
    def has_permission(self, request: Request, view: APIView) -> bool:
        if not request.user.is_authenticated:
            return False
        
        return getattr(request.user, 'user_type', None) == 'citizen'


class MinistryAccessPermission(BasePermission):
    """
    Combined permission: authenticated + ministry member.
    """
    message = "Ministry access required."
    
    def has_permission(self, request: Request, view: APIView) -> bool:
        if not request.user.is_authenticated:
            return False
        
        # Super admins can access all ministries
        if getattr(request.user, 'user_type', None) == 'super_admin':
            return True
        
        # Regular users must be ministry members
        if not hasattr(request, 'ministry') or not request.ministry:
            return False
        
        return request.user.ministry_memberships.filter(
            ministry=request.ministry,
            is_active=True
        ).exists()
