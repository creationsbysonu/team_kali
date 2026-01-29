"""
Notification Models

In-app notifications for citizens and staff.

Triggers:
- Token booked
- Token served
- Token pushed back (no-show)
- Token cancelled
- Queue unavailable (holiday/absence)
"""
import uuid
from django.db import models


class Notification(models.Model):
    """
    In-app notification.
    
    Delivery:
    - In-app mandatory
    - SMS/email optional (future)
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Recipient
    user = models.ForeignKey(
        'authentication.CustomUser',
        on_delete=models.CASCADE,
        related_name='notifications',
        help_text="Recipient of notification"
    )
    
    # Notification content
    title = models.CharField(
        max_length=200,
        help_text="Notification title"
    )
    
    message = models.TextField(
        help_text="Notification message"
    )
    
    # Related entities (optional)
    queue_token = models.ForeignKey(
        'queue_management.QueueToken',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='notifications',
        help_text="Related queue token"
    )
    
    # Status
    read = models.BooleanField(
        default=False,
        help_text="Whether notification has been read"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'Notification'
        verbose_name_plural = 'Notifications'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'read']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.title} - {self.user.email}"
