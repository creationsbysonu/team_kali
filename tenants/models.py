"""
Tenant Models for Multi-Tenancy

Tenants represent government ministries/departments.
Each tenant has its own dashboard and data isolation.
"""
import uuid
from django.db import models
from django.utils.text import slugify


class Tenant(models.Model):
    """
    Government Ministry/Department Tenant
    
    Each ministry is a separate tenant with isolated data.
    Super admin creates and manages tenants.
    """
    
    class Status(models.TextChoices):
        ACTIVE = 'active', 'Active'
        SUSPENDED = 'suspended', 'Suspended'
        PENDING = 'pending', 'Pending Approval'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Basic Info
    name = models.CharField(max_length=255, help_text="Ministry/Department name")
    slug = models.SlugField(unique=True, max_length=100, help_text="URL-friendly identifier")
    description = models.TextField(blank=True, help_text="Ministry description")
    
    # Contact Info
    email = models.EmailField(help_text="Official contact email")
    phone = models.CharField(max_length=20, blank=True)
    address = models.TextField(blank=True)
    website = models.URLField(blank=True)
    
    # Branding
    logo = models.ImageField(upload_to='tenants/logos/', null=True, blank=True)
    
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
        help_text="Tenant-specific configuration"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Tenant'
        verbose_name_plural = 'Tenants'
        ordering = ['name']
        indexes = [
            models.Index(fields=['slug']),
            models.Index(fields=['status']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return self.name
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)
    
    @property
    def is_active(self):
        return self.status == self.Status.ACTIVE


class TenantMember(models.Model):
    """
    Ministry staff membership
    
    Links users to ministries. All ministry staff have the same access level.
    Citizens don't need TenantMember - they interact with all ministries.
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.CASCADE,
        related_name='members'
    )
    user = models.ForeignKey(
        'authentication.CustomUser',
        on_delete=models.CASCADE,
        related_name='tenant_memberships'
    )
    
    # Status
    is_active = models.BooleanField(default=True)
    
    # Timestamps
    joined_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Ministry Staff'
        verbose_name_plural = 'Ministry Staff'
        unique_together = ['tenant', 'user']
        indexes = [
            models.Index(fields=['tenant']),
            models.Index(fields=['user', 'is_active']),
        ]
    
    def __str__(self):
        return f"{self.user.email} - {self.tenant.name}"


class TenantInvitation(models.Model):
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
    
    tenant = models.ForeignKey(
        Tenant,
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
            models.Index(fields=['tenant', 'status']),
            models.Index(fields=['email']),
            models.Index(fields=['token']),
        ]
    
    def __str__(self):
        return f"Invitation to {self.email} for {self.tenant.name}"
