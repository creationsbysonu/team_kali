"""
Mixins for Views and ViewSets

Provides:
- Caching mixins with automatic invalidation
- Query optimization (select_related, prefetch_related)
- ETag support for conditional requests
- Rate limiting integration
"""
import hashlib
import logging
from typing import List, Optional, Dict, Any, Tuple
from functools import cached_property

from django.db.models import QuerySet
from django.core.cache import cache
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page
from django.views.decorators.vary import vary_on_headers

from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework import status

from .utils.cache import (
    CacheKeyBuilder, 
    CacheTTL, 
    CacheInvalidator, 
    get_or_set_cache
)

logger = logging.getLogger(__name__)


class QueryOptimizationMixin:
    """
    Mixin for optimizing database queries.
    
    Automatically applies select_related() and prefetch_related()
    based on class attributes.
    
    Usage:
        class MyViewSet(QueryOptimizationMixin, ModelViewSet):
            queryset = MyModel.objects.all()
            select_related_fields = ['user', 'category']
            prefetch_related_fields = ['tags', 'comments']
            only_fields = ['id', 'name', 'created_at']  # Optional
            defer_fields = ['large_text_field']  # Optional
    """
    
    # Override these in your view
    select_related_fields: List[str] = []
    prefetch_related_fields: List[str] = []
    only_fields: List[str] = []
    defer_fields: List[str] = []
    
    # Different optimizations for list vs detail
    list_select_related: Optional[List[str]] = None
    list_prefetch_related: Optional[List[str]] = None
    detail_select_related: Optional[List[str]] = None
    detail_prefetch_related: Optional[List[str]] = None
    
    def get_queryset(self) -> QuerySet:
        """Apply query optimizations based on action"""
        queryset = super().get_queryset()  # type: ignore[misc]
        
        # Determine if list or detail action
        is_list = getattr(self, 'action', None) in ['list', None]
        
        # Select related
        select_fields = (
            (self.list_select_related if is_list else self.detail_select_related)
            or self.select_related_fields
        )
        if select_fields:
            queryset = queryset.select_related(*select_fields)
        
        # Prefetch related
        prefetch_fields = (
            (self.list_prefetch_related if is_list else self.detail_prefetch_related)
            or self.prefetch_related_fields
        )
        if prefetch_fields:
            queryset = queryset.prefetch_related(*prefetch_fields)
        
        # Only/Defer fields (only for list to reduce payload)
        if is_list:
            if self.only_fields:
                queryset = queryset.only(*self.only_fields)
            elif self.defer_fields:
                queryset = queryset.defer(*self.defer_fields)
        
        return queryset


class CacheMixin:
    """
    Mixin for caching API responses with automatic invalidation.
    
    Features:
    - Automatic cache key generation
    - Per-action TTL configuration
    - User/tenant-aware caching
    - Cache invalidation on mutations
    
    Usage:
        class MyViewSet(CacheMixin, ModelViewSet):
            cache_model_name = 'mymodel'
            cache_ttl = CacheTTL.FEED
            cache_user_specific = False
            cache_tenant_aware = True
    """
    
    cache_model_name: Optional[str] = None
    cache_ttl: int = CacheTTL.FEED
    cache_user_specific: bool = False
    cache_tenant_aware: bool = True
    
    # Per-action TTL overrides
    cache_ttl_overrides: Dict[str, int] = {
        'list': CacheTTL.FEED,
        'retrieve': CacheTTL.DETAIL,
        'search': CacheTTL.SEARCH,
    }
    
    def _get_cache_key(self, request: Request, action: Optional[str] = None) -> str:
        """Generate cache key for request"""
        model = self.cache_model_name or self.__class__.__name__.lower()
        resolved_action = action or getattr(self, 'action', 'default') or 'default'
        
        return CacheKeyBuilder.build(
            model=model,
            identifier=resolved_action,
            params=dict(request.query_params),
            user_id=str(request.user.id) if self.cache_user_specific and request.user.is_authenticated else None,
            ministry_id=getattr(request, 'ministry_id', None) if self.cache_tenant_aware else None
        )
    
    def _get_cache_ttl(self, action: Optional[str] = None) -> int:
        """Get TTL for current action"""
        resolved_action = action or getattr(self, 'action', 'default') or 'default'
        return self.cache_ttl_overrides.get(resolved_action, self.cache_ttl)
    
    def list(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Cached list action"""
        cache_key = self._get_cache_key(request, 'list')
        
        cached = cache.get(cache_key)
        if cached is not None:
            logger.debug(f"Cache HIT: {cache_key}")
            return Response(cached)
        
        logger.debug(f"Cache MISS: {cache_key}")
        response = super().list(request, *args, **kwargs)  # type: ignore[misc]
        
        if response.status_code == 200:
            cache.set(cache_key, response.data, self._get_cache_ttl('list'))
        
        return response
    
    def retrieve(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Cached retrieve action"""
        pk = kwargs.get('pk')
        cache_key = CacheKeyBuilder.build(
            model=self.cache_model_name or 'default',
            identifier=str(pk) if pk else 'unknown',
            ministry_id=getattr(request, 'ministry_id', None) if self.cache_tenant_aware else None
        )
        
        cached = cache.get(cache_key)
        if cached is not None:
            logger.debug(f"Cache HIT: {cache_key}")
            return Response(cached)
        
        logger.debug(f"Cache MISS: {cache_key}")
        response = super().retrieve(request, *args, **kwargs)  # type: ignore[misc]
        
        if response.status_code == 200:
            cache.set(cache_key, response.data, self._get_cache_ttl('retrieve'))
        
        return response
    
    def create(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Create with cache invalidation"""
        response = super().create(request, *args, **kwargs)  # type: ignore[misc]
        
        if response.status_code == 201:
            ministry_id = getattr(request, 'ministry_id', None) if self.cache_tenant_aware else None
            CacheInvalidator.on_create(
                model=self.cache_model_name or 'default',
                ministry_id=str(ministry_id) if ministry_id else None
            )
        
        return response
    
    def update(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Update with cache invalidation"""
        response = super().update(request, *args, **kwargs)  # type: ignore[misc]
        
        if response.status_code == 200:
            pk = kwargs.get('pk')
            ministry_id = getattr(request, 'ministry_id', None) if self.cache_tenant_aware else None
            CacheInvalidator.on_update(
                model=self.cache_model_name or 'default',
                object_id=str(pk) if pk else None,
                ministry_id=str(ministry_id) if ministry_id else None
            )
        
        return response
    
    def partial_update(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Partial update with cache invalidation"""
        response = super().partial_update(request, *args, **kwargs)  # type: ignore[misc]
        
        if response.status_code == 200:
            pk = kwargs.get('pk')
            ministry_id = getattr(request, 'ministry_id', None) if self.cache_tenant_aware else None
            CacheInvalidator.on_update(
                model=self.cache_model_name or 'default',
                object_id=str(pk) if pk else None,
                ministry_id=str(ministry_id) if ministry_id else None
            )
        
        return response
    
    def destroy(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Destroy with cache invalidation"""
        pk = kwargs.get('pk')
        response = super().destroy(request, *args, **kwargs)  # type: ignore[misc]
        
        if response.status_code == 204:
            ministry_id = getattr(request, 'ministry_id', None) if self.cache_tenant_aware else None
            CacheInvalidator.on_delete(
                model=self.cache_model_name or 'default',
                object_id=str(pk) if pk else None,
                ministry_id=str(ministry_id) if ministry_id else None
            )
        
        return response


class ETagMixin:
    """
    Mixin for ETag support in conditional requests.
    
    Supports:
    - If-None-Match header for conditional GET
    - ETag generation from response data
    - 304 Not Modified responses
    
    Usage:
        class MyViewSet(ETagMixin, ModelViewSet):
            pass
    """
    
    def _generate_etag(self, data: Any) -> str:
        """Generate ETag from response data"""
        import json
        content = json.dumps(data, sort_keys=True, default=str)
        return f'"{hashlib.md5(content.encode()).hexdigest()}"'
    
    def finalize_response(self, request: Request, response: Response, *args: Any, **kwargs: Any) -> Response:
        """Add ETag and check If-None-Match"""
        response = super().finalize_response(request, response, *args, **kwargs)  # type: ignore[misc]
        
        # Only for successful GET requests
        if request.method != 'GET' or response.status_code != 200:
            return response
        
        # Generate ETag
        if hasattr(response, 'data') and response.data:
            etag = self._generate_etag(response.data)
            response['ETag'] = etag
            
            # Check If-None-Match
            if_none_match = request.META.get('HTTP_IF_NONE_MATCH')
            if if_none_match and if_none_match == etag:
                response.status_code = 304
                response.data = None
        
        return response


class PaginatedCacheMixin(CacheMixin):
    """
    Extended cache mixin for paginated responses.
    
    Caches each page separately with cursor/offset as part of key.
    """
    
    def _get_cache_key(self, request: Request, action: Optional[str] = None) -> str:
        """Include pagination params in cache key"""
        model = self.cache_model_name or self.__class__.__name__.lower()
        action = action or getattr(self, 'action', 'default')
        
        # Include pagination params
        params = dict(request.query_params)
        cursor_value = params.get('cursor')
        ministry_id = getattr(request, 'ministry_id', None) if self.cache_tenant_aware else None
        
        return CacheKeyBuilder.build_pagination_key(
            model=model,
            cursor=str(cursor_value) if cursor_value else None,
            page_size=int(params.get('page_size', 20)),
            filters={k: v for k, v in params.items() if k not in ['cursor', 'page_size']},
            user_id=str(request.user.id) if self.cache_user_specific and request.user.is_authenticated else None,
            ministry_id=str(ministry_id) if ministry_id else None
        )


class StaleWhileRevalidateMixin(CacheMixin):
    """
    Implements stale-while-revalidate caching pattern.
    
    Returns stale cached data immediately while refreshing in background.
    Great for feeds and frequently updated data.
    
    Usage:
        class MyViewSet(StaleWhileRevalidateMixin, ModelViewSet):
            stale_ttl = 300  # 5 minutes of stale allowed
    """
    
    stale_ttl: int = 300  # Extra time to serve stale content
    
    def list(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """List with stale-while-revalidate"""
        cache_key = self._get_cache_key(request, 'list')
        stale_key = f"{cache_key}:stale"
        
        # Try fresh cache
        cached = cache.get(cache_key)
        if cached is not None:
            logger.debug(f"Fresh cache HIT: {cache_key}")
            return Response(cached)
        
        # Try stale cache
        stale = cache.get(stale_key)
        if stale is not None:
            logger.debug(f"Stale cache HIT: {stale_key}")
            # TODO: Queue background refresh via Celery
            return Response(stale)
        
        # Cache miss, fetch fresh - call grandparent's list
        logger.debug(f"Cache MISS: {cache_key}")
        # Access the list method from the class that comes after CacheMixin in MRO
        for cls in self.__class__.__mro__:
            if cls is not StaleWhileRevalidateMixin and cls is not CacheMixin and hasattr(cls, 'list'):
                response = cls.list(self, request, *args, **kwargs)  # type: ignore[arg-type]
                break
        else:
            raise RuntimeError("No list method found in MRO")
        
        if response.status_code == 200:
            ttl = self._get_cache_ttl('list')
            cache.set(cache_key, response.data, ttl)
            cache.set(stale_key, response.data, ttl + self.stale_ttl)
        
        return response


# Composite mixins for common use cases
class OptimizedListMixin(QueryOptimizationMixin, CacheMixin, ETagMixin):
    """Combined optimization for list views"""
    pass


class FullyOptimizedMixin(QueryOptimizationMixin, PaginatedCacheMixin, ETagMixin):
    """Full optimization with pagination caching"""
    pass
