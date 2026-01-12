"""
Ministry Management Views

Endpoints for ministry self-management and staff service management.
Ministry admin can manage their organization and staff services.
"""
import logging
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from ministry.core.permissions import IsMinistryMember
from .services import MinistryManagementService, StaffServiceManagementService

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


# ==================== Staff Service Management Views ====================

class StaffServiceListView(BaseAPIView):
    """
    GET /ministry/management/staff-services/
    POST /ministry/management/staff-services/
    
    List all staff services / Create new staff service.
    Ministry admin only.
    """
    permission_classes = [IsAuthenticated, IsMinistryMember]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get(self, request):
        """Get list of staff services for this ministry"""
        try:
            success, response_data, status_code = StaffServiceManagementService.get_list(
                ministry=request.ministry,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[ministry] Staff services list error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch staff services"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def post(self, request):
        """Create a new staff service"""
        try:
            success, response_data, status_code = StaffServiceManagementService.create(
                ministry=request.ministry,
                data=request.data,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[ministry] Create staff service error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to create staff service"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class StaffServiceDetailView(BaseAPIView):
    """
    GET /ministry/management/staff-services/<uuid>/
    PATCH /ministry/management/staff-services/<uuid>/
    DELETE /ministry/management/staff-services/<uuid>/
    
    Get/Update/Delete staff service.
    Ministry admin only.
    """
    permission_classes = [IsAuthenticated, IsMinistryMember]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get(self, request, staff_service_id):
        """Get staff service details"""
        try:
            success, response_data, status_code = StaffServiceManagementService.get_details(
                ministry=request.ministry,
                staff_service_id=staff_service_id,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[ministry] Staff service detail error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch staff service"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def patch(self, request, staff_service_id):
        """Update staff service (name, logo)"""
        try:
            success, response_data, status_code = StaffServiceManagementService.update(
                ministry=request.ministry,
                staff_service_id=staff_service_id,
                data=request.data,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[ministry] Update staff service error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to update staff service"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def delete(self, request, staff_service_id):
        """Permanently delete staff service"""
        try:
            success, response_data, status_code = StaffServiceManagementService.delete(
                ministry=request.ministry,
                staff_service_id=staff_service_id
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[ministry] Delete staff service error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to delete staff service"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class StaffServicePasswordResetView(BaseAPIView):
    """
    POST /ministry/management/staff-services/<uuid>/reset-password/
    
    Reset staff service password.
    Ministry admin only.
    """
    permission_classes = [IsAuthenticated, IsMinistryMember]
    
    def post(self, request, staff_service_id):
        """Reset password for staff service"""
        try:
            new_password = request.data.get('new_password')
            if not new_password:
                return Response(
                    standardized_response(success=False, error="new_password is required"),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            if len(new_password) < 8:
                return Response(
                    standardized_response(success=False, error="Password must be at least 8 characters long"),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            success, response_data, status_code = StaffServiceManagementService.reset_password(
                ministry=request.ministry,
                staff_service_id=staff_service_id,
                new_password=new_password
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[ministry] Reset password error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to reset password"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class StaffServiceStatusToggleView(BaseAPIView):
    """
    POST /ministry/management/staff-services/<uuid>/toggle-status/
    
    Toggle service status between ACTIVE and PAUSED.
    Useful for attendance-based service control.
    Ministry admin only.
    """
    permission_classes = [IsAuthenticated, IsMinistryMember]
    
    def post(self, request, staff_service_id):
        """Toggle service status (auto-toggle if no status provided)"""
        try:
            new_status = request.data.get('status')
            
            # If no status provided, let the service auto-toggle
            if not new_status:
                success, response_data, status_code = StaffServiceManagementService.toggle_status(
                    ministry=request.ministry,
                    staff_service_id=staff_service_id,
                    new_status=None  # Auto-toggle
                )
            else:
                # Validate provided status
                if new_status not in ['active', 'paused']:
                    return Response(
                        standardized_response(success=False, error="status must be 'active' or 'paused'"),
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                success, response_data, status_code = StaffServiceManagementService.toggle_status(
                    ministry=request.ministry,
                    staff_service_id=staff_service_id,
                    new_status=new_status
                )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[ministry] Toggle status error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to toggle status"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
