"""
Business logic for Queue Management System.

This service handles:
- Queue configuration management
- Daily queue auto-creation
- Token booking with concurrency handling (SELECT_FOR_UPDATE)
- Staff actions (SERVED/NO_SHOW with push-back logic)
- Queue recalculation
"""

import logging
from datetime import datetime, timedelta
from django.db import transaction, models as django_models
from django.core.cache import cache
from django.utils import timezone

from .models import QueueConfiguration, DailyQueue, QueueToken, QueueEventLog, ServiceProgressStep
from attendance.models import AttendanceRecord
from attendance.services import AttendanceService
from holidays.models import Holiday
from ministry.models import StaffService
from authentication.models import CustomUser
from core.utils.nepal_time import (
    get_nepal_today,
    nepal_datetime_combine,
    is_saturday,
    is_future_date,
    is_today_or_future
)

logger = logging.getLogger(__name__)


class QueueConfigurationService:
    """Service for managing queue configuration."""
    
    @staticmethod
    def create_or_update_config(staff_service_id, office_start_time, office_end_time,
                                lunch_start_time=None, lunch_end_time=None,
                                average_service_time_minutes=15,
                                documents_required=None, active=True,
                                prebooking_allowed=False, prebooking_lead_hours=None,
                                prebooking_quota_per_day=None,
                                emergency_allowed=False, emergency_fee=None,
                                emergency_quota_per_day=None,
                                higher_official_id=None,
                                enable_progress_tracking=False,
                                progress_steps=None):
        """
        Create or update queue configuration for a staff service.
        
        Args:
            progress_steps: List of dicts with keys: title, step_order
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Validate staff service
            try:
                staff_service = StaffService.objects.get(id=staff_service_id, is_active=True)
            except StaffService.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Staff service not found or inactive"
                }, 404
            
            # Validate times
            if office_start_time >= office_end_time:
                return False, {
                    "success": False,
                    "error": "Office end time must be after start time"
                }, 400
            
            if lunch_start_time and lunch_end_time:
                if lunch_start_time >= lunch_end_time:
                    return False, {
                        "success": False,
                        "error": "Lunch end time must be after start time"
                    }, 400
                
                if lunch_start_time < office_start_time or lunch_end_time > office_end_time:
                    return False, {
                        "success": False,
                        "error": "Lunch hours must be within office hours"
                    }, 400
            
            # Validate higher official if provided
            higher_official = None
            if higher_official_id:
                from officials.models import MinistryOfficial
                try:
                    higher_official = MinistryOfficial.objects.get(
                        id=higher_official_id,
                        is_active=True
                    )
                    # Ensure official belongs to same ministry
                    if higher_official.ministry and staff_service.ministry and higher_official.ministry.id != staff_service.ministry.id:
                        return False, {
                            "success": False,
                            "error": "Higher official must belong to the same ministry"
                        }, 400
                except MinistryOfficial.DoesNotExist:
                    return False, {
                        "success": False,
                        "error": "Higher official not found or inactive"
                    }, 404
            
            with transaction.atomic():
                config, created = QueueConfiguration.objects.update_or_create(
                    staff_service=staff_service,
                    defaults={
                        'ministry': staff_service.ministry,
                        'office_start_time': office_start_time,
                        'office_end_time': office_end_time,
                        'lunch_start_time': lunch_start_time,
                        'lunch_end_time': lunch_end_time,
                        'average_service_time_minutes': average_service_time_minutes,
                        'documents_required': documents_required or [],
                        'prebooking_allowed': prebooking_allowed,
                        'prebooking_lead_hours': prebooking_lead_hours,
                        'prebooking_quota_per_day': prebooking_quota_per_day,
                        'emergency_allowed': emergency_allowed,
                        'emergency_fee': emergency_fee,
                        'emergency_quota_per_day': emergency_quota_per_day,
                        'higher_official': higher_official,
                        'enable_progress_tracking': enable_progress_tracking,
                        'active': active,
                    }
                )
                
                # Handle progress steps creation if provided
                if enable_progress_tracking and progress_steps:
                    # Delete existing progress steps for this config
                    config.progress_steps.all().delete()  # type: ignore[attr-defined]
                    
                    # Create new progress steps (simple: just title and step_order)
                    for step_data in progress_steps:
                        ServiceProgressStep.objects.create(
                            queue_config=config,
                            title=step_data['title'],
                            step_order=step_data['step_order']
                        )
                    
                    logger.info(f"Created {len(progress_steps)} progress steps for queue configuration")
            
            action = "created" if created else "updated"
            logger.info(f"Queue configuration {action} for {staff_service.service_name}")
            
            return True, {
                "success": True,
                "data": {
                    "id": str(config.id),
                    "staff_service": str(staff_service.id),
                    "calculated_daily_capacity": config.calculate_daily_capacity(),
                },
                "message": f"Queue configuration {action} successfully"
            }, 201 if created else 200
            
        except Exception as e:
            logger.error(f"Error creating/updating queue config: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to create/update queue configuration"
            }, 500


class DailyQueueService:
    """Service for managing daily queues."""
    
    @staticmethod
    def create_daily_queue(queue_config, date):
        """
        Create a daily queue if conditions are met.
        
        Conditions:
        1. Not Saturday
        2. Not a holiday
        3. Staff is marked as PRESENT
        
        Returns:
            tuple: (success: bool, daily_queue or None, message: str)
        """
        try:
            staff_service = queue_config.staff_service
            
            # Check Saturday
            if is_saturday(date):
                return False, None, "Saturday - Weekly Holiday"
            
            # Check holiday
            is_holiday, holiday_name = Holiday.is_holiday(date)
            if is_holiday:
                return False, None, f"Holiday: {holiday_name}"
            
            # Check staff availability
            is_available, reason = AttendanceService.check_person_availability(staff_service, date, AttendanceRecord.PersonType.STAFF)
            if not is_available:
                return False, None, reason
            
            # Check higher official availability if required
            if queue_config.higher_official:
                is_official_available, official_reason = AttendanceService.check_person_availability(
                    queue_config.higher_official, date, AttendanceRecord.PersonType.OFFICIAL
                )
                if not is_official_available:
                    return False, None, f"Required official unavailable: {official_reason}"
            
            # Create daily queue
            with transaction.atomic():
                daily_queue, created = DailyQueue.objects.get_or_create(
                    queue_config=queue_config,
                    date=date,
                    defaults={'next_token_number': 1}
                )
            
            if created:
                logger.info(f"Daily queue created for {staff_service.name} on {date}")
            
            return True, daily_queue, "Queue available"
            
        except Exception as e:
            logger.error(f"Error creating daily queue: {str(e)}")
            return False, None, "Failed to create daily queue"
    
    @staticmethod
    def check_queue_availability(staff_service_id, date):
        """
        Check if queue is available for a given date.
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Validate staff service
            try:
                staff_service = StaffService.objects.get(id=staff_service_id, is_active=True)
            except StaffService.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Staff service not found or inactive"
                }, 404
            
            # Get queue configuration
            try:
                queue_config = QueueConfiguration.objects.get(staff_service=staff_service, active=True)
            except QueueConfiguration.DoesNotExist:
                return True, {
                    "success": True,
                    "queue_available": False,
                    "message": "Queue not configured for this service",
                    "date": str(date)
                }, 200
            
            # Try to get or create daily queue
            success, daily_queue, message = DailyQueueService.create_daily_queue(queue_config, date)
            
            if not success:
                return True, {
                    "success": True,
                    "queue_available": False,
                    "message": message,
                    "date": str(date)
                }, 200
            
            # Calculate daily capacity dynamically
            total_capacity = queue_config.calculate_daily_capacity()
            
            # Get current token counts by booking type
            current_tokens = daily_queue.tokens.filter(active=True).count()  # type: ignore[union-attr]
            regular_tokens = daily_queue.tokens.filter(  # type: ignore[union-attr]
                active=True, 
                booking_type=QueueToken.BookingType.REGULAR
            ).count()
            prebooked_tokens = daily_queue.tokens.filter(  # type: ignore[union-attr]
                active=True,
                booking_type=QueueToken.BookingType.PREBOOKED
            ).count()
            emergency_tokens = daily_queue.tokens.filter(  # type: ignore[union-attr]
                active=True,
                booking_type=QueueToken.BookingType.EMERGENCY
            ).count()
            
            # Calculate quotas
            prebooking_quota = queue_config.prebooking_quota_per_day or 0
            emergency_quota = queue_config.emergency_quota_per_day or 0
            regular_quota = max(0, total_capacity - prebooking_quota - emergency_quota)
            
            # Calculate remaining capacity
            capacity_remaining = total_capacity - current_tokens
            regular_remaining = regular_quota - regular_tokens
            prebooking_remaining = prebooking_quota - prebooked_tokens
            emergency_remaining = emergency_quota - emergency_tokens
            
            if capacity_remaining <= 0:
                return True, {
                    "success": True,
                    "queue_available": False,
                    "message": "Queue is full for this date",
                    "date": str(date),
                    "capacity_remaining": 0
                }, 200
            
            return True, {
                "success": True,
                "queue_available": True,
                "message": "Queue available for booking",
                "daily_queue_id": str(daily_queue.id),  # type: ignore[union-attr]
                "date": str(date),
                "capacity_info": {
                    "total_capacity": total_capacity,
                    "capacity_remaining": capacity_remaining,
                    "regular_quota": regular_quota,
                    "regular_remaining": regular_remaining,
                    "prebooking_quota": prebooking_quota,
                    "prebooking_remaining": prebooking_remaining,
                    "prebooking_allowed": queue_config.prebooking_allowed,
                    "emergency_quota": emergency_quota,
                    "emergency_remaining": emergency_remaining,
                    "emergency_allowed": queue_config.emergency_allowed,
                    "emergency_fee": float(queue_config.emergency_fee) if queue_config.emergency_fee else 0,
                },
                "next_token_number": daily_queue.next_token_number  # type: ignore[union-attr]
            }, 200
            
        except Exception as e:
            logger.error(f"Error checking queue availability: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to check queue availability"
            }, 500


class TokenBookingService:
    """Service for booking queue tokens with concurrency handling."""
    
    @staticmethod
    def book_token(citizen, staff_service_id, date, booking_type=QueueToken.BookingType.REGULAR):
        """
        Book a queue token for a citizen.
        
        Uses SELECT_FOR_UPDATE to prevent race conditions.
        
        Args:
            citizen: CustomUser instance
            staff_service_id: UUID of staff service
            date: Date for booking
            booking_type: REGULAR, PREBOOKED, or EMERGENCY
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Validate date
            if not is_today_or_future(date):
                return False, {
                    "success": False,
                    "error": "Cannot book tokens for past dates"
                }, 400
            
            # Check if citizen already has an active token for this date
            existing_token = QueueToken.objects.filter(
                daily_queue__queue_config__staff_service_id=staff_service_id,
                daily_queue__date=date,
                citizen=citizen,
                active=True
            ).first()
            
            if existing_token:
                return False, {
                    "success": False,
                    "error": "You already have an active token for this date and service"
                }, 400
            
            # Validate staff service
            try:
                staff_service = StaffService.objects.get(id=staff_service_id, is_active=True)
            except StaffService.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Staff service not found or inactive"
                }, 404
            
            # Get queue configuration
            try:
                queue_config = QueueConfiguration.objects.get(staff_service=staff_service, active=True)
            except QueueConfiguration.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Queue not configured for this service"
                }, 400
            
            # Validate booking type against configuration
            if booking_type == QueueToken.BookingType.PREBOOKED:
                if not queue_config.prebooking_allowed:
                    return False, {
                        "success": False,
                        "error": "Prebooking is not allowed for this service"
                    }, 400
                
                # Validate prebooking lead time
                from core.utils.nepal_time import get_nepal_now
                now = get_nepal_now()
                booking_datetime = nepal_datetime_combine(date, queue_config.office_start_time)
                hours_until_booking = (booking_datetime - now).total_seconds() / 3600
                
                if hours_until_booking < (queue_config.prebooking_lead_hours or 0):
                    return False, {
                        "success": False,
                        "error": f"Prebooking requires at least {queue_config.prebooking_lead_hours} hours advance notice"
                    }, 400
            
            elif booking_type == QueueToken.BookingType.EMERGENCY:
                if not queue_config.emergency_allowed:
                    return False, {
                        "success": False,
                        "error": "Emergency booking is not allowed for this service"
                    }, 400
            
            # Use transaction with SELECT FOR UPDATE for concurrency safety
            with transaction.atomic():
                # Get or create daily queue
                success, daily_queue, message = DailyQueueService.create_daily_queue(queue_config, date)
                
                if not success:
                    return False, {
                        "success": False,
                        "error": message
                    }, 400
                
                # Lock the daily queue row to prevent race conditions
                daily_queue = DailyQueue.objects.select_for_update().get(id=daily_queue.id)  # type: ignore[union-attr]
                
                # Check capacity again (inside transaction)
                total_capacity = queue_config.calculate_daily_capacity()
                current_tokens = daily_queue.tokens.filter(active=True).count()  # type: ignore[union-attr]
                
                if current_tokens >= total_capacity:
                    return False, {
                        "success": False,
                        "error": "Queue is full for this date"
                    }, 400
                
                # Check booking type specific quota
                if booking_type == QueueToken.BookingType.PREBOOKED:
                    prebooked_count = daily_queue.tokens.filter(  # type: ignore[union-attr]
                        active=True,
                        booking_type=QueueToken.BookingType.PREBOOKED
                    ).count()
                    if prebooked_count >= (queue_config.prebooking_quota_per_day or 0):
                        return False, {
                            "success": False,
                            "error": "Prebooking quota is full for this date"
                        }, 400
                
                elif booking_type == QueueToken.BookingType.EMERGENCY:
                    emergency_count = daily_queue.tokens.filter(  # type: ignore[union-attr]
                        active=True,
                        booking_type=QueueToken.BookingType.EMERGENCY
                    ).count()
                    if emergency_count >= (queue_config.emergency_quota_per_day or 0):
                        return False, {
                            "success": False,
                            "error": "Emergency quota is full for this date"
                        }, 400
                
                # Assign token number
                token_number = daily_queue.next_token_number
                
                # Calculate expected service time
                expected_service_time = TokenBookingService._calculate_expected_time(
                    daily_queue, token_number, queue_config
                )
                
                # Calculate emergency fee if applicable
                emergency_fee_paid = None
                if booking_type == QueueToken.BookingType.EMERGENCY:
                    emergency_fee_paid = queue_config.emergency_fee or 0
                
                # Create token
                token = QueueToken.objects.create(
                    daily_queue=daily_queue,
                    citizen=citizen,
                    token_number=token_number,
                    expected_service_time=expected_service_time,
                    booking_type=booking_type,
                    emergency_fee_paid=emergency_fee_paid,
                    no_show_count=0,
                    active=True
                )
                
                # Create event log
                QueueEventLog.objects.create(
                    token=token,
                    event=QueueEventLog.Event.CREATED,
                    performed_by=citizen,
                    metadata={
                        "token_number": token_number,
                        "date": str(date),
                        "expected_time": str(expected_service_time)
                    }
                )
                
                # Increment next token number
                daily_queue.next_token_number += 1
                daily_queue.save(update_fields=['next_token_number'])
                
                # Initialize progress tracking if enabled
                if queue_config.enable_progress_tracking:
                    from .progress_tracking_service import ProgressTrackingService
                    progress_initialized = ProgressTrackingService.initialize_token_progress(token)
                    if progress_initialized:
                        logger.info(
                            f"Initialized progress tracking for token {token_number}"
                        )
                    else:
                        logger.warning(
                            f"Failed to initialize progress tracking for token {token_number}"
                        )
            
            logger.info(f"Token {token_number} booked for {citizen.email} on {date}")
            
            # Send notification (outside transaction)
            from notifications.services import NotificationService
            NotificationService.send_token_booked_notification(token)
            
            return True, {
                "success": True,
                "data": {
                    "token_id": str(token.id),
                    "token_number": token_number,
                    "date": str(date),
                    "expected_service_time": str(expected_service_time),
                    "booking_type": booking_type,
                    "emergency_fee_paid": float(emergency_fee_paid) if emergency_fee_paid else None,
                    "staff_service": staff_service.service_name,
                    "ministry": staff_service.ministry.name,
                },
                "message": "Token booked successfully"
            }, 201
            
        except Exception as e:
            logger.error(f"Error booking token: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to book token"
            }, 500
    
    @staticmethod
    def _calculate_expected_time(daily_queue, token_number, queue_config):
        """Calculate expected service time for a token."""
        from core.utils.nepal_time import nepal_datetime_combine, NEPAL_TZ
        
        # Start time
        start_time = queue_config.office_start_time
        date = daily_queue.date
        
        # Calculate total minutes from start
        total_minutes = (token_number - 1) * queue_config.average_service_time_minutes
        
        # Create datetime
        expected_dt = datetime.combine(date, start_time)
        expected_dt = NEPAL_TZ.localize(expected_dt)
        
        # Add service time
        expected_dt += timedelta(minutes=total_minutes)
        
        # Check if it crosses lunch time
        if queue_config.lunch_start_time and queue_config.lunch_end_time:
            lunch_start_dt = datetime.combine(date, queue_config.lunch_start_time)
            lunch_start_dt = NEPAL_TZ.localize(lunch_start_dt)
            
            lunch_end_dt = datetime.combine(date, queue_config.lunch_end_time)
            lunch_end_dt = NEPAL_TZ.localize(lunch_end_dt)
            
            # If expected time is during lunch, push it after lunch
            if lunch_start_dt <= expected_dt < lunch_end_dt:
                lunch_duration = (lunch_end_dt - lunch_start_dt).total_seconds() / 60
                expected_dt = lunch_end_dt
            # If expected time is after lunch started, add lunch duration
            elif expected_dt >= lunch_start_dt:
                lunch_duration = (lunch_end_dt - lunch_start_dt).total_seconds() / 60
                # Only add lunch duration once
                pass
        
        return expected_dt


class TokenManagementService:
    """Service for staff actions on tokens (SERVED/NO_SHOW)."""
    
    @staticmethod
    def mark_token_served(token_id, staff_user):
        """
        Mark a token as served.
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Get token
            try:
                token = QueueToken.objects.select_related(
                    'daily_queue__queue_config__staff_service',
                    'citizen'
                ).get(id=token_id)
            except QueueToken.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Token not found"
                }, 404
            
            # Validate token is active
            if not token.active:
                return False, {
                    "success": False,
                    "error": "Token is already completed or cancelled"
                }, 400
            
            # Validate it's today's queue
            today = get_nepal_today()
            if token.daily_queue.date != today:
                return False, {
                    "success": False,
                    "error": "Can only mark tokens for today's queue"
                }, 400
            
            with transaction.atomic():
                # Mark as served
                token.active = False
                token.save(update_fields=['active', 'updated_at'])
                
                # Create event log
                QueueEventLog.objects.create(
                    token=token,
                    event=QueueEventLog.Event.SERVED,
                    performed_by=staff_user,
                    metadata={
                        "token_number": token.token_number,
                        "served_at": str(timezone.now())
                    }
                )
            
            logger.info(f"Token {token.token_number} marked as SERVED by {staff_user.email}")
            
            # Send notification
            from notifications.services import NotificationService
            NotificationService.send_token_served_notification(token)
            
            return True, {
                "success": True,
                "message": "Token marked as served"
            }, 200
            
        except Exception as e:
            logger.error(f"Error marking token as served: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to mark token as served"
            }, 500
    
    @staticmethod
    def mark_token_no_show(token_id, staff_user):
        """
        Mark a token as no-show (citizen fault).
        
        First no-show: Push back 3 positions
        Second no-show: Auto-cancel
        
        Staff Admin ONLY has this button - cannot mark as SERVED.
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Get token
            try:
                token = QueueToken.objects.select_related(
                    'daily_queue__queue_config__staff_service',
                    'citizen'
                ).get(id=token_id)
            except QueueToken.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Token not found"
                }, 404
            
            # Validate token is in valid state for no-show
            if token.status not in [QueueToken.Status.WAITING, QueueToken.Status.IN_SERVICE]:
                return False, {
                    "success": False,
                    "error": f"Cannot mark no-show for token with status: {token.status}"
                }, 400
            
            # Validate it's today's queue
            today = get_nepal_today()
            if token.daily_queue.date != today:
                return False, {
                    "success": False,
                    "error": "Can only mark tokens for today's queue"
                }, 400
            
            with transaction.atomic():
                # Increment no-show count
                token.no_show_count += 1
                
                # Log the no-show event first
                QueueEventLog.objects.create(
                    token=token,
                    event=QueueEventLog.Event.NO_SHOW,
                    performed_by=staff_user,
                    metadata={
                        "token_number": token.token_number,
                        "no_show_count": token.no_show_count
                    }
                )
                
                if token.no_show_count >= 2:
                    # Second no-show: Auto-cancel
                    token.status = QueueToken.Status.CANCELLED
                    token.active = False
                    token.save(update_fields=['no_show_count', 'status', 'active'])
                    
                    # Create cancel event log
                    QueueEventLog.objects.create(
                        token=token,
                        event=QueueEventLog.Event.CANCELLED,
                        performed_by=staff_user,
                        metadata={
                            "token_number": token.token_number,
                            "reason": "Auto-cancelled after 2 no-shows",
                            "no_show_count": 2
                        }
                    )
                    
                    logger.info(f"Token {token.token_number} auto-cancelled after 2 no-shows")
                    
                    # Send notification
                    from notifications.services import NotificationService
                    NotificationService.send_token_cancelled_notification(
                        token, "Auto-cancelled after 2 no-shows"
                    )
                    
                    return True, {
                        "success": True,
                        "data": {
                            "token_id": str(token.id),
                            "token_number": token.token_number,
                            "status": "CANCELLED",
                            "reason": "Auto-cancelled after 2 no-shows"
                        },
                        "message": "Token auto-cancelled after 2 no-shows"
                    }, 200
                
                else:
                    # First no-show: Push back 3 positions (changed from 5)
                    old_token_number = token.token_number
                    new_token_number = old_token_number + 3
                    
                    # Check if new position exceeds day's total capacity
                    queue_config = token.daily_queue.queue_config
                    total_capacity = queue_config.calculate_daily_capacity()
                    
                    # Get total tokens booked for the day
                    total_tokens = token.daily_queue.tokens.count()  # type: ignore[attr-defined]
                    max_possible_position = max(total_capacity, total_tokens)
                    
                    # If pushed position exceeds reasonable limit, auto-cancel instead
                    if new_token_number > max_possible_position + 10:  # Allow 10 extra buffer
                        token.status = QueueToken.Status.CANCELLED
                        token.active = False
                        token.save(update_fields=['no_show_count', 'status', 'active'])
                        
                        # Create event log
                        QueueEventLog.objects.create(
                            token=token,
                            event=QueueEventLog.Event.CANCELLED,
                            performed_by=staff_user,
                            metadata={
                                "token_number": token.token_number,
                                "reason": "Auto-cancelled: pushed position exceeds day capacity",
                                "old_token_number": old_token_number,
                                "attempted_new_number": new_token_number,
                                "max_capacity": max_possible_position,
                                "no_show_count": token.no_show_count
                            }
                        )
                        
                        logger.info(
                            f"Token {token.token_number} auto-cancelled: "
                            f"pushed position {new_token_number} exceeds capacity {max_possible_position}"
                        )
                        
                        # Send notification
                        from notifications.services import NotificationService
                        NotificationService.send_token_cancelled_notification(
                            token, "Auto-cancelled: service window exceeded"
                        )
                        
                        return True, {
                            "success": True,
                            "data": {
                                "token_id": str(token.id),
                                "token_number": token.token_number,
                                "status": "CANCELLED",
                                "reason": "Cannot be served within service hours"
                            },
                            "message": "Token auto-cancelled: cannot be served within service hours"
                        }, 200
                    
                    # Otherwise, push back normally
                    token.token_number = new_token_number
                    token.status = QueueToken.Status.WAITING  # Reset to waiting
                    token.service_started_at = None  # Reset service countdown
                    token.save(update_fields=['no_show_count', 'token_number', 'status', 'service_started_at'])
                    
                    # Recalculate expected time
                    new_expected_time = TokenBookingService._calculate_expected_time(
                        token.daily_queue, new_token_number, queue_config
                    )
                    token.expected_service_time = new_expected_time
                    token.save(update_fields=['expected_service_time'])
                    
                    # Create pushed back event log
                    QueueEventLog.objects.create(
                        token=token,
                        event=QueueEventLog.Event.PUSHED_BACK,
                        performed_by=staff_user,
                        metadata={
                            "old_token_number": old_token_number,
                            "new_token_number": new_token_number,
                            "pushed_positions": 3,
                            "new_expected_time": str(new_expected_time)
                        }
                    )
                    
                    logger.info(
                        f"Token pushed from {old_token_number} to {new_token_number} "
                        f"(No-show #{token.no_show_count})"
                    )
                    
                    # Send notification
                    from notifications.services import NotificationService
                    NotificationService.send_token_pushed_notification(
                        token, old_token_number, new_token_number
                    )
                    
                    return True, {
                        "success": True,
                        "data": {
                            "token_id": str(token.id),
                            "old_token_number": old_token_number,
                            "new_token_number": new_token_number,
                            "new_expected_time": str(new_expected_time),
                            "no_show_count": token.no_show_count,
                            "status": "WAITING"
                        },
                        "message": "Token pushed back 3 positions"
                    }, 200
            
        except Exception as e:
            logger.error(f"Error marking token as no-show: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to mark token as no-show"
            }, 500
    
    @staticmethod
    def auto_cancel_end_of_day_tokens(date=None):
        """
        Auto-cancel all active tokens at end of day.
        
        This should be run as a scheduled task (Celery) at end of office hours.
        Cancels tokens that:
        - Are still active (not served)
        - Service date has ended
        
        Args:
            date: Date to process (defaults to today)
            
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            if date is None:
                date = get_nepal_today()
            
            logger.info(f"Running end-of-day auto-cancellation for {date}")
            
            # Get all daily queues for the date
            daily_queues = DailyQueue.objects.filter(date=date)
            
            total_cancelled = 0
            
            with transaction.atomic():
                for daily_queue in daily_queues:
                    # Get all active tokens for this queue
                    active_tokens = QueueToken.objects.filter(
                        daily_queue=daily_queue,
                        active=True
                    )
                    
                    for token in active_tokens:
                        # Cancel the token
                        token.active = False
                        token.save(update_fields=['active', 'updated_at'])
                        
                        # Create event log
                        QueueEventLog.objects.create(
                            token=token,
                            event=QueueEventLog.Event.CANCELLED,
                            performed_by=None,  # System action
                            metadata={
                                "token_number": token.token_number,
                                "reason": "Auto-cancelled at end of day",
                                "service_date": str(date),
                                "cancellation_type": "END_OF_DAY"
                            }
                        )
                        
                        total_cancelled += 1
                        
                        # Send notification
                        from notifications.services import NotificationService
                        NotificationService.send_token_cancelled_notification(
                            token, "Service day ended - Token auto-cancelled"
                        )
            
            logger.info(
                f"End-of-day auto-cancellation completed: "
                f"{total_cancelled} tokens cancelled for {date}"
            )
            
            return True, {
                "success": True,
                "data": {
                    "date": str(date),
                    "total_cancelled": total_cancelled
                },
                "message": f"{total_cancelled} tokens auto-cancelled at end of day"
            }, 200
            
        except Exception as e:
            logger.error(f"Error in end-of-day auto-cancellation: {str(e)}")
            import traceback
            logger.error(traceback.format_exc())
            return False, {
                "success": False,
                "error": "Failed to auto-cancel end-of-day tokens"
            }, 500
    
    @staticmethod
    def cancel_token(token_id, user, reason=""):
        """
        Cancel a token (can be done by citizen or admin).
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Get token
            try:
                token = QueueToken.objects.select_related('citizen').get(id=token_id)
            except QueueToken.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Token not found"
                }, 404
            
            # Validate token is active
            if not token.active:
                return False, {
                    "success": False,
                    "error": "Token is already completed or cancelled"
                }, 400
            
            # Validate user has permission (citizen can cancel their own token)
            if token.citizen != user and not user.is_staff:
                return False, {
                    "success": False,
                    "error": "You don't have permission to cancel this token"
                }, 403
            
            with transaction.atomic():
                token.active = False
                token.save(update_fields=['active', 'updated_at'])
                
                # Create event log
                QueueEventLog.objects.create(
                    token=token,
                    event=QueueEventLog.Event.CANCELLED,
                    performed_by=user,
                    metadata={
                        "token_number": token.token_number,
                        "reason": reason or "Cancelled by user"
                    }
                )
            
            logger.info(f"Token {token.token_number} cancelled by {user.email}")
            
            # Send notification
            from notifications.services import NotificationService
            NotificationService.send_token_cancelled_notification(token, reason or "Cancelled by user")
            
            return True, {
                "success": True,
                "message": "Token cancelled successfully"
            }, 200
            
        except Exception as e:
            logger.error(f"Error cancelling token: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to cancel token"
            }, 500
    
    @staticmethod
    def get_my_tokens(citizen):
        """
        Get all tokens for a citizen.
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            tokens = QueueToken.objects.filter(
                citizen=citizen
            ).select_related(
                'daily_queue__queue_config__staff_service__ministry'
            ).order_by('-created_at')[:20]  # Last 20 tokens
            
            tokens_data = []
            for token in tokens:
                latest_event = token.events.order_by('-created_at').first()  # type: ignore[attr-defined]
                
                tokens_data.append({
                    "id": str(token.id),
                    "token_number": token.token_number,
                    "date": str(token.daily_queue.date),
                    "staff_service": token.daily_queue.queue_config.staff_service.name,
                    "ministry": token.daily_queue.queue_config.staff_service.ministry.name,
                    "expected_service_time": str(token.expected_service_time),
                    "active": token.active,
                    "no_show_count": token.no_show_count,
                    "status": "Waiting" if token.active else "Completed",
                    "latest_event": latest_event.get_event_display() if latest_event else None,
                    "created_at": str(token.created_at),
                })
            
            return True, {
                "success": True,
                "data": tokens_data,
                "count": len(tokens_data)
            }, 200
            
        except Exception as e:
            logger.error(f"Error fetching tokens: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch tokens"
            }, 500
    
    @staticmethod
    def get_todays_queue(staff_service_id):
        """
        Get today's queue for a staff service (for staff view).
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            today = get_nepal_today()
            
            # Get staff service
            try:
                staff_service = StaffService.objects.get(id=staff_service_id)
            except StaffService.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Staff service not found"
                }, 404
            
            # Get queue config
            try:
                queue_config = QueueConfiguration.objects.get(staff_service=staff_service)
            except QueueConfiguration.DoesNotExist:
                return True, {
                    "success": True,
                    "message": "No queue configuration found",
                    "data": []
                }, 200
            
            # Get today's queue
            try:
                daily_queue = DailyQueue.objects.get(queue_config=queue_config, date=today)
            except DailyQueue.DoesNotExist:
                return True, {
                    "success": True,
                    "message": "No queue for today",
                    "data": []
                }, 200
            
            # Get all tokens for today
            tokens = QueueToken.objects.filter(
                daily_queue=daily_queue
            ).select_related('citizen').order_by('token_number')
            
            tokens_data = []
            for token in tokens:
                tokens_data.append({
                    "id": str(token.id),
                    "token_number": token.token_number,
                    "citizen_name": token.citizen.username,
                    "citizen_email": token.citizen.email,
                    "expected_service_time": str(token.expected_service_time),
                    "active": token.active,
                    "no_show_count": token.no_show_count,
                    "status": "Waiting" if token.active else "Completed",
                })
            
            return True, {
                "success": True,
                "data": tokens_data,
                "count": len(tokens_data)
            }, 200
            
        except Exception as e:
            logger.error(f"Error fetching today's queue: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch today's queue"
            }, 500


class PendingTokenService:
    """
    Service for managing pending tokens (government/system fault).
    
    Pending tokens are tokens where:
    - Citizen appeared BUT service couldn't be completed
    - Government/system fault (document issue, official absent, system down)
    - Citizen gets NO penalty
    - Token is deferred to next working day with priority
    """
    
    @staticmethod
    def mark_token_pending(token_id, staff_user, reason: str):
        """
        Move a token to pending queue (government fault).
        
        Staff Admin's SECOND button - for government/system issues.
        
        Args:
            token_id: UUID of token
            staff_user: Staff user marking pending
            reason: Reason for pending (government fault)
            
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Get token
            try:
                token = QueueToken.objects.select_related(
                    'daily_queue__queue_config__staff_service',
                    'citizen'
                ).get(id=token_id)
            except QueueToken.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Token not found"
                }, 404
            
            # Validate token is in valid state
            if token.status not in [QueueToken.Status.WAITING, QueueToken.Status.IN_SERVICE]:
                return False, {
                    "success": False,
                    "error": f"Cannot mark pending for token with status: {token.status}"
                }, 400
            
            # Validate it's today's queue
            today = get_nepal_today()
            if token.daily_queue.date != today:
                return False, {
                    "success": False,
                    "error": "Can only mark tokens for today's queue"
                }, 400
            
            # Calculate next working day for priority
            next_working_day = PendingTokenService._get_next_working_day(
                token.daily_queue.queue_config.staff_service
            )
            
            with transaction.atomic():
                # Update token to pending status
                token.status = QueueToken.Status.PENDING
                token.pending_reason = reason
                token.pending_priority_date = next_working_day
                token.service_started_at = None  # Reset any service countdown
                token.save(update_fields=[
                    'status', 'pending_reason', 'pending_priority_date', 'service_started_at'
                ])
                
                # Create event log
                QueueEventLog.objects.create(
                    token=token,
                    event=QueueEventLog.Event.MOVED_TO_PENDING,
                    performed_by=staff_user,
                    metadata={
                        "token_number": token.token_number,
                        "reason": reason,
                        "priority_date": str(next_working_day)
                    }
                )
                
                logger.info(
                    f"Token {token.token_number} moved to pending. "
                    f"Reason: {reason}. Priority date: {next_working_day}"
                )
                
                # Send notification to citizen
                from notifications.services import NotificationService
                NotificationService.send_token_pending_notification(token, reason)
                
                return True, {
                    "success": True,
                    "data": {
                        "token_id": str(token.id),
                        "token_number": token.token_number,
                        "status": "PENDING",
                        "reason": reason,
                        "priority_date": str(next_working_day),
                        "citizen_email": token.citizen.email
                    },
                    "message": "Token moved to pending queue"
                }, 200
                
        except Exception as e:
            logger.error(f"Error marking token pending: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to mark token as pending"
            }, 500
    
    @staticmethod
    def _get_next_working_day(staff_service):
        """Get the next working day (not Saturday, not holiday)."""
        from holidays.models import Holiday
        
        today = get_nepal_today()
        next_day = today + timedelta(days=1)
        
        # Loop until we find a working day
        for _ in range(14):  # Max 2 weeks ahead
            if not is_saturday(next_day):
                is_holiday, _ = Holiday.is_holiday(next_day)
                if not is_holiday:
                    return next_day
            next_day += timedelta(days=1)
        
        # Fallback: return tomorrow even if holiday
        return today + timedelta(days=1)
    
    @staticmethod
    def get_pending_tokens(staff_service_id):
        """
        Get all pending tokens for a staff service.
        
        For Staff Admin Panel - "Pending Tokens" section.
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Get staff service
            try:
                staff_service = StaffService.objects.get(id=staff_service_id)
            except StaffService.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Staff service not found"
                }, 404
            
            # Get queue config
            try:
                queue_config = QueueConfiguration.objects.get(staff_service=staff_service)
            except QueueConfiguration.DoesNotExist:
                return True, {
                    "success": True,
                    "data": [],
                    "count": 0
                }, 200
            
            # Get all pending tokens for this service
            pending_tokens = QueueToken.objects.filter(
                daily_queue__queue_config=queue_config,
                status=QueueToken.Status.PENDING
            ).select_related(
                'citizen', 'daily_queue'
            ).order_by('pending_priority_date', 'token_number')
            
            tokens_data = []
            for token in pending_tokens:
                tokens_data.append({
                    "id": str(token.id),
                    "token_number": token.token_number,
                    "original_date": str(token.daily_queue.date),
                    "citizen_name": token.citizen.username,
                    "citizen_email": token.citizen.email,
                    "pending_reason": token.pending_reason,
                    "priority_date": str(token.pending_priority_date),
                    "booking_type": token.booking_type,
                    "created_at": str(token.created_at),
                })
            
            return True, {
                "success": True,
                "data": tokens_data,
                "count": len(tokens_data)
            }, 200
            
        except Exception as e:
            logger.error(f"Error fetching pending tokens: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch pending tokens"
            }, 500
    
    @staticmethod
    def mark_pending_served(token_id, staff_user):
        """
        Mark a pending token as served/completed.
        
        Used when the government issue is resolved and citizen is served.
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Get token
            try:
                token = QueueToken.objects.select_related(
                    'daily_queue__queue_config__staff_service',
                    'citizen'
                ).get(id=token_id)
            except QueueToken.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Token not found"
                }, 404
            
            # Validate token is pending
            if token.status != QueueToken.Status.PENDING:
                return False, {
                    "success": False,
                    "error": f"Token is not in pending status. Current: {token.status}"
                }, 400
            
            with transaction.atomic():
                # Update token to completed
                token.status = QueueToken.Status.COMPLETED
                token.active = False
                token.save(update_fields=['status', 'active'])
                
                # Create event log
                QueueEventLog.objects.create(
                    token=token,
                    event=QueueEventLog.Event.COMPLETED,
                    performed_by=staff_user,
                    metadata={
                        "token_number": token.token_number,
                        "was_pending": True,
                        "original_reason": token.pending_reason
                    }
                )
                
                logger.info(
                    f"Pending token {token.token_number} marked as served"
                )
                
                # Send notification to citizen
                from notifications.services import NotificationService
                NotificationService.send_pending_served_notification(token)
                
                return True, {
                    "success": True,
                    "data": {
                        "token_id": str(token.id),
                        "token_number": token.token_number,
                        "status": "COMPLETED"
                    },
                    "message": "Pending token marked as served"
                }, 200
                
        except Exception as e:
            logger.error(f"Error marking pending token served: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to mark pending token as served"
            }, 500
    
    @staticmethod
    def send_pending_email(token_id, staff_user, message: str = ""):
        """
        Send update email to a pending token citizen.
        
        Staff can communicate updates about pending tokens.
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Get token
            try:
                token = QueueToken.objects.select_related(
                    'daily_queue__queue_config__staff_service',
                    'citizen'
                ).get(id=token_id)
            except QueueToken.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Token not found"
                }, 404
            
            # Validate token is pending
            if token.status != QueueToken.Status.PENDING:
                return False, {
                    "success": False,
                    "error": "Can only send emails for pending tokens"
                }, 400
            
            # Send email
            from notifications.services import NotificationService
            NotificationService.send_pending_email_notification(token)
            
            # Log the email event
            QueueEventLog.objects.create(
                token=token,
                event=QueueEventLog.Event.PENDING_EMAIL_SENT,
                performed_by=staff_user,
                metadata={
                    "token_number": token.token_number,
                    "message": message[:500] if message else "Status update"
                }
            )
            
            logger.info(
                f"Pending email sent for token {token.token_number} to {token.citizen.email}"
            )
            
            return True, {
                "success": True,
                "data": {
                    "token_id": str(token.id),
                    "email_sent_to": token.citizen.email
                },
                "message": "Email sent to citizen"
            }, 200
            
        except Exception as e:
            logger.error(f"Error sending pending email: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to send email"
            }, 500


class StaffPanelService:
    """
    Service for staff admin panel views.
    
    Sections:
    1. Active Tokens - Currently being served or next in line (with countdown)
    2. All Tokens - All tokens for today
    3. Pending Tokens - Tokens with government/system issues
    """
    
    @staticmethod
    def get_active_tokens(staff_service_id):
        """
        Get active tokens for staff workbench.
        
        Shows tokens that are:
        - WAITING or IN_SERVICE
        - Only for today
        - Ordered by token number
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            today = get_nepal_today()
            
            # Get staff service
            try:
                staff_service = StaffService.objects.get(id=staff_service_id)
            except StaffService.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Staff service not found"
                }, 404
            
            # Get queue config
            try:
                queue_config = QueueConfiguration.objects.get(staff_service=staff_service)
            except QueueConfiguration.DoesNotExist:
                return True, {
                    "success": True,
                    "data": {
                        "active_token": None,
                        "waiting_tokens": [],
                        "average_service_time_minutes": 15
                    }
                }, 200
            
            # Get today's queue
            try:
                daily_queue = DailyQueue.objects.get(queue_config=queue_config, date=today)
            except DailyQueue.DoesNotExist:
                return True, {
                    "success": True,
                    "data": {
                        "active_token": None,
                        "waiting_tokens": [],
                        "average_service_time_minutes": queue_config.average_service_time_minutes
                    }
                }, 200
            
            # Get priority pending tokens for today first
            priority_pending = QueueToken.objects.filter(
                daily_queue__queue_config=queue_config,
                status=QueueToken.Status.PENDING,
                pending_priority_date=today
            ).select_related('citizen').order_by('token_number')
            
            # Get today's active tokens (WAITING or IN_SERVICE)
            active_tokens = QueueToken.objects.filter(
                daily_queue=daily_queue,
                status__in=[QueueToken.Status.WAITING, QueueToken.Status.IN_SERVICE]
            ).select_related('citizen').order_by('token_number')
            
            # Current active token (IN_SERVICE or first WAITING)
            current_active = active_tokens.filter(
                status=QueueToken.Status.IN_SERVICE
            ).first()
            
            if not current_active:
                current_active = active_tokens.filter(
                    status=QueueToken.Status.WAITING
                ).first()
            
            # Prepare response
            active_token_data = None
            if current_active:
                from django.utils import timezone
                now = timezone.now()
                
                # Calculate countdown remaining
                countdown_remaining = None
                if current_active.service_started_at:
                    elapsed = (now - current_active.service_started_at).total_seconds()
                    countdown_total = queue_config.average_service_time_minutes * 60
                    countdown_remaining = max(0, countdown_total - elapsed)
                
                active_token_data = {
                    "id": str(current_active.id),
                    "token_number": current_active.token_number,
                    "citizen_name": current_active.citizen.username,
                    "citizen_email": current_active.citizen.email,
                    "status": current_active.status,
                    "no_show_count": current_active.no_show_count,
                    "booking_type": current_active.booking_type,
                    "expected_service_time": str(current_active.expected_service_time),
                    "service_started_at": str(current_active.service_started_at) if current_active.service_started_at else None,
                    "countdown_remaining_seconds": countdown_remaining,
                    "average_service_time_minutes": queue_config.average_service_time_minutes,
                }
            
            # Waiting tokens (exclude current active)
            waiting_tokens_data = []
            for token in active_tokens:
                if current_active and token.id == current_active.id:
                    continue
                waiting_tokens_data.append({
                    "id": str(token.id),
                    "token_number": token.token_number,
                    "citizen_name": token.citizen.username,
                    "citizen_email": token.citizen.email,
                    "status": token.status,
                    "no_show_count": token.no_show_count,
                    "booking_type": token.booking_type,
                    "expected_service_time": str(token.expected_service_time),
                })
            
            # Priority pending tokens for today
            priority_tokens_data = []
            for token in priority_pending:
                priority_tokens_data.append({
                    "id": str(token.id),
                    "token_number": token.token_number,
                    "citizen_name": token.citizen.username,
                    "citizen_email": token.citizen.email,
                    "pending_reason": token.pending_reason,
                    "original_date": str(token.daily_queue.date),
                    "is_priority": True,
                })
            
            return True, {
                "success": True,
                "data": {
                    "active_token": active_token_data,
                    "waiting_tokens": waiting_tokens_data,
                    "priority_pending_tokens": priority_tokens_data,
                    "average_service_time_minutes": queue_config.average_service_time_minutes,
                    "total_waiting": len(waiting_tokens_data),
                    "total_priority": len(priority_tokens_data),
                }
            }, 200
            
        except Exception as e:
            logger.error(f"Error fetching active tokens: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch active tokens"
            }, 500
    
    @staticmethod
    def get_all_tokens(staff_service_id, date=None):
        """
        Get all tokens for a day (for staff admin panel).
        
        Shows ALL tokens regardless of status.
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
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
            
            # Get queue config
            try:
                queue_config = QueueConfiguration.objects.get(staff_service=staff_service)
            except QueueConfiguration.DoesNotExist:
                return True, {
                    "success": True,
                    "data": {
                        "tokens": [],
                        "summary": {
                            "total": 0,
                            "waiting": 0,
                            "in_service": 0,
                            "completed": 0,
                            "pending": 0,
                            "cancelled": 0
                        }
                    }
                }, 200
            
            # Get queue for the date
            try:
                daily_queue = DailyQueue.objects.get(queue_config=queue_config, date=date)
            except DailyQueue.DoesNotExist:
                return True, {
                    "success": True,
                    "data": {
                        "tokens": [],
                        "summary": {
                            "total": 0,
                            "waiting": 0,
                            "in_service": 0,
                            "completed": 0,
                            "pending": 0,
                            "cancelled": 0
                        }
                    }
                }, 200
            
            # Get all tokens
            tokens = QueueToken.objects.filter(
                daily_queue=daily_queue
            ).select_related('citizen').order_by('token_number')
            
            # Build tokens data and summary
            tokens_data = []
            summary = {
                "total": 0,
                "waiting": 0,
                "in_service": 0,
                "completed": 0,
                "pending": 0,
                "cancelled": 0
            }
            
            for token in tokens:
                summary["total"] += 1
                status_lower = token.status.lower()
                if status_lower in summary:
                    summary[status_lower] += 1
                
                tokens_data.append({
                    "id": str(token.id),
                    "token_number": token.token_number,
                    "citizen_name": token.citizen.username,
                    "citizen_email": token.citizen.email,
                    "status": token.status,
                    "booking_type": token.booking_type,
                    "no_show_count": token.no_show_count,
                    "expected_service_time": str(token.expected_service_time),
                    "pending_reason": token.pending_reason,
                    "created_at": str(token.created_at),
                })
            
            return True, {
                "success": True,
                "data": {
                    "date": str(date),
                    "tokens": tokens_data,
                    "summary": summary
                }
            }, 200
            
        except Exception as e:
            logger.error(f"Error fetching all tokens: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch tokens"
            }, 500
    
    @staticmethod
    def start_token_service(token_id, staff_user):
        """
        Start the service countdown for a token.
        
        When staff calls a token, the countdown begins.
        After countdown ends, token is auto-completed.
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            from django.utils import timezone
            
            # Get token
            try:
                token = QueueToken.objects.select_related(
                    'daily_queue__queue_config',
                    'citizen'
                ).get(id=token_id)
            except QueueToken.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Token not found"
                }, 404
            
            # Validate token is waiting
            if token.status != QueueToken.Status.WAITING:
                return False, {
                    "success": False,
                    "error": f"Cannot start service for token with status: {token.status}"
                }, 400
            
            # Validate it's today's queue
            today = get_nepal_today()
            if token.daily_queue.date != today:
                return False, {
                    "success": False,
                    "error": "Can only start service for today's tokens"
                }, 400
            
            with transaction.atomic():
                # Update token to IN_SERVICE
                token.status = QueueToken.Status.IN_SERVICE
                token.service_started_at = timezone.now()
                token.save(update_fields=['status', 'service_started_at'])
                
                # Create event log
                QueueEventLog.objects.create(
                    token=token,
                    event=QueueEventLog.Event.IN_SERVICE,
                    performed_by=staff_user,
                    metadata={
                        "token_number": token.token_number,
                        "service_started_at": str(token.service_started_at),
                        "average_service_time_minutes": token.daily_queue.queue_config.average_service_time_minutes
                    }
                )
                
                logger.info(
                    f"Service started for token {token.token_number}. "
                    f"Countdown: {token.daily_queue.queue_config.average_service_time_minutes} minutes"
                )
                
                # Schedule auto-complete task
                from .tasks import auto_complete_token
                countdown_seconds = token.daily_queue.queue_config.average_service_time_minutes * 60
                auto_complete_token.apply_async(  # type: ignore[attr-defined]
                    args=[str(token.id)],
                    countdown=countdown_seconds
                )
                
                return True, {
                    "success": True,
                    "data": {
                        "token_id": str(token.id),
                        "token_number": token.token_number,
                        "status": "IN_SERVICE",
                        "service_started_at": str(token.service_started_at),
                        "countdown_minutes": token.daily_queue.queue_config.average_service_time_minutes
                    },
                    "message": "Service countdown started"
                }, 200
                
        except Exception as e:
            logger.error(f"Error starting token service: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to start service"
            }, 500
