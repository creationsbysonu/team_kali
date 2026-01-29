"""
URL routing for Officials App.
"""

from django.urls import path
from .views import (
    MinistryOfficialCreateView,
    MinistryOfficialListView,
    MinistryOfficialDetailView
)

app_name = 'officials'

urlpatterns = [
    # Officials CRUD
    path('', MinistryOfficialListView.as_view(), name='list'),
    path('create/', MinistryOfficialCreateView.as_view(), name='create'),
    path('<uuid:official_id>/', MinistryOfficialDetailView.as_view(), name='detail'),
]
