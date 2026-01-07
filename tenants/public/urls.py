"""Citizen tenant URL configuration"""
from django.urls import path
from .views import CitizenTenantListView, CitizenTenantDetailView

app_name = 'citizen'

urlpatterns = [
    path('', CitizenTenantListView.as_view(), name='list'),
    path('<slug:slug>/', CitizenTenantDetailView.as_view(), name='detail'),
]
