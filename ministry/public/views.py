"""
Public Ministry Views

Public endpoints for browsing ministries and services.
No authentication required.
"""
import logging
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from .services import PublicMinistryService

logger = logging.getLogger(__name__)


class PublicMinistryListView(BaseAPIView):
    """
    GET /ministry/public/<place_slug>/ministries/
    
    List all active ministries for a place.
    No authentication required.
    """
    permission_classes = [AllowAny]
    
    def get(self, request, place_slug):
        try:
            success, response_data, status_code = PublicMinistryService.get_ministries_by_place(
                place_slug=place_slug,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[public] Ministry list view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch ministries"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class PublicMinistryDetailView(BaseAPIView):
    """
    GET /ministry/public/<place_slug>/ministries/<ministry_slug>/
    
    Get ministry details by slug.
    No authentication required.
    """
    permission_classes = [AllowAny]
    
    def get(self, request, place_slug, ministry_slug):
        try:
            success, response_data, status_code = PublicMinistryService.get_ministry_detail(
                place_slug=place_slug,
                ministry_slug=ministry_slug,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[public] Ministry detail view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch ministry details"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class PublicServiceListView(BaseAPIView):
    """
    GET /ministry/public/<place_slug>/ministries/<ministry_slug>/services/
    
    List all active services for a ministry.
    No authentication required.
    """
    permission_classes = [AllowAny]
    
    def get(self, request, place_slug, ministry_slug):
        try:
            success, response_data, status_code = PublicMinistryService.get_services_by_ministry(
                place_slug=place_slug,
                ministry_slug=ministry_slug,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[public] Service list view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch services"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
