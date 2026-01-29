"""
User Profile Views for Mobile App
"""
import logging
import traceback

from rest_framework import status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.throttling import UserRateThrottle

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from authentication.serializers import UserSerializer

logger = logging.getLogger(__name__)


class UserProfileView(BaseAPIView):
    """
    Get current user profile information.
    
    GET /api/auth/profile/
    Headers: Authorization: Bearer <access_token>
    
    Response:
    {
        "success": true,
        "data": {
            "id": "uuid",
            "email": "user@example.com",
            "user_type": "citizen",
            "is_verified": true,
            "created_at": "2024-01-01T00:00:00Z"
        }
    }
    """
    permission_classes = [IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request):
        try:
            user = request.user
            serializer = UserSerializer(user, context={'request': request})
            
            return Response(
                standardized_response(
                    success=True,
                    data=serializer.data,
                    message="Profile retrieved successfully"
                ),
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            logger.error(f"[profile] Error retrieving profile: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(
                    success=False,
                    error="Failed to retrieve profile"
                ),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
