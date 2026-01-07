"""
Citizen Tenant Views

Endpoints for citizens to browse ministries.
Authentication required (Citizens only - Flutter App).
"""
import logging
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from tenants.core.permissions import IsCitizen
from .services import PublicTenantService

logger = logging.getLogger(__name__)


class CitizenTenantListView(BaseAPIView):
    """
    GET /tenants/citizen/
    
    List all active ministries (citizens only - must be logged in).
    """
    permission_classes = [IsAuthenticated, IsCitizen]
    
    def get(self, request):
        try:
            success, response_data, status_code = PublicTenantService.get_list(
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[citizen] Ministry list view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch ministries"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class CitizenTenantDetailView(BaseAPIView):
    """
    GET /tenants/citizen/<slug>/
    
    Get ministry details by slug (citizens only - must be logged in).
    """
    permission_classes = [IsAuthenticated, IsCitizen]
    
    def get(self, request, slug):
        try:
            success, response_data, status_code = PublicTenantService.get_detail(
                slug=slug,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[public] Detail view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch ministry"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
