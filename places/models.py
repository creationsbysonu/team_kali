"""
Place Model - Core Domain Data Layer

Defines the Place model representing decentralized locations.
Places are the primary entity - ministries belong to places.

This is a DATA LAYER ONLY - no business logic here.
"""
import uuid
from django.db import models
from django.conf import settings as django_settings
from django.utils import timezone
from django.utils.text import slugify


class PlaceManager(models.Manager):
    """Custom manager that excludes soft-deleted places by default"""
    
    def get_queryset(self):
        return super().get_queryset().filter(is_deleted=False)
    
    def all_with_deleted(self):
        """Include soft-deleted places"""
        return super().get_queryset()
    
    def deleted_only(self):
        """Only soft-deleted places"""
        return super().get_queryset().filter(is_deleted=True)
    
    def active(self):
        """Only active places"""
        return self.get_queryset().filter(is_active=True)


class Place(models.Model):
    """
    Decentralized Location/Place
    
    Represents a geographic location where government services are provided.
    Each place has its own set of ministries.
    
    Examples: Kathmandu, Biratnagar, Pokhara, Lalitpur
    
    Hierarchy: Place -> Ministries -> Services -> Staff
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Basic Info - only name field as per requirement
    name = models.CharField(
        max_length=100, 
        help_text="Place/Location name (e.g., Kathmandu, Biratnagar)"
    )
    slug = models.SlugField(
        unique=True, 
        max_length=100, 
        help_text="URL-friendly identifier"
    )
    
    # Status
    is_active = models.BooleanField(
        default=True,
        help_text="Whether this place is active and accessible"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Soft Delete
    is_deleted = models.BooleanField(
        default=False,
        help_text="Soft deleted - data remains but place is inaccessible"
    )
    deleted_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When the place was soft deleted"
    )
    deleted_by = models.ForeignKey(
        django_settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='deleted_places',
        help_text="Super admin who deleted the place"
    )
    
    # Custom managers
    objects = PlaceManager()  # Default excludes soft-deleted
    all_objects = models.Manager()  # Includes all (for admin use)
    
    class Meta:
        verbose_name = 'Place'
        verbose_name_plural = 'Places'
        ordering = ['name']
        indexes = [
            models.Index(fields=['slug']),
            models.Index(fields=['is_active']),
            models.Index(fields=['is_deleted']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return self.name
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)
    
    def soft_delete(self, deleted_by=None):
        """Soft delete the place - data preserved but inaccessible"""
        self.is_deleted = True
        self.deleted_at = timezone.now()
        self.deleted_by = deleted_by
        self.is_active = False
        self.save(update_fields=['is_deleted', 'deleted_at', 'deleted_by', 'is_active', 'updated_at'])
    
    def restore(self):
        """Restore a soft-deleted place"""
        self.is_deleted = False
        self.deleted_at = None
        self.deleted_by = None
        self.is_active = True
        self.save(update_fields=['is_deleted', 'deleted_at', 'deleted_by', 'is_active', 'updated_at'])
    
    @property
    def ministry_count(self):
        """Number of active ministries in this place"""
        return self.ministries.filter(is_deleted=False, status='active').count()  # type: ignore[attr-defined]
