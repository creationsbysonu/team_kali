"""
Ministry Management Service

Handles ministry self-management operations.
For ministry admins to manage their own organization.
"""
import logging
import secrets
from datetime import timedelta
from django.db import transaction
from django.core.cache import cache
from django.utils import timezone

from ministry.models import Ministry, MinistryMember, MinistryInvitation
from ministry.serializers import (
    MinistrySerializer, 
    MinistryMemberSerializer,
    MinistryInvitationSerializer
)

logger = logging.getLogger(__name__)


class MinistryManagementService:
    """Service for ministry self-management"""
    
    @staticmethod
    def get_details(ministry, request=None):
        """
        Get ministry details for members.
        
        Args:
            ministry: Current ministry
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            context = {'request': request} if request else {}
            data = MinistrySerializer(ministry, context=context).data
            
            return True, {"success": True, "data": data}, 200
            
        except Exception as e:
            logger.error(f"[ministry:{ministry.slug}] Details error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch details"
            }, 500
    
    @staticmethod
    def update_details(ministry, data, user, request=None):
        """
        Update ministry details (admin only).
        
        Args:
            ministry: Current ministry
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
                        setattr(ministry, field, data[field])
                
                # Handle logo separately
                if 'logo' in data:
                    ministry.logo = data['logo']
                
                ministry.save()
            
            # Clear caches
            cache.delete("public_ministrys_list")
            cache.delete(f"public_ministry_{ministry.slug}")
            
            logger.info(f"[ministry:{ministry.slug}] Details updated by {user.email}")
            
            context = {'request': request} if request else {}
            return True, {
                "success": True,
                "data": MinistrySerializer(ministry, context=context).data,
                "message": "Details updated successfully"
            }, 200
            
        except Exception as e:
            logger.error(f"[ministry:{ministry.slug}] Update error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to update details"
            }, 500
    
    @staticmethod
    def update_settings(ministry, settings_data, user):
        """
        Update ministry settings (admin only).
        
        Args:
            ministry: Current ministry
            settings_data: Settings to update
            user: User making the change
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            with transaction.atomic():
                ministry.settings.update(settings_data)
                ministry.save(update_fields=['settings', 'updated_at'])
            
            logger.info(f"[ministry:{ministry.slug}] Settings updated by {user.email}")
            
            return True, {
                "success": True,
                "data": {"settings": ministry.settings},
                "message": "Settings updated successfully"
            }, 200
            
        except Exception as e:
            logger.error(f"[ministry:{ministry.slug}] Settings update error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to update settings"
            }, 500
    
    @staticmethod
    def get_members(ministry, request=None):
        """Get list of ministry members"""
        try:
            members = MinistryMember.objects.filter(
                ministry=ministry
            ).select_related('user').order_by('-joined_at')
            
            context = {'request': request} if request else {}
            data = MinistryMemberSerializer(members, many=True, context=context).data
            
            return True, {
                "success": True,
                "data": data,
                "count": len(data)
            }, 200
            
        except Exception as e:
            logger.error(f"[ministry:{ministry.slug}] Members list error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch members"
            }, 500
    
    @staticmethod
    def remove_member(ministry, member_id, removed_by):
        """Remove a staff member from ministry"""
        try:
            member = MinistryMember.objects.get(
                id=member_id,
                ministry=ministry
            )
            
            # Can't remove yourself
            if member.user.id == removed_by.id:
                return False, {
                    "success": False,
                    "error": "You cannot remove yourself"
                }, 400
            
            email = member.user.email
            member.delete()
            
            logger.info(f"[ministry:{ministry.slug}] Staff {email} removed by {removed_by.email}")
            
            return True, {
                "success": True,
                "message": f"Staff member {email} removed"
            }, 200
            
        except MinistryMember.DoesNotExist:
            return False, {"success": False, "error": "Staff member not found"}, 404
        except Exception as e:
            logger.error(f"[ministry:{ministry.slug}] Remove staff error: {str(e)}")
            return False, {"success": False, "error": "Failed to remove staff member"}, 500
    
    @staticmethod
    def create_invitation(ministry, email, invited_by):
        """Create an invitation to join ministry"""
        try:
            email = email.lower().strip()
            
            # Check if already a member
            from authentication.models import CustomUser
            existing_user = CustomUser.objects.filter(email=email).first()
            if existing_user:
                if MinistryMember.objects.filter(ministry=ministry, user=existing_user).exists():
                    return False, {
                        "success": False,
                        "error": "User is already a staff member"
                    }, 400
            
            # Check for pending invitation
            pending = MinistryInvitation.objects.filter(
                ministry=ministry,
                email=email,
                status=MinistryInvitation.Status.PENDING
            ).first()
            
            if pending:
                return False, {
                    "success": False,
                    "error": "An invitation is already pending for this email"
                }, 400
            
            # Create invitation
            with transaction.atomic():
                invitation = MinistryInvitation.objects.create(
                    ministry=ministry,
                    email=email,
                    invited_by=invited_by,
                    token=secrets.token_urlsafe(32),
                    expires_at=timezone.now() + timedelta(days=7)
                )
            
            # TODO: Send invitation email via Celery task
            logger.info(f"[ministry:{ministry.slug}] Invitation created for {email} by {invited_by.email}")
            
            return True, {
                "success": True,
                "data": MinistryInvitationSerializer(invitation).data,
                "message": f"Invitation sent to {email}"
            }, 201
            
        except Exception as e:
            logger.error(f"[ministry:{ministry.slug}] Create invitation error: {str(e)}")
            return False, {"success": False, "error": "Failed to create invitation"}, 500
    
    @staticmethod
    def get_invitations(ministry, request=None):
        """Get list of pending invitations"""
        try:
            invitations = MinistryInvitation.objects.filter(
                ministry=ministry,
                status=MinistryInvitation.Status.PENDING
            ).order_by('-created_at')
            
            context = {'request': request} if request else {}
            data = MinistryInvitationSerializer(invitations, many=True, context=context).data
            
            return True, {
                "success": True,
                "data": data,
                "count": len(data)
            }, 200
            
        except Exception as e:
            logger.error(f"[ministry:{ministry.slug}] Invitations list error: {str(e)}")
            return False, {"success": False, "error": "Failed to fetch invitations"}, 500
    
    @staticmethod
    def cancel_invitation(ministry, invitation_id, cancelled_by):
        """Cancel a pending invitation"""
        try:
            invitation = MinistryInvitation.objects.get(
                id=invitation_id,
                ministry=ministry,
                status=MinistryInvitation.Status.PENDING
            )
            
            invitation.status = MinistryInvitation.Status.CANCELLED
            invitation.save(update_fields=['status'])
            
            logger.info(f"[ministry:{ministry.slug}] Invitation to {invitation.email} cancelled by {cancelled_by.email}")
            
            return True, {
                "success": True,
                "message": "Invitation cancelled"
            }, 200
            
        except MinistryInvitation.DoesNotExist:
            return False, {"success": False, "error": "Invitation not found"}, 404
        except Exception as e:
            logger.error(f"[ministry:{ministry.slug}] Cancel invitation error: {str(e)}")
            return False, {"success": False, "error": "Failed to cancel invitation"}, 500
