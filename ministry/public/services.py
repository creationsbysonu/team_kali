"""
Public Ministry Service

Handles public-facing ministry operations.
No authentication required.
"""
import logging
from django.core.cache import cache
from ministry.models import Ministry
from ministry.serializers import MinistryPublicSerializer
from services.models import Service

logger = logging.getLogger(__name__)


class PublicMinistryService:
    """Service for public ministry operations"""
    
    CACHE_KEY = "public_ministries_list"
    CACHE_TIMEOUT = 3600  # 1 hour
    
    @staticmethod
    def get_ministries_by_place(place_slug, request=None):
        """
        Get list of active ministries for a place.
        
        Args:
            place_slug: Place slug
            request: HTTP request for building URLs
        
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            from places.models import Place
            
            cache_key = f"public_ministries_{place_slug}"
            cached = cache.get(cache_key)
            if cached:
                logger.debug(f"[public] Returning cached ministries for {place_slug}")
                return True, {"success": True, "data": cached, "cached": True}, 200
            
            # Verify place exists
            place = Place.objects.filter(slug=place_slug, is_active=True).first()
            if not place:
                return False, {"success": False, "error": "Place not found"}, 404
            
            # Query active ministries
            ministries = Ministry.objects.filter(
                place=place,
                status=Ministry.Status.ACTIVE
            ).order_by('name')
            
            context = {'request': request} if request else {}
            data = MinistryPublicSerializer(ministries, many=True, context=context).data
            
            # Cache the result
            cache.set(cache_key, data, PublicMinistryService.CACHE_TIMEOUT)
            
            logger.info(f"[public] Fetched {len(data)} ministries for {place_slug}")
            
            return True, {
                "success": True,
                "data": data,
                "place": {"name": place.name, "slug": place.slug},
                "count": len(data)
            }, 200
            
        except Exception as e:
            logger.error(f"[public] Ministry list error: {str(e)}")
            return False, {"success": False, "error": "Failed to fetch ministries"}, 500
    
    @staticmethod
    def get_ministry_detail(place_slug, ministry_slug, request=None):
        """
        Get public details of a ministry by slug.
        
        Args:
            place_slug: Place slug
            ministry_slug: Ministry slug
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            from places.models import Place
            
            cache_key = f"public_ministry_{place_slug}_{ministry_slug}"
            cached = cache.get(cache_key)
            
            if cached:
                return True, {"success": True, "data": cached}, 200
            
            # Verify place exists
            place = Place.objects.filter(slug=place_slug, is_active=True).first()
            if not place:
                return False, {"success": False, "error": "Place not found"}, 404
            
            ministry = Ministry.objects.get(
                place=place,
                slug=ministry_slug,
                status=Ministry.Status.ACTIVE
            )
            
            context = {'request': request} if request else {}
            data = MinistryPublicSerializer(ministry, context=context).data
            
            cache.set(cache_key, data, PublicMinistryService.CACHE_TIMEOUT)
            
            return True, {"success": True, "data": data}, 200
            
        except Ministry.DoesNotExist:
            return False, {"success": False, "error": "Ministry not found"}, 404
        except Exception as e:
            logger.error(f"[public] Ministry detail error: {str(e)}")
            return False, {"success": False, "error": "Failed to fetch ministry details"}, 500

    @staticmethod
    def get_services_by_ministry(place_slug, ministry_slug, request=None):
        """
        Get list of active services for a ministry.
        
        Args:
            place_slug: Place slug
            ministry_slug: Ministry slug
            request: HTTP request for building URLs
        
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            from places.models import Place
            
            cache_key = f"public_services_{place_slug}_{ministry_slug}"
            cached = cache.get(cache_key)
            if cached:
                return True, {"success": True, "data": cached, "cached": True}, 200
            
            # Verify place exists
            place = Place.objects.filter(slug=place_slug, is_active=True).first()
            if not place:
                return False, {"success": False, "error": "Place not found"}, 404
            
            # Verify ministry exists
            ministry = Ministry.objects.filter(
                place=place,
                slug=ministry_slug,
                status=Ministry.Status.ACTIVE
            ).first()
            if not ministry:
                return False, {"success": False, "error": "Ministry not found"}, 404
            
            # Query active services
            services = Service.objects.filter(
                ministry=ministry,
                is_active=True,
                is_published=True
            ).order_by('display_order', 'name')
            
            data = []
            for service in services:
                data.append({
                    'id': str(service.id),
                    'name': service.name,
                    'slug': service.slug,
                    'short_description': service.short_description,
                    'service_type': service.service_type,
                    'processing_time': service.processing_time,
                    'fee_amount': str(service.fee_amount),
                    'icon': service.icon,
                    'is_featured': service.is_featured,
                })
            
            # Cache the result
            cache.set(cache_key, data, PublicMinistryService.CACHE_TIMEOUT)
            
            logger.info(f"[public] Fetched {len(data)} services for {place_slug}/{ministry_slug}")
            
            return True, {
                "success": True,
                "data": data,
                "ministry": {"name": ministry.name, "slug": ministry.slug},
                "count": len(data)
            }, 200
            
        except Exception as e:
            logger.error(f"[public] Service list error: {str(e)}")
            return False, {"success": False, "error": "Failed to fetch services"}, 500
