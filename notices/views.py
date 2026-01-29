"""
Notices Views

REST API endpoints for notices:
- POST /api/notices/ - Upload notice (admin only)
- GET /api/notices/ - List notices (authenticated users)
- GET /api/notices/<id>/ - Notice detail
"""

import logging
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser

from .models import Notice
from ministry.models import Ministry
from services.models import Service
from ministry.serializers import MinistryListSerializer
from services.serializers import ServicePublicListSerializer
from .serializers import (
    NoticeListSerializer, 
    NoticeDetailSerializer,
    NoticeCreateSerializer,
    NoticeUpdateSerializer,
)
from core.permissions import IsAdminUser

logger = logging.getLogger(__name__)


class CanUploadNotice(IsAdminUser):
    """Permission check for notice upload - admin or staff with permission"""
    pass


class NoticeListCreateView(generics.ListCreateAPIView):
    """
    GET: List all active notices (latest first)
    POST: Upload a new notice (admin only)
    
    Query parameters for filtering are handled by filters app.
    """
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return NoticeCreateSerializer
        return NoticeListSerializer
    
    def get_queryset(self):
        """
        Get notices queryset.
        Filtering is delegated to the filters app.
        """
        queryset = Notice.objects.filter(is_active=True).select_related(
            'ministry', 'service', 'created_by'
        )
        
        # Import and apply filters from filters app
        from filters.services import NoticeFilterService
        queryset = NoticeFilterService.apply(queryset, self.request.query_params)
        
        return queryset
    
    def get_permissions(self):
        """Different permissions for GET vs POST"""
        if self.request.method == 'POST':
            return [IsAuthenticated(), CanUploadNotice()]
        return [IsAuthenticated()]
    
    def list(self, request, *args, **kwargs):
        """List notices with standardized response"""
        queryset = self.get_queryset()
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True, context={'request': request})
            response = self.get_paginated_response(serializer.data)
            response.data = {
                'success': True,
                'data': response.data
            }
            return response
        
        serializer = self.get_serializer(queryset, many=True, context={'request': request})
        return Response({
            'success': True,
            'data': serializer.data,
            'count': len(serializer.data)
        })
    
    def create(self, request, *args, **kwargs):
        """Upload a new notice"""
        serializer = self.get_serializer(data=request.data, context={'request': request})
        
        if not serializer.is_valid():
            return Response({
                'success': False,
                'error': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
        
        notice = serializer.save()
        
        logger.info(f"Notice uploaded by {request.user.email}: {notice.title} ({notice.id})")
        
        # Trigger async RAG ingestion
        from rag_bridge.tasks import ingest_document
        ingest_document.delay(str(notice.id))
        
        return Response({
            'success': True,
            'message': 'Notice uploaded successfully. Document ingestion queued.',
            'data': NoticeDetailSerializer(notice, context={'request': request}).data
        }, status=status.HTTP_201_CREATED)


class NoticeDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET: Retrieve notice details
    PATCH: Update notice (admin only)
    DELETE: Soft delete notice (admin only)
    """
    lookup_field = 'pk'
    
    def get_serializer_class(self):
        if self.request.method in ['PATCH', 'PUT']:
            return NoticeUpdateSerializer
        return NoticeDetailSerializer
    
    def get_queryset(self):
        return Notice.objects.select_related('ministry', 'service', 'created_by')
    
    def get_permissions(self):
        """Admin for write, authenticated for read"""
        if self.request.method in ['PATCH', 'PUT', 'DELETE']:
            return [IsAuthenticated(), IsAdminUser()]
        return [IsAuthenticated()]
    
    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance, context={'request': request})
        return Response({
            'success': True,
            'data': serializer.data
        })
    
    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', True)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        
        if not serializer.is_valid():
            return Response({
                'success': False,
                'error': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
        
        serializer.save()
        
        logger.info(f"Notice updated by {request.user.email}: {instance.id}")
        
        return Response({
            'success': True,
            'message': 'Notice updated successfully',
            'data': NoticeDetailSerializer(instance, context={'request': request}).data
        })
    
    def destroy(self, request, *args, **kwargs):
        """Soft delete - just mark as inactive"""
        instance = self.get_object()
        instance.is_active = False
        instance.save(update_fields=['is_active', 'updated_at'])
        
        logger.info(f"Notice deactivated by {request.user.email}: {instance.id}")
        
        return Response({
            'success': True,
            'message': 'Notice deactivated successfully'
        }, status=status.HTTP_200_OK)


class MinistryListView(generics.ListAPIView):
    """
    GET: List all active ministries.
    Used for filtering dropdown in notices.
    """
    permission_classes = [IsAuthenticated]
    serializer_class = MinistryListSerializer
    pagination_class = None  # Return all
    
    def get_queryset(self):
        return Ministry.objects.filter(
            status=Ministry.Status.ACTIVE
        ).order_by('name')
    
    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True, context={'request': request})
        return Response({
            'success': True,
            'data': serializer.data,
            'count': len(serializer.data)
        })


class ServiceListView(generics.ListAPIView):
    """
    GET: List services, optionally filtered by ministry.
    Used for filtering dropdown in notices.
    """
    permission_classes = [IsAuthenticated]
    serializer_class = ServicePublicListSerializer
    pagination_class = None
    
    def get_queryset(self):
        queryset = Service.objects.filter(is_active=True).select_related('ministry')
        ministry = self.request.query_params.get('ministry')
        if ministry:
            queryset = queryset.filter(ministry_id=ministry)
        return queryset.order_by('name')
    
    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True, context={'request': request})
        return Response({
            'success': True,
            'data': serializer.data,
            'count': len(serializer.data)
        })
