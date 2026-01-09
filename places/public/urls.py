"""
Public Places URL configuration

Public endpoints for place selection (NO authentication required).
"""
from django.urls import path
from .views import PublicPlaceListView, PublicPlaceDetailView

app_name = 'places_public'

urlpatterns = [
    # GET /api/places/public/ - List all active places (no auth)
    path('', PublicPlaceListView.as_view(), name='place_list'),
    
    # GET /api/places/public/<slug>/ - Get place by slug (no auth)
    path('<slug:slug>/', PublicPlaceDetailView.as_view(), name='place_detail'),
]
