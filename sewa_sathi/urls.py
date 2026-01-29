from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('auth/', include('authentication.urls', namespace='authentication')),
    path('places/', include('places.urls', namespace='places')),
    path('ministry/', include('ministry.urls', namespace='ministry')),
    path('staff/', include('staff.urls', namespace='staff')),
    
    # Queue Management System URLs
    path('attendance/', include('attendance.urls', namespace='attendance')),
    path('holidays/', include('holidays.urls', namespace='holidays')),
    path('officials/', include('officials.urls', namespace='officials')),
    path('queue/', include('queue_management.urls', namespace='queue_management')),
    path('api/queue/', include('queue_management.urls', namespace='queue_management_api')),  # API prefix for Flutter
    path('notifications/', include('notifications.urls', namespace='notifications')),
    
    # Mobile App URLs
    path('api/mobile/', include('mobile_initial.urls', namespace='mobile_initial')),
    
    # Citizen Token Booking (Flutter App)
    path('api/get-token/', include('get_token.urls', namespace='get_token')),
    
    # Citizen API v1 - Optimized for Flutter (with pagination & caching)
    path('api/citizen/v1/', include('citizen_api.urls', namespace='citizen_api')),
    
    # Notice Portal URLs
    path('api/public/notices/', include('notices.public.urls', namespace='notices_public')),  # Public (no auth) for mobile app
    path('api/notices/', include('notices.urls', namespace='notices')),  # Authenticated citizen endpoints
    path('api/admin/notices/', include('notices.admin_panel.urls', namespace='notices_admin')),  # Ministry admin endpoints
    
    # Chat API (HTTP backup for WebSocket)
    path('api/chat/', include('citizen_chat.urls', namespace='citizen_chat')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
