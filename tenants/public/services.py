"""
Public Tenant Service

Handles public-facing tenant operations.
No authentication required.
"""
import logging
from django.core.cache import cache
from tenants.models import Tenant
from tenants.serializers import TenantPublicSerializer

logger = logging.getLogger(__name__)


class PublicTenantService:
    """Service for public tenant operations"""
    
    CACHE_KEY = "public_tenants_list"
    CACHE_TIMEOUT = 3600  # 1 hour
    
    @staticmethod
    def get_list(request=None):
        """
        Get list of active tenants (ministries).
        
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            # Check cache first
            cached = cache.get(PublicTenantService.CACHE_KEY)
            if cached:
                logger.debug("[public] Returning cached tenant list")
                return True, {
                    "success": True,
                    "data": cached,
                    "cached": True
                }, 200
            
            # Query active tenants
            tenants = Tenant.objects.filter(
                status=Tenant.Status.ACTIVE
            ).order_by('name')
            
            context = {'request': request} if request else {}
            data = TenantPublicSerializer(tenants, many=True, context=context).data
            
            # Cache the result
            cache.set(PublicTenantService.CACHE_KEY, data, PublicTenantService.CACHE_TIMEOUT)
            
            logger.info(f"[public] Fetched {len(data)} active tenants")
            
            return True, {
                "success": True,
                "data": data,
                "count": len(data)
            }, 200
            
        except Exception as e:
            logger.error(f"[public] Tenant list error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch ministries"
            }, 500
    
    @staticmethod
    def get_detail(slug, request=None):
        """
        Get public details of a tenant by slug.
        
        Args:
            slug: Tenant slug
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        try:
            cache_key = f"public_tenant_{slug}"
            cached = cache.get(cache_key)
            
            if cached:
                return True, {"success": True, "data": cached}, 200
            
            tenant = Tenant.objects.get(slug=slug, status=Tenant.Status.ACTIVE)
            
            context = {'request': request} if request else {}
            data = TenantPublicSerializer(tenant, context=context).data
            
            cache.set(cache_key, data, PublicTenantService.CACHE_TIMEOUT)
            
            return True, {"success": True, "data": data}, 200
            
        except Tenant.DoesNotExist:
            return False, {
                "success": False,
                "error": "Ministry not found"
            }, 404
        except Exception as e:
            logger.error(f"[public] Tenant detail error: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch ministry details"
            }, 500
