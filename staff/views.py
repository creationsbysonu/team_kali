"""
Staff Views

API endpoints for staff management by ministry admins.
"""
import logging
import traceback
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from ministry.core.permissions import IsMinistryMember
from .services import StaffService
from .serializers import StaffCreateSerializer, StaffUpdateSerializer

logger = logging.getLogger(__name__)


class StaffListView(BaseAPIView):
    """
    GET /staff/
    POST /staff/
    
    List all staff / Create new staff.
    Ministry admin only.
    """
    permission_classes = [IsAuthenticated, IsMinistryMember]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get(self, request):
        try:
            ministry = request.ministry
            
            success, response_data, status_code = StaffService.get_staff_list(
                ministry=ministry,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[staff] List error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch staff"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def post(self, request):
        try:
            ministry = request.ministry
            
            # Validate input
            serializer = StaffCreateSerializer(data=request.data)
            if not serializer.is_valid():
                return Response(
                    standardized_response(success=False, error=serializer.errors),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            success, response_data, status_code = StaffService.create_staff(
                data=serializer.validated_data,
                ministry=ministry,
                created_by=request.user,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[staff] Create error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to create staff"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class StaffDetailView(BaseAPIView):
    """
    GET /staff/<uuid:pk>/
    PUT /staff/<uuid:pk>/
    DELETE /staff/<uuid:pk>/
    
    Get/Update/Delete a staff member.
    Ministry admin only.
    """
    permission_classes = [IsAuthenticated, IsMinistryMember]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get(self, request, pk):
        try:
            ministry = request.ministry
            
            success, response_data, status_code = StaffService.get_staff_detail(
                staff_id=pk,
                ministry=ministry,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[staff] Detail error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch staff"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def put(self, request, pk):
        try:
            ministry = request.ministry
            
            # Validate input
            serializer = StaffUpdateSerializer(data=request.data)
            if not serializer.is_valid():
                return Response(
                    standardized_response(success=False, error=serializer.errors),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            success, response_data, status_code = StaffService.update_staff(
                staff_id=pk,
                data=serializer.validated_data,
                ministry=ministry,
                updated_by=request.user,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[staff] Update error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to update staff"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def delete(self, request, pk):
        try:
            ministry = request.ministry
            
            success, response_data, status_code = StaffService.delete_staff(
                staff_id=pk,
                ministry=ministry,
                deleted_by=request.user
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[staff] Delete error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to delete staff"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class StaffResetPasswordView(BaseAPIView):
    """
    POST /staff/<uuid:pk>/reset-password/
    
    Reset staff password.
    Ministry admin only.
    """
    permission_classes = [IsAuthenticated, IsMinistryMember]
    
    def post(self, request, pk):
        try:
            ministry = request.ministry
            new_password = request.data.get('new_password')
            
            if not new_password:
                return Response(
                    standardized_response(success=False, error="new_password is required"),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            if len(new_password) < 8:
                return Response(
                    standardized_response(success=False, error="Password must be at least 8 characters"),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            success, response_data, status_code = StaffService.reset_password(
                staff_id=pk,
                new_password=new_password,
                ministry=ministry,
                reset_by=request.user
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[staff] Reset password error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to reset password"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
