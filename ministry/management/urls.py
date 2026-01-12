"""Ministry management URL configuration"""
from django.urls import path
from .views import (
    MinistryDetailView,
    StaffServiceListView,
    StaffServiceDetailView,
    StaffServicePasswordResetView,
    StaffServiceStatusToggleView
)

app_name = 'management'

urlpatterns = [
    # Ministry self-management
    path('', MinistryDetailView.as_view(), name='detail'),
    
    # Staff Service Management (Ministry Admin)
    path('staff-services/', StaffServiceListView.as_view(), name='staff_service_list'),
    path('staff-services/<uuid:staff_service_id>/', StaffServiceDetailView.as_view(), name='staff_service_detail'),
    path('staff-services/<uuid:staff_service_id>/reset-password/', StaffServicePasswordResetView.as_view(), name='staff_service_reset_password'),
    path('staff-services/<uuid:staff_service_id>/toggle-status/', StaffServiceStatusToggleView.as_view(), name='staff_service_toggle_status'),
]
