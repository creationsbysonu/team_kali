"""
Tenant Management Service

Handles tenant self-management operations.
For tenant admins to manage their own organization.
"""
import logging
import secrets
from datetime import timedelta
from django.db import transaction
from django.core.cache import cache
from django.utils import timezone

from tenants.models import Tenant, TenantMember, TenantInvitation
from tenants.serializers import (
    TenantSerializer, 
    TenantMemberSerializer,
    TenantInvitationSerializer
)

logger = logging.getLogger(__name__)


class TenantManagementService:
    """Service for tenant self-management"""
    
    @staticmethod
    def get_details(tenant, request=None):
        """
        Get tenant details for members.
        
        Args:
            tenant: Current tenant
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            context = {'request': request} if request else {}
            data = TenantSerializer(tenant, context=context).data
            
            return True, {"success": True, "data": data}, 200
            
        except Exception as e:
            logger.error(f"[tenant:{tenant.slug}] Details error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch details"
            }, 500
    
    @staticmethod
    def update_details(tenant, data, user, request=None):
        """
        Update tenant details (admin only).
        
        Args:
            tenant: Current tenant
            data: Update data
            user: User making the change
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            with transaction.atomic():
                # Update allowed fields
                allowed_fields = ['name', 'description', 'email', 'phone', 'address', 'website']
                for field in allowed_fields:
                    if field in data:
                        setattr(tenant, field, data[field])
                
                # Handle logo separately
                if 'logo' in data:
                    tenant.logo = data['logo']
                
                tenant.save()
            
            # Clear caches
            cache.delete("public_tenants_list")
            cache.delete(f"public_tenant_{tenant.slug}")
            
            logger.info(f"[tenant:{tenant.slug}] Details updated by {user.email}")
            
            context = {'request': request} if request else {}
            return True, {
                "success": True,
                "data": TenantSerializer(tenant, context=context).data,
                "message": "Details updated successfully"
            }, 200
            
        except Exception as e:
            logger.error(f"[tenant:{tenant.slug}] Update error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to update details"
            }, 500
    
    @staticmethod
    def update_settings(tenant, settings_data, user):
        """
        Update tenant settings (admin only).
        
        Args:
            tenant: Current tenant
            settings_data: Settings to update
            user: User making the change
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            with transaction.atomic():
                tenant.settings.update(settings_data)
                tenant.save(update_fields=['settings', 'updated_at'])
            
            logger.info(f"[tenant:{tenant.slug}] Settings updated by {user.email}")
            
            return True, {
                "success": True,
                "data": {"settings": tenant.settings},
                "message": "Settings updated successfully"
            }, 200
            
        except Exception as e:
            logger.error(f"[tenant:{tenant.slug}] Settings update error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to update settings"
            }, 500
    
    @staticmethod
    def get_members(tenant, request=None):
        """Get list of tenant members"""
        try:
            members = TenantMember.objects.filter(
                tenant=tenant
            ).select_related('user').order_by('-joined_at')
            
            context = {'request': request} if request else {}
            data = TenantMemberSerializer(members, many=True, context=context).data
            
            return True, {
                "success": True,
                "data": data,
                "count": len(data)
            }, 200
            
        except Exception as e:
            logger.error(f"[tenant:{tenant.slug}] Members list error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch members"
            }, 500
    
    @staticmethod
    def remove_member(tenant, member_id, removed_by):
        """Remove a staff member from ministry"""
        try:
            member = TenantMember.objects.get(
                id=member_id,
                tenant=tenant
            )
            
            # Can't remove yourself
            if member.user.id == removed_by.id:
                return False, {
                    "success": False,
                    "error": "You cannot remove yourself"
                }, 400
            
            email = member.user.email
            member.delete()
            
            logger.info(f"[ministry:{tenant.slug}] Staff {email} removed by {removed_by.email}")
            
            return True, {
                "success": True,
                "message": f"Staff member {email} removed"
            }, 200
            
        except TenantMember.DoesNotExist:
            return False, {"success": False, "error": "Staff member not found"}, 404
        except Exception as e:
            logger.error(f"[ministry:{tenant.slug}] Remove staff error: {str(e)}")
            return False, {"success": False, "error": "Failed to remove staff member"}, 500
    
    @staticmethod
    def create_invitation(tenant, email, invited_by):
        """Create an invitation to join ministry"""
        try:
            email = email.lower().strip()
            
            # Check if already a member
            from authentication.models import CustomUser
            existing_user = CustomUser.objects.filter(email=email).first()
            if existing_user:
                if TenantMember.objects.filter(tenant=tenant, user=existing_user).exists():
                    return False, {
                        "success": False,
                        "error": "User is already a staff member"
                    }, 400
            
            # Check for pending invitation
            pending = TenantInvitation.objects.filter(
                tenant=tenant,
                email=email,
                status=TenantInvitation.Status.PENDING
            ).first()
            
            if pending:
                return False, {
                    "success": False,
                    "error": "An invitation is already pending for this email"
                }, 400
            
            # Create invitation
            with transaction.atomic():
                invitation = TenantInvitation.objects.create(
                    tenant=tenant,
                    email=email,
                    invited_by=invited_by,
                    token=secrets.token_urlsafe(32),
                    expires_at=timezone.now() + timedelta(days=7)
                )
            
            # TODO: Send invitation email via Celery task
            logger.info(f"[ministry:{tenant.slug}] Invitation created for {email} by {invited_by.email}")
            
            return True, {
                "success": True,
                "data": TenantInvitationSerializer(invitation).data,
                "message": f"Invitation sent to {email}"
            }, 201
            
        except Exception as e:
            logger.error(f"[ministry:{tenant.slug}] Create invitation error: {str(e)}")
            return False, {"success": False, "error": "Failed to create invitation"}, 500
    
    @staticmethod
    def get_invitations(tenant, request=None):
        """Get list of pending invitations"""
        try:
            invitations = TenantInvitation.objects.filter(
                tenant=tenant,
                status=TenantInvitation.Status.PENDING
            ).order_by('-created_at')
            
            context = {'request': request} if request else {}
            data = TenantInvitationSerializer(invitations, many=True, context=context).data
            
            return True, {
                "success": True,
                "data": data,
                "count": len(data)
            }, 200
            
        except Exception as e:
            logger.error(f"[ministry:{tenant.slug}] Invitations list error: {str(e)}")
            return False, {"success": False, "error": "Failed to fetch invitations"}, 500
    
    @staticmethod
    def cancel_invitation(tenant, invitation_id, cancelled_by):
        """Cancel a pending invitation"""
        try:
            invitation = TenantInvitation.objects.get(
                id=invitation_id,
                tenant=tenant,
                status=TenantInvitation.Status.PENDING
            )
            
            invitation.status = TenantInvitation.Status.CANCELLED
            invitation.save(update_fields=['status'])
            
            logger.info(f"[ministry:{tenant.slug}] Invitation to {invitation.email} cancelled by {cancelled_by.email}")
            
            return True, {
                "success": True,
                "message": "Invitation cancelled"
            }, 200
            
        except TenantInvitation.DoesNotExist:
            return False, {"success": False, "error": "Invitation not found"}, 404
        except Exception as e:
            logger.error(f"[ministry:{tenant.slug}] Cancel invitation error: {str(e)}")
            return False, {"success": False, "error": "Failed to cancel invitation"}, 500
