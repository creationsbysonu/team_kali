"""
Tenant-Aware Model Mixins

Base classes for models that belong to a specific tenant.
"""
from django.db import models
from .context import get_current_tenant


class TenantAwareManager(models.Manager):
    """
    Manager that automatically filters by current tenant.
    
    When a tenant is set in the context, all queries will be
    automatically filtered to that tenant.
    """
    
    def get_queryset(self):
        qs = super().get_queryset()
        tenant = get_current_tenant()
        
        if tenant:
            return qs.filter(tenant=tenant)
        return qs
    
    def all_tenants(self):
        """Get queryset without tenant filtering"""
        return super().get_queryset()


class TenantAwareModel(models.Model):
    """
    Abstract model for tenant-scoped data.
    
    Inherit from this for any model that should be isolated per tenant.
    
    Example:
        class Application(TenantAwareModel):
            title = models.CharField(max_length=255)
            # tenant field is inherited
    """
    tenant = models.ForeignKey(
        'tenants.Tenant',
        on_delete=models.CASCADE,
        related_name='%(class)s_items'
    )
    
    # Use tenant-aware manager by default
    objects = TenantAwareManager()
    
    # Keep a manager for unfiltered access
    all_objects = models.Manager()
    
    class Meta:
        abstract = True
    
    def save(self, *args, **kwargs):  # type: ignore[override]
        # Auto-set tenant from context if not provided
        if not getattr(self, 'tenant_id', None):
            tenant = get_current_tenant()
            if tenant:
                self.tenant = tenant  # type: ignore[attr-defined]
        super().save(*args, **kwargs)
