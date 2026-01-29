"""
Celery Tasks for Queue Management

Scheduled tasks:
- End-of-day token auto-cancellation
- Daily queue auto-creation
- Auto-complete token after service countdown
- Email notifications 30 minutes before turn
"""
import logging
from celery import shared_task
from datetime import timedelta
from django.utils import timezone

from .services import TokenManagementService, DailyQueueService
from .models import QueueConfiguration, QueueToken, QueueEventLog
from core.utils.nepal_time import get_nepal_today

logger = logging.getLogger(__name__)


@shared_task(
    bind=True,
    autoretry_for=(Exception,),
    retry_kwargs={'max_retries': 3},
    retry_backoff=True,
    retry_backoff_max=60,
    name="queue_management.end_of_day_auto_cancel"
)
def end_of_day_auto_cancel_tokens(self, date_str=None):
    """
    Celery task to auto-cancel all active tokens at end of day.
    
    Should be scheduled to run daily at end of office hours (e.g., 6:00 PM Nepal Time).
    
    Args:
        date_str: Optional date string in YYYY-MM-DD format (defaults to today)
    """
    try:
        from datetime import datetime
        
        if date_str:
            date = datetime.strptime(date_str, '%Y-%m-%d').date()
        else:
            date = get_nepal_today()
        
        logger.info(f"Starting end-of-day auto-cancellation task for {date}")
        
        success, response_data, status_code = TokenManagementService.auto_cancel_end_of_day_tokens(date)
        
        if success:
            logger.info(
                f"End-of-day auto-cancellation completed successfully: "
                f"{response_data.get('data', {}).get('total_cancelled', 0)} tokens cancelled"
            )
        else:
            logger.error(f"End-of-day auto-cancellation failed: {response_data.get('error')}")
            raise Exception(response_data.get('error', 'Auto-cancellation failed'))
        
        return response_data
        
    except Exception as e:
        logger.error(f"End-of-day auto-cancellation task failed on attempt {self.request.retries}: {e}")
        raise e


@shared_task(
    bind=True,
    autoretry_for=(Exception,),
    retry_kwargs={'max_retries': 3},
    retry_backoff=True,
    name="queue_management.create_daily_queues"
)
def create_daily_queues_for_tomorrow(self):
    """
    Celery task to create daily queues for tomorrow.
    
    Should be scheduled to run daily at midnight Nepal Time.
    Creates queues for all active queue configurations.
    """
    try:
        from datetime import datetime
        
        tomorrow = get_nepal_today() + timedelta(days=1)
        
        logger.info(f"Starting daily queue creation for {tomorrow}")
        
        # Get all active queue configurations
        queue_configs = QueueConfiguration.objects.filter(active=True)
        
        created_count = 0
        skipped_count = 0
        
        for config in queue_configs:
            try:
                success, response_data, status_code = DailyQueueService.create_daily_queue(
                    config, tomorrow
                )
                
                if success:
                    created_count += 1
                    logger.info(f"Created daily queue for {config.staff_service.service_name} on {tomorrow}")
                else:
                    skipped_count += 1
                    error_msg = response_data.get('error', 'Unknown error') if isinstance(response_data, dict) else 'Unknown error'
                    logger.warning(
                        f"Skipped queue creation for {config.staff_service.service_name}: "
                        f"{error_msg}"
                    )
                    
            except Exception as e:
                logger.error(
                    f"Error creating queue for {config.staff_service.service_name}: {str(e)}"
                )
                skipped_count += 1
        
        logger.info(
            f"Daily queue creation completed: "
            f"{created_count} created, {skipped_count} skipped"
        )
        
        return {
            "success": True,
            "date": str(tomorrow),
            "created": created_count,
            "skipped": skipped_count
        }
        
    except Exception as e:
        logger.error(f"Daily queue creation task failed on attempt {self.request.retries}: {e}")
        raise e


@shared_task(name="queue_management.cleanup_old_tokens")
def cleanup_old_tokens():
    """
    Celery task to cleanup old token data (optional maintenance task).
    
    Can be run weekly/monthly to archive or cleanup tokens older than X days.
    """
    try:
        from datetime import datetime
        from .models import QueueToken
        
        # Example: Archive tokens older than 90 days
        cutoff_date = get_nepal_today() - timedelta(days=90)
        
        logger.info(f"Starting token cleanup for dates before {cutoff_date}")
        
        # You can implement archival logic here
        # For now, just log the count
        old_tokens_count = QueueToken.objects.filter(
            daily_queue__date__lt=cutoff_date
        ).count()
        
        logger.info(f"Found {old_tokens_count} tokens older than {cutoff_date}")
        
        return {
            "success": True,
            "cutoff_date": str(cutoff_date),
            "old_tokens_count": old_tokens_count
        }
        
    except Exception as e:
        logger.error(f"Token cleanup task failed: {e}")
        raise e


@shared_task(
    bind=True,
    autoretry_for=(Exception,),
    retry_kwargs={'max_retries': 2},
    name="queue_management.auto_complete_token"
)
def auto_complete_token(self, token_id: str):
    """
    Auto-complete a token after service countdown ends.
    
    Called automatically after average_service_time_minutes from service start.
    Token is marked as COMPLETED by the SYSTEM (not staff).
    
    Args:
        token_id: UUID of the token to complete
    """
    try:
        from django.db import transaction
        
        try:
            token = QueueToken.objects.select_related(
                'daily_queue__queue_config',
                'citizen'
            ).get(id=token_id)
        except QueueToken.DoesNotExist:
            logger.warning(f"Token {token_id} not found for auto-completion")
            return {"success": False, "error": "Token not found"}
        
        # Only auto-complete if still IN_SERVICE
        if token.status != QueueToken.Status.IN_SERVICE:
            logger.info(
                f"Token {token.token_number} not auto-completed: "
                f"current status is {token.status} (not IN_SERVICE)"
            )
            return {
                "success": False,
                "reason": f"Token status is {token.status}, not IN_SERVICE"
            }
        
        with transaction.atomic():
            # Mark as completed
            token.status = QueueToken.Status.COMPLETED
            token.active = False
            token.save(update_fields=['status', 'active'])
            
            # Create event log (performed by SYSTEM - no user)
            QueueEventLog.objects.create(
                token=token,
                event=QueueEventLog.Event.COMPLETED,
                performed_by=None,  # System action
                metadata={
                    "token_number": token.token_number,
                    "auto_completed": True,
                    "service_started_at": str(token.service_started_at),
                    "completed_at": str(timezone.now())
                }
            )
            
            logger.info(
                f"Token {token.token_number} auto-completed after service countdown"
            )
            
            # Send completion notification
            from notifications.services import NotificationService
            NotificationService.send_token_completed_notification(token)
            
            return {
                "success": True,
                "token_number": token.token_number,
                "status": "COMPLETED"
            }
            
    except Exception as e:
        logger.error(f"Auto-complete task failed for token {token_id}: {e}")
        raise e


@shared_task(
    bind=True,
    name="queue_management.send_upcoming_token_notifications"
)
def send_upcoming_token_notifications(self):
    """
    Send email notifications to citizens whose tokens are coming up in 30 minutes.
    
    Should be scheduled to run every 5-10 minutes during office hours.
    Changed from 15 minutes to 30 minutes as per specification.
    """
    try:
        from datetime import datetime
        from django.utils import timezone
        
        now = timezone.now()
        notification_window_start = now + timedelta(minutes=25)  # Buffer
        notification_window_end = now + timedelta(minutes=35)    # 30 min window
        
        today = get_nepal_today()
        
        # Get tokens that:
        # 1. Are for today
        # 2. Status is WAITING
        # 3. Expected service time is within 30 minutes
        # 4. Haven't been notified yet (check event log)
        
        upcoming_tokens = QueueToken.objects.filter(
            daily_queue__date=today,
            status=QueueToken.Status.WAITING,
            expected_service_time__gte=notification_window_start,
            expected_service_time__lte=notification_window_end
        ).select_related(
            'citizen',
            'daily_queue__queue_config__staff_service'
        )
        
        notifications_sent = 0
        
        for token in upcoming_tokens:
            # Check if already notified
            already_notified = QueueEventLog.objects.filter(
                token=token,
                event='UPCOMING_NOTIFICATION'
            ).exists()
            
            if already_notified:
                continue
            
            # Send notification
            from notifications.services import NotificationService
            NotificationService.send_token_upcoming_notification(token)
            
            # Log the notification
            QueueEventLog.objects.create(
                token=token,
                event='UPCOMING_NOTIFICATION',
                performed_by=None,  # System action
                metadata={
                    "token_number": token.token_number,
                    "expected_time": str(token.expected_service_time),
                    "notified_at": str(now)
                }
            )
            
            notifications_sent += 1
            logger.info(
                f"Sent upcoming notification for token {token.token_number} "
                f"to {token.citizen.email}"
            )
        
        logger.info(
            f"Upcoming token notifications task completed: "
            f"{notifications_sent} notifications sent"
        )
        
        return {
            "success": True,
            "notifications_sent": notifications_sent
        }
        
    except Exception as e:
        logger.error(f"Upcoming token notifications task failed: {e}")
        raise e


@shared_task(
    bind=True,
    name="queue_management.process_priority_pending_tokens"
)
def process_priority_pending_tokens(self):
    """
    Process pending tokens that have priority for today.
    
    Should be scheduled to run early morning before office opens.
    Sends notifications to citizens with pending tokens that get priority today.
    """
    try:
        today = get_nepal_today()
        
        # Get pending tokens with priority for today
        priority_tokens = QueueToken.objects.filter(
            status=QueueToken.Status.PENDING,
            pending_priority_date=today
        ).select_related(
            'citizen',
            'daily_queue__queue_config__staff_service'
        )
        
        notifications_sent = 0
        
        for token in priority_tokens:
            # Send priority notification
            from notifications.services import NotificationService
            NotificationService.send_priority_service_notification(token)
            
            # Log the event
            QueueEventLog.objects.create(
                token=token,
                event=QueueEventLog.Event.PRIORITY_RESTORED,
                performed_by=None,  # System action
                metadata={
                    "token_number": token.token_number,
                    "priority_date": str(today),
                    "original_reason": token.pending_reason
                }
            )
            
            notifications_sent += 1
            logger.info(
                f"Sent priority notification for pending token {token.token_number} "
                f"to {token.citizen.email}"
            )
        
        logger.info(
            f"Priority pending tokens task completed: "
            f"{notifications_sent} notifications sent"
        )
        
        return {
            "success": True,
            "notifications_sent": notifications_sent
        }
        
    except Exception as e:
        logger.error(f"Priority pending tokens task failed: {e}")
        raise e