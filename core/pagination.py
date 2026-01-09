"""
Cursor-Based Pagination for Flutter Mobile/Web Apps

Features:
- Cursor-based pagination (default) for infinite scroll
- Offset-based fallback for search results
- Bidirectional scrolling support
- Redis caching integration
- Timezone-aware ordering
- Multi-field sorting

Response Format:
{
    "next": "cursor_string",
    "previous": "cursor_string",
    "has_more": true,
    "results": [...],
    "metadata": {"page_size": 20, "estimated_total": 1000}
}
"""
import base64
import logging
from datetime import datetime
from typing import Optional, Tuple, List, Any, Dict
from collections import OrderedDict

from django.db.models import QuerySet, Q
from django.utils import timezone
from django.core.cache import cache
from django.conf import settings

from rest_framework.pagination import BasePagination
from rest_framework.response import Response
from rest_framework.request import Request
from rest_framework.utils.urls import replace_query_param, remove_query_param

from .utils.cache import CacheKeyBuilder, CacheTTL, get_or_set_cache

logger = logging.getLogger(__name__)


class CursorEncoder:
    """
    Encode/decode cursor values for pagination.
    
    Cursor format: base64({field}:{value}:{direction})
    Example: created_at:2024-01-01T12:00:00Z:next
    """
    
    SEPARATOR = '|'
    
    @classmethod
    def encode(cls, values: dict, direction: str = 'next') -> str:
        """
        Encode cursor values to string.
        
        Args:
            values: Dict of field names to values
            direction: 'next' or 'prev'
        """
        parts = []
        for field, value in values.items():
            # Handle datetime
            if isinstance(value, datetime):
                value = value.isoformat()
            parts.append(f"{field}:{value}")
        
        parts.append(f"dir:{direction}")
        cursor_str = cls.SEPARATOR.join(parts)
        
        return base64.urlsafe_b64encode(cursor_str.encode()).decode()
    
    @classmethod
    def decode(cls, cursor: str) -> Tuple[dict, str]:
        """
        Decode cursor string to values.
        
        Returns:
            Tuple of (values_dict, direction)
        """
        try:
            decoded = base64.urlsafe_b64decode(cursor.encode()).decode()
            parts = decoded.split(cls.SEPARATOR)
            
            values = {}
            direction = 'next'
            
            for part in parts:
                field, value = part.split(':', 1)
                if field == 'dir':
                    direction = value
                else:
                    values[field] = value
            
            return values, direction
            
        except Exception as e:
            logger.warning(f"Invalid cursor: {cursor}, error: {e}")
            raise InvalidCursorError(f"Invalid cursor format: {cursor}")


class InvalidCursorError(Exception):
    """Raised when cursor cannot be decoded"""
    pass


class CursorPagination(BasePagination):
    """
    Cursor-based pagination for infinite scroll/lazy loading.
    
    Best for:
    - Feeds and timelines
    - Real-time data that changes frequently
    - Infinite scroll UIs
    
    Usage in ViewSet:
        pagination_class = CursorPagination
        
    Or with custom settings:
        class MyPagination(CursorPagination):
            page_size = 50
            ordering = '-created_at'
    """
    
    # Configuration
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100
    
    # Ordering (can be tuple for multi-field)
    ordering = '-created_at'
    ordering_query_param = 'ordering'
    
    # Cursor parameter name
    cursor_query_param = 'cursor'
    
    # Cache settings
    cache_enabled = True
    cache_ttl = CacheTTL.FEED
    cache_model_name = None  # Override in subclass or view
    
    def __init__(self):
        self.cursor = None
        self.cursor_direction = 'next'
        self.has_next = False
        self.has_prev = False
        self.next_cursor = None
        self.prev_cursor = None
        self.count = None
    
    def get_page_size(self, request: Request) -> int:
        """Get page size from request or default"""
        if self.page_size_query_param:
            try:
                page_size = int(request.query_params.get(
                    self.page_size_query_param, 
                    self.page_size
                ))
                return min(page_size, self.max_page_size)
            except (ValueError, TypeError):
                pass
        return self.page_size
    
    def get_ordering(self, request: Request) -> List[str]:
        """Get ordering fields from request or default"""
        ordering = request.query_params.get(
            self.ordering_query_param, 
            self.ordering
        )
        
        if isinstance(ordering, str):
            ordering = [o.strip() for o in ordering.split(',')]
        
        return ordering if isinstance(ordering, (list, tuple)) else [ordering]
    
    def _get_ordering_field(self, ordering: str) -> Tuple[str, bool]:
        """Extract field name and direction from ordering string"""
        if ordering.startswith('-'):
            return ordering[1:], True  # descending
        return ordering, False  # ascending
    
    def paginate_queryset(
        self, 
        queryset: QuerySet, 
        request: Request, 
        view=None
    ) -> Optional[List]:
        """
        Paginate the queryset using cursor-based pagination.
        """
        self.request = request
        self.view = view
        
        page_size = self.get_page_size(request)
        ordering = self.get_ordering(request)
        
        # Apply ordering to queryset
        queryset = queryset.order_by(*ordering)
        
        # Decode cursor if provided
        cursor_str = request.query_params.get(self.cursor_query_param)
        cursor_values = None
        
        if cursor_str:
            try:
                cursor_values, self.cursor_direction = CursorEncoder.decode(cursor_str)
            except InvalidCursorError:
                # Invalid cursor, start from beginning
                cursor_values = None
        
        # Build cursor filter
        if cursor_values:
            queryset = self._apply_cursor_filter(queryset, cursor_values, ordering)
        
        # Fetch one extra to determine if there are more results
        results = list(queryset[:page_size + 1])
        
        # Determine has_more
        if len(results) > page_size:
            self.has_next = True
            results = results[:page_size]
        else:
            self.has_next = False
        
        # Generate cursors
        if results:
            self.next_cursor = self._get_cursor_for_item(
                results[-1], ordering, 'next'
            ) if self.has_next else None
            
            self.prev_cursor = self._get_cursor_for_item(
                results[0], ordering, 'prev'
            ) if cursor_values else None
        
        # Estimate total count (cached)
        self.count = self._get_estimated_count(queryset, request)
        
        return results
    
    def _apply_cursor_filter(
        self, 
        queryset: QuerySet, 
        cursor_values: dict, 
        ordering: List[str]
    ) -> QuerySet:
        """Apply filter based on cursor position"""
        q_objects = Q()
        
        for order_field in ordering:
            field_name, is_descending = self._get_ordering_field(order_field)
            
            if field_name not in cursor_values:
                continue
            
            cursor_value = cursor_values[field_name]
            
            # Parse datetime values
            if 'T' in str(cursor_value):
                try:
                    cursor_value = datetime.fromisoformat(
                        cursor_value.replace('Z', '+00:00')
                    )
                except ValueError:
                    pass
            
            # Determine comparison operator based on direction and ordering
            if self.cursor_direction == 'next':
                if is_descending:
                    q_objects &= Q(**{f'{field_name}__lt': cursor_value})
                else:
                    q_objects &= Q(**{f'{field_name}__gt': cursor_value})
            else:  # prev
                if is_descending:
                    q_objects &= Q(**{f'{field_name}__gt': cursor_value})
                else:
                    q_objects &= Q(**{f'{field_name}__lt': cursor_value})
        
        return queryset.filter(q_objects)
    
    def _get_cursor_for_item(
        self, 
        item: Any, 
        ordering: List[str], 
        direction: str
    ) -> str:
        """Generate cursor string for an item"""
        values = {}
        
        for order_field in ordering:
            field_name, _ = self._get_ordering_field(order_field)
            value = getattr(item, field_name, None)
            if value is not None:
                values[field_name] = value
        
        return CursorEncoder.encode(values, direction)
    
    def _get_estimated_count(self, queryset: QuerySet, request: Request) -> int:
        """Get estimated total count (cached)"""
        cache_key = CacheKeyBuilder.build(
            model=self.cache_model_name or 'default',
            identifier='count',
            params={'base': 'true'},
            tenant_id=getattr(request, 'tenant_id', None)
        )
        
        def get_count():
            # Use count() for small tables, estimate for large ones
            try:
                # Try explain for PostgreSQL estimate
                from django.db import connection
                if connection.vendor == 'postgresql':
                    with connection.cursor() as cursor:
                        cursor.execute(
                            f"SELECT reltuples::BIGINT FROM pg_class WHERE relname = %s",
                            [queryset.model._meta.db_table]
                        )
                        row = cursor.fetchone()
                        if row and row[0] > 0:
                            return int(row[0])
            except Exception:
                pass
            
            # Fallback to actual count (limit for performance)
            return queryset.count()
        
        return get_or_set_cache(cache_key, get_count, ttl=CacheTTL.STATIC)
    
    def get_paginated_response(self, data: List) -> Response:
        """Return paginated response with metadata"""
        return Response(OrderedDict([
            ('next', self.next_cursor),
            ('previous', self.prev_cursor),
            ('has_more', self.has_next),
            ('results', data),
            ('metadata', OrderedDict([
                ('page_size', self.get_page_size(self.request)),
                ('estimated_total', self.count),
                ('ordering', self.get_ordering(self.request)),
            ]))
        ]))
    
    def get_paginated_response_schema(self, schema):
        """OpenAPI schema for paginated response"""
        return {
            'type': 'object',
            'properties': {
                'next': {'type': 'string', 'nullable': True},
                'previous': {'type': 'string', 'nullable': True},
                'has_more': {'type': 'boolean'},
                'results': schema,
                'metadata': {
                    'type': 'object',
                    'properties': {
                        'page_size': {'type': 'integer'},
                        'estimated_total': {'type': 'integer'},
                        'ordering': {'type': 'array', 'items': {'type': 'string'}},
                    }
                }
            }
        }


class OffsetPagination(BasePagination):
    """
    Offset-based pagination for search results.
    
    Best for:
    - Search results with scoring
    - Admin panels
    - Cases where "jump to page X" is needed
    
    Usage:
        pagination_class = OffsetPagination
    """
    
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100
    offset_query_param = 'offset'
    
    # Cache settings
    cache_enabled = True
    cache_ttl = CacheTTL.SEARCH
    
    def __init__(self):
        self.offset = 0
        self.limit: int = self.page_size
        self.count = 0
        self.request: Optional[Request] = None
    
    def get_page_size(self, request: Request) -> int:
        """Get page size from request"""
        try:
            size = int(request.query_params.get(
                self.page_size_query_param, 
                self.page_size
            ))
            return min(size, self.max_page_size)
        except (ValueError, TypeError):
            return self.page_size
    
    def paginate_queryset(
        self, 
        queryset: QuerySet, 
        request: Request, 
        view=None
    ) -> Optional[List]:
        """Paginate using offset/limit"""
        self.request = request
        self.limit = self.get_page_size(request)
        
        try:
            self.offset = int(request.query_params.get(
                self.offset_query_param, 0
            ))
            if self.offset < 0:
                self.offset = 0
        except (ValueError, TypeError):
            self.offset = 0
        
        # Get total count
        self.count = queryset.count()
        
        # Slice queryset
        return list(queryset[self.offset:self.offset + self.limit])
    
    def get_next_offset(self) -> Optional[int]:
        """Calculate next offset"""
        next_offset = self.offset + self.limit
        if next_offset >= self.count:
            return None
        return next_offset
    
    def get_previous_offset(self) -> Optional[int]:
        """Calculate previous offset"""
        if self.offset <= 0:
            return None
        return max(0, self.offset - self.limit)
    
    def get_paginated_response(self, data: List) -> Response:
        """Return paginated response"""
        next_offset = self.get_next_offset()
        prev_offset = self.get_previous_offset()
        
        return Response(OrderedDict([
            ('next', str(next_offset) if next_offset is not None else None),
            ('previous', str(prev_offset) if prev_offset is not None else None),
            ('has_more', next_offset is not None),
            ('results', data),
            ('metadata', OrderedDict([
                ('page_size', self.limit),
                ('offset', self.offset),
                ('total_count', self.count),
                ('total_pages', (self.count + self.limit - 1) // self.limit if self.limit else 0),
            ]))
        ]))


class FlutterPagination(CursorPagination):
    """
    Optimized pagination for Flutter apps.
    
    Inherits from CursorPagination with Flutter-specific defaults:
    - Smaller initial page size for faster first load
    - ETag support for conditional requests
    - Prefetch hints for images
    """
    
    page_size = 15  # Smaller for initial load
    max_page_size = 50
    
    def get_paginated_response(self, data: List) -> Response:
        """Enhanced response with Flutter optimization hints"""
        response = super().get_paginated_response(data)
        
        # Add prefetch hints for next page
        if self.has_next and response.data is not None:
            response.data['metadata']['prefetch_next'] = True
        
        return response


# Convenience classes for common use cases
class FeedPagination(CursorPagination):
    """Pagination for social feed-like content"""
    page_size = 20
    ordering = '-created_at'
    cache_ttl = CacheTTL.FEED


class SearchPagination(OffsetPagination):
    """Pagination for search results"""
    page_size = 25
    cache_ttl = CacheTTL.SEARCH


class AdminPagination(OffsetPagination):
    """Pagination for admin panels"""
    page_size = 50
    max_page_size = 200
    cache_ttl = CacheTTL.SHORT
