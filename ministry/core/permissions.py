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
    """
    message = "You must be a member of this ministry."
    
    def has_permission(self, request: Request, view: APIView) -> bool:
        if not request.user.is_authenticated:
            return False
        
        if not hasattr(request, 'ministry') or not request.ministry:
            return False
        
        # Check if user has membership in this ministry
        return request.user.ministry_memberships.filter(
            ministry=request.ministry,
            is_active=True
        ).exists()


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
