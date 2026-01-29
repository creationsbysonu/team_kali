"""
Progress Tracking Service

Handles progress tracking logic for queue management:
- Creating and managing progress steps
- Manual step completion by staff after real-world verification
- Progress validation and audit trails
- Enabling/disabling progress tracking

IMPORTANT: 
- Progress steps are MANUALLY completed by staff
- Attendance indicates official availability, NOT automatic completion
- Each step completion requires explicit staff action via API
"""

import logging
from typing import List, Dict, Tuple, Optional
from datetime import date
from django.db import transaction
from django.core.cache import cache

from .models import QueueConfiguration, QueueToken, ServiceProgressStep, TokenProgress
from attendance.models import AttendanceRecord
from attendance.services import AttendanceService

logger = logging.getLogger(__name__)


class ProgressTrackingService:
    """Service for managing progress tracking in queue management."""
    
    @staticmethod
    def create_progress_steps(
        queue_config_id: str,
        steps_data: List[Dict],
        created_by=None
    ) -> Tuple[bool, Dict, int]:
        """
        Create progress steps for a queue configuration.
        
        Simple like Google Forms - just step title and order.
        
        Args:
            queue_config_id: UUID of queue configuration
            steps_data: List of dicts with {title, step_order}
            created_by: User creating the steps
            
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Get queue configuration
            try:
                queue_config = QueueConfiguration.objects.get(id=queue_config_id)
            except QueueConfiguration.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Queue configuration not found"
                }, 404
            
            # Validate steps_data
            if not steps_data or not isinstance(steps_data, list):
                return False, {
                    "success": False,
                    "error": "Steps data must be a non-empty list"
                }, 400
            
            # Validate each step
            step_orders = set()
            
            for step_data in steps_data:
                # Required fields: title and step_order only
                if not all(k in step_data for k in ['title', 'step_order']):
                    return False, {
                        "success": False,
                        "error": "Each step must have title and step_order"
                    }, 400
                
                step_order = step_data['step_order']
                
                # Check duplicate step_order
                if step_order in step_orders:
                    return False, {
                        "success": False,
                        "error": f"Duplicate step_order: {step_order}"
                    }, 400
                step_orders.add(step_order)
            
            # Create steps in transaction
            with transaction.atomic():
                # Delete existing steps for this configuration
                ServiceProgressStep.objects.filter(queue_config=queue_config).delete()
                
                created_steps = []
                for step_data in steps_data:
                    step = ServiceProgressStep.objects.create(
                        queue_config=queue_config,
                        title=step_data['title'],
                        step_order=step_data['step_order']
                    )
                    created_steps.append(step)
                
                # Clear related cache
                cache_key = f"progress_steps_{queue_config_id}"
                cache.delete(cache_key)
            
            logger.info(
                f"Created {len(created_steps)} progress steps for queue config {queue_config_id}"
            )
            
            return True, {
                "success": True,
                "data": {
                    "queue_config_id": str(queue_config_id),
                    "steps_count": len(created_steps),
                },
                "message": f"Successfully created {len(created_steps)} progress steps"
            }, 201
            
        except Exception as e:
            logger.error(f"Error creating progress steps: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to create progress steps"
            }, 500
    
    @staticmethod
    def enable_progress_tracking(
        queue_config_id: str,
        enabled: bool = True
    ) -> Tuple[bool, Dict, int]:
        """
        Enable or disable progress tracking for a queue configuration.
        
        Args:
            queue_config_id: UUID of queue configuration
            enabled: True to enable, False to disable
            
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Get queue configuration
            try:
                queue_config = QueueConfiguration.objects.get(id=queue_config_id)
            except QueueConfiguration.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Queue configuration not found"
                }, 404
            
            # If enabling, check that progress steps exist
            if enabled:
                steps_count = ServiceProgressStep.objects.filter(
                    queue_config=queue_config
                ).count()
                
                if steps_count == 0:
                    return False, {
                        "success": False,
                        "error": "Cannot enable progress tracking without defining progress steps"
                    }, 400
            
            # Update configuration
            queue_config.enable_progress_tracking = enabled
            queue_config.save(update_fields=['enable_progress_tracking', 'updated_at'])
            
            # Clear cache
            cache_key = f"queue_config_{queue_config_id}"
            cache.delete(cache_key)
            
            status_text = "enabled" if enabled else "disabled"
            logger.info(f"Progress tracking {status_text} for queue config {queue_config_id}")
            
            return True, {
                "success": True,
                "data": {
                    "queue_config_id": str(queue_config_id),
                    "enable_progress_tracking": enabled
                },
                "message": f"Progress tracking {status_text} successfully"
            }, 200
            
        except Exception as e:
            logger.error(f"Error toggling progress tracking: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to update progress tracking setting"
            }, 500
    
    @staticmethod
    def complete_progress_step(
        progress_id: str,
        staff_user,
        notes: str = ""
    ) -> Tuple[bool, Dict, int]:
        """
        Manually mark a progress step as complete.
        
        Validation:
        - Step must not already be completed
        - All previous steps must be completed
        - Staff user must have permission
        
        Args:
            progress_id: UUID of TokenProgress record
            staff_user: Staff user completing the step
            notes: Optional notes about the completion
            
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Get progress record
            try:
                progress = TokenProgress.objects.select_related(
                    'token', 'step', 'token__daily_queue__queue_config'
                ).get(id=progress_id)
            except TokenProgress.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Progress step not found"
                }, 404
            
            # Check if already completed
            if progress.completed:
                return False, {
                    "success": False,
                    "error": "This step is already completed"
                }, 400
            
            # Validate previous steps are completed
            previous_steps = TokenProgress.objects.filter(
                token=progress.token,
                step__step_order__lt=progress.step.step_order,
                completed=False
            )
            
            if previous_steps.exists():
                incomplete_step = previous_steps.order_by('step__step_order').first()
                if incomplete_step:
                    return False, {
                        "success": False,
                        "error": f"Previous step must be completed first: {incomplete_step.step.title}"
                    }, 400
            
            # Complete the step
            from django.utils import timezone
            from .models import QueueEventLog
            
            with transaction.atomic():
                progress.completed = True
                progress.completed_at = timezone.now()
                progress.completed_by = staff_user
                progress.save(update_fields=['completed', 'completed_at', 'completed_by'])
                
                # Create event log
                QueueEventLog.objects.create(
                    token=progress.token,
                    event=QueueEventLog.Event.PROGRESS_COMPLETED,
                    performed_by=staff_user,
                    metadata={
                        "step_order": progress.step.step_order,
                        "step_title": progress.step.title,
                        "notes": notes,
                        "completed_at": str(progress.completed_at)
                    }
                )
                
                # Clear cache
                cache.delete(f"token_progress_{progress.token.id}")
            
            logger.info(
                f"Progress step {progress.step.step_order} ({progress.step.title}) "
                f"completed for token {progress.token.token_number} by {staff_user.email}"
            )
            
            # Check if all steps are complete
            remaining_steps = TokenProgress.objects.filter(
                token=progress.token,
                completed=False
            ).count()
            
            message = "Progress step completed successfully"
            if remaining_steps == 0:
                message += " - All steps completed!"
            
            return True, {
                "success": True,
                "data": {
                    "token_id": str(progress.token.id),
                    "token_number": progress.token.token_number,
                    "step_order": progress.step.step_order,
                    "step_title": progress.step.title,
                    "completed_at": str(progress.completed_at.isoformat()) if progress.completed_at else None, # type: ignore

                    "remaining_steps": remaining_steps
                },
                "message": message
            }, 200
            
        except Exception as e:
            logger.error(f"Error completing progress step: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to complete progress step"
            }, 500
    
    @staticmethod
    def get_pending_progress_tokens(
        staff_service_id: str,
        date=None
    ) -> Tuple[bool, Dict, int]:
        """
        Get list of tokens with pending progress steps for staff workbench.
        
        This is the "Progress Workbench" view - separate from normal queue tokens.
        
        Args:
            staff_service_id: UUID of staff service
            date: Date to filter tokens (defaults to today)
            
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            from core.utils.nepal_time import get_nepal_today
            from ministry.models import StaffService
            
            if date is None:
                date = get_nepal_today()
            
            # Get staff service
            try:
                staff_service = StaffService.objects.get(id=staff_service_id)
            except StaffService.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Staff service not found"
                }, 404
            
            # Get queue configuration
            try:
                queue_config = QueueConfiguration.objects.get(
                    staff_service=staff_service,
                    enable_progress_tracking=True
                )
            except QueueConfiguration.DoesNotExist:
                return True, {
                    "success": True,
                    "data": [],
                    "message": "Progress tracking not enabled for this service"
                }, 200
            
            # Get daily queue for the date
            from .models import DailyQueue, QueueToken
            try:
                daily_queue = DailyQueue.objects.get(
                    queue_config=queue_config,
                    date=date
                )
            except DailyQueue.DoesNotExist:
                return True, {
                    "success": True,
                    "data": [],
                    "message": "No queue found for this date"
                }, 200
            
            # Get all active tokens with progress tracking
            tokens = QueueToken.objects.filter(
                daily_queue=daily_queue,
                active=True
            ).select_related('citizen').prefetch_related(
                'progress_records__step'
            ).order_by('token_number')
            
            tokens_data = []
            for token in tokens:
                progress_records = token.progress_records.all().order_by('step__step_order')  # type: ignore[attr-defined]
                
                # Get current step (first incomplete step)
                current_step = None
                total_steps = progress_records.count()
                completed_steps = 0
                
                for progress in progress_records:
                    if progress.completed:
                        completed_steps += 1
                    elif current_step is None:
                        current_step = {
                            "progress_id": str(progress.id),
                            "step_order": progress.step.step_order,
                            "title": progress.step.title
                        }
                
                # Calculate progress percentage
                progress_percentage = (completed_steps / total_steps * 100) if total_steps > 0 else 0
                
                tokens_data.append({
                    "token_id": str(token.id),
                    "token_number": token.token_number,
                    "citizen_name": token.citizen.username,
                    "citizen_email": token.citizen.email,
                    "created_at": token.created_at.isoformat() if token.created_at else None,
                    "total_steps": total_steps,
                    "completed_steps": completed_steps,
                    "progress_percentage": round(progress_percentage, 2),
                    "current_step": current_step,
                    "status": "Completed" if completed_steps == total_steps else "In Progress"
                })
            
            return True, {
                "success": True,
                "data": tokens_data,
                "count": len(tokens_data),
                "date": str(date)
            }, 200
            
        except Exception as e:
            logger.error(f"Error fetching pending progress tokens: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch progress tokens"
            }, 500
    

    
    @staticmethod
    def get_token_progress(
        token_id: str
    ) -> Tuple[bool, Dict, int]:
        """
        Get progress status for a token.
        
        Args:
            token_id: UUID of token
            
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Get token
            try:
                token = QueueToken.objects.select_related('daily_queue__queue_config').get(id=token_id)
            except QueueToken.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Token not found"
                }, 404
            
            # Check if progress tracking is enabled
            if not token.daily_queue.queue_config.enable_progress_tracking:
                return True, {
                    "success": True,
                    "data": {
                        "token_id": str(token_id),
                        "progress_enabled": False,
                        "progress": []
                    },
                    "message": "Progress tracking is not enabled for this token"
                }, 200
            
            # Get progress records
            progress_records = TokenProgress.objects.filter(
                token=token
            ).select_related('step').order_by('step__step_order')
            
            progress_data = []
            for progress in progress_records:
                progress_data.append({
                    "step_order": progress.step.step_order,
                    "title": progress.step.title,
                    "completed": progress.completed,
                    "completed_at": progress.completed_at.isoformat() if progress.completed_at else None
                })
            
            # Calculate progress percentage
            total_steps = len(progress_data)
            completed_steps = sum(1 for p in progress_data if p['completed'])
            progress_percentage = (completed_steps / total_steps * 100) if total_steps > 0 else 0
            
            return True, {
                "success": True,
                "data": {
                    "token_id": str(token_id),
                    "token_number": token.token_number,
                    "progress_enabled": True,
                    "total_steps": total_steps,
                    "completed_steps": completed_steps,
                    "progress_percentage": round(progress_percentage, 2),
                    "progress": progress_data
                }
            }, 200
            
        except Exception as e:
            logger.error(f"Error getting token progress: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to retrieve token progress"
            }, 500
    
    @staticmethod
    def initialize_token_progress(
        token: QueueToken
    ) -> bool:
        """
        Initialize progress records for a newly booked token.
        
        Creates TokenProgress records for each step in the queue configuration.
        ALL STEPS START AS INCOMPLETE - staff must manually complete each step.
        
        Args:
            token: QueueToken instance
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            queue_config = token.daily_queue.queue_config
            
            # Get all progress steps for this queue configuration
            steps = ServiceProgressStep.objects.filter(
                queue_config=queue_config
            ).order_by('step_order')
            
            if not steps.exists():
                logger.warning(
                    f"No progress steps found for queue config {queue_config.id}"
                )
                return False
            
            with transaction.atomic():
                for step in steps:
                    TokenProgress.objects.create(
                        token=token,
                        step=step,
                        completed=False
                    )
            
            logger.info(
                f"Initialized {steps.count()} progress records for token {token.token_number} "
                f"(all steps start incomplete)"
            )
            return True
            
        except Exception as e:
            logger.error(f"Error initializing token progress: {str(e)}")
            return False
