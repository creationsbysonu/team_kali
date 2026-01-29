"""
Business logic for Notification System.

This service handles:
- Sending notifications for all queue events
- Marking notifications as read
- Fetching user notifications
"""

import logging
from django.db import transaction

from .models import Notification

logger = logging.getLogger(__name__)


class NotificationService:
    """Service class for handling notification business logic."""
    
    @staticmethod
    def send_notification(user, title, message, queue_token=None):
        """
        Send a notification to a user.
        
        Args:
            user: CustomUser instance
            title: Notification title
            message: Notification message
            queue_token: Optional QueueToken instance
            
        Returns:
            Notification instance or None
        """
        try:
            notification = Notification.objects.create(
                user=user,
                title=title,
                message=message,
                queue_token=queue_token,
                read=False
            )
            
            logger.info(f"Notification sent to {user.email}: {title}")
            return notification
            
        except Exception as e:
            logger.error(f"Error sending notification: {str(e)}")
            return None
    
    @staticmethod
    def send_token_booked_notification(token):
        """Send notification when token is booked."""
        staff_service = token.daily_queue.queue_config.staff_service
        
        title = "Token Booked Successfully"
        message = (
            f"Your token #{token.token_number} has been booked for "
            f"{staff_service.name} at {staff_service.ministry.name} "
            f"on {token.daily_queue.date}. "
            f"Expected service time: {token.expected_service_time.strftime('%I:%M %p')}"
        )
        
        return NotificationService.send_notification(
            user=token.citizen,
            title=title,
            message=message,
            queue_token=token
        )
    
    @staticmethod
    def send_token_served_notification(token):
        """Send notification when token is served."""
        title = "Service Completed"
        message = f"Your token #{token.token_number} has been served. Thank you for visiting!"
        
        return NotificationService.send_notification(
            user=token.citizen,
            title=title,
            message=message,
            queue_token=token
        )
    
    @staticmethod
    def send_token_pushed_notification(token, old_number, new_number):
        """Send notification when token is pushed back."""
        title = "Token Rescheduled"
        message = (
            f"You missed your turn for token #{old_number}. "
            f"Your token has been moved to #{new_number}. "
            f"New expected time: {token.expected_service_time.strftime('%I:%M %p')}. "
            f"Please arrive on time. This is warning {token.no_show_count}/2."
        )
        
        return NotificationService.send_notification(
            user=token.citizen,
            title=title,
            message=message,
            queue_token=token
        )
    
    @staticmethod
    def send_token_cancelled_notification(token, reason):
        """Send notification when token is cancelled."""
        title = "Token Cancelled"
        message = f"Your token #{token.token_number} has been cancelled. Reason: {reason}"
        
        return NotificationService.send_notification(
            user=token.citizen,
            title=title,
            message=message,
            queue_token=token
        )
    
    @staticmethod
    def mark_notifications_read(notification_ids, user):
        """
        Mark notifications as read.
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Validate notifications belong to user
            notifications = Notification.objects.filter(
                id__in=notification_ids,
                user=user
            )
            
            if notifications.count() != len(notification_ids):
                return False, {
                    "success": False,
                    "error": "Some notification IDs are invalid or do not belong to you"
                }, 400
            
            # Mark as read
            updated_count = notifications.update(read=True)
            
            logger.info(f"{updated_count} notifications marked as read for {user.email}")
            
            return True, {
                "success": True,
                "message": f"{updated_count} notifications marked as read"
            }, 200
            
        except Exception as e:
            logger.error(f"Error marking notifications as read: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to mark notifications as read"
            }, 500
    
    @staticmethod
    def mark_all_read(user):
        """
        Mark all notifications as read for a user.
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            updated_count = Notification.objects.filter(
                user=user,
                read=False
            ).update(read=True)
            
            logger.info(f"All {updated_count} notifications marked as read for {user.email}")
            
            return True, {
                "success": True,
                "message": f"{updated_count} notifications marked as read"
            }, 200
            
        except Exception as e:
            logger.error(f"Error marking all notifications as read: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to mark all notifications as read"
            }, 500
    
    @staticmethod
    def get_notifications(user, unread_only=False, limit=50):
        """
        Get notifications for a user.
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            queryset = Notification.objects.filter(user=user)
            
            if unread_only:
                queryset = queryset.filter(read=False)
            
            notifications = queryset.select_related('queue_token').order_by('-created_at')[:limit]
            
            notifications_data = []
            for notif in notifications:
                notifications_data.append({
                    "id": str(notif.id),
                    "title": notif.title,
                    "message": notif.message,
                    "read": notif.read,
                    "token_number": notif.queue_token.token_number if notif.queue_token else None,
                    "created_at": str(notif.created_at),
                })
            
            return True, {
                "success": True,
                "data": notifications_data,
                "count": len(notifications_data)
            }, 200
            
        except Exception as e:
            logger.error(f"Error fetching notifications: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch notifications"
            }, 500
    
    @staticmethod
    def get_notification_stats(user):
        """
        Get notification statistics for a user.
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            total_count = Notification.objects.filter(user=user).count()
            unread_count = Notification.objects.filter(user=user, read=False).count()
            read_count = total_count - unread_count
            
            latest_notification = Notification.objects.filter(
                user=user
            ).order_by('-created_at').first()
            
            latest_data = None
            if latest_notification:
                latest_data = {
                    "id": str(latest_notification.id),
                    "title": latest_notification.title,
                    "message": latest_notification.message,
                    "read": latest_notification.read,
                    "created_at": str(latest_notification.created_at),
                }
            
            return True, {
                "success": True,
                "data": {
                    "total_count": total_count,
                    "unread_count": unread_count,
                    "read_count": read_count,
                    "latest_notification": latest_data,
                }
            }, 200
            
        except Exception as e:
            logger.error(f"Error fetching notification stats: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch notification statistics"
            }, 500
    
    @staticmethod
    def send_progress_completed(token, step):
        """
        Send notification when a progress step is completed.
        
        Args:
            token: QueueToken instance
            step: ServiceProgressStep instance
        """
        title = "Progress Update"
        message = (
            f"Step {step.step_order} ({step.title}) has been completed "
            f"for your token #{token.token_number}. "
            f"Official {step.official.name} has processed your request."
        )
        
        return NotificationService.send_notification(
            user=token.citizen,
            title=title,
            message=message,
            queue_token=token
        )
    
    @staticmethod
    def send_official_absent_warning(token, official, date):
        """
        Send notification when assigned official is absent.
        
        Args:
            token: QueueToken instance
            official: MinistryOfficial instance
            date: Date when official is absent
        """
        title = "Service Delay Notice"
        message = (
            f"Please note: {official.name} ({official.role}) is absent on {date}. "
            f"Your token #{token.token_number} may experience delays. "
            f"We apologize for any inconvenience."
        )
        
        return NotificationService.send_notification(
            user=token.citizen,
            title=title,
            message=message,
            queue_token=token
        )

    # ========================================================
    # NEW: Staff Panel Notification Methods
    # ========================================================
    
    @staticmethod
    def send_token_pending_notification(token, reason):
        """
        Send notification when token is marked as PENDING.
        
        Citizen is informed about:
        - Why their token couldn't be served (government/system fault)
        - When they will get priority service (pending_priority_date)
        
        Args:
            token: QueueToken instance
            reason: Reason for pending status
        """
        staff_service = token.daily_queue.queue_config.staff_service
        priority_date = token.pending_priority_date
        
        title = "Service Pending - Action Required"
        message = (
            f"Your token #{token.token_number} for {staff_service.name} "
            f"could not be completed today due to: {reason}. "
            f"\n\nYou have been given PRIORITY SERVICE for {priority_date.strftime('%B %d, %Y')}. "
            f"Please visit the office on this date - you will be served first. "
            f"\n\nWe apologize for the inconvenience."
        )
        
        return NotificationService.send_notification(
            user=token.citizen,
            title=title,
            message=message,
            queue_token=token
        )
    
    @staticmethod
    def send_pending_email_notification(token):
        """
        Send email notification for pending token with detailed instructions.
        
        This is triggered when staff clicks "Send Email" in pending tokens section.
        
        Args:
            token: QueueToken instance with status=PENDING
        """
        staff_service = token.daily_queue.queue_config.staff_service
        ministry = staff_service.ministry
        priority_date = token.pending_priority_date
        
        title = "Important: Your Pending Service Appointment"
        message = (
            f"Dear {token.citizen.username},\n\n"
            f"We are writing to inform you about your pending service at {ministry.name}.\n\n"
            f"Service: {staff_service.name}\n"
            f"Original Token: #{token.token_number}\n"
            f"Reason for Delay: {token.pending_reason or 'Government/System Issue'}\n\n"
            f"IMPORTANT: You have been scheduled for PRIORITY SERVICE on "
            f"{priority_date.strftime('%B %d, %Y')}.\n\n"
            f"On this date, please arrive during office hours. You will be served "
            f"before other citizens in the queue.\n\n"
            f"If you cannot attend on this date, please contact us to reschedule.\n\n"
            f"We sincerely apologize for any inconvenience caused.\n\n"
            f"Best regards,\n{ministry.name}"
        )
        
        return NotificationService.send_notification(
            user=token.citizen,
            title=title,
            message=message,
            queue_token=token
        )
    
    @staticmethod
    def send_token_upcoming_notification(token):
        """
        Send notification 30 minutes before token's turn.
        
        Citizen is reminded to arrive for their appointment.
        
        Args:
            token: QueueToken instance
        """
        staff_service = token.daily_queue.queue_config.staff_service
        expected_time = token.expected_service_time
        
        title = "Your Turn is Coming Up!"
        message = (
            f"Your token #{token.token_number} for {staff_service.name} "
            f"will be called in approximately 30 minutes "
            f"(around {expected_time.strftime('%I:%M %p')}). "
            f"\n\nPlease ensure you are present at the counter. "
            f"Missing your turn may result in your token being pushed back."
        )
        
        return NotificationService.send_notification(
            user=token.citizen,
            title=title,
            message=message,
            queue_token=token
        )
    
    @staticmethod
    def send_token_completed_notification(token):
        """
        Send notification when token service is auto-completed.
        
        This is sent when the countdown timer ends and the system
        automatically marks the token as COMPLETED.
        
        Args:
            token: QueueToken instance
        """
        staff_service = token.daily_queue.queue_config.staff_service
        
        title = "Service Completed"
        message = (
            f"Your service for token #{token.token_number} at {staff_service.name} "
            f"has been completed. "
            f"\n\nThank you for visiting {staff_service.ministry.name}. "
            f"We hope you had a good experience!"
        )
        
        return NotificationService.send_notification(
            user=token.citizen,
            title=title,
            message=message,
            queue_token=token
        )
    
    @staticmethod
    def send_priority_service_notification(token):
        """
        Send notification for pending tokens on their priority date.
        
        Reminds citizen that today is their priority service day.
        
        Args:
            token: QueueToken instance with pending_priority_date=today
        """
        staff_service = token.daily_queue.queue_config.staff_service
        ministry = staff_service.ministry
        
        title = "Your Priority Service Day is Today!"
        message = (
            f"Good morning! Today is your priority service day for "
            f"token #{token.token_number} at {staff_service.name}.\n\n"
            f"Your service was postponed on {token.daily_queue.date.strftime('%B %d, %Y')} "
            f"due to: {token.pending_reason or 'Government/System Issue'}.\n\n"
            f"Please visit {ministry.name} during office hours today. "
            f"You will be served with priority before other citizens in the queue.\n\n"
            f"We look forward to serving you today!"
        )
        
        return NotificationService.send_notification(
            user=token.citizen,
            title=title,
            message=message,
            queue_token=token
        )
    
    @staticmethod
    def send_pending_served_notification(token):
        """
        Send notification when a pending token is marked as served.
        
        Args:
            token: QueueToken instance that was pending and now completed
        """
        staff_service = token.daily_queue.queue_config.staff_service
        
        title = "Pending Service Completed"
        message = (
            f"Your pending service for token #{token.token_number} has been completed "
            f"at {staff_service.name}. "
            f"\n\nThank you for your patience. We apologize for the earlier delay."
        )
        
        return NotificationService.send_notification(
            user=token.citizen,
            title=title,
            message=message,
            queue_token=token
        )
