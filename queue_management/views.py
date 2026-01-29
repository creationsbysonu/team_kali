"""
Views for Queue Management System.
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
from core.permissions import IsMinistryAdmin, IsStaffAdminForToday, IsCitizen
from .services import (
    QueueConfigurationService,
    DailyQueueService,
    TokenBookingService,
    TokenManagementService
)
from .serializers import (
    QueueConfigurationCreateSerializer,
    QueueConfigurationSerializer,
    QueueTokenBookingSerializer,
    QueueTokenStaffActionSerializer
)

logger = logging.getLogger(__name__)


# ============================================================================
# MINISTRY ADMIN ENDPOINTS
# ============================================================================

class QueueConfigurationView(BaseAPIView):
    """
    API endpoint for queue configuration.
    GET: Retrieve queue config by staff_service_id
    POST: Create or update queue configuration
    """
    permission_classes = [IsAuthenticated, IsMinistryAdmin]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request):
        """Get queue configuration by staff_service_id."""
        try:
            staff_service_id = request.query_params.get('staff_service')
            
            if not staff_service_id:
                return Response(
                    standardized_response(
                        success=False,
                        error="staff_service query parameter is required"
                    ),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            from django.db import connection, reset_queries
            from django.db.utils import OperationalError, InterfaceError
            from .models import QueueConfiguration
            from .serializers import QueueConfigurationSerializer
            import time
            
            max_retries = 5
            last_error = None
            
            for attempt in range(max_retries + 1):
                try:
                    if attempt > 0:
                        logger.info(f"Queue config retry {attempt + 1} for {staff_service_id}")
                        time.sleep(0.5 * attempt)
                    
                    # Ensure we have a valid connection
                    if connection.connection is None or not connection.is_usable():
                        connection.close()
                        connection.ensure_connection()
                    
                    configs = list(QueueConfiguration.objects.filter(
                        staff_service_id=staff_service_id,
                        ministry=request.ministry
                    ))
                    
                    serializer = QueueConfigurationSerializer(
                        configs,
                        many=True,
                        context={'request': request}
                    )
                    
                    return Response(
                        standardized_response(
                            success=True,
                            data={"results": serializer.data}
                        ),
                        status=status.HTTP_200_OK
                    )
                    
                except (OperationalError, InterfaceError) as e:
                    last_error = e
                    logger.warning(f"Queue config DB error attempt {attempt + 1}: {str(e)}")
                    connection.close()
                    if attempt < max_retries:
                        continue
                    break
                except Exception as e:
                    last_error = e
                    logger.warning(f"Queue config error attempt {attempt + 1}: {str(e)}")
                    if 'closed' in str(e).lower() and attempt < max_retries:
                        connection.close()
                        continue
                    break
            
            logger.error(f"Queue config failed after {max_retries + 1} attempts: {str(last_error)}")
            
            return Response(
                standardized_response(
                    success=True,
                    data={"results": []}
                ),
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            logger.error(f"Queue configuration GET error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to fetch queue configuration"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def post(self, request):
        """Create or update queue configuration."""
        try:
            # Check if config already exists for this staff service
            staff_service_id = request.data.get('staff_service')
            existing_config = None
            
            if staff_service_id:
                from .models import QueueConfiguration
                try:
                    existing_config = QueueConfiguration.objects.get(staff_service_id=staff_service_id)
                except QueueConfiguration.DoesNotExist:
                    pass
            
            # Use existing instance for update, or None for create
            serializer = QueueConfigurationCreateSerializer(
                instance=existing_config,
                data=request.data,
                context={'request': request}
            )
            
            if not serializer.is_valid():
                return Response(
                    standardized_response(success=False, error=serializer.errors),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Save (will call update() if instance exists, create() if not)
            queue_config = serializer.save()
            
            # Return the config using the read serializer
            response_serializer = QueueConfigurationSerializer(queue_config)
            
            message = "Queue configuration updated successfully" if existing_config else "Queue configuration created successfully"
            status_code = status.HTTP_200_OK if existing_config else status.HTTP_201_CREATED
            
            return Response(
                standardized_response(
                    success=True,
                    data=response_serializer.data,
                    message=message
                ),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Queue configuration error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to configure queue"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ============================================================================
# STAFF ADMIN ENDPOINTS (TODAY'S QUEUE ONLY)
# ============================================================================

class TodaysQueueView(BaseAPIView):
    """API endpoint for viewing today's queue."""
    permission_classes = [IsAuthenticated, IsStaffAdminForToday]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request):
        """Get today's queue for a staff service."""
        try:
            staff_service_id = request.query_params.get('staff_service_id')
            
            if not staff_service_id:
                return Response(
                    standardized_response(
                        success=False,
                        error="staff_service_id is required"
                    ),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            success, response_data, status_code = TokenManagementService.get_todays_queue(
                staff_service_id=staff_service_id
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Today's queue fetch error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to fetch today's queue"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class TokenServedView(BaseAPIView):
    """API endpoint for marking token as served."""
    permission_classes = [IsAuthenticated, IsStaffAdminForToday]
    throttle_classes = [UserRateThrottle]
    
    def post(self, request):
        """Mark a token as served."""
        try:
            token_id = request.data.get('token_id')
            
            if not token_id:
                return Response(
                    standardized_response(
                        success=False,
                        error="token_id is required"
                    ),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            success, response_data, status_code = TokenManagementService.mark_token_served(
                token_id=token_id,
                staff_user=request.user
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Token served error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to mark token as served"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class TokenNoShowView(BaseAPIView):
    """API endpoint for marking token as no-show."""
    permission_classes = [IsAuthenticated, IsStaffAdminForToday]
    throttle_classes = [UserRateThrottle]
    
    def post(self, request):
        """Mark a token as no-show."""
        try:
            token_id = request.data.get('token_id')
            
            if not token_id:
                return Response(
                    standardized_response(
                        success=False,
                        error="token_id is required"
                    ),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            success, response_data, status_code = TokenManagementService.mark_token_no_show(
                token_id=token_id,
                staff_user=request.user
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Token no-show error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to mark token as no-show"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ============================================================================
# STAFF ADMIN PANEL ENDPOINTS (New: Active Tokens, All Tokens, Pending Tokens)
# ============================================================================

class StaffActiveTokensView(BaseAPIView):
    """
    API endpoint for active tokens (Staff Admin Panel).
    
    Shows tokens that are currently WAITING or IN_SERVICE for today.
    Staff can mark tokens as NO_SHOW or PENDING from this view.
    
    Token auto-completes after countdown - staff does NOT click SERVED.
    """
    permission_classes = [IsAuthenticated, IsStaffAdminForToday]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request):
        """Get active tokens for today's queue."""
        try:
            staff_service_id = request.query_params.get('staff_service_id')
            
            if not staff_service_id:
                return Response(
                    standardized_response(
                        success=False,
                        error="staff_service_id is required"
                    ),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            from .services import StaffPanelService
            success, response_data, status_code = StaffPanelService.get_active_tokens(
                staff_service_id=staff_service_id
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Active tokens fetch error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to fetch active tokens"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class StaffAllTokensView(BaseAPIView):
    """
    API endpoint for all tokens (Staff Admin Panel).
    
    Shows all tokens for today with complete status history.
    Read-only view for staff reference.
    """
    permission_classes = [IsAuthenticated, IsStaffAdminForToday]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request):
        """Get all tokens for today's queue."""
        try:
            staff_service_id = request.query_params.get('staff_service_id')
            
            if not staff_service_id:
                return Response(
                    standardized_response(
                        success=False,
                        error="staff_service_id is required"
                    ),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            from .services import StaffPanelService
            success, response_data, status_code = StaffPanelService.get_all_tokens(
                staff_service_id=staff_service_id
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"All tokens fetch error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to fetch all tokens"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class StaffPendingTokensView(BaseAPIView):
    """
    API endpoint for pending tokens (Staff Admin Panel).
    
    Shows tokens marked as PENDING due to government/system fault.
    Staff can send notification email or mark as served when citizen returns.
    """
    permission_classes = [IsAuthenticated, IsStaffAdminForToday]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request):
        """Get pending tokens for this service."""
        try:
            staff_service_id = request.query_params.get('staff_service_id')
            
            if not staff_service_id:
                return Response(
                    standardized_response(
                        success=False,
                        error="staff_service_id is required"
                    ),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            from .services import PendingTokenService
            success, response_data, status_code = PendingTokenService.get_pending_tokens(
                staff_service_id=staff_service_id
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Pending tokens fetch error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to fetch pending tokens"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class StaffMarkPendingView(BaseAPIView):
    """
    API endpoint for marking a token as PENDING (Staff Admin Panel).
    
    Used when service cannot be completed due to government/system fault.
    Token gets priority service on the next working day.
    """
    permission_classes = [IsAuthenticated, IsStaffAdminForToday]
    throttle_classes = [UserRateThrottle]
    
    def post(self, request, token_id):
        """Mark a token as pending."""
        try:
            from .serializers import MarkPendingSerializer
            serializer = MarkPendingSerializer(data=request.data)
            
            if not serializer.is_valid():
                return Response(
                    standardized_response(success=False, error=serializer.errors),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            from .services import PendingTokenService
            success, response_data, status_code = PendingTokenService.mark_token_pending(
                token_id=str(token_id),
                staff_user=request.user,
                reason=serializer.validated_data['reason']
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Mark pending error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to mark token as pending"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class StaffPendingEmailView(BaseAPIView):
    """
    API endpoint for sending pending notification email (Staff Admin Panel).
    
    Sends email to citizen informing them about their pending token
    and the priority date for service.
    """
    permission_classes = [IsAuthenticated, IsStaffAdminForToday]
    throttle_classes = [UserRateThrottle]
    
    def post(self, request, token_id):
        """Send pending notification email."""
        try:
            from .services import PendingTokenService
            success, response_data, status_code = PendingTokenService.send_pending_email(
                token_id=str(token_id),
                staff_user=request.user
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Pending email error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to send pending email"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class StaffPendingServedView(BaseAPIView):
    """
    API endpoint for marking a pending token as served (Staff Admin Panel).
    
    Used when citizen returns on their priority date.
    """
    permission_classes = [IsAuthenticated, IsStaffAdminForToday]
    throttle_classes = [UserRateThrottle]
    
    def post(self, request, token_id):
        """Mark pending token as served."""
        try:
            from .services import PendingTokenService
            success, response_data, status_code = PendingTokenService.mark_pending_served(
                token_id=str(token_id),
                staff_user=request.user
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Pending served error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to mark pending token as served"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class StaffStartServiceView(BaseAPIView):
    """
    API endpoint for starting token service (Staff Admin Panel).
    
    Called when it's a token's turn. Starts countdown timer.
    Token will auto-complete after average_service_time_minutes.
    """
    permission_classes = [IsAuthenticated, IsStaffAdminForToday]
    throttle_classes = [UserRateThrottle]
    
    def post(self, request, token_id):
        """Start service for a token."""
        try:
            from .services import StaffPanelService
            success, response_data, status_code = StaffPanelService.start_token_service(
                token_id=str(token_id),
                staff_user=request.user
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Start service error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to start token service"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ============================================================================
# CITIZEN ENDPOINTS
# ============================================================================

class QueueAvailabilityView(BaseAPIView):
    """API endpoint for checking queue availability."""
    permission_classes = [IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request):
        """Check if queue is available for booking."""
        try:
            staff_service_id = request.query_params.get('staff_service_id')
            date_str = request.query_params.get('date')
            
            if not all([staff_service_id, date_str]):
                return Response(
                    standardized_response(
                        success=False,
                        error="staff_service_id and date are required"
                    ),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Parse date
            try:
                date = datetime.strptime(date_str, "%Y-%m-%d").date()
            except ValueError:
                return Response(
                    standardized_response(
                        success=False,
                        error="Invalid date format. Use YYYY-MM-DD"
                    ),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            success, response_data, status_code = DailyQueueService.check_queue_availability(
                staff_service_id=staff_service_id,
                date=date
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Queue availability check error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to check queue availability"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class TokenBookingView(BaseAPIView):
    """API endpoint for booking queue tokens."""
    permission_classes = [IsAuthenticated, IsCitizen]
    throttle_classes = [UserRateThrottle]
    
    def post(self, request):
        """Book a queue token."""
        try:
            serializer = QueueTokenBookingSerializer(data=request.data)
            
            if not serializer.is_valid():
                return Response(
                    standardized_response(success=False, error=serializer.errors),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            validated_data = serializer.validated_data
            
            success, response_data, status_code = TokenBookingService.book_token(
                citizen=request.user,
                staff_service_id=validated_data['staff_service_id'],  # type: ignore[index]\n                date=validated_data['date']  # type: ignore[index]
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Token booking error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to book token"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class MyTokensView(BaseAPIView):
    """API endpoint for viewing citizen's tokens."""
    permission_classes = [IsAuthenticated, IsCitizen]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request):
        """Get all tokens for the authenticated citizen."""
        try:
            success, response_data, status_code = TokenManagementService.get_my_tokens(
                citizen=request.user
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"My tokens fetch error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to fetch tokens"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class TokenCancelView(BaseAPIView):
    """API endpoint for cancelling tokens."""
    permission_classes = [IsAuthenticated, IsCitizen]
    throttle_classes = [UserRateThrottle]
    
    def post(self, request):
        """Cancel a token."""
        try:
            token_id = request.data.get('token_id')
            reason = request.data.get('reason', '')
            
            if not token_id:
                return Response(
                    standardized_response(
                        success=False,
                        error="token_id is required"
                    ),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            success, response_data, status_code = TokenManagementService.cancel_token(
                token_id=token_id,
                user=request.user,
                reason=reason
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Token cancel error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to cancel token"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class EndOfDayAutoCancelView(BaseAPIView):
    """API endpoint for manually triggering end-of-day auto-cancellation (Admin only)."""
    permission_classes = [IsAuthenticated, IsMinistryAdmin]
    throttle_classes = [UserRateThrottle]
    
    def post(self, request):
        """Manually trigger end-of-day auto-cancellation for a specific date."""
        try:
            date_str = request.data.get('date')  # Optional: defaults to today
            
            # Parse date if provided
            date = None
            if date_str:
                try:
                    from datetime import datetime
                    date = datetime.strptime(date_str, '%Y-%m-%d').date()
                except ValueError:
                    return Response(
                        standardized_response(
                            success=False,
                            error="Invalid date format. Use YYYY-MM-DD"
                        ),
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            success, response_data, status_code = TokenManagementService.auto_cancel_end_of_day_tokens(date)
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"End-of-day auto-cancel error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to auto-cancel tokens"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

