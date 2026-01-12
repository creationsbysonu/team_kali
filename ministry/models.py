"""
Ministry Models

Ministries represent government ministries/departments.
Each ministry has its own dashboard and data isolation.
"""
import uuid
from django.db import models
from django.conf import settings as django_settings
from django.utils.text import slugify
from django.utils import timezone
from django.contrib.auth.hashers import make_password, check_password

from core.storage import LogoCloudinaryStorage


class MinistryManager(models.Manager):
    """Custom manager that excludes soft-deleted ministries by default"""
    
    def get_queryset(self):
        return super().get_queryset().filter(is_deleted=False)
    
    def all_with_deleted(self):
        """Include soft-deleted ministries"""
        return super().get_queryset()
    
    def deleted_only(self):
        """Only soft-deleted ministries"""
        return super().get_queryset().filter(is_deleted=True)


class Ministry(models.Model):
    """
    Government Ministry/Department
    
    Each ministry is isolated with its own data.
    Ministries belong to a Place (decentralized location).
    Super admin creates places first, then ministries within each place.
    
    Hierarchy: Place -> Ministry -> Services -> Staff
    """
    
    class Status(models.TextChoices):
        ACTIVE = 'active', 'Active'
        SUSPENDED = 'suspended', 'Suspended'
        PENDING = 'pending', 'Pending Approval'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Parent Place - Ministry belongs to a Place
    place = models.ForeignKey(
        'places.Place',
        on_delete=models.CASCADE,
        related_name='ministries',
        null=True,
        blank=True,
        help_text="Place/Location this ministry belongs to"
    )
    
    # Basic Info
    name = models.CharField(max_length=255, help_text="Ministry/Department name")
    slug = models.SlugField(max_length=100, blank=True, help_text="URL-friendly identifier (auto-generated from name)")
    description = models.TextField(blank=True, help_text="Ministry description")
    
    # Contact Info & Authentication
    email = models.EmailField(unique=True, help_text="Official contact email (used for login)")
    password = models.CharField(max_length=128, null=True, blank=True, help_text="Hashed password for ministry login")
    phone = models.CharField(max_length=20, blank=True)
    address = models.TextField(blank=True)
    website = models.URLField(blank=True)
    
    # Branding
    logo = models.ImageField(
        upload_to=LogoCloudinaryStorage.get_upload_path,
        storage=LogoCloudinaryStorage(),
        null=True,
        blank=True,
        help_text="Ministry logo (uploaded to Cloudinary /logos folder)"
    )
    
    # Status
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING
    )
    
    # Settings (JSON for flexibility)
    settings = models.JSONField(
        default=dict,
        blank=True,
        help_text="Ministry-specific configuration"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Soft Delete
    is_deleted = models.BooleanField(
        default=False,
        help_text="Soft deleted - data remains but ministry is inaccessible"
    )
    deleted_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When the ministry was soft deleted"
    )
    deleted_by = models.ForeignKey(
        django_settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='deleted_ministries',
        help_text="Super admin who deleted the ministry"
    )
    
    # Custom managers
    objects = MinistryManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = 'Ministry'
        verbose_name_plural = 'Ministries'
        ordering = ['place', 'name']
        unique_together = ['place', 'slug']
        indexes = [
            models.Index(fields=['place', 'slug']),
            models.Index(fields=['place', 'status']),
            models.Index(fields=['status']),
            models.Index(fields=['created_at']),
            models.Index(fields=['is_deleted']),
        ]
    
    def __str__(self):
        return self.name
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)
    
    def soft_delete(self, deleted_by=None):
        """Soft delete the ministry"""
        self.is_deleted = True
        self.deleted_at = timezone.now()
        self.deleted_by = deleted_by
        self.status = self.Status.SUSPENDED
        self.save(update_fields=['is_deleted', 'deleted_at', 'deleted_by', 'status', 'updated_at'])
    
    def restore(self):
        """Restore a soft-deleted ministry"""
        self.is_deleted = False
        self.deleted_at = None
        self.deleted_by = None
        self.status = self.Status.ACTIVE
        self.save(update_fields=['is_deleted', 'deleted_at', 'deleted_by', 'status', 'updated_at'])
    
    @property
    def is_active(self):
        return self.status == self.Status.ACTIVE and not self.is_deleted
    
    def set_password(self, raw_password):
        """Hash and set the password for ministry login"""
        self.password = make_password(raw_password)
    
    def check_password(self, raw_password):
        """Verify the password for ministry login"""
        if not self.password:
            return False
        return check_password(raw_password, self.password)



class StaffService(models.Model):
    """
    Staff Service - Staff Login Account with Service Control
    
    Managed by Ministry Admin. Staff use these accounts to login.
    Ministry can control service availability (e.g., pause when staff is absent).
    
    Future-proof design for attendance system integration:
    - When staff marks absent → Ministry can pause service → Citizens see service unavailable
    - Service status controls citizen-facing availability
    - is_active provides system-level enable/disable
    
    Hierarchy: Place -> Ministry -> StaffService (staff login account + service control)
    """
    
    class Status(models.TextChoices):
        ACTIVE = 'active', 'Active'
        PAUSED = 'paused', 'Paused'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Parent Ministry - StaffService belongs to a Ministry
    ministry = models.ForeignKey(
        Ministry,
        on_delete=models.CASCADE,
        related_name='staff_services',
        help_text="Ministry this staff service belongs to"
    )
    
    # Service Information
    service_name = models.CharField(
        max_length=255,
        help_text="Name of the service (e.g., IT Support, Birth Certificate)"
    )
    service_logo = models.ImageField(
        upload_to=LogoCloudinaryStorage.get_upload_path,
        storage=LogoCloudinaryStorage(),
        null=True,
        blank=True,
        help_text="Service logo (uploaded to Cloudinary /logos folder)"
    )
    
    # Staff Information
    staff_name = models.CharField(
        max_length=255,
        help_text="Full name of the staff member handling this service"
    )
    staff_image = models.ImageField(
        upload_to=LogoCloudinaryStorage.get_upload_path,
        storage=LogoCloudinaryStorage(),
        null=True,
        blank=True,
        help_text="Staff profile photo (uploaded to Cloudinary /logos folder)"
    )
    
    # Authentication
    email = models.EmailField(
        unique=True,
        help_text="Staff login email"
    )
    password = models.CharField(
        max_length=128,
        help_text="Hashed password for staff login"
    )
    
    # Status Control (Ministry-controlled)
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.ACTIVE,
        help_text="Service availability status - Ministry can pause when staff is absent"
    )
    
    # System-level Control
    is_active = models.BooleanField(
        default=True,
        help_text="System-level enable/disable for this staff service account"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Staff Service'
        verbose_name_plural = 'Staff Services'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['ministry', 'status', 'is_active']),
            models.Index(fields=['email']),
            models.Index(fields=['status']),
            models.Index(fields=['is_active']),
        ]
    
    def __str__(self):
        return f"{self.service_name} - {self.staff_name} ({self.ministry.name})"
    
    def set_password(self, raw_password):
        """Hash and set the password for staff login"""
        self.password = make_password(raw_password)
    
    def check_password(self, raw_password):
        """Verify the password for staff login"""
        if not self.password:
            return False
        return check_password(raw_password, self.password)
    
    def pause_service(self):
        """Pause service (e.g., when staff is absent)"""
        self.status = self.Status.PAUSED
        self.save(update_fields=['status'])
    
    def activate_service(self):
        """Activate service (e.g., when staff is present)"""
        self.status = self.Status.ACTIVE
        self.save(update_fields=['status'])
    
    @property
    def is_available(self):
        """Check if service is available for citizens"""
        return self.status == self.Status.ACTIVE and self.is_active
    
    @property
    def place(self):
        """Get the place this staff service belongs to"""
        return self.ministry.place


class MinistryMember(models.Model):
    """
    Ministry Admin membership
    
    Links ONE admin user to ONE ministry.
    Each ministry has exactly ONE admin who can manage it.
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    ministry = models.ForeignKey(
        Ministry,
        on_delete=models.CASCADE,
        related_name='members'
    )
    user = models.ForeignKey(
        'authentication.CustomUser',
        on_delete=models.CASCADE,
        related_name='ministry_memberships'
    )
    
    # Status
    is_active = models.BooleanField(default=True)
    
    # Timestamps
    joined_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Ministry Admin'
        verbose_name_plural = 'Ministry Admins'
        unique_together = ['ministry', 'user']
        indexes = [
            models.Index(fields=['ministry']),
            models.Index(fields=['user', 'is_active']),
        ]
    
    def __str__(self):
        return f"{self.user.email} - {self.ministry.name}"


class MinistryInvitation(models.Model):
    """
    Invitation to join a ministry
    
    Used to invite staff members to ministry dashboard.
    """
    
    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        ACCEPTED = 'accepted', 'Accepted'
        EXPIRED = 'expired', 'Expired'
        CANCELLED = 'cancelled', 'Cancelled'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    ministry = models.ForeignKey(
        Ministry,
        on_delete=models.CASCADE,
        related_name='invitations'
    )
    
    email = models.EmailField(help_text="Email to invite")
    
    invited_by = models.ForeignKey(
        'authentication.CustomUser',
        on_delete=models.SET_NULL,
        null=True,
        related_name='sent_invitations'
    )
    
    accepted_by = models.ForeignKey(
        'authentication.CustomUser',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='accepted_invitations'
    )
    
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING
    )
    
    token = models.CharField(max_length=100, unique=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    accepted_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        verbose_name = 'Ministry Invitation'
        verbose_name_plural = 'Ministry Invitations'
        indexes = [
            models.Index(fields=['ministry', 'status']),
            models.Index(fields=['email']),
            models.Index(fields=['token']),
        ]
    
    def __str__(self):
        return f"Invitation to {self.email} for {self.ministry.name}"
