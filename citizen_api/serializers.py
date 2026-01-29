"""
Citizen API - Optimized Serializers for Flutter

Design Principles:
1. MINIMAL PAYLOAD - Only include fields that Flutter UI actually needs
2. NO NESTED QUERIES - Use SerializerMethodField with prefetched data
3. PRECOMPUTED VALUES - Calculate availability, counts etc. in service layer
4. FLAT STRUCTURE - Avoid deeply nested objects for easier parsing
5. CONSISTENT NAMING - snake_case for all fields

Response Size Targets:
- Ministry list item: < 500 bytes
- Service list item: < 600 bytes  
- Service details: < 2KB
- Token item: < 800 bytes
"""
from rest_framework import serializers
from ministry.models import Ministry, StaffService
from officials.models import MinistryOfficial
from queue_management.models import (
    QueueConfiguration,
    QueueToken,
    ServiceProgressStep,
    TokenProgress
)


# =============================================================================
# PHASE 1: PLACE & MINISTRY LISTING (First screen in Flutter)
# =============================================================================

class MinistryListLiteSerializer(serializers.Serializer):
    """
    Ultra-lightweight ministry serializer for list view.
    Target: < 500 bytes per item
    """
    id = serializers.UUIDField()
    name = serializers.CharField()
    slug = serializers.CharField()
    logo_url = serializers.CharField(allow_null=True)
    services_count = serializers.IntegerField()
    
    # Optional fields (lazy load on scroll)
    address = serializers.CharField(required=False, allow_null=True)
    phone = serializers.CharField(required=False, allow_null=True)


# =============================================================================
# PHASE 2: SERVICES LISTING (After ministry selected)
# =============================================================================

class ServiceListLiteSerializer(serializers.Serializer):
    """
    Lightweight service serializer for list view.
    Target: < 600 bytes per item
    
    Critical fields for initial display:
    - id, name, logo for identification
    - is_available_today for UI state (green/red indicator)
    - availability_reason for tooltip/message
    """
    id = serializers.UUIDField()
    service_name = serializers.CharField()
    service_logo_url = serializers.CharField(allow_null=True)
    staff_name = serializers.CharField()
    staff_image_url = serializers.CharField(allow_null=True)
    
    # Availability (pre-computed in service layer)
    is_available_today = serializers.BooleanField()
    availability_reason = serializers.CharField(allow_null=True)
    availability_code = serializers.CharField(allow_null=True)
    
    # Quick stats (for UI badges)
    tokens_available = serializers.IntegerField()
    current_queue_position = serializers.IntegerField(allow_null=True)


# =============================================================================
# PHASE 3: SERVICE DETAILS (After service selected - before booking)
# =============================================================================

class DocumentSerializer(serializers.Serializer):
    """Required document with sample image"""
    name = serializers.CharField()
    sample_image_url = serializers.CharField(allow_null=True)


class ProgressStepLiteSerializer(serializers.Serializer):
    """Progress step for citizen view"""
    step_order = serializers.IntegerField()
    title = serializers.CharField()


class OfficialLiteSerializer(serializers.Serializer):
    """Official with attendance status"""
    id = serializers.UUIDField()
    name = serializers.CharField()
    role = serializers.CharField()
    is_present = serializers.BooleanField()


class ServiceDetailsLiteSerializer(serializers.Serializer):
    """
    Complete service details for booking screen.
    Target: < 2KB total
    
    Sections:
    1. Basic info (name, ministry, staff)
    2. Office hours
    3. Booking options (regular, prebook, emergency)
    4. Required documents
    5. Today's availability
    6. Progress steps (if enabled)
    7. Officials (if any)
    """
    # Basic info
    id = serializers.UUIDField()
    service_name = serializers.CharField()
    service_logo_url = serializers.CharField(allow_null=True)
    staff_name = serializers.CharField()
    staff_image_url = serializers.CharField(allow_null=True)
    ministry_name = serializers.CharField()
    ministry_id = serializers.UUIDField()
    
    # Office hours (formatted for display)
    office_hours = serializers.CharField()  # "10:00 AM - 5:00 PM"
    lunch_break = serializers.CharField(allow_null=True)  # "1:00 PM - 2:00 PM"
    
    # Service time
    avg_service_time = serializers.CharField()  # "15 minutes"
    daily_capacity = serializers.IntegerField()
    
    # Booking options
    booking_options = serializers.DictField()
    # Structure: {
    #   "regular": {"enabled": true},
    #   "prebook": {"enabled": true, "lead_hours": 24, "quota": 10},
    #   "emergency": {"enabled": true, "fee": "500.00", "quota": 5}
    # }
    
    # Required documents
    documents = DocumentSerializer(many=True)
    
    # Today's availability
    is_available_today = serializers.BooleanField()
    availability = serializers.DictField()
    # Structure: {
    #   "available": true,
    #   "reason": "Service is open",
    #   "reason_code": "AVAILABLE",
    #   "tokens_available": 20,
    #   "tokens_booked": 5,
    #   "current_token": 3,
    #   "estimated_wait": "45 minutes"
    # }
    
    # Progress tracking
    progress_enabled = serializers.BooleanField()
    progress_steps = ProgressStepLiteSerializer(many=True)
    
    # Officials
    officials = OfficialLiteSerializer(many=True)


# =============================================================================
# PHASE 4: TOKEN BOOKING & MY TOKENS
# =============================================================================

class BookingRequestSerializer(serializers.Serializer):
    """Request body for booking a token"""
    service_id = serializers.UUIDField()
    booking_type = serializers.ChoiceField(
        choices=['REGULAR', 'PREBOOKED', 'EMERGENCY'],
        default='REGULAR'
    )
    booking_date = serializers.DateField(required=False)  # For prebook


class BookingResponseSerializer(serializers.Serializer):
    """Response after successful booking"""
    success = serializers.BooleanField()
    token = serializers.DictField()  # TokenLiteSerializer data
    message = serializers.CharField()


class TokenLiteSerializer(serializers.Serializer):
    """
    Token for citizen's "My Tokens" view.
    Target: < 800 bytes per item
    """
    id = serializers.UUIDField()
    token_number = serializers.IntegerField()
    booking_type = serializers.CharField()  # REGULAR, PREBOOKED, EMERGENCY
    status = serializers.CharField()  # WAITING, IN_SERVICE, PENDING, COMPLETED, CANCELLED
    
    # Service info (denormalized for fast access)
    service_name = serializers.CharField()
    service_logo_url = serializers.CharField(allow_null=True)
    ministry_name = serializers.CharField()
    
    # Queue position (only for WAITING status)
    queue_position = serializers.IntegerField(allow_null=True)
    estimated_time = serializers.CharField(allow_null=True)  # "10:30 AM"
    estimated_wait = serializers.CharField(allow_null=True)  # "30 minutes"
    
    # Dates
    booking_date = serializers.DateField()
    created_at = serializers.DateTimeField()
    
    # Progress (if enabled)
    progress = serializers.DictField(allow_null=True)
    # Structure: {
    #   "total_steps": 3,
    #   "completed_steps": 1,
    #   "current_step": "Seen by Chairman",
    #   "steps": [{"title": "...", "completed": true}, ...]
    # }


class TokenDetailSerializer(serializers.Serializer):
    """
    Detailed token view with full progress history.
    Used when citizen taps on a token.
    """
    id = serializers.UUIDField()
    token_number = serializers.IntegerField()
    booking_type = serializers.CharField()
    status = serializers.CharField()
    
    # Full service details
    service = serializers.DictField()
    # Structure: {
    #   "id": "...",
    #   "name": "...",
    #   "staff_name": "...",
    #   "ministry_name": "..."
    # }
    
    # Queue info
    queue_position = serializers.IntegerField(allow_null=True)
    estimated_time = serializers.CharField(allow_null=True)
    estimated_wait = serializers.CharField(allow_null=True)
    
    # For emergency tokens
    emergency_fee_paid = serializers.DecimalField(
        max_digits=10, 
        decimal_places=2,
        allow_null=True
    )
    
    # Progress tracking (full detail)
    progress = serializers.DictField(allow_null=True)
    
    # Dates
    booking_date = serializers.DateField()
    created_at = serializers.DateTimeField()
    
    # Actions available
    can_cancel = serializers.BooleanField()
    cancel_deadline = serializers.DateTimeField(allow_null=True)


# =============================================================================
# PAGINATION WRAPPER
# =============================================================================

class PaginatedResponseSerializer(serializers.Serializer):
    """
    Standard paginated response wrapper.
    Consistent structure for all list endpoints.
    """
    success = serializers.BooleanField(default=True)
    data = serializers.DictField()
    # data structure: {
    #   "items": [...],
    #   "pagination": {
    #     "next_cursor": "...",
    #     "prev_cursor": "...",
    #     "has_more": true,
    #     "total_estimate": 100
    #   }
    # }
