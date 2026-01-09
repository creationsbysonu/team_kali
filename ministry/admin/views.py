"""
Super Admin Ministry Views

System-wide ministry management endpoints.
Super admin only.
"""
import logging
import traceback
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from ministry.core.permissions import IsSuperAdmin
from .services import SuperAdminMinistryService

logger = logging.getLogger(__name__)


class SuperAdminMinistryListView(BaseAPIView):
    """
    GET /ministrys/admin/
    POST /ministrys/admin/
    
    List all ministrys / Create new ministry.
    Super admin only.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get(self, request):
        try:
            filters = {
                'status': request.query_params.get('status'),
                'search': request.query_params.get('search'),
            }
            
            success, response_data, status_code = SuperAdminMinistryService.get_list(
                filters=filters,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] List view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch ministrys"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def post(self, request):
        try:
            success, response_data, status_code = SuperAdminMinistryService.create_ministry(
                data=request.data,
                admin_user=request.user,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Create view error: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                standardized_response(success=False, error="Failed to create ministry"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SuperAdminMinistryDetailView(BaseAPIView):
    """
    GET /ministrys/admin/<uuid:pk>/
    PUT /ministrys/admin/<uuid:pk>/
    DELETE /ministrys/admin/<uuid:pk>/
    
    Get/Update/Delete ministry.
    Super admin only.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get(self, request, pk):
        try:
            success, response_data, status_code = SuperAdminMinistryService.get_detail(
                ministry_id=pk,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Detail view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch ministry"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def put(self, request, pk):
        try:
            success, response_data, status_code = SuperAdminMinistryService.update_ministry(
                ministry_id=pk,
                data=request.data,
                admin_user=request.user,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Update view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to update ministry"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def delete(self, request, pk):
        """Soft delete a ministry (can be restored)"""
        try:
            success, response_data, status_code = SuperAdminMinistryService.soft_delete_ministry(
                ministry_id=pk,
                admin_user=request.user
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Delete view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to delete ministry"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SuperAdminMinistryDeletedListView(BaseAPIView):
    """
    GET /ministry/admin/deleted/
    
    List all soft-deleted ministries.
    Super admin only.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    
    def get(self, request):
        try:
            success, response_data, status_code = SuperAdminMinistryService.get_deleted_list(
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Deleted list error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch deleted ministries"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SuperAdminMinistryRestoreView(BaseAPIView):
    """
    POST /ministry/admin/<uuid:pk>/restore/
    
    Restore a soft-deleted ministry.
    Super admin only.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    
    def post(self, request, pk):
        try:
            success, response_data, status_code = SuperAdminMinistryService.restore_ministry(
                ministry_id=pk,
                admin_user=request.user
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Restore view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to restore ministry"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SuperAdminMinistryHardDeleteView(BaseAPIView):
    """
    POST /ministry/admin/<uuid:pk>/hard-delete/
    
    Permanently delete a ministry (irreversible).
    Super admin only.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    
    def post(self, request, pk):
        try:
            confirm = request.data.get('confirm', False)
            
            success, response_data, status_code = SuperAdminMinistryService.hard_delete_ministry(
                ministry_id=pk,
                admin_user=request.user,
                confirm=confirm
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Hard delete view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to delete ministry"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SuperAdminMinistryResetPasswordView(BaseAPIView):
    """
    POST /ministry/admin/<uuid:pk>/reset-password/
    
    Reset ministry admin's password.
    Super admin only.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    
    def post(self, request, pk):
        try:
            new_password = request.data.get('new_password')
            
            if not new_password:
                return Response(
                    standardized_response(success=False, error="new_password is required"),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            success, response_data, status_code = SuperAdminMinistryService.reset_ministry_password(
                ministry_id=pk,
                new_password=new_password,
                admin_user=request.user
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Reset password view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to reset password"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SuperAdminMinistryActivateView(BaseAPIView):
    """
    POST /ministrys/admin/<uuid:pk>/activate/
    
    Activate a ministry.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    
    def post(self, request, pk):
        try:
            success, response_data, status_code = SuperAdminMinistryService.activate_ministry(
                ministry_id=pk,
                admin_user=request.user
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Activate view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to activate ministry"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SuperAdminMinistrySuspendView(BaseAPIView):
    """
    POST /ministrys/admin/<uuid:pk>/suspend/
    
    Suspend a ministry.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    
    def post(self, request, pk):
        try:
            reason = request.data.get('reason')
            
            success, response_data, status_code = SuperAdminMinistryService.suspend_ministry(
                ministry_id=pk,
                admin_user=request.user,
                reason=reason
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Suspend view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to suspend ministry"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SuperAdminMinistryAddStaffView(BaseAPIView):
    """
    POST /ministrys/admin/<uuid:pk>/add-staff/
    
    Add existing user as staff to a ministry.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    
    def post(self, request, pk):
        try:
            user_id = request.data.get('user_id')
            if not user_id:
                return Response(
                    standardized_response(success=False, error="user_id is required"),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            success, response_data, status_code = SuperAdminMinistryService.add_staff_to_ministry(
                ministry_id=pk,
                user_id=user_id,
                admin_user=request.user
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Add staff view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to add staff"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# =========================================
# Staff User Management Views
# =========================================

class SuperAdminMinistryUsersView(BaseAPIView):
    """
    GET /ministrys/admin/<uuid:pk>/users/
    POST /ministrys/admin/<uuid:pk>/users/
    
    List ministry users / Create staff user for ministry.
    Super admin only.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    
    def get(self, request, pk):
        """List all users for a ministry"""
        try:
            success, response_data, status_code = SuperAdminMinistryService.get_ministry_users(
                ministry_id=pk,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] List users error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch users"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def post(self, request, pk):
        """Create a new staff user for a ministry"""
        try:
            success, response_data, status_code = SuperAdminMinistryService.create_staff_user(
                ministry_id=pk,
                data=request.data,
                admin_user=request.user,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Create user error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to create user"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SuperAdminMinistryUserDetailView(BaseAPIView):
    """
    GET /ministrys/admin/<uuid:pk>/users/<uuid:user_id>/
    PUT /ministrys/admin/<uuid:pk>/users/<uuid:user_id>/
    DELETE /ministrys/admin/<uuid:pk>/users/<uuid:user_id>/
    
    Get/Update/Delete a staff user.
    Super admin only.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    
    def put(self, request, pk, user_id):
        """Update a staff user"""
        try:
            success, response_data, status_code = SuperAdminMinistryService.update_staff_user(
                ministry_id=pk,
                user_id=user_id,
                data=request.data,
                admin_user=request.user
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Update user error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to update user"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def delete(self, request, pk, user_id):
        """Remove a staff user from ministry"""
        try:
            success, response_data, status_code = SuperAdminMinistryService.delete_staff_user(
                ministry_id=pk,
                user_id=user_id,
                admin_user=request.user
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Delete user error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to delete user"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
