"""
Notices Models

Core model for government notices with file attachments.
Uses existing Ministry and Service models from ministry and services apps.
"""

import uuid
from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError


def validate_file_extension(value):
    """Validate file extension against allowed types"""
    ext = value.name.split('.')[-1].lower()
    allowed = getattr(settings, 'ALLOWED_NOTICE_EXTENSIONS', ['pdf', 'png', 'jpg', 'jpeg'])
    if ext not in allowed:
        raise ValidationError(
            f'File type "{ext}" is not allowed. Allowed types: {", ".join(allowed)}'
        )


def validate_file_size(value):
    """Validate file size against maximum allowed"""
    max_size = getattr(settings, 'MAX_UPLOAD_SIZE', 10 * 1024 * 1024)  # Default 10MB
    if value.size > max_size:
        max_mb = max_size / (1024 * 1024)
        raise ValidationError(f'File size cannot exceed {max_mb} MB')


class Notice(models.Model):
    """
    Government Notice model.
    
    - Uploaded by Ministry Admin or Staff Admin
    - Contains PDF or image file
    - Associated with ministry and optionally a service
    - Uses existing Ministry and Service models from ministry and services apps
    """
    
    class IngestionStatus(models.TextChoices):
        PENDING = 'pending', 'Pending'
        PROCESSING = 'processing', 'Processing'
        COMPLETED = 'completed', 'Completed'
        FAILED = 'failed', 'Failed'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=500)
    
    # Use existing Ministry model from ministry app
    ministry = models.ForeignKey(
        'ministry.Ministry',
        on_delete=models.CASCADE,
        related_name='notices'
    )
    # Use existing Service model from services app
    service = models.ForeignKey(
        'services.Service',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='notices'
    )
    
    # File stored via Cloudinary
    file = models.FileField(
        upload_to='notices/',
        validators=[validate_file_extension, validate_file_size],
        help_text="PDF or image file (max 10MB)"
    )
    file_type = models.CharField(max_length=10, blank=True)  # pdf, png, jpg, jpeg
    
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='uploaded_notices'
    )
    
    is_active = models.BooleanField(default=True)
    
    # RAG ingestion status
    ingestion_status = models.CharField(
        max_length=20,
        choices=IngestionStatus.choices,
        default=IngestionStatus.PENDING
    )
    ingestion_error = models.TextField(blank=True)
    ingested_at = models.DateTimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'notices_notice'
        ordering = ['-created_at']  # Latest first
        indexes = [
            models.Index(fields=['ministry', 'is_active']),
            models.Index(fields=['service', 'is_active']),
            models.Index(fields=['created_at']),
            models.Index(fields=['ingestion_status']),
            models.Index(fields=['-created_at', 'is_active']),  # For listing
        ]
    
    def __str__(self):
        return f"{self.title} ({self.ministry.slug})"
    
    def save(self, *args, **kwargs):
        # Auto-detect file type
        if self.file:
            ext = self.file.name.split('.')[-1].lower()
            self.file_type = ext
        super().save(*args, **kwargs)
    
    @property
    def file_url(self):
        """Get the URL for the file"""
        if self.file:
            return self.file.url
        return None
    
    @property
    def is_pdf(self):
        return self.file_type == 'pdf'
    
    @property
    def is_image(self):
        return self.file_type in ['png', 'jpg', 'jpeg']
