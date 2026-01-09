"""Public Ministry URL configuration"""
from django.urls import path
from .views import (
    PublicMinistryListView,
    PublicMinistryDetailView,
    PublicServiceListView,
)

app_name = 'public'

urlpatterns = [
    # List ministries by place
    path(
        '<slug:place_slug>/ministries/',
        PublicMinistryListView.as_view(),
        name='ministry_list'
    ),
    
    # Get ministry detail
    path(
        '<slug:place_slug>/ministries/<slug:ministry_slug>/',
        PublicMinistryDetailView.as_view(),
        name='ministry_detail'
    ),
    
    # List services by ministry
    path(
        '<slug:place_slug>/ministries/<slug:ministry_slug>/services/',
        PublicServiceListView.as_view(),
        name='service_list'
    ),
]
