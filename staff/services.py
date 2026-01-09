"""
Staff Services

Business logic for staff management.
Used by ministry admins to manage their staff.
"""
import logging
from django.db import transaction
from django.core.cache import cache
from django.contrib.auth import get_user_model

from .models import Staff
from .serializers import StaffDetailSerializer, StaffPublicSerializer

CustomUser = get_user_model()
logger = logging.getLogger(__name__)


class StaffService:
    """Service for staff management by ministry admins"""
    
    @staticmethod
    def get_staff_list(ministry, request=None):
        """
        Get all staff for a ministry.
        
        Args:
            ministry: The ministry to get staff for
            request: HTTP request for context
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            # Get all staff for services in this ministry
            staff = Staff.objects.filter(
                service__ministry=ministry,
                is_deleted=False
            ).select_related('user', 'service').order_by('name')
            
            context = {'request': request} if request else {}
            data = StaffPublicSerializer(staff, many=True, context=context).data
            
            return True, {
                "success": True,
                "data": data,
                "count": len(data)
            }, 200
            
        except Exception as e:
            logger.error(f"[staff] List error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch staff list"
            }, 500
    
    @staticmethod
    def get_staff_detail(staff_id, ministry, request=None):
        """Get detailed staff information"""
        try:
            staff = Staff.objects.get(
                id=staff_id,
                service__ministry=ministry,
                is_deleted=False
            )
            
            context = {'request': request} if request else {}
            data = StaffDetailSerializer(staff, context=context).data
            
            return True, {"success": True, "data": data}, 200
            
        except Staff.DoesNotExist:
            return False, {"success": False, "error": "Staff not found"}, 404
        except Exception as e:
            logger.error(f"[staff] Detail error: {str(e)}")
            return False, {"success": False, "error": "Failed to fetch staff"}, 500
    
    @staticmethod
    def create_staff(data, ministry, created_by, request=None):
        """
        Create a new staff member.
        
        Args:
            data: dict with name, email, password, contact, service_id, image
            ministry: The ministry (for validation)
            created_by: The user creating the staff
            request: HTTP request for context
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            from services.models import Service
            
            # Validate service belongs to this ministry
            service = Service.objects.filter(
                id=data['service_id'],
                ministry=ministry,
                is_active=True
            ).first()
            
            if not service:
                return False, {
                    "success": False,
                    "error": "Service not found or doesn't belong to this ministry"
                }, 400
            
            with transaction.atomic():
                # Create user account
                user = CustomUser.objects.create_user(  # type: ignore[call-arg]
                    email=data['email'].lower(),
                    password=data['password'],
                    user_type='staff',
                    is_verified=True,
                    is_active=True
                )
                
                # Create staff profile
                staff = Staff.objects.create(
                    user=user,
                    service=service,
                    name=data['name'],
                    contact=data['contact'],
                    image=data.get('image')
                )
            
            logger.info(f"[staff] Created {staff.name} ({user.email}) for service {service.name} by {created_by.email}")
            
            context = {'request': request} if request else {}
            return True, {
                "success": True,
                "data": StaffDetailSerializer(staff, context=context).data,
                "message": f"Staff '{staff.name}' created successfully"
            }, 201
            
        except Exception as e:
            logger.error(f"[staff] Create error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to create staff"
            }, 500
    
    @staticmethod
    def update_staff(staff_id, data, ministry, updated_by, request=None):
        """Update staff details"""
        try:
            staff = Staff.objects.get(
                id=staff_id,
                service__ministry=ministry,
                is_deleted=False
            )
            
            with transaction.atomic():
                # Update staff fields
                if 'name' in data:
                    staff.name = data['name']
                if 'contact' in data:
                    staff.contact = data['contact']
                if 'image' in data:
                    staff.image = data['image']
                if 'is_active' in data:
                    staff.is_active = data['is_active']
                    staff.user.is_active = data['is_active']
                    staff.user.save(update_fields=['is_active'])
                
                # Update password if provided
                if 'password' in data and data['password']:
                    staff.user.set_password(data['password'])
                    staff.user.save()
                
                staff.save()
            
            logger.info(f"[staff] Updated {staff.name} by {updated_by.email}")
            
            context = {'request': request} if request else {}
            return True, {
                "success": True,
                "data": StaffDetailSerializer(staff, context=context).data,
                "message": "Staff updated successfully"
            }, 200
            
        except Staff.DoesNotExist:
            return False, {"success": False, "error": "Staff not found"}, 404
        except Exception as e:
            logger.error(f"[staff] Update error: {str(e)}")
            return False, {"success": False, "error": "Failed to update staff"}, 500
    
    @staticmethod
    def delete_staff(staff_id, ministry, deleted_by):
        """Soft delete a staff member"""
        try:
            staff = Staff.objects.get(
                id=staff_id,
                service__ministry=ministry,
                is_deleted=False
            )
            
            staff_name = staff.name
            staff.soft_delete(deleted_by=deleted_by)
            
            logger.info(f"[staff] Deleted {staff_name} by {deleted_by.email}")
            
            return True, {
                "success": True,
                "message": f"Staff '{staff_name}' deleted"
            }, 200
            
        except Staff.DoesNotExist:
            return False, {"success": False, "error": "Staff not found"}, 404
        except Exception as e:
            logger.error(f"[staff] Delete error: {str(e)}")
            return False, {"success": False, "error": "Failed to delete staff"}, 500
    
    @staticmethod
    def reset_password(staff_id, new_password, ministry, reset_by):
        """Reset staff password"""
        try:
            staff = Staff.objects.get(
                id=staff_id,
                service__ministry=ministry,
                is_deleted=False
            )
            
            staff.user.set_password(new_password)
            staff.user.save()
            
            logger.info(f"[staff] Password reset for {staff.name} by {reset_by.email}")
            
            return True, {
                "success": True,
                "message": f"Password reset for '{staff.name}'"
            }, 200
            
        except Staff.DoesNotExist:
            return False, {"success": False, "error": "Staff not found"}, 404
        except Exception as e:
            logger.error(f"[staff] Password reset error: {str(e)}")
            return False, {"success": False, "error": "Failed to reset password"}, 500
