"""
Staff URL Configuration

Routes for staff management by ministry admins.
"""
from django.urls import path
from .views import (
    StaffListView,
    StaffDetailView,
    StaffResetPasswordView,
)

app_name = 'staff'

urlpatterns = [
    # Staff management (ministry admin)
    path('', StaffListView.as_view(), name='list'),
    path('<uuid:pk>/', StaffDetailView.as_view(), name='detail'),
    path('<uuid:pk>/reset-password/', StaffResetPasswordView.as_view(), name='reset_password'),
]
