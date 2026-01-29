"""
Citizen Chat URL Configuration
"""

from django.urls import path
from .views import ChatView

app_name = 'citizen_chat'

urlpatterns = [
    path('', ChatView.as_view(), name='chat'),
]
