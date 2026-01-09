"""
Password-based Authentication Views (Staff/Admin only)

Citizens should use OTP authentication at /auth/otp/
"""
import logging
import traceback
from django.utils import timezone
from django.conf import settings
from datetime import timedelta

from rest_framework import status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.throttling import AnonRateThrottle, UserRateThrottle

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from .services import AuthenticationService


logger = logging.getLogger(__name__)


class UserLoginView(BaseAPIView):
    """
    Password-based login for Staff and Admin users.
    Citizens should use OTP authentication.
    
    POST /auth/login/
    Body: {
        "email": "staff@example.com", 
        "password": "password123",
        "place_slug": "kathmandu",           # Required for ministry/staff login
        "ministry_slug": "ministry-of-health", # Required for ministry/staff login
        "service_slug": "passport-service"   # Required for staff login only
    }
    
    Login Contexts:
    - With place_slug + ministry_slug + service_slug: Service staff login
    - With place_slug + ministry_slug: Ministry admin login
    - Without any slugs: Super admin portal login
    """
    permission_classes = [AllowAny]
    throttle_classes = [AnonRateThrottle]

    
    def post(self, request):
        try: 
            email = request.data.get('email')
            password = request.data.get('password')
            device_info = request.data.get('device_info', {})
            place_slug = request.data.get('place_slug')
            ministry_slug = request.data.get('ministry_slug')
            service_slug = request.data.get('service_slug')
            
            success, response_data, status_code  = AuthenticationService.login(
                email=email, 
                password=password, 
                device_info=device_info, 
                request_meta=request.META, 
                request=request,
                place_slug=place_slug,
                ministry_slug=ministry_slug,
                service_slug=service_slug
            )
            
            # create response object
            response = Response(
                standardized_response(**response_data), status=status_code
            )
            
            if success :
                tokens = response_data.get('data', {}).get('tokens', {})
                refresh_token = tokens.get('refresh_token')
                if refresh_token:
                    # Set HTTP-only cookie for refresh token
                    response.set_cookie(
                        key = settings.JWT_COOKIE_NAME, 
                        value = refresh_token, 
                        expires = timezone.now() + settings.SIMPLE_JWT['REFRESH_TOKEN_LIFETIME'], 
                        secure = settings.JWT_COOKIE_SECURE, 
                        httponly=True, 
                        samesite= settings.JWT_COOKIE_SAMESITE,
                        path = '/', 
                    )
                    # In production, remove refresh_token from body
                    # In development (DEBUG=True), keep it for Flutter Web cross-origin
                    if not settings.DEBUG:
                        del response.data['data']['tokens']['refresh_token']
                    
    
                
            return response
        except Exception as e:
            logger.error(f"Login error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(standardized_response(success = False, error = "An unexpected error occurred. Please try again."), status= status.HTTP_500_INTERNAL_SERVER_ERROR)
        

class TokenRefreshView(BaseAPIView):
    """API endpoint for refreshing JWT tokens"""
    permission_classes = [AllowAny]
    throttle_classes = [AnonRateThrottle]
    
    def post(self, request):
        try:
            # Try to get refresh token from request body first (for Flutter Web)
            refresh_token = request.data.get('refresh_token')
            
            # If not in body, try cookie
            if not refresh_token:
                refresh_token = request.COOKIES.get(settings.JWT_COOKIE_NAME)
            
            if not refresh_token:
                return Response(standardized_response(success=False, error="Refresh token required."), status=status.HTTP_401_UNAUTHORIZED)
            success, response_data , status_code = AuthenticationService.refresh_token(refresh_token)
            
            response = Response(standardized_response(**response_data), status = status_code)
            
            if success :
                tokens = response_data.get('data', {})
                new_refresh_token = tokens.get('refresh_token')
                if new_refresh_token:
                    response.set_cookie(
                        key = settings.JWT_COOKIE_NAME, 
                        value = new_refresh_token, 
                        expires = timezone.now() + settings.SIMPLE_JWT['REFRESH_TOKEN_LIFETIME'], 
                        secure = settings.JWT_COOKIE_SECURE, 
                        httponly=True, 
                        samesite= settings.JWT_COOKIE_SAMESITE,
                       
                    )
                    # In production, remove refresh_token from body
                    if not settings.DEBUG:
                        del response.data['data']['refresh_token']
                    
         
            return response
        except Exception as e:
            logger.error(f"Token refresh error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(standardized_response(success = False, error = "An  error occurred during token refresh."), status= status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        
class ValidateTokenView(BaseAPIView):
    """Token validation"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        user = request.user
        
        # Get token from Authorization header
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')
        if auth_header.startswith('Bearer '):
            token = auth_header.split(' ')[1]
        
            success, response_data, status_code = AuthenticationService.validate_token(token, user)
            return Response(
                standardized_response(**response_data), 
                status = status_code
            )
            
        return Response(
            standardized_response(success = False, error = "No token provided"), 
            status = status.HTTP_400_BAD_REQUEST
        )
    

class LogoutView(BaseAPIView):
    """Logout endpoint that invalidates tokens"""
    permission_classes = [AllowAny]  # Allow logout even with expired token
    
    def post(self, request):
        try:
            user = request.user if request.user.is_authenticated else None
            refresh_token = None
            
            # Try to get refresh token from body first
            if 'refresh_token' in request.data:
                refresh_token = request.data.get('refresh_token')
            # Then try cookie
            elif request.COOKIES.get(settings.JWT_COOKIE_NAME):
                refresh_token = request.COOKIES.get(settings.JWT_COOKIE_NAME)
               
            success, response_data, status_code = AuthenticationService.logout(user, refresh_token)
            
            response = Response(standardized_response(**response_data), status=status_code)
            
            # Always try to delete the cookie
            response.delete_cookie(
                key=settings.JWT_COOKIE_NAME, 
                path='/', 
            ) 
                
            return response
        
        except Exception as e:
            logger.error(f"Logout error: {str(e)}")
            logger.error(traceback.format_exc())
            # Still return success - user wants to logout
            response = Response(
                standardized_response(success=True, message="Logged out"),
                status=status.HTTP_200_OK
            )
            response.delete_cookie(key=settings.JWT_COOKIE_NAME, path='/')
            return response
            
            response =Response(standardized_response(success = True, message = "Logout processed"), status = status.HTTP_200_OK)
            
            if settings.JWT_COOKIE_SECURE:
                response.delete_cookie(
                    key = settings.JWT_COOKIE_NAME, 
                    path = '/', 
                    domain = settings.SESSION_COOKE_DOMAIN
                ) 
                
            return response