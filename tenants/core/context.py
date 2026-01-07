"""
Tenant Context Manager

Thread-local storage for current tenant context.
Used by middleware to set tenant for each request.
"""
import threading

_thread_locals = threading.local()


def set_current_tenant(tenant):
    """Set tenant for current thread/request"""
    _thread_locals.tenant = tenant


def get_current_tenant():
    """Get tenant for current thread/request"""
    return getattr(_thread_locals, 'tenant', None)


def clear_current_tenant():
    """Clear tenant from current thread"""
    if hasattr(_thread_locals, 'tenant'):
        del _thread_locals.tenant


class TenantContext:
    """
    Context manager for tenant scope.
    
    Usage:
        with TenantContext(tenant):
            # All queries here are scoped to tenant
            applications = Application.objects.all()
    """
    
    def __init__(self, tenant):
        self.tenant = tenant
        self.previous_tenant = None
    
    def __enter__(self):
        self.previous_tenant = get_current_tenant()
        set_current_tenant(self.tenant)
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.previous_tenant:
            set_current_tenant(self.previous_tenant)
        else:
            clear_current_tenant()
