"""
ASGI config for sewa_sathi project.

It exposes the ASGI callable as a module-level variable named ``application``.

Supports both HTTP and WebSocket protocols:
- HTTP: Regular Django views via REST Framework
- WebSocket: Citizen chat via Django Channels

MOBILE DEVICE SUPPORT:
- Physical devices connect via LAN IP: ws://192.168.1.112:8000/ws/chat/
- AllowedHostsOriginValidator disabled in DEBUG for easier mobile testing
- In production, enable strict origin validation

For more information on this file, see
https://docs.djangoproject.com/en/6.0/howto/deployment/asgi/
"""

import os

from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sewa_sathi.settings')

# Initialize Django ASGI application early to ensure AppRegistry is populated
django_asgi_app = get_asgi_application()

from django.conf import settings
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.security.websocket import AllowedHostsOriginValidator
from citizen_chat.middleware import JWTAuthMiddleware
from citizen_chat.routing import websocket_urlpatterns

# WebSocket routing with JWT auth
websocket_application = JWTAuthMiddleware(
    URLRouter(websocket_urlpatterns)
)

# In DEBUG mode, allow all origins for easier mobile testing
# In production, use AllowedHostsOriginValidator for security
if settings.DEBUG:
    # Development: Allow any origin (mobile devices on LAN)
    ws_app = websocket_application
else:
    # Production: Validate origin against ALLOWED_HOSTS
    ws_app = AllowedHostsOriginValidator(websocket_application)

application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": ws_app,
})
