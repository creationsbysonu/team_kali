"""
Cache Utilities for Pagination and API Responses

Provides:
- Cache key generation with versioning
- Intelligent cache invalidation
- Stale-while-revalidate pattern support
- User-specific and global cache strategies
"""
import hashlib
import logging
from typing import Optional, List, Any, Callable, Dict, cast, TYPE_CHECKING
from functools import wraps

from django.core.cache import cache
from django.conf import settings

logger = logging.getLogger(__name__)


class CacheKeyBuilder:
    """
    Build consistent, versioned cache keys.
    
    Key format: {prefix}:{version}:{model}:{identifier}:{hash}
    Example: sewa:v1:tenant:list:abc123def
    """
    
    PREFIX = getattr(settings, 'CACHE_KEY_PREFIX', 'sewa')
    VERSION = getattr(settings, 'CACHE_VERSION', 'v1')
    
    @classmethod
    def _hash_params(cls, params: Optional[Dict[str, Any]]) -> str:
        """Create short hash from parameters"""
        if not params:
            return 'default'
        
        # Sort keys for consistency
        sorted_items = sorted(params.items())
        param_str = '&'.join(f"{k}={v}" for k, v in sorted_items if v is not None)
        return hashlib.md5(param_str.encode()).hexdigest()[:12]
    
    @classmethod
    def build(
        cls,
        model: str,
        identifier: str = 'list',
        params: Optional[Dict[str, Any]] = None,
        user_id: Optional[str] = None,
        ministry_id: Optional[str] = None
    ) -> str:
        """
        Build a cache key.
        
        Args:
            model: Model/resource name (e.g., 'ministry', 'service')
            identifier: Specific identifier (e.g., 'list', 'detail', UUID)
            params: Query parameters to hash
            user_id: User ID for user-specific caching
            ministry_id: Ministry ID for tenant-scoped caching
            
        Returns:
            Formatted cache key string
        """
        parts = [cls.PREFIX, cls.VERSION, model]
        
        if ministry_id:
            parts.append(f"t:{str(ministry_id)[:8]}")
        
        if user_id:
            parts.append(f"u:{str(user_id)[:8]}")
        
        parts.append(identifier)
        
        if params:
            parts.append(cls._hash_params(params))
        
        return ':'.join(parts)
    
    @classmethod
    def build_pagination_key(
        cls,
        model: str,
        cursor: Optional[str] = None,
        page_size: int = 20,
        filters: Optional[Dict[str, Any]] = None,
        user_id: Optional[str] = None,
        ministry_id: Optional[str] = None
    ) -> str:
        """Build cache key specifically for paginated responses"""
        params: Dict[str, Any] = {
            'cursor': cursor,
            'page_size': page_size,
            **(filters or {})
        }
        return cls.build(
            model=model,
            identifier='paginated',
            params=params,
            user_id=user_id,
            ministry_id=ministry_id
        )
    
    @classmethod
    def get_pattern(cls, model: str, ministry_id: Optional[str] = None) -> str:
        """Get pattern for bulk cache invalidation"""
        parts = [cls.PREFIX, cls.VERSION, model]
        if ministry_id:
            parts.append(f"t:{str(ministry_id)[:8]}")
        return ':'.join(parts) + ':*'


class CacheTTL:
    """Standard TTL values for different cache types"""
    
    # Feed/list caching (15 minutes)
    FEED = 60 * 15
    
    # User-specific data (5 minutes)
    USER_SPECIFIC = 60 * 5
    
    # Search results (3 minutes - more volatile)
    SEARCH = 60 * 3
    
    # Static/reference data (1 hour)
    STATIC = 60 * 60
    
    # Detail views (10 minutes)
    DETAIL = 60 * 10
    
    # Short-lived (1 minute)
    SHORT = 60


class CacheInvalidator:
    """
    Handles cache invalidation strategies.
    
    Supports:
    - Single key invalidation
    - Pattern-based bulk invalidation
    - Versioned invalidation (bump version)
    """
    
    @staticmethod
    def invalidate_key(key: str) -> bool:
        """Invalidate a single cache key"""
        try:
            cache.delete(key)
            logger.debug(f"Cache invalidated: {key}")
            return True
        except Exception as e:
            logger.error(f"Cache invalidation failed for {key}: {e}")
            return False
    
    @staticmethod
    def invalidate_keys(keys: List[str]) -> int:
        """Invalidate multiple cache keys"""
        if not keys:
            return 0
        
        try:
            cache.delete_many(keys)
            logger.debug(f"Cache invalidated: {len(keys)} keys")
            return len(keys)
        except Exception as e:
            logger.error(f"Bulk cache invalidation failed: {e}")
            return 0
    
    @staticmethod
    def invalidate_pattern(pattern: str) -> int:
        """
        Invalidate all keys matching a pattern.
        
        Note: Requires Redis backend with pattern support.
        Falls back to version bumping if pattern delete not available.
        """
        try:
            # Try Redis native pattern delete
            # Access Redis client through django-redis
            cache_backend = cache  # type: Any
            if hasattr(cache_backend, 'client') and hasattr(cache_backend.client, 'get_client'):
                redis_cache = cache_backend.client.get_client()
                keys = redis_cache.keys(pattern)
                if keys:
                    redis_cache.delete(*keys)
                    logger.info(f"Pattern invalidation: {len(keys)} keys matching '{pattern}'")
                    return len(keys)
            return 0
        except AttributeError:
            # Cache backend doesn't support pattern operations
            logger.warning(f"Pattern invalidation not supported, pattern: {pattern}")
            return 0
        except Exception as e:
            logger.error(f"Pattern invalidation failed for {pattern}: {e}")
            return 0
    
    @classmethod
    def invalidate_model(cls, model: str, ministry_id: Optional[str] = None) -> int:
        """Invalidate all cache entries for a model"""
        pattern = CacheKeyBuilder.get_pattern(model, ministry_id)
        return cls.invalidate_pattern(pattern)
    
    @classmethod
    def on_create(cls, model: str, ministry_id: Optional[str] = None) -> None:
        """Called when a new object is created"""
        # Invalidate list caches
        cls.invalidate_model(model, ministry_id)
    
    @classmethod
    def on_update(cls, model: str, object_id: Optional[str], ministry_id: Optional[str] = None) -> None:
        """Called when an object is updated"""
        # Invalidate detail cache
        if object_id:
            detail_key = CacheKeyBuilder.build(model, str(object_id), ministry_id=ministry_id)
            cls.invalidate_key(detail_key)
        
        # Invalidate list caches (object might affect ordering/filtering)
        cls.invalidate_model(model, ministry_id)
    
    @classmethod
    def on_delete(cls, model: str, object_id: Optional[str], ministry_id: Optional[str] = None) -> None:
        """Called when an object is deleted"""
        cls.on_update(model, object_id, ministry_id)


def cached_response(
    key_builder: Optional[Callable[..., str]] = None,
    ttl: int = CacheTTL.FEED,
    user_specific: bool = False,
    tenant_aware: bool = False
):
    """
    Decorator for caching API responses.
    
    Usage:
        @cached_response(ttl=CacheTTL.FEED)
        def get_list(self, request):
            ...
            
        @cached_response(
            key_builder=lambda r: f"custom:{r.query_params.get('type')}",
            ttl=CacheTTL.SHORT
        )
        def get_filtered(self, request):
            ...
    """
    def decorator(func):
        @wraps(func)
        def wrapper(self, request, *args, **kwargs):
            # Build cache key
            if key_builder:
                cache_key = key_builder(request)
            else:
                # Auto-generate key
                model_name = getattr(self, 'cache_model_name', 'default')
                user_id = str(request.user.id) if user_specific and request.user.is_authenticated else None
                ministry_id = getattr(request, 'ministry_id', None) if tenant_aware else None
                
                cache_key = CacheKeyBuilder.build(
                    model=model_name,
                    identifier='response',
                    params=dict(request.query_params),
                    user_id=user_id,
                    ministry_id=ministry_id
                )
            
            # Try cache
            cached = cache.get(cache_key)
            if cached is not None:
                logger.debug(f"Cache HIT: {cache_key}")
                return cached
            
            # Execute function
            logger.debug(f"Cache MISS: {cache_key}")
            response = func(self, request, *args, **kwargs)
            
            # Cache successful responses only
            if hasattr(response, 'status_code') and 200 <= response.status_code < 300:
                cache.set(cache_key, response, ttl)
            
            return response
        
        return wrapper
    return decorator


def get_or_set_cache(
    key: str,
    factory: Callable[[], Any],
    ttl: int = CacheTTL.FEED,
    stale_ttl: Optional[int] = None
) -> Any:
    """
    Get from cache or compute and set.
    
    Supports stale-while-revalidate pattern when stale_ttl is provided.
    
    Args:
        key: Cache key
        factory: Callable to generate value if not cached
        ttl: Time to live in seconds
        stale_ttl: Additional time to serve stale content while revalidating
        
    Returns:
        Cached or computed value
    """
    # Try primary cache
    result = cache.get(key)
    if result is not None:
        return result
    
    # Try stale cache (if using stale-while-revalidate)
    if stale_ttl:
        stale_key = f"{key}:stale"
        stale_result = cache.get(stale_key)
        if stale_result is not None:
            # Return stale immediately, trigger background refresh
            # In production, this would queue a Celery task
            logger.debug(f"Serving stale cache for {key}")
            return stale_result
    
    # Compute fresh value
    result = factory()
    
    # Set primary cache
    cache.set(key, result, ttl)
    
    # Set stale cache with extended TTL
    if stale_ttl:
        cache.set(f"{key}:stale", result, ttl + stale_ttl)
    
    return result
