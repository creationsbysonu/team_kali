"""
Super Admin Ministry Service

Handles system-wide ministry management.
Only for super admins.
"""
import logging
from typing import Any, Dict, Optional
from django.db import transaction
from django.db.models import Q, Count, Prefetch
from django.core.cache import cache
from django.contrib.auth import get_user_model
from django.utils import timezone

from ministry.models import Ministry, MinistryMember
from ministry.serializers import MinistryAdminSerializer, MinistryCreateSerializer
from places.models import Place

CustomUser = get_user_model()

logger = logging.getLogger(__name__)

# Cache timeout constants
MINISTRY_LIST_CACHE_TIMEOUT = 300  # 5 minutes
PLACE_FILTER_CACHE_TIMEOUT = 600   # 10 minutes


class SuperAdminMinistryService:
    """Service for super admin ministry management"""
    
    @staticmethod
    def _build_cache_key(filters: Optional[Dict] = None) -> str:
        """
        Build a deterministic cache key from filters.
        
        Uses sorted filter values to ensure consistent key generation.
        """
        if not filters:
            return "super_admin:ministries:all"
        
        # Extract and normalize filter values
        parts = ["super_admin:ministries"]
        
        if place_id := filters.get('place'):
            parts.append(f"place:{place_id}")
        if status_val := filters.get('status'):
            parts.append(f"status:{status_val}")
        if search := filters.get('search'):
            # Hash search term for shorter cache key
            import hashlib
            search_hash = hashlib.md5(search.lower().encode()).hexdigest()[:8]
            parts.append(f"search:{search_hash}")
        
        return ":".join(parts)
    
    @staticmethod
    def _invalidate_ministry_caches():
        """Invalidate all ministry-related caches"""
        cache.delete_pattern("super_admin:ministries:*")
        cache.delete("public_ministrys_list")
    
    @staticmethod
    def get_list(filters: Optional[Dict] = None, request=None):
        """
        Get list of all ministries with optimized filtering.
        
        Supports filtering by:
        - place: UUID of place to filter by
        - status: 'active', 'pending', 'suspended'
        - search: text search on ministry name
        
        Uses database indexes for optimal performance:
        - Index on (place, status) for combined filtering
        - Index on (place, slug) for place-based lookups
        - Index on (status) for status-only filtering
        
        Args:
            filters: dict with place, status, search
            request: HTTP request for context
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            # Build cache key
            cache_key = SuperAdminMinistryService._build_cache_key(filters)
            
            # Try cache first (skip if search filter - search results change frequently)
            use_cache = not (filters and filters.get('search'))
            if use_cache:
                cached_data = cache.get(cache_key)
                if cached_data is not None:
                    logger.debug(f"[super_admin] Cache hit for ministry list: {cache_key}")
                    return True, cached_data, 200
            
            # Build optimized queryset
            # Use select_related for place to avoid N+1 queries
            queryset = Ministry.objects.select_related('place').only(
                'id', 'name', 'slug', 'email', 'phone', 'address', 'website',
                'logo', 'status', 'description', 'settings',
                'created_at', 'updated_at', 'is_deleted',
                'place__id', 'place__name', 'place__slug'
            )
            
            # Apply filters using Q objects for optimal query building
            filter_conditions = Q()
            
            if filters:
                # Place filter - uses index (place, status) or (place, slug)
                if place_id := filters.get('place'):
                    # Validate place exists
                    if not Place.objects.filter(id=place_id).exists():
                        return False, {
                            "success": False,
                            "error": "Place not found"
                        }, 404
                    filter_conditions &= Q(place_id=place_id)
                
                # Status filter - uses index (status) or combined (place, status)
                if status_val := filters.get('status'):
                    if status_val not in [s[0] for s in Ministry.Status.choices]:
                        return False, {
                            "success": False,
                            "error": f"Invalid status. Must be one of: {', '.join([s[0] for s in Ministry.Status.choices])}"
                        }, 400
                    filter_conditions &= Q(status=status_val)
                
                # Text search on name - case insensitive
                if search := filters.get('search'):
                    # Clean and validate search term
                    search = search.strip()
                    if len(search) < 2:
                        return False, {
                            "success": False,
                            "error": "Search term must be at least 2 characters"
                        }, 400
                    filter_conditions &= Q(name__icontains=search)
            
            # Apply all filters at once (single WHERE clause)
            if filter_conditions:
                queryset = queryset.filter(filter_conditions)
            
            # Annotate with member count for display (using correct related_name 'members')
            queryset = queryset.annotate(
                member_count=Count('members', distinct=True)
            )
            
            # Order by place name first (grouping), then by ministry name
            queryset = queryset.order_by('place__name', 'name', '-created_at')
            
            # Serialize data
            context = {'request': request} if request else {}
            data = MinistryAdminSerializer(queryset, many=True, context=context).data
            
            response_data = {
                "success": True,
                "data": data,
                "count": len(data),
                "filters_applied": {
                    k: v for k, v in (filters or {}).items() if v
                }
            }
            
            # Cache the result (skip for search queries)
            if use_cache:
                cache.set(cache_key, response_data, timeout=MINISTRY_LIST_CACHE_TIMEOUT)
                logger.debug(f"[super_admin] Cached ministry list: {cache_key}")
            
            return True, response_data, 200
            
        except Exception as e:
            logger.error(f"[super_admin] Ministry list error: {str(e)}")
            import traceback
            logger.error(traceback.format_exc())
            return False, {
                "success": False,
                "error": "Failed to fetch ministries"
            }, 500
    
    @staticmethod
    def get_places_for_filter(request=None):
        """
        Get list of places for the filter dropdown.
        
        Returns places that have at least one ministry.
        Optimized for filter UI - minimal data transfer.
        
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            cache_key = "super_admin:places:filter_options"
            
            # Try cache first
            cached_data = cache.get(cache_key)
            if cached_data is not None:
                logger.debug("[super_admin] Cache hit for places filter options")
                return True, cached_data, 200
            
            # Get places with ministry count
            # Only return places that have at least one ministry OR all places for super admin
            places = Place.objects.annotate(
                ministry_count=Count('ministries', distinct=True)
            ).values(
                'id', 'name', 'slug', 'ministry_count'
            ).order_by('name')
            
            # Convert to list with proper formatting
            place_options = [
                {
                    "id": str(place['id']),
                    "name": place['name'],
                    "slug": place['slug'],
                    "ministry_count": place['ministry_count']
                }
                for place in places
            ]
            
            response_data = {
                "success": True,
                "data": place_options,
                "count": len(place_options)
            }
            
            # Cache for longer - places don't change often
            cache.set(cache_key, response_data, timeout=PLACE_FILTER_CACHE_TIMEOUT)
            
            return True, response_data, 200
            
        except Exception as e:
            logger.error(f"[super_admin] Places filter options error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch places"
            }, 500
    
    @staticmethod
    def get_detail(ministry_id, request=None):
        """Get detailed ministry information"""
        try:
            ministry = Ministry.objects.get(id=ministry_id)
            
            context = {'request': request} if request else {}
            serializer_data = MinistryAdminSerializer(ministry, context=context).data
            
            # Add additional stats
            data: Dict[str, Any] = dict(serializer_data)
            data['stats'] = {
                'total_staff': MinistryMember.objects.filter(ministry=ministry).count(),
                'active_staff': MinistryMember.objects.filter(ministry=ministry, is_active=True).count(),
            }
            
            return True, {"success": True, "data": data}, 200
            
        except Ministry.DoesNotExist:
            return False, {"success": False, "error": "Ministry not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Ministry detail error: {str(e)}")
            return False, {"success": False, "error": "Failed to fetch ministry"}, 500
    
    @staticmethod
    def create_ministry(data, admin_user, request=None):
        """
        Create a new ministry with email and password for direct login.
        
        Args:
            data: Ministry data including email and password
            admin_user: Super admin creating the ministry
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            # Extract password before serializer validation
            password = data.get('password')
            if not password:
                return False, {
                    "success": False,
                    "error": "Password is required for ministry creation"
                }, 400
            
            serializer = MinistryCreateSerializer(data=data)
            if not serializer.is_valid():
                return False, {
                    "success": False,
                    "error": serializer.errors
                }, 400
            
            with transaction.atomic():
                validated = serializer.validated_data
                ministry = Ministry.objects.create(**validated)  # type: ignore[arg-type]
                
                # Set the ministry password (hashed)
                ministry.set_password(password)
                ministry.save(update_fields=['password'])
                
                logger.info(f"[super_admin] Ministry '{ministry.name}' created by {admin_user.email}")
            
            # Clear caches
            cache.delete("public_ministrys_list")
            cache.delete_pattern("public_ministries_*")
            
            context = {'request': request} if request else {}
            return True, {
                "success": True,
                "data": MinistryAdminSerializer(ministry, context=context).data,
                "message": f"Ministry '{ministry.name}' created successfully"
            }, 201
            
        except Exception as e:
            logger.error(f"[super_admin] Create ministry error: {str(e)}")
            import traceback
            logger.error(traceback.format_exc())
            return False, {
                "success": False,
                "error": "Failed to create ministry"
            }, 500
    
    @staticmethod
    def update_ministry(ministry_id, data, admin_user, request=None):
        """Update ministry details"""
        try:
            ministry = Ministry.objects.get(id=ministry_id)
            
            with transaction.atomic():
                for field, value in data.items():
                    if hasattr(ministry, field) and field not in ['id', 'created_at']:
                        setattr(ministry, field, value)
                ministry.save()
            
            # Clear caches
            cache.delete("public_ministrys_list")
            cache.delete(f"public_ministry_{ministry.slug}")
            
            logger.info(f"[super_admin] Ministry '{ministry.name}' updated by {admin_user.email}")
            
            context = {'request': request} if request else {}
            return True, {
                "success": True,
                "data": MinistryAdminSerializer(ministry, context=context).data,
                "message": "Ministry updated successfully"
            }, 200
            
        except Ministry.DoesNotExist:
            return False, {"success": False, "error": "Ministry not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Update ministry error: {str(e)}")
            return False, {"success": False, "error": "Failed to update ministry"}, 500
    
    @staticmethod
    def activate_ministry(ministry_id, admin_user):
        """Activate a pending/suspended ministry"""
        try:
            ministry = Ministry.objects.get(id=ministry_id)
            
            if ministry.status == Ministry.Status.ACTIVE:
                return False, {
                    "success": False,
                    "error": "Ministry is already active"
                }, 400
            
            with transaction.atomic():
                ministry.status = Ministry.Status.ACTIVE
                ministry.save(update_fields=['status', 'updated_at'])
            
            cache.delete("public_ministrys_list")
            
            logger.info(f"[super_admin] Ministry '{ministry.name}' activated by {admin_user.email}")
            
            return True, {
                "success": True,
                "message": f"Ministry '{ministry.name}' activated"
            }, 200
            
        except Ministry.DoesNotExist:
            return False, {"success": False, "error": "Ministry not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Activate ministry error: {str(e)}")
            return False, {"success": False, "error": "Failed to activate ministry"}, 500
    
    @staticmethod
    def suspend_ministry(ministry_id, admin_user, reason=None):
        """Suspend a ministry"""
        try:
            ministry = Ministry.objects.get(id=ministry_id)
            
            if ministry.status == Ministry.Status.SUSPENDED:
                return False, {
                    "success": False,
                    "error": "Ministry is already suspended"
                }, 400
            
            with transaction.atomic():
                ministry.status = Ministry.Status.SUSPENDED
                if reason:
                    ministry.settings['suspension_reason'] = reason
                    ministry.settings['suspended_at'] = str(timezone.now())
                    ministry.settings['suspended_by'] = str(admin_user.id)
                ministry.save()
            
            cache.delete("public_ministrys_list")
            cache.delete(f"public_ministry_{ministry.slug}")
            
            logger.info(f"[super_admin] Ministry '{ministry.name}' suspended by {admin_user.email}. Reason: {reason}")
            
            return True, {
                "success": True,
                "message": f"Ministry '{ministry.name}' suspended"
            }, 200
            
        except Ministry.DoesNotExist:
            return False, {"success": False, "error": "Ministry not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Suspend ministry error: {str(e)}")
            return False, {"success": False, "error": "Failed to suspend ministry"}, 500
    
    @staticmethod
    def soft_delete_ministry(ministry_id, admin_user):
        """Soft delete a ministry (data remains, ministry inaccessible)"""
        try:
            ministry = Ministry.objects.get(id=ministry_id)
            
            if ministry.is_deleted:
                return False, {
                    "success": False,
                    "error": "Ministry is already deleted"
                }, 400
            
            ministry_name = ministry.name
            ministry.soft_delete(deleted_by=admin_user)
            
            cache.delete("public_ministrys_list")
            cache.delete(f"public_ministry_{ministry.slug}")
            
            logger.warning(f"[super_admin] Ministry '{ministry_name}' SOFT DELETED by {admin_user.email}")
            
            return True, {
                "success": True,
                "message": f"Ministry '{ministry_name}' deleted (can be restored)"
            }, 200
            
        except Ministry.DoesNotExist:
            return False, {"success": False, "error": "Ministry not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Soft delete ministry error: {str(e)}")
            return False, {"success": False, "error": "Failed to delete ministry"}, 500
    
    @staticmethod
    def restore_ministry(ministry_id, admin_user):
        """Restore a soft-deleted ministry"""
        try:
            ministry = Ministry.all_objects.get(id=ministry_id)
            
            if not ministry.is_deleted:
                return False, {
                    "success": False,
                    "error": "Ministry is not deleted"
                }, 400
            
            ministry.restore()
            
            cache.delete("public_ministrys_list")
            
            logger.info(f"[super_admin] Ministry '{ministry.name}' RESTORED by {admin_user.email}")
            
            return True, {
                "success": True,
                "message": f"Ministry '{ministry.name}' restored"
            }, 200
            
        except Ministry.DoesNotExist:
            return False, {"success": False, "error": "Ministry not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Restore ministry error: {str(e)}")
            return False, {"success": False, "error": "Failed to restore ministry"}, 500
    
    @staticmethod
    def hard_delete_ministry(ministry_id, admin_user, confirm=False):
        """Permanently delete a ministry (irreversible)"""
        try:
            if not confirm:
                return False, {
                    "success": False,
                    "error": "Confirmation required. Set confirm=true to proceed."
                }, 400
            
            ministry = Ministry.all_objects.get(id=ministry_id)
            ministry_name = ministry.name
            ministry_slug = ministry.slug
            
            with transaction.atomic():
                ministry.delete()
            
            cache.delete("public_ministrys_list")
            cache.delete(f"public_ministry_{ministry_slug}")
            
            logger.warning(f"[super_admin] Ministry '{ministry_name}' PERMANENTLY DELETED by {admin_user.email}")
            
            return True, {
                "success": True,
                "message": f"Ministry '{ministry_name}' permanently deleted"
            }, 200
            
        except Ministry.DoesNotExist:
            return False, {"success": False, "error": "Ministry not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Hard delete ministry error: {str(e)}")
            return False, {"success": False, "error": "Failed to delete ministry"}, 500
    
    @staticmethod
    def get_deleted_list(request=None):
        """Get list of soft-deleted ministries"""
        try:
            queryset = Ministry.all_objects.filter(is_deleted=True).order_by('-deleted_at')
            
            context = {'request': request} if request else {}
            data = MinistryAdminSerializer(queryset, many=True, context=context).data
            
            return True, {
                "success": True,
                "data": data,
                "count": len(data)
            }, 200
            
        except Exception as e:
            logger.error(f"[super_admin] Deleted ministry list error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch deleted ministries"
            }, 500
    
    @staticmethod
    def reset_ministry_password(ministry_id, new_password, admin_user):
        """Reset the ministry admin's password"""
        try:
            ministry = Ministry.objects.get(id=ministry_id)
            
            # Find the ministry admin
            member = MinistryMember.objects.filter(ministry=ministry, is_active=True).first()
            
            if not member:
                return False, {
                    "success": False,
                    "error": "No admin found for this ministry"
                }, 404
            
            if len(new_password) < 8:
                return False, {
                    "success": False,
                    "error": "Password must be at least 8 characters"
                }, 400
            
            member.user.set_password(new_password)
            member.user.save()
            
            logger.info(f"[super_admin] Password reset for ministry admin of '{ministry.name}' by {admin_user.email}")
            
            return True, {
                "success": True,
                "message": f"Password reset for ministry admin of '{ministry.name}'"
            }, 200
            
        except Ministry.DoesNotExist:
            return False, {"success": False, "error": "Ministry not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Reset password error: {str(e)}")
            return False, {"success": False, "error": "Failed to reset password"}, 500
    
    @staticmethod
    def add_staff_to_ministry(ministry_id, user_id, admin_user):
        """Add staff to a ministry"""
        try:
            ministry = Ministry.objects.get(id=ministry_id)
            
            from authentication.models import CustomUser
            user = CustomUser.objects.get(id=user_id)
            
            # Check if already a member
            if MinistryMember.objects.filter(ministry=ministry, user=user).exists():
                return False, {
                    "success": False,
                    "error": "User is already a staff member of this ministry"
                }, 400
            
            with transaction.atomic():
                MinistryMember.objects.create(
                    ministry=ministry,
                    user=user,
                    is_active=True
                )
            
            logger.info(f"[super_admin] User {user.email} added as staff to '{ministry.name}' by {admin_user.email}")
            
            return True, {
                "success": True,
                "message": f"Staff added to '{ministry.name}'"
            }, 201
            
        except Ministry.DoesNotExist:
            return False, {"success": False, "error": "Ministry not found"}, 404
        except CustomUser.DoesNotExist:  # type: ignore[union-attr]
            return False, {"success": False, "error": "User not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Add staff error: {str(e)}")
            return False, {"success": False, "error": "Failed to add staff"}, 500

    # =========================================
    # Staff User Management
    # =========================================
    
    @staticmethod
    def create_staff_user(ministry_id, data, admin_user, request=None):
        """
        Create a new staff user for a ministry.
        Super admin creates credentials that ministry staff will use to login.
        
        Args:
            ministry_id: UUID of the ministry
            data: dict with email, password
            admin_user: Super admin creating the user
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            ministry = Ministry.objects.get(id=ministry_id)
            
            # Validate required fields
            email = data.get('email')
            password = data.get('password')
            
            if not email or not password:
                return False, {
                    "success": False,
                    "error": "Email and password are required"
                }, 400
            
            # Check if user already exists
            if CustomUser.objects.filter(email=email).exists():
                return False, {
                    "success": False,
                    "error": "A user with this email already exists"
                }, 400
            
            with transaction.atomic():
                # Create the user
                user = CustomUser.objects.create_user(
                    email=email,
                    password=password,
                    user_type='staff',
                    is_verified=True,  # Pre-verified by super admin
                    is_active=True,
                )
                
                # Add user to ministry
                MinistryMember.objects.create(
                    ministry=ministry,
                    user=user,
                    is_active=True
                )
            
            logger.info(f"[super_admin] Staff user {email} created for '{ministry.name}' by {admin_user.email}")
            
            return True, {
                "success": True,
                "data": {
                    "id": str(user.id),
                    "email": user.email,
                    "ministry": ministry.name,
                },
                "message": f"Staff user created for '{ministry.name}'"
            }, 201
            
        except Ministry.DoesNotExist:
            return False, {"success": False, "error": "Ministry not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Create staff error: {str(e)}")
            return False, {"success": False, "error": "Failed to create staff user"}, 500
    
    @staticmethod
    def get_ministry_users(ministry_id, request=None):
        """
        Get all users for a ministry.
        
        Args:
            ministry_id: UUID of the ministry
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            ministry = Ministry.objects.get(id=ministry_id)
            
            members = MinistryMember.objects.filter(ministry=ministry).select_related('user')
            
            users_data = []
            for member in members:
                users_data.append({
                    "id": str(member.user.id),
                    "email": member.user.email,
                    "is_active": member.is_active,
                    "joined_at": member.joined_at.isoformat(),
                })
            
            return True, {
                "success": True,
                "data": users_data,
                "count": len(users_data)
            }, 200
            
        except Ministry.DoesNotExist:
            return False, {"success": False, "error": "Ministry not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Get ministry staff error: {str(e)}")
            return False, {"success": False, "error": "Failed to fetch staff"}, 500
    
    @staticmethod
    def update_staff_user(ministry_id, user_id, data, admin_user):
        """
        Update a staff user's details.
        
        Args:
            ministry_id: UUID of the ministry
            user_id: UUID of the user to update
            data: dict with fields to update (is_active, password)
            admin_user: Super admin making the change
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            ministry = Ministry.objects.get(id=ministry_id)
            member = MinistryMember.objects.get(ministry=ministry, user_id=user_id)
            user = member.user
            
            with transaction.atomic():
                # Update user fields
                if 'is_active' in data:
                    user.is_active = data['is_active']
                    member.is_active = data['is_active']
                if 'password' in data and data['password']:
                    user.set_password(data['password'])
                
                user.save()
                member.save()
            
            logger.info(f"[super_admin] Staff user {user.email} updated by {admin_user.email}")
            
            return True, {
                "success": True,
                "data": {
                    "id": str(user.id),
                    "email": user.email,
                    "is_active": member.is_active,
                },
                "message": "Staff user updated"
            }, 200
            
        except Ministry.DoesNotExist:
            return False, {"success": False, "error": "Ministry not found"}, 404
        except MinistryMember.DoesNotExist:
            return False, {"success": False, "error": "User not found in this ministry"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Update staff error: {str(e)}")
            return False, {"success": False, "error": "Failed to update staff user"}, 500
    
    @staticmethod
    def delete_staff_user(ministry_id, user_id, admin_user):
        """
        Remove a staff user from a ministry (and optionally delete the user).
        
        Args:
            ministry_id: UUID of the ministry
            user_id: UUID of the user to remove
            admin_user: Super admin making the change
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            ministry = Ministry.objects.get(id=ministry_id)
            member = MinistryMember.objects.get(ministry=ministry, user_id=user_id)
            user = member.user
            email = user.email
            
            with transaction.atomic():
                # Remove membership
                member.delete()
                
                # If user has no other memberships, deactivate the account
                if not MinistryMember.objects.filter(user=user).exists():
                    user.is_active = False
                    user.save(update_fields=['is_active'])
            
            logger.info(f"[super_admin] Staff user {email} removed from '{ministry.name}' by {admin_user.email}")
            
            return True, {
                "success": True,
                "message": f"Staff user {email} removed from '{ministry.name}'"
            }, 200
            
        except Ministry.DoesNotExist:
            return False, {"success": False, "error": "Ministry not found"}, 404
        except MinistryMember.DoesNotExist:
            return False, {"success": False, "error": "User not found in this ministry"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Delete staff error: {str(e)}")
            return False, {"success": False, "error": "Failed to remove staff user"}, 500
