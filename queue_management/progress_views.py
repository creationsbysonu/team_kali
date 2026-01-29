"""
Views for Progress Tracking in Queue Management.

IMPORTANT CONCEPT:
- Progress tracking is MANUAL, not automatic
- Attendance indicates official availability, NOT work completion
- Staff must explicitly mark each step complete after real-world verification
"""

import logging
import traceback
from rest_framework import status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.throttling import UserRateThrottle

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from core.permissions import IsMinistryAdmin, IsStaffAdminForToday
from .progress_tracking_service import ProgressTrackingService
from .serializers import (
    ServiceProgressStepCreateSerializer,
    ServiceProgressStepSerializer,
    TokenProgressSerializer
)
from .models import ServiceProgressStep, QueueConfiguration, TokenProgress

logger = logging.getLogger(__name__)


class ProgressStepsCreateView(BaseAPIView):
    """API endpoint to create progress steps for a queue configuration."""
    permission_classes = [IsAuthenticated, IsMinistryAdmin]
    throttle_classes = [UserRateThrottle]
    
    def post(self, request, config_id):
        """Create progress steps for queue configuration."""
        try:
            steps_data = request.data.get('steps', [])
            
            if not steps_data:
                return Response(
                    standardized_response(
                        success=False,
                        error="Steps data is required"
                    ),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Validate each step using serializer
            for step_data in steps_data:
                serializer = ServiceProgressStepCreateSerializer(
                    data=step_data,
                    context={'queue_config_id': config_id}
                )
                if not serializer.is_valid():
                    return Response(
                        standardized_response(
                            success=False,
                            error=serializer.errors
                        ),
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            # Create steps using service
            success, response_data, status_code = ProgressTrackingService.create_progress_steps(
                queue_config_id=config_id,
                steps_data=steps_data,
                created_by=request.user
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Progress steps creation error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(
                    success=False,
                    error="Failed to create progress steps"
                ),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ProgressStepsListView(BaseAPIView):
    """API endpoint to list progress steps for a queue configuration."""
    permission_classes = [IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request, config_id):
        """Get list of progress steps for a queue configuration."""
        try:
            # Get queue configuration
            try:
                queue_config = QueueConfiguration.objects.get(id=config_id)
            except QueueConfiguration.DoesNotExist:
                return Response(
                    standardized_response(
                        success=False,
                        error="Queue configuration not found"
                    ),
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Get progress steps
            steps = ServiceProgressStep.objects.filter(
                queue_config=queue_config
            ).select_related('official').order_by('step_order')
            
            serializer = ServiceProgressStepSerializer(steps, many=True)
            
            return Response(
                standardized_response(
                    success=True,
                    data={
                        "queue_config_id": str(config_id),
                        "enable_progress_tracking": queue_config.enable_progress_tracking,
                        "steps": serializer.data
                    }
                ),
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            logger.error(f"Progress steps list error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(
                    success=False,
                    error="Failed to retrieve progress steps"
                ),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ProgressTrackingToggleView(BaseAPIView):
    """API endpoint to enable/disable progress tracking."""
    permission_classes = [IsAuthenticated, IsMinistryAdmin]
    throttle_classes = [UserRateThrottle]
    
    def put(self, request, config_id):
        """Enable or disable progress tracking."""
        try:
            enabled = request.data.get('enabled', True)
            
            # Validate boolean
            if not isinstance(enabled, bool):
                return Response(
                    standardized_response(
                        success=False,
                        error="'enabled' must be a boolean value"
                    ),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            success, response_data, status_code = ProgressTrackingService.enable_progress_tracking(
                queue_config_id=config_id,
                enabled=enabled
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Progress tracking toggle error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(
                    success=False,
                    error="Failed to toggle progress tracking"
                ),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class TokenProgressView(BaseAPIView):
    """API endpoint to get progress status for a token."""
    permission_classes = [IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request, token_id):
        """Get progress status for a token."""
        try:
            success, response_data, status_code = ProgressTrackingService.get_token_progress(
                token_id=token_id
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Token progress retrieval error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(
                    success=False,
                    error="Failed to retrieve token progress"
                ),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class CompleteProgressStepView(BaseAPIView):
    """
    API endpoint for staff to manually mark a progress step as complete.
    
    IMPORTANT:
    - Only staff members can complete progress steps
    - Attendance indicates official availability, NOT automatic completion
    - Each completion requires real-world verification
    """
    permission_classes = [IsAuthenticated, IsStaffAdminForToday]
    throttle_classes = [UserRateThrottle]
    
    def post(self, request, progress_id):
        """
        Manually complete a progress step.
        
        Validates:
        - Step is not already completed
        - Previous steps are completed
        - Staff has permission
        """
        try:
            # Get optional notes
            notes = request.data.get('notes', '')
            
            success, response_data, status_code = ProgressTrackingService.complete_progress_step(
                progress_id=progress_id,
                staff_user=request.user,
                notes=notes
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Progress step completion error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(
                    success=False,
                    error="Failed to complete progress step"
                ),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ProgressWorkbenchView(BaseAPIView):
    """
    API endpoint for staff to view progress-tracked tokens.
    
    This is the "Progress Workbench" - separate from normal queue tokens.
    Shows tokens that require manual progress step completion.
    
    SEPARATION OF CONCERNS:
    - Normal Queue Tokens → /staff/today/ → SERVED/NO-SHOW/CANCEL
    - Progress-Tracked Tokens → /staff/progress-workbench/ → Manual step completion
    """
    permission_classes = [IsAuthenticated, IsStaffAdminForToday]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request):
        """Get list of tokens with pending progress steps."""
        try:
            staff_service_id = request.query_params.get('staff_service_id')
            date_str = request.query_params.get('date')  # Optional
            
            if not staff_service_id:
                return Response(
                    standardized_response(
                        success=False,
                        error="staff_service_id is required"
                    ),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Parse date if provided
            date = None
            if date_str:
                try:
                    from datetime import datetime
                    date = datetime.strptime(date_str, "%Y-%m-%d").date()
                except ValueError:
                    return Response(
                        standardized_response(
                            success=False,
                            error="Invalid date format. Use YYYY-MM-DD"
                        ),
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            success, response_data, status_code = ProgressTrackingService.get_pending_progress_tokens(
                staff_service_id=staff_service_id,
                date=date
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Progress workbench error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(
                    success=False,
                    error="Failed to fetch progress workbench data"
                ),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
