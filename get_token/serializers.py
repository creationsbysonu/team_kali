"""
Get Token Serializers

Serializers for citizen token booking flow:
1. List ministries by place
2. List services by ministry
3. Service details with queue config, officials, attendance
4. Token booking
"""
from rest_framework import serializers
from ministry.models import Ministry, StaffService
from officials.models import MinistryOfficial
from queue_management.models import (
    QueueConfiguration, 
    DailyQueue, 
    QueueToken, 
    ServiceProgressStep
)
from attendance.models import AttendanceRecord
from core.utils.nepal_time import get_nepal_today


# ============================================================
# STEP 1: List Ministries by Place
# ============================================================

class MinistryListSerializer(serializers.ModelSerializer):
    """
    Ministry list for citizen view.
    Shows all active ministries in a place.
    """
    logo_url = serializers.SerializerMethodField()
    services_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Ministry
        fields = [
            'id', 'name', 'slug', 'description',
            'logo_url', 'address', 'phone',
            'services_count'
        ]
    
    def get_logo_url(self, obj):
        if obj.logo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.logo.url)
            return obj.logo.url
        return None
    
    def get_services_count(self, obj):
        """Count of active services in this ministry"""
        return obj.staff_services.filter(is_active=True, status='active').count()


# ============================================================
# STEP 2: List Services by Ministry
# ============================================================

class ServiceListSerializer(serializers.ModelSerializer):
    """
    Service list for citizen view.
    Shows all active services in a ministry with availability status.
    """
    service_logo_url = serializers.SerializerMethodField()
    staff_image_url = serializers.SerializerMethodField()
    is_available_today = serializers.SerializerMethodField()
    availability_reason = serializers.SerializerMethodField()
    has_queue_config = serializers.SerializerMethodField()
    
    class Meta:
        model = StaffService
        fields = [
            'id', 'service_name', 'service_logo_url',
            'staff_name', 'staff_image_url',
            'is_available_today', 'availability_reason',
            'has_queue_config'
        ]
    
    def get_service_logo_url(self, obj):
        if obj.service_logo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.service_logo.url)
            return obj.service_logo.url
        return None
    
    def get_staff_image_url(self, obj):
        if obj.staff_image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.staff_image.url)
            return obj.staff_image.url
        return None
    
    def get_has_queue_config(self, obj):
        """Check if queue is configured for this service"""
        return hasattr(obj, 'queue_config') and obj.queue_config is not None
    
    def get_is_available_today(self, obj):
        """Check if service is available for booking today"""
        # Check if service is active
        if not obj.is_active or obj.status != 'active':
            return False
        
        # Check if queue config exists
        if not hasattr(obj, 'queue_config') or obj.queue_config is None:
            return False
        
        # Check if staff is present today
        today = get_nepal_today()
        staff_attendance = AttendanceRecord.objects.filter(
            staff=obj,
            date=today,
            person_type=AttendanceRecord.PersonType.STAFF
        ).first()
        
        # If no record, assume present (default behavior)
        if staff_attendance and staff_attendance.status == AttendanceRecord.Status.ABSENT:
            return False
        
        return True
    
    def get_availability_reason(self, obj):
        """Get reason why service is unavailable"""
        if not obj.is_active:
            return "सेवा निष्क्रिय छ (Service is inactive)"
        
        if obj.status != 'active':
            return "सेवा अहिले रोकिएको छ (Service is paused)"
        
        if not hasattr(obj, 'queue_config') or obj.queue_config is None:
            return "कतार कन्फिग सेटअप गरिएको छैन (Queue not configured)"
        
        today = get_nepal_today()
        staff_attendance = AttendanceRecord.objects.filter(
            staff=obj,
            date=today,
            person_type=AttendanceRecord.PersonType.STAFF
        ).first()
        
        if staff_attendance and staff_attendance.status == AttendanceRecord.Status.ABSENT:
            return f"कर्मचारी आज अनुपस्थित छन् (Staff absent today)"
        
        return None  # Service is available


# ============================================================
# STEP 3: Service Details with Queue Config
# ============================================================

class DocumentRequiredSerializer(serializers.Serializer):
    """Serializer for required documents"""
    name = serializers.CharField()
    sample_image_url = serializers.CharField(required=False, allow_null=True)


class ProgressStepSerializer(serializers.ModelSerializer):
    """Serializer for progress steps"""
    class Meta:
        model = ServiceProgressStep
        fields = ['id', 'step_order', 'title']


class OfficialAttendanceSerializer(serializers.ModelSerializer):
    """
    Official with today's attendance status.
    Used to show citizens which officials are present.
    """
    attendance_status = serializers.SerializerMethodField()
    is_present_today = serializers.SerializerMethodField()
    
    class Meta:
        model = MinistryOfficial
        fields = ['id', 'name', 'role', 'attendance_status', 'is_present_today']
    
    def get_is_present_today(self, obj):
        """Check if official is present today"""
        today = get_nepal_today()
        attendance = AttendanceRecord.objects.filter(
            official=obj,
            date=today,
            person_type=AttendanceRecord.PersonType.OFFICIAL
        ).first()
        
        # Default is present if no record
        if attendance:
            return attendance.status == AttendanceRecord.Status.PRESENT
        return True
    
    def get_attendance_status(self, obj):
        """Get attendance status text"""
        if self.get_is_present_today(obj):
            return "उपस्थित (Present)"
        return "अनुपस्थित (Absent)"


class QueueConfigDetailSerializer(serializers.ModelSerializer):
    """
    Complete queue configuration details for citizen view.
    Shows everything needed before booking a token.
    """
    # Basic info
    service_name = serializers.CharField(source='staff_service.service_name')
    service_logo_url = serializers.SerializerMethodField()
    staff_name = serializers.CharField(source='staff_service.staff_name')
    staff_image_url = serializers.SerializerMethodField()
    ministry_name = serializers.CharField(source='ministry.name')
    
    # Office hours (formatted for display)
    office_hours = serializers.SerializerMethodField()
    lunch_break = serializers.SerializerMethodField()
    
    # Service time info
    average_service_time_display = serializers.SerializerMethodField()
    daily_capacity = serializers.SerializerMethodField()
    
    # Documents required
    documents_required = DocumentRequiredSerializer(many=True)
    
    # Prebooking info
    prebooking_info = serializers.SerializerMethodField()
    
    # Emergency booking info
    emergency_info = serializers.SerializerMethodField()
    
    # Progress tracking
    progress_tracking_enabled = serializers.BooleanField(source='enable_progress_tracking')
    progress_steps = serializers.SerializerMethodField()
    
    # Officials linked to this service
    officials = serializers.SerializerMethodField()
    
    # Today's availability
    is_available_today = serializers.SerializerMethodField()
    availability_status = serializers.SerializerMethodField()
    tokens_available_today = serializers.SerializerMethodField()
    tokens_booked_today = serializers.SerializerMethodField()
    current_token = serializers.SerializerMethodField()
    estimated_wait_time = serializers.SerializerMethodField()
    
    class Meta:
        model = QueueConfiguration
        fields = [
            # Basic
            'id', 'service_name', 'service_logo_url',
            'staff_name', 'staff_image_url', 'ministry_name',
            
            # Office hours
            'office_hours', 'lunch_break',
            'office_start_time', 'office_end_time',
            'lunch_start_time', 'lunch_end_time',
            
            # Service info
            'average_service_time_minutes', 'average_service_time_display',
            'daily_capacity',
            
            # Documents
            'documents_required',
            
            # Prebooking
            'prebooking_allowed', 'prebooking_info',
            
            # Emergency
            'emergency_allowed', 'emergency_info',
            
            # Progress
            'progress_tracking_enabled', 'progress_steps',
            
            # Officials
            'officials',
            
            # Today's status
            'is_available_today', 'availability_status',
            'tokens_available_today', 'tokens_booked_today',
            'current_token', 'estimated_wait_time',
            
            # Meta
            'active'
        ]
    
    def get_service_logo_url(self, obj):
        if obj.staff_service.service_logo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.staff_service.service_logo.url)
            return obj.staff_service.service_logo.url
        return None
    
    def get_staff_image_url(self, obj):
        if obj.staff_service.staff_image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.staff_service.staff_image.url)
            return obj.staff_service.staff_image.url
        return None
    
    def get_office_hours(self, obj):
        """Format office hours for display"""
        start = obj.office_start_time.strftime('%I:%M %p')
        end = obj.office_end_time.strftime('%I:%M %p')
        return f"{start} - {end}"
    
    def get_lunch_break(self, obj):
        """Format lunch break for display"""
        if obj.lunch_start_time and obj.lunch_end_time:
            start = obj.lunch_start_time.strftime('%I:%M %p')
            end = obj.lunch_end_time.strftime('%I:%M %p')
            return f"{start} - {end}"
        return None
    
    def get_average_service_time_display(self, obj):
        """Format average service time"""
        mins = obj.average_service_time_minutes
        if mins >= 60:
            hours = mins // 60
            remaining = mins % 60
            if remaining:
                return f"{hours} घण्टा {remaining} मिनेट ({hours}h {remaining}m)"
            return f"{hours} घण्टा ({hours}h)"
        return f"{mins} मिनेट ({mins} minutes)"
    
    def get_daily_capacity(self, obj):
        """Calculate daily capacity"""
        return obj.calculate_daily_capacity()
    
    def get_prebooking_info(self, obj):
        """Get prebooking configuration"""
        if not obj.prebooking_allowed:
            return {
                "allowed": False,
                "message": "अग्रिम बुकिङ उपलब्ध छैन (Advance booking not available)"
            }
        return {
            "allowed": True,
            "lead_hours": obj.prebooking_lead_hours,
            "quota_per_day": obj.prebooking_quota_per_day,
            "message": f"{obj.prebooking_lead_hours} घण्टा अगाडि बुक गर्न सक्नुहुन्छ (Book {obj.prebooking_lead_hours} hours in advance)"
        }
    
    def get_emergency_info(self, obj):
        """Get emergency booking configuration"""
        if not obj.emergency_allowed:
            return {
                "allowed": False,
                "message": "आपतकालीन बुकिङ उपलब्ध छैन (Emergency booking not available)"
            }
        return {
            "allowed": True,
            "fee": str(obj.emergency_fee),
            "quota_per_day": obj.emergency_quota_per_day,
            "message": f"आपतकालीन शुल्क: रु. {obj.emergency_fee} (Emergency fee: Rs. {obj.emergency_fee})"
        }
    
    def get_progress_steps(self, obj):
        """Get progress steps if enabled"""
        if not obj.enable_progress_tracking:
            return []
        steps = obj.progress_steps.all().order_by('step_order')
        return ProgressStepSerializer(steps, many=True).data
    
    def get_officials(self, obj):
        """Get officials linked to this service with attendance"""
        officials = obj.higher_officials.filter(is_active=True)
        return OfficialAttendanceSerializer(officials, many=True, context=self.context).data
    
    def get_is_available_today(self, obj):
        """Check if service is available for booking today"""
        today = get_nepal_today()
        
        # Check queue config is active
        if not obj.active:
            return False
        
        # Check staff service is active
        if not obj.staff_service.is_active or obj.staff_service.status != 'active':
            return False
        
        # Check staff attendance
        staff_attendance = AttendanceRecord.objects.filter(
            staff=obj.staff_service,
            date=today,
            person_type=AttendanceRecord.PersonType.STAFF
        ).first()
        
        if staff_attendance and staff_attendance.status == AttendanceRecord.Status.ABSENT:
            return False
        
        # Check if Saturday (weekend)
        from core.utils.nepal_time import is_saturday
        if is_saturday(today):
            return False
        
        # Check holidays
        from holidays.models import Holiday
        if Holiday.objects.filter(date=today).exists():
            return False
        
        return True
    
    def get_availability_status(self, obj):
        """Get detailed availability status"""
        today = get_nepal_today()
        
        if not obj.active:
            return {
                "available": False,
                "reason": "कतार कन्फिग निष्क्रिय छ (Queue configuration is inactive)",
                "reason_code": "QUEUE_INACTIVE"
            }
        
        if not obj.staff_service.is_active:
            return {
                "available": False,
                "reason": "सेवा निष्क्रिय छ (Service is inactive)",
                "reason_code": "SERVICE_INACTIVE"
            }
        
        if obj.staff_service.status != 'active':
            return {
                "available": False,
                "reason": "सेवा रोकिएको छ (Service is paused)",
                "reason_code": "SERVICE_PAUSED"
            }
        
        # Check Saturday
        from core.utils.nepal_time import is_saturday
        if is_saturday(today):
            return {
                "available": False,
                "reason": "शनिबार बिदा (Saturday - Holiday)",
                "reason_code": "SATURDAY"
            }
        
        # Check holidays
        from holidays.models import Holiday
        holiday = Holiday.objects.filter(date=today).first()
        if holiday:
            return {
                "available": False,
                "reason": f"बिदा: {holiday.name} (Holiday: {holiday.name})",
                "reason_code": "HOLIDAY"
            }
        
        # Check staff attendance
        staff_attendance = AttendanceRecord.objects.filter(
            staff=obj.staff_service,
            date=today,
            person_type=AttendanceRecord.PersonType.STAFF
        ).first()
        
        if staff_attendance and staff_attendance.status == AttendanceRecord.Status.ABSENT:
            return {
                "available": False,
                "reason": "कर्मचारी आज अनुपस्थित छन् (Staff absent today)",
                "reason_code": "STAFF_ABSENT"
            }
        
        # Check capacity
        daily_queue = DailyQueue.objects.filter(
            queue_config=obj,
            date=today
        ).first()
        
        capacity = obj.calculate_daily_capacity()
        tokens_booked = 0
        if daily_queue:
            tokens_booked = daily_queue.tokens.filter(
                status__in=[QueueToken.Status.WAITING, QueueToken.Status.IN_SERVICE]
            ).count()
        
        if tokens_booked >= capacity:
            return {
                "available": False,
                "reason": "आजको क्षमता भरियो (Today's capacity is full)",
                "reason_code": "CAPACITY_FULL"
            }
        
        return {
            "available": True,
            "reason": "सेवा उपलब्ध छ (Service is available)",
            "reason_code": "AVAILABLE"
        }
    
    def get_tokens_available_today(self, obj):
        """Get number of tokens available today"""
        today = get_nepal_today()
        capacity = obj.calculate_daily_capacity()
        
        daily_queue = DailyQueue.objects.filter(
            queue_config=obj,
            date=today
        ).first()
        
        if not daily_queue:
            return capacity
        
        tokens_booked = daily_queue.tokens.filter(
            status__in=[QueueToken.Status.WAITING, QueueToken.Status.IN_SERVICE, QueueToken.Status.PENDING]
        ).count()
        
        return max(0, capacity - tokens_booked)
    
    def get_tokens_booked_today(self, obj):
        """Get number of tokens booked today"""
        today = get_nepal_today()
        
        daily_queue = DailyQueue.objects.filter(
            queue_config=obj,
            date=today
        ).first()
        
        if not daily_queue:
            return 0
        
        return daily_queue.tokens.filter(
            status__in=[QueueToken.Status.WAITING, QueueToken.Status.IN_SERVICE, QueueToken.Status.PENDING]
        ).count()
    
    def get_current_token(self, obj):
        """Get current token being served"""
        today = get_nepal_today()
        
        daily_queue = DailyQueue.objects.filter(
            queue_config=obj,
            date=today
        ).first()
        
        if not daily_queue:
            return None
        
        current = daily_queue.tokens.filter(
            status=QueueToken.Status.IN_SERVICE
        ).first()
        
        if current:
            return current.token_number
        return None
    
    def get_estimated_wait_time(self, obj):
        """Estimate wait time for a new token"""
        today = get_nepal_today()
        
        daily_queue = DailyQueue.objects.filter(
            queue_config=obj,
            date=today
        ).first()
        
        if not daily_queue:
            return "0 मिनेट (0 minutes)"
        
        waiting_count = daily_queue.tokens.filter(
            status=QueueToken.Status.WAITING
        ).count()
        
        wait_minutes = waiting_count * obj.average_service_time_minutes
        
        if wait_minutes >= 60:
            hours = wait_minutes // 60
            mins = wait_minutes % 60
            return f"लगभग {hours} घण्टा {mins} मिनेट (Approx. {hours}h {mins}m)"
        
        return f"लगभग {wait_minutes} मिनेट (Approx. {wait_minutes} minutes)"


# ============================================================
# STEP 4: Token Booking
# ============================================================

class TokenBookingRequestSerializer(serializers.Serializer):
    """
    Request serializer for booking a token.
    """
    service_id = serializers.UUIDField(
        help_text="Staff Service ID to book token for"
    )
    booking_type = serializers.ChoiceField(
        choices=[('REGULAR', 'Regular'), ('PREBOOKED', 'Pre-booked'), ('EMERGENCY', 'Emergency')],
        default='REGULAR',
        help_text="Type of booking"
    )
    booking_date = serializers.DateField(
        required=False,
        help_text="Date to book for (required for PREBOOKED type, defaults to today)"
    )


class TokenBookingResponseSerializer(serializers.ModelSerializer):
    """
    Response serializer after booking a token.
    Shows all token details for citizen.
    """
    service_name = serializers.CharField(source='daily_queue.queue_config.staff_service.service_name')
    ministry_name = serializers.CharField(source='daily_queue.queue_config.ministry.name')
    booking_date = serializers.DateField(source='daily_queue.date')
    expected_service_time_display = serializers.SerializerMethodField()
    status_display = serializers.SerializerMethodField()
    position_in_queue = serializers.SerializerMethodField()
    
    class Meta:
        model = QueueToken
        fields = [
            'id', 'token_number',
            'service_name', 'ministry_name',
            'booking_date', 'booking_type',
            'expected_service_time', 'expected_service_time_display',
            'status', 'status_display',
            'position_in_queue',
            'emergency_fee_paid',
            'created_at'
        ]
    
    def get_expected_service_time_display(self, obj):
        """Format expected service time in Nepal timezone"""
        import pytz
        nepal_tz = pytz.timezone('Asia/Kathmandu')
        local_time = obj.expected_service_time.astimezone(nepal_tz)
        return local_time.strftime('%I:%M %p')
    
    def get_status_display(self, obj):
        """Get Nepali status display"""
        status_map = {
            'WAITING': 'पर्खिदै (Waiting)',
            'IN_SERVICE': 'सेवामा (Being Served)',
            'PENDING': 'पेन्डिङ (Pending)',
            'COMPLETED': 'सकियो (Completed)',
            'CANCELLED': 'रद्द भयो (Cancelled)'
        }
        return status_map.get(obj.status, obj.status)
    
    def get_position_in_queue(self, obj):
        """Get current position in queue"""
        if obj.status != QueueToken.Status.WAITING:
            return None
        
        waiting_before = obj.daily_queue.tokens.filter(
            status=QueueToken.Status.WAITING,
            token_number__lt=obj.token_number
        ).count()
        
        return waiting_before + 1
