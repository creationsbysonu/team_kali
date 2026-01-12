"""
Super Admin Place Service

Handles system-wide place management.
Only for super admins.

Places: Add, Edit, Delete (hard delete only - no soft delete)
"""
import logging
from django.db import transaction
from django.core.cache import cache
from django.utils.text import slugify

from places.models import Place
from ministry.models import Ministry

logger = logging.getLogger(__name__)


class SuperAdminPlaceService:
    """Service for super admin place management"""
    
    CACHE_KEY_LIST = "admin_places_list"
    CACHE_KEY_PUBLIC = "public_active_places"
    
    @staticmethod
    def get_list(filters=None, request=None):
        """
        Get list of all places with filtering.
        
        Args:
            filters: dict with search, is_active, etc.
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            # Use all_objects to include all places (no soft delete for places)
            queryset = Place.objects.all()
            
            if filters:
                if search := filters.get('search'):
                    queryset = queryset.filter(name__icontains=search)
                if is_active := filters.get('is_active'):
                    if is_active.lower() == 'true':
                        queryset = queryset.filter(is_active=True)
                    elif is_active.lower() == 'false':
                        queryset = queryset.filter(is_active=False)
            
            queryset = queryset.order_by('name')
            
            data = []
            for place in queryset:
                # Count ministries in this place
                ministry_count = Ministry.objects.filter(place=place, is_deleted=False).count()
                
                data.append({
                    'id': str(place.id),
                    'name': place.name,
                    'slug': place.slug,
                    'is_active': place.is_active,
                    'ministry_count': ministry_count,
                    'created_at': place.created_at.isoformat(),
                    'updated_at': place.updated_at.isoformat(),
                })
            
            return True, {
                "success": True,
                "data": data,
                "count": len(data)
            }, 200
            
        except Exception as e:
            logger.error(f"[super_admin] Place list error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch places"
            }, 500
    
    @staticmethod
    def get_detail(place_id, request=None):
        """Get detailed place information"""
        try:
            place = Place.objects.get(id=place_id)
            
            # Get ministry stats for this place
            total_ministries = Ministry.objects.filter(place=place, is_deleted=False).count()
            active_ministries = Ministry.objects.filter(place=place, is_deleted=False, status='active').count()
            suspended_ministries = Ministry.objects.filter(place=place, is_deleted=False, status='suspended').count()
            
            data = {
                'id': str(place.id),
                'name': place.name,
                'slug': place.slug,
                'is_active': place.is_active,
                'created_at': place.created_at.isoformat(),
                'updated_at': place.updated_at.isoformat(),
                'stats': {
                    'total_ministries': total_ministries,
                    'active_ministries': active_ministries,
                    'suspended_ministries': suspended_ministries,
                }
            }
            
            return True, {"success": True, "data": data}, 200
            
        except Place.DoesNotExist:
            return False, {"success": False, "error": "Place not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Place detail error: {str(e)}")
            return False, {"success": False, "error": "Failed to fetch place"}, 500
    
    @staticmethod
    def create_place(data, admin_user, request=None):
        """
        Create a new place.
        
        Args:
            data: Place data (name required)
            admin_user: Super admin creating the place
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            name = data.get('name', '').strip()
            
            if not name:
                return False, {
                    "success": False,
                    "error": "Place name is required"
                }, 400
            
            # Generate slug from name
            base_slug = slugify(name)
            slug = base_slug
            counter = 1
            
            # Ensure unique slug
            while Place.all_objects.filter(slug=slug).exists():
                slug = f"{base_slug}-{counter}"
                counter += 1
            
            with transaction.atomic():
                place = Place.objects.create(
                    name=name,
                    slug=slug,
                    is_active=data.get('is_active', True)
                )
            
            # Clear caches
            SuperAdminPlaceService._clear_cache()
            
            logger.info(f"[super_admin] Place '{place.name}' created by {admin_user.email}")
            
            return True, {
                "success": True,
                "data": {
                    'id': str(place.id),
                    'name': place.name,
                    'slug': place.slug,
                    'is_active': place.is_active,
                    'created_at': place.created_at.isoformat(),
                },
                "message": f"Place '{place.name}' created successfully"
            }, 201
            
        except Exception as e:
            logger.error(f"[super_admin] Create place error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to create place"
            }, 500
    
    @staticmethod
    def update_place(place_id, data, admin_user, request=None):
        """
        Update place details (name only).
        
        Args:
            place_id: UUID of the place
            data: Updated data
            admin_user: Super admin making the update
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            place = Place.objects.get(id=place_id)
            
            with transaction.atomic():
                # Update name if provided
                if 'name' in data:
                    new_name = data['name'].strip()
                    if new_name:
                        place.name = new_name
                        # Optionally update slug if name changes
                        # place.slug = slugify(new_name)  # Uncomment if slug should change
                
                # Update is_active if provided
                if 'is_active' in data:
                    place.is_active = bool(data['is_active'])
                
                place.save()
            
            # Clear caches
            SuperAdminPlaceService._clear_cache()
            
            logger.info(f"[super_admin] Place '{place.name}' updated by {admin_user.email}")
            
            return True, {
                "success": True,
                "data": {
                    'id': str(place.id),
                    'name': place.name,
                    'slug': place.slug,
                    'is_active': place.is_active,
                    'updated_at': place.updated_at.isoformat(),
                },
                "message": "Place updated successfully"
            }, 200
            
        except Place.DoesNotExist:
            return False, {"success": False, "error": "Place not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Update place error: {str(e)}")
            return False, {"success": False, "error": "Failed to update place"}, 500
    
    @staticmethod
    def delete_place(place_id, admin_user, confirm=False):
        """
        Permanently delete a place (hard delete).
        
        WARNING: This will also delete all ministries and related data in this place!
        
        Args:
            place_id: UUID of the place
            admin_user: Super admin performing the delete
            confirm: Must be True to proceed with deletion
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            place = Place.objects.get(id=place_id)
            
            # Check for ministries
            ministry_count = Ministry.objects.filter(place=place).count()
            
            if ministry_count > 0 and not confirm:
                return False, {
                    "success": False,
                    "error": f"This place has {ministry_count} ministries. Set confirm=true to delete everything.",
                    "ministry_count": ministry_count,
                    "requires_confirmation": True
                }, 400
            
            place_name = place.name
            
            with transaction.atomic():
                # This will cascade delete all related ministries and their data
                place.delete()
            
            # Clear caches
            SuperAdminPlaceService._clear_cache()
            
            logger.warning(f"[super_admin] Place '{place_name}' PERMANENTLY DELETED by {admin_user.email}")
            
            return True, {
                "success": True,
                "message": f"Place '{place_name}' and all related data permanently deleted"
            }, 200
            
        except Place.DoesNotExist:
            return False, {"success": False, "error": "Place not found"}, 404
        except Exception as e:
            logger.error(f"[super_admin] Delete place error: {str(e)}")
            return False, {"success": False, "error": "Failed to delete place"}, 500
    
    @staticmethod
    def _clear_cache():
        """Clear all place-related caches"""
        cache.delete(SuperAdminPlaceService.CACHE_KEY_LIST)
        cache.delete(SuperAdminPlaceService.CACHE_KEY_PUBLIC)
