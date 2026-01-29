"""
URL routing for Staff Attendance Management.
"""

from django.urls import path
from .views import (
    AttendanceMarkView,
    AttendanceBulkMarkView,
    AttendanceCalendarView,
    AttendanceDeleteView
)

app_name = 'attendance'

urlpatterns = [
    # Ministry admin endpoints
    path('mark/', AttendanceMarkView.as_view(), name='mark_attendance'),
    path('bulk-mark/', AttendanceBulkMarkView.as_view(), name='bulk_mark_attendance'),
    path('calendar/', AttendanceCalendarView.as_view(), name='attendance_calendar'),
    path('delete/<uuid:attendance_id>/', AttendanceDeleteView.as_view(), name='delete_attendance'),
]
