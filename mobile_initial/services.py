"""
Mobile Profile Service Layer

Handles business logic for citizen profile setup and completion.
"""
import logging
from typing import Optional, Tuple
from django.db import transaction
from django.core.exceptions import ValidationError

from authentication.models import CustomUser
from places.models import Place
from .models import CitizenProfile
from .serializers import (
    CitizenProfileSerializer,
    ProfileStatusSerializer,
    PlaceListSerializer
)

logger = logging.getLogger(__name__)


class ProfileService:
    """Service for handling citizen profile operations"""
    
    @staticmethod
    def get_profile_status(user: CustomUser) -> Tuple[bool, dict, int]:
        """
        Check if user has completed their profile.
        
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            # Check if user is citizen
            if user.user_type != CustomUser.UserType.CITIZEN:
                return False, {
                    "success": False,
                    "error": "Only citizens can have mobile profiles"
                }, 400
            
            # Try to get existing profile
            try:
                profile = CitizenProfile.objects.select_related('place').get(user=user)
                serializer = CitizenProfileSerializer(profile)
                
                return True, {
                    "success": True,
                    "data": {
                        "is_profile_complete": profile.is_profile_complete,
                        "profile": serializer.data
                    }
                }, 200
                
            except CitizenProfile.DoesNotExist:
                # No profile exists yet
                return True, {
                    "success": True,
                    "data": {
                        "is_profile_complete": False,
                        "profile": None
                    }
                }, 200
                
        except Exception as e:
            logger.error(f"[profile] Error checking profile status for user {user.id}: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to check profile status"
            }, 500
    
    @staticmethod
    def setup_profile(
        user: CustomUser,
        full_name: str,
        place_id: str
    ) -> Tuple[bool, dict, int]:
        """
        Create or update citizen profile.
        
        Args:
            user: CustomUser instance
            full_name: Citizen's full name
            place_id: Selected place UUID
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            # Validate user type
            if user.user_type != CustomUser.UserType.CITIZEN:
                return False, {
                    "success": False,
                    "error": "Only citizens can set up mobile profiles"
                }, 403
            
            # Validate place
            try:
                place = Place.objects.get(id=place_id, is_active=True)
            except Place.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Selected place not found or inactive"
                }, 400
            
            # Validate name
            if not full_name or len(full_name.strip()) < 2:
                return False, {
                    "success": False,
                    "error": "Full name must be at least 2 characters"
                }, 400
            
            with transaction.atomic():
                # Create or update profile
                profile, created = CitizenProfile.objects.update_or_create(
                    user=user,
                    defaults={
                        'full_name': full_name.strip(),
                        'place': place,
                        'is_profile_complete': True
                    }
                )
                
                serializer = CitizenProfileSerializer(profile)
                
                message = "Profile created successfully" if created else "Profile updated successfully"
                logger.info(f"[profile] Profile {'created' if created else 'updated'} for user {user.id}")
                
                return True, {
                    "success": True,
                    "message": message,
                    "data": serializer.data
                }, 201 if created else 200
                
        except Exception as e:
            logger.error(f"[profile] Error setting up profile for user {user.id}: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to set up profile"
            }, 500
    
    @staticmethod
    def get_available_places() -> Tuple[bool, dict, int]:
        """
        Get list of active places for selection.
        
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            places = Place.objects.filter(is_active=True).order_by('name')
            serializer = PlaceListSerializer(places, many=True)
            
            return True, {
                "success": True,
                "data": serializer.data,
                "count": places.count()
            }, 200
            
        except Exception as e:
            logger.error(f"[profile] Error fetching places: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch places"
            }, 500
    
    @staticmethod
    def update_profile(
        user: CustomUser,
        full_name: Optional[str] = None,
        place_id: Optional[str] = None
    ) -> Tuple[bool, dict, int]:
        """
        Update existing profile fields.
        
        Args:
            user: CustomUser instance
            full_name: New full name (optional)
            place_id: New place UUID (optional)
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            # Get existing profile
            try:
                profile = CitizenProfile.objects.select_related('place').get(user=user)
            except CitizenProfile.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Profile not found. Please complete profile setup first."
                }, 404
            
            # Update fields
            updated = False
            
            if full_name:
                if len(full_name.strip()) < 2:
                    return False, {
                        "success": False,
                        "error": "Full name must be at least 2 characters"
                    }, 400
                profile.full_name = full_name.strip()
                updated = True
            
            if place_id:
                try:
                    place = Place.objects.get(id=place_id, is_active=True)
                    profile.place = place
                    updated = True
                except Place.DoesNotExist:
                    return False, {
                        "success": False,
                        "error": "Selected place not found or inactive"
                    }, 400
            
            if not updated:
                return False, {
                    "success": False,
                    "error": "No fields to update"
                }, 400
            
            with transaction.atomic():
                profile.save()
                
            serializer = CitizenProfileSerializer(profile)
            logger.info(f"[profile] Profile updated for user {user.id}")
            
            return True, {
                "success": True,
                "message": "Profile updated successfully",
                "data": serializer.data
            }, 200
            
        except Exception as e:
            logger.error(f"[profile] Error updating profile for user {user.id}: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to update profile"
            }, 500
