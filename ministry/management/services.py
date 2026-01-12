"""
Ministry Management Service

Handles ministry self-management operations and staff service management.
For ministry admins to manage their organization and staff services.
"""
import logging
import secrets
from datetime import timedelta
from django.db import transaction
from django.core.cache import cache
from django.utils import timezone

from ministry.models import Ministry, MinistryMember, MinistryInvitation, StaffService
from ministry.serializers import (
    MinistrySerializer, 
    MinistryMemberSerializer,
    MinistryInvitationSerializer,
    StaffServiceSerializer,
    StaffServiceCreateSerializer,
    StaffServiceUpdateSerializer
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


# ==================== Staff Service Management ====================

class StaffServiceManagementService:
    """
    Service for Ministry Admin to manage Staff Services.
    
    Staff Services are login accounts for staff members.
    Similar to how Super Admin manages Ministries, Ministry Admin manages Staff Services.
    """
    
    @staticmethod
    def get_list(ministry, request=None):
        """
        Get list of staff services for this ministry.
        
        Args:
            ministry: Current ministry
            request: HTTP request for context
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            staff_services = StaffService.objects.filter(
                ministry=ministry
            ).order_by('-created_at')
            
            context = {'request': request} if request else {}
            data = StaffServiceSerializer(staff_services, many=True, context=context).data
            
            logger.info(f"[ministry:{ministry.slug}] Listed {len(data)} staff services")
            
            return True, {
                "success": True,
                "data": data
            }, 200
            
        except Exception as e:
            logger.error(f"[ministry:{ministry.slug}] Staff services list error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch staff services"
            }, 500
    
    @staticmethod
    def create(ministry, data, request=None):
        """
        Create a new staff service.
        
        Args:
            ministry: Current ministry
            data: Staff service data (service_name, service_logo, staff_name, staff_image, email, password)
            request: HTTP request for context
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            # Validate input
            serializer = StaffServiceCreateSerializer(data=data)
            if not serializer.is_valid():
                return False, {
                    "success": False,
                    "error": "Validation failed",
                    "details": serializer.errors
                }, 400
            
            validated_data = serializer.validated_data  # type: ignore
            
            with transaction.atomic():
                # Create staff service
                staff_service = StaffService.objects.create(
                    ministry=ministry,
                    service_name=validated_data['service_name'],  # type: ignore
                    service_logo=validated_data.get('service_logo'),  # type: ignore
                    staff_name=validated_data['staff_name'],  # type: ignore
                    staff_image=validated_data.get('staff_image'),  # type: ignore
                    email=validated_data['email'],  # type: ignore
                    status=StaffService.Status.ACTIVE,
                    is_active=True
                )
                
                # Hash password
                staff_service.set_password(validated_data['password'])  # type: ignore
                staff_service.save(update_fields=['password'])
            
            logger.info(f"[ministry:{ministry.slug}] Staff service created: {staff_service.service_name} - {staff_service.staff_name} ({staff_service.email})")
            
            context = {'request': request} if request else {}
            return True, {
                "success": True,
                "data": StaffServiceSerializer(staff_service, context=context).data,
                "message": "Staff service created successfully"
            }, 201
            
        except Exception as e:
            logger.error(f"[ministry:{ministry.slug}] Create staff service error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to create staff service"
            }, 500
    
    @staticmethod
    def get_details(ministry, staff_service_id, request=None):
        """
        Get staff service details.
        
        Args:
            ministry: Current ministry
            staff_service_id: UUID of staff service
            request: HTTP request for context
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            staff_service = StaffService.objects.get(
                id=staff_service_id,
                ministry=ministry
            )
            
            context = {'request': request} if request else {}
            data = StaffServiceSerializer(staff_service, context=context).data
            
            return True, {"success": True, "data": data}, 200
            
        except StaffService.DoesNotExist:
            return False, {"success": False, "error": "Staff service not found"}, 404
        except Exception as e:
            logger.error(f"[ministry:{ministry.slug}] Staff service details error: {str(e)}")
            return False, {"success": False, "error": "Failed to fetch details"}, 500
    
    @staticmethod
    def update(ministry, staff_service_id, data, request=None):
        """
        Update staff service (service info, staff info, status).
        
        Args:
            ministry: Current ministry
            staff_service_id: UUID of staff service
            data: Update data (service_name, service_logo, staff_name, staff_image, status, is_active)
            request: HTTP request for context
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            staff_service = StaffService.objects.get(
                id=staff_service_id,
                ministry=ministry
            )
            
            # Validate input
            serializer = StaffServiceUpdateSerializer(data=data)
            if not serializer.is_valid():
                return False, {
                    "success": False,
                    "error": "Validation failed",
                    "details": serializer.errors
                }, 400
            
            validated_data = serializer.validated_data  # type: ignore
            
            with transaction.atomic():
                # Update allowed fields
                if 'service_name' in validated_data:  # type: ignore
                    staff_service.service_name = validated_data['service_name']  # type: ignore
                if 'service_logo' in validated_data:  # type: ignore
                    staff_service.service_logo = validated_data['service_logo']  # type: ignore
                if 'staff_name' in validated_data:  # type: ignore
                    staff_service.staff_name = validated_data['staff_name']  # type: ignore
                if 'staff_image' in validated_data:  # type: ignore
                    staff_service.staff_image = validated_data['staff_image']  # type: ignore
                if 'status' in validated_data:  # type: ignore
                    staff_service.status = validated_data['status']  # type: ignore
                if 'is_active' in validated_data:  # type: ignore
                    staff_service.is_active = validated_data['is_active']  # type: ignore
                
                staff_service.save()
            
            logger.info(f"[ministry:{ministry.slug}] Staff service updated: {staff_service.service_name} - {staff_service.staff_name}")
            
            context = {'request': request} if request else {}
            return True, {
                "success": True,
                "data": StaffServiceSerializer(staff_service, context=context).data,
                "message": "Staff service updated successfully"
            }, 200
            
        except StaffService.DoesNotExist:
            return False, {"success": False, "error": "Staff service not found"}, 404
        except Exception as e:
            logger.error(f"[ministry:{ministry.slug}] Update staff service error: {str(e)}")
            return False, {"success": False, "error": "Failed to update staff service"}, 500
    
    @staticmethod
    def toggle_status(ministry, staff_service_id, new_status=None):
        """
        Toggle service status between ACTIVE and PAUSED.
        Quick method for attendance-based service control.
        
        Args:
            ministry: Current ministry
            staff_service_id: UUID of staff service
            new_status: 'active' or 'paused' (optional - auto-toggles if None)
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            staff_service = StaffService.objects.get(
                id=staff_service_id,
                ministry=ministry
            )
            
            # Auto-toggle if no status provided
            if new_status is None:
                new_status = 'paused' if staff_service.status == 'active' else 'active'
            
            # Update status
            staff_service.status = new_status
            staff_service.save(update_fields=['status'])
            
            # Serialize updated staff service
            from ministry.serializers import StaffServiceSerializer
            serializer = StaffServiceSerializer(staff_service)
            
            logger.info(f"[ministry:{ministry.slug}] Service status changed to {new_status}: {staff_service.service_name}")
            
            return True, {
                "success": True,
                "data": serializer.data,
                "message": f"Service status changed to {new_status}"
            }, 200
            
        except StaffService.DoesNotExist:
            return False, {"success": False, "error": "Staff service not found"}, 404
        except Exception as e:
            logger.error(f"[ministry:{ministry.slug}] Toggle status error: {str(e)}")
            return False, {"success": False, "error": "Failed to toggle status"}, 500
    
    @staticmethod
    def reset_password(ministry, staff_service_id, new_password):
        """
        Reset staff service password.
        
        Args:
            ministry: Current ministry
            staff_service_id: UUID of staff service
            new_password: New password
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            staff_service = StaffService.objects.get(
                id=staff_service_id,
                ministry=ministry
            )
            
            # Hash and set new password
            staff_service.set_password(new_password)
            staff_service.save(update_fields=['password'])
            
            logger.info(f"[ministry:{ministry.slug}] Password reset for staff service: {staff_service.service_name} - {staff_service.staff_name}")
            
            return True, {
                "success": True,
                "message": "Password reset successfully"
            }, 200
            
        except StaffService.DoesNotExist:
            return False, {"success": False, "error": "Staff service not found"}, 404
        except Exception as e:
            logger.error(f"[ministry:{ministry.slug}] Reset password error: {str(e)}")
            return False, {"success": False, "error": "Failed to reset password"}, 500
    
    @staticmethod
    def delete(ministry, staff_service_id):
        """
        Permanently delete staff service (hard delete).
        
        Args:
            ministry: Current ministry
            staff_service_id: UUID of staff service
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            staff_service = StaffService.objects.get(
                id=staff_service_id,
                ministry=ministry
            )
            
            service_name = staff_service.service_name
            staff_name = staff_service.staff_name
            service_email = staff_service.email
            
            # Permanently delete
            staff_service.delete()
            
            logger.info(f"[ministry:{ministry.slug}] Staff service deleted: {service_name} - {staff_name} ({service_email})")
            
            return True, {
                "success": True,
                "message": "Staff service deleted permanently"
            }, 200
            
        except StaffService.DoesNotExist:
            return False, {"success": False, "error": "Staff service not found"}, 404
        except Exception as e:
            logger.error(f"[ministry:{ministry.slug}] Delete staff service error: {str(e)}")
            return False, {"success": False, "error": "Failed to delete staff service"}, 500
            logger.error(f"[ministry:{ministry.slug}] Cancel invitation error: {str(e)}")
            return False, {"success": False, "error": "Failed to cancel invitation"}, 500
