# Pagination System Guide

A production-ready, cursor-based pagination system optimized for Flutter mobile and web apps with infinite scroll/lazy loading.

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Pagination Types](#pagination-types)
4. [Caching](#caching)
5. [Query Optimization](#query-optimization)
6. [Response Format](#response-format)
7. [Flutter Integration](#flutter-integration)
8. [Best Practices](#best-practices)
9. [Database Indexes](#database-indexes)

---

## Overview

This pagination system provides:

- **Cursor-based pagination** (default) - Best for feeds and infinite scroll
- **Offset-based pagination** - For search results and admin panels
- **Redis caching** with automatic invalidation
- **Query optimization** with select_related/prefetch_related
- **ETag support** for conditional requests
- **Compression** for large responses

---

## Quick Start

### Basic Usage

```python
from rest_framework.viewsets import ModelViewSet
from core.pagination import CursorPagination
from core.mixins import CacheMixin, QueryOptimizationMixin

class ServiceViewSet(QueryOptimizationMixin, CacheMixin, ModelViewSet):
    queryset = Service.objects.all()
    serializer_class = ServiceSerializer
    pagination_class = CursorPagination
    
    # Query optimization
    select_related_fields = ['category', 'tenant']
    prefetch_related_fields = ['tags']
    
    # Cache configuration
    cache_model_name = 'service'
    cache_ttl = 900  # 15 minutes
```

### Using Pre-configured Pagination Classes

```python
from core.pagination import FeedPagination, SearchPagination, AdminPagination

# For feeds/timelines
class NotificationViewSet(ModelViewSet):
    pagination_class = FeedPagination  # 20 items, cursor-based

# For search results
class SearchViewSet(ModelViewSet):
    pagination_class = SearchPagination  # 25 items, offset-based

# For admin panels
class AdminServiceViewSet(ModelViewSet):
    pagination_class = AdminPagination  # 50 items, offset-based
```

---

## Pagination Types

### 1. Cursor Pagination (Recommended for Mobile)

Best for:
- Infinite scroll feeds
- Real-time data that changes frequently
- Large datasets

```python
from core.pagination import CursorPagination

class MyPagination(CursorPagination):
    page_size = 20
    max_page_size = 100
    ordering = '-created_at'  # Must have index
```

**Request:**
```
GET /api/services/?page_size=20
GET /api/services/?cursor=eyJjcmVhdGVkX2F0IjoiMjAyNC0wMS0wMSJ9
```

**Response:**
```json
{
    "next": "eyJjcmVhdGVkX2F0IjoiMjAyNC0wMS0wMVQxMjowMDowMFoiLCJkaXIiOiJuZXh0In0=",
    "previous": null,
    "has_more": true,
    "results": [...],
    "metadata": {
        "page_size": 20,
        "estimated_total": 1523,
        "ordering": ["-created_at"]
    }
}
```

### 2. Offset Pagination

Best for:
- Search results with scoring
- Admin panels needing "page X of Y"
- Small to medium datasets

```python
from core.pagination import OffsetPagination

class SearchPagination(OffsetPagination):
    page_size = 25
    max_page_size = 100
```

**Request:**
```
GET /api/search/?q=health&offset=50&page_size=25
```

**Response:**
```json
{
    "next": "75",
    "previous": "25",
    "has_more": true,
    "results": [...],
    "metadata": {
        "page_size": 25,
        "offset": 50,
        "total_count": 150,
        "total_pages": 6
    }
}
```

### 3. Flutter-Optimized Pagination

```python
from core.pagination import FlutterPagination

class MobileServiceViewSet(ModelViewSet):
    pagination_class = FlutterPagination  # Smaller initial page, prefetch hints
```

---

## Caching

### Cache TTL Values

```python
from core.utils.cache import CacheTTL

CacheTTL.FEED = 900          # 15 minutes - feeds/lists
CacheTTL.USER_SPECIFIC = 300 # 5 minutes - user data
CacheTTL.SEARCH = 180        # 3 minutes - search results
CacheTTL.STATIC = 3600       # 1 hour - reference data
CacheTTL.DETAIL = 600        # 10 minutes - detail views
CacheTTL.SHORT = 60          # 1 minute - volatile data
```

### Using Cache Mixins

```python
from core.mixins import CacheMixin, PaginatedCacheMixin

class MyViewSet(CacheMixin, ModelViewSet):
    cache_model_name = 'mymodel'
    cache_ttl = CacheTTL.FEED
    cache_user_specific = False  # Set True for user-specific data
    cache_tenant_aware = True    # Include tenant in cache key
```

### Manual Cache Invalidation

```python
from core.utils.cache import CacheInvalidator

# After creating an object
CacheInvalidator.on_create(model='service', tenant_id=tenant.id)

# After updating an object
CacheInvalidator.on_update(model='service', object_id=service.id, tenant_id=tenant.id)

# After deleting an object
CacheInvalidator.on_delete(model='service', object_id=service.id, tenant_id=tenant.id)

# Invalidate all cache for a model
CacheInvalidator.invalidate_model('service', tenant_id=tenant.id)
```

### Stale-While-Revalidate Pattern

```python
from core.mixins import StaleWhileRevalidateMixin, CacheMixin

class FeedViewSet(StaleWhileRevalidateMixin, CacheMixin, ModelViewSet):
    stale_ttl = 300  # Serve stale for 5 minutes while refreshing
```

---

## Query Optimization

### Using QueryOptimizationMixin

```python
from core.mixins import QueryOptimizationMixin

class ServiceViewSet(QueryOptimizationMixin, ModelViewSet):
    queryset = Service.objects.all()
    
    # Always applied
    select_related_fields = ['category']
    prefetch_related_fields = ['tags']
    
    # List-specific (lighter)
    list_select_related = ['category']
    list_prefetch_related = []
    
    # Detail-specific (heavier)
    detail_select_related = ['category', 'tenant']
    detail_prefetch_related = ['tags', 'requirements', 'documents']
    
    # Field optimization
    only_fields = ['id', 'name', 'slug', 'logo', 'created_at']
    # OR
    defer_fields = ['description', 'long_content']
```

### Serializer Optimization

```python
from core.serializers import BaseModelSerializer, cached_serializer_method

class ServiceSerializer(BaseModelSerializer):
    category_name = serializers.SerializerMethodField()
    
    class Meta:
        model = Service
        fields = ['id', 'name', 'category_name', 'created_at']
    
    # Optimization hints for views
    select_related_fields = ['category']
    prefetch_related_fields = ['tags']
    
    @cached_serializer_method
    def get_category_name(self, obj):
        # This result is cached per-object in same serialization
        return obj.category.name if obj.category else None
```

---

## Response Format

### Standard Cursor Response

```json
{
    "next": "cursor_string_for_next_page",
    "previous": "cursor_string_for_previous_page",
    "has_more": true,
    "results": [
        {"id": "uuid", "name": "Item 1", ...},
        {"id": "uuid", "name": "Item 2", ...}
    ],
    "metadata": {
        "page_size": 20,
        "estimated_total": 1000,
        "ordering": ["-created_at"]
    }
}
```

### Flutter Usage

```dart
class PaginatedResponse<T> {
  final String? nextCursor;
  final String? previousCursor;
  final bool hasMore;
  final List<T> results;
  final PaginationMetadata metadata;
  
  Future<PaginatedResponse<T>> loadNext() async {
    if (!hasMore || nextCursor == null) return this;
    return api.get('/items/', params: {'cursor': nextCursor});
  }
}
```

---

## Flutter Integration

### Infinite Scroll Controller

```dart
class InfiniteScrollController<T> {
  String? _cursor;
  bool _hasMore = true;
  bool _isLoading = false;
  final List<T> items = [];
  
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    
    _isLoading = true;
    try {
      final response = await api.get('/items/', params: {
        'cursor': _cursor,
        'page_size': 20,
      });
      
      items.addAll(response.results);
      _cursor = response.next;
      _hasMore = response.hasMore;
    } finally {
      _isLoading = false;
    }
  }
  
  void reset() {
    _cursor = null;
    _hasMore = true;
    items.clear();
  }
}
```

### ETag Caching (Conditional Requests)

```dart
class CachedApiClient {
  final Map<String, String> _etags = {};
  final Map<String, dynamic> _cache = {};
  
  Future<dynamic> get(String url) async {
    final headers = <String, String>{};
    
    if (_etags.containsKey(url)) {
      headers['If-None-Match'] = _etags[url]!;
    }
    
    final response = await http.get(url, headers: headers);
    
    if (response.statusCode == 304) {
      // Use cached data
      return _cache[url];
    }
    
    // Store ETag and cache response
    if (response.headers['etag'] != null) {
      _etags[url] = response.headers['etag']!;
      _cache[url] = response.data;
    }
    
    return response.data;
  }
}
```

---

## Best Practices

### 1. Always Add Database Indexes

```python
class Service(models.Model):
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['-created_at']),  # For cursor pagination
            models.Index(fields=['status', '-created_at']),  # For filtered queries
            models.Index(fields=['tenant', '-created_at']),  # For tenant-scoped queries
        ]
```

### 2. Use Appropriate Pagination for Use Case

| Use Case | Pagination Type | Page Size |
|----------|-----------------|-----------|
| Mobile Feed | FlutterPagination | 15-20 |
| Web List | CursorPagination | 20-30 |
| Search Results | OffsetPagination | 20-25 |
| Admin Panel | AdminPagination | 50 |

### 3. Cache Invalidation Strategy

```python
# In your service layer
class ServiceService:
    @staticmethod
    def create_service(data, tenant):
        service = Service.objects.create(**data)
        CacheInvalidator.on_create('service', tenant_id=tenant.id)
        return service
    
    @staticmethod
    def update_service(service, data, tenant):
        # Update...
        CacheInvalidator.on_update('service', service.id, tenant_id=tenant.id)
```

### 4. Optimize for First Page Load

```python
class FlutterFeedPagination(FlutterPagination):
    # Smaller first page for faster initial load
    default_page_size = 15
    max_page_size = 30
    
    def get_page_size(self, request):
        cursor = request.query_params.get('cursor')
        if not cursor:
            return 10  # Even smaller for first load
        return super().get_page_size(request)
```

---

## Database Indexes

### Recommended Indexes for Pagination

```python
class MyModel(models.Model):
    class Meta:
        indexes = [
            # Primary pagination index
            models.Index(fields=['-created_at']),
            
            # Compound indexes for filtered pagination
            models.Index(fields=['status', '-created_at']),
            models.Index(fields=['tenant', '-created_at']),
            models.Index(fields=['category', '-created_at']),
            
            # For multi-field sorting
            models.Index(fields=['-updated_at', '-created_at']),
            
            # For search with ordering
            models.Index(fields=['name', '-created_at']),
        ]
```

### PostgreSQL-Specific Optimizations

```sql
-- Partial index for active items only
CREATE INDEX idx_active_services_created 
ON services (created_at DESC) 
WHERE status = 'active';

-- BRIN index for time-series data (more efficient for large tables)
CREATE INDEX idx_services_created_brin 
ON services USING BRIN (created_at);
```

---

## Middleware Configuration

Add to your `settings.py`:

```python
MIDDLEWARE = [
    # ... other middleware ...
    'core.middleware.ResponseCompressionMiddleware',
    'core.middleware.CacheControlMiddleware',
    'core.middleware.RequestTimingMiddleware',
    'core.middleware.SecurityHeadersMiddleware',
]

# Compression settings
RESPONSE_COMPRESSION_MIN_LENGTH = 1024  # Compress responses > 1KB
RESPONSE_COMPRESSION_LEVEL = 6  # 1-9, higher = more compression

# Cache control
API_CACHE_MAX_AGE = 300  # 5 minutes
API_CACHE_STALE_WHILE_REVALIDATE = 60  # Serve stale for 1 min
```

---

## Error Handling

### Invalid Cursor

```python
from core.pagination import InvalidCursorError

# The paginator handles this gracefully - returns first page
# But you can catch it explicitly:

try:
    paginator.paginate_queryset(queryset, request)
except InvalidCursorError:
    # Return first page or custom error
    pass
```

### Response for Invalid Cursor

```json
{
    "next": "new_cursor",
    "previous": null,
    "has_more": true,
    "results": [...],
    "metadata": {
        "page_size": 20,
        "estimated_total": 1000,
        "note": "Invalid cursor, returned first page"
    }
}
```
