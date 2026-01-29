"""
Serializers for In-App Notifications System.
"""

from rest_framework import serializers
from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    """Serializer for viewing notifications."""
    
    user_email = serializers.SerializerMethodField()
    token_number = serializers.SerializerMethodField()
    time_ago = serializers.SerializerMethodField()
    
    class Meta:
        model = Notification
        fields = [
            'id',
            'user',
            'user_email',
            'title',
            'message',
            'queue_token',
            'token_number',
            'read',
            'created_at',
            'time_ago',
        ]
        read_only_fields = ['id', 'user', 'created_at']
    
    def get_user_email(self, obj):
        """Get user email."""
        return obj.user.email if obj.user else None
    
    def get_token_number(self, obj):
        """Get token number if notification is related to a token."""
        return obj.queue_token.token_number if obj.queue_token else None
    
    def get_time_ago(self, obj):
        """Get human-readable time ago."""
        from django.utils import timezone
        from datetime import timedelta
        
        now = timezone.now()
        diff = now - obj.created_at
        
        if diff < timedelta(minutes=1):
            return "just now"
        elif diff < timedelta(hours=1):
            minutes = int(diff.total_seconds() / 60)
            return f"{minutes} minute{'s' if minutes > 1 else ''} ago"
        elif diff < timedelta(days=1):
            hours = int(diff.total_seconds() / 3600)
            return f"{hours} hour{'s' if hours > 1 else ''} ago"
        elif diff < timedelta(days=7):
            days = diff.days
            return f"{days} day{'s' if days > 1 else ''} ago"
        elif diff < timedelta(days=30):
            weeks = diff.days // 7
            return f"{weeks} week{'s' if weeks > 1 else ''} ago"
        else:
            months = diff.days // 30
            return f"{months} month{'s' if months > 1 else ''} ago"


class NotificationCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating notifications (used internally by services)."""
    
    class Meta:
        model = Notification
        fields = [
            'user',
            'title',
            'message',
            'queue_token',
        ]
    
    def validate_user(self, value):
        """Validate that user is active."""
        if not value.is_active:
            raise serializers.ValidationError("Cannot send notification to inactive user.")
        
        return value


class NotificationMarkReadSerializer(serializers.Serializer):
    """Serializer for marking notifications as read."""
    
    notification_ids = serializers.ListField(
        child=serializers.UUIDField(),
        allow_empty=False,
        help_text="List of notification IDs to mark as read"
    )
    
    def validate_notification_ids(self, value):
        """Validate that all notification IDs exist and belong to the user."""
        request = self.context.get('request')
        if not request or not hasattr(request, 'user'):
            raise serializers.ValidationError("Request context with user required.")
        
        user = request.user
        
        # Check that all notifications exist and belong to user
        notifications = Notification.objects.filter(id__in=value, user=user)
        
        if notifications.count() != len(value):
            raise serializers.ValidationError(
                "Some notification IDs are invalid or do not belong to you."
            )
        
        return value


class NotificationStatsSerializer(serializers.Serializer):
    """Serializer for notification statistics."""
    
    total_count = serializers.IntegerField()
    unread_count = serializers.IntegerField()
    read_count = serializers.IntegerField()
    latest_notification = NotificationSerializer(required=False, allow_null=True)
