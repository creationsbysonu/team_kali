# Core utilities module
"""
Core utilities for Sewa Sathi Backend

Exports:
- Pagination classes for infinite scroll
- Caching utilities and mixins
- Query optimization mixins
- Base serializers
- Custom storage backends
"""

from .pagination import (
    CursorPagination,
    OffsetPagination,
    FlutterPagination,
    FeedPagination,
    SearchPagination,
    AdminPagination,
    InvalidCursorError,
)

from .mixins import (
    QueryOptimizationMixin,
    CacheMixin,
    ETagMixin,
    PaginatedCacheMixin,
    StaleWhileRevalidateMixin,
    OptimizedListMixin,
    FullyOptimizedMixin,
)

from .utils.cache import (
    CacheKeyBuilder,
    CacheTTL,
    CacheInvalidator,
    cached_response,
    get_or_set_cache,
)

from .serializers import (
    BaseModelSerializer,
    OptimizedSerializerMixin,
    DynamicFieldsMixin,
    cached_serializer_method,
)

from .storage import (
    LogoCloudinaryStorage,
    DocumentCloudinaryStorage,
    AvatarCloudinaryStorage,
)

__all__ = [
    # Pagination
    'CursorPagination',
    'OffsetPagination',
    'FlutterPagination',
    'FeedPagination',
    'SearchPagination',
    'AdminPagination',
    'InvalidCursorError',
    
    # Mixins
    'QueryOptimizationMixin',
    'CacheMixin',
    'ETagMixin',
    'PaginatedCacheMixin',
    'StaleWhileRevalidateMixin',
    'OptimizedListMixin',
    'FullyOptimizedMixin',
    
    # Cache utilities
    'CacheKeyBuilder',
    'CacheTTL',
    'CacheInvalidator',
    'cached_response',
    'get_or_set_cache',
    
    # Serializers
    'BaseModelSerializer',
    'OptimizedSerializerMixin',
    'DynamicFieldsMixin',
    'cached_serializer_method',
    
    # Storage
    'LogoCloudinaryStorage',
    'DocumentCloudinaryStorage',
    'AvatarCloudinaryStorage',
]
