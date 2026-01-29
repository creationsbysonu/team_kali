"""
Get Token Services

Business logic for citizen token booking flow:
1. Get ministries by place
2. Get services by ministry
3. Get service details with queue config
4. Validate and book token
"""
import logging
from datetime import datetime, timedelta
from django.db import transaction
from django.utils import timezone
from decimal import Decimal

from ministry.models import Ministry, StaffService
from officials.models import MinistryOfficial
from queue_management.models import (
    QueueConfiguration, 
    DailyQueue, 
    QueueToken,
    QueueEventLog,
    TokenProgress,
    ServiceProgressStep
)
from attendance.models import AttendanceRecord
from holidays.models import Holiday
from core.utils.nepal_time import (
    get_nepal_today,
    get_nepal_now,
    nepal_datetime_combine,
    is_saturday,
    is_today_or_future
)

logger = logging.getLogger(__name__)


class GetTokenService:
    """
    Service class for citizen token booking flow.
    All business logic for the Get Token feature.
    """
    
    @staticmethod
    def get_ministries_by_place(place_id):
        """
        Get all active ministries in a place.
        
        Args:
            place_id: UUID of the place
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            ministries = Ministry.objects.filter(
                place_id=place_id,
                status=Ministry.Status.ACTIVE,
                is_deleted=False
            ).order_by('name')
            
            return True, {
                "success": True,
                "data": {
                    "ministries": ministries,
                    "count": ministries.count()
                }
            }, 200
            
        except Exception as e:
            logger.error(f"Error fetching ministries: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch ministries"
            }, 500
    
    @staticmethod
    def get_services_by_ministry(ministry_id):
        """
        Get all active services in a ministry.
        
        Args:
            ministry_id: UUID of the ministry
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            # Verify ministry exists
            try:
                ministry = Ministry.objects.get(
                    id=ministry_id,
                    status=Ministry.Status.ACTIVE,
                    is_deleted=False
                )
            except Ministry.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Ministry not found or inactive"
                }, 404
            
            services = StaffService.objects.filter(
                ministry=ministry,
                is_active=True
            ).select_related('ministry').order_by('service_name')
            
            return True, {
                "success": True,
                "data": {
                    "ministry": {
                        "id": str(ministry.id),
                        "name": ministry.name
                    },
                    "services": services,
                    "count": services.count()
                }
            }, 200
            
        except Exception as e:
            logger.error(f"Error fetching services: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch services"
            }, 500
    
    @staticmethod
    def get_service_details(service_id):
        """
        Get complete service details with queue config, officials, attendance.
        
        Args:
            service_id: UUID of the staff service
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            # Get service with related queue config
            try:
                service = StaffService.objects.select_related(
                    'ministry', 'queue_config'
                ).get(id=service_id, is_active=True)
            except StaffService.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Service not found or inactive"
                }, 404
            
            # Check if queue config exists
            if not hasattr(service, 'queue_config') or service.queue_config is None:
                return False, {
                    "success": False,
                    "error": "Queue not configured for this service. Please contact the ministry."
                }, 400
            
            queue_config = service.queue_config
            
            return True, {
                "success": True,
                "data": {
                    "queue_config": queue_config
                }
            }, 200
            
        except Exception as e:
            logger.error(f"Error fetching service details: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch service details"
            }, 500
    
    @staticmethod
    def validate_booking(service_id, user, booking_type='REGULAR', booking_date=None):
        """
        Validate if user can book a token.
        
        Validation rules:
        1. Service must exist and be active
        2. Queue config must exist and be active
        3. Staff must be present (not marked absent)
        4. Not Saturday
        5. Not a holiday
        6. Capacity not full
        7. User doesn't already have active token for this service today
        8. For PREBOOKED: check lead hours and quota
        9. For EMERGENCY: check quota
        
        Returns:
            tuple: (can_book: bool, error_message: str or None, queue_config: QueueConfiguration or None)
        """
        today = get_nepal_today()
        target_date = booking_date or today
        
        # 1. Get service
        try:
            service = StaffService.objects.select_related(
                'ministry', 'queue_config'
            ).get(id=service_id, is_active=True)
        except StaffService.DoesNotExist:
            return False, "Service not found or inactive", None
        
        # 2. Check queue config
        if not hasattr(service, 'queue_config') or service.queue_config is None:
            return False, "Queue not configured for this service", None
        
        queue_config = service.queue_config
        
        if not queue_config.active:
            return False, "Queue is not active for this service", None
        
        # 3. Check service status
        if service.status != 'active':
            return False, "Service is currently paused", None
        
        # 4. Check Saturday
        if is_saturday(target_date):
            return False, "Cannot book on Saturday (weekend holiday)", None
        
        # 5. Check holiday
        holiday = Holiday.objects.filter(date=target_date).first()
        if holiday:
            return False, f"Cannot book on holiday: {holiday.name}", None
        
        # 6. Check staff attendance
        staff_attendance = AttendanceRecord.objects.filter(
            staff=service,
            date=target_date,
            person_type=AttendanceRecord.PersonType.STAFF
        ).first()
        
        if staff_attendance and staff_attendance.status == AttendanceRecord.Status.ABSENT:
            return False, "Staff is absent on this date", None
        
        # 7. Check user's existing tokens
        existing_token = QueueToken.objects.filter(
            citizen=user,
            daily_queue__queue_config=queue_config,
            daily_queue__date=target_date,
            status__in=[QueueToken.Status.WAITING, QueueToken.Status.IN_SERVICE, QueueToken.Status.PENDING]
        ).first()
        
        if existing_token:
            return False, f"You already have an active token (#{existing_token.token_number}) for this service today", None
        
        # 8. Get or create daily queue
        daily_queue, _ = DailyQueue.objects.get_or_create(
            queue_config=queue_config,
            date=target_date,
            defaults={'next_token_number': 1}
        )
        
        # Calculate capacity and current bookings
        capacity = queue_config.calculate_daily_capacity()
        current_bookings = daily_queue.tokens.filter(
            status__in=[QueueToken.Status.WAITING, QueueToken.Status.IN_SERVICE, QueueToken.Status.PENDING]
        ).count()
        
        if current_bookings >= capacity:
            return False, "Today's capacity is full. Please try tomorrow.", None
        
        # 9. Booking type specific validations
        if booking_type == 'PREBOOKED':
            if not queue_config.prebooking_allowed:
                return False, "Advance booking is not allowed for this service", None
            
            # Check lead hours
            if target_date == today:
                return False, "Prebooking must be for a future date", None
            
            # Check prebooking quota
            prebooked_count = daily_queue.tokens.filter(
                booking_type=QueueToken.BookingType.PREBOOKED,
                status__in=[QueueToken.Status.WAITING, QueueToken.Status.IN_SERVICE, QueueToken.Status.PENDING]
            ).count()
            
            if prebooked_count >= (queue_config.prebooking_quota_per_day or 0):
                return False, "Prebooking quota for this day is full", None
        
        elif booking_type == 'EMERGENCY':
            if not queue_config.emergency_allowed:
                return False, "Emergency booking is not allowed for this service", None
            
            # Check emergency quota
            emergency_count = daily_queue.tokens.filter(
                booking_type=QueueToken.BookingType.EMERGENCY,
                status__in=[QueueToken.Status.WAITING, QueueToken.Status.IN_SERVICE, QueueToken.Status.PENDING]
            ).count()
            
            if emergency_count >= (queue_config.emergency_quota_per_day or 0):
                return False, "Emergency booking quota for today is full", None
        
        return True, None, queue_config
    
    @staticmethod
    def book_token(service_id, user, booking_type='REGULAR', booking_date=None):
        """
        Book a token for the user.
        
        Args:
            service_id: UUID of the staff service
            user: Authenticated user (citizen)
            booking_type: REGULAR, PREBOOKED, or EMERGENCY
            booking_date: Date to book for (defaults to today)
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            today = get_nepal_today()
            target_date = booking_date or today
            
            # Validate booking
            can_book, error_message, queue_config = GetTokenService.validate_booking(
                service_id, user, booking_type, target_date
            )
            
            if not can_book:
                return False, {
                    "success": False,
                    "error": error_message
                }, 400
            
            with transaction.atomic():
                # Get or create daily queue with lock
                daily_queue, _ = DailyQueue.objects.select_for_update().get_or_create(
                    queue_config=queue_config,
                    date=target_date,
                    defaults={'next_token_number': 1}
                )
                
                # Get token number
                token_number = daily_queue.next_token_number
                daily_queue.next_token_number += 1
                daily_queue.save(update_fields=['next_token_number'])
                
                # Calculate expected service time
                from datetime import datetime
                import pytz
                nepal_tz = pytz.timezone('Asia/Kathmandu')
                
                # Start from office start time
                base_time = nepal_datetime_combine(target_date, queue_config.office_start_time)
                
                # Add waiting time based on position
                waiting_tokens = daily_queue.tokens.filter(
                    status__in=[QueueToken.Status.WAITING, QueueToken.Status.IN_SERVICE]
                ).count()
                
                wait_minutes = waiting_tokens * queue_config.average_service_time_minutes
                expected_time = base_time + timedelta(minutes=wait_minutes)
                
                # Adjust for lunch break if needed
                if queue_config.lunch_start_time and queue_config.lunch_end_time:
                    lunch_start = nepal_datetime_combine(target_date, queue_config.lunch_start_time)
                    lunch_end = nepal_datetime_combine(target_date, queue_config.lunch_end_time)
                    
                    if expected_time >= lunch_start and expected_time < lunch_end:
                        expected_time = lunch_end
                
                # Calculate emergency fee
                emergency_fee = Decimal('0')
                if booking_type == 'EMERGENCY' and queue_config.emergency_fee:
                    emergency_fee = queue_config.emergency_fee
                
                # Create token
                token = QueueToken.objects.create(
                    daily_queue=daily_queue,
                    citizen=user,
                    token_number=token_number,
                    booking_type=booking_type,
                    emergency_fee_paid=emergency_fee,
                    expected_service_time=expected_time,
                    status=QueueToken.Status.WAITING
                )
                
                # Create event log
                QueueEventLog.objects.create(
                    token=token,
                    event=QueueEventLog.Event.CREATED,
                    performed_by=user,
                    metadata={
                        "booking_type": booking_type,
                        "token_number": token_number,
                        "expected_time": expected_time.isoformat()
                    }
                )
                
                # Create progress records if progress tracking is enabled
                if queue_config.enable_progress_tracking:
                    steps = ServiceProgressStep.objects.filter(
                        queue_config=queue_config
                    ).order_by('step_order')
                    
                    for step in steps:
                        TokenProgress.objects.create(
                            token=token,
                            step=step,
                            completed=False
                        )
                
                logger.info(f"Token #{token_number} booked by {user.email} for {queue_config.staff_service.service_name}")
                
                return True, {
                    "success": True,
                    "message": f"टोकन सफलतापूर्वक बुक भयो! (Token booked successfully!)",
                    "data": {
                        "token": token
                    }
                }, 201
                
        except Exception as e:
            logger.error(f"Error booking token: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to book token. Please try again."
            }, 500
    
    @staticmethod
    def get_user_tokens(user, include_past=False):
        """
        Get all tokens for a user.
        
        Args:
            user: Authenticated user
            include_past: Include completed/cancelled tokens
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            today = get_nepal_today()
            
            tokens = QueueToken.objects.filter(
                citizen=user
            ).select_related(
                'daily_queue__queue_config__staff_service__ministry'
            ).order_by('-created_at')
            
            if not include_past:
                tokens = tokens.filter(
                    status__in=[QueueToken.Status.WAITING, QueueToken.Status.IN_SERVICE, QueueToken.Status.PENDING]
                )
            
            return True, {
                "success": True,
                "data": {
                    "tokens": tokens,
                    "count": tokens.count()
                }
            }, 200
            
        except Exception as e:
            logger.error(f"Error fetching user tokens: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch your tokens"
            }, 500
    
    @staticmethod
    def cancel_token(token_id, user):
        """
        Cancel a token.
        
        Args:
            token_id: UUID of the token
            user: Authenticated user (must be token owner)
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            # Get token
            try:
                token = QueueToken.objects.select_related(
                    'daily_queue__queue_config'
                ).get(id=token_id, citizen=user)
            except QueueToken.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Token not found or you don't have permission"
                }, 404
            
            # Check if can be cancelled
            if token.status not in [QueueToken.Status.WAITING, QueueToken.Status.PENDING]:
                return False, {
                    "success": False,
                    "error": f"Cannot cancel token with status: {token.status}"
                }, 400
            
            with transaction.atomic():
                token.status = QueueToken.Status.CANCELLED
                token.active = False
                token.save(update_fields=['status', 'active'])
                
                # Create event log
                QueueEventLog.objects.create(
                    token=token,
                    event=QueueEventLog.Event.CANCELLED,
                    performed_by=user,
                    metadata={
                        "cancelled_by": "citizen",
                        "previous_status": token.status
                    }
                )
                
                logger.info(f"Token #{token.token_number} cancelled by {user.email}")
                
                return True, {
                    "success": True,
                    "message": "टोकन रद्द भयो (Token cancelled successfully)"
                }, 200
                
        except Exception as e:
            logger.error(f"Error cancelling token: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to cancel token"
            }, 500
