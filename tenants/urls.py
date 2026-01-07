"""
Tenants App URL Configuration

Routes for multi-tenant management:
- /citizen/ - Citizens browse ministries (auth required)
- /me/ - Ministry self-management
- /admin/ - Super admin tenant management
"""
from django.urls import path, include

app_name = 'tenants'

urlpatterns = [
    # Citizen endpoints (must be logged in via OTP)
    path('citizen/', include('tenants.public.urls')),
    
    # Ministry self-management (authenticated ministry members)
    path('me/', include('tenants.management.urls')),
    
    # Super admin endpoints
    path('admin/', include('tenants.admin.urls')),
]
