"""
Super Admin Tenant Service

Handles system-wide tenant management.
Only for super admins.
"""
import logging
from typing import Any, Dict
from django.db import transaction
from django.core.cache import cache
from django.contrib.auth import get_user_model
from django.utils import timezone

from tenants.models import Tenant, TenantMember
from tenants.serializers import TenantAdminSerializer, TenantCreateSerializer

CustomUser = get_user_model()

logger = logging.getLogger(__name__)


class SuperAdminTenantService:
    """Service for super admin tenant management"""
    
    @staticmethod
    def get_list(filters=None, request=None):
        """
        Get list of all tenants with filtering.
        
        Args:
            filters: dict with status, search, etc.
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            queryset = Tenant.objects.all()
            
            if filters:
                if status := filters.get('status'):
                    queryset = queryset.filter(status=status)
                if search := filters.get('search'):
                    queryset = queryset.filter(name__icontains=search)
            
            queryset = queryset.order_by('-created_at')
            
            context = {'request': request} if request else {}
            data = TenantAdminSerializer(queryset, many=True, context=context).data
            
            return True, {
                "success": True,
                "data": data,
                "count": len(data)
            }, 200
            
        except Exception as e:
            logger.error(f"[super_admin] Tenant list error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch tenants"
            }, 500
    
    @staticmethod
    def get_detail(tenant_id, request=None):
        """Get detailed ministry information"""
        try:
            tenant = Tenant.objects.get(id=tenant_id)
            
            context = {'request': request} if request else {}
            serializer_data = TenantAdminSerializer(tenant, context=context).data
            
            # Add additional stats
            data: Dict[str, Any] = dict(serializer_data)
            data['stats'] = {
                'total_staff': TenantMember.objects.filter(tenant=tenant).count(),
                'active_staff': TenantMember.objects.filter(tenant=tenant, is_active=True).count(),
            }
            
            return True, {"success": True, "data": data}, 200
            
        except Tenant.DoesNotExist:
            return False, {"success": False, "error": "Ministry not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Ministry detail error: {str(e)}")
            return False, {"success": False, "error": "Failed to fetch ministry"}, 500
    
    @staticmethod
    def create_tenant(data, admin_user, request=None):
        """
        Create a new tenant (ministry).
        
        Args:
            data: Tenant data
            admin_user: Super admin creating the tenant
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            serializer = TenantCreateSerializer(data=data)
            if not serializer.is_valid():
                return False, {
                    "success": False,
                    "error": serializer.errors
                }, 400
            
            with transaction.atomic():
                validated = serializer.validated_data
                tenant = Tenant.objects.create(**validated)  # type: ignore[arg-type]
            
            # Clear caches
            cache.delete("public_tenants_list")
            
            logger.info(f"[super_admin] Tenant '{tenant.name}' created by {admin_user.email}")
            
            context = {'request': request} if request else {}
            return True, {
                "success": True,
                "data": TenantAdminSerializer(tenant, context=context).data,
                "message": f"Ministry '{tenant.name}' created successfully"
            }, 201
            
        except Exception as e:
            logger.error(f"[super_admin] Create tenant error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to create ministry"
            }, 500
    
    @staticmethod
    def update_tenant(tenant_id, data, admin_user, request=None):
        """Update tenant details"""
        try:
            tenant = Tenant.objects.get(id=tenant_id)
            
            with transaction.atomic():
                for field, value in data.items():
                    if hasattr(tenant, field) and field not in ['id', 'created_at']:
                        setattr(tenant, field, value)
                tenant.save()
            
            # Clear caches
            cache.delete("public_tenants_list")
            cache.delete(f"public_tenant_{tenant.slug}")
            
            logger.info(f"[super_admin] Tenant '{tenant.name}' updated by {admin_user.email}")
            
            context = {'request': request} if request else {}
            return True, {
                "success": True,
                "data": TenantAdminSerializer(tenant, context=context).data,
                "message": "Ministry updated successfully"
            }, 200
            
        except Tenant.DoesNotExist:
            return False, {"success": False, "error": "Tenant not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Update tenant error: {str(e)}")
            return False, {"success": False, "error": "Failed to update ministry"}, 500
    
    @staticmethod
    def activate_tenant(tenant_id, admin_user):
        """Activate a pending/suspended tenant"""
        try:
            tenant = Tenant.objects.get(id=tenant_id)
            
            if tenant.status == Tenant.Status.ACTIVE:
                return False, {
                    "success": False,
                    "error": "Tenant is already active"
                }, 400
            
            with transaction.atomic():
                tenant.status = Tenant.Status.ACTIVE
                tenant.save(update_fields=['status', 'updated_at'])
            
            cache.delete("public_tenants_list")
            
            logger.info(f"[super_admin] Tenant '{tenant.name}' activated by {admin_user.email}")
            
            return True, {
                "success": True,
                "message": f"Ministry '{tenant.name}' activated"
            }, 200
            
        except Tenant.DoesNotExist:
            return False, {"success": False, "error": "Tenant not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Activate tenant error: {str(e)}")
            return False, {"success": False, "error": "Failed to activate ministry"}, 500
    
    @staticmethod
    def suspend_tenant(tenant_id, admin_user, reason=None):
        """Suspend a tenant"""
        try:
            tenant = Tenant.objects.get(id=tenant_id)
            
            if tenant.status == Tenant.Status.SUSPENDED:
                return False, {
                    "success": False,
                    "error": "Tenant is already suspended"
                }, 400
            
            with transaction.atomic():
                tenant.status = Tenant.Status.SUSPENDED
                if reason:
                    tenant.settings['suspension_reason'] = reason
                    tenant.settings['suspended_at'] = str(timezone.now())
                    tenant.settings['suspended_by'] = str(admin_user.id)
                tenant.save()
            
            cache.delete("public_tenants_list")
            cache.delete(f"public_tenant_{tenant.slug}")
            
            logger.info(f"[super_admin] Tenant '{tenant.name}' suspended by {admin_user.email}. Reason: {reason}")
            
            return True, {
                "success": True,
                "message": f"Ministry '{tenant.name}' suspended"
            }, 200
            
        except Tenant.DoesNotExist:
            return False, {"success": False, "error": "Tenant not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Suspend tenant error: {str(e)}")
            return False, {"success": False, "error": "Failed to suspend ministry"}, 500
    
    @staticmethod
    def delete_tenant(tenant_id, admin_user):
        """Delete a tenant (use with caution)"""
        try:
            tenant = Tenant.objects.get(id=tenant_id)
            tenant_name = tenant.name
            tenant_slug = tenant.slug
            
            with transaction.atomic():
                tenant.delete()
            
            cache.delete("public_tenants_list")
            cache.delete(f"public_tenant_{tenant_slug}")
            
            logger.warning(f"[super_admin] Tenant '{tenant_name}' DELETED by {admin_user.email}")
            
            return True, {
                "success": True,
                "message": f"Ministry '{tenant_name}' deleted"
            }, 200
            
        except Tenant.DoesNotExist:
            return False, {"success": False, "error": "Tenant not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Delete tenant error: {str(e)}")
            return False, {"success": False, "error": "Failed to delete ministry"}, 500
    
    @staticmethod
    def add_staff_to_tenant(tenant_id, user_id, admin_user):
        """Add staff to a ministry"""
        try:
            tenant = Tenant.objects.get(id=tenant_id)
            
            from authentication.models import CustomUser
            user = CustomUser.objects.get(id=user_id)
            
            # Check if already a member
            if TenantMember.objects.filter(tenant=tenant, user=user).exists():
                return False, {
                    "success": False,
                    "error": "User is already a staff member of this ministry"
                }, 400
            
            with transaction.atomic():
                TenantMember.objects.create(
                    tenant=tenant,
                    user=user,
                    is_active=True
                )
            
            logger.info(f"[super_admin] User {user.email} added as staff to '{tenant.name}' by {admin_user.email}")
            
            return True, {
                "success": True,
                "message": f"Staff added to '{tenant.name}'"
            }, 201
            
        except Tenant.DoesNotExist:
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
    def create_staff_user(tenant_id, data, admin_user, request=None):
        """
        Create a new staff user for a ministry.
        Super admin creates credentials that ministry staff will use to login.
        
        Args:
            tenant_id: UUID of the ministry
            data: dict with email, password
            admin_user: Super admin creating the user
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            tenant = Tenant.objects.get(id=tenant_id)
            
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
                TenantMember.objects.create(
                    tenant=tenant,
                    user=user,
                    is_active=True
                )
            
            logger.info(f"[super_admin] Staff user {email} created for '{tenant.name}' by {admin_user.email}")
            
            return True, {
                "success": True,
                "data": {
                    "id": str(user.id),
                    "email": user.email,
                    "ministry": tenant.name,
                },
                "message": f"Staff user created for '{tenant.name}'"
            }, 201
            
        except Tenant.DoesNotExist:
            return False, {"success": False, "error": "Ministry not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Create staff error: {str(e)}")
            return False, {"success": False, "error": "Failed to create staff user"}, 500
    
    @staticmethod
    def get_tenant_users(tenant_id, request=None):
        """
        Get all users for a tenant.
        
        Args:
            tenant_id: UUID of the ministry
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            tenant = Tenant.objects.get(id=tenant_id)
            
            members = TenantMember.objects.filter(tenant=tenant).select_related('user')
            
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
            
        except Tenant.DoesNotExist:
            return False, {"success": False, "error": "Ministry not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Get ministry staff error: {str(e)}")
            return False, {"success": False, "error": "Failed to fetch staff"}, 500
    
    @staticmethod
    def update_staff_user(tenant_id, user_id, data, admin_user):
        """
        Update a staff user's details.
        
        Args:
            tenant_id: UUID of the ministry
            user_id: UUID of the user to update
            data: dict with fields to update (is_active, password)
            admin_user: Super admin making the change
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            tenant = Tenant.objects.get(id=tenant_id)
            member = TenantMember.objects.get(tenant=tenant, user_id=user_id)
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
            
        except Tenant.DoesNotExist:
            return False, {"success": False, "error": "Ministry not found"}, 404
        except TenantMember.DoesNotExist:
            return False, {"success": False, "error": "User not found in this ministry"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Update staff error: {str(e)}")
            return False, {"success": False, "error": "Failed to update staff user"}, 500
    
    @staticmethod
    def delete_staff_user(tenant_id, user_id, admin_user):
        """
        Remove a staff user from a tenant (and optionally delete the user).
        
        Args:
            tenant_id: UUID of the tenant
            user_id: UUID of the user to remove
            admin_user: Super admin making the change
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            tenant = Tenant.objects.get(id=tenant_id)
            member = TenantMember.objects.get(tenant=tenant, user_id=user_id)
            user = member.user
            email = user.email
            
            with transaction.atomic():
                # Remove membership
                member.delete()
                
                # If user has no other memberships, deactivate the account
                if not TenantMember.objects.filter(user=user).exists():
                    user.is_active = False
                    user.save(update_fields=['is_active'])
            
            logger.info(f"[super_admin] Staff user {email} removed from '{tenant.name}' by {admin_user.email}")
            
            return True, {
                "success": True,
                "message": f"Staff user {email} removed from '{tenant.name}'"
            }, 200
            
        except Tenant.DoesNotExist:
            return False, {"success": False, "error": "Tenant not found"}, 404
        except TenantMember.DoesNotExist:
            return False, {"success": False, "error": "User not found in this ministry"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Delete staff error: {str(e)}")
            return False, {"success": False, "error": "Failed to remove staff user"}, 500
