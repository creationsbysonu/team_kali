"""
Places URL configuration

URL routing for places app.
"""
from django.urls import path, include

app_name = 'places'

urlpatterns = [
    # Public endpoints (no auth)
    path('public/', include('places.public.urls')),
]
