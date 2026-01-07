from django.urls import path

# OTP-based authentication (Citizens - Flutter App)
from .otp.views import OTPRequestView, OTPVerifyView, OTPResendView

# Password authentication (Ministry Users & Super Admin - Web App)
from .auth.views import (
    UserLoginView,
    TokenRefreshView,
    ValidateTokenView,
    LogoutView
)

app_name = 'authentication'


urlpatterns = [
    # ============================================
    # OTP Authentication (Citizens - Flutter App)
    # ============================================
    path('otp/request/', OTPRequestView.as_view(), name='otp_request'),
    path('otp/verify/', OTPVerifyView.as_view(), name='otp_verify'),
    path('otp/resend/', OTPResendView.as_view(), name='otp_resend'),
    
    # ============================================
    # Password Authentication (Ministry & Super Admin - Web App)
    # ============================================
    path('login/', UserLoginView.as_view(), name='login'),
    
    # ============================================
    # Token Management
    # ============================================
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('token/validate/', ValidateTokenView.as_view(), name='validate_token'),
    path('logout/', LogoutView.as_view(), name='logout'),
]
