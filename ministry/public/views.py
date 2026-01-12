"""
Public Ministry Views

Public endpoints for browsing ministries and services.
No authentication required.
"""
import logging
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from rest_framework.throttling import AnonRateThrottle

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from .services import PublicMinistryService
from ministry.core.auth_service import MinistryAuthService
from .staff_auth_service import StaffAuthService

logger = logging.getLogger(__name__)


class PublicMinistryListView(BaseAPIView):
    """
    GET /ministry/public/<place_slug>/ministries/
    
    List all active ministries for a place.
    No authentication required.
    """
    permission_classes = [AllowAny]
    
    def get(self, request, place_slug):
        try:
            success, response_data, status_code = PublicMinistryService.get_ministries_by_place(
                place_slug=place_slug,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[public] Ministry list view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch ministries"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class PublicMinistryDetailView(BaseAPIView):
    """
    GET /ministry/public/<place_slug>/ministries/<ministry_slug>/
    
    Get ministry details by slug.
    No authentication required.
    """
    permission_classes = [AllowAny]
    
    def get(self, request, place_slug, ministry_slug):
        try:
            success, response_data, status_code = PublicMinistryService.get_ministry_detail(
                place_slug=place_slug,
                ministry_slug=ministry_slug,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[public] Ministry detail view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch ministry details"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class PublicServiceListView(BaseAPIView):
    """
    GET /ministry/public/<place_slug>/ministries/<ministry_slug>/services/
    
    List all active services for a ministry.
    No authentication required.
    """
    permission_classes = [AllowAny]
    
    def get(self, request, place_slug, ministry_slug):
        try:
            success, response_data, status_code = PublicMinistryService.get_services_by_ministry(
                place_slug=place_slug,
                ministry_slug=ministry_slug,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[public] Service list view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch services"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class MinistryLoginView(BaseAPIView):
    """
    POST /ministry/public/<place_slug>/<ministry_slug>/login/
    
    Ministry login endpoint.
    Ministry logs in with email and password set by super admin.
    
    Body:
    {
        "email": "ministry@example.com",
        "password": "password123"
    }
    
    Returns JWT tokens for ministry dashboard access.
    """
    permission_classes = [AllowAny]
    throttle_classes = [AnonRateThrottle]
    
    def post(self, request, place_slug, ministry_slug):
        try:
            email = request.data.get('email')
            password = request.data.get('password')
            
            success, response_data, status_code = MinistryAuthService.login(
                email=email,
                password=password,
                place_slug=place_slug,
                ministry_slug=ministry_slug,
                request=request
            )
            
            response = Response(
                standardized_response(**response_data),
                status=status_code
            )
            
            # Set HTTP-only cookie for refresh token if login successful
            if success and 'data' in response_data:
                tokens = response_data['data'].get('tokens', {})
                refresh_token = tokens.get('refresh_token')
                
                if refresh_token:
                    from django.conf import settings
                    from django.utils import timezone
                    
                    response.set_cookie(
                        key=settings.JWT_COOKIE_NAME,
                        value=refresh_token,
                        expires=timezone.now() + settings.SIMPLE_JWT['REFRESH_TOKEN_LIFETIME'],
                        secure=settings.JWT_COOKIE_SECURE,
                        httponly=True,
                        samesite=settings.JWT_COOKIE_SAMESITE,
                        path='/',
                    )
                    
                    # Remove refresh token from response body in production
                    if not settings.DEBUG:
                        del response.data['data']['tokens']['refresh_token']
            
            return response
            
        except Exception as e:
            logger.error(f"[public] Ministry login error: {str(e)}")
            import traceback
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Login failed"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class StaffLoginView(BaseAPIView):
    """
    POST /ministry/public/<place_slug>/ministries/<ministry_slug>/staff/login/
    
    Staff login endpoint.
    Staff (StaffService) logs in with email and password set by ministry admin.
    
    Body:
    {
        "email": "staff@example.com",
        "password": "password123"
    }
    
    Returns JWT tokens for staff dashboard access.
    """
    permission_classes = [AllowAny]
    throttle_classes = [AnonRateThrottle]
    
    def post(self, request, place_slug, ministry_slug):
        try:
            email = request.data.get('email')
            password = request.data.get('password')
            
            success, response_data, status_code = StaffAuthService.login(
                email=email,
                password=password,
                place_slug=place_slug,
                ministry_slug=ministry_slug,
                request=request
            )
            
            response = Response(
                standardized_response(**response_data),
                status=status_code
            )
            
            # Set HTTP-only cookie for refresh token if login successful
            if success and 'data' in response_data:
                tokens = response_data['data'].get('tokens', {})
                refresh_token = tokens.get('refresh_token')
                
                if refresh_token:
                    from django.conf import settings
                    from django.utils import timezone
                    
                    response.set_cookie(
                        key=settings.JWT_COOKIE_NAME,
                        value=refresh_token,
                        expires=timezone.now() + settings.SIMPLE_JWT['REFRESH_TOKEN_LIFETIME'],
                        secure=settings.JWT_COOKIE_SECURE,
                        httponly=True,
                        samesite=settings.JWT_COOKIE_SAMESITE,
                        path='/',
                    )
                    
                    # Remove refresh token from response body in production
                    if not settings.DEBUG:
                        del response.data['data']['tokens']['refresh_token']
            
            return response
            
        except Exception as e:
            logger.error(f"[public] Staff login error: {str(e)}")
            import traceback
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Login failed"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
