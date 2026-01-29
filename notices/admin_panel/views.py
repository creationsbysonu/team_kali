"""
Notice Admin Panel Views

Views for ministry admins and staff admins to manage notices.
"""

import logging
import traceback
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser

from authentication.core.response import standardized_response
from core.permissions import IsMinistryAdmin, IsStaffAdminForToday

from .services import NoticeAdminService

logger = logging.getLogger(__name__)


class IsStaffUser(IsAuthenticated):
    """
    Permission check for staff users.
    
    Allows:
    - Users with active staff_profile (Staff model)
    - StaffService users (staff login via StaffService model)
    """
    
    def has_permission(self, request, view):
        if not super().has_permission(request, view):
            return False
        
        # Check if user is StaffService object (staff direct login)
        user_type = getattr(request.user, 'user_type', None)
        if user_type == 'staff':
            # Staff logged in through StaffService from ministry.models
            from ministry.models import StaffService
            return (
                request.user.is_active and 
                request.user.status == StaffService.Status.ACTIVE
            )
        
        # Check if user has staff_profile (Staff model - regular user linked to staff)
        if hasattr(request.user, 'staff_profile'):
            return request.user.staff_profile.is_active
        
        return False


class MinistryNoticeListCreateView(APIView):
    """
    GET: List notices for the authenticated admin's ministry
    POST: Upload a new notice for the ministry
    
    Used by: Ministry Admins, Staff Admins
    """
    permission_classes = [IsAuthenticated]  # Allow both ministry admin and staff
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def check_permissions(self, request):
        """Custom permission check to allow both ministry admin and staff"""
        super().check_permissions(request)
        
        # Allow if ministry admin
        from core.permissions import IsMinistryAdmin
        if IsMinistryAdmin().has_permission(request, self):
            return
        
        # Allow if staff user
        if IsStaffUser().has_permission(request, self):
            return
        
        from rest_framework.exceptions import PermissionDenied
        raise PermissionDenied("You don't have permission to access notices")
    
    def get(self, request):
        """List notices for the admin's ministry"""
        try:
            # Get ministry from request (set by middleware)
            ministry = getattr(request, 'ministry', None)
            if not ministry:
                return Response(
                    standardized_response(success=False, error="Ministry context not found"),
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Extract filters
            filters = {
                'service': request.query_params.get('service'),
                'is_active': request.query_params.get('is_active'),
                'ingestion_status': request.query_params.get('ingestion_status'),
                'search': request.query_params.get('search'),
            }
            # Convert is_active to boolean
            if filters.get('is_active') is not None:
                filters['is_active'] = filters['is_active'].lower() == 'true'
            
            # Remove None values
            filters = {k: v for k, v in filters.items() if v is not None}
            
            success, response_data, status_code = NoticeAdminService.get_notices_for_ministry(
                ministry_id=str(ministry.id),
                filters=filters if filters else None,
                request=request
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Error listing notices: {e}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to fetch notices"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def post(self, request):
        """Upload a new notice"""
        try:
            # Get ministry from request
            ministry = getattr(request, 'ministry', None)
            if not ministry:
                return Response(
                    standardized_response(success=False, error="Ministry context not found"),
                    status=status.HTTP_403_FORBIDDEN
                )
            
            success, response_data, status_code = NoticeAdminService.upload_notice(
                ministry_id=str(ministry.id),
                data=request.data,
                uploaded_by=request.user,
                request=request
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Error uploading notice: {e}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to upload notice"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class MinistryNoticeDetailView(APIView):
    """
    GET: Get notice details
    PATCH: Update notice
    DELETE: Soft delete notice
    
    Used by: Ministry Admins, Staff Admins
    """
    permission_classes = [IsAuthenticated]  # Allow both ministry admin and staff
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def check_permissions(self, request):
        """Custom permission check to allow both ministry admin and staff"""
        super().check_permissions(request)
        
        # Allow if ministry admin
        from core.permissions import IsMinistryAdmin
        if IsMinistryAdmin().has_permission(request, self):
            return
        
        # Allow if staff user
        if IsStaffUser().has_permission(request, self):
            return
        
        from rest_framework.exceptions import PermissionDenied
        raise PermissionDenied("You don't have permission to access this notice")
    
    def get(self, request, notice_id):
        """Get notice details"""
        try:
            from notices.models import Notice
            from notices.serializers import NoticeDetailSerializer
            
            ministry = getattr(request, 'ministry', None)
            if not ministry:
                return Response(
                    standardized_response(success=False, error="Ministry context not found"),
                    status=status.HTTP_403_FORBIDDEN
                )
            
            try:
                notice = Notice.objects.select_related(
                    'ministry', 'service', 'created_by'
                ).get(id=notice_id, ministry_id=ministry.id)
            except Notice.DoesNotExist:
                return Response(
                    standardized_response(success=False, error="Notice not found"),
                    status=status.HTTP_404_NOT_FOUND
                )
            
            serializer = NoticeDetailSerializer(notice, context={'request': request})
            
            return Response(
                standardized_response(success=True, data=serializer.data),
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            logger.error(f"Error getting notice: {e}")
            return Response(
                standardized_response(success=False, error="Failed to fetch notice"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def patch(self, request, notice_id):
        """Update notice"""
        try:
            ministry = getattr(request, 'ministry', None)
            if not ministry:
                return Response(
                    standardized_response(success=False, error="Ministry context not found"),
                    status=status.HTTP_403_FORBIDDEN
                )
            
            success, response_data, status_code = NoticeAdminService.update_notice(
                notice_id=notice_id,
                ministry_id=str(ministry.id),
                data=request.data,
                updated_by=request.user,
                request=request
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Error updating notice: {e}")
            return Response(
                standardized_response(success=False, error="Failed to update notice"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def delete(self, request, notice_id):
        """Soft delete notice"""
        try:
            ministry = getattr(request, 'ministry', None)
            if not ministry:
                return Response(
                    standardized_response(success=False, error="Ministry context not found"),
                    status=status.HTTP_403_FORBIDDEN
                )
            
            success, response_data, status_code = NoticeAdminService.delete_notice(
                notice_id=notice_id,
                ministry_id=str(ministry.id),
                deleted_by=request.user
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Error deleting notice: {e}")
            return Response(
                standardized_response(success=False, error="Failed to delete notice"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class MinistryNoticeStatsView(APIView):
    """
    GET: Get notice statistics for the ministry
    
    Used by: Ministry Admins, Staff Admins
    """
    permission_classes = [IsAuthenticated]  # Allow both ministry admin and staff
    
    def check_permissions(self, request):
        """Custom permission check to allow both ministry admin and staff"""
        super().check_permissions(request)
        
        # Allow if ministry admin
        from core.permissions import IsMinistryAdmin
        if IsMinistryAdmin().has_permission(request, self):
            return
        
        # Allow if staff user
        if IsStaffUser().has_permission(request, self):
            return
        
        from rest_framework.exceptions import PermissionDenied
        raise PermissionDenied("You don't have permission to access notice statistics")
    
    def get(self, request):
        try:
            ministry = getattr(request, 'ministry', None)
            if not ministry:
                return Response(
                    standardized_response(success=False, error="Ministry context not found"),
                    status=status.HTTP_403_FORBIDDEN
                )
            
            success, response_data, status_code = NoticeAdminService.get_notice_stats(
                ministry_id=str(ministry.id)
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Error getting notice stats: {e}")
            return Response(
                standardized_response(success=False, error="Failed to fetch statistics"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class NoticeRetryIngestionView(APIView):
    """
    POST: Retry RAG ingestion for a failed notice
    
    Used by: Ministry Admins
    """
    permission_classes = [IsAuthenticated, IsMinistryAdmin]
    
    def post(self, request, notice_id):
        try:
            ministry = getattr(request, 'ministry', None)
            if not ministry:
                return Response(
                    standardized_response(success=False, error="Ministry context not found"),
                    status=status.HTTP_403_FORBIDDEN
                )
            
            success, response_data, status_code = NoticeAdminService.retry_ingestion(
                notice_id=notice_id,
                ministry_id=str(ministry.id)
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Error retrying ingestion: {e}")
            return Response(
                standardized_response(success=False, error="Failed to retry ingestion"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class MinistryServicesForNoticeView(APIView):
    """
    GET: List services for the ministry (for notice upload dropdown)
    
    Used by: Ministry Admins, Staff Admins
    """
    permission_classes = [IsAuthenticated, IsMinistryAdmin]
    
    def get(self, request):
        try:
            from services.models import Service
            from services.serializers import ServicePublicListSerializer
            
            ministry = getattr(request, 'ministry', None)
            if not ministry:
                return Response(
                    standardized_response(success=False, error="Ministry context not found"),
                    status=status.HTTP_403_FORBIDDEN
                )
            
            services = Service.objects.filter(
                ministry_id=ministry.id,
                is_active=True
            ).order_by('name')
            
            serializer = ServicePublicListSerializer(
                services, 
                many=True, 
                context={'request': request}
            )
            
            return Response(
                standardized_response(
                    success=True, 
                    data=serializer.data,
                    count=services.count()
                ),
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            logger.error(f"Error listing services: {e}")
            return Response(
                standardized_response(success=False, error="Failed to fetch services"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ============================================
# STAFF ADMIN VIEWS
# ============================================

class StaffNoticeListCreateView(APIView):
    """
    GET: List notices for the staff's service
    POST: Upload a new notice (auto-attaches staff's ministry and service)
    
    Used by: Staff Admins only
    
    Staff admins can only:
    - See notices for their assigned service
    - Upload notices for their assigned service
    
    POST body:
    {
        "title": "Notice Title",
        "file": <file>
    }
    
    ministry and service are auto-attached from staff's profile.
    """
    permission_classes = [IsAuthenticated, IsStaffUser]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get(self, request):
        """List notices for staff's service"""
        try:
            # Get staff object (either StaffService or Staff model)
            staff = None
            user_type = getattr(request.user, 'user_type', None)
            
            if user_type == 'staff':
                # Direct StaffService login
                staff = request.user
            elif hasattr(request.user, 'staff_profile'):
                # Regular user with staff_profile
                staff = request.user.staff_profile
            
            if not staff:
                return Response(
                    standardized_response(success=False, error="Staff profile not found"),
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Extract filters
            filters = {
                'is_active': request.query_params.get('is_active'),
                'ingestion_status': request.query_params.get('ingestion_status'),
                'search': request.query_params.get('search'),
            }
            # Convert is_active to boolean
            if filters.get('is_active') is not None:
                filters['is_active'] = filters['is_active'].lower() == 'true'
            
            # Remove None values
            filters = {k: v for k, v in filters.items() if v is not None}
            
            success, response_data, status_code = NoticeAdminService.get_notices_for_staff(
                staff=staff,
                filters=filters if filters else None,
                request=request
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Error listing notices for staff: {e}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to fetch notices"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def post(self, request):
        """Upload a new notice for staff's service"""
        try:
            # Get staff object (either StaffService or Staff model)
            staff = None
            user_type = getattr(request.user, 'user_type', None)
            
            if user_type == 'staff':
                # Direct StaffService login
                staff = request.user
            elif hasattr(request.user, 'staff_profile'):
                # Regular user with staff_profile
                staff = request.user.staff_profile
            
            if not staff:
                return Response(
                    standardized_response(success=False, error="Staff profile not found"),
                    status=status.HTTP_403_FORBIDDEN
                )
            
            success, response_data, status_code = NoticeAdminService.upload_notice_as_staff(
                staff=staff,
                data=request.data,
                request=request
            )
            
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
            
        except Exception as e:
            logger.error(f"Error uploading notice as staff: {e}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to upload notice"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class StaffNoticeDetailView(APIView):
    """
    GET: Get notice details
    PATCH: Update notice (title only)
    DELETE: Soft delete notice
    
    Used by: Staff Admins only
    Staff can only access notices for their assigned service.
    """
    permission_classes = [IsAuthenticated, IsStaffUser]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get(self, request, notice_id):
        """Get notice details"""
        try:
            from notices.models import Notice
            from notices.serializers import NoticeDetailSerializer
            
            if not hasattr(request.user, 'staff_profile'):
                return Response(
                    standardized_response(success=False, error="Staff profile not found"),
                    status=status.HTTP_403_FORBIDDEN
                )
            
            staff = request.user.staff_profile
            
            try:
                notice = Notice.objects.select_related(
                    'ministry', 'service', 'created_by'
                ).get(id=notice_id, service=staff.service)
            except Notice.DoesNotExist:
                return Response(
                    standardized_response(success=False, error="Notice not found"),
                    status=status.HTTP_404_NOT_FOUND
                )
            
            serializer = NoticeDetailSerializer(notice, context={'request': request})
            
            return Response(
                standardized_response(success=True, data=serializer.data),
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            logger.error(f"Error getting notice detail: {e}")
            return Response(
                standardized_response(success=False, error="Failed to fetch notice"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def patch(self, request, notice_id):
        """Update notice (title only for staff)"""
        try:
            from notices.models import Notice
            from notices.serializers import NoticeDetailSerializer
            
            if not hasattr(request.user, 'staff_profile'):
                return Response(
                    standardized_response(success=False, error="Staff profile not found"),
                    status=status.HTTP_403_FORBIDDEN
                )
            
            staff = request.user.staff_profile
            
            try:
                notice = Notice.objects.get(id=notice_id, service=staff.service)
            except Notice.DoesNotExist:
                return Response(
                    standardized_response(success=False, error="Notice not found"),
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Staff can only update title and is_active
            if 'title' in request.data:
                notice.title = request.data['title']
            if 'is_active' in request.data:
                notice.is_active = request.data['is_active']
            
            notice.save()
            
            serializer = NoticeDetailSerializer(notice, context={'request': request})
            
            return Response(
                standardized_response(
                    success=True,
                    message="Notice updated successfully",
                    data=serializer.data
                ),
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            logger.error(f"Error updating notice: {e}")
            return Response(
                standardized_response(success=False, error="Failed to update notice"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def delete(self, request, notice_id):
        """Soft delete notice"""
        try:
            from notices.models import Notice
            
            if not hasattr(request.user, 'staff_profile'):
                return Response(
                    standardized_response(success=False, error="Staff profile not found"),
                    status=status.HTTP_403_FORBIDDEN
                )
            
            staff = request.user.staff_profile
            
            try:
                notice = Notice.objects.get(id=notice_id, service=staff.service)
            except Notice.DoesNotExist:
                return Response(
                    standardized_response(success=False, error="Notice not found"),
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Soft delete
            notice.is_active = False
            notice.save(update_fields=['is_active', 'updated_at'])
            
            logger.info(f"Notice deactivated by staff: {notice.id}")
            
            return Response(
                standardized_response(success=True, message="Notice deleted successfully"),
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            logger.error(f"Error deleting notice: {e}")
            return Response(
                standardized_response(success=False, error="Failed to delete notice"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )