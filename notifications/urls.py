"""
URL routing for Notification System.
"""

from django.urls import path
from .views import (
    NotificationListView,
    NotificationMarkReadView,
    NotificationMarkAllReadView,
    NotificationStatsView,
)

app_name = 'notifications'

urlpatterns = [
    # Notification endpoints
    path('list/', NotificationListView.as_view(), name='list_notifications'),
    path('mark-read/', NotificationMarkReadView.as_view(), name='mark_read'),
    path('mark-all-read/', NotificationMarkAllReadView.as_view(), name='mark_all_read'),
    path('stats/', NotificationStatsView.as_view(), name='notification_stats'),
]
