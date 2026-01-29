"""
Citizen Chat Models

Minimal models for chat session tracking.
No AI/ML logic - Django just proxies to FastAPI.
"""

import uuid
from django.db import models
from django.conf import settings


class ChatSession(models.Model):
    """
    Tracks citizen chat sessions.
    The actual chat intelligence is in FastAPI RAG server.
    """
    
    class Status(models.TextChoices):
        ACTIVE = 'active', 'Active'
        CLOSED = 'closed', 'Closed'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='chat_sessions'
    )
    
    status = models.CharField(
        max_length=10,
        choices=Status.choices,
        default=Status.ACTIVE
    )
    
    # Tracking
    message_count = models.PositiveIntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    last_activity = models.DateTimeField(auto_now=True)
    closed_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'citizen_chat_session'
        ordering = ['-last_activity']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['-last_activity']),
        ]
    
    def __str__(self):
        return f"Chat {self.id} - {self.user.email}"


class ChatMessage(models.Model):
    """
    Log of chat messages for audit purposes.
    Does not store AI responses in detail - just for tracking.
    """
    
    class Role(models.TextChoices):
        USER = 'user', 'User'
        ASSISTANT = 'assistant', 'Assistant'
        SYSTEM = 'system', 'System'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    session = models.ForeignKey(
        ChatSession,
        on_delete=models.CASCADE,
        related_name='messages'
    )
    
    role = models.CharField(max_length=10, choices=Role.choices)
    content = models.TextField()
    
    # For tracking only - not used for RAG
    metadata = models.JSONField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'citizen_chat_message'
        ordering = ['created_at']
        indexes = [
            models.Index(fields=['session', 'created_at']),
        ]
    
    def __str__(self):
        return f"{self.role}: {self.content[:50]}..."
