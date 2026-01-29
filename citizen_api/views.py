"""
Citizen API - Optimized Views for Flutter

Design Principles:
1. THIN VIEWS - All logic in service layer
2. CONSISTENT RESPONSES - Same structure for all endpoints
3. PROPER ERROR HANDLING - Meaningful error messages
4. RATE LIMITING - Protect against abuse
5. AUTHENTICATION - Mixed (public lists, auth for booking)
"""
import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.throttling import AnonRateThrottle, UserRateThrottle

from .services import CitizenAPIService

logger = logging.getLogger(__name__)


def api_response(success: bool, data=None, error=None, message=None, **kwargs):
    """Standardized API response"""
    response = {"success": success}
    if data is not None:
        response["data"] = data
    if error is not None:
        response["error"] = error
    if message is not None:
        response["message"] = message
    response.update(kwargs)
    return response


# =============================================================================
# RATE LIMITING
# =============================================================================

class CitizenAnonThrottle(AnonRateThrottle):
    """Rate limit for anonymous users"""
    rate = '60/minute'


class CitizenUserThrottle(UserRateThrottle):
    """Rate limit for authenticated users"""
    rate = '120/minute'


# =============================================================================
# PHASE 1: MINISTRIES BY PLACE
# =============================================================================

class MinistriesListView(APIView):
    """
    GET /citizen/v1/places/{place}/ministries/
    
    List ministries in a place with pagination.
    
    Query Parameters:
    - cursor: Pagination cursor (optional)
    - page_size: Items per page (default: 20, max: 50)
    
    Response:
    {
        "success": true,
        "data": {
            "items": [...],
            "pagination": {
                "next_cursor": "...",
                "has_more": true,
                "total_estimate": 100
            },
            "place": {"id": "...", "name": "...", "slug": "..."}
        }
    }
    """
    permission_classes = [AllowAny]
    throttle_classes = [CitizenAnonThrottle]
    
    def get(self, request, place_identifier):
        cursor = request.query_params.get('cursor')
        page_size = min(int(request.query_params.get('page_size', 20)), 50)
        
        success, response_data, status_code = CitizenAPIService.get_ministries_by_place(
            place_identifier=place_identifier,
            cursor=cursor,
            page_size=page_size,
            request=request
        )
        
        if success:
            return Response(
                api_response(success=True, **response_data),
                status=status_code
            )
        else:
            return Response(
                api_response(success=False, **response_data),
                status=status_code
            )


# =============================================================================
# PHASE 2: SERVICES BY MINISTRY
# =============================================================================

class ServicesListView(APIView):
    """
    GET /citizen/v1/ministries/{ministry}/services/
    
    List services in a ministry with availability status.
    
    Query Parameters:
    - cursor: Pagination cursor (optional)
    - page_size: Items per page (default: 20, max: 50)
    
    Response:
    {
        "success": true,
        "data": {
            "items": [
                {
                    "id": "...",
                    "service_name": "...",
                    "is_available_today": true,
                    "availability_reason": null,
                    "tokens_available": 15,
                    ...
                }
            ],
            "pagination": {...},
            "ministry": {"id": "...", "name": "...", "slug": "..."}
        }
    }
    """
    permission_classes = [AllowAny]
    throttle_classes = [CitizenAnonThrottle]
    
    def get(self, request, ministry_identifier):
        cursor = request.query_params.get('cursor')
        page_size = min(int(request.query_params.get('page_size', 20)), 50)
        
        success, response_data, status_code = CitizenAPIService.get_services_by_ministry(
            ministry_identifier=ministry_identifier,
            cursor=cursor,
            page_size=page_size,
            request=request
        )
        
        if success:
            return Response(
                api_response(success=True, **response_data),
                status=status_code
            )
        else:
            return Response(
                api_response(success=False, **response_data),
                status=status_code
            )


# =============================================================================
# PHASE 3: SERVICE DETAILS
# =============================================================================

class ServiceDetailView(APIView):
    """
    GET /citizen/v1/services/{service_id}/
    
    Get complete service details for booking screen.
    
    Response includes:
    - Basic info (name, ministry, staff)
    - Office hours and lunch break
    - Booking options (regular, prebook, emergency)
    - Required documents
    - Today's availability with queue stats
    - Progress steps (if enabled)
    - Officials with attendance
    """
    permission_classes = [AllowAny]
    throttle_classes = [CitizenAnonThrottle]
    
    def get(self, request, service_id):
        success, response_data, status_code = CitizenAPIService.get_service_details(
            service_id=str(service_id),
            request=request
        )
        
        if success:
            return Response(
                api_response(success=True, **response_data),
                status=status_code
            )
        else:
            return Response(
                api_response(success=False, **response_data),
                status=status_code
            )


# =============================================================================
# PHASE 4: MY TOKENS
# =============================================================================

class MyTokensListView(APIView):
    """
    GET /citizen/v1/tokens/
    
    Get authenticated user's tokens with queue position and progress.
    
    Query Parameters:
    - status: Filter by status (ACTIVE, COMPLETED, CANCELLED)
    - cursor: Pagination cursor
    - page_size: Items per page (default: 20)
    
    Response:
    {
        "success": true,
        "data": {
            "items": [
                {
                    "id": "...",
                    "token_number": 5,
                    "status": "WAITING",
                    "queue_position": 3,
                    "estimated_wait": "30 minutes",
                    "progress": {
                        "total_steps": 3,
                        "completed_steps": 1,
                        ...
                    }
                }
            ],
            "pagination": {...}
        }
    }
    """
    permission_classes = [IsAuthenticated]
    throttle_classes = [CitizenUserThrottle]
    
    def get(self, request):
        status_filter = request.query_params.get('status')
        cursor = request.query_params.get('cursor')
        page_size = min(int(request.query_params.get('page_size', 20)), 50)
        
        success, response_data, status_code = CitizenAPIService.get_my_tokens(
            user=request.user,
            status_filter=status_filter,
            cursor=cursor,
            page_size=page_size,
            request=request
        )
        
        if success:
            return Response(
                api_response(success=True, **response_data),
                status=status_code
            )
        else:
            return Response(
                api_response(success=False, **response_data),
                status=status_code
            )


class TokenDetailView(APIView):
    """
    GET /citizen/v1/tokens/{token_id}/
    
    Get detailed token information including full progress history.
    """
    permission_classes = [IsAuthenticated]
    throttle_classes = [CitizenUserThrottle]
    
    def get(self, request, token_id):
        # TODO: Implement token detail view
        return Response(
            api_response(success=False, error="Not implemented"),
            status=status.HTTP_501_NOT_IMPLEMENTED
        )


# =============================================================================
# QUICK AVAILABILITY CHECK
# =============================================================================

class AvailabilityCheckView(APIView):
    """
    GET /citizen/v1/services/{service_id}/availability/
    
    Quick check if service is available for booking.
    Ultra-fast response for Flutter UI state.
    
    Response:
    {
        "success": true,
        "data": {
            "available": true,
            "reason": null,
            "tokens_available": 15,
            "current_queue": 5,
            "estimated_wait": "45 minutes"
        }
    }
    """
    permission_classes = [AllowAny]
    throttle_classes = [CitizenAnonThrottle]
    
    def get(self, request, service_id):
        # Get just availability portion of service details
        success, response_data, status_code = CitizenAPIService.get_service_details(
            service_id=str(service_id),
            request=request
        )
        
        if success:
            data = response_data.get('data', {})
            availability = data.get('availability', {})
            
            return Response(
                api_response(
                    success=True,
                    data={
                        "available": data.get('is_available_today', False),
                        "reason": availability.get('reason'),
                        "reason_code": availability.get('code'),
                        "tokens_available": availability.get('tokens_available', 0),
                        "current_queue": availability.get('current_token'),
                        "estimated_wait": availability.get('estimated_wait')
                    }
                ),
                status=status.HTTP_200_OK
            )
        else:
            return Response(
                api_response(success=False, **response_data),
                status=status_code
            )
