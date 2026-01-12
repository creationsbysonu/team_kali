"""
Ministry Authentication Service

Handles ministry login authentication.
Ministry logs in with email + password set by super admin.
"""
import logging
from django.core.cache import cache
from authentication.core.jwt_utils import TokenManager
from ministry.models import Ministry
from ministry.serializers import MinistrySerializer

logger = logging.getLogger(__name__)


class MinistryAuthService:
    """Service for ministry authentication"""
    
    @staticmethod
    def login(email, password, place_slug, ministry_slug, request=None):
        """
        Authenticate ministry with email and password.
        
        Flow:
        1. User selects place → sees ministries
        2. User selects ministry → login form appears
        3. Ministry logs in with email/password
        4. System returns JWT tokens for ministry dashboard access
        
        Args:
            email: Ministry email
            password: Ministry password
            place_slug: Place slug for context validation
            ministry_slug: Ministry slug for context validation
            request: HTTP request for logging
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        if not email or not password:
            return False, {
                "success": False,
                "error": "Email and password are required"
            }, 400
        
        if not place_slug or not ministry_slug:
            return False, {
                "success": False,
                "error": "Place and ministry context required"
            }, 400
        
        try:
            # Check for account lockout
            lockout_key = f"ministry_lockout:{email}"
            if cache.get(lockout_key):
                logger.warning(f"[ministry_auth] Login attempt for locked ministry: {email}")
                return False, {
                    "success": False,
                    "error": "Account temporarily locked due to multiple failed attempts. Try again later.",
                    "lockout": True
                }, 403
            
            # Find ministry by email, place, and slug
            from places.models import Place
            
            place = Place.objects.filter(slug=place_slug, is_active=True).first()
            if not place:
                return False, {
                    "success": False,
                    "error": "Place not found"
                }, 404
            
            ministry = Ministry.objects.filter(
                email=email,
                place=place,
                slug=ministry_slug,
                status=Ministry.Status.ACTIVE
            ).first()
            
            if not ministry:
                # Increment failed attempts
                failed_key = f"ministry_failed_logins:{email}"
                failed_attempts = cache.get(failed_key, 0) + 1
                cache.set(failed_key, failed_attempts, timeout=1800)
                
                logger.warning(f"[ministry_auth] Login attempt for non-existent ministry: {email}")
                return False, {
                    "success": False,
                    "error": "Invalid email or password"
                }, 401
            
            # Check if ministry is deleted
            if ministry.is_deleted:
                return False, {
                    "success": False,
                    "error": "Ministry has been deleted"
                }, 403
            
            # Verify password
            if not ministry.password or not ministry.check_password(password):
                # Increment failed attempts
                failed_key = f"ministry_failed_logins:{email}"
                failed_attempts = cache.get(failed_key, 0) + 1
                cache.set(failed_key, failed_attempts, timeout=1800)
                
                # Lock account after 5 failed attempts
                if failed_attempts >= 5:
                    cache.set(lockout_key, True, timeout=900)  # 15 minutes
                    logger.warning(f"[ministry_auth] Ministry locked due to failed attempts: {email}")
                    return False, {
                        "success": False,
                        "error": "Account temporarily locked due to multiple failed attempts. Try again later.",
                        "lockout": True
                    }, 403
                
                logger.warning(f"[ministry_auth] Invalid password for ministry: {email}")
                return False, {
                    "success": False,
                    "error": "Invalid email or password"
                }, 401
            
            # Clear failed login attempts on success
            cache.delete(f"ministry_failed_logins:{email}")
            
            # Generate JWT tokens for ministry
            # Create a pseudo-user dict for token generation
            ministry_user_data = {
                'id': str(ministry.id),
                'email': ministry.email,
                'username': ministry.slug,
                'is_staff': False,
                'user_type': 'ministry',  # Custom type for ministry login
                'ministry_id': str(ministry.id),
                'ministry_name': ministry.name,
                'ministry_slug': ministry.slug,
                'place_id': str(ministry.place.id),
                'place_name': ministry.place.name,
                'place_slug': ministry.place.slug,
            }
            
            # Generate tokens with ministry context
            try:
                from rest_framework_simplejwt.tokens import RefreshToken
                import uuid
                
                # Create refresh token
                refresh = RefreshToken()
                refresh['user_id'] = str(ministry.id)
                refresh['email'] = ministry.email
                refresh['user_type'] = 'ministry'
                refresh['ministry_id'] = str(ministry.id)
                refresh['ministry_slug'] = ministry.slug
                refresh['place_id'] = str(ministry.place.id)
                refresh['place_slug'] = ministry.place.slug
                refresh['jti'] = str(uuid.uuid4())
                
                # Create access token from refresh
                access = refresh.access_token
                access['jti'] = str(uuid.uuid4())
                
                tokens = {
                    'access_token': str(access),
                    'refresh_token': str(refresh),
                    'token_type': 'Bearer',
                    'expires_in': 900,  # 15 minutes
                    'refresh_expires_in': 1209600,  # 14 days
                }
            except Exception as token_error:
                logger.error(f"[ministry_auth] Token generation error: {str(token_error)}")
                return False, {
                    "success": False,
                    "error": "Failed to generate authentication tokens"
                }, 500
            
            # Serialize ministry data
            context = {'request': request} if request else {}
            ministry_data = MinistrySerializer(ministry, context=context).data
            
            logger.info(f"[ministry_auth] Ministry login successful: {ministry.name} ({ministry.email})")
            
            return True, {
                "success": True,
                "data": {
                    'ministry': ministry_data,
                    'tokens': tokens,
                    'place': {
                        'id': str(ministry.place.id),
                        'name': ministry.place.name,
                        'slug': ministry.place.slug
                    }
                },
                "message": "Login successful"
            }, 200
            
        except Exception as e:
            logger.error(f"[ministry_auth] Login error: {str(e)}")
            import traceback
            logger.error(traceback.format_exc())
            return False, {
                "success": False,
                "error": "Authentication failed. Please try again"
            }, 500
