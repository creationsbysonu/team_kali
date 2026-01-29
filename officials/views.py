"""
Views for Officials App.
"""

import logging
import traceback
from rest_framework import status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.throttling import UserRateThrottle

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from core.permissions import IsMinistryAdmin
from .models import MinistryOfficial
from .serializers import (
    MinistryOfficialSerializer,
    MinistryOfficialCreateSerializer,
    MinistryOfficialUpdateSerializer,
    MinistryOfficialListQuerySerializer
)

logger = logging.getLogger(__name__)


class MinistryOfficialCreateView(BaseAPIView):
    """API endpoint for creating ministry officials."""
    permission_classes = [IsAuthenticated, IsMinistryAdmin]
    throttle_classes = [UserRateThrottle]
    
    def post(self, request):
        """Create a new ministry official."""
        try:
            serializer = MinistryOfficialCreateSerializer(
                data=request.data,
                context={'request': request}
            )
            
            if not serializer.is_valid():
                return Response(
                    standardized_response(success=False, error=serializer.errors),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            official = serializer.save()
            
            result_serializer = MinistryOfficialSerializer(official)
            
            return Response(
                standardized_response(
                    success=True,
                    data=result_serializer.data,
                    message="Official created successfully"
                ),
                status=status.HTTP_201_CREATED
            )
            
        except Exception as e:
            logger.error(f"Official create error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to create official"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class MinistryOfficialListView(BaseAPIView):
    """API endpoint for listing ministry officials."""
    permission_classes = [IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request):
        """Get list of ministry officials with filtering."""
        try:
            query_serializer = MinistryOfficialListQuerySerializer(data=request.query_params)
            query_serializer.is_valid(raise_exception=True)
            
            # Build queryset
            queryset = MinistryOfficial.objects.select_related('ministry').all()
            
            # Apply filters (type assertion - validated_data exists after is_valid)
            validated_data: dict = query_serializer.validated_data  # type: ignore
            
            # IMPORTANT: Filter by ministry from request context (set by middleware)
            # This ensures users only see officials from their own ministry
            ministry_id = validated_data.get('ministry')
            if ministry_id:
                # Use explicitly provided ministry_id
                queryset = queryset.filter(ministry_id=ministry_id)
            elif hasattr(request, 'ministry') and request.ministry:
                # Auto-filter by logged-in user's ministry
                queryset = queryset.filter(ministry_id=request.ministry.id)
                logger.info(f"Auto-filtering officials by ministry: {request.ministry.slug}")
            else:
                # No ministry context - return empty for safety
                logger.warning("No ministry context in request, returning empty officials list")
                queryset = queryset.none()
                queryset = queryset.none()
            
            role = validated_data.get('role')
            if role:
                queryset = queryset.filter(role__icontains=role)
            
            is_active = validated_data.get('is_active')
            if is_active is not None:
                queryset = queryset.filter(is_active=is_active)
            
            search = validated_data.get('search')
            if search:
                queryset = queryset.filter(name__icontains=search)
            
            # Order by name
            queryset = queryset.order_by('name')
            
            serializer = MinistryOfficialSerializer(queryset, many=True)
            
            return Response(
                standardized_response(
                    success=True,
                    data=serializer.data,
                    count=queryset.count()
                ),
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            logger.error(f"Official list fetch error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to fetch officials"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class MinistryOfficialDetailView(BaseAPIView):
    """API endpoint for getting, updating, and deleting a specific official."""
    permission_classes = [IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    
    def get(self, request, official_id):
        """Get official details."""
        try:
            official = MinistryOfficial.objects.select_related('ministry').get(id=official_id)
            serializer = MinistryOfficialSerializer(official)
            
            return Response(
                standardized_response(success=True, data=serializer.data),
                status=status.HTTP_200_OK
            )
            
        except MinistryOfficial.DoesNotExist:
            return Response(
                standardized_response(success=False, error="Official not found"),
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f"Official fetch error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to fetch official"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def patch(self, request, official_id):
        """Update official details."""
        try:
            official = MinistryOfficial.objects.get(id=official_id)
            
            serializer = MinistryOfficialUpdateSerializer(
                official,
                data=request.data,
                partial=True,
                context={'request': request}
            )
            
            if not serializer.is_valid():
                return Response(
                    standardized_response(success=False, error=serializer.errors),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            updated_official = serializer.save()
            result_serializer = MinistryOfficialSerializer(updated_official)
            
            return Response(
                standardized_response(
                    success=True,
                    data=result_serializer.data,
                    message="Official updated successfully"
                ),
                status=status.HTTP_200_OK
            )
            
        except MinistryOfficial.DoesNotExist:
            return Response(
                standardized_response(success=False, error="Official not found"),
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f"Official update error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to update official"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def delete(self, request, official_id):
        """Delete official."""
        try:
            official = MinistryOfficial.objects.get(id=official_id)
            
            # Check if official is assigned to any active progress steps
            from queue_management.models import ServiceProgressStep
            active_steps = ServiceProgressStep.objects.filter(
                official=official,
                queue_config__active=True
            ).count()
            
            if active_steps > 0:
                return Response(
                    standardized_response(
                        success=False,
                        error=f"Cannot delete official assigned to {active_steps} active progress steps. Deactivate them first."
                    ),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            official_name = official.name
            official.delete()
            
            return Response(
                standardized_response(
                    success=True,
                    message=f"Official '{official_name}' deleted successfully"
                ),
                status=status.HTTP_200_OK
            )
            
        except MinistryOfficial.DoesNotExist:
            return Response(
                standardized_response(success=False, error="Official not found"),
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f"Official delete error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to delete official"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
