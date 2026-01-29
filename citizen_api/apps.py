"""
Citizen API App Configuration

Optimized API endpoints for Flutter mobile app with:
- Cursor-based pagination for infinite scroll
- Redis caching for fast responses
- Lightweight serializers for minimal payload
- Prefetch/select_related for N+1 query prevention
"""
from django.apps import AppConfig


class CitizenApiConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'citizen_api'
    verbose_name = 'Citizen API (Flutter Optimized)'
