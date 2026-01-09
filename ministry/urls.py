"""
Ministry App URL Configuration

Routes for ministry management:
- /public/ - Public ministry list (NO auth)
- /me/ - Ministry self-management
- /admin/ - Super admin ministry management
"""
from django.urls import path, include

app_name = 'ministry'

urlpatterns = [
    # Public endpoints (NO authentication required)
    path('public/', include('ministry.public.urls')),
    
    # Ministry self-management (authenticated ministry members)
    path('me/', include('ministry.management.urls')),
    
    # Super admin endpoints
    path('admin/', include('ministry.admin.urls')),
]
