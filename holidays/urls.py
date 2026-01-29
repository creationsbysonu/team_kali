"""
URL routing for Holiday Management.
"""

from django.urls import path
from .views import (
    HolidayCreateView,
    HolidayUpdateView,
    HolidayDeleteView,
    HolidayListView,
    HolidayCalendarView
)

app_name = 'holidays'

urlpatterns = [
    # Ministry admin endpoints
    path('create/', HolidayCreateView.as_view(), name='create_holiday'),
    path('update/<uuid:holiday_id>/', HolidayUpdateView.as_view(), name='update_holiday'),
    path('delete/<uuid:holiday_id>/', HolidayDeleteView.as_view(), name='delete_holiday'),
    
    # Public endpoints (authenticated)
    path('list/', HolidayListView.as_view(), name='list_holidays'),
    path('calendar/', HolidayCalendarView.as_view(), name='holiday_calendar'),
]
