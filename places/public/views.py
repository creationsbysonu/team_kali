"""
Public Places Views

Endpoints for public access to place information.
NO authentication required - used for place selection.
"""
import logging
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from . import PublicPlaceService

logger = logging.getLogger(__name__)


class PublicPlaceListView(BaseAPIView):
    """
    GET /api/places/public/
    
    Public endpoint to list all ACTIVE places.
    Used for place selection dropdown.
    
    NO AUTHENTICATION REQUIRED.
    
    Response:
    {
        "success": true,
        "data": [
            {
                "id": "uuid",
                "name": "Kathmandu",
                "slug": "kathmandu"
            }
        ]
    }
    """
    permission_classes = [AllowAny]
    authentication_classes = []
    
    def get(self, request):
        try:
            success, response_data, status_code = PublicPlaceService.get_active_places()
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[public] Place list error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch places"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class PublicPlaceDetailView(BaseAPIView):
    """
    GET /api/places/public/<slug>/
    
    Get place details by slug.
    NO AUTHENTICATION REQUIRED.
    """
    permission_classes = [AllowAny]
    authentication_classes = []
    
    def get(self, request, slug):
        try:
            success, response_data, status_code = PublicPlaceService.get_place_by_slug(slug)
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[public] Place detail error for {slug}: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch place details"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
