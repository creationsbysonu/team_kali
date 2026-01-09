"""
Ministry Management Views

Endpoints for ministry self-management.
Ministry admin can view their organization details.
"""
import logging
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from ministry.core.permissions import IsMinistryMember
from .services import MinistryManagementService

logger = logging.getLogger(__name__)


class MinistryDetailView(BaseAPIView):
    """
    GET /ministry/me/
    
    Get current ministry details.
    Ministry admin only.
    """
    permission_classes = [IsAuthenticated, IsMinistryMember]
    
    def get(self, request):
        try:
            success, response_data, status_code = MinistryManagementService.get_details(
                ministry=request.ministry,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[ministry] Detail view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch details"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
