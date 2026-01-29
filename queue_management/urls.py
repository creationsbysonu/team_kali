"""
URL routing for Queue Management System.
"""

from django.urls import path
from .views import (
    # Ministry admin
    QueueConfigurationView,
    EndOfDayAutoCancelView,
    
    # Staff admin (legacy)
    TodaysQueueView,
    TokenServedView,
    TokenNoShowView,
    
    # Staff admin panel (new)
    StaffActiveTokensView,
    StaffAllTokensView,
    StaffPendingTokensView,
    StaffMarkPendingView,
    StaffPendingEmailView,
    StaffPendingServedView,
    StaffStartServiceView,
    
    # Citizens
    QueueAvailabilityView,
    TokenBookingView,
    MyTokensView,
    TokenCancelView,
)
from .progress_views import (
    ProgressStepsCreateView,
    ProgressStepsListView,
    ProgressTrackingToggleView,
    TokenProgressView,
    CompleteProgressStepView,
    ProgressWorkbenchView,
)

app_name = 'queue_management'

urlpatterns = [
    # Ministry admin endpoints
    path('config/', QueueConfigurationView.as_view(), name='queue_configuration'),
    path('admin/end-of-day-cancel/', EndOfDayAutoCancelView.as_view(), name='end_of_day_auto_cancel'),
    
    # Progress tracking endpoints (Ministry admin)
    path('config/<uuid:config_id>/progress/steps/', ProgressStepsListView.as_view(), name='progress_steps_list'),
    path('config/<uuid:config_id>/progress/steps/create/', ProgressStepsCreateView.as_view(), name='progress_steps_create'),
    path('config/<uuid:config_id>/progress/enable/', ProgressTrackingToggleView.as_view(), name='progress_tracking_toggle'),
    
    # Progress workbench (Staff)
    path('staff/progress-workbench/', ProgressWorkbenchView.as_view(), name='progress_workbench'),
    path('progress/steps/<uuid:progress_id>/complete/', CompleteProgressStepView.as_view(), name='complete_progress_step'),
    
    # Staff admin endpoints (legacy - for backward compatibility)
    path('staff/today/', TodaysQueueView.as_view(), name='todays_queue'),
    path('staff/served/', TokenServedView.as_view(), name='mark_served'),
    path('staff/no-show/', TokenNoShowView.as_view(), name='mark_no_show'),
    
    # ========================================================
    # STAFF ADMIN PANEL ENDPOINTS (New Structure)
    # ========================================================
    # Active Tokens - shows WAITING and IN_SERVICE tokens
    path('staff/active-tokens/', StaffActiveTokensView.as_view(), name='staff_active_tokens'),
    
    # All Tokens - shows all tokens for today (read-only view)
    path('staff/all-tokens/', StaffAllTokensView.as_view(), name='staff_all_tokens'),
    
    # Pending Tokens - shows tokens marked as PENDING
    path('staff/pending-tokens/', StaffPendingTokensView.as_view(), name='staff_pending_tokens'),
    
    # Token Actions
    path('staff/token/<uuid:token_id>/start-service/', StaffStartServiceView.as_view(), name='staff_start_service'),
    path('staff/token/<uuid:token_id>/mark-pending/', StaffMarkPendingView.as_view(), name='staff_mark_pending'),
    path('staff/token/<uuid:token_id>/send-pending-email/', StaffPendingEmailView.as_view(), name='staff_pending_email'),
    path('staff/token/<uuid:token_id>/mark-pending-served/', StaffPendingServedView.as_view(), name='staff_pending_served'),
    
    # Citizen endpoints
    path('availability/', QueueAvailabilityView.as_view(), name='queue_availability'),
    path('book/', TokenBookingView.as_view(), name='book_token'),
    path('my-tokens/', MyTokensView.as_view(), name='my_tokens'),
    path('cancel/', TokenCancelView.as_view(), name='cancel_token'),
    
    # Token progress (Citizens can view their token progress)
    path('token/<uuid:token_id>/progress/', TokenProgressView.as_view(), name='token_progress'),
]
