"""
Staff Authentication Service

Handles staff login authentication for StaffService.
Staff logs in with email + password set by ministry admin.
"""
import logging
from django.core.cache import cache
from ministry.models import StaffService

logger = logging.getLogger(__name__)


class StaffAuthService:
    """Service for staff authentication (StaffService login)"""
    
    @staticmethod
    def login(email, password, place_slug, ministry_slug, request=None):
        """
        Authenticate staff with email and password.
        
        Flow:
        1. User selects place → sees ministries
        2. User selects ministry → sees services
        3. User selects service → staff login form
        4. Staff logs in with email/password (set by ministry admin)
        5. System returns JWT tokens for staff dashboard access
        
        Args:
            email: Staff email (from StaffService)
            password: Staff password
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
            lockout_key = f"staff_lockout:{email}"
            if cache.get(lockout_key):
                logger.warning(f"[staff_auth] Login attempt for locked staff: {email}")
                return False, {
                    "success": False,
                    "error": "Account temporarily locked due to multiple failed attempts. Try again later.",
                    "lockout": True
                }, 403
            
            # Find staff service by email, ministry slug, and place slug
            from places.models import Place
            from ministry.models import Ministry
            
            place = Place.objects.filter(slug=place_slug, is_active=True).first()
            if not place:
                return False, {
                    "success": False,
                    "error": "Place not found"
                }, 404
            
            ministry = Ministry.objects.filter(
                place=place,
                slug=ministry_slug,
                status=Ministry.Status.ACTIVE
            ).first()
            
            if not ministry:
                return False, {
                    "success": False,
                    "error": "Ministry not found"
                }, 404
            
            # Find staff service by email
            staff_service = StaffService.objects.filter(
                email=email,
                ministry=ministry,
                is_active=True,
                status=StaffService.Status.ACTIVE
            ).first()
            
            if not staff_service:
                # Increment failed attempts
                failed_key = f"staff_failed_logins:{email}"
                failed_attempts = cache.get(failed_key, 0) + 1
                cache.set(failed_key, failed_attempts, timeout=1800)
                
                logger.warning(f"[staff_auth] Login attempt for non-existent staff: {email}")
                return False, {
                    "success": False,
                    "error": "Invalid email or password"
                }, 401
            
            # Verify password
            if not staff_service.password or not staff_service.check_password(password):
                # Increment failed attempts
                failed_key = f"staff_failed_logins:{email}"
                failed_attempts = cache.get(failed_key, 0) + 1
                cache.set(failed_key, failed_attempts, timeout=1800)
                
                # Lock account after 5 failed attempts
                if failed_attempts >= 5:
                    cache.set(lockout_key, True, timeout=900)  # 15 minutes
                    logger.warning(f"[staff_auth] Staff locked due to failed attempts: {email}")
                    return False, {
                        "success": False,
                        "error": "Account temporarily locked due to multiple failed attempts. Try again later.",
                        "lockout": True
                    }, 403
                
                logger.warning(f"[staff_auth] Invalid password for staff: {email}")
                return False, {
                    "success": False,
                    "error": "Invalid email or password"
                }, 401
            
            # Clear failed login attempts on success
            cache.delete(f"staff_failed_logins:{email}")
            
            # Generate JWT tokens for staff
            try:
                from rest_framework_simplejwt.tokens import RefreshToken
                import uuid
                
                # Create refresh token with staff context
                refresh = RefreshToken()
                refresh['user_id'] = str(staff_service.id)
                refresh['email'] = staff_service.email
                refresh['user_type'] = 'staff'  # Identify as staff login
                refresh['staff_service_id'] = str(staff_service.id)
                refresh['staff_name'] = staff_service.staff_name
                refresh['service_name'] = staff_service.service_name
                refresh['ministry_id'] = str(staff_service.ministry.id)
                refresh['ministry_slug'] = staff_service.ministry.slug
                refresh['place_id'] = str(place.id)
                refresh['place_slug'] = place.slug
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
                logger.error(f"[staff_auth] Token generation error: {str(token_error)}")
                return False, {
                    "success": False,
                    "error": "Failed to generate authentication tokens"
                }, 500
            
            # Build staff data response
            staff_data = {
                'id': str(staff_service.id),
                'service_name': staff_service.service_name,
                'staff_name': staff_service.staff_name,
                'email': staff_service.email,
                'status': staff_service.status,
                'service_logo_url': request.build_absolute_uri(staff_service.service_logo.url) if request and staff_service.service_logo else None,
                'staff_image_url': request.build_absolute_uri(staff_service.staff_image.url) if request and staff_service.staff_image else None,
            }
            
            logger.info(f"[staff_auth] Staff login successful: {staff_service.staff_name} ({staff_service.email}) - {staff_service.service_name}")
            
            return True, {
                "success": True,
                "data": {
                    'staff': staff_data,
                    'tokens': tokens,
                    'ministry': {
                        'id': str(staff_service.ministry.id),
                        'name': staff_service.ministry.name,
                        'slug': staff_service.ministry.slug
                    },
                    'place': {
                        'id': str(place.id),
                        'name': place.name,
                        'slug': place.slug
                    }
                },
                "message": "Login successful"
            }, 200
            
        except Exception as e:
            logger.error(f"[staff_auth] Login error: {str(e)}")
            import traceback
            logger.error(traceback.format_exc())
            return False, {
                "success": False,
                "error": "Login failed"
            }, 500
