"""
Views for Holiday Management.
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
from .services import HolidayService
from .serializers import HolidayCreateSerializer, HolidayUpdateSerializer

logger = logging.getLogger(__name__)


class HolidayCreateView(BaseAPIView):
    """API endpoint for creating holidays."""
    permission_classes = [IsAuthenticated, IsMinistryAdmin]
    throttle_classes = [UserRateThrottle]
    
    def post(self, request):
        """Create a new holiday."""
        try:
            serializer = HolidayCreateSerializer(
                data=request.data,
                context={'request': request}
            )
            
            if not serializer.is_valid():
                return Response(
                    standardized_response(success=False, error=serializer.errors),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            validated_data = serializer.validated_data
            
            success, response_data, status_code = HolidayService.create_holiday(
                name=validated_data['name'],  # type: ignore[index]
                date=validated_data['date'],  # type: ignore[index]
                description=validated_data.get('description', ''),  # type: ignore[union-attr]
                created_by=request.user
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Holiday create error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to create holiday"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class HolidayUpdateView(BaseAPIView):
    """API endpoint for updating holidays."""
    permission_classes = [IsAuthenticated, IsMinistryAdmin]
    throttle_classes = [UserRateThrottle]
    
    def patch(self, request, holiday_id):
        """Update a holiday."""
        try:
            serializer = HolidayUpdateSerializer(data=request.data)
            
            if not serializer.is_valid():
                return Response(
                    standardized_response(success=False, error=serializer.errors),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            validated_data = serializer.validated_data
            
            success, response_data, status_code = HolidayService.update_holiday(
                holiday_id=holiday_id,
                name=validated_data.get('name'),  # type: ignore[union-attr]
                description=validated_data.get('description'),  # type: ignore[union-attr]
                user=request.user
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Holiday update error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to update holiday"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class HolidayDeleteView(BaseAPIView):
    """API endpoint for deleting holidays."""
    permission_classes = [IsAuthenticated, IsMinistryAdmin]
    throttle_classes = [UserRateThrottle]
    
    def delete(self, request, holiday_id):
        """Delete a holiday."""
        try:
            success, response_data, status_code = HolidayService.delete_holiday(
                holiday_id=holiday_id,
                user=request.user
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Holiday delete error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to delete holiday"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class HolidayListView(BaseAPIView):
    """API endpoint for listing holidays."""
    permission_classes = [IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request):
        """Get list of holidays with optional filtering."""
        try:
            year = request.query_params.get('year')
            month = request.query_params.get('month')
            start_date_str = request.query_params.get('start_date')
            end_date_str = request.query_params.get('end_date')
            
            # Convert to integers if provided
            year = int(year) if year else None
            month = int(month) if month else None
            
            # Parse dates if provided
            start_date = None
            end_date = None
            if start_date_str:
                try:
                    start_date = datetime.strptime(start_date_str, "%Y-%m-%d").date()
                except ValueError:
                    return Response(
                        standardized_response(success=False, error="Invalid start_date format. Use YYYY-MM-DD"),
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            if end_date_str:
                try:
                    end_date = datetime.strptime(end_date_str, "%Y-%m-%d").date()
                except ValueError:
                    return Response(
                        standardized_response(success=False, error="Invalid end_date format. Use YYYY-MM-DD"),
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            success, response_data, status_code = HolidayService.get_holidays(
                year=year,
                month=month,
                start_date=start_date,
                end_date=end_date
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except ValueError:
            return Response(
                standardized_response(success=False, error="Invalid year or month"),
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            logger.error(f"Holiday list fetch error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to fetch holidays"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class HolidayCalendarView(BaseAPIView):
    """API endpoint for holiday calendar."""
    permission_classes = [IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request):
        """Get holiday calendar for a date range."""
        try:
            start_date_str = request.query_params.get('start_date')
            end_date_str = request.query_params.get('end_date')
            
            if not all([start_date_str, end_date_str]):
                return Response(
                    standardized_response(
                        success=False,
                        error="start_date and end_date are required"
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
            
            success, response_data, status_code = HolidayService.get_holiday_calendar(
                start_date=start_date,
                end_date=end_date
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Holiday calendar fetch error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to fetch holiday calendar"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
