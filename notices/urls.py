"""
Notices URL Configuration
"""

from django.urls import path
from . import views

app_name = 'notices'

urlpatterns = [
    # Notice endpoints
    path('', views.NoticeListCreateView.as_view(), name='notice_list_create'),
    path('<uuid:pk>/', views.NoticeDetailView.as_view(), name='notice_detail'),
    
    # Reference data endpoints
    path('ministries/', views.MinistryListView.as_view(), name='ministry_list'),
    path('services/', views.ServiceListView.as_view(), name='service_list'),
]
