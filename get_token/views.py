"""
Get Token Views

API endpoints for citizen token booking flow:
1. GET /places/<place_id>/ministries/ - List ministries in a place
2. GET /ministries/<ministry_id>/services/ - List services in a ministry
3. GET /services/<service_id>/details/ - Get service details with queue config
4. POST /book/ - Book a token
5. GET /my-tokens/ - Get user's tokens
6. POST /cancel/<token_id>/ - Cancel a token
"""
import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny

from .services import GetTokenService
from .serializers import (
    MinistryListSerializer,
    ServiceListSerializer,
    QueueConfigDetailSerializer,
    TokenBookingRequestSerializer,
    TokenBookingResponseSerializer
)

logger = logging.getLogger(__name__)


def standardized_response(success=True, data=None, error=None, message=None, **kwargs):
    """Creates a standardized API response format"""
    response = {"success": success}
    if data is not None:
        response['data'] = data
    if error is not None:
        response["error"] = error
    if message is not None:
        response["message"] = message
    for key, value in kwargs.items():
        response[key] = value
    return response


class MinistriesByPlaceView(APIView):
    """
    GET /get-token/places/<place_id>/ministries/
    
    List all active ministries in a place.
    Public endpoint - no authentication required.
    """
    permission_classes = [AllowAny]
    
    def get(self, request, place_id):
        try:
            success, response_data, status_code = GetTokenService.get_ministries_by_place(place_id)
            
            if not success:
                return Response(
                    standardized_response(success=False, error=response_data.get('error')),
                    status=status_code
                )
            
            ministries = response_data['data']['ministries']
            serializer = MinistryListSerializer(
                ministries, 
                many=True, 
                context={'request': request}
            )
            
            return Response(
                standardized_response(
                    success=True,
                    data={
                        "ministries": serializer.data,
                        "count": response_data['data']['count']
                    }
                ),
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            logger.error(f"Error in MinistriesByPlaceView: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch ministries"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class MinistriesByPlaceSlugView(APIView):
    """
    GET /get-token/places/<place_slug>/ministries/
    
    List all active ministries in a place (by slug or numeric ID).
    Public endpoint - no authentication required.
    
    Accepts:
    - Place slug (e.g., "dharan")
    - Numeric ID from legacy systems (e.g., "1")
    """
    permission_classes = [AllowAny]
    
    def get(self, request, place_slug):
        try:
            from places.models import Place
            
            place = None
            
            # Try to find place by slug first
            place = Place.objects.filter(slug=place_slug, is_active=True).first()
            
            # If not found and it's a numeric ID, try lookup by pk or order
            if not place and place_slug.isdigit():
                place_index = int(place_slug)
                # Try direct pk lookup (if it's actually a pk)
                place = Place.objects.filter(pk=place_index, is_active=True).first()
                
                # If still not found, get by order (1 = first place, 2 = second, etc.)
                if not place:
                    places = Place.objects.filter(is_active=True).order_by('created_at')
                    if place_index > 0 and place_index <= places.count():
                        place = places[place_index - 1]  # 1-indexed
            
            if not place:
                return Response(
                    standardized_response(success=False, error="Place not found"),
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Use existing service with place ID
            success, response_data, status_code = GetTokenService.get_ministries_by_place(place.id)
            
            if not success:
                return Response(
                    standardized_response(success=False, error=response_data.get('error')),
                    status=status_code
                )
            
            ministries = response_data['data']['ministries']
            serializer = MinistryListSerializer(
                ministries, 
                many=True, 
                context={'request': request}
            )
            
            return Response(
                standardized_response(
                    success=True,
                    data={
                        "place": {
                            "id": str(place.id),
                            "name": place.name,
                            "slug": place.slug
                        },
                        "ministries": serializer.data,
                        "count": response_data['data']['count']
                    }
                ),
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            logger.error(f"Error in MinistriesByPlaceSlugView: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch ministries"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ServicesByMinistryView(APIView):
    """
    GET /get-token/ministries/<ministry_id>/services/
    
    List all active services in a ministry with availability status.
    Public endpoint - no authentication required.
    """
    permission_classes = [AllowAny]
    
    def get(self, request, ministry_id):
        try:
            success, response_data, status_code = GetTokenService.get_services_by_ministry(ministry_id)
            
            if not success:
                return Response(
                    standardized_response(success=False, error=response_data.get('error')),
                    status=status_code
                )
            
            services = response_data['data']['services']
            serializer = ServiceListSerializer(
                services, 
                many=True, 
                context={'request': request}
            )
            
            return Response(
                standardized_response(
                    success=True,
                    data={
                        "ministry": response_data['data']['ministry'],
                        "services": serializer.data,
                        "count": response_data['data']['count']
                    }
                ),
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            logger.error(f"Error in ServicesByMinistryView: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch services"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ServicesByMinistrySlugView(APIView):
    """
    GET /get-token/<place_slug>/<ministry_slug>/services/
    
    List all active services in a ministry (by slug).
    Public endpoint - no authentication required.
    """
    permission_classes = [AllowAny]
    
    def get(self, request, place_slug, ministry_slug):
        try:
            from places.models import Place
            from ministry.models import Ministry
            
            # Look up place by slug
            try:
                place = Place.objects.get(slug=place_slug, is_active=True)
            except Place.DoesNotExist:
                return Response(
                    standardized_response(success=False, error="Place not found"),
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Look up ministry by slug within place
            try:
                ministry = Ministry.objects.get(
                    slug=ministry_slug, 
                    place=place, 
                    status=Ministry.Status.ACTIVE
                )
            except Ministry.DoesNotExist:
                return Response(
                    standardized_response(success=False, error="Ministry not found"),
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Use existing service with ministry ID
            success, response_data, status_code = GetTokenService.get_services_by_ministry(ministry.id)
            
            if not success:
                return Response(
                    standardized_response(success=False, error=response_data.get('error')),
                    status=status_code
                )
            
            services = response_data['data']['services']
            serializer = ServiceListSerializer(
                services, 
                many=True, 
                context={'request': request}
            )
            
            return Response(
                standardized_response(
                    success=True,
                    data={
                        "place": {
                            "id": str(place.id),
                            "name": place.name,
                            "slug": place.slug
                        },
                        "ministry": response_data['data']['ministry'],
                        "services": serializer.data,
                        "count": response_data['data']['count']
                    }
                ),
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            logger.error(f"Error in ServicesByMinistrySlugView: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch services"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ServiceDetailsView(APIView):
    """
    GET /get-token/services/<service_id>/details/
    
    Get complete service details including:
    - Queue configuration (office hours, lunch, documents, etc.)
    - Prebooking and emergency booking info
    - Progress steps (if enabled)
    - Officials linked and their attendance
    - Today's availability status
    - Tokens available/booked
    
    Public endpoint - no authentication required.
    """
    permission_classes = [AllowAny]
    
    def get(self, request, service_id):
        try:
            success, response_data, status_code = GetTokenService.get_service_details(service_id)
            
            if not success:
                return Response(
                    standardized_response(success=False, error=response_data.get('error')),
                    status=status_code
                )
            
            queue_config = response_data['data']['queue_config']
            serializer = QueueConfigDetailSerializer(
                queue_config, 
                context={'request': request}
            )
            
            return Response(
                standardized_response(
                    success=True,
                    data=serializer.data
                ),
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            logger.error(f"Error in ServiceDetailsView: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch service details"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class BookTokenView(APIView):
    """
    POST /get-token/book/
    
    Book a token for a service.
    Requires authentication.
    
    Request body:
    {
        "service_id": "uuid",
        "booking_type": "REGULAR" | "PREBOOKED" | "EMERGENCY",
        "booking_date": "2026-01-29"  // optional, for PREBOOKED
    }
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        try:
            serializer = TokenBookingRequestSerializer(data=request.data)
            if not serializer.is_valid():
                return Response(
                    standardized_response(success=False, error=serializer.errors),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            service_id = serializer.validated_data['service_id']
            booking_type = serializer.validated_data.get('booking_type', 'REGULAR')
            booking_date = serializer.validated_data.get('booking_date')
            
            success, response_data, status_code = GetTokenService.book_token(
                service_id=service_id,
                user=request.user,
                booking_type=booking_type,
                booking_date=booking_date
            )
            
            if not success:
                return Response(
                    standardized_response(success=False, error=response_data.get('error')),
                    status=status_code
                )
            
            # Serialize the token
            token = response_data['data']['token']
            token_serializer = TokenBookingResponseSerializer(token, context={'request': request})
            
            return Response(
                standardized_response(
                    success=True,
                    message=response_data.get('message'),
                    data=token_serializer.data
                ),
                status=status.HTTP_201_CREATED
            )
            
        except Exception as e:
            logger.error(f"Error in BookTokenView: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to book token"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class MyTokensView(APIView):
    """
    GET /get-token/my-tokens/
    
    Get all tokens for the authenticated user.
    Query params:
    - include_past: true/false (include completed/cancelled tokens)
    
    Requires authentication.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            include_past = request.query_params.get('include_past', 'false').lower() == 'true'
            
            success, response_data, status_code = GetTokenService.get_user_tokens(
                user=request.user,
                include_past=include_past
            )
            
            if not success:
                return Response(
                    standardized_response(success=False, error=response_data.get('error')),
                    status=status_code
                )
            
            tokens = response_data['data']['tokens']
            serializer = TokenBookingResponseSerializer(
                tokens, 
                many=True, 
                context={'request': request}
            )
            
            return Response(
                standardized_response(
                    success=True,
                    data={
                        "tokens": serializer.data,
                        "count": response_data['data']['count']
                    }
                ),
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            logger.error(f"Error in MyTokensView: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch your tokens"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class CancelTokenView(APIView):
    """
    POST /get-token/cancel/<token_id>/
    
    Cancel a token.
    Only WAITING or PENDING tokens can be cancelled.
    
    Requires authentication (must be token owner).
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request, token_id):
        try:
            success, response_data, status_code = GetTokenService.cancel_token(
                token_id=token_id,
                user=request.user
            )
            
            if not success:
                return Response(
                    standardized_response(success=False, error=response_data.get('error')),
                    status=status_code
                )
            
            return Response(
                standardized_response(
                    success=True,
                    message=response_data.get('message')
                ),
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            logger.error(f"Error in CancelTokenView: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to cancel token"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class CheckAvailabilityView(APIView):
    """
    GET /get-token/services/<service_id>/availability/
    
    Quick availability check for a service.
    Returns only availability status without full details.
    
    Public endpoint.
    """
    permission_classes = [AllowAny]
    
    def get(self, request, service_id):
        try:
            from queue_management.models import QueueConfiguration, DailyQueue, QueueToken
            from ministry.models import StaffService
            from attendance.models import AttendanceRecord
            from core.utils.nepal_time import get_nepal_today, is_saturday
            from holidays.models import Holiday
            
            today = get_nepal_today()
            
            # Get service
            try:
                service = StaffService.objects.select_related('queue_config').get(
                    id=service_id, is_active=True
                )
            except StaffService.DoesNotExist:
                return Response(
                    standardized_response(
                        success=True,
                        data={
                            "available": False,
                            "reason": "Service not found",
                            "reason_code": "NOT_FOUND"
                        }
                    ),
                    status=status.HTTP_200_OK
                )
            
            # Quick checks
            if not hasattr(service, 'queue_config') or not service.queue_config:
                return Response(
                    standardized_response(
                        success=True,
                        data={
                            "available": False,
                            "reason": "Queue not configured",
                            "reason_code": "NO_CONFIG"
                        }
                    ),
                    status=status.HTTP_200_OK
                )
            
            queue_config = service.queue_config
            
            if not queue_config.active or service.status != 'active':
                return Response(
                    standardized_response(
                        success=True,
                        data={
                            "available": False,
                            "reason": "Service not active",
                            "reason_code": "INACTIVE"
                        }
                    ),
                    status=status.HTTP_200_OK
                )
            
            if is_saturday(today):
                return Response(
                    standardized_response(
                        success=True,
                        data={
                            "available": False,
                            "reason": "Saturday holiday",
                            "reason_code": "SATURDAY"
                        }
                    ),
                    status=status.HTTP_200_OK
                )
            
            holiday = Holiday.objects.filter(date=today).first()
            if holiday:
                return Response(
                    standardized_response(
                        success=True,
                        data={
                            "available": False,
                            "reason": f"Holiday: {holiday.name}",
                            "reason_code": "HOLIDAY"
                        }
                    ),
                    status=status.HTTP_200_OK
                )
            
            # Check staff attendance
            staff_absent = AttendanceRecord.objects.filter(
                staff=service,
                date=today,
                person_type=AttendanceRecord.PersonType.STAFF,
                status=AttendanceRecord.Status.ABSENT
            ).exists()
            
            if staff_absent:
                return Response(
                    standardized_response(
                        success=True,
                        data={
                            "available": False,
                            "reason": "Staff absent today",
                            "reason_code": "STAFF_ABSENT"
                        }
                    ),
                    status=status.HTTP_200_OK
                )
            
            # Check capacity
            capacity = queue_config.calculate_daily_capacity()
            daily_queue = DailyQueue.objects.filter(queue_config=queue_config, date=today).first()
            
            tokens_booked = 0
            if daily_queue:
                tokens_booked = daily_queue.tokens.filter(
                    status__in=[QueueToken.Status.WAITING, QueueToken.Status.IN_SERVICE]
                ).count()
            
            available_slots = capacity - tokens_booked
            
            if available_slots <= 0:
                return Response(
                    standardized_response(
                        success=True,
                        data={
                            "available": False,
                            "reason": "Capacity full",
                            "reason_code": "FULL"
                        }
                    ),
                    status=status.HTTP_200_OK
                )
            
            return Response(
                standardized_response(
                    success=True,
                    data={
                        "available": True,
                        "slots_available": available_slots,
                        "total_capacity": capacity,
                        "tokens_booked": tokens_booked,
                        "reason_code": "AVAILABLE"
                    }
                ),
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            logger.error(f"Error in CheckAvailabilityView: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to check availability"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

