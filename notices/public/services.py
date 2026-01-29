"""
Public Notice Services

Business logic for public notice endpoints (mobile app).
No authentication required for reading notices.
"""

import logging
from django.core.cache import cache
from notices.models import Notice
from notices.serializers import NoticeListSerializer, NoticeDetailSerializer
from filters.services import NoticeFilterService

logger = logging.getLogger(__name__)


class PublicNoticeService:
    """
    Service class for public notice operations.
    Returns tuple: (success: bool, response_data: dict, status_code: int)
    """
    
    CACHE_TTL = 300  # 5 minutes cache
    
    @classmethod
    def list_notices(cls, query_params: dict, request=None):
        """
        Get paginated list of active notices.
        
        Filters:
        - ministry: UUID of ministry
        - service: UUID of service
        - search: Text search in title
        - file_type: pdf, png, jpg
        
        Args:
            query_params: Request query parameters
            request: HTTP request for URL building
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            # Build cache key from filters
            cache_key = cls._build_cache_key(query_params)
            
            # Try cache first (skip if request has page/cursor params)
            if not query_params.get('cursor') and not query_params.get('page'):
                cached = cache.get(cache_key)
                if cached:
                    logger.debug(f"Cache hit for notices: {cache_key}")
                    return True, cached, 200
            
            # Query notices
            queryset = Notice.objects.filter(
                is_active=True
            ).select_related(
                'ministry', 'service'
            ).only(
                'id', 'title', 'file', 'file_type', 'created_at',
                'ministry__id', 'ministry__name', 'ministry__slug', 'ministry__logo',
                'service__id', 'service__name', 'service__slug'
            ).order_by('-created_at')
            
            # Apply filters
            queryset = NoticeFilterService.apply(queryset, query_params)
            
            # Get count for metadata
            total_count = queryset.count()
            
            # Apply limit (default 20, max 50)
            limit = min(int(query_params.get('limit', 20)), 50)
            offset = int(query_params.get('offset', 0))
            
            notices = queryset[offset:offset + limit]
            
            # Serialize
            serializer = NoticeListSerializer(
                notices, 
                many=True, 
                context={'request': request}
            )
            
            response_data = {
                'success': True,
                'data': {
                    'results': serializer.data,
                    'count': total_count,
                    'limit': limit,
                    'offset': offset,
                    'has_more': (offset + limit) < total_count
                }
            }
            
            # Cache first page only
            if offset == 0 and not query_params.get('search'):
                cache.set(cache_key, response_data, cls.CACHE_TTL)
            
            return True, response_data, 200
            
        except Exception as e:
            logger.error(f"Error listing public notices: {str(e)}")
            return False, {
                'success': False,
                'error': 'Failed to fetch notices'
            }, 500
    
    @classmethod
    def get_notice_detail(cls, notice_id: str, request=None):
        """
        Get single notice detail by ID.
        
        Args:
            notice_id: UUID of the notice
            request: HTTP request for URL building
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            cache_key = f"notice_detail_{notice_id}"
            
            # Try cache
            cached = cache.get(cache_key)
            if cached:
                return True, cached, 200
            
            # Query
            notice = Notice.objects.select_related(
                'ministry', 'service'
            ).get(
                id=notice_id,
                is_active=True
            )
            
            serializer = NoticeDetailSerializer(
                notice,
                context={'request': request}
            )
            
            response_data = {
                'success': True,
                'data': serializer.data
            }
            
            # Cache for 10 minutes
            cache.set(cache_key, response_data, 600)
            
            return True, response_data, 200
            
        except Notice.DoesNotExist:
            return False, {
                'success': False,
                'error': 'Notice not found'
            }, 404
            
        except Exception as e:
            logger.error(f"Error getting notice detail: {str(e)}")
            return False, {
                'success': False,
                'error': 'Failed to fetch notice'
            }, 500
    
    @classmethod
    def get_filter_options(cls, request=None):
        """
        Get available filter options (ministries and services).
        
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            from ministry.models import Ministry
            from services.models import Service
            from ministry.serializers import MinistryListSerializer
            from services.serializers import ServicePublicListSerializer
            
            cache_key = "notice_filter_options"
            cached = cache.get(cache_key)
            if cached:
                return True, cached, 200
            
            # Get active ministries
            ministries = Ministry.objects.filter(
                status=Ministry.Status.ACTIVE
            ).order_by('name')
            
            # Get active services
            services = Service.objects.filter(
                is_active=True
            ).select_related('ministry').order_by('ministry__name', 'name')
            
            response_data = {
                'success': True,
                'data': {
                    'ministries': MinistryListSerializer(
                        ministries, 
                        many=True,
                        context={'request': request}
                    ).data,
                    'services': ServicePublicListSerializer(
                        services,
                        many=True,
                        context={'request': request}
                    ).data,
                    'file_types': [
                        {'value': 'pdf', 'label': 'PDF'},
                        {'value': 'png', 'label': 'PNG Image'},
                        {'value': 'jpg', 'label': 'JPG Image'},
                        {'value': 'jpeg', 'label': 'JPEG Image'},
                    ]
                }
            }
            
            cache.set(cache_key, response_data, cls.CACHE_TTL)
            
            return True, response_data, 200
            
        except Exception as e:
            logger.error(f"Error getting filter options: {str(e)}")
            return False, {
                'success': False,
                'error': 'Failed to fetch filter options'
            }, 500
    
    @staticmethod
    def _build_cache_key(params: dict) -> str:
        """Build a cache key from query parameters"""
        parts = ['public_notices']
        
        for key in ['ministry', 'service', 'file_type']:
            if params.get(key):
                parts.append(f"{key}={params[key]}")
        
        return '_'.join(parts)
