"""
Notices Serializers

Serializers for government notices.
Uses existing Ministry and Service models from their respective apps.
"""

from rest_framework import serializers
from .models import Notice
from ministry.models import Ministry
from services.models import Service


class NoticeMinistrySerializer(serializers.ModelSerializer):
    """Nested ministry serializer for notice listings"""
    logo_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Ministry
        fields = ['id', 'name', 'slug', 'logo_url']
        read_only_fields = fields
    
    def get_logo_url(self, obj):
        if obj.logo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.logo.url)
            return obj.logo.url
        return None


class NoticeServiceSerializer(serializers.ModelSerializer):
    """Nested service serializer for notice listings"""
    
    class Meta:
        model = Service
        fields = ['id', 'name', 'slug']
        read_only_fields = fields


class NoticeListSerializer(serializers.ModelSerializer):
    """
    Serializer for listing notices (citizen view).
    Includes ministry and service names for display.
    """
    
    ministry_name = serializers.CharField(source='ministry.name', read_only=True)
    ministry_slug = serializers.CharField(source='ministry.slug', read_only=True)
    service_name = serializers.CharField(source='service.name', read_only=True, default=None)
    service_slug = serializers.CharField(source='service.slug', read_only=True, default=None)
    file_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Notice
        fields = [
            'id', 'title', 
            'ministry', 'ministry_name', 'ministry_slug',
            'service', 'service_name', 'service_slug',
            'file_url', 'file_type',
            'created_at'
        ]
    
    def get_file_url(self, obj):
        """Build absolute URL for file"""
        request = self.context.get('request')
        if obj.file and request:
            return request.build_absolute_uri(obj.file.url)
        return obj.file_url


class NoticeDetailSerializer(serializers.ModelSerializer):
    """
    Detailed serializer for single notice view.
    """
    
    ministry = NoticeMinistrySerializer(read_only=True)
    service = NoticeServiceSerializer(read_only=True)
    created_by_email = serializers.CharField(source='created_by.email', read_only=True, default=None)
    file_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Notice
        fields = [
            'id', 'title',
            'ministry', 
            'service',
            'file', 'file_url', 'file_type',
            'created_by', 'created_by_email',
            'is_active',
            'ingestion_status',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'ingestion_status']
    
    def get_file_url(self, obj):
        request = self.context.get('request')
        if obj.file and request:
            return request.build_absolute_uri(obj.file.url)
        return obj.file_url


class NoticeCreateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating/uploading notices (admin only).
    """
    
    class Meta:
        model = Notice
        fields = ['title', 'ministry', 'service', 'file']
    
    def validate_service(self, value):
        """Ensure service belongs to selected ministry"""
        if value:
            ministry = self.initial_data.get('ministry')
            if ministry and str(value.ministry_id) != str(ministry):
                raise serializers.ValidationError(
                    "Service must belong to the selected ministry"
                )
        return value
    
    def validate_file(self, value):
        """Additional file validation"""
        if not value:
            raise serializers.ValidationError("File is required")
        return value
    
    def create(self, validated_data):
        """Create notice and set created_by from context"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            validated_data['created_by'] = request.user
        return super().create(validated_data)


class NoticeUpdateSerializer(serializers.ModelSerializer):
    """
    Serializer for updating notice (admin only).
    File cannot be changed after upload.
    """
    
    class Meta:
        model = Notice
        fields = ['title', 'service', 'is_active']
