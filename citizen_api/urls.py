"""
Citizen API - URL Configuration

Versioned API endpoints for Flutter mobile app.

URL Pattern: /citizen/v1/<resource>/

All endpoints follow RESTful conventions:
- GET for reading
- POST for creating
- No PUT/PATCH/DELETE for citizens (only staff can modify)
"""
from django.urls import path
from .views import (
    MinistriesListView,
    ServicesListView,
    ServiceDetailView,
    MyTokensListView,
    TokenDetailView,
    AvailabilityCheckView,
)

app_name = 'citizen_api'

urlpatterns = [
    # ==========================================================================
    # PUBLIC ENDPOINTS (No Authentication Required)
    # ==========================================================================
    
    # Phase 1: Get ministries in a place
    # GET /citizen/v1/places/{place}/ministries/
    # Accepts: UUID, slug, or numeric ID (e.g., "1" for first place)
    path(
        'places/<str:place_identifier>/ministries/',
        MinistriesListView.as_view(),
        name='ministries_list'
    ),
    
    # Phase 2: Get services in a ministry
    # GET /citizen/v1/ministries/{ministry}/services/
    # Accepts: UUID or slug
    path(
        'ministries/<str:ministry_identifier>/services/',
        ServicesListView.as_view(),
        name='services_list'
    ),
    
    # Phase 3: Get service details
    # GET /citizen/v1/services/{service_id}/
    path(
        'services/<uuid:service_id>/',
        ServiceDetailView.as_view(),
        name='service_detail'
    ),
    
    # Quick availability check
    # GET /citizen/v1/services/{service_id}/availability/
    path(
        'services/<uuid:service_id>/availability/',
        AvailabilityCheckView.as_view(),
        name='service_availability'
    ),
    
    # ==========================================================================
    # PROTECTED ENDPOINTS (Authentication Required)
    # ==========================================================================
    
    # Phase 4: Get user's tokens
    # GET /citizen/v1/tokens/
    path(
        'tokens/',
        MyTokensListView.as_view(),
        name='my_tokens'
    ),
    
    # Get token details
    # GET /citizen/v1/tokens/{token_id}/
    path(
        'tokens/<uuid:token_id>/',
        TokenDetailView.as_view(),
        name='token_detail'
    ),
]
