"""
Notice Admin Panel URL Configuration

URLs for ministry admins and staff admins to manage notices.

Ministry Admin:
- /notices/admin/                    - List/Create notices for ministry
- /notices/admin/<uuid>/             - Get/Update/Delete notice
- /notices/admin/stats/              - Notice statistics
- /notices/admin/<uuid>/retry-ingestion/ - Retry RAG ingestion
- /notices/admin/services/           - List services for dropdown

Staff Admin:
- /notices/staff/                    - List/Create notices (auto-attached to staff's service)
- /notices/staff/<uuid>/             - Get/Update/Delete notice
"""

from django.urls import path
from . import views

app_name = 'notices_admin'

urlpatterns = [
    # ========================================
    # MINISTRY ADMIN ROUTES
    # ========================================
    # Notice CRUD
    path('', views.MinistryNoticeListCreateView.as_view(), name='notice_list_create'),
    path('<uuid:notice_id>/', views.MinistryNoticeDetailView.as_view(), name='notice_detail'),
    
    # Statistics
    path('stats/', views.MinistryNoticeStatsView.as_view(), name='notice_stats'),
    
    # Retry ingestion
    path('<uuid:notice_id>/retry-ingestion/', views.NoticeRetryIngestionView.as_view(), name='retry_ingestion'),
    
    # Services dropdown
    path('services/', views.MinistryServicesForNoticeView.as_view(), name='services_list'),
    
    # ========================================
    # STAFF ADMIN ROUTES
    # ========================================
    # Staff notice CRUD (auto-attaches service)
    path('staff/', views.StaffNoticeListCreateView.as_view(), name='staff_notice_list_create'),
    path('staff/<uuid:notice_id>/', views.StaffNoticeDetailView.as_view(), name='staff_notice_detail'),
]
