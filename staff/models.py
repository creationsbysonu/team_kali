"""
Staff Models

Staff are service-level employees assigned by ministry admins.
Each staff belongs to a specific service within a ministry.

Hierarchy: Place -> Ministry -> Service -> Staff
"""
import uuid
from django.db import models
from django.conf import settings as django_settings
from django.utils import timezone

from core.storage import AvatarCloudinaryStorage


class StaffManager(models.Manager):
    """Custom manager that excludes soft-deleted staff by default"""
    
    def get_queryset(self):
        return super().get_queryset().filter(is_deleted=False)
    
    def all_with_deleted(self):
        """Include soft-deleted staff"""
        return super().get_queryset()
    
    def deleted_only(self):
        """Only soft-deleted staff"""
        return super().get_queryset().filter(is_deleted=True)
    
    def active(self):
        """Only active staff"""
        return self.get_queryset().filter(is_active=True)


class Staff(models.Model):
    """
    Staff member assigned to a specific service.
    
    Staff login with: place_slug + ministry_slug + service_slug
    They can only access applications for their assigned service.
    
    Created by: Ministry Admin
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # The user account for authentication
    user = models.OneToOneField(
        django_settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='staff_profile',
        help_text="User account for this staff member"
    )
    
    # Service assignment - staff works at ONE service
    service = models.ForeignKey(
        'services.Service',
        on_delete=models.CASCADE,
        related_name='staff',
        help_text="Service this staff is assigned to"
    )
    
    # Profile info (displayed in ministry dashboard)
    name = models.CharField(max_length=100, help_text="Staff full name")
    contact = models.CharField(max_length=20, help_text="Contact number")
    image = models.ImageField(
        upload_to=AvatarCloudinaryStorage.get_upload_path,
        storage=AvatarCloudinaryStorage(),
        null=True,
        blank=True,
        help_text="Staff profile photo (uploaded to Cloudinary /avatars folder)"
    )
    
    # Status
    is_active = models.BooleanField(
        default=True,
        help_text="Whether staff can login and access the service"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Soft delete
    is_deleted = models.BooleanField(default=False)
    deleted_at = models.DateTimeField(null=True, blank=True)
    deleted_by = models.ForeignKey(
        django_settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='deleted_staff'
    )
    
    # Custom managers
    objects = StaffManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = 'Staff'
        verbose_name_plural = 'Staff'
        ordering = ['name']
        indexes = [
            models.Index(fields=['service']),
            models.Index(fields=['user']),
            models.Index(fields=['is_active']),
            models.Index(fields=['is_deleted']),
        ]
    
    def __str__(self):
        return f"{self.name} - {self.service.name}"
    
    @property
    def ministry(self):
        """Get the ministry this staff belongs to"""
        return self.service.ministry
    
    @property
    def place(self):
        """Get the place this staff belongs to"""
        return self.service.ministry.place
    
    @property
    def email(self):
        """Get staff email from user account"""
        return self.user.email
    
    def soft_delete(self, deleted_by=None):
        """Soft delete the staff"""
        self.is_deleted = True
        self.is_active = False
        self.deleted_at = timezone.now()
        self.deleted_by = deleted_by
        self.save(update_fields=['is_deleted', 'is_active', 'deleted_at', 'deleted_by', 'updated_at'])
        
        # Also deactivate the user account
        self.user.is_active = False
        self.user.save(update_fields=['is_active'])
    
    def restore(self):
        """Restore a soft-deleted staff"""
        self.is_deleted = False
        self.is_active = True
        self.deleted_at = None
        self.deleted_by = None
        self.save(update_fields=['is_deleted', 'is_active', 'deleted_at', 'deleted_by', 'updated_at'])
        
        # Also reactivate the user account
        self.user.is_active = True
        self.user.save(update_fields=['is_active'])
