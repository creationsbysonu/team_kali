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
    def login(email, password, device_info=None, request_meta=None, request=None, 
              place_slug=None, ministry_slug=None, service_slug=None):
        """
        Handle user login with email and password.
        This is for MINISTRY ADMIN, STAFF and SUPER ADMIN only (Web App).
        Citizens should use OTP authentication (Flutter App).
        
        Login Types:
        1. Super Admin: No place/ministry/service needed
        2. Ministry Admin: place_slug + ministry_slug required
        3. Staff: place_slug + ministry_slug + service_slug required
        
        Args:
            email: User email
            password: User password
            device_info: Optional device information
            request_meta: Request metadata for logging
            request: HTTP request object
            place_slug: Place slug for ministry/staff login
            ministry_slug: Ministry slug for ministry/staff login
            service_slug: Service slug for staff login only
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
            

            # Update last login
            try:
                user.last_login = timezone.now()
                user.save(update_fields=['last_login'])
            except Exception as save_error:
                logger.warning(f"[auth] Failed to update last_login: {str(save_error)}")
            
            # Log successful login
            if request_meta:
                logger.info(f"[auth] Login successful for user: {user.email} from IP: {request_meta.get('REMOTE_ADDR')}")
            
            # Validate login context (ministry vs super admin portal)
            ministry_data = None
            place_data = None
            service_data = None
            ministry_id = None
            place_id = None
            service_id = None
            
            # CASE 1: Staff login (place_slug + ministry_slug + service_slug)
            if place_slug and ministry_slug and service_slug:
                # Only staff can login to service
                if user.user_type != CustomUser.UserType.STAFF:
                    logger.warning(f"[auth] Non-staff tried service login: {email}")
                    return False, {
                        "success": False,
                        "error": "Only staff accounts can login to services."
                    }, 403
                
                # Validate place, ministry, service and staff assignment
                try:
                    from places.models import Place
                    from ministry.models import Ministry
                    from services.models import Service, ServiceStaff
                    
                    # Verify place
                    place = Place.objects.filter(slug=place_slug, is_active=True).first()
                    if not place:
                        return False, {"success": False, "error": "Place not found."}, 404
                    
                    # Verify ministry in this place
                    ministry = Ministry.objects.filter(
                        place=place,
                        slug=ministry_slug,
                        status=Ministry.Status.ACTIVE
                    ).first()
                    if not ministry:
                        return False, {"success": False, "error": "Ministry not found."}, 404
                    
                    if ministry.is_deleted:
                        return False, {"success": False, "error": "Ministry has been deleted."}, 403
                    
                    # Verify service in this ministry
                    service = Service.objects.filter(
                        ministry=ministry,
                        slug=service_slug,
                        is_active=True,
                        is_published=True
                    ).first()
                    if not service:
                        return False, {"success": False, "error": "Service not found."}, 404
                    
                    # Verify staff is assigned to this service
                    staff_assignment = ServiceStaff.objects.filter(
                        service=service,
                        user=user,
                        is_active=True
                    ).first()
                    if not staff_assignment:
                        return False, {
                            "success": False,
                            "error": "You are not assigned to this service."
                        }, 403
                    
                    place_data = {'id': str(place.id), 'name': place.name, 'slug': place.slug}
                    ministry_data = {'id': str(ministry.id), 'name': ministry.name, 'slug': ministry.slug}
                    service_data = {'id': str(service.id), 'name': service.name, 'slug': service.slug}
                    
                    # Set IDs for token generation
                    place_id = place.id
                    ministry_id = ministry.id
                    service_id = service.id
                    
                    logger.info(f"[auth] Staff login success: {email} -> {place.name}/{ministry.name}/{service.name}")
                    
                except Exception as e:
                    logger.error(f"[auth] Staff login validation error: {str(e)}")
                    return False, {"success": False, "error": "Failed to validate staff assignment."}, 500
            
            # CASE 2: Ministry Admin login (place_slug + ministry_slug)
            elif place_slug and ministry_slug:
                # Only admin can login to ministry
                if user.user_type != CustomUser.UserType.ADMIN:
                    if user.user_type == CustomUser.UserType.SUPER_ADMIN:
                        return False, {
                            "success": False,
                            "error": "Super admin accounts must login through the admin portal."
                        }, 403
                    elif user.user_type == CustomUser.UserType.STAFF:
                        return False, {
                            "success": False,
                            "error": "Staff must login through the service portal."
                        }, 403
                    else:
                        return False, {"success": False, "error": "Invalid credentials."}, 403
                
                try:
                    from places.models import Place
                    from ministry.models import MinistryMember, Ministry
                    
                    # Verify place
                    place = Place.objects.filter(slug=place_slug, is_active=True).first()
                    if not place:
                        return False, {"success": False, "error": "Place not found."}, 404
                    
                    # Verify ministry in this place
                    ministry = Ministry.objects.filter(
                        place=place,
                        slug=ministry_slug,
                        status=Ministry.Status.ACTIVE
                    ).first()
                    if not ministry:
                        return False, {"success": False, "error": "Ministry not found."}, 404
                    
                    if ministry.is_deleted:
                        return False, {"success": False, "error": "Ministry has been deleted."}, 403
                    
                    if ministry.status == Ministry.Status.SUSPENDED:
                        return False, {"success": False, "error": "Ministry has been suspended."}, 403
                    
                    # Verify user is admin of this ministry
                    membership = MinistryMember.objects.filter(
                        user=user,
                        ministry=ministry,
                        is_active=True
                    ).first()
                    
                    if not membership:
                        return False, {
                            "success": False,
                            "error": "You are not an admin of this ministry."
                        }, 403
                    
                    place_data = {'id': str(place.id), 'name': place.name, 'slug': place.slug}
                    ministry_data = {'id': str(ministry.id), 'name': ministry.name, 'slug': ministry.slug}
                    
                    # Set IDs for token generation (done at the end)
                    place_id = place.id
                    ministry_id = ministry.id
                    
                    logger.info(f"[auth] Ministry admin login success: {email} -> {place.name}/{ministry.name}")
                    
                except Exception as e:
                    logger.error(f"[auth] Ministry validation error: {str(e)}")
                    return False, {"success": False, "error": "Failed to validate ministry membership."}, 500
            
            # CASE 3: Super Admin portal login (no place/ministry/service)
            else:
                if user.user_type != CustomUser.UserType.SUPER_ADMIN:
                    if user.user_type in [CustomUser.UserType.STAFF, CustomUser.UserType.ADMIN]:
                        return False, {
                            "success": False,
                            "error": "Please login through your ministry or service portal."
                        }, 403
                    else:
                        return False, {"success": False, "error": "Invalid login credentials."}, 403
                
                logger.info(f"[auth] Super admin login success: {email}")
            
            # Generate tokens with context (after all validations)
            try:
                tokens = TokenManager.generate_tokens(
                    user,
                    ministry_id=ministry_id,
                    place_id=place_id,
                    service_id=service_id
                )
            except Exception as token_error:
                logger.error(f"[auth] Token generation error: {str(token_error)}")
                return False, {
                    "success": False,
                    "error": "Token generation failed"
                }, 500
            
            response_data = {
                'user': serializer.data,
                'tokens': tokens,
                'email_verified': user.is_verified,
                'verification_needed': not user.is_verified and settings.REQUIRE_EMAIL_VERIFICATION
            }
            
            # Add context info based on login type
            if place_data:
                response_data['place'] = place_data
            if ministry_data:
                response_data['ministry'] = ministry_data
            if service_data:
                response_data['service'] = service_data
            
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
        
        # Compare as strings since JWT stores user_id as string
        if not is_valid or str(user_id) != str(user.id):
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
    def logout(user, refresh_token=None):
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
        
        user_info = user.email if user else "anonymous"
        logger.info(f"User logged out: {user_info}")
        return True, {
            "success": True, 
            "message": "Successfully logged out"
        }, 200