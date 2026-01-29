"""
Views for Notification System.
"""

import logging
import traceback
from rest_framework import status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.throttling import UserRateThrottle

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from .services import NotificationService
from .serializers import NotificationMarkReadSerializer

logger = logging.getLogger(__name__)


class NotificationListView(BaseAPIView):
    """API endpoint for listing notifications."""
    permission_classes = [IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request):
        """Get notifications for the authenticated user."""
        try:
            unread_only = request.query_params.get('unread_only', 'false').lower() == 'true'
            limit = int(request.query_params.get('limit', 50))
            
            success, response_data, status_code = NotificationService.get_notifications(
                user=request.user,
                unread_only=unread_only,
                limit=limit
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except ValueError:
            return Response(
                standardized_response(success=False, error="Invalid limit value"),
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            logger.error(f"Notification list fetch error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to fetch notifications"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class NotificationMarkReadView(BaseAPIView):
    """API endpoint for marking notifications as read."""
    permission_classes = [IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    
    def post(self, request):
        """Mark specific notifications as read."""
        try:
            serializer = NotificationMarkReadSerializer(
                data=request.data,
                context={'request': request}
            )
            
            if not serializer.is_valid():
                return Response(
                    standardized_response(success=False, error=serializer.errors),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            notification_ids = serializer.validated_data['notification_ids']  # type: ignore[index]
            
            success, response_data, status_code = NotificationService.mark_notifications_read(
                notification_ids=notification_ids,
                user=request.user
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Notification mark read error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to mark notifications as read"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class NotificationMarkAllReadView(BaseAPIView):
    """API endpoint for marking all notifications as read."""
    permission_classes = [IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    
    def post(self, request):
        """Mark all notifications as read for the authenticated user."""
        try:
            success, response_data, status_code = NotificationService.mark_all_read(
                user=request.user
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Notification mark all read error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to mark all notifications as read"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class NotificationStatsView(BaseAPIView):
    """API endpoint for notification statistics."""
    permission_classes = [IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request):
        """Get notification statistics for the authenticated user."""
        try:
            success, response_data, status_code = NotificationService.get_notification_stats(
                user=request.user
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Notification stats fetch error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to fetch notification statistics"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
