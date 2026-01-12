"""Super admin place URL configuration"""
from django.urls import path
from .views import (
    SuperAdminPlaceListView,
    SuperAdminPlaceDetailView,
)

app_name = 'admin'

urlpatterns = [
    # Place management
    # GET /places/admin/ - List all places
    # POST /places/admin/ - Create new place
    path('', SuperAdminPlaceListView.as_view(), name='list'),
    
    # GET /places/admin/<uuid>/ - Get place details
    # PUT /places/admin/<uuid>/ - Update place (name)
    # DELETE /places/admin/<uuid>/?confirm=true - Hard delete place
    path('<uuid:pk>/', SuperAdminPlaceDetailView.as_view(), name='detail'),
]
