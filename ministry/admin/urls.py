"""Super admin ministry URL configuration"""
from django.urls import path
from .views import (
    SuperAdminMinistryListView,
    SuperAdminMinistryDetailView,
    SuperAdminMinistryDeletedListView,
    SuperAdminMinistryRestoreView,
    SuperAdminMinistryHardDeleteView,
    SuperAdminMinistryResetPasswordView,
    SuperAdminMinistryActivateView,
    SuperAdminMinistrySuspendView,
    SuperAdminMinistryAddStaffView,
    SuperAdminMinistryUsersView,
    SuperAdminMinistryUserDetailView,
)

app_name = 'admin'

urlpatterns = [
    # Ministry management
    path('', SuperAdminMinistryListView.as_view(), name='list'),
    path('deleted/', SuperAdminMinistryDeletedListView.as_view(), name='deleted_list'),
    path('<uuid:pk>/', SuperAdminMinistryDetailView.as_view(), name='detail'),
    path('<uuid:pk>/activate/', SuperAdminMinistryActivateView.as_view(), name='activate'),
    path('<uuid:pk>/suspend/', SuperAdminMinistrySuspendView.as_view(), name='suspend'),
    path('<uuid:pk>/restore/', SuperAdminMinistryRestoreView.as_view(), name='restore'),
    path('<uuid:pk>/hard-delete/', SuperAdminMinistryHardDeleteView.as_view(), name='hard_delete'),
    path('<uuid:pk>/reset-password/', SuperAdminMinistryResetPasswordView.as_view(), name='reset_password'),
    path('<uuid:pk>/add-staff/', SuperAdminMinistryAddStaffView.as_view(), name='add_staff'),
    
    # Staff user management for ministries
    path('<uuid:pk>/users/', SuperAdminMinistryUsersView.as_view(), name='users'),
    path('<uuid:pk>/users/<uuid:user_id>/', SuperAdminMinistryUserDetailView.as_view(), name='user_detail'),
]
