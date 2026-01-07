"""
OTP Views for Citizen Authentication

Endpoints:
- POST /auth/otp/request/ - Request OTP
- POST /auth/otp/verify/ - Verify OTP and get tokens
- POST /auth/otp/resend/ - Resend OTP
"""
import logging
import traceback

from django.utils import timezone
from django.conf import settings
from datetime import timedelta

from rest_framework import status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework.throttling import AnonRateThrottle

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from .services import OTPService

logger = logging.getLogger(__name__)


class OTPRequestThrottle(AnonRateThrottle):
    """Custom throttle for OTP requests"""
    rate = '5/hour'


class OTPRequestView(BaseAPIView):
    """
    Request OTP for citizen authentication.
    
    POST /auth/otp/request/
    Body: {"email": "user@example.com"}
    """
    permission_classes = [AllowAny]
    throttle_classes = [OTPRequestThrottle]
    
    def post(self, request):
        try:
            email = request.data.get('email')
            
            if not email:
                return Response(
                    standardized_response(success=False, error="Email is required"),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            success, response_data, status_code = OTPService.request_otp(
                email=email,
                request_meta=request.META
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"[otp] Request OTP error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to send OTP. Please try again."),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class OTPVerifyView(BaseAPIView):
    """
    Verify OTP and return authentication tokens.
    Creates user account if doesn't exist.
    
    POST /auth/otp/verify/
    Body: {"email": "user@example.com", "otp": "123456"}
    """
    permission_classes = [AllowAny]
    throttle_classes = [AnonRateThrottle]
    
    def post(self, request):
        try:
            email = request.data.get('email')
            otp = request.data.get('otp')
            
            if not email or not otp:
                return Response(
                    standardized_response(success=False, error="Email and OTP are required"),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            success, response_data, status_code = OTPService.verify_otp(
                email=email,
                otp=otp,
                request_meta=request.META,
                request=request
            )
            
            # Create response
            response = Response(
                standardized_response(**response_data),
                status=status_code
            )
            
            # Set refresh token in HTTP-only cookie if successful
            if success and hasattr(settings, 'JWT_COOKIE_SECURE') and settings.JWT_COOKIE_SECURE:
                tokens = response_data.get('data', {}).get('tokens', {})
                refresh_token = tokens.get('refresh_token')
                
                if refresh_token:
                    response.set_cookie(
                        key=settings.JWT_COOKIE_NAME,
                        value=refresh_token,
                        expires=timezone.now() + settings.SIMPLE_JWT['REFRESH_TOKEN_LIFETIME'],
                        secure=settings.JWT_COOKIE_SECURE,
                        httponly=True,
                        samesite=settings.JWT_COOKIE_SAMESITE,
                        path='/'
                    )
                    # Remove refresh token from response body for security
                    if response.data and 'data' in response.data and 'tokens' in response.data.get('data', {}):
                        del response.data['data']['tokens']['refresh_token']
            
            return response
            
        except Exception as e:
            logger.error(f"[otp] Verify OTP error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Verification failed. Please try again."),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class OTPResendView(BaseAPIView):
    """
    Resend OTP to email.
    
    POST /auth/otp/resend/
    Body: {"email": "user@example.com"}
    """
    permission_classes = [AllowAny]
    throttle_classes = [OTPRequestThrottle]
    
    def post(self, request):
        try:
            email = request.data.get('email')
            
            if not email:
                return Response(
                    standardized_response(success=False, error="Email is required"),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            success, response_data, status_code = OTPService.resend_otp(
                email=email,
                request_meta=request.META
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"[otp] Resend OTP error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to resend OTP. Please try again."),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
