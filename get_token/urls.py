"""
Get Token URL Configuration

Citizen token booking flow endpoints.
"""
from django.urls import path
from .views import (
    MinistriesByPlaceView,
    MinistriesByPlaceSlugView,
    ServicesByMinistryView,
    ServicesByMinistrySlugView,
    ServiceDetailsView,
    BookTokenView,
    MyTokensView,
    CancelTokenView,
    CheckAvailabilityView
)

app_name = 'get_token'

urlpatterns = [
    # ========== Public Endpoints (No Auth Required) ==========
    
    # Step 1: Get ministries in a place (by UUID)
    # GET /get-token/places/<place_id>/ministries/
    path(
        'places/<uuid:place_id>/ministries/',
        MinistriesByPlaceView.as_view(),
        name='ministries_by_place'
    ),
    
    # Step 1 (Alternative): Get ministries in a place (by slug)
    # GET /get-token/places/<place_slug>/ministries/
    path(
        'places/<str:place_slug>/ministries/',
        MinistriesByPlaceSlugView.as_view(),
        name='ministries_by_place_slug'
    ),
    
    # Step 2: Get services in a ministry (by UUID)
    # GET /get-token/ministries/<ministry_id>/services/
    path(
        'ministries/<uuid:ministry_id>/services/',
        ServicesByMinistryView.as_view(),
        name='services_by_ministry'
    ),
    
    # Step 2 (Alternative): Get services in a ministry (by slug)
    # GET /get-token/<place_slug>/<ministry_slug>/services/
    path(
        '<str:place_slug>/<str:ministry_slug>/services/',
        ServicesByMinistrySlugView.as_view(),
        name='services_by_ministry_slug'
    ),
    
    # Step 3: Get service details (queue config, officials, availability)
    # GET /get-token/services/<service_id>/details/
    path(
        'services/<uuid:service_id>/details/',
        ServiceDetailsView.as_view(),
        name='service_details'
    ),
    
    # Quick availability check
    # GET /get-token/services/<service_id>/availability/
    path(
        'services/<uuid:service_id>/availability/',
        CheckAvailabilityView.as_view(),
        name='service_availability'
    ),
    
    # ========== Protected Endpoints (Auth Required) ==========
    
    # Step 4: Book a token
    # POST /get-token/book/
    path(
        'book/',
        BookTokenView.as_view(),
        name='book_token'
    ),
    
    # Get user's tokens
    # GET /get-token/my-tokens/
    path(
        'my-tokens/',
        MyTokensView.as_view(),
        name='my_tokens'
    ),
    
    # Cancel a token
    # POST /get-token/cancel/<token_id>/
    path(
        'cancel/<uuid:token_id>/',
        CancelTokenView.as_view(),
        name='cancel_token'
    ),
]
