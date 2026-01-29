"""
Views for Unified Attendance Management (Staff + Officials).
"""

import logging
import traceback
from rest_framework import status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.throttling import UserRateThrottle
from datetime import datetime

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from core.permissions import IsMinistryAdmin
from .services import AttendanceService
from .serializers import (
    AttendanceRecordSerializer,
    AttendanceRecordCreateSerializer,
    AttendanceRecordBulkCreateSerializer
)

logger = logging.getLogger(__name__)


class AttendanceMarkView(BaseAPIView):
    """API endpoint for marking attendance (staff or official)."""
    permission_classes = [IsAuthenticated, IsMinistryAdmin]
    throttle_classes = [UserRateThrottle]
    
    def post(self, request):
        """Mark attendance for a person (staff or official)."""
        try:
            serializer = AttendanceRecordCreateSerializer(
                data=request.data,
                context={'request': request}
            )
            
            if not serializer.is_valid():
                return Response(
                    standardized_response(success=False, error=serializer.errors),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            validated_data = serializer.validated_data
            person_type = validated_data['person_type']  # type: ignore[index]
            
            # Get person_id based on type
            if person_type == 'STAFF':
                person_id = validated_data['staff'].id  # type: ignore[index]
            else:
                person_id = validated_data['official'].id  # type: ignore[index]
            
            success, response_data, status_code = AttendanceService.mark_attendance(
                person_type=person_type,
                person_id=person_id,
                date=validated_data['date'],  # type: ignore[index]
                status=validated_data['status'],  # type: ignore[index]
                reason=validated_data.get('reason', ''),  # type: ignore[union-attr]
                marked_by=request.user
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Attendance mark error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to mark attendance"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class AttendanceBulkMarkView(BaseAPIView):
    """API endpoint for bulk marking attendance."""
    permission_classes = [IsAuthenticated, IsMinistryAdmin]
    throttle_classes = [UserRateThrottle]
    
    def post(self, request):
        """Bulk mark attendance for a date range."""
        try:
            serializer = AttendanceRecordBulkCreateSerializer(
                data=request.data,
                context={'request': request}
            )
            
            if not serializer.is_valid():
                return Response(
                    standardized_response(success=False, error=serializer.errors),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            validated_data = serializer.validated_data
            person_type = validated_data['person_type']  # type: ignore[index]
            
            # Get person_id based on type
            if person_type == 'STAFF':
                person_id = validated_data['staff'].id  # type: ignore[index]
            else:
                person_id = validated_data['official'].id  # type: ignore[index]
            
            success, response_data, status_code = AttendanceService.bulk_mark_attendance(
                person_type=person_type,
                person_id=person_id,
                start_date=validated_data['start_date'],  # type: ignore[index]
                end_date=validated_data['end_date'],  # type: ignore[index]
                status=validated_data['status'],  # type: ignore[index]
                reason=validated_data.get('reason', ''),  # type: ignore[union-attr]
                marked_by=request.user
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Bulk attendance mark error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to bulk mark attendance"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class AttendanceCalendarView(BaseAPIView):
    """API endpoint for viewing attendance calendar."""
    permission_classes = [IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request):
        """Get attendance calendar for a person."""
        try:
            person_type = request.query_params.get('person_type', 'STAFF')
            person_id = request.query_params.get('person_id')
            start_date_str = request.query_params.get('start_date')
            end_date_str = request.query_params.get('end_date')
            
            if not all([person_id, start_date_str, end_date_str]):
                return Response(
                    standardized_response(
                        success=False,
                        error="person_id, start_date, and end_date are required"
                    ),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Parse dates
            try:
                start_date = datetime.strptime(start_date_str, "%Y-%m-%d").date()
                end_date = datetime.strptime(end_date_str, "%Y-%m-%d").date()
            except ValueError:
                return Response(
                    standardized_response(
                        success=False,
                        error="Invalid date format. Use YYYY-MM-DD"
                    ),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            success, response_data, status_code = AttendanceService.get_attendance_calendar(
                person_type=person_type,
                person_id=person_id,
                start_date=start_date,
                end_date=end_date
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Attendance calendar fetch error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to fetch attendance calendar"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class AttendanceDeleteView(BaseAPIView):
    """API endpoint for deleting attendance records."""
    permission_classes = [IsAuthenticated, IsMinistryAdmin]
    throttle_classes = [UserRateThrottle]
    
    def delete(self, request, attendance_id):
        """Delete an attendance record."""
        try:
            success, response_data, status_code = AttendanceService.delete_attendance(
                attendance_id=attendance_id,
                user=request.user
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Attendance delete error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to delete attendance"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
