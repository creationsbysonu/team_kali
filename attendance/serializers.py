"""
Serializers for Unified Attendance Management (Staff + Officials).
"""

from rest_framework import serializers
from .models import AttendanceRecord
from ministry.models import StaffService
from officials.models import MinistryOfficial
from authentication.models import CustomUser


class AttendanceRecordSerializer(serializers.ModelSerializer):
    """Serializer for viewing attendance records (staff + officials)."""
    
    person_name = serializers.SerializerMethodField()
    person_email = serializers.SerializerMethodField()
    marked_by_email = serializers.SerializerMethodField()
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    person_type_display = serializers.CharField(source='get_person_type_display', read_only=True)
    is_saturday = serializers.SerializerMethodField()
    
    class Meta:
        model = AttendanceRecord
        fields = [
            'id',
            'date',
            'person_type',
            'person_type_display',
            'staff',
            'official',
            'person_name',
            'person_email',
            'status',
            'status_display',
            'is_saturday',
            'marked_by',
            'marked_by_email',
            'reason',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_person_name(self, obj):
        """Get person name based on type."""
        if obj.person_type == AttendanceRecord.PersonType.STAFF:
            return obj.staff.staff_name if obj.staff else None
        return obj.official.name if obj.official else None
    
    def get_person_email(self, obj):
        """Get person email based on type."""
        if obj.person_type == AttendanceRecord.PersonType.STAFF:
            return obj.staff.email if obj.staff else None
        return obj.official.ministry.email if obj.official else None
    
    def get_marked_by_email(self, obj):
        """Get the email of the user who marked attendance."""
        return obj.marked_by.email if obj.marked_by else None
    
    def get_is_saturday(self, obj):
        """Check if the attendance date is Saturday."""
        return obj.date.weekday() == 5  # 5 = Saturday


class AttendanceRecordCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating attendance records."""
    
    class Meta:
        model = AttendanceRecord
        fields = [
            'date',
            'person_type',
            'staff',
            'official',
            'status',
            'reason',
        ]
    
    def validate_date(self, value):
        """Validate that date is today or in the future."""
        from core.utils.nepal_time import get_nepal_today
        
        today = get_nepal_today()
        if value < today:
            raise serializers.ValidationError(
                "Attendance can only be marked for today or future dates."
            )
        
        return value
    
    def validate(self, attrs):
        """Cross-field validation."""
        date_value = attrs.get('date')
        status = attrs.get('status')
        person_type = attrs.get('person_type')
        staff = attrs.get('staff')
        official = attrs.get('official')
        
        # Check if Saturday
        if date_value and date_value.weekday() == 5:  # Saturday
            if status == AttendanceRecord.Status.PRESENT:
                raise serializers.ValidationError({
                    "status": "Saturday is a weekly holiday in Nepal. Status must be ABSENT."
                })
        
        # Validate person_type matches FK
        if person_type == AttendanceRecord.PersonType.STAFF:
            if not staff:
                raise serializers.ValidationError({
                    "staff": "Staff must be specified when person_type is STAFF."
                })
            if official:
                raise serializers.ValidationError({
                    "official": "Official should be null when person_type is STAFF."
                })
            if not staff.is_active:
                raise serializers.ValidationError({
                    "staff": "Cannot mark attendance for inactive staff."
                })
        elif person_type == AttendanceRecord.PersonType.OFFICIAL:
            if not official:
                raise serializers.ValidationError({
                    "official": "Official must be specified when person_type is OFFICIAL."
                })
            if staff:
                raise serializers.ValidationError({
                    "staff": "Staff should be null when person_type is OFFICIAL."
                })
            if not official.is_active:
                raise serializers.ValidationError({
                    "official": "Cannot mark attendance for inactive official."
                })
        
        return attrs
    
    def create(self, validated_data):
        """Create attendance record with marked_by from context."""
        request = self.context.get('request')
        if request and hasattr(request, 'user'):
            validated_data['marked_by'] = request.user
        
        return super().create(validated_data)
    
    def update(self, instance, validated_data):
        """Update attendance record (only status and reason can be updated)."""
        # marked_by should reflect the last person who updated
        request = self.context.get('request')
        if request and hasattr(request, 'user'):
            validated_data['marked_by'] = request.user
        
        return super().update(instance, validated_data)


class AttendanceRecordBulkCreateSerializer(serializers.Serializer):
    """Serializer for bulk creating attendance records (e.g., for a week or month)."""
    
    person_type = serializers.ChoiceField(choices=AttendanceRecord.PersonType.choices)
    staff = serializers.PrimaryKeyRelatedField(
        queryset=StaffService.objects.filter(is_active=True),
        required=False,
        allow_null=True
    )
    official = serializers.PrimaryKeyRelatedField(
        queryset=MinistryOfficial.objects.filter(is_active=True),
        required=False,
        allow_null=True
    )
    start_date = serializers.DateField()
    end_date = serializers.DateField()
    status = serializers.ChoiceField(choices=AttendanceRecord.Status.choices)
    reason = serializers.CharField(required=False, allow_blank=True)
    
    def validate(self, attrs):
        """Validate date range and prevent past dates."""
        from core.utils.nepal_time import get_nepal_today
        
        start_date = attrs.get('start_date')
        end_date = attrs.get('end_date')
        person_type = attrs.get('person_type')
        staff = attrs.get('staff')
        official = attrs.get('official')
        
        today = get_nepal_today()
        
        if start_date <= today:
            raise serializers.ValidationError({
                "start_date": "Start date must be in the future."
            })
        
        if end_date < start_date:
            raise serializers.ValidationError({
                "end_date": "End date must be after start date."
            })
        
        # Limit to prevent abuse
        date_diff = (end_date - start_date).days
        if date_diff > 90:  # 3 months max
            raise serializers.ValidationError(
                "Date range cannot exceed 90 days."
            )
        
        # Validate person_type matches FK
        if person_type == AttendanceRecord.PersonType.STAFF:
            if not staff:
                raise serializers.ValidationError({
                    "staff": "Staff must be specified when person_type is STAFF."
                })
            if official:
                raise serializers.ValidationError({
                    "official": "Official should be null when person_type is STAFF."
                })
        elif person_type == AttendanceRecord.PersonType.OFFICIAL:
            if not official:
                raise serializers.ValidationError({
                    "official": "Official must be specified when person_type is OFFICIAL."
                })
            if staff:
                raise serializers.ValidationError({
                    "staff": "Staff should be null when person_type is OFFICIAL."
                })
        
        return attrs
    
    def create(self, validated_data):
        """Create multiple attendance records for the date range."""
        from datetime import timedelta
        from core.utils.nepal_time import is_saturday
        
        person_type = validated_data['person_type']
        staff = validated_data.get('staff')
        official = validated_data.get('official')
        start_date = validated_data['start_date']
        end_date = validated_data['end_date']
        status = validated_data['status']
        reason = validated_data.get('reason', '')
        
        request = self.context.get('request')
        marked_by = request.user if request and hasattr(request, 'user') else None
        
        attendance_records = []
        current_date = start_date
        
        while current_date <= end_date:
            # Build filter kwargs based on person type
            filter_kwargs = {'date': current_date, 'person_type': person_type}
            if person_type == AttendanceRecord.PersonType.STAFF:
                filter_kwargs['staff'] = staff
            else:
                filter_kwargs['official'] = official
            
            # Skip if already exists
            if not AttendanceRecord.objects.filter(**filter_kwargs).exists():
                
                # Auto-set to ABSENT for Saturdays
                final_status = AttendanceRecord.Status.ABSENT if is_saturday(current_date) else status
                
                attendance_records.append(
                    AttendanceRecord(
                        date=current_date,
                        person_type=person_type,
                        staff=staff,
                        official=official,
                        status=final_status,
                        reason=reason,
                        marked_by=marked_by,
                    )
                )
            
            current_date += timedelta(days=1)
        
        # Bulk create
        created = AttendanceRecord.objects.bulk_create(attendance_records)
        
        return {
            'created_count': len(created),
            'person_type': person_type,
            'staff': staff.id if staff else None,
            'official': official.id if official else None,
            'start_date': start_date,
            'end_date': end_date,
        }


class AttendanceRecordCalendarSerializer(serializers.Serializer):
    """Serializer for calendar view of attendance."""
    
    date = serializers.DateField()
    status = serializers.CharField()
    status_display = serializers.CharField()
    is_saturday = serializers.BooleanField()
    is_holiday = serializers.BooleanField()
    holiday_name = serializers.CharField(allow_null=True)
    reason = serializers.CharField(allow_blank=True)
