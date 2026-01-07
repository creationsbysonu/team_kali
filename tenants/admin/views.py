"""
Super Admin Tenant Views

System-wide tenant management endpoints.
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
from tenants.core.permissions import IsSuperAdmin
from .services import SuperAdminTenantService

logger = logging.getLogger(__name__)


class SuperAdminTenantListView(BaseAPIView):
    """
    GET /tenants/admin/
    POST /tenants/admin/
    
    List all tenants / Create new tenant.
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
            
            success, response_data, status_code = SuperAdminTenantService.get_list(
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
                standardized_response(success=False, error="Failed to fetch tenants"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def post(self, request):
        try:
            success, response_data, status_code = SuperAdminTenantService.create_tenant(
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
                standardized_response(success=False, error="Failed to create tenant"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SuperAdminTenantDetailView(BaseAPIView):
    """
    GET /tenants/admin/<uuid:pk>/
    PUT /tenants/admin/<uuid:pk>/
    DELETE /tenants/admin/<uuid:pk>/
    
    Get/Update/Delete tenant.
    Super admin only.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get(self, request, pk):
        try:
            success, response_data, status_code = SuperAdminTenantService.get_detail(
                tenant_id=pk,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Detail view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch tenant"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def put(self, request, pk):
        try:
            success, response_data, status_code = SuperAdminTenantService.update_tenant(
                tenant_id=pk,
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
                standardized_response(success=False, error="Failed to update tenant"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def delete(self, request, pk):
        try:
            success, response_data, status_code = SuperAdminTenantService.delete_tenant(
                tenant_id=pk,
                admin_user=request.user
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Delete view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to delete tenant"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SuperAdminTenantActivateView(BaseAPIView):
    """
    POST /tenants/admin/<uuid:pk>/activate/
    
    Activate a tenant.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    
    def post(self, request, pk):
        try:
            success, response_data, status_code = SuperAdminTenantService.activate_tenant(
                tenant_id=pk,
                admin_user=request.user
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[super_admin] Activate view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to activate tenant"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SuperAdminTenantSuspendView(BaseAPIView):
    """
    POST /tenants/admin/<uuid:pk>/suspend/
    
    Suspend a tenant.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    
    def post(self, request, pk):
        try:
            reason = request.data.get('reason')
            
            success, response_data, status_code = SuperAdminTenantService.suspend_tenant(
                tenant_id=pk,
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
                standardized_response(success=False, error="Failed to suspend tenant"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SuperAdminTenantAddStaffView(BaseAPIView):
    """
    POST /tenants/admin/<uuid:pk>/add-staff/
    
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
            
            success, response_data, status_code = SuperAdminTenantService.add_staff_to_tenant(
                tenant_id=pk,
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

class SuperAdminTenantUsersView(BaseAPIView):
    """
    GET /tenants/admin/<uuid:pk>/users/
    POST /tenants/admin/<uuid:pk>/users/
    
    List tenant users / Create staff user for tenant.
    Super admin only.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    
    def get(self, request, pk):
        """List all users for a tenant"""
        try:
            success, response_data, status_code = SuperAdminTenantService.get_tenant_users(
                tenant_id=pk,
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
        """Create a new staff user for a tenant"""
        try:
            success, response_data, status_code = SuperAdminTenantService.create_staff_user(
                tenant_id=pk,
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


class SuperAdminTenantUserDetailView(BaseAPIView):
    """
    GET /tenants/admin/<uuid:pk>/users/<uuid:user_id>/
    PUT /tenants/admin/<uuid:pk>/users/<uuid:user_id>/
    DELETE /tenants/admin/<uuid:pk>/users/<uuid:user_id>/
    
    Get/Update/Delete a staff user.
    Super admin only.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    
    def put(self, request, pk, user_id):
        """Update a staff user"""
        try:
            success, response_data, status_code = SuperAdminTenantService.update_staff_user(
                tenant_id=pk,
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
        """Remove a staff user from tenant"""
        try:
            success, response_data, status_code = SuperAdminTenantService.delete_staff_user(
                tenant_id=pk,
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
