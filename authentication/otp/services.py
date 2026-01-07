"""
OTP Authentication Service for Citizens

This service handles OTP-based authentication flow:
1. Request OTP → Send to email
2. Verify OTP → Return tokens (create user if new)
"""
import logging
import hashlib
import secrets
from datetime import timedelta
from typing import Optional

from django.db import transaction
from django.core.cache import cache
from django.utils import timezone
from django.conf import settings

from authentication.models import CustomUser, OTPLog
from authentication.serializers import UserSerializer
from authentication.core.jwt_utils import TokenManager
from .tasks import send_otp_email_task

logger = logging.getLogger(__name__)


class OTPService:
    """OTP authentication service for citizens"""
    
    OTP_CACHE_PREFIX = "otp_"
    OTP_EXPIRY = 300  # 5 minutes
    OTP_LENGTH = 6
    MAX_OTP_ATTEMPTS = 5
    MAX_OTP_REQUESTS_PER_HOUR = 5
    RATE_LIMIT_TIMEOUT = 3600  # 1 hour
    
    @staticmethod
    def _generate_otp():
        """Generate a secure random OTP"""
        return ''.join([str(secrets.randbelow(10)) for _ in range(OTPService.OTP_LENGTH)])
    
    @staticmethod
    def _hash_otp(otp: str) -> str:
        """Hash OTP for secure storage"""
        return hashlib.sha256(otp.encode()).hexdigest()
    
    @staticmethod
    def _get_cache_key(email: str) -> str:
        """Generate cache key for OTP"""
        return f"{OTPService.OTP_CACHE_PREFIX}{email.lower()}"
    
    @staticmethod
    def _get_rate_limit_key(email: str) -> str:
        """Generate cache key for rate limiting"""
        return f"otp_rate_limit_{email.lower()}"
    
    @staticmethod
    def _get_attempts_key(email: str) -> str:
        """Generate cache key for verification attempts"""
        return f"otp_attempts_{email.lower()}"
    
    @staticmethod
    def request_otp(email: str, request_meta: Optional[dict] = None):
        """
        Generate and send OTP to email.
        
        Args:
            email: User's email address
            request_meta: Request metadata for logging
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        if not email:
            return False, {
                "success": False,
                "error": "Email is required"
            }, 400
        
        email = email.lower().strip()
        
        # Log request
        ip_address = request_meta.get('REMOTE_ADDR') if request_meta else None
        logger.info(f"[otp] OTP request for {email} from IP: {ip_address}")
        
        try:
            # Check rate limit
            rate_key = OTPService._get_rate_limit_key(email)
            request_count = cache.get(rate_key, 0)
            
            if request_count >= OTPService.MAX_OTP_REQUESTS_PER_HOUR:
                logger.warning(f"[otp] Rate limit exceeded for {email}")
                return False, {
                    "success": False,
                    "error": "Too many OTP requests. Please try again later."
                }, 429
            
            # Generate OTP
            otp = OTPService._generate_otp()
            otp_hash = OTPService._hash_otp(otp)
            
            # Store OTP in cache
            cache_key = OTPService._get_cache_key(email)
            cache_data = {
                'otp_hash': otp_hash,
                'email': email,
                'created_at': timezone.now().isoformat(),
                'attempts': 0
            }
            cache.set(cache_key, cache_data, OTPService.OTP_EXPIRY)
            
            # Update rate limit counter
            cache.set(rate_key, request_count + 1, OTPService.RATE_LIMIT_TIMEOUT)
            
            # Clear any previous verification attempts
            cache.delete(OTPService._get_attempts_key(email))
            
            # Log OTP request to database for audit
            OTPLog.objects.create(
                email=email,
                purpose=OTPLog.OTPPurpose.LOGIN,
                otp_hash=otp_hash,
                ip_address=ip_address,
                user_agent=request_meta.get('HTTP_USER_AGENT', '') if request_meta else '',
                expires_at=timezone.now() + timedelta(seconds=OTPService.OTP_EXPIRY)
            )
            
            # Send OTP via email asynchronously
            send_otp_email_task.delay(email, otp)  # type: ignore[union-attr]
            
            logger.info(f"[otp] OTP generated and queued for {email}")
            
            return True, {
                "success": True,
                "message": "OTP sent to your email. Please check your inbox.",
                "data": {
                    "email": email,
                    "expires_in": OTPService.OTP_EXPIRY
                }
            }, 200
            
        except Exception as e:
            logger.error(f"[otp] Error requesting OTP for {email}: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to send OTP. Please try again."
            }, 500
    
    @staticmethod
    def verify_otp(email: str, otp: str, request_meta: Optional[dict] = None, request=None):
        """
        Verify OTP and return tokens.
        Creates user if doesn't exist.
        
        Args:
            email: User's email address
            otp: OTP code to verify
            request_meta: Request metadata
            request: HTTP request object
            
        Returns:
            tuple: (success, response_data, status_code)
        """
        if not email or not otp:
            return False, {
                "success": False,
                "error": "Email and OTP are required"
            }, 400
        
        email = email.lower().strip()
        otp = otp.strip()
        
        logger.info(f"[otp] OTP verification attempt for {email}")
        
        try:
            # Check verification attempts
            attempts_key = OTPService._get_attempts_key(email)
            attempts = cache.get(attempts_key, 0)
            
            if attempts >= OTPService.MAX_OTP_ATTEMPTS:
                logger.warning(f"[otp] Too many failed attempts for {email}")
                # Clear the OTP cache to force new OTP request
                cache.delete(OTPService._get_cache_key(email))
                return False, {
                    "success": False,
                    "error": "Too many failed attempts. Please request a new OTP."
                }, 429
            
            # Get OTP from cache
            cache_key = OTPService._get_cache_key(email)
            cache_data = cache.get(cache_key)
            
            if not cache_data:
                logger.warning(f"[otp] OTP not found or expired for {email}")
                return False, {
                    "success": False,
                    "error": "OTP expired or not found. Please request a new OTP."
                }, 400
            
            # Verify OTP
            stored_hash = cache_data.get('otp_hash')
            provided_hash = OTPService._hash_otp(otp)
            
            if stored_hash != provided_hash:
                # Increment failed attempts
                cache.set(attempts_key, attempts + 1, OTPService.OTP_EXPIRY)
                logger.warning(f"[otp] Invalid OTP for {email}. Attempt {attempts + 1}")
                
                remaining = OTPService.MAX_OTP_ATTEMPTS - (attempts + 1)
                return False, {
                    "success": False,
                    "error": f"Invalid OTP. {remaining} attempts remaining."
                }, 400
            
            # OTP is valid - clear cache
            cache.delete(cache_key)
            cache.delete(attempts_key)
            
            # Update OTP log
            OTPLog.objects.filter(
                email=email,
                otp_hash=stored_hash,
                is_used=False
            ).update(
                is_used=True,
                used_at=timezone.now()
            )
            
            # Get or create user
            with transaction.atomic():
                user, is_new_user = CustomUser.objects.get_or_create(
                    email=email,
                    defaults={
                        'user_type': CustomUser.UserType.CITIZEN,
                        'is_verified': True  # Email verified via OTP
                    }
                )
                
                # If existing user, ensure they're verified now
                if not is_new_user and not user.is_verified:
                    user.is_verified = True
                    user.save(update_fields=['is_verified'])
                
                # Check if user is active
                if not user.is_active:
                    logger.warning(f"[otp] Inactive user tried to login: {email}")
                    return False, {
                        "success": False,
                        "error": "Account is disabled. Please contact support."
                    }, 403
                
                # Ensure user is a citizen (OTP auth is only for citizens)
                if user.user_type != CustomUser.UserType.CITIZEN:
                    logger.warning(f"[otp] Non-citizen user tried OTP login: {email}")
                    return False, {
                        "success": False,
                        "error": "Please use password login for staff/admin accounts."
                    }, 403
            
            # Generate tokens
            tokens = TokenManager.generate_tokens(user)
            
            # Serialize user
            context = {'request': request} if request else {}
            serializer = UserSerializer(user, context=context)
            
            logger.info(f"[otp] OTP verification successful for {email}. New user: {is_new_user}")
            
            return True, {
                "success": True,
                "message": "Login successful" if not is_new_user else "Account created successfully",
                "data": {
                    "user": serializer.data,
                    "tokens": tokens,
                    "is_new_user": is_new_user
                }
            }, 200 if not is_new_user else 201
            
        except Exception as e:
            logger.error(f"[otp] Error verifying OTP for {email}: {str(e)}")
            return False, {
                "success": False,
                "error": "Verification failed. Please try again."
            }, 500
    
    @staticmethod
    def resend_otp(email: str, request_meta: Optional[dict] = None):
        """
        Resend OTP to email (wrapper for request_otp with additional checks).
        
        Returns:
            tuple: (success, response_data, status_code)
        """
        if not email:
            return False, {
                "success": False,
                "error": "Email is required"
            }, 400
        
        email = email.lower().strip()
        
        # Check if there's a recent OTP that hasn't expired
        cache_key = OTPService._get_cache_key(email)
        existing = cache.get(cache_key)
        
        if existing:
            # Check if minimum wait time has passed (60 seconds)
            created_at = existing.get('created_at')
            if created_at:
                from dateutil import parser
                created = parser.parse(created_at)
                if timezone.now() - created < timedelta(seconds=60):
                    return False, {
                        "success": False,
                        "error": "Please wait before requesting a new OTP."
                    }, 429
        
        # Request new OTP
        return OTPService.request_otp(email, request_meta)
