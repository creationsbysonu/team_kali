"""
RAG Bridge Models

Tracks document ingestion status for notices.
"""

import uuid
from django.db import models
from django.conf import settings


class IngestionLog(models.Model):
    """
    Log of document ingestion attempts.
    Tracks success/failure and retry attempts.
    """
    
    class Status(models.TextChoices):
        QUEUED = 'queued', 'Queued'
        SENDING = 'sending', 'Sending'
        PROCESSING = 'processing', 'Processing'
        COMPLETED = 'completed', 'Completed'
        FAILED = 'failed', 'Failed'
        RETRYING = 'retrying', 'Retrying'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    notice = models.ForeignKey(
        'notices.Notice',
        on_delete=models.CASCADE,
        related_name='ingestion_logs'
    )
    
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.QUEUED
    )
    
    # Attempt tracking
    attempt_number = models.PositiveIntegerField(default=1)
    
    # Timing
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    # Error tracking
    error_message = models.TextField(blank=True)
    error_code = models.CharField(max_length=50, blank=True)
    
    # Response from FastAPI
    fastapi_response = models.JSONField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'rag_bridge_ingestion_log'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['notice', 'status']),
            models.Index(fields=['status', 'created_at']),
        ]
    
    def __str__(self):
        return f"Ingestion {self.notice_id} - {self.status} (Attempt {self.attempt_number})"
