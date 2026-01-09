"""
Middleware for API Performance

Provides:
- GZip compression for large responses
- Cache control headers
- ETag handling
- Rate limiting headers
- Request timing
"""
import gzip
import time
import logging
from typing import Callable

from django.conf import settings
from django.http import HttpRequest, HttpResponse
from django.utils.cache import patch_cache_control
from django.utils.deprecation import MiddlewareMixin

logger = logging.getLogger(__name__)


class ResponseCompressionMiddleware(MiddlewareMixin):
    """
    GZip compression for large API responses.
    
    Only compresses:
    - Responses larger than min_length (default 1KB)
    - JSON/text content types
    - When client accepts gzip
    
    Settings:
        RESPONSE_COMPRESSION_MIN_LENGTH = 1024  # bytes
        RESPONSE_COMPRESSION_LEVEL = 6  # 1-9
    """
    
    COMPRESSIBLE_TYPES = [
        'application/json',
        'text/plain',
        'text/html',
        'text/xml',
        'application/xml',
    ]
    
    def __init__(self, get_response: Callable):
        self.get_response = get_response
        self.min_length = getattr(settings, 'RESPONSE_COMPRESSION_MIN_LENGTH', 1024)
        self.compression_level = getattr(settings, 'RESPONSE_COMPRESSION_LEVEL', 6)
    
    def __call__(self, request: HttpRequest) -> HttpResponse:
        response = self.get_response(request)  # type: ignore[misc]
        
        # Skip if already compressed or streaming
        if (
            response.get('Content-Encoding') or
            response.streaming or
            not self._accepts_gzip(request) or
            not self._should_compress(response)
        ):
            return response
        
        # Compress content
        content = response.content
        if len(content) < self.min_length:
            return response
        
        compressed = gzip.compress(content, compresslevel=self.compression_level)
        
        # Only use if compression is beneficial
        if len(compressed) < len(content):
            response.content = compressed  # type: ignore[misc]
            response['Content-Encoding'] = 'gzip'
            response['Content-Length'] = len(compressed)
            
            # Add Vary header for caching
            vary = response.get('Vary', '')
            if 'Accept-Encoding' not in vary:
                response['Vary'] = f"{vary}, Accept-Encoding".strip(', ')
        
        return response
    
    def _accepts_gzip(self, request: HttpRequest) -> bool:
        """Check if client accepts gzip encoding"""
        accept_encoding = request.META.get('HTTP_ACCEPT_ENCODING', '')
        return 'gzip' in accept_encoding.lower()
    
    def _should_compress(self, response: HttpResponse) -> bool:
        """Check if response should be compressed"""
        content_type = response.get('Content-Type', '')
        return any(ct in content_type for ct in self.COMPRESSIBLE_TYPES)


class CacheControlMiddleware(MiddlewareMixin):
    """
    Add appropriate cache control headers to responses.
    
    Features:
    - Different cache policies for different endpoints
    - Private caching for authenticated requests
    - No-cache for mutations
    
    Settings:
        API_CACHE_MAX_AGE = 300  # 5 minutes default
        API_CACHE_STALE_WHILE_REVALIDATE = 60
    """
    
    def __init__(self, get_response: Callable):
        self.get_response = get_response
        self.max_age = getattr(settings, 'API_CACHE_MAX_AGE', 300)
        self.stale_while_revalidate = getattr(
            settings, 
            'API_CACHE_STALE_WHILE_REVALIDATE', 
            60
        )
    
    def __call__(self, request: HttpRequest) -> HttpResponse:
        response = self.get_response(request)  # type: ignore[misc]
        
        # Skip if already has cache control
        if response.get('Cache-Control'):
            return response
        
        # No caching for mutations
        if request.method in ['POST', 'PUT', 'PATCH', 'DELETE']:
            patch_cache_control(response, no_cache=True, no_store=True)
            return response
        
        # No caching for errors
        if response.status_code >= 400:
            patch_cache_control(response, no_cache=True)
            return response
        
        # Private caching for authenticated requests
        if hasattr(request, 'user') and request.user.is_authenticated:
            patch_cache_control(
                response,
                private=True,
                max_age=self.max_age,
                stale_while_revalidate=self.stale_while_revalidate
            )
        else:
            # Public caching for anonymous requests
            patch_cache_control(
                response,
                public=True,
                max_age=self.max_age,
                stale_while_revalidate=self.stale_while_revalidate
            )
        
        return response


class RequestTimingMiddleware(MiddlewareMixin):
    """
    Add request timing headers for performance monitoring.
    
    Adds:
    - X-Request-Time: Request processing time in ms
    - Server-Timing: W3C Server Timing header
    """
    
    def __init__(self, get_response: Callable):
        self.get_response = get_response
    
    def __call__(self, request: HttpRequest) -> HttpResponse:
        start_time = time.perf_counter()
        
        response = self.get_response(request)  # type: ignore[misc]
        
        # Calculate processing time
        duration_ms = (time.perf_counter() - start_time) * 1000
        
        response['X-Request-Time'] = f"{duration_ms:.2f}ms"
        response['Server-Timing'] = f'total;dur={duration_ms:.2f}'
        
        # Log slow requests
        if duration_ms > 1000:  # > 1 second
            logger.warning(
                f"Slow request: {request.method} {request.path} took {duration_ms:.2f}ms"
            )
        
        return response


class RateLimitHeadersMiddleware(MiddlewareMixin):
    """
    Add rate limit information to response headers.
    
    Works with DRF throttling to expose limits to clients.
    
    Headers added:
    - X-RateLimit-Limit: Maximum requests allowed
    - X-RateLimit-Remaining: Requests remaining
    - X-RateLimit-Reset: Timestamp when limit resets
    """
    
    def __init__(self, get_response: Callable):
        self.get_response = get_response
    
    def __call__(self, request: HttpRequest) -> HttpResponse:
        response = self.get_response(request)  # type: ignore[misc]
        
        # Check if throttle info is available (set by DRF)
        throttle_info = getattr(request, '_throttle_info', None)
        if throttle_info:
            response['X-RateLimit-Limit'] = throttle_info.get('limit', 'unknown')
            response['X-RateLimit-Remaining'] = throttle_info.get('remaining', 'unknown')
            response['X-RateLimit-Reset'] = throttle_info.get('reset', 'unknown')
        
        # Add Retry-After for 429 responses
        if response.status_code == 429:
            retry_after = getattr(request, '_throttle_wait', 60)
            response['Retry-After'] = int(retry_after)
        
        return response


class SecurityHeadersMiddleware(MiddlewareMixin):
    """
    Add security headers to all responses.
    
    Headers:
    - X-Content-Type-Options: nosniff
    - X-Frame-Options: DENY
    - Referrer-Policy: strict-origin-when-cross-origin
    """
    
    def __init__(self, get_response: Callable):
        self.get_response = get_response
    
    def __call__(self, request: HttpRequest) -> HttpResponse:
        response = self.get_response(request)  # type: ignore[misc]
        
        response['X-Content-Type-Options'] = 'nosniff'
        response['X-Frame-Options'] = 'DENY'
        response['Referrer-Policy'] = 'strict-origin-when-cross-origin'
        
        # API responses don't need XSS protection header (JSON only)
        if 'application/json' in response.get('Content-Type', ''):
            response['X-XSS-Protection'] = '0'
        
        return response


class APIVersionMiddleware(MiddlewareMixin):
    """
    Handle API versioning via headers or URL prefix.
    
    Supports:
    - Accept header versioning: Accept: application/json; version=1
    - Custom header: X-API-Version: 1
    - URL prefix: /api/v1/...
    
    Sets request.api_version for use in views.
    """
    
    DEFAULT_VERSION = '1'
    
    def __init__(self, get_response: Callable):
        self.get_response = get_response
    
    def __call__(self, request: HttpRequest) -> HttpResponse:
        # Try custom header first
        version = request.META.get('HTTP_X_API_VERSION')
        
        # Try Accept header
        if not version:
            accept = request.META.get('HTTP_ACCEPT', '')
            if 'version=' in accept:
                try:
                    version = accept.split('version=')[1].split(';')[0].strip()
                except IndexError:
                    pass
        
        # Try URL prefix
        if not version:
            path = request.path
            if path.startswith('/api/v'):
                try:
                    version = path.split('/')[2][1:]  # Extract from /api/v1/...
                except IndexError:
                    pass
        
        # Set default
        request.api_version = version or self.DEFAULT_VERSION  # type: ignore[attr-defined]
        
        response = self.get_response(request)  # type: ignore[misc]
        
        # Add version to response
        response['X-API-Version'] = request.api_version  # type: ignore[attr-defined]
        
        return response
