"""
Public Places Service

Service layer for public place endpoints.
NO authentication required - used for place selection.
"""
import logging
from django.core.cache import cache
from places.models import Place

logger = logging.getLogger(__name__)


class PublicPlaceService:
    """Service for public (unauthenticated) place operations"""
    
    CACHE_KEY = "public_active_places"
    CACHE_TIMEOUT = 300  # 5 minutes
    
    @staticmethod
    def get_active_places():
        """
        Get all ACTIVE places for selection dropdown.
        
        Returns minimal data needed for place selection:
        - id, name, slug
        
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Check cache first
            cached = cache.get(PublicPlaceService.CACHE_KEY)
            if cached:
                logger.debug("[public] Returning cached place list")
                return True, {
                    "success": True,
                    "data": cached
                }, 200
            
            # Query only ACTIVE places
            places = Place.objects.filter(
                is_active=True
            ).order_by('name').only('id', 'name', 'slug')
            
            # Build response
            place_list = []
            for place in places:
                place_list.append({
                    'id': str(place.id),
                    'name': place.name,
                    'slug': place.slug,
                })
            
            # Cache the result
            cache.set(
                PublicPlaceService.CACHE_KEY, 
                place_list, 
                PublicPlaceService.CACHE_TIMEOUT
            )
            
            logger.info(f"[public] Fetched {len(place_list)} active places")
            
            return True, {
                "success": True,
                "data": place_list
            }, 200
            
        except Exception as e:
            logger.error(f"[public] Error fetching places: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch places"
            }, 500
    
    @staticmethod
    def get_place_by_slug(slug):
        """
        Get place details by slug.
        
        Args:
            slug: Place slug (e.g., 'kathmandu')
            
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            place = Place.objects.filter(
                slug=slug,
                is_active=True
            ).only('id', 'name', 'slug').first()
            
            if not place:
                logger.warning(f"[public] Place not found or inactive: {slug}")
                return False, {
                    "success": False,
                    "error": "Place not found or inactive"
                }, 404
            
            place_data = {
                'id': str(place.id),
                'name': place.name,
                'slug': place.slug,
            }
            
            logger.info(f"[public] Fetched place: {slug}")
            
            return True, {
                "success": True,
                "data": place_data
            }, 200
            
        except Exception as e:
            logger.error(f"[public] Error fetching place {slug}: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch place details"
            }, 500
    
    @staticmethod
    def invalidate_cache():
        """Invalidate the public places cache"""
        cache.delete(PublicPlaceService.CACHE_KEY)
        logger.info("[public] Places cache invalidated")
