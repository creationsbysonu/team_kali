"""
Citizen Profile Model for Mobile App

Stores additional profile information for citizens after OTP authentication.
This includes their name and selected place for personalized service access.
"""
import uuid
from django.db import models
from django.conf import settings
from places.models import Place


class CitizenProfile(models.Model):
    """
    Extended profile information for citizens using the mobile app.
    
    Flow:
    1. User signs up via OTP (CustomUser created)
    2. User must complete profile (name + place selection)
    3. Profile completion required before accessing main app features
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Link to authentication user
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='citizen_profile',
        limit_choices_to={'user_type': 'citizen'}
    )
    
    # Personal Information
    full_name = models.CharField(
        max_length=100,
        help_text="Citizen's full name"
    )
    
    # Location Selection
    place = models.ForeignKey(
        Place,
        on_delete=models.PROTECT,
        related_name='citizens',
        help_text="Selected place for service access"
    )
    
    # Profile Status
    is_profile_complete = models.BooleanField(
        default=False,
        help_text="Whether profile setup is completed"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user']),
            models.Index(fields=['place']),
            models.Index(fields=['is_profile_complete']),
        ]
        verbose_name = 'Citizen Profile'
        verbose_name_plural = 'Citizen Profiles'
    
    def __str__(self):
        return f"{self.full_name} - {self.place.name}"
    
    def save(self, *args, **kwargs):
        # Auto-mark profile as complete when name and place are set
        if self.full_name and self.place_id:
            self.is_profile_complete = True
        super().save(*args, **kwargs)
