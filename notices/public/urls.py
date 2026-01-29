"""
Public Notice URLs

Public endpoints for citizen mobile app.
No authentication required.
"""

from django.urls import path
from .views import (
    PublicNoticeListView,
    PublicNoticeDetailView,
    PublicNoticeFilterOptionsView,
)

app_name = 'notices_public'

urlpatterns = [
    # Filter options (for dropdowns)
    path('filters/', PublicNoticeFilterOptionsView.as_view(), name='filter_options'),
    
    # Notice list and detail
    path('', PublicNoticeListView.as_view(), name='list'),
    path('<uuid:notice_id>/', PublicNoticeDetailView.as_view(), name='detail'),
]
