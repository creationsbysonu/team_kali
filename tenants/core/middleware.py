"""
Tenant Middleware

Sets the current tenant context from request headers, 
subdomain, or authenticated user.
"""
import logging
from django.utils.deprecation import MiddlewareMixin
from .context import set_current_tenant, clear_current_tenant

logger = logging.getLogger(__name__)


class TenantMiddleware(MiddlewareMixin):
    """
    Middleware to set tenant context from request.
    
    Tenant is determined by (in order of priority):
    1. X-Tenant-ID header (for API clients)
    2. Authenticated user's tenant membership
    """
    
    def process_request(self, request):
        tenant = None
        
        # 1. Try X-Tenant-ID header first (for API/dashboard)
        tenant_id = request.headers.get('X-Tenant-ID')
        if tenant_id:
            try:
                from tenants.models import Tenant
                tenant = Tenant.objects.get(id=tenant_id, status='active')
                logger.debug(f"[tenant] Set from header: {tenant.slug}")
            except Exception as e:
                logger.warning(f"[tenant] Invalid tenant ID in header: {tenant_id}")
        
        # 2. Try from authenticated user's membership
        if not tenant and hasattr(request, 'user') and request.user.is_authenticated:
            # For staff/admin users, get their primary tenant
            membership = getattr(request.user, 'tenant_memberships', None)
            if membership:
                active_membership = membership.filter(is_active=True).first()
                if active_membership:
                    tenant = active_membership.tenant
                    logger.debug(f"[tenant] Set from user membership: {tenant.slug}")
        
        # Set tenant in context
        if tenant:
            set_current_tenant(tenant)
            request.tenant = tenant
        else:
            request.tenant = None
    
    def process_response(self, request, response):
        clear_current_tenant()
        return response
