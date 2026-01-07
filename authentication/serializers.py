from rest_framework import serializers
from .models import CustomUser


class UserSerializer(serializers.ModelSerializer):
    """Simple user serializer - just email and type"""
    
    class Meta:
        model = CustomUser
        fields = ['id', 'email', 'user_type', 'is_verified', 'created_at']
        read_only_fields = ['id', 'email', 'user_type', 'is_verified', 'created_at']


class OTPRequestSerializer(serializers.Serializer):
    """Serializer for OTP request - just email"""
    email = serializers.EmailField(required=True)
    
    def validate_email(self, value):
        return value.lower().strip()


class OTPVerifySerializer(serializers.Serializer):
    """Serializer for OTP verification - email + otp"""
    email = serializers.EmailField(required=True)
    otp = serializers.CharField(required=True, min_length=6, max_length=6)
    
    def validate_email(self, value):
        return value.lower().strip()
    
    def validate_otp(self, value):
        if not value.isdigit():
            raise serializers.ValidationError("OTP must contain only digits")
        return value.strip()


class TokenResponseSerializer(serializers.Serializer):
    """Serializer for token response"""
    access_token = serializers.CharField()
    refresh_token = serializers.CharField(required=False)
    token_type = serializers.CharField(default='Bearer')
    expires_in = serializers.IntegerField()


class AuthResponseSerializer(serializers.Serializer):
    """Serializer for authentication response"""
    user = UserSerializer()
    tokens = TokenResponseSerializer()
    is_new_user = serializers.BooleanField(default=False)