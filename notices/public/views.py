"""
Public Notice Views

Public API endpoints for citizen mobile app to view notices.
No authentication required - open to all users.
"""

import logging
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from .services import PublicNoticeService

logger = logging.getLogger(__name__)


class PublicNoticeListView(BaseAPIView):
    """
    GET /api/public/notices/
    
    List all active notices with optional filters.
    No authentication required.
    
    Query Parameters:
        - ministry: UUID - Filter by ministry
        - service: UUID - Filter by service
        - file_type: string - Filter by file type (pdf, png, jpg)
        - search: string - Search in title
        - limit: int - Number of results (default 20, max 50)
        - offset: int - Pagination offset
    
    Response:
    {
        "success": true,
        "data": {
            "results": [...],
            "count": 100,
            "limit": 20,
            "offset": 0,
            "has_more": true
        }
    }
    """
    permission_classes = [AllowAny]
    
    def get(self, request):
        try:
            success, response_data, status_code = PublicNoticeService.list_notices(
                query_params=request.query_params,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[public] Notice list error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch notices"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class PublicNoticeDetailView(BaseAPIView):
    """
    GET /api/public/notices/<uuid>/
    
    Get notice details by ID.
    No authentication required.
    
    Response:
    {
        "success": true,
        "data": {
            "id": "uuid",
            "title": "Notice Title",
            "ministry": {...},
            "service": {...},
            "file_url": "https://...",
            "file_type": "pdf",
            "created_at": "2024-01-01T00:00:00Z"
        }
    }
    """
    permission_classes = [AllowAny]
    
    def get(self, request, notice_id):
        try:
            success, response_data, status_code = PublicNoticeService.get_notice_detail(
                notice_id=str(notice_id),
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[public] Notice detail error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch notice"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class PublicNoticeFilterOptionsView(BaseAPIView):
    """
    GET /api/public/notices/filters/
    
    Get available filter options for notices.
    No authentication required.
    
    Response:
    {
        "success": true,
        "data": {
            "ministries": [...],
            "services": [...],
            "file_types": [...]
        }
    }
    """
    permission_classes = [AllowAny]
    
    def get(self, request):
        try:
            success, response_data, status_code = PublicNoticeService.get_filter_options(
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[public] Filter options error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch filter options"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
