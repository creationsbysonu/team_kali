"""
Simple caching layer for query results
"""
from typing import Any, Optional
from datetime import datetime, timedelta
from collections import OrderedDict
from threading import Lock
import hashlib


class LRUCache:
    """Thread-safe LRU cache with TTL support."""
    
    def __init__(self, max_size: int = 100, ttl_seconds: int = 3600):
        self.max_size = max_size
        self.ttl = timedelta(seconds=ttl_seconds)
        self._cache = OrderedDict()
        self._timestamps = {}
        self._lock = Lock()
        self._hits = 0
        self._misses = 0
    
    def _make_key(self, query: str) -> str:
        """Create cache key from query."""
        return hashlib.md5(query.encode('utf-8')).hexdigest()
    
    def get(self, query: str) -> Optional[Any]:
        """Get value from cache."""
        key = self._make_key(query)
        
        with self._lock:
            if key not in self._cache:
                self._misses += 1
                return None
            
            # Check TTL
            timestamp = self._timestamps.get(key)
            if timestamp and datetime.now() - timestamp > self.ttl:
                # Expired
                del self._cache[key]
                del self._timestamps[key]
                self._misses += 1
                return None
            
            # Move to end (most recently used)
            self._cache.move_to_end(key)
            self._hits += 1
            return self._cache[key]
    
    def set(self, query: str, value: Any):
        """Set value in cache."""
        key = self._make_key(query)
        
        with self._lock:
            # Remove oldest if cache full
            if len(self._cache) >= self.max_size and key not in self._cache:
                oldest_key = next(iter(self._cache))
                del self._cache[oldest_key]
                del self._timestamps[oldest_key]
            
            self._cache[key] = value
            self._cache.move_to_end(key)
            self._timestamps[key] = datetime.now()
    
    def clear(self):
        """Clear all cache entries."""
        with self._lock:
            self._cache.clear()
            self._timestamps.clear()
            self._hits = 0
            self._misses = 0
    
    def stats(self) -> dict:
        """Get cache statistics."""
        with self._lock:
            total = self._hits + self._misses
            hit_rate = (self._hits / total * 100) if total > 0 else 0
            
            return {
                "size": len(self._cache),
                "max_size": self.max_size,
                "hits": self._hits,
                "misses": self._misses,
                "hit_rate": round(hit_rate, 2),
                "ttl_seconds": self.ttl.total_seconds()
            }


# Global cache instances
query_cache = LRUCache(max_size=100, ttl_seconds=1800)  # 30 min TTL for queries
embedding_cache = LRUCache(max_size=500, ttl_seconds=3600)  # 1 hour TTL for embeddings
