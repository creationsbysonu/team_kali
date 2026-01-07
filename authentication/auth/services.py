import logging
import traceback
from django.utils import timezone
from django.conf import settings
from django.core.cache import cache
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError

from authentication.serializers import UserSerializer
from authentication.core.jwt_utils import TokenManager
from authentication.models import CustomUser
from rest_framework_simplejwt.tokens import RefreshToken

logger = logging.getLogger(__name__)


class AuthenticationService:
    """Service class to handle authentication-related business logic for Ministry Users & Super Admin (Web App)"""
    
    @staticmethod
    def login(email, password, device_info=None, request_meta=None, request=None):
        """
        Handle user login with email and password.
        This is for MINISTRY USERS and SUPER ADMIN only (Web App).
        Citizens should use OTP authentication (Flutter App).
        """
        if not email or not password:
            return False, {"success": False, "error": "Email and password are required."}, 400
        
        if request_meta:
            logger.info(f"[auth] Login attempt from IP: {request_meta.get('REMOTE_ADDR')}, User-Agent: {request_meta.get('HTTP_USER_AGENT')}")
        
        try:
            # Check for account lockout
            if cache.get(f"account_lockout:{email}"):
                logger.warning(f"[auth] Login attempt for locked account: {email}")
                return False, {
                    "success": False,
                    "error": "Account temporarily locked due to multiple failed attempts. Try again later.",
                    "lockout": True
                }, 403
            
            # Check if user exists and validate user type
            user_check = CustomUser.objects.filter(email=email).first()
            if not user_check:
                logger.warning(f"[auth] Login attempt for non-existent email: {email}")
                failed_attempts = cache.get(f"failed_logins:{email}", 0) + 1
                cache.set(f"failed_logins:{email}", failed_attempts, timeout=1800)
                return False, {
                    "success": False,
                    "error": "Invalid email or password"
                }, 401
            
            # Check if user is a citizen - they should use OTP
            if user_check.user_type == CustomUser.UserType.CITIZEN:
                logger.warning(f"[auth] Citizen tried password login: {email}")
                return False, {
                    "success": False,
                    "error": "Please use OTP login for citizen accounts."
                }, 403
            
            # Authenticate with password
            user = authenticate(username=email, password=password)
            
            if not user:
                # Increment failed login attempts
                failed_attempts = cache.get(f"failed_logins:{email}", 0) + 1
                cache.set(f"failed_logins:{email}", failed_attempts, timeout=1800)
                
                # Lock account after 5 failed attempts
                if failed_attempts >= 5:
                    cache.set(f"account_lockout:{email}", True, timeout=900)
                    logger.warning(f"[auth] Account locked due to failed attempts: {email}")
                    return False, {
                        "success": False,
                        "error": "Account temporarily locked due to multiple failed attempts. Try again later.",
                        "lockout": True
                    }, 403
                
                logger.warning(f"[auth] Failed login attempt for email: {email}")
                return False, {
                    "success": False,
                    "error": "Invalid email or password"
                }, 401
            
            if not user.is_active:
                logger.warning(f"[auth] Login attempt for disabled account: {email}")
                return False, {
                    "success": False,
                    "error": "Account is disabled. Please contact support."
                }, 403
            
            # Clear failed login attempts on success
            cache.delete(f"failed_logins:{email}")
            
            # Serialize user data
            try:
                context = {'request': request} if request else {}
                serializer = UserSerializer(user, context=context)
            except Exception as serializer_error:
                logger.error(f"[auth] User serialization error: {str(serializer_error)}")
                return False, {
                    "success": False,
                    "error": "User data serialization failed"
                }, 500
            
            # Generate tokens
            try:
                tokens = TokenManager.generate_tokens(user)
            except Exception as token_error:
                logger.error(f"[auth] Token generation error: {str(token_error)}")
                return False, {
                    "success": False,
                    "error": "Token generation failed"
                }, 500
            
            # Update last login
            try:
                user.last_login = timezone.now()
                user.save(update_fields=['last_login'])
            except Exception as save_error:
                logger.warning(f"[auth] Failed to update last_login: {str(save_error)}")
            
            # Log successful login
            if request_meta:
                logger.info(f"[auth] Login successful for user: {user.email} from IP: {request_meta.get('REMOTE_ADDR')}")
            
            # Get tenant info for staff/admin users
            tenant_data = None
            if user.user_type in ['staff', 'admin']:
                try:
                    from tenants.models import TenantMember
                    membership = TenantMember.objects.filter(
                        user=user, is_active=True
                    ).select_related('tenant').first()
                    if membership:
                        tenant_data = {
                            'id': str(membership.tenant.id),
                            'name': membership.tenant.name,
                            'slug': membership.tenant.slug,
                            'role': membership.role,
                        }
                except Exception as tenant_error:
                    logger.warning(f"[auth] Failed to fetch tenant info: {str(tenant_error)}")
            
            response_data = {
                'user': serializer.data,
                'tokens': tokens,
                'email_verified': user.is_verified,
                'verification_needed': not user.is_verified and settings.REQUIRE_EMAIL_VERIFICATION
            }
            
            # Add tenant info if available
            if tenant_data:
                response_data['tenant'] = tenant_data
            
            return True, {
                "success": True,
                "data": response_data
            }, 200
            
        except ValidationError as ve:
            logger.error(f"[auth] Validation error during login: {str(ve)}")
            return False, {
                "success": False,
                "error": f"Validation error: {str(ve)}"
            }, 400
            
        except Exception as e:
            logger.error(f"[auth] Unexpected login error: {str(e)}")
            logger.error(f"[auth] Login error traceback: {traceback.format_exc()}")
            return False, {
                "success": False,
                "error": "Authentication failed. Please try again"
            }, 500
    
    @staticmethod
    def refresh_token(refresh_token):
        """Refresh an authentication token"""
        if not refresh_token:
            return False, {"success": False, "error": "Refresh token is required"}, 400
        
        try:
            tokens = TokenManager.refresh_tokens(refresh_token) 
            return True, {
                "success": True, 
                "data": {
                    'access_token': tokens['access_token'], 
                    "refresh_token": tokens['refresh_token'], 
                    'token_type': tokens['token_type'], 
                    'expires_in': tokens['expires_in']
                }
            }, 200
            
        except Exception as e:
            logger.error(f"Token refresh error: {str(e)}")
            return False, {
                "success": False, 
                "error": "An error occurred during token refresh"
            }, 500
        
    @staticmethod
    def validate_token(token, user):
        """Validate a token and check if it belongs to the user"""
        is_valid, user_id, token_type = TokenManager.validate_token(token)
        
        if not is_valid or user_id != user.id:
            logger.warning(f"Token validation failed: expected user {user.id}, got {user_id}")
            return False, {"success": False, "error": "Token validation failed"}, 401
        
        is_verified = user.is_verified
        logger.info(f"Token validation for user {user.id}: is_verified={is_verified}")
        
        return True, {
            "success": True, 
            "data": {
                'valid': True, 
                'user_id': str(user.id), 
                'email_verified': is_verified
            }
        }, 200
        
        
    @staticmethod
    def logout(user, refresh_token =None):
        """Handle user logout, invalidating tokens as needed"""
        if refresh_token:
            try: 
                token = RefreshToken(refresh_token)
                jti = token.get('jti')
                if jti:
                    TokenManager.blacklist_token(jti)
                    logger.info(f"Token blacklisted during logout: {jti}")
            except Exception as e:
                logger.warning(f"Error blacklisting token during logout: {str(e)}")
                
        logger.info(f"User logged out: {user.id}")
        return True, {
            "success": True, 
            "message": "Successfully logged out"
        }, 200