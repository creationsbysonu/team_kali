"""
Custom JWT Authentication

Handles multiple user types: CustomUser, Ministry, StaffService
"""
import logging
from typing import Any
from django.core.exceptions import ValidationError
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import InvalidToken, AuthenticationFailed, TokenError
from rest_framework_simplejwt.tokens import Token

logger = logging.getLogger(__name__)


class MultiUserTypeJWTAuthentication(JWTAuthentication):
    """
    JWT Authentication that supports multiple user types:
    - CustomUser (citizens, admins, super admin)
    - Ministry (ministry login)
    - StaffService (staff login)
    
    Uses the 'user_type' claim in the JWT to determine which model to query.
    """
    
    def get_user(self, validated_token: Token) -> Any:  # type: ignore[override]
        """
        Get the user object from the validated token.
        Supports multiple user types based on token claims.
        
        Raises:
            InvalidToken: If token is malformed or missing required claims
            AuthenticationFailed: If user not found or inactive
        """
        try:
            # Extract claims with validation
            user_id = validated_token.get('user_id')
            if not user_id:
                logger.warning("[auth] Token missing user_id claim")
                raise InvalidToken('Token contained no recognizable user identification')
            
            user_type = validated_token.get('user_type', 'citizen')  # Default to citizen for backward compatibility
            
            # Handle different user types
            if user_type == 'staff':
                return self._get_staff_user(user_id)
            elif user_type == 'ministry':
                return self._get_ministry_user(user_id)
            else:
                return self._get_custom_user(user_id)
        
        except (InvalidToken, AuthenticationFailed):
            # Re-raise authentication exceptions as-is
            raise
        except (KeyError, ValueError, TypeError) as e:
            logger.error(f"[auth] Token validation error: {type(e).__name__}: {str(e)}")
            raise InvalidToken('Token contained invalid user identification')
        except ValidationError as e:
            logger.error(f"[auth] User validation error: {str(e)}")
            raise AuthenticationFailed('Invalid user data', code='invalid_user')
        except Exception as e:
            logger.error(f"[auth] Unexpected authentication error: {type(e).__name__}: {str(e)}")
            import traceback
            logger.error(traceback.format_exc())
            raise AuthenticationFailed('Authentication failed', code='authentication_failed')
    
    def _get_staff_user(self, user_id):
        """Get and validate staff service user"""
        from ministry.models import StaffService
        
        try:
            staff_service = StaffService.objects.select_related(
                'ministry', 
                'ministry__place'
            ).get(id=user_id)
            
            # Validate staff service status
            if not staff_service.is_active:
                logger.warning(f"[auth] Inactive staff service attempted access: {user_id}")
                raise AuthenticationFailed('Staff service is inactive', code='user_inactive')
            
            if staff_service.status != StaffService.Status.ACTIVE:
                logger.warning(f"[auth] Non-active staff service status: {user_id} - {staff_service.status}")
                raise AuthenticationFailed(f'Staff service is {staff_service.status}', code='user_inactive')
            
            # Validate ministry is still active
            if staff_service.ministry.status != staff_service.ministry.Status.ACTIVE:
                logger.warning(f"[auth] Staff service belongs to inactive ministry: {user_id}")
                raise AuthenticationFailed('Ministry is no longer active', code='ministry_inactive')
            
            # Add authentication attributes dynamically
            setattr(staff_service, 'is_authenticated', True)
            setattr(staff_service, 'is_anonymous', False)
            setattr(staff_service, 'user_type', 'staff')
            
            logger.debug(f"[auth] Staff authenticated: {staff_service.staff_name} ({staff_service.email})")
            return staff_service
            
        except StaffService.DoesNotExist:
            logger.warning(f"[auth] Staff service not found: {user_id}")
            raise AuthenticationFailed('Staff service not found', code='user_not_found')
    
    def _get_ministry_user(self, user_id):
        """Get and validate ministry user"""
        from ministry.models import Ministry
        
        try:
            ministry = Ministry.objects.select_related('place').get(id=user_id)
            
            # Validate ministry status
            if ministry.status != Ministry.Status.ACTIVE:
                logger.warning(f"[auth] Non-active ministry attempted access: {user_id} - {ministry.status}")
                raise AuthenticationFailed(f'Ministry is {ministry.status}', code='user_inactive')
            
            # Check soft delete
            if ministry.is_deleted:
                logger.warning(f"[auth] Deleted ministry attempted access: {user_id}")
                raise AuthenticationFailed('Ministry has been deleted', code='user_deleted')
            
            # Validate place is active
            if ministry.place and not ministry.place.is_active:
                logger.warning(f"[auth] Ministry belongs to inactive place: {user_id}")
                raise AuthenticationFailed('Place is no longer active', code='place_inactive')
            
            # Add authentication attributes dynamically
            setattr(ministry, 'is_authenticated', True)
            setattr(ministry, 'is_anonymous', False)
            setattr(ministry, 'user_type', 'ministry')
            
            logger.debug(f"[auth] Ministry authenticated: {ministry.name} ({ministry.email})")
            return ministry
            
        except Ministry.DoesNotExist:
            logger.warning(f"[auth] Ministry not found: {user_id}")
            raise AuthenticationFailed('Ministry not found', code='user_not_found')
    
    def _get_custom_user(self, user_id):
        """Get and validate CustomUser (citizens, admins, super admin)"""
        from authentication.models import CustomUser
        
        try:
            user = CustomUser.objects.get(id=user_id)
            
            # Validate user is active
            if not user.is_active:
                logger.warning(f"[auth] Inactive user attempted access: {user.email}")
                raise AuthenticationFailed('User account is disabled', code='user_inactive')
            
            # Optional: Check email verification for citizens
            # if user.user_type == CustomUser.UserType.CITIZEN and not user.is_verified:
            #     logger.warning(f"[auth] Unverified user attempted access: {user.email}")
            #     raise AuthenticationFailed('Email verification required', code='email_not_verified')
            
            logger.debug(f"[auth] User authenticated: {user.email} ({user.user_type})")
            return user
            
        except CustomUser.DoesNotExist:
            logger.warning(f"[auth] User not found: {user_id}")
            raise AuthenticationFailed('User not found', code='user_not_found')
