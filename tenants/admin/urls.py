"""Super admin tenant URL configuration"""
from django.urls import path
from .views import (
    SuperAdminTenantListView,
    SuperAdminTenantDetailView,
    SuperAdminTenantActivateView,
    SuperAdminTenantSuspendView,
    SuperAdminTenantAddStaffView,
    SuperAdminTenantUsersView,
    SuperAdminTenantUserDetailView,
)

app_name = 'admin'

urlpatterns = [
    # Ministry management
    path('', SuperAdminTenantListView.as_view(), name='list'),
    path('<uuid:pk>/', SuperAdminTenantDetailView.as_view(), name='detail'),
    path('<uuid:pk>/activate/', SuperAdminTenantActivateView.as_view(), name='activate'),
    path('<uuid:pk>/suspend/', SuperAdminTenantSuspendView.as_view(), name='suspend'),
    path('<uuid:pk>/add-staff/', SuperAdminTenantAddStaffView.as_view(), name='add_staff'),
    
    # Staff user management for ministries
    path('<uuid:pk>/users/', SuperAdminTenantUsersView.as_view(), name='users'),
    path('<uuid:pk>/users/<uuid:user_id>/', SuperAdminTenantUserDetailView.as_view(), name='user_detail'),
]
