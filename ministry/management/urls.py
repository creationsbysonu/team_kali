"""Ministry management URL configuration"""
from django.urls import path
from .views import MinistryDetailView

app_name = 'management'

urlpatterns = [
    # Ministry self-management (GET only for now)
    path('', MinistryDetailView.as_view(), name='detail'),
]
