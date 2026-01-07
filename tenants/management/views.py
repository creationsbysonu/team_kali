"""
Ministry Management Views

Endpoints for ministry self-management.
Any ministry staff can manage their organization.
"""
import logging
import traceback
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser

from authentication.core.base_view import BaseAPIView
from authentication.core.response import standardized_response
from tenants.core.permissions import IsTenantMember
from .services import TenantManagementService

logger = logging.getLogger(__name__)


class TenantDetailView(BaseAPIView):
    """
    GET /tenants/me/
    PUT /tenants/me/
    
    Get/Update current tenant details.
    """
    permission_classes = [IsAuthenticated, IsTenantMember]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get(self, request):
        try:
            success, response_data, status_code = TenantManagementService.get_details(
                tenant=request.tenant,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[tenant] Detail view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch details"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def put(self, request):
        # Any ministry staff can update basic info
        try:
            success, response_data, status_code = TenantManagementService.update_details(
                tenant=request.tenant,
                data=request.data,
                user=request.user,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[tenant] Update view error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to update details"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class TenantSettingsView(BaseAPIView):
    """
    GET /tenants/me/settings/
    PUT /tenants/me/settings/
    
    Get/Update ministry settings (any staff).
    """
    permission_classes = [IsAuthenticated, IsTenantMember]
    
    def get(self, request):
        try:
            return Response(
                standardized_response(
                    success=True,
                    data={"settings": request.tenant.settings}
                ),
                status=status.HTTP_200_OK
            )
        except Exception as e:
            logger.error(f"[tenant] Settings get error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch settings"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def put(self, request):
        try:
            success, response_data, status_code = TenantManagementService.update_settings(
                tenant=request.tenant,
                settings_data=request.data,
                user=request.user
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[tenant] Settings update error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to update settings"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class TenantMemberListView(BaseAPIView):
    """
    GET /tenants/me/members/
    
    List tenant members.
    """
    permission_classes = [IsAuthenticated, IsTenantMember]
    
    def get(self, request):
        try:
            success, response_data, status_code = TenantManagementService.get_members(
                tenant=request.tenant,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[tenant] Members list error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch members"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class TenantMemberDetailView(BaseAPIView):
    """
    DELETE /tenants/me/members/<uuid:pk>/
    
    Remove ministry staff member.
    """
    permission_classes = [IsAuthenticated, IsTenantMember]
    
    def delete(self, request, pk):
        try:
            success, response_data, status_code = TenantManagementService.remove_member(
                tenant=request.tenant,
                member_id=pk,
                removed_by=request.user
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[tenant] Member remove error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to remove member"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class TenantInvitationListView(BaseAPIView):
    """
    GET /tenants/me/invitations/
    POST /tenants/me/invitations/
    
    List/Create invitations (any staff).
    """
    permission_classes = [IsAuthenticated, IsTenantMember]
    
    def get(self, request):
        try:
            success, response_data, status_code = TenantManagementService.get_invitations(
                tenant=request.tenant,
                request=request
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[tenant] Invitations list error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to fetch invitations"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def post(self, request):
        try:
            email = request.data.get('email')
            
            if not email:
                return Response(
                    standardized_response(success=False, error="Email is required"),
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            success, response_data, status_code = TenantManagementService.create_invitation(
                tenant=request.tenant,
                email=email,
                invited_by=request.user
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[tenant] Create invitation error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to create invitation"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class TenantInvitationDetailView(BaseAPIView):
    """
    DELETE /tenants/me/invitations/<uuid:pk>/
    
    Cancel invitation (any staff).
    """
    permission_classes = [IsAuthenticated, IsTenantMember]
    
    def delete(self, request, pk):
        try:
            success, response_data, status_code = TenantManagementService.cancel_invitation(
                tenant=request.tenant,
                invitation_id=pk,
                cancelled_by=request.user
            )
            return Response(
                standardized_response(**response_data),
                status=status_code
            )
        except Exception as e:
            logger.error(f"[tenant] Cancel invitation error: {str(e)}")
            return Response(
                standardized_response(success=False, error="Failed to cancel invitation"),
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
