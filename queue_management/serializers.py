"""
Serializers for Queue Management System.
"""

from rest_framework import serializers
from django.db import models
from .models import (
    QueueConfiguration, 
    DailyQueue, 
    QueueToken, 
    QueueEventLog,
    ServiceProgressStep,
    TokenProgress
)
from ministry.models import StaffService
from authentication.models import CustomUser


class QueueConfigurationSerializer(serializers.ModelSerializer):
    """Serializer for viewing queue configuration."""
    
    staff_service_name = serializers.SerializerMethodField()
    ministry_name = serializers.SerializerMethodField()
    ministry_id = serializers.UUIDField(source='ministry.id', read_only=True)
    office_hours = serializers.SerializerMethodField()
    lunch_hours = serializers.SerializerMethodField()
    calculated_daily_capacity = serializers.SerializerMethodField()
    higher_officials_details = serializers.SerializerMethodField()
    # Convert Decimal to float for frontend compatibility
    emergency_fee = serializers.SerializerMethodField()
    
    class Meta:
        model = QueueConfiguration
        fields = [
            'id',
            'staff_service',
            'staff_service_name',
            'ministry',
            'ministry_id',
            'ministry_name',
            'office_start_time',
            'office_end_time',
            'office_hours',
            'lunch_start_time',
            'lunch_end_time',
            'lunch_hours',
            'average_service_time_minutes',
            'calculated_daily_capacity',
            'documents_required',
            'prebooking_allowed',
            'prebooking_lead_hours',
            'prebooking_quota_per_day',
            'emergency_allowed',
            'emergency_fee',
            'emergency_quota_per_day',
            'higher_officials',
            'higher_officials_details',
            'enable_progress_tracking',
            'active',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'ministry', 'ministry_id', 'calculated_daily_capacity', 'created_at', 'updated_at']
    
    def get_staff_service_name(self, obj):
        """Get staff service name."""
        return obj.staff_service.service_name if obj.staff_service else None
    
    def get_ministry_name(self, obj):
        """Get ministry name."""
        return obj.ministry.name if obj.ministry else None
    
    def get_office_hours(self, obj):
        """Get formatted office hours."""
        return f"{obj.office_start_time.strftime('%I:%M %p')} - {obj.office_end_time.strftime('%I:%M %p')}"
    
    def get_lunch_hours(self, obj):
        """Get formatted lunch hours."""
        if obj.lunch_start_time and obj.lunch_end_time:
            return f"{obj.lunch_start_time.strftime('%I:%M %p')} - {obj.lunch_end_time.strftime('%I:%M %p')}"
        return None
    
    def get_calculated_daily_capacity(self, obj):
        """Get dynamically calculated daily capacity."""
        return obj.calculate_daily_capacity()
    
    def get_higher_officials_details(self, obj):
        """Get array of higher officials with their details."""
        officials = obj.higher_officials.all()
        return [
            {
                'id': str(official.id),
                'name': official.name,
                'role': official.role
            }
            for official in officials
        ]
    
    def get_emergency_fee(self, obj):
        """Convert Decimal to float for frontend compatibility."""
        if obj.emergency_fee is not None:
            return float(obj.emergency_fee)
        return None


class ProgressStepInputSerializer(serializers.Serializer):
    """Serializer for progress step input during queue configuration.
    
    Simple like Google Forms - just step name and order.
    """
    title = serializers.CharField(max_length=200, help_text="Step title (e.g., 'Seen by Staff', 'Seen by Chairman')")
    step_order = serializers.IntegerField(min_value=1, help_text="Order of the step (1, 2, 3, ...)")


class QueueConfigurationCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating queue configuration with optional progress steps."""
    
    from officials.models import MinistryOfficial
    
    progress_steps = ProgressStepInputSerializer(many=True, required=False, help_text="Progress tracking steps")
    higher_officials = serializers.PrimaryKeyRelatedField(
        many=True,
        required=False,
        queryset=MinistryOfficial.objects.filter(is_active=True),
        help_text="Array of higher official IDs to assign to this service"
    )
    
    class Meta:
        model = QueueConfiguration
        fields = [
            'staff_service',
            'office_start_time',
            'office_end_time',
            'lunch_start_time',
            'lunch_end_time',
            'average_service_time_minutes',
            'documents_required',
            'prebooking_allowed',
            'prebooking_lead_hours',
            'prebooking_quota_per_day',
            'emergency_allowed',
            'emergency_fee',
            'emergency_quota_per_day',
            'higher_officials',
            'enable_progress_tracking',
            'progress_tracking_enabled',  # Alias field for compatibility
            'progress_steps',  # New field
            'active',
        ]
    
    def validate_staff_service(self, value):
        """Validate that staff service is active."""
        if not value.is_active:
            raise serializers.ValidationError("Cannot create configuration for inactive staff service.")
        
        return value
    
    def validate_documents_required(self, value):
        """Validate documents_required structure."""
        if not isinstance(value, list):
            raise serializers.ValidationError("documents_required must be a list")
        
        for doc in value:
            if not isinstance(doc, dict):
                raise serializers.ValidationError("Each document must be a dictionary")
            if 'name' not in doc:
                raise serializers.ValidationError("Each document must have a 'name' field")
            # sample_image_url is optional
        
        return value
    
    def validate_higher_officials(self, value):
        """Validate all higher officials belong to same ministry as the service."""
        if hasattr(self, 'initial_data') and self.initial_data:
            staff_service_id = self.initial_data.get('staff_service')  # type: ignore[union-attr]
            if value and staff_service_id:
                from ministry.models import StaffService
                try:
                    service = StaffService.objects.get(id=staff_service_id)
                    for official in value:
                        if official.ministry and service.ministry and official.ministry.id != service.ministry.id:
                            raise serializers.ValidationError(
                                f"All higher officials must belong to the same ministry as the staff service. {official.name} belongs to {official.ministry.name}."
                            )
                except StaffService.DoesNotExist:
                    pass  # Will be caught by validate_staff_service
        
        return value
    
    def validate(self, attrs):
        """Cross-field validation (backend enforcement)."""
        # Sync both progress tracking fields (database has duplicate columns)
        if 'progress_tracking_enabled' in attrs or 'enable_progress_tracking' in attrs:
            # Use whichever field was provided, or default to False
            value = attrs.get('enable_progress_tracking', attrs.get('progress_tracking_enabled', False))
            attrs['enable_progress_tracking'] = value
            attrs['progress_tracking_enabled'] = value
        
        office_start = attrs.get('office_start_time')
        office_end = attrs.get('office_end_time')
        lunch_start = attrs.get('lunch_start_time')
        lunch_end = attrs.get('lunch_end_time')
        
        # Rule 1: Validate office hours
        if office_start and office_end:
            if office_start >= office_end:
                raise serializers.ValidationError({
                    "office_end_time": "Office end time must be after start time."
                })
        
        # Rule 2: Validate lunch hours if provided
        if lunch_start or lunch_end:
            if not (lunch_start and lunch_end):
                raise serializers.ValidationError(
                    "Both lunch start and end times must be provided together."
                )
            
            if lunch_start >= lunch_end:
                raise serializers.ValidationError({
                    "lunch_end_time": "Lunch end time must be after start time."
                })
            
            # Lunch must be within office hours
            if office_start and office_end:
                if lunch_start < office_start or lunch_end > office_end:
                    raise serializers.ValidationError({
                        "lunch_hours": "Lunch hours must be within office hours."
                    })
        
        # Rule 3: Prebooking validation
        prebooking_allowed = attrs.get('prebooking_allowed', False)
        if prebooking_allowed:
            if not attrs.get('prebooking_lead_hours') or attrs.get('prebooking_lead_hours') <= 0:
                raise serializers.ValidationError({
                    "prebooking_lead_hours": "Must be greater than 0 when prebooking is allowed."
                })
            if not attrs.get('prebooking_quota_per_day') or attrs.get('prebooking_quota_per_day') <= 0:
                raise serializers.ValidationError({
                    "prebooking_quota_per_day": "Must be greater than 0 when prebooking is allowed."
                })
        
        # Rule 4: Emergency booking validation
        emergency_allowed = attrs.get('emergency_allowed', False)
        if emergency_allowed:
            emergency_fee = attrs.get('emergency_fee')
            if emergency_fee is None or emergency_fee < 0:
                raise serializers.ValidationError({
                    "emergency_fee": "Must be 0 or greater when emergency booking is allowed."
                })
            # Validate decimal places (max 2)
            if emergency_fee is not None:
                try:
                    # Check if more than 2 decimal places
                    decimal_places = abs(emergency_fee.as_tuple().exponent)
                    if decimal_places > 2:
                        raise serializers.ValidationError({
                            "emergency_fee": "Maximum 2 decimal places allowed (e.g., 100.50)."
                        })
                except AttributeError:
                    pass  # Not a Decimal, will be handled by field validation
            
            if not attrs.get('emergency_quota_per_day') or attrs.get('emergency_quota_per_day') <= 0:
                raise serializers.ValidationError({
                    "emergency_quota_per_day": "Must be greater than 0 when emergency booking is allowed."
                })
        
        # Rule 5: Progress tracking validation
        enable_progress_tracking = attrs.get('enable_progress_tracking', False)
        progress_steps = attrs.get('progress_steps', [])
        
        if enable_progress_tracking:
            if not progress_steps or len(progress_steps) == 0:
                raise serializers.ValidationError({
                    "progress_steps": "At least one progress step is required when progress tracking is enabled."
                })
            
            # Validate step_order uniqueness
            step_orders = [step['step_order'] for step in progress_steps]
            if len(step_orders) != len(set(step_orders)):
                raise serializers.ValidationError({
                    "progress_steps": "Each step must have a unique step_order."
                })
        
        return attrs
    
    def create(self, validated_data):
        """Create queue configuration with higher officials and progress steps."""
        # Extract ManyToMany and nested data
        higher_officials = validated_data.pop('higher_officials', [])
        progress_steps_data = validated_data.pop('progress_steps', [])
        
        # Create the queue configuration
        queue_config = QueueConfiguration.objects.create(**validated_data)
        
        # Set ManyToMany relationship for higher officials
        if higher_officials:
            queue_config.higher_officials.set(higher_officials)
        
        # Create progress steps if provided
        if progress_steps_data and queue_config.enable_progress_tracking:
            from .progress_tracking_service import ProgressTrackingService
            ProgressTrackingService.create_progress_steps(
                queue_config_id=str(queue_config.id),
                steps_data=progress_steps_data
            )
        
        return queue_config
    
    def update(self, instance, validated_data):
        """Update queue configuration with higher officials and progress steps."""
        # Extract ManyToMany and nested data
        higher_officials = validated_data.pop('higher_officials', None)
        progress_steps_data = validated_data.pop('progress_steps', None)
        
        # Update regular fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Update ManyToMany relationship for higher officials
        if higher_officials is not None:
            instance.higher_officials.set(higher_officials)
        
        # Update progress steps if provided
        if progress_steps_data is not None and instance.enable_progress_tracking:
            # Delete existing steps and create new ones
            instance.progress_steps.all().delete()  # type: ignore
            
            if progress_steps_data:
                from .progress_tracking_service import ProgressTrackingService
                ProgressTrackingService.create_progress_steps(
                    queue_config_id=str(instance.id),
                    steps_data=progress_steps_data
                )
        
        return instance


class DailyQueueSerializer(serializers.ModelSerializer):
    """Serializer for viewing daily queue."""
    
    staff_service_name = serializers.SerializerMethodField()
    ministry_name = serializers.SerializerMethodField()
    total_tokens = serializers.SerializerMethodField()
    served_count = serializers.SerializerMethodField()
    pending_count = serializers.SerializerMethodField()
    no_show_count = serializers.SerializerMethodField()
    
    class Meta:
        model = DailyQueue
        fields = [
            'id',
            'queue_config',
            'staff_service_name',
            'ministry_name',
            'date',
            'next_token_number',
            'total_tokens',
            'served_count',
            'pending_count',
            'no_show_count',
            'created_at',
        ]
        read_only_fields = ['id', 'next_token_number', 'created_at']
    
    def get_staff_service_name(self, obj):
        """Get staff service name."""
        return obj.queue_config.staff_service.name if obj.queue_config.staff_service else None
    
    def get_ministry_name(self, obj):
        """Get ministry name."""
        if obj.queue_config.staff_service and obj.queue_config.staff_service.ministry:
            return obj.queue_config.staff_service.ministry.name
        return None
    
    def get_total_tokens(self, obj):
        """Get total number of tokens for this queue."""
        return obj.tokens.count()
    
    def get_served_count(self, obj):
        """Get count of served tokens."""
        return obj.tokens.filter(active=False).count()
    
    def get_pending_count(self, obj):
        """Get count of pending tokens."""
        return obj.tokens.filter(active=True).count()
    
    def get_no_show_count(self, obj):
        """Get count of no-show events."""
        from django.db.models import Count
        return obj.tokens.aggregate(
            total_no_shows=Count('events', filter=models.Q(events__event=QueueEventLog.Event.NO_SHOW_PUSHED))
        )['total_no_shows'] or 0


class QueueTokenSerializer(serializers.ModelSerializer):
    """Serializer for viewing queue token."""
    
    citizen_name = serializers.SerializerMethodField()
    citizen_email = serializers.SerializerMethodField()
    expected_service_time_nepal = serializers.SerializerMethodField()
    status = serializers.SerializerMethodField()
    latest_event = serializers.SerializerMethodField()
    token_type = serializers.SerializerMethodField()
    booking_type_display = serializers.CharField(source='get_booking_type_display', read_only=True)
    
    class Meta:
        model = QueueToken
        fields = [
            'id',
            'daily_queue',
            'citizen',
            'citizen_name',
            'citizen_email',
            'token_number',
            'booking_type',
            'booking_type_display',
            'emergency_fee_paid',
            'expected_service_time',
            'expected_service_time_nepal',
            'no_show_count',
            'active',
            'status',
            'token_type',
            'latest_event',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'token_number', 'no_show_count', 'created_at', 'updated_at']
    
    def get_citizen_name(self, obj):
        """Get citizen name."""
        return obj.citizen.username if obj.citizen else None
    
    def get_citizen_email(self, obj):
        """Get citizen email."""
        return obj.citizen.email if obj.citizen else None
    
    def get_expected_service_time_nepal(self, obj):
        """Get expected service time in Nepal timezone."""
        from core.utils.nepal_time import format_nepal_datetime
        return format_nepal_datetime(obj.expected_service_time)
    
    def get_status(self, obj):
        """Get human-readable status."""
        if not obj.active:
            return "Completed/Cancelled"
        elif obj.no_show_count >= 2:
            return "Auto-Cancelled (Max No-Shows)"
        else:
            return "Waiting"
    
    def get_token_type(self, obj):
        """
        Get token type: NORMAL or PROGRESS_TRACKED.
        
        NORMAL tokens: Handled with SERVED/NO-SHOW/CANCEL actions
        PROGRESS_TRACKED tokens: Require manual step-by-step progression
        """
        if obj.daily_queue and obj.daily_queue.queue_config:
            if obj.daily_queue.queue_config.enable_progress_tracking:
                return "PROGRESS_TRACKED"
        return "NORMAL"
    
    def get_latest_event(self, obj):
        """Get the latest event for this token."""
        latest = obj.events.order_by('-created_at').first()
        if latest:
            return {
                'event': latest.event,
                'event_display': latest.get_event_display(),
                'timestamp': latest.created_at,
            }
        return None


class QueueTokenBookingSerializer(serializers.Serializer):
    """Serializer for booking a queue token."""
    
    staff_service_id = serializers.UUIDField()
    date = serializers.DateField()
    booking_type = serializers.ChoiceField(
        choices=['REGULAR', 'PREBOOKED', 'EMERGENCY'],
        default='REGULAR',
        required=False
    )
    
    def validate_date(self, value):
        """Validate that date is today or future."""
        from core.utils.nepal_time import get_nepal_today
        
        today = get_nepal_today()
        if value < today:
            raise serializers.ValidationError("Cannot book tokens for past dates.")
        
        return value
    
    def validate_staff_service_id(self, value):
        """Validate that staff service exists and is active."""
        try:
            staff_service = StaffService.objects.get(id=value, is_active=True)
        except StaffService.DoesNotExist:
            raise serializers.ValidationError("Staff service not found or inactive.")
        
        return value
    
    def validate(self, attrs):
        """Cross-field validation for booking type."""
        from datetime import datetime, timedelta
        from core.utils.nepal_time import get_nepal_now
        
        booking_type = attrs.get('booking_type', 'REGULAR')
        date = attrs.get('date')
        staff_service_id = attrs.get('staff_service_id')
        
        # Get queue configuration
        from ministry.models import StaffService
        try:
            staff_service = StaffService.objects.get(id=staff_service_id)
            queue_config = QueueConfiguration.objects.get(staff_service=staff_service, active=True)
        except (StaffService.DoesNotExist, QueueConfiguration.DoesNotExist):
            raise serializers.ValidationError("Queue configuration not found.")
        
        # Validate prebooking
        if booking_type == 'PREBOOKED':
            if not queue_config.prebooking_allowed:
                raise serializers.ValidationError({
                    "booking_type": "Prebooking is not allowed for this service."
                })
            
            # Check prebooking lead time
            now = get_nepal_now()
            booking_datetime = datetime.combine(date, datetime.min.time())
            hours_until_booking = (booking_datetime - now.replace(tzinfo=None)).total_seconds() / 3600
            
            if queue_config.prebooking_lead_hours and hours_until_booking < queue_config.prebooking_lead_hours:
                raise serializers.ValidationError({
                    "booking_type": f"Prebooking requires at least {queue_config.prebooking_lead_hours} hours advance notice."
                })
        
        # Validate emergency booking
        if booking_type == 'EMERGENCY':
            if not queue_config.emergency_allowed:
                raise serializers.ValidationError({
                    "booking_type": "Emergency booking is not allowed for this service."
                })
        
        return attrs


class QueueTokenStaffActionSerializer(serializers.Serializer):
    """Serializer for staff actions on tokens (SERVED/NO_SHOW)."""
    
    token_id = serializers.UUIDField()
    action = serializers.ChoiceField(choices=['SERVED', 'NO_SHOW'])
    
    def validate_token_id(self, value):
        """Validate that token exists and is active."""
        try:
            token = QueueToken.objects.get(id=value)
        except QueueToken.DoesNotExist:
            raise serializers.ValidationError("Token not found.")
        
        if not token.active:
            raise serializers.ValidationError("Token is already completed or cancelled.")
        
        return value


class QueueEventLogSerializer(serializers.ModelSerializer):
    """Serializer for viewing queue event logs (immutable audit trail)."""
    
    token_number = serializers.SerializerMethodField()
    citizen_email = serializers.SerializerMethodField()
    performed_by_email = serializers.SerializerMethodField()
    event_display = serializers.CharField(source='get_event_display', read_only=True)
    
    class Meta:
        model = QueueEventLog
        fields = [
            'id',
            'token',
            'token_number',
            'citizen_email',
            'event',
            'event_display',
            'performed_by',
            'performed_by_email',
            'metadata',
            'created_at',
        ]
        read_only_fields = '__all__'  # All fields are read-only (immutable)
    
    def get_token_number(self, obj):
        """Get token number."""
        return obj.token.token_number if obj.token else None
    
    def get_citizen_email(self, obj):
        """Get citizen email."""
        return obj.token.citizen.email if obj.token and obj.token.citizen else None
    
    def get_performed_by_email(self, obj):
        """Get email of user who performed the action."""
        return obj.performed_by.email if obj.performed_by else "System"


class QueueStatusSerializer(serializers.Serializer):
    """Serializer for queue status response."""
    
    queue_available = serializers.BooleanField()
    message = serializers.CharField()
    daily_queue_id = serializers.UUIDField(required=False, allow_null=True)
    date = serializers.DateField()
    capacity_remaining = serializers.IntegerField(required=False)
    next_token_number = serializers.IntegerField(required=False)


class ServiceProgressStepSerializer(serializers.ModelSerializer):
    """Serializer for viewing progress steps."""
    
    class Meta:
        model = ServiceProgressStep
        fields = [
            'id',
            'queue_config',
            'step_order',
            'title',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class ServiceProgressStepCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating progress steps."""
    
    class Meta:
        model = ServiceProgressStep
        fields = [
            'queue_config',
            'step_order',
            'title',
        ]
    
    def validate(self, attrs):
        """Cross-field validation."""
        queue_config = attrs.get('queue_config')
        step_order = attrs.get('step_order')
        
        # Check for duplicate step_order
        if queue_config and step_order:
            existing = ServiceProgressStep.objects.filter(
                queue_config=queue_config,
                step_order=step_order
            ).exclude(id=self.instance.id if self.instance else None).first()
            
            if existing:
                raise serializers.ValidationError({
                    "step_order": f"Step order {step_order} already exists for this queue configuration."
                })
        
        return attrs


class TokenProgressSerializer(serializers.ModelSerializer):
    """Serializer for viewing token progress."""
    
    step_title = serializers.SerializerMethodField()
    step_order = serializers.SerializerMethodField()
    
    class Meta:
        model = TokenProgress
        fields = [
            'id',
            'token',
            'step',
            'step_title',
            'step_order',
            'completed',
            'completed_at',
            'created_at',
        ]
        read_only_fields = '__all__'  # Progress is manually managed via separate API
    
    def get_step_title(self, obj):
        """Get step title."""
        return obj.step.title if obj.step else None
    
    def get_step_order(self, obj):
        """Get step order."""
        return obj.step.step_order if obj.step else None


class QueueTokenWithProgressSerializer(serializers.ModelSerializer):
    """Serializer for queue token with progress information."""
    
    citizen_name = serializers.SerializerMethodField()
    citizen_email = serializers.SerializerMethodField()
    queue_name = serializers.SerializerMethodField()
    ministry_name = serializers.SerializerMethodField()
    progress = serializers.SerializerMethodField()
    progress_enabled = serializers.SerializerMethodField()
    
    class Meta:
        model = QueueToken
        fields = [
            'id',
            'daily_queue',
            'citizen',
            'citizen_name',
            'citizen_email',
            'token_number',
            'booked_at',
            'expected_service_time',
            'queue_name',
            'ministry_name',
            'active',
            'progress_enabled',
            'progress',
            'created_at',
        ]
        read_only_fields = '__all__'
    
    def get_citizen_name(self, obj):
        """Get citizen username."""
        return obj.citizen.username if obj.citizen else None
    
    def get_citizen_email(self, obj):
        """Get citizen email."""
        return obj.citizen.email if obj.citizen else None
    
    def get_queue_name(self, obj):
        """Get service name."""
        if obj.daily_queue and obj.daily_queue.queue_config:
            return obj.daily_queue.queue_config.staff_service.name
        return None
    
    def get_ministry_name(self, obj):
        """Get ministry name."""
        if obj.daily_queue and obj.daily_queue.queue_config:
            return obj.daily_queue.queue_config.staff_service.ministry.name
        return None
    
    def get_progress_enabled(self, obj):
        """Check if progress tracking is enabled."""
        if obj.daily_queue and obj.daily_queue.queue_config:
            return obj.daily_queue.queue_config.enable_progress_tracking
        return False
    
    def get_progress(self, obj):
        """Get progress steps if tracking enabled."""
        if obj.daily_queue and obj.daily_queue.queue_config:
            if obj.daily_queue.queue_config.enable_progress_tracking:
                progress_records = obj.progress_records.select_related('step').order_by('step__step_order')
                return TokenProgressSerializer(progress_records, many=True).data
        return []


# ====================================================
# Staff Panel Serializers (Active Tokens, All Tokens, Pending Tokens)
# ====================================================

class StaffActiveTokenSerializer(serializers.ModelSerializer):
    """
    Serializer for active tokens in staff panel.
    
    Shows tokens that are currently WAITING or IN_SERVICE for today.
    Includes countdown information and action buttons (NO_SHOW, PENDING).
    """
    citizen_name = serializers.SerializerMethodField()
    citizen_email = serializers.SerializerMethodField()
    citizen_phone = serializers.SerializerMethodField()
    service_name = serializers.SerializerMethodField()
    expected_service_time_nepal = serializers.SerializerMethodField()
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    countdown_seconds = serializers.SerializerMethodField()
    service_time_remaining_seconds = serializers.SerializerMethodField()
    is_being_served = serializers.SerializerMethodField()
    can_mark_no_show = serializers.SerializerMethodField()
    can_mark_pending = serializers.SerializerMethodField()
    
    class Meta:
        model = QueueToken
        fields = [
            'id',
            'token_number',
            'citizen_name',
            'citizen_email',
            'citizen_phone',
            'service_name',
            'booking_type',
            'expected_service_time',
            'expected_service_time_nepal',
            'status',
            'status_display',
            'no_show_count',
            'is_being_served',
            'countdown_seconds',
            'service_time_remaining_seconds',
            'service_started_at',
            'can_mark_no_show',
            'can_mark_pending',
            'created_at',
        ]
        read_only_fields = '__all__'
    
    def get_citizen_name(self, obj):
        """Get citizen username."""
        return obj.citizen.username if obj.citizen else None
    
    def get_citizen_email(self, obj):
        """Get citizen email."""
        return obj.citizen.email if obj.citizen else None
    
    def get_citizen_phone(self, obj):
        """Get citizen phone."""
        return getattr(obj.citizen, 'phone', None) if obj.citizen else None
    
    def get_service_name(self, obj):
        """Get service name."""
        if obj.daily_queue and obj.daily_queue.queue_config:
            return obj.daily_queue.queue_config.staff_service.service_name
        return None
    
    def get_expected_service_time_nepal(self, obj):
        """Get expected service time in Nepal timezone."""
        from core.utils.nepal_time import format_nepal_datetime
        return format_nepal_datetime(obj.expected_service_time)
    
    def get_countdown_seconds(self, obj):
        """
        Get countdown seconds until token turn.
        
        Returns positive value if turn hasn't come yet.
        Returns 0 if it's this token's turn.
        Returns None if already being served.
        """
        if obj.status == QueueToken.Status.IN_SERVICE:
            return None  # Already being served
        
        if not obj.expected_service_time:
            return None
        
        from django.utils import timezone
        now = timezone.now()
        time_until = (obj.expected_service_time - now).total_seconds()
        
        return max(0, int(time_until))
    
    def get_service_time_remaining_seconds(self, obj):
        """
        Get remaining time until auto-completion (when IN_SERVICE).
        
        Returns seconds remaining before system auto-completes the token.
        """
        if obj.status != QueueToken.Status.IN_SERVICE:
            return None
        
        if not obj.service_started_at:
            return None
        
        from django.utils import timezone
        
        # Get average service time from config
        avg_minutes = 10  # Default
        if obj.daily_queue and obj.daily_queue.queue_config:
            avg_minutes = obj.daily_queue.queue_config.average_service_time_minutes or 10
        
        service_end_time = obj.service_started_at + timezone.timedelta(minutes=avg_minutes)
        remaining = (service_end_time - timezone.now()).total_seconds()
        
        return max(0, int(remaining))
    
    def get_is_being_served(self, obj):
        """Check if this token is currently being served."""
        return obj.status == QueueToken.Status.IN_SERVICE
    
    def get_can_mark_no_show(self, obj):
        """
        Check if staff can mark this token as NO_SHOW.
        
        Can only mark no-show when:
        - Token is WAITING (not yet IN_SERVICE)
        - It's the token's turn (countdown reached 0)
        """
        if obj.status != QueueToken.Status.WAITING:
            return False
        
        # Check if it's this token's turn
        countdown = self.get_countdown_seconds(obj)
        return countdown is not None and countdown == 0
    
    def get_can_mark_pending(self, obj):
        """
        Check if staff can mark this token as PENDING.
        
        Can only mark pending when:
        - Token is currently IN_SERVICE
        - Due to government/system fault
        """
        return obj.status == QueueToken.Status.IN_SERVICE


class StaffAllTokenSerializer(serializers.ModelSerializer):
    """
    Serializer for all tokens in staff panel.
    
    Shows all tokens for today with their complete status history.
    """
    citizen_name = serializers.SerializerMethodField()
    citizen_email = serializers.SerializerMethodField()
    service_name = serializers.SerializerMethodField()
    expected_service_time_nepal = serializers.SerializerMethodField()
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    booking_type_display = serializers.CharField(source='get_booking_type_display', read_only=True)
    latest_event = serializers.SerializerMethodField()
    
    class Meta:
        model = QueueToken
        fields = [
            'id',
            'token_number',
            'citizen_name',
            'citizen_email',
            'service_name',
            'booking_type',
            'booking_type_display',
            'expected_service_time',
            'expected_service_time_nepal',
            'status',
            'status_display',
            'no_show_count',
            'active',
            'latest_event',
            'created_at',
            'updated_at',
        ]
        read_only_fields = '__all__'
    
    def get_citizen_name(self, obj):
        """Get citizen username."""
        return obj.citizen.username if obj.citizen else None
    
    def get_citizen_email(self, obj):
        """Get citizen email."""
        return obj.citizen.email if obj.citizen else None
    
    def get_service_name(self, obj):
        """Get service name."""
        if obj.daily_queue and obj.daily_queue.queue_config:
            return obj.daily_queue.queue_config.staff_service.service_name
        return None
    
    def get_expected_service_time_nepal(self, obj):
        """Get expected service time in Nepal timezone."""
        from core.utils.nepal_time import format_nepal_datetime
        return format_nepal_datetime(obj.expected_service_time)
    
    def get_latest_event(self, obj):
        """Get the latest event for this token."""
        latest = obj.events.order_by('-created_at').first()
        if latest:
            return {
                'event': latest.event,
                'event_display': latest.get_event_display(),
                'performed_by': latest.performed_by.email if latest.performed_by else 'System',
                'timestamp': latest.created_at,
            }
        return None


class StaffPendingTokenSerializer(serializers.ModelSerializer):
    """
    Serializer for pending tokens in staff panel.
    
    Shows tokens marked as PENDING due to government/system fault.
    These tokens get priority service on their pending_priority_date.
    """
    citizen_name = serializers.SerializerMethodField()
    citizen_email = serializers.SerializerMethodField()
    citizen_phone = serializers.SerializerMethodField()
    service_name = serializers.SerializerMethodField()
    original_date = serializers.SerializerMethodField()
    priority_date_display = serializers.SerializerMethodField()
    is_priority_today = serializers.SerializerMethodField()
    email_sent = serializers.SerializerMethodField()
    can_send_email = serializers.SerializerMethodField()
    can_mark_served = serializers.SerializerMethodField()
    
    class Meta:
        model = QueueToken
        fields = [
            'id',
            'token_number',
            'citizen_name',
            'citizen_email',
            'citizen_phone',
            'service_name',
            'pending_reason',
            'pending_priority_date',
            'priority_date_display',
            'is_priority_today',
            'original_date',
            'email_sent',
            'can_send_email',
            'can_mark_served',
            'created_at',
        ]
        read_only_fields = '__all__'
    
    def get_citizen_name(self, obj):
        """Get citizen username."""
        return obj.citizen.username if obj.citizen else None
    
    def get_citizen_email(self, obj):
        """Get citizen email."""
        return obj.citizen.email if obj.citizen else None
    
    def get_citizen_phone(self, obj):
        """Get citizen phone."""
        return getattr(obj.citizen, 'phone', None) if obj.citizen else None
    
    def get_service_name(self, obj):
        """Get service name."""
        if obj.daily_queue and obj.daily_queue.queue_config:
            return obj.daily_queue.queue_config.staff_service.service_name
        return None
    
    def get_original_date(self, obj):
        """Get the original booking date."""
        if obj.daily_queue:
            return obj.daily_queue.date
        return None
    
    def get_priority_date_display(self, obj):
        """Get formatted priority date."""
        if obj.pending_priority_date:
            return obj.pending_priority_date.strftime('%B %d, %Y')
        return None
    
    def get_is_priority_today(self, obj):
        """Check if this pending token has priority today."""
        from core.utils.nepal_time import get_nepal_today
        today = get_nepal_today()
        return obj.pending_priority_date == today
    
    def get_email_sent(self, obj):
        """Check if pending email has been sent."""
        return obj.events.filter(event=QueueEventLog.Event.PENDING_EMAIL_SENT).exists()
    
    def get_can_send_email(self, obj):
        """Check if we can send pending email."""
        # Can send if email not already sent and citizen has email
        email_sent = self.get_email_sent(obj)
        has_email = obj.citizen and obj.citizen.email
        return not email_sent and has_email
    
    def get_can_mark_served(self, obj):
        """
        Check if this pending token can be marked as served.
        
        Can only mark served on the priority date.
        """
        return self.get_is_priority_today(obj)


class MarkPendingSerializer(serializers.Serializer):
    """
    Serializer for marking a token as PENDING.
    
    Staff provides a reason for why the token couldn't be served
    due to government/system fault.
    """
    reason = serializers.CharField(
        max_length=500,
        required=True,
        help_text="Reason for marking as pending (government/system fault)"
    )
    
    def validate_reason(self, value):
        """Validate reason is not empty."""
        if not value or not value.strip():
            raise serializers.ValidationError("Reason is required when marking a token as pending.")
        return value.strip()


class StartServiceSerializer(serializers.Serializer):
    """
    Serializer for starting token service (used internally by system).
    
    This transitions a token from WAITING to IN_SERVICE.
    """
    pass  # No input needed - action is triggered by token turn


class MarkPendingServedSerializer(serializers.Serializer):
    """
    Serializer for marking a pending token as served.
    
    Used when a citizen with a pending token returns on their priority date.
    """
    pass  # No input needed - just marking as served

