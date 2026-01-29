"""
URL Configuration for Mobile Profile Setup
"""
from django.urls import path
from .views import (
    ProfileStatusView,
    ProfileSetupView,
    PlacesListView,
    ProfileUpdateView
)

app_name = 'mobile_initial'

urlpatterns = [
    # Profile management
    path('profile/status/', ProfileStatusView.as_view(), name='profile_status'),
    path('profile/setup/', ProfileSetupView.as_view(), name='profile_setup'),
    path('profile/update/', ProfileUpdateView.as_view(), name='profile_update'),
    
    # Places list
    path('places/', PlacesListView.as_view(), name='places_list'),
]
