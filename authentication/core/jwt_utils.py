from rest_framework_simplejwt.tokens import RefreshToken, TokenError
from datetime import datetime, timedelta
from django.conf import settings
from django.core.cache import cache
import jwt
import logging
import uuid
import time
from django.utils import timezone
from django_redis import get_redis_connection

logger = logging.getLogger(__name__)

class TokenManager:
    """Enhanced JWT token manager with Redis caching"""
    @staticmethod
    def _get_redis_client():
        """Get  a raw redis-py client"""
        return get_redis_connection("default") 
    
    @staticmethod
    def generate_tokens(user, ministry_id=None, place_id=None, service_id=None):
        """Generate secure access and refresh tokens with enhanced claims and security"""
        try:
            refresh = RefreshToken.for_user(user)
            
            # Create unique JTI (JWT ID) for better tracking
            jti = str(uuid.uuid4())
            
            # Add custom claims with security considerations
            refresh['jti'] = jti 
            refresh['user_type'] = user.user_type
            refresh['is_staff'] = user.is_staff
            refresh['email'] = user.email
            refresh['is_verified'] = user.is_verified
            refresh['type'] = 'refresh'
            
            # Add context claims for ministry/place/service
            if ministry_id:
                refresh['ministry_id'] = str(ministry_id)
            if place_id:
                refresh['place_id'] = str(place_id)
            if service_id:
                refresh['service_id'] = str(service_id)
            
            # set up different claims for access token
            access_token = refresh.access_token
            access_token['type'] = 'access'
            access_token['jti'] = str(uuid.uuid4())
            
            # Copy context claims to access token
            if ministry_id:
                access_token['ministry_id'] = str(ministry_id)
            if place_id:
                access_token['place_id'] = str(place_id)
            if service_id:
                access_token['service_id'] = str(service_id)
            
            access_expiry = settings.SIMPLE_JWT.get('ACCESS_TOKEN_LIFETIME', timedelta(minutes=15))
            refresh_expiry = settings.SIMPLE_JWT.get('REFRESH_TOKEN_LIFETIME', timedelta(days = 14))
            
            TokenManager._store_token_metadata(user.id, jti, refresh_expiry.total_seconds())
            
            return {
                'access_token': str(access_token), 
                'refresh_token' : str(refresh), 
                'token_type': 'Bearer', 
                'expires_in': int(access_expiry.total_seconds()), 
                'refresh_expires_in': int(refresh_expiry.total_seconds()), 
                'user_id': user.id, 
                'issued_at': int(time.time())
            }
        except Exception as e:
            logger.error(f"Failed to generate tokens for user {user.id}: {str(e)}")
            raise 
        
    @staticmethod
    def refresh_tokens(refresh_token):
        """
        Refresh tokens with validation and optional rotation - supports all user types.
        
        Args:
            refresh_token: The refresh token to use
            
        Returns:
            dict: New tokens with access_token, refresh_token, token_type, expires_in
            
        Raises:
            TokenError: If token is invalid, blacklisted, or user not found
        """
        if not refresh_token:
            raise TokenError("Refresh token is required")
        
        try:
            token = RefreshToken(refresh_token)
        except Exception as e:
            logger.warning(f"[token] Invalid refresh token format: {str(e)}")
            raise TokenError("Invalid refresh token format")
        
        try:
            jti = token.get('jti')
            
            if not jti:
                logger.warning("[token] Refresh token missing JTI claim")
                raise TokenError("Invalid token structure")
            
            if TokenManager.is_token_blacklisted(jti):
                logger.warning(f"[token] Attempt to use blacklisted token: {jti[:8]}...")
                raise TokenError("Token is blacklisted")
            
            # Get user details from token with validation
            user_id = token.get('user_id')
            if not user_id:
                logger.warning("[token] Refresh token missing user_id claim")
                raise TokenError("Invalid token structure")
            
            user_type = token.get('user_type', 'citizen')  # Default for backward compatibility
            
            # Handle different user types
            if user_type == 'staff':
                return TokenManager._refresh_staff_token(user_id, jti, token)
            elif user_type == 'ministry':
                return TokenManager._refresh_ministry_token(user_id, jti, token)
            else:
                return TokenManager._refresh_custom_user_token(user_id, jti, token)
                
        except TokenError:
            # Re-raise TokenError as-is
            raise
        except Exception as e:
            logger.error(f"[token] Unexpected error during token refresh: {type(e).__name__}: {str(e)}")
            import traceback
            logger.error(traceback.format_exc())
            raise TokenError(f"Token refresh failed: {str(e)}")
    
    @staticmethod
    def _refresh_staff_token(user_id, jti, token):
        """Refresh tokens for staff user"""
        from ministry.models import StaffService
        
        try:
            staff_service = StaffService.objects.select_related(
                'ministry',
                'ministry__place'
            ).get(id=user_id)
            
            # Validate staff service is active
            if not staff_service.is_active:
                logger.warning(f"[token] Inactive staff service attempted token refresh: {user_id}")
                TokenManager.blacklist_token(jti)
                raise TokenError("Staff service is inactive")
            
            if staff_service.status != StaffService.Status.ACTIVE:
                logger.warning(f"[token] Non-active staff service attempted refresh: {user_id} - {staff_service.status}")
                TokenManager.blacklist_token(jti)
                raise TokenError(f"Staff service is {staff_service.status}")
            
            # Validate ministry is still active
            if staff_service.ministry.status != staff_service.ministry.Status.ACTIVE:
                logger.warning(f"[token] Staff service belongs to inactive ministry: {user_id}")
                TokenManager.blacklist_token(jti)
                raise TokenError("Ministry is no longer active")
                
        except StaffService.DoesNotExist:
            logger.warning(f"[token] Token refresh for non-existent staff: {user_id}")
            raise TokenError("Staff service not found")
        
        # Blacklist old token if rotation enabled
        if settings.SIMPLE_JWT.get('ROTATE_REFRESH_TOKENS', True):
            TokenManager.blacklist_token(jti)
        
        # Generate new tokens with staff context
        refresh = RefreshToken()
        refresh['user_id'] = str(staff_service.id)
        refresh['email'] = staff_service.email
        refresh['user_type'] = 'staff'
        refresh['staff_service_id'] = str(staff_service.id)
        refresh['staff_name'] = staff_service.staff_name
        refresh['service_name'] = staff_service.service_name
        refresh['ministry_id'] = str(staff_service.ministry.id)
        refresh['ministry_slug'] = staff_service.ministry.slug
        refresh['place_id'] = str(staff_service.ministry.place.id)
        refresh['place_slug'] = staff_service.ministry.place.slug
        refresh['jti'] = str(uuid.uuid4())
        
        access = refresh.access_token
        access['jti'] = str(uuid.uuid4())
        
        logger.debug(f"[token] Staff token refreshed: {staff_service.email}")
        
        return {
            'access_token': str(access),
            'refresh_token': str(refresh),
            'token_type': 'Bearer',
            'expires_in': 900,
            'refresh_expires_in': 1209600,
        }
    
    @staticmethod
    def _refresh_ministry_token(user_id, jti, token):
        """Refresh tokens for ministry user"""
        from ministry.models import Ministry
        
        try:
            ministry = Ministry.objects.select_related('place').get(id=user_id)
            
            # Validate ministry is active
            if ministry.status != Ministry.Status.ACTIVE:
                logger.warning(f"[token] Non-active ministry attempted refresh: {user_id} - {ministry.status}")
                TokenManager.blacklist_token(jti)
                raise TokenError(f"Ministry is {ministry.status}")
            
            # Check soft delete
            if ministry.is_deleted:
                logger.warning(f"[token] Deleted ministry attempted refresh: {user_id}")
                TokenManager.blacklist_token(jti)
                raise TokenError("Ministry has been deleted")
            
            # Validate place is active
            if not ministry.place.is_active:
                logger.warning(f"[token] Ministry belongs to inactive place: {user_id}")
                TokenManager.blacklist_token(jti)
                raise TokenError("Place is no longer active")
                
        except Ministry.DoesNotExist:
            logger.warning(f"[token] Token refresh for non-existent ministry: {user_id}")
            raise TokenError("Ministry not found")
        
        # Blacklist old token if rotation enabled
        if settings.SIMPLE_JWT.get('ROTATE_REFRESH_TOKENS', True):
            TokenManager.blacklist_token(jti)
        
        # Generate new tokens with ministry context
        refresh = RefreshToken()
        refresh['user_id'] = str(ministry.id)
        refresh['email'] = ministry.email
        refresh['user_type'] = 'ministry'
        refresh['ministry_id'] = str(ministry.id)
        refresh['ministry_slug'] = ministry.slug
        refresh['place_id'] = str(ministry.place.id)
        refresh['place_slug'] = ministry.place.slug
        refresh['jti'] = str(uuid.uuid4())
        
        access = refresh.access_token
        access['jti'] = str(uuid.uuid4())
        
        logger.debug(f"[token] Ministry token refreshed: {ministry.email}")
        
        return {
            'access_token': str(access),
            'refresh_token': str(refresh),
            'token_type': 'Bearer',
            'expires_in': 900,
            'refresh_expires_in': 1209600,
        }
    
    @staticmethod
    def _refresh_custom_user_token(user_id, jti, token):
        """Refresh tokens for CustomUser (citizens, admins, super admin)"""
        from authentication.models import CustomUser
        
        try:
            user = CustomUser.objects.get(id=user_id)
        except CustomUser.DoesNotExist:
            logger.warning(f"[token] Token refresh for non-existent user: {user_id}")
            raise TokenError("User not found")
        
        if not user.is_active:
            logger.warning(f"[token] Inactive user attempted token refresh: {user.email}")
            TokenManager.blacklist_token(jti)
            raise TokenError("User is inactive")
        
        # Blacklist old token if rotation enabled
        if settings.SIMPLE_JWT.get('ROTATE_REFRESH_TOKENS', True):
            TokenManager.blacklist_token(jti)
        
        # Generate new tokens with context from original token
        ministry_id = token.get('ministry_id')
        place_id = token.get('place_id')
        service_id = token.get('service_id')
        
        logger.debug(f"[token] User token refreshed: {user.email}")
        
        return TokenManager.generate_tokens(
            user,
            ministry_id=ministry_id,
            place_id=place_id,
            service_id=service_id
        )
        
        
    @staticmethod
    def validate_token(token_string):
        """Validate token without using the database"""
        try:
            unverified = jwt.decode(token_string, options = {"verify_signature": False})
            alg = unverified.get('alg', settings.SIMPLE_JWT.get('ALGORITHM', 'HS256'))
            
            decoded = jwt.decode(
                token_string, 
                settings.SIMPLE_JWT.get('SIGNING_KEY', settings.SECRET_KEY), 
                algorithms=[alg], 
                options={"verify_signature": True}
            )
            
            token_type = decoded.get('token_type', decoded.get('type', 'access'))
            user_id = decoded.get('user_id')
            jti = decoded.get('jti')
            
            if jti and TokenManager.is_token_blacklisted(jti):
                logger.warning(f"Attempt to use blacklisted token with JTI: {jti}")
                return False, None, None 
            
            exp = decoded.get('exp', 0)
            if exp < time.time():
                logger.debug(f"Token expired at {datetime.fromtimestamp(exp).isoformat()}")
                return False, None, None
            return True, user_id, token_type
        
        except jwt.PyJWTError as e :
            logger.debug(f"Token validation error: {str(e)}")
            return False, None, None
                
                
                
    @staticmethod
    def blacklist_token(jti):
        """Blacklist a token by JTI"""
        if not jti:
            return False 
        
        try:
            redis_client = TokenManager._get_redis_client()
            blacklist_key = f"blacklisted_token: {jti}"
            timeout = settings.SIMPLE_JWT.get('BLACKLIST_TIMEOUT', 86400)
            redis_client.setex(blacklist_key, timeout, "1")
            return True
        except Exception as e:
            logger.error(f"Error blacklisting token in Redis: {str(e)}")
            return False
            
            
            
    @staticmethod
    def is_token_blacklisted(jti):
        """Check if a token is blacklisted"""
        if not jti:
            return False
        
        try:
            redis_client = TokenManager._get_redis_client()
            blacklist_key = f"blacklisted_token: {jti}"
            return redis_client.exists(blacklist_key) > 0
        except Exception as e:
            logger.error(f"Error checking token blacklist in Redis: {str(e)}")
            return False
            
    @staticmethod
    def _store_token_metadata(user_id, jti, expiry_seconds):
        """Store token metadata in Redis for blacklisting"""
        try:
            redis_client = TokenManager._get_redis_client()
            user_tokens_key = f"user_tokens: {user_id}"
            
            pipe = redis_client.pipeline()
            pipe.sadd(user_tokens_key, jti) 
            pipe.expire(user_tokens_key, int(expiry_seconds))
            pipe.execute()
            
        except  Exception as e:
            logger.error(f"Error storing token metadata in Redis: {str(e)}")
            
            
    @staticmethod 
    def blacklist_all_user_tokens(user_id):
        """Blacklist all tokens for a specif user"""
        try:
            redis_client = TokenManager._get_redis_client()
            user_tokens_key = f"user_tokens:{user_id}"
            
            # Get all active tokens for the user
            active_tokens = redis_client.smembers(user_tokens_key)
            if not active_tokens:
                return 0
            
            pipe = redis_client.pipeline()
            blacklist_timeout = settings.SIMPLE_JWT.get('BLACKLIST_TIMEOUT', 86400)
            
            for jti in active_tokens:
                jti_str = jti.decode('utf-8') if isinstance(jti, bytes) else jti
                blacklist_key = f"blacklisted_token: {jti_str}"
                pipe.setex(blacklist_key, blacklist_timeout, "1")
                
            # clear the user tokens set
            pipe.delete(user_tokens_key)
            pipe.execute()
            
            logger.info(f"Blacklisted {len(active_tokens)} tokens for user {user_id}")
            return len(active_tokens)
        except Exception as e:
            logger.error(f"Error blacklisting user tokens in Redis : {str(e)}")
            return 0
        
    @staticmethod
    def get_user_active_tokens_count(user_id):
        """et count of active tokens for a user"""
        try: 
            redis_client = TokenManager._get_redis_client()
            user_tokens_key = f"user_tokens: {user_id}"
            return redis_client.scard(user_tokens_key)
        except Exception as e:
            logger.error(f"Error getting user token count from Redis: {str(e)}")
            return 0
        
        
    @staticmethod
    def cleanup_expired_tokens():
        """Utility method to clean up expired token metadata"""
        try:
            redis_client = TokenManager._get_redis_client()
            logger.info("Token cleanup completed")
            return True
        except Exception as e:
            logger.error(f"Error during token cleanup: {str(e)}")
            return False