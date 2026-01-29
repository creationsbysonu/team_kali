"""
Ministry Officials Models

Officials represent higher-level ministry roles (chairperson, secretary, etc.)
that may be required for service progress tracking.

Each ministry can define its own officials dynamically.
"""
import uuid
from django.db import models


class MinistryOfficial(models.Model):
    """
    Ministry Official - Higher officials like Chairperson, Secretary, etc.
    
    Purpose:
    - Allow each ministry to define its own officials
    - Used in progress tracking steps
    - Attendance tracking for officials
    
    Rules:
    - Officials are ministry-specific
    - No images
    - No hierarchy enforced by backend
    - Order handled in progress steps
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Ministry relationship
    ministry = models.ForeignKey(
        'ministry.Ministry',
        on_delete=models.CASCADE,
        related_name='officials',
        help_text="Ministry this official belongs to"
    )
    
    # Official details
    name = models.CharField(
        max_length=255,
        help_text="Full name of the official"
    )
    
    role = models.CharField(
        max_length=100,
        help_text="Role/designation (e.g., Chairperson, Secretary, President)"
    )
    
    # Status
    is_active = models.BooleanField(
        default=True,
        help_text="Whether this official is currently active"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Ministry Official'
        verbose_name_plural = 'Ministry Officials'
        ordering = ['ministry', 'name']
        indexes = [
            models.Index(fields=['ministry', 'is_active']),
            models.Index(fields=['is_active']),
        ]
        # Allow same name/role across different ministries
        unique_together = [['ministry', 'name', 'role']]
    
    def __str__(self):
        return f"{self.name} ({self.role}) - {self.ministry.name}"
