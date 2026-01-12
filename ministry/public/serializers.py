"""
Staff Service Serializers for Public API

Serializers for displaying StaffService (ministry-created services) to public.
"""
from rest_framework import serializers
from ministry.models import StaffService


class StaffServicePublicListSerializer(serializers.ModelSerializer):
    """
    Public serializer for staff service listing.
    Shows service info with staff details and ministry branding.
    """
    service_logo_url = serializers.SerializerMethodField()
    staff_image_url = serializers.SerializerMethodField()
    ministry_name = serializers.CharField(source='ministry.name', read_only=True)
    ministry_slug = serializers.CharField(source='ministry.slug', read_only=True)
    ministry_logo_url = serializers.SerializerMethodField()
    
    class Meta:
        model = StaffService
        fields = [
            'id',
            'service_name',
            'service_logo_url',
            'staff_name',
            'staff_image_url',
            'status',
            'ministry_name',
            'ministry_slug',
            'ministry_logo_url',
        ]
        read_only_fields = fields
    
    def get_service_logo_url(self, obj):
        """Build absolute URL for service logo"""
        if obj.service_logo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.service_logo.url)
            return obj.service_logo.url
        return None
    
    def get_staff_image_url(self, obj):
        """Build absolute URL for staff image"""
        if obj.staff_image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.staff_image.url)
            return obj.staff_image.url
        return None
    
    def get_ministry_logo_url(self, obj):
        """Build absolute URL for ministry logo"""
        if obj.ministry and obj.ministry.logo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.ministry.logo.url)
            return obj.ministry.logo.url
        return None
