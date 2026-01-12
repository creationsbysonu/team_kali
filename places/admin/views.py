"""
Super Admin Place Views

System-wide place management endpoints.
Super admin only.

Places: Add, Edit, Delete (hard delete - no soft delete for places)
"""
import logging
import traceback
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from ministry.core.permissions import IsSuperAdmin
from .services import SuperAdminPlaceService

logger = logging.getLogger(__name__)


class SuperAdminPlaceListView(BaseAPIView):
    """
    GET /places/admin/
    POST /places/admin/
    
    List all places / Create new place.
    Super admin only.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    
    def get(self, request):
        """List all places with optional filtering"""
        try:
            filters = {
                'search': request.query_params.get('search'),
                'is_active': request.query_params.get('is_active'),
            }
            
            success, response_data, status_code = SuperAdminPlaceService.get_list(
                filters=filters,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Place list view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch places"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def post(self, request):
        """Create a new place"""
        try:
            success, response_data, status_code = SuperAdminPlaceService.create_place(
                data=request.data,
                admin_user=request.user,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Create place view error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to create place"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SuperAdminPlaceDetailView(BaseAPIView):
    """
    GET /places/admin/<uuid:pk>/
    PUT /places/admin/<uuid:pk>/
    DELETE /places/admin/<uuid:pk>/
    
    Get/Update/Delete place.
    Super admin only.
    
    DELETE is a HARD DELETE - permanently removes the place and all related data!
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    
    def get(self, request, pk):
        """Get place details"""
        try:
            success, response_data, status_code = SuperAdminPlaceService.get_detail(
                place_id=pk,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Place detail view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch place"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def put(self, request, pk):
        """Update place (name, is_active)"""
        try:
            success, response_data, status_code = SuperAdminPlaceService.update_place(
                place_id=pk,
                data=request.data,
                admin_user=request.user,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Update place view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to update place"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def delete(self, request, pk):
        """
        Permanently delete a place (HARD DELETE).
        
        WARNING: This deletes the place AND all its ministries/related data!
        
        Query params:
            confirm=true - Required if place has ministries
        """
        try:
            confirm = request.query_params.get('confirm', '').lower() == 'true'
            
            success, response_data, status_code = SuperAdminPlaceService.delete_place(
                place_id=pk,
                admin_user=request.user,
                confirm=confirm
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Delete place view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to delete place"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
