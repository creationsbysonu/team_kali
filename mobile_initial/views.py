"""
Mobile Profile Views

API endpoints for citizen profile setup and management.
"""
import logging
import traceback

from rest_framework import status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.throttling import UserRateThrottle

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from .services import ProfileService
from .serializers import ProfileSetupSerializer

logger = logging.getLogger(__name__)


class ProfileStatusView(BaseAPIView):
    """
    Check citizen profile completion status.
    
    GET /api/mobile/profile/status/
    
    Response:
    {
        "success": true,
        "data": {
            "is_profile_complete": false,
            "profile": null
        }
    }
    """
    permission_classes = [IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request):
        try:
            user = request.user
            
            success, response_data, status_code = ProfileService.get_profile_status(user)
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"[profile] Status check error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(
                    success=False,
                    error="Failed to check profile status"
                ),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ProfileSetupView(BaseAPIView):
    """
    Create or update citizen profile.
    
    POST /api/mobile/profile/setup/
    
    Request:
    {
        "full_name": "John Doe",
        "place_id": "uuid-here"
    }
    
    Response:
    {
        "success": true,
        "message": "Profile created successfully",
        "data": {
            "id": "uuid",
            "full_name": "John Doe",
            "place": "uuid",
            "place_details": {...},
            "is_profile_complete": true
        }
    }
    """
    permission_classes = [IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    
    def post(self, request):
        try:
            serializer = ProfileSetupSerializer(data=request.data)
            
            if not serializer.is_valid():
                return Response(
                    standardized_response(
                        success=False,
                        error=serializer.errors
                    ),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            user = request.user
            full_name = serializer.validated_data['full_name']
            place_id = serializer.validated_data['place_id']
            
            success, response_data, status_code = ProfileService.setup_profile(
                user=user,
                full_name=full_name,
                place_id=place_id
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"[profile] Setup error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(
                    success=False,
                    error="Failed to set up profile"
                ),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class PlacesListView(BaseAPIView):
    """
    Get list of available places for selection.
    
    GET /api/mobile/places/
    
    Response:
    {
        "success": true,
        "data": [
            {
                "id": "uuid",
                "name": "Kathmandu",
                "slug": "kathmandu",
                "description": "Capital city"
            },
            ...
        ],
        "count": 10
    }
    """
    permission_classes = [IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request):
        try:
            success, response_data, status_code = ProfileService.get_available_places()
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"[profile] Places list error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(
                    success=False,
                    error="Failed to fetch places"
                ),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ProfileUpdateView(BaseAPIView):
    """
    Update existing profile (name or place).
    
    PATCH /api/mobile/profile/update/
    
    Request:
    {
        "full_name": "Jane Doe",  // optional
        "place_id": "uuid-here"   // optional
    }
    
    Response:
    {
        "success": true,
        "message": "Profile updated successfully",
        "data": {...}
    }
    """
    permission_classes = [IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    
    def patch(self, request):
        try:
            user = request.user
            full_name = request.data.get('full_name')
            place_id = request.data.get('place_id')
            
            if not full_name and not place_id:
                return Response(
                    standardized_response(
                        success=False,
                        error="Provide at least one field to update (full_name or place_id)"
                    ),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            success, response_data, status_code = ProfileService.update_profile(
                user=user,
                full_name=full_name,
                place_id=place_id
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"[profile] Update error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(
                    success=False,
                    error="Failed to update profile"
                ),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
