"""
Services Models - Core Domain Data Layer

Defines the data models for ministry services and staff assignments.
Services belong to ministries. Staff are assigned to specific services.

Hierarchy: Place -> Ministry -> Service -> ServiceStaff
"""
import uuid
from decimal import Decimal
from django.db import models
from django.conf import settings as django_settings
from django.utils import timezone


class ServiceCategoryManager(models.Manager):
    """Custom manager that excludes soft-deleted categories by default"""
    
    def get_queryset(self):
        return super().get_queryset().filter(is_deleted=False)
    
    def all_with_deleted(self):
        """Include soft-deleted categories"""
        return super().get_queryset()
    
    def deleted_only(self):
        """Only soft-deleted categories"""
        return super().get_queryset().filter(is_deleted=True)


class ServiceCategory(models.Model):
    """
    Category of services offered by a ministry.
    
    Examples: License Services, Certificate Services, Registration Services
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Relationship to ministry
    ministry = models.ForeignKey(
        'ministry.Ministry',
        on_delete=models.CASCADE,
        related_name='service_categories',
        help_text="Ministry that owns this category"
    )
    
    # Basic info
    name = models.CharField(max_length=100, help_text="Category name")
    slug = models.SlugField(max_length=100, help_text="URL-friendly identifier")
    description = models.TextField(blank=True, help_text="Category description")
    icon = models.CharField(max_length=50, blank=True, help_text="Icon class/name")
    
    # Ordering
    display_order = models.PositiveIntegerField(default=0, help_text="Display order")
    
    # Status
    is_active = models.BooleanField(default=True)
    
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
        related_name='deleted_service_categories'
    )
    
    objects = ServiceCategoryManager()
    
    class Meta:
        verbose_name = 'Service Category'
        verbose_name_plural = 'Service Categories'
        ordering = ['display_order', 'name']
        unique_together = ['ministry', 'slug']
        indexes = [
            models.Index(fields=['ministry', 'is_active']),
            models.Index(fields=['slug']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.ministry.name})"
    
    def soft_delete(self, user=None):
        """Soft delete the category"""
        self.is_deleted = True
        self.deleted_at = timezone.now()
        self.deleted_by = user
        self.save(update_fields=['is_deleted', 'deleted_at', 'deleted_by'])
    
    def restore(self):
        """Restore soft-deleted category"""
        self.is_deleted = False
        self.deleted_at = None
        self.deleted_by = None
        self.save(update_fields=['is_deleted', 'deleted_at', 'deleted_by'])
    
    @property
    def service_count(self):
        """Number of active services in this category"""
        return self.services.filter(is_active=True, is_deleted=False).count()  # type: ignore[attr-defined]


class ServiceManager(models.Manager):
    """Custom manager that excludes soft-deleted services by default"""
    
    def get_queryset(self):
        return super().get_queryset().filter(is_deleted=False)
    
    def all_with_deleted(self):
        """Include soft-deleted services"""
        return super().get_queryset()
    
    def deleted_only(self):
        """Only soft-deleted services"""
        return super().get_queryset().filter(is_deleted=True)
    
    def active(self):
        """Only active and non-deleted services"""
        return self.get_queryset().filter(is_active=True)


class Service(models.Model):
    """
    A service offered by a ministry to citizens.
    
    Examples: Driving License Application, Birth Certificate, Business Registration
    """
    
    class ServiceType(models.TextChoices):
        ONLINE = 'online', 'Online Service'
        OFFLINE = 'offline', 'Offline Service'
        HYBRID = 'hybrid', 'Hybrid (Online + Offline)'
    
    class ProcessingTime(models.TextChoices):
        INSTANT = 'instant', 'Instant'
        SAME_DAY = 'same_day', 'Same Day'
        ONE_TO_THREE_DAYS = '1_3_days', '1-3 Days'
        ONE_WEEK = '1_week', '1 Week'
        TWO_WEEKS = '2_weeks', '2 Weeks'
        ONE_MONTH = '1_month', '1 Month'
        VARIABLE = 'variable', 'Variable'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Relationships
    ministry = models.ForeignKey(
        'ministry.Ministry',
        on_delete=models.CASCADE,
        related_name='services',
        help_text="Ministry that provides this service"
    )
    category = models.ForeignKey(
        ServiceCategory,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='services',
        help_text="Service category"
    )
    
    # Basic info
    name = models.CharField(max_length=200, help_text="Service name")
    slug = models.SlugField(max_length=200, help_text="URL-friendly identifier")
    short_description = models.CharField(max_length=500, blank=True, help_text="Brief description")
    description = models.TextField(blank=True, help_text="Full service description")
    
    # Service details
    service_type = models.CharField(
        max_length=20,
        choices=ServiceType.choices,
        default=ServiceType.ONLINE
    )
    processing_time = models.CharField(
        max_length=20,
        choices=ProcessingTime.choices,
        default=ProcessingTime.VARIABLE
    )
    
    # Fees
    fee_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Service fee in NPR"
    )
    fee_description = models.CharField(max_length=200, blank=True, help_text="Fee details")
    
    # Requirements
    required_documents = models.JSONField(
        default=list,
        blank=True,
        help_text="List of required documents"
    )
    eligibility_criteria = models.TextField(blank=True, help_text="Who can apply")
    
    # Application form schema (JSON Schema format)
    form_schema = models.JSONField(
        default=dict,
        blank=True,
        help_text="JSON Schema for the application form"
    )
    
    # External links
    external_url = models.URLField(blank=True, help_text="External service portal URL")
    
    # Display
    icon = models.CharField(max_length=50, blank=True, help_text="Icon class/name")
    display_order = models.PositiveIntegerField(default=0)
    is_featured = models.BooleanField(default=False, help_text="Show on ministry homepage")
    
    # Status
    is_active = models.BooleanField(default=True)
    is_published = models.BooleanField(default=False, help_text="Visible to citizens")
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    published_at = models.DateTimeField(null=True, blank=True)
    
    # Soft delete
    is_deleted = models.BooleanField(default=False)
    deleted_at = models.DateTimeField(null=True, blank=True)
    deleted_by = models.ForeignKey(
        django_settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='deleted_services'
    )
    
    # Audit
    created_by = models.ForeignKey(
        django_settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_services'
    )
    updated_by = models.ForeignKey(
        django_settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='updated_services'
    )
    
    objects = ServiceManager()
    
    class Meta:
        verbose_name = 'Service'
        verbose_name_plural = 'Services'
        ordering = ['display_order', 'name']
        unique_together = ['ministry', 'slug']
        indexes = [
            models.Index(fields=['ministry', 'is_active', 'is_published']),
            models.Index(fields=['category', 'is_active']),
            models.Index(fields=['service_type']),
            models.Index(fields=['slug']),
            models.Index(fields=['is_featured']),
        ]
    
    def __str__(self):
        return f"{self.name} - {self.ministry.name}"
    
    def soft_delete(self, user=None):
        """Soft delete the service"""
        self.is_deleted = True
        self.is_published = False
        self.deleted_at = timezone.now()
        self.deleted_by = user
        self.save(update_fields=['is_deleted', 'is_published', 'deleted_at', 'deleted_by'])
    
    def restore(self):
        """Restore soft-deleted service"""
        self.is_deleted = False
        self.deleted_at = None
        self.deleted_by = None
        self.save(update_fields=['is_deleted', 'deleted_at', 'deleted_by'])
    
    def publish(self, user=None):
        """Publish the service"""
        self.is_published = True
        self.published_at = timezone.now()
        if user:
            self.updated_by = user
        self.save(update_fields=['is_published', 'published_at', 'updated_by'])
    
    def unpublish(self, user=None):
        """Unpublish the service"""
        self.is_published = False
        if user:
            self.updated_by = user
        self.save(update_fields=['is_published', 'updated_by'])


class ServiceStaff(models.Model):
    """
    Staff assignment for a specific service.
    
    Links a user (staff role) to a specific service within a ministry.
    Staff can only login and access the specific service they are assigned to.
    
    Hierarchy: Place -> Ministry -> Service -> Staff
    
    This enables decentralized access control:
    - Staff login requires: place_slug + ministry_slug + service_slug
    - Staff can only see applications for their assigned service
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # The service this staff is assigned to
    service = models.ForeignKey(
        Service,
        on_delete=models.CASCADE,
        related_name='staff_members',
        help_text="Service this staff is assigned to"
    )
    
    # The user with staff role
    user = models.ForeignKey(
        django_settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='service_assignments',
        help_text="User assigned as staff"
    )
    
    # Status
    is_active = models.BooleanField(
        default=True,
        help_text="Whether this staff assignment is active"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Service Staff'
        verbose_name_plural = 'Service Staff'
        unique_together = ['service', 'user']
        indexes = [
            models.Index(fields=['service', 'is_active']),
            models.Index(fields=['user', 'is_active']),
        ]
    
    def __str__(self):
        return f"{self.user.email} - {self.service.name}"
    
    @property
    def ministry(self):
        """Get the ministry this staff belongs to"""
        return self.service.ministry
    
    @property
    def place(self):
        """Get the place this staff belongs to"""
        return self.service.ministry.place
