"""
Ministry-Aware Model Mixins

Base classes for models that belong to a specific ministry.
"""
from django.db import models
from .context import get_current_ministry


class MinistryAwareManager(models.Manager):
    """
    Manager that automatically filters by current ministry.
    
    When a ministry is set in the context, all queries will be
    automatically filtered to that ministry.
    """
    
    def get_queryset(self):
        qs = super().get_queryset()
        ministry = get_current_ministry()
        
        if ministry:
            return qs.filter(ministry=ministry)
        return qs
    
    def all_ministries(self):
        """Get queryset without ministry filtering"""
        return super().get_queryset()


class MinistryAwareModel(models.Model):
    """
    Abstract model for ministry-scoped data.
    
    Inherit from this for any model that should be isolated per ministry.
    
    Example:
        class Service(MinistryAwareModel):
            name = models.CharField(max_length=255)
            # ministry field is inherited
    """
    ministry = models.ForeignKey(
        'ministry.Ministry',
        on_delete=models.CASCADE,
        related_name='%(class)s_items'
    )
    
    # Use ministry-aware manager by default
    objects = MinistryAwareManager()
    
    class Meta:
        abstract = True
