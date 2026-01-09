"""
Staff Serializers

Serializers for staff listing and creation.
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model

from .models import Staff

CustomUser = get_user_model()


class StaffPublicSerializer(serializers.ModelSerializer):
    """
    Public serializer for staff listing.
    Shows only basic info: image, name, contact.
    """
    image_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Staff
        fields = ['id', 'name', 'contact', 'image_url']
        read_only_fields = fields
    
    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return None


class StaffDetailSerializer(serializers.ModelSerializer):
    """
    Detailed serializer for ministry admin view.
    Shows all staff info including email.
    """
    email = serializers.CharField(source='user.email', read_only=True)
    image_url = serializers.SerializerMethodField()
    service_name = serializers.CharField(source='service.name', read_only=True)
    ministry_name = serializers.CharField(source='service.ministry.name', read_only=True)
    
    class Meta:
        model = Staff
        fields = [
            'id', 'name', 'email', 'contact', 
            'image', 'image_url',
            'service', 'service_name', 'ministry_name',
            'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'email', 'created_at', 'updated_at']
    
    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return None


class StaffCreateSerializer(serializers.Serializer):
    """
    Serializer for creating new staff.
    Creates both user account and staff profile.
    """
    name = serializers.CharField(max_length=100)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=8)
    contact = serializers.CharField(max_length=20)
    service_id = serializers.UUIDField()
    image = serializers.ImageField(required=False, allow_null=True)
    
    def validate_email(self, value):
        if CustomUser.objects.filter(email=value.lower()).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value.lower()
    
    def validate_service_id(self, value):
        from services.models import Service
        if not Service.objects.filter(id=value, is_active=True).exists():
            raise serializers.ValidationError("Service not found or inactive.")
        return value


class StaffUpdateSerializer(serializers.Serializer):
    """Serializer for updating staff"""
    name = serializers.CharField(max_length=100, required=False)
    contact = serializers.CharField(max_length=20, required=False)
    image = serializers.ImageField(required=False, allow_null=True)
    is_active = serializers.BooleanField(required=False)
    password = serializers.CharField(write_only=True, min_length=8, required=False)
