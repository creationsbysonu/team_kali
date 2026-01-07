"""Tenant management URL configuration"""
from django.urls import path
from .views import (
    TenantDetailView,
    TenantSettingsView,
    TenantMemberListView,
    TenantMemberDetailView,
    TenantInvitationListView,
    TenantInvitationDetailView,
)

app_name = 'management'

urlpatterns = [
    # Tenant self-management
    path('', TenantDetailView.as_view(), name='detail'),
    path('settings/', TenantSettingsView.as_view(), name='settings'),
    
    # Member management
    path('members/', TenantMemberListView.as_view(), name='members'),
    path('members/<uuid:pk>/', TenantMemberDetailView.as_view(), name='member_detail'),
    
    # Invitation management
    path('invitations/', TenantInvitationListView.as_view(), name='invitations'),
    path('invitations/<uuid:pk>/', TenantInvitationDetailView.as_view(), name='invitation_detail'),
]
