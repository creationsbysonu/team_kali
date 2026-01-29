"""
Serializers for Universal Holiday Management.
"""

from rest_framework import serializers
from .models import Holiday


class HolidaySerializer(serializers.ModelSerializer):
    """Serializer for viewing holiday records."""
    
    created_by_email = serializers.SerializerMethodField()
    
    class Meta:
        model = Holiday
        fields = [
            'id',
            'name',
            'date',
            'description',
            'created_by',
            'created_by_email',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_created_by_email(self, obj):
        """Get the email of the user who created the holiday."""
        return obj.created_by.email if obj.created_by else None


class HolidayCreateSerializer(serializers.Serializer):
    """Serializer for creating holiday records (validation only)."""
    
    name = serializers.CharField(max_length=200)
    date = serializers.DateField()
    description = serializers.CharField(required=False, allow_blank=True, default='')
    
    def validate_date(self, value):
        """Validate that date is in the future."""
        from core.utils.nepal_time import get_nepal_today
        
        today = get_nepal_today()
        if value <= today:
            raise serializers.ValidationError(
                "Holidays can only be created for future dates."
            )
        
        return value


class HolidayUpdateSerializer(serializers.Serializer):
    """Serializer for updating holiday records (validation only - only name and description can be updated)."""
    
    name = serializers.CharField(max_length=200, required=False)
    description = serializers.CharField(required=False, allow_blank=True)


class HolidayListQuerySerializer(serializers.Serializer):
    """Serializer for filtering holiday list."""
    
    year = serializers.IntegerField(required=False)
    month = serializers.IntegerField(required=False, min_value=1, max_value=12)
    start_date = serializers.DateField(required=False)
    end_date = serializers.DateField(required=False)
    
    def validate(self, attrs):
        """Validate query parameters."""
        year = attrs.get('year')
        month = attrs.get('month')
        
        if month and not year:
            raise serializers.ValidationError({
                "year": "Year is required when filtering by month."
            })
        
        return attrs


class HolidayCalendarSerializer(serializers.Serializer):
    """Serializer for calendar view of holidays."""
    
    date = serializers.DateField()
    holidays = serializers.ListField(
        child=serializers.DictField(),
        help_text="List of holidays on this date"
    )
