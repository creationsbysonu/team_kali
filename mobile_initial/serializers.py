"""
Serializers for Mobile Profile Setup
"""
from rest_framework import serializers
from .models import CitizenProfile
from places.models import Place


class PlaceListSerializer(serializers.ModelSerializer):
    """Serializer for place selection list"""
    
    class Meta:
        model = Place
        fields = ['id', 'name', 'slug']
        read_only_fields = ['id', 'name', 'slug']


class CitizenProfileSerializer(serializers.ModelSerializer):
    """Serializer for citizen profile"""
    
    place_details = PlaceListSerializer(source='place', read_only=True)
    user_email = serializers.EmailField(source='user.email', read_only=True)
    
    class Meta:
        model = CitizenProfile
        fields = [
            'id',
            'user_email',
            'full_name',
            'place',
            'place_details',
            'is_profile_complete',
            'created_at',
            'updated_at'
        ]
        read_only_fields = ['id', 'is_profile_complete', 'created_at', 'updated_at']
    
    def validate_full_name(self, value):
        """Validate full name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Full name cannot be empty")
        
        if len(value.strip()) < 2:
            raise serializers.ValidationError("Full name must be at least 2 characters")
        
        return value.strip()
    
    def validate_place(self, value):
        """Validate place exists and is active"""
        if not value.is_active:
            raise serializers.ValidationError("Selected place is not active")
        return value


class ProfileSetupSerializer(serializers.Serializer):
    """Serializer for initial profile setup"""
    
    full_name = serializers.CharField(max_length=100, required=True)
    place_id = serializers.UUIDField(required=True)
    
    def validate_full_name(self, value):
        """Validate full name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Full name is required")
        
        if len(value.strip()) < 2:
            raise serializers.ValidationError("Full name must be at least 2 characters")
        
        return value.strip()
    
    def validate_place_id(self, value):
        """Validate place exists and is active"""
        try:
            place = Place.objects.get(id=value, is_active=True)
        except Place.DoesNotExist:
            raise serializers.ValidationError("Selected place not found or inactive")
        
        return value


class ProfileStatusSerializer(serializers.Serializer):
    """Serializer for profile completion status"""
    
    is_profile_complete = serializers.BooleanField()
    profile_data = CitizenProfileSerializer(required=False, allow_null=True)
