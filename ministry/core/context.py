"""
Ministry Context Manager

Thread-local storage for current ministry context.
Used by middleware to set ministry for each request.
"""
import threading

_thread_locals = threading.local()


def set_current_ministry(ministry):
    """Set ministry for current thread/request"""
    _thread_locals.ministry = ministry


def get_current_ministry():
    """Get ministry for current thread/request"""
    return getattr(_thread_locals, 'ministry', None)


def clear_current_ministry():
    """Clear ministry from current thread"""
    if hasattr(_thread_locals, 'ministry'):
        del _thread_locals.ministry


class MinistryContext:
    """
    Context manager for ministry scope.
    
    Usage:
        with MinistryContext(ministry):
            # All queries here are scoped to ministry
            services = Service.objects.all()
    """
    
    def __init__(self, ministry):
        self.ministry = ministry
        self.previous_ministry = None
    
    def __enter__(self):
        self.previous_ministry = get_current_ministry()
        set_current_ministry(self.ministry)
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.previous_ministry:
            set_current_ministry(self.previous_ministry)
        else:
            clear_current_ministry()
        return False
