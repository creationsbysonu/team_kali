"""
Tenant Permission Classes

Permission classes for ministry-scoped access control.

Simplified structure (no role hierarchy within ministries):
- IsTenantMember: Check if user is a staff member of a ministry
- IsSuperAdmin: Check if user is super admin
- IsCitizen: Check if user is a citizen
- TenantAccessPermission: Combined permission for ministry staff endpoints
"""
import logging
from rest_framework.permissions import BasePermission
from rest_framework.request import Request
from rest_framework.views import APIView

logger = logging.getLogger(__name__)


class IsTenantMember(BasePermission):
    """
    User must be an active staff member of the request ministry.
    
    Use for endpoints that require ministry context.
    All ministry staff have the same access level.
    """
    message = "You must be a staff member of this ministry."
    
    def has_permission(self, request: Request, view: APIView) -> bool:  # type: ignore[override]
        if not request.user.is_authenticated:
            return False
        
        if not hasattr(request, 'tenant') or not request.tenant:
            return False
        
        # Check if user has membership in this ministry
        return request.user.tenant_memberships.filter(
            tenant=request.tenant,
            is_active=True
        ).exists()


class IsSuperAdmin(BasePermission):
    """
    User must be a system super admin.
    
    Use for system-wide management (creating ministries, managing all staff, etc.)
    """
    message = "Super admin access required."
    
    def has_permission(self, request: Request, view: APIView) -> bool:  # type: ignore[override]
        if not request.user.is_authenticated:
            return False
        
        return getattr(request.user, 'user_type', None) == 'super_admin'


class IsCitizen(BasePermission):
    """
    User must be a citizen.
    
    Use for citizen-only endpoints (Flutter app).
    """
    message = "This endpoint is for citizens only."
    
    def has_permission(self, request: Request, view: APIView) -> bool:  # type: ignore[override]
        if not request.user.is_authenticated:
            return False
        
        return getattr(request.user, 'user_type', None) == 'citizen'


class TenantAccessPermission(BasePermission):
    """
    Combined permission for ministry staff endpoints.
    
    - Super admins: Full access to all ministries
    - Ministry staff: Access to their ministry only
    - Citizens: No access (use IsCitizen for citizen endpoints)
    """
    message = "You don't have access to this ministry."
    
    def has_permission(self, request: Request, view: APIView) -> bool:  # type: ignore[override]
        if not request.user.is_authenticated:
            return False
        
        # Super admin has access to everything
        if getattr(request.user, 'user_type', None) == 'super_admin':
            return True
        
        # Check ministry context
        if not hasattr(request, 'tenant') or not request.tenant:
            return False
        
        # Check membership (all staff have same access)
        return request.user.tenant_memberships.filter(
            tenant=request.tenant,
            is_active=True
        ).exists()
