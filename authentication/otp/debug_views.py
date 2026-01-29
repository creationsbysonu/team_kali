"""
Development-only OTP Debug View (DO NOT USE IN PRODUCTION)
"""
import logging
from django.conf import settings
from django.core.cache import cache

from rest_framework import status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response

logger = logging.getLogger(__name__)


class OTPDebugView(BaseAPIView):
    """
    ⚠️  DEVELOPMENT ONLY - Get OTP from cache for testing
    
    GET /api/auth/otp/debug/?email=user@example.com
    
    This endpoint should be DISABLED in production!
    """
    permission_classes = [AllowAny]
    
    def get(self, request):
        # Only allow in DEBUG mode
        if not settings.DEBUG:
            return Response(
                standardized_response(
                    success=False,
                    error="Not available in production"
                ),
                status=status.HTTP_404_NOT_FOUND
            )
        
        email = request.query_params.get('email')
        
        if not email:
            return Response(
                standardized_response(
                    success=False,
                    error="Email parameter required"
                ),
                status=status.HTTP_400_BAD_REQUEST
            )
        
        email = email.lower().strip()
        cache_key = f"otp_{email}"
        cache_data = cache.get(cache_key)
        
        if not cache_data:
            return Response(
                standardized_response(
                    success=False,
                    error=f"No OTP found for {email}. Request OTP first."
                ),
                status=status.HTTP_404_NOT_FOUND
            )
        
        return Response(
            standardized_response(
                success=True,
                data={
                    "email": email,
                    "otp_hash": cache_data.get('otp_hash'),
                    "created_at": cache_data.get('created_at'),
                    "attempts": cache_data.get('attempts'),
                    "note": "⚠️ OTP is hashed. Check server logs for actual OTP value in DEBUG mode."
                },
                message="OTP cache data retrieved (DEBUG only)"
            ),
            status=status.HTTP_200_OK
        )
