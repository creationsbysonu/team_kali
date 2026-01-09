"""
Base Serializers with Optimization Hints

Provides:
- Optimized serializer base classes
- Field selection utilities
- Nested serializer optimization
- Caching for computed fields
"""
import logging
from typing import List, Dict, Any, Optional, Union
from functools import lru_cache

from django.db.models import QuerySet, Prefetch

from rest_framework import serializers
from rest_framework.request import Request

logger = logging.getLogger(__name__)


class OptimizedSerializerMixin:
    """
    Mixin providing query optimization hints for serializers.
    
    Usage:
        class MySerializer(OptimizedSerializerMixin, serializers.ModelSerializer):
            class Meta:
                model = MyModel
                fields = ['id', 'name', 'user', 'tags']
            
            # Optimization hints
            select_related_fields = ['user']
            prefetch_related_fields = ['tags']
    """
    
    # Override in subclass
    select_related_fields: List[str] = []
    prefetch_related_fields: List[str] = []
    
    @classmethod
    def get_select_related(cls) -> List[str]:
        """Get fields for select_related()"""
        return cls.select_related_fields
    
    @classmethod
    def get_prefetch_related(cls) -> List[str]:
        """Get fields for prefetch_related()"""
        return cls.prefetch_related_fields
    
    @classmethod
    def optimize_queryset(cls, queryset: QuerySet) -> QuerySet:
        """Apply all optimizations to queryset"""
        if cls.select_related_fields:
            queryset = queryset.select_related(*cls.select_related_fields)
        if cls.prefetch_related_fields:
            queryset = queryset.prefetch_related(*cls.prefetch_related_fields)
        return queryset


class DynamicFieldsMixin:
    """
    Mixin for dynamic field selection via query params.
    
    Allows clients to request only specific fields:
    GET /api/items/?fields=id,name,created_at
    
    Or exclude fields:
    GET /api/items/?exclude=large_field,metadata
    
    Usage:
        class MySerializer(DynamicFieldsMixin, serializers.ModelSerializer):
            class Meta:
                model = MyModel
                fields = '__all__'
    """
    
    def __init__(self, *args, **kwargs):
        # Get fields/exclude from context
        request = kwargs.get('context', {}).get('request')
        
        # Pop custom kwargs if passed directly
        fields = kwargs.pop('fields', None)
        exclude = kwargs.pop('exclude', None)
        
        super().__init__(*args, **kwargs)
        
        # Handle request query params
        if request and hasattr(request, 'query_params'):
            fields = fields or request.query_params.get('fields')
            exclude = exclude or request.query_params.get('exclude')
        
        # Apply field filtering
        if fields:
            fields = fields.split(',') if isinstance(fields, str) else fields
            allowed = set(fields)
            existing = set(self.fields.keys())  # type: ignore[attr-defined]
            
            for field_name in existing - allowed:
                self.fields.pop(field_name, None)  # type: ignore[attr-defined]
        
        if exclude:
            exclude = exclude.split(',') if isinstance(exclude, str) else exclude
            for field_name in exclude:
                self.fields.pop(field_name, None)  # type: ignore[attr-defined]


class CachedSerializerMethodMixin:
    """
    Mixin for caching expensive SerializerMethodField computations.
    
    Usage:
        class MySerializer(CachedSerializerMethodMixin, serializers.ModelSerializer):
            expensive_field = serializers.SerializerMethodField()
            
            @cached_serializer_method
            def get_expensive_field(self, obj):
                # This result will be cached
                return expensive_computation(obj)
    """
    
    _method_cache: Dict[str, Any] = {}
    
    def get_cache_key(self, method_name: str, obj: Any) -> str:
        """Generate cache key for method result"""
        obj_id = getattr(obj, 'id', id(obj))
        return f"{self.__class__.__name__}:{method_name}:{obj_id}"


def cached_serializer_method(func):
    """
    Decorator for caching serializer method field results.
    
    Caches per-instance within the same serialization context.
    """
    def wrapper(self, obj):
        cache_key = f"{func.__name__}:{getattr(obj, 'id', id(obj))}"
        
        # Use instance-level cache
        if not hasattr(self, '_field_cache'):
            self._field_cache = {}
        
        if cache_key not in self._field_cache:
            self._field_cache[cache_key] = func(self, obj)
        
        return self._field_cache[cache_key]
    
    return wrapper


class BaseModelSerializer(
    OptimizedSerializerMixin, 
    DynamicFieldsMixin, 
    serializers.ModelSerializer
):
    """
    Base serializer with all optimization features.
    
    Features:
    - Query optimization hints
    - Dynamic field selection
    - Consistent created/updated field formatting
    
    Usage:
        class MySerializer(BaseModelSerializer):
            class Meta:
                model = MyModel
                fields = ['id', 'name', 'created_at', 'updated_at']
            
            select_related_fields = ['user']
            prefetch_related_fields = ['tags']
    """
    
    # Common timestamp fields - override in subclass if needed
    # Note: format parameter is valid at runtime despite type checker warning


class PaginatedResponseSerializer(serializers.Serializer):
    """
    Serializer for documenting paginated response structure.
    
    Used for OpenAPI/Swagger documentation.
    """
    
    next = serializers.CharField(allow_null=True, help_text="Cursor for next page")
    previous = serializers.CharField(allow_null=True, help_text="Cursor for previous page")
    has_more = serializers.BooleanField(help_text="Whether more results exist")
    results = serializers.ListField(help_text="List of result items")
    metadata = serializers.DictField(help_text="Pagination metadata")


class NestedSerializerMixin:
    """
    Mixin for optimizing nested serializer relationships.
    
    Provides methods to handle nested data efficiently.
    """
    
    @classmethod
    def get_nested_prefetch(
        cls, 
        field_name: str, 
        queryset: Optional[QuerySet] = None
    ) -> Union[Prefetch, str]:
        """
        Get Prefetch object for nested serializer field.
        
        Usage in view:
            queryset = MyModel.objects.prefetch_related(
                MySerializer.get_nested_prefetch('items')
            )
        """
        declared_fields = getattr(cls, '_declared_fields', {})
        field = declared_fields.get(field_name)
        
        if not field:
            raise ValueError(f"Field {field_name} not found in serializer")
        
        # Get nested serializer class
        if hasattr(field, 'child'):
            nested_serializer = field.child.__class__
        else:
            nested_serializer = field.__class__
        
        # Get queryset if not provided
        if queryset is None:
            related_model = getattr(nested_serializer.Meta, 'model', None)
            if related_model:
                queryset = related_model.objects.all()
            else:
                return field_name  # Fallback to simple prefetch
        
        # Apply nested optimizations
        if hasattr(nested_serializer, 'optimize_queryset'):
            queryset = nested_serializer.optimize_queryset(queryset)
        
        return Prefetch(field_name, queryset=queryset)


class ListSerializer(serializers.ListSerializer):
    """
    Optimized list serializer for bulk operations.
    
    Provides batch optimization for many=True serializers.
    """
    
    def to_representation(self, data):
        """
        Optimize representation of lists.
        
        Pre-fetches related data in bulk before iterating.
        """
        # Check if child serializer has optimization hints
        child = self.child
        if child and hasattr(child, 'optimize_queryset') and hasattr(data, 'all'):
            data = child.optimize_queryset(data.all())
        
        return super().to_representation(data)


class ErrorResponseSerializer(serializers.Serializer):
    """Standard error response serializer for documentation"""
    
    success = serializers.BooleanField(default=False)
    error = serializers.CharField()
    code = serializers.CharField(required=False)
    details = serializers.DictField(required=False)


class SuccessResponseSerializer(serializers.Serializer):
    """Standard success response serializer for documentation"""
    
    success = serializers.BooleanField(default=True)
    response_data = serializers.DictField(required=False, help_text="Response data payload")
    message = serializers.CharField(required=False)
