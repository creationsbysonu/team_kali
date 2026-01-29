"""
Queue Management Models

Core models for queue-based service delivery:
- QueueConfiguration: Ministry admin configures service parameters
- DailyQueue: Auto-created queue for each service/day
- QueueToken: Citizen's token/appointment
- QueueEventLog: Immutable audit trail of all token state changes
"""
import uuid
from decimal import Decimal
from datetime import datetime, time, timedelta
from django.db import models
from django.core.exceptions import ValidationError
from django.utils import timezone
import pytz

NEPAL_TZ = pytz.timezone('Asia/Kathmandu')


class QueueConfiguration(models.Model):
    """
    Queue configuration for a service (STATIC RULES ONLY).
    ONE configuration per service (one staff per service model).
    
    Stores CONFIGURATION, not runtime/date-specific data.
    
    Ministry admin configures:
    - Office hours (static schedule)
    - Average service time (for capacity calculation)
    - Document requirements (with sample images)
    - Prebooking rules
    - Emergency booking rules
    - Progress tracking (optional)
    - Higher official assignment
    
    Does NOT store:
    - Daily capacity (calculated dynamically)
    - Dates, holidays, attendance
    - Token numbers or counts
    - Notifications, waiting times
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Service and ministry (one staff per service)
    staff_service = models.OneToOneField(
        'ministry.StaffService',
        on_delete=models.CASCADE,
        related_name='queue_config',
        help_text="Staff service for which queue is configured (one staff per service)"
    )
    
    ministry = models.ForeignKey(
        'ministry.Ministry',
        on_delete=models.CASCADE,
        related_name='queue_configs',
        null=True,
        blank=True,
        help_text="Ministry owning this queue configuration (auto-set from staff_service)"
    )
    
    # Office hours (static schedule)
    office_start_time = models.TimeField(
        help_text="Office opening time (e.g., 10:00)"
    )
    
    office_end_time = models.TimeField(
        help_text="Office closing time (e.g., 17:00)"
    )
    
    # Lunch break (optional)
    lunch_start_time = models.TimeField(
        null=True,
        blank=True,
        help_text="Lunch break start time (e.g., 13:00)"
    )
    
    lunch_end_time = models.TimeField(
        null=True,
        blank=True,
        help_text="Lunch break end time (e.g., 14:00)"
    )
    
    # Service time (for capacity calculation)
    average_service_time_minutes = models.IntegerField(
        default=15,
        help_text="Average time to serve one token (in minutes) - used for dynamic capacity calculation"
    )
    
    # Required documents (JSON with name and sample image URL)
    documents_required = models.JSONField(
        default=list,
        blank=True,
        help_text='List of required documents: [{"name": "Citizenship", "sample_image_url": "..."}]'
    )
    
    # Prebooking configuration
    prebooking_allowed = models.BooleanField(
        default=False,
        help_text="Allow citizens to pre-book tokens in advance"
    )
    
    prebooking_lead_hours = models.IntegerField(
        default=24,
        null=True,
        blank=True,
        help_text="Minimum hours in advance for prebooking (e.g., 24 hours)"
    )
    
    prebooking_quota_per_day = models.IntegerField(
        default=10,
        null=True,
        blank=True,
        help_text="Maximum prebooked tokens allowed per day (included in total capacity)"
    )
    
    # Emergency booking configuration
    emergency_allowed = models.BooleanField(
        default=False,
        help_text="Allow emergency token bookings"
    )
    
    emergency_fee = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0'),
        null=True,
        blank=True,
        help_text="Additional fee for emergency bookings (in local currency)"
    )
    
    emergency_quota_per_day = models.IntegerField(
        default=5,
        null=True,
        blank=True,
        help_text="Maximum emergency tokens allowed per day (included in total capacity)"
    )
    
    # Higher officials assignment (can assign multiple officials)
    higher_officials = models.ManyToManyField(
        'officials.MinistryOfficial',
        blank=True,
        related_name='assigned_queues',
        help_text="Higher officials assigned to this service (if all absent, service closes)"
    )
    
    # Progress tracking (optional)
    # NOTE: Database has TWO columns due to migration issue - keep both in sync
    progress_tracking_enabled = models.BooleanField(
        default=False,
        db_column='progress_tracking_enabled',
        help_text="Legacy column - kept for database compatibility"
    )
    enable_progress_tracking = models.BooleanField(
        default=False,
        help_text="Enable multi-step progress tracking for tokens"
    )
    
    # Status
    active = models.BooleanField(
        default=True,
        help_text="Whether queue is active for this service (false = completely closed)"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Queue Configuration'
        verbose_name_plural = 'Queue Configurations'
        indexes = [
            models.Index(fields=['staff_service', 'active']),
            models.Index(fields=['ministry', 'active']),
        ]
    
    def __str__(self):
        ministry_name = self.ministry.name if self.ministry else 'No Ministry'
        return f"Queue Config: {self.staff_service.service_name} ({ministry_name})"
    
    def calculate_daily_capacity(self):
        """
        Calculate dynamic daily capacity based on office hours and service time.
        
        Formula:
        daily_capacity = (working_minutes - lunch_minutes) / average_service_time_minutes
        
        Returns:
            int: Maximum tokens that can be served per day
        """
        from datetime import datetime, timedelta
        
        # Calculate total office hours in minutes
        start = datetime.combine(datetime.today(), self.office_start_time)
        end = datetime.combine(datetime.today(), self.office_end_time)
        total_minutes = int((end - start).total_seconds() / 60)
        
        # Subtract lunch break if configured
        if self.lunch_start_time and self.lunch_end_time:
            lunch_start = datetime.combine(datetime.today(), self.lunch_start_time)
            lunch_end = datetime.combine(datetime.today(), self.lunch_end_time)
            lunch_minutes = int((lunch_end - lunch_start).total_seconds() / 60)
            total_minutes -= lunch_minutes
        
        # Calculate capacity
        if self.average_service_time_minutes > 0:
            return int(total_minutes / self.average_service_time_minutes)
        
        return 0
    
    def clean(self):
        """
        Validate queue configuration rules.
        All validation MUST be at backend/database level.
        """
        super().clean()
        
        # Rule 1: Ministry must match staff service's ministry
        if self.staff_service and self.ministry:
            if self.staff_service.ministry and self.staff_service.ministry.id != self.ministry.id:
                raise ValidationError({
                    'ministry': 'Ministry must match staff service ministry'
                })
        
        # Rule 2: office_start < office_end
        if self.office_start_time and self.office_end_time:
            if self.office_start_time >= self.office_end_time:
                raise ValidationError({
                    'office_end_time': 'Office end time must be after start time'
                })
        
        # Rule 3: lunch must be inside office hours
        if self.lunch_start_time and self.lunch_end_time:
            if self.lunch_start_time >= self.lunch_end_time:
                raise ValidationError({
                    'lunch_end_time': 'Lunch end time must be after start time'
                })
            
            if self.office_start_time and self.office_end_time:
                if self.lunch_start_time < self.office_start_time or self.lunch_end_time > self.office_end_time:
                    raise ValidationError({
                        'lunch_start_time': 'Lunch break must be within office hours'
                    })
        
        # Rule 4: average_service_time_minutes > 0
        if self.average_service_time_minutes and self.average_service_time_minutes <= 0:
            raise ValidationError({
                'average_service_time_minutes': 'Must be greater than 0'
            })
        
        # Rule 5: Prebooking validation
        if self.prebooking_allowed:
            if not self.prebooking_lead_hours or self.prebooking_lead_hours <= 0:
                raise ValidationError({
                    'prebooking_lead_hours': 'Must be greater than 0 when prebooking is allowed'
                })
            if not self.prebooking_quota_per_day or self.prebooking_quota_per_day <= 0:
                raise ValidationError({
                    'prebooking_quota_per_day': 'Must be greater than 0 when prebooking is allowed'
                })
        
        # Rule 6: Emergency booking validation
        if self.emergency_allowed:
            if self.emergency_fee is None or self.emergency_fee < 0:
                raise ValidationError({
                    'emergency_fee': 'Must be 0 or greater when emergency booking is allowed'
                })
            if not self.emergency_quota_per_day or self.emergency_quota_per_day <= 0:
                raise ValidationError({
                    'emergency_quota_per_day': 'Must be greater than 0 when emergency booking is allowed'
                })
        
        # Rule 7: All higher officials must belong to same ministry
        # Note: This validation runs in clean(), but for ManyToMany we also need save() validation
        # See save() method for runtime validation of officials
        
        # Progress tracking validation - Note: steps will be created after config is saved
        # Step validation happens in the service layer
    
    def save(self, *args, **kwargs):
        # Auto-set ministry from staff_service if not provided
        if self.staff_service and not self.ministry:
            self.ministry = self.staff_service.ministry
        
        # Keep both progress tracking fields in sync (database has duplicate columns)
        if self.enable_progress_tracking != self.progress_tracking_enabled:
            self.progress_tracking_enabled = self.enable_progress_tracking
        
        self.full_clean()
        super().save(*args, **kwargs)
        
        # Validate ManyToMany relationships AFTER save (must exist in DB first)
        if self.pk and self.ministry:
            for official in self.higher_officials.all():
                if official.ministry and official.ministry.id != self.ministry.id:
                    raise ValidationError({
                        'higher_officials': f'All higher officials must belong to the same ministry. {official.name} belongs to {official.ministry.name}.'
                    })


class DailyQueue(models.Model):
    """
    Daily queue for a service.
    ONE queue per service per day.
    
    Auto-created ONLY if:
    - Not holiday
    - Staff PRESENT
    - Not Saturday
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Queue configuration
    queue_config = models.ForeignKey(
        QueueConfiguration,
        on_delete=models.CASCADE,
        related_name='daily_queues',
        help_text="Queue configuration for this daily queue"
    )
    
    # Date
    date = models.DateField(
        help_text="Date for which this queue is created"
    )
    
    # Token counter
    next_token_number = models.IntegerField(
        default=1,
        help_text="Next token number to assign"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'Daily Queue'
        verbose_name_plural = 'Daily Queues'
        unique_together = [['queue_config', 'date']]
        ordering = ['-date']
        indexes = [
            models.Index(fields=['queue_config', 'date']),
            models.Index(fields=['date']),
        ]
    
    def __str__(self):
        return f"{self.queue_config.staff_service.service_name} - {self.date}"


class QueueToken(models.Model):
    """
    Queue token for a citizen.
    Valid for ONE DAY only.
    
    Token types:
    - REGULAR: Normal walk-in or same-day booking
    - PREBOOKED: Advance booking (if allowed by config)
    - EMERGENCY: Emergency booking with fee (if allowed by config)
    
    Token Status:
    - WAITING: In active queue, waiting for turn
    - IN_SERVICE: Currently being served (countdown running)
    - PENDING: Moved to pending due to government/system fault
    - COMPLETED: Service finished successfully
    - CANCELLED: Cancelled after repeated no-shows
    
    Fields:
    - booking_type: Type of booking
    - emergency_fee_paid: Fee paid for emergency booking
    - status: Current token status
    - no_show_count: Tracks no-shows (max 2)
    - expected_service_time: UTC timestamp
    - pending_reason: Reason for moving to pending (government fault)
    - pending_priority_date: Date when pending token gets priority service
    """
    
    class BookingType(models.TextChoices):
        REGULAR = 'REGULAR', 'Regular'
        PREBOOKED = 'PREBOOKED', 'Pre-booked'
        EMERGENCY = 'EMERGENCY', 'Emergency'
    
    class Status(models.TextChoices):
        WAITING = 'WAITING', 'Waiting in Queue'
        IN_SERVICE = 'IN_SERVICE', 'Currently Being Served'
        PENDING = 'PENDING', 'Pending (Government Fault)'
        COMPLETED = 'COMPLETED', 'Service Completed'
        CANCELLED = 'CANCELLED', 'Cancelled'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Daily queue
    daily_queue = models.ForeignKey(
        DailyQueue,
        on_delete=models.CASCADE,
        related_name='tokens',
        help_text="Daily queue for this token"
    )
    
    # Citizen
    citizen = models.ForeignKey(
        'authentication.CustomUser',
        on_delete=models.CASCADE,
        related_name='queue_tokens',
        help_text="Citizen who booked this token"
    )
    
    # Token details
    token_number = models.IntegerField(
        help_text="Token number for the day"
    )
    
    # Booking type
    booking_type = models.CharField(
        max_length=10,
        choices=BookingType.choices,
        default=BookingType.REGULAR,
        help_text="Type of booking (REGULAR, PREBOOKED, EMERGENCY)"
    )
    
    # Emergency fee tracking
    emergency_fee_paid = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0'),
        help_text="Fee paid for emergency booking (0 for regular/prebooked)"
    )
    
    expected_service_time = models.DateTimeField(
        help_text="Expected time when citizen will be served (UTC)"
    )
    
    # No-show tracking
    no_show_count = models.IntegerField(
        default=0,
        help_text="Number of times citizen was marked as no-show (max 2)"
    )
    
    # Token status (replaces simple active boolean)
    status = models.CharField(
        max_length=15,
        choices=Status.choices,
        default=Status.WAITING,
        help_text="Current token status"
    )
    
    # Pending token fields (for government/system fault)
    pending_reason = models.TextField(
        null=True,
        blank=True,
        help_text="Reason for moving to pending (government fault only)"
    )
    
    pending_priority_date = models.DateField(
        null=True,
        blank=True,
        help_text="Date when this pending token gets priority service"
    )
    
    # Service tracking
    service_started_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When the token service countdown started"
    )
    
    # Legacy field - kept for backwards compatibility
    active = models.BooleanField(
        default=True,
        help_text="False means token is finished (served/cancelled) - DEPRECATED, use status"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'Queue Token'
        verbose_name_plural = 'Queue Tokens'
        unique_together = [['daily_queue', 'token_number']]
        ordering = ['token_number']
        indexes = [
            models.Index(fields=['daily_queue', 'status']),
            models.Index(fields=['daily_queue', 'active']),
            models.Index(fields=['citizen', 'active']),
            models.Index(fields=['expected_service_time']),
            models.Index(fields=['booking_type']),
            models.Index(fields=['status']),
            models.Index(fields=['pending_priority_date']),
        ]
    
    def __str__(self):
        return f"Token #{self.token_number} ({self.booking_type}) - {self.daily_queue.queue_config.staff_service.service_name} - {self.daily_queue.date}"


class QueueEventLog(models.Model):
    """
    Immutable audit log for all token state changes.
    
    Events:
    - CREATED: Token booked by citizen
    - IN_SERVICE: Token turn came, countdown started
    - COMPLETED: Service completed (auto after countdown OR pending resolved)
    - NO_SHOW: Citizen didn't appear (first time)
    - PUSHED_BACK: Token pushed back in queue after no-show
    - MOVED_TO_PENDING: Token moved to pending queue (government fault)
    - CANCELLED: Token cancelled (max no-shows reached)
    - PROGRESS_COMPLETED: Progress step completed
    - PENDING_EMAIL_SENT: Email sent to pending token citizen
    - PRIORITY_RESTORED: Pending token restored to priority queue
    
    MANDATORY: ALL state changes MUST be logged.
    NO event deletion allowed.
    """
    
    class Event(models.TextChoices):
        CREATED = 'CREATED', 'Token Created'
        IN_SERVICE = 'IN_SERVICE', 'Service Started (Countdown)'
        COMPLETED = 'COMPLETED', 'Service Completed'
        NO_SHOW = 'NO_SHOW', 'Citizen No Show'
        PUSHED_BACK = 'PUSHED_BACK', 'Pushed Back in Queue'
        MOVED_TO_PENDING = 'MOVED_TO_PENDING', 'Moved to Pending Queue'
        CANCELLED = 'CANCELLED', 'Token Cancelled'
        PROGRESS_COMPLETED = 'PROGRESS_COMPLETED', 'Progress Step Completed'
        PENDING_EMAIL_SENT = 'PENDING_EMAIL_SENT', 'Pending Email Sent'
        PRIORITY_RESTORED = 'PRIORITY_RESTORED', 'Priority Service Restored'
        # Legacy event - kept for backwards compatibility
        SERVED = 'SERVED', 'Token Served (Legacy)'
        NO_SHOW_PUSHED = 'NO_SHOW_PUSHED', 'No Show - Pushed Back (Legacy)'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Token
    token = models.ForeignKey(
        QueueToken,
        on_delete=models.CASCADE,
        related_name='event_logs',
        help_text="Token for which this event occurred"
    )
    
    # Event details
    event = models.CharField(
        max_length=20,
        choices=Event.choices,
        help_text="Event type"
    )
    
    # Performer (user or system)
    performed_by = models.ForeignKey(
        'authentication.CustomUser',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='performed_events',
        help_text="User who performed this action (null for system)"
    )
    
    # Additional data (JSON)
    metadata = models.JSONField(
        default=dict,
        blank=True,
        help_text="Additional event metadata"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'Queue Event Log'
        verbose_name_plural = 'Queue Event Logs'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['token', 'event']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.event} - Token #{self.token.token_number} - {self.created_at}"


class ServiceProgressStep(models.Model):
    """
    Progress step configuration for a queue service.
    
    Each step represents a stage in service completion that staff will
    manually mark as complete. Simple like Google Forms - just step names.
    
    Examples:
    - Step 1: "Seen by Staff"
    - Step 2: "Seen by Chairman"
    - Step 3: "Approved"
    
    Rules:
    - Steps are ordered by step_order
    - Steps are MANUALLY completed by staff
    - Progress is displayed to citizens
    - Only used if queue_config.enable_progress_tracking = True
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Queue configuration
    queue_config = models.ForeignKey(
        QueueConfiguration,
        on_delete=models.CASCADE,
        related_name='progress_steps',
        help_text="Queue configuration for which this step is defined"
    )
    
    # Step details
    step_order = models.IntegerField(
        help_text="Order of the step (1, 2, 3, ...)"
    )
    
    title = models.CharField(
        max_length=200,
        help_text="Title of the step (e.g., 'Seen by Staff', 'Seen by Chairman')"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Service Progress Step'
        verbose_name_plural = 'Service Progress Steps'
        ordering = ['queue_config', 'step_order']
        unique_together = [['queue_config', 'step_order']]
        indexes = [
            models.Index(fields=['queue_config', 'step_order']),
        ]
    
    def __str__(self):
        return f"Step {self.step_order}: {self.title} ({self.queue_config.staff_service.service_name})"
    
    def clean(self):
        """Validate step configuration"""
        super().clean()
        
        # Rule: step_order must be positive
        if self.step_order and self.step_order <= 0:
            raise ValidationError({
                'step_order': 'Step order must be greater than 0'
            })
    
    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)


class TokenProgress(models.Model):
    """
    Tracks progress of a token through service steps.
    
    One record per token per step.
    Auto-created when token is booked (if progress tracking enabled).
    MANUALLY completed by staff after real-world verification.
    
    Rules:
    - All steps start as incomplete
    - Staff explicitly marks steps complete via API
    - Previous steps must be completed before advancing
    - Completed steps are immutable with audit trail
    - Attendance indicates official availability, NOT automatic completion
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Token
    token = models.ForeignKey(
        QueueToken,
        on_delete=models.CASCADE,
        related_name='progress_records',
        help_text="Token for which progress is tracked"
    )
    
    # Step
    step = models.ForeignKey(
        ServiceProgressStep,
        on_delete=models.CASCADE,
        related_name='token_progress',
        help_text="Progress step being tracked"
    )
    
    # Completion status
    completed = models.BooleanField(
        default=False,
        help_text="Whether this step has been completed"
    )
    
    completed_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When this step was completed (UTC)"
    )
    
    # Audit trail: Who completed this step
    completed_by = models.ForeignKey(
        'authentication.CustomUser',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='completed_progress_steps',
        help_text="Staff member who manually marked this step as complete"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'Token Progress'
        verbose_name_plural = 'Token Progress Records'
        ordering = ['token', 'step__step_order']
        unique_together = [['token', 'step']]
        indexes = [
            models.Index(fields=['token', 'completed']),
            models.Index(fields=['step', 'completed']),
            models.Index(fields=['completed_by']),
        ]
    
    def __str__(self):
        status = "✓" if self.completed else "○"
        return f"{status} Token #{self.token.token_number} - {self.step.title}"
