"""
Custom permission classes for Queue Management System.
"""

from rest_framework import permissions  # type: ignore[import-untyped]
from ministry.models import Ministry, StaffService
from core.utils.nepal_time import get_nepal_today


class IsMinistryAdmin(permissions.BasePermission):
    """
    Permission class for ministry administrators.
    
    Ministry admins can:
    - Configure queue settings
    - Mark attendance
    - Create holidays (ministry-specific)
    
    A ministry admin is identified by:
    - user_type = 'admin' AND has ministry_id in JWT token
    - OR is_staff = True (super admin)
    """
    
    def has_permission(self, request, view):  # type: ignore[override]
        """Check if user is authenticated and is ministry admin."""
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Super admins have all permissions (only for CustomUser, not Ministry)
        if hasattr(request.user, 'is_staff') and hasattr(request.user, 'is_superuser'):
            if request.user.is_staff or request.user.is_superuser:
                return True
        
        # Check if user is Ministry (logged in as ministry)
        if isinstance(request.user, Ministry):
            return True
        
        # Check if user is ministry admin (user_type = 'admin')
        if hasattr(request.user, 'user_type') and request.user.user_type == 'admin':
            # Verify they have ministry context (set by middleware)
            if hasattr(request, 'ministry') and request.ministry:
                return True
        
        # Check if user has ministry membership
        if hasattr(request.user, 'ministry_memberships'):
            return request.user.ministry_memberships.filter(is_active=True).exists()
        
        return False
    
    def has_object_permission(self, request, view, obj):  # type: ignore[override]
        """Check if user has permission for specific ministry object."""
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Super admins have all permissions (only for CustomUser, not Ministry)
        if hasattr(request.user, 'is_staff') and hasattr(request.user, 'is_superuser'):
            if request.user.is_staff or request.user.is_superuser:
                return True
        
        # If user is Ministry, check if they own the object
        if isinstance(request.user, Ministry):
            if isinstance(obj, Ministry):
                return obj.id == request.user.id
            # For other objects, check if they belong to this ministry
            if hasattr(obj, 'ministry'):
                return obj.ministry.id == request.user.id
            return True  # Allow by default for ministry users
        
        # If obj is a Ministry, check if user belongs to it
        if isinstance(obj, Ministry):
            # Ministry admins can access their own ministry
            if hasattr(request, 'ministry') and request.ministry:
                return obj.id == request.ministry.id
        
        return False


class IsStaffAdminForToday(permissions.BasePermission):
    """
    Permission class for staff admins to manage today's queue only.
    
    Staff admins can only:
    - View today's queue
    - Mark tokens as SERVED
    - Mark tokens as NO_SHOW
    
    They cannot:
    - Configure queue settings
    - Mark attendance
    - View/modify past or future queues
    """
    
    def has_permission(self, request, view):  # type: ignore[override]
        """Check if user is authenticated and is staff admin."""
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Check if user is a StaffService object (staff login)
        user_type = getattr(request.user, 'user_type', None)
        if user_type == 'staff':
            # User logged in as staff - check if active
            return request.user.is_active and request.user.status == StaffService.Status.ACTIVE
        
        # Regular Django user - check if is_staff or has a staff service
        if hasattr(request.user, 'is_staff') and request.user.is_staff:
            return True
        
        # Check if user has an associated staff service by email
        return StaffService.objects.filter(
            email=request.user.email,
            is_active=True
        ).exists()
    
    def has_object_permission(self, request, view, obj):  # type: ignore[override]
        """Check if user has permission for today's queue only."""
        if not request.user or not request.user.is_authenticated:
            return False
        
        # If obj is a QueueToken, check if it's for today
        from queue_management.models import QueueToken
        if isinstance(obj, QueueToken):
            today = get_nepal_today()
            if obj.daily_queue.date != today:
                return False
            
            # Check if user belongs to this staff service
            staff_service = obj.daily_queue.queue_config.staff_service
            
            # If user is a StaffService, compare IDs
            user_type = getattr(request.user, 'user_type', None)
            if user_type == 'staff':
                return str(request.user.id) == str(staff_service.id)
            
            # Check by email or is_staff flag
            if staff_service.email == request.user.email:
                return True
            if hasattr(request.user, 'is_staff') and request.user.is_staff:
                return True
        
        # For regular Django users with is_staff
        if hasattr(request.user, 'is_staff') and request.user.is_staff:
            return True
        
        return False


class IsCitizen(permissions.BasePermission):
    """
    Permission class for citizens.
    
    Citizens can:
    - Book tokens
    - View their own tokens
    - Cancel their own tokens
    - View notifications
    """
    
    def has_permission(self, request, view):  # type: ignore[override]
        """Check if user is authenticated citizen."""
        if not request.user or not request.user.is_authenticated:
            return False
        
        # All authenticated users are citizens by default
        return True
    
    def has_object_permission(self, request, view, obj):  # type: ignore[override]
        """Check if citizen owns the object."""
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Check if user is staff (only for CustomUser)
        is_staff = getattr(request.user, 'is_staff', False)
        
        # If obj is a QueueToken, check if it belongs to the user
        from queue_management.models import QueueToken
        if isinstance(obj, QueueToken):
            return obj.citizen == request.user or is_staff
        
        # If obj is a Notification, check if it belongs to the user
        from notifications.models import Notification
        if isinstance(obj, Notification):
            return obj.user == request.user or is_staff
        
        return is_staff


class IsOwnerOrReadOnly(permissions.BasePermission):
    """
    Object-level permission to only allow owners to edit objects.
    """
    
    def has_object_permission(self, request, view, obj):
        """Check if user owns the object or is just reading."""
        # Read permissions are allowed for any request
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Check if user is staff (only for CustomUser)
        is_staff = getattr(request.user, 'is_staff', False)
        
        # Write permissions are only allowed to the owner or staff
        if hasattr(obj, 'user'):
            return obj.user == request.user or is_staff
        elif hasattr(obj, 'citizen'):
            return obj.citizen == request.user or is_staff
        elif hasattr(obj, 'created_by'):
            return obj.created_by == request.user or is_staff
        
        return is_staff


class IsAdminUser(permissions.BasePermission):
    """
    Permission class for admin users (admin, super_admin, or is_staff).
    Used for notice uploads and other admin-only operations.
    """
    
    def has_permission(self, request, view):  # type: ignore[override]
        # Check if user is Ministry (logged in as ministry)
        if isinstance(request.user, Ministry):
            return True
        
        # Super admins and staff have all permissions (only for CustomUser)
        if hasattr(request.user, 'is_staff') and hasattr(request.user, 'is_superuser'):
            if request.user.is_staff or request.user.is_superuser:
                return True
        
        # Check if user is admin via user_type
        if hasattr(request.user, 'is_admin_user'):
            return request.user.is_admin_user
        
        if hasattr(request.user, 'user_type'):
            return request.user.user_type in ['admin', 'super_admin']
        
        return False


class IsMinistryAdminOrReadOnly(permissions.BasePermission):
    """
    Permission for ministry admins to write, others to read.
    """
    
    def has_permission(self, request, view):  # type: ignore[override]
        """Check permissions based on request method."""
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Check if user is Ministry (logged in as ministry)
        if isinstance(request.user, Ministry):
            return True
        
        # Read permissions for any authenticated user
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Write permissions for ministry admins or staff
        is_staff = getattr(request.user, 'is_staff', False)
        return is_staff or hasattr(request.user, 'ministry_profile')
