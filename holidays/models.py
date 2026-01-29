"""
Universal Holiday Models

Defines days when offices are CLOSED.
All holidays apply universally to everyone (staff + officials + ministries).
Holiday OVERRIDES attendance.
"""
import uuid
from django.db import models
from django.core.exceptions import ValidationError
from django.utils import timezone
import pytz

NEPAL_TZ = pytz.timezone('Asia/Kathmandu')


class Holiday(models.Model):
    """
    Universal holiday (applies to all ministries, staff, and officials).
    
    Rules:
    - All holidays apply universally
    - Cannot modify past or same-day holidays
    - Holiday overrides attendance (even if marked PRESENT)
    - Only future holidays can be created/modified
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Holiday details
    name = models.CharField(
        max_length=200,
        help_text="Name of the holiday (e.g., Dashain, Tihar, New Year)"
    )
    
    date = models.DateField(
        unique=True,
        help_text="Date of the holiday"
    )
    
    description = models.TextField(
        blank=True,
        default='',
        help_text="Optional description of the holiday"
    )
    
    # Audit fields
    created_by = models.ForeignKey(
        'authentication.CustomUser',
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_holidays',
        help_text="User who created this holiday"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Holiday'
        verbose_name_plural = 'Holidays'
        ordering = ['date']
        indexes = [
            models.Index(fields=['date']),
        ]
    
    def __str__(self):
        return f"{self.name} - {self.date}"
    
    def clean(self):
        """Validate holiday rules"""
        super().clean()
        
        if not self.date:
            return
        
        # Get today's date in Nepal timezone
        nepal_now = timezone.now().astimezone(NEPAL_TZ)
        today = nepal_now.date()
        
        # Rule: Cannot create/modify past or same-day holidays
        if self.date <= today:
            raise ValidationError({
                'date': 'Cannot create or modify holidays for past or current date. Only future dates allowed.'
            })
    
    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)
    
    @staticmethod
    def is_holiday(date):
        """
        Check if a given date is a holiday.
        
        Args:
            date: date object
            
        Returns:
            tuple: (is_holiday: bool, holiday_name: str or None)
        """
        holiday = Holiday.objects.filter(date=date).first()
        
        if holiday:
            return True, holiday.name
        
        return False, None
