"""
OTP Email Delivery - Synchronous and Async Options
"""
import logging
import threading
from celery import shared_task
from django.conf import settings
from django.core.mail import send_mail
from django.template.loader import render_to_string

logger = logging.getLogger(__name__)


def _send_otp_email_sync(email: str, otp: str) -> dict:
    """
    Synchronous function to send OTP email.
    Used for immediate delivery.
    
    Args:
        email: Recipient email address
        otp: OTP code to send
        
    Returns:
        dict with status
    """
    try:
        logger.info(f"[otp] Sending OTP email to {email}")
        
        app_name = getattr(settings, 'APP_NAME', 'Sewa Sathi')
        otp_expiry_minutes = getattr(settings, 'OTP_EXPIRY', 300) // 60
        
        subject = f"{app_name} - Your Login OTP"
        
        context = {
            'otp': otp,
            'app_name': app_name,
            'expiry_minutes': otp_expiry_minutes,
            'email': email
        }
        
        # Try to render HTML template
        try:
            html_message = render_to_string('emails/otp_email.html', context)
        except Exception as template_error:
            logger.debug(f"[otp] Template not found, using plain text: {str(template_error)}")
            html_message = None
        
        # Plain text fallback
        plain_message = f"""
Hello,

Your OTP for {app_name} is: {otp}

This OTP is valid for {otp_expiry_minutes} minutes.

If you didn't request this OTP, please ignore this email.

Thank you,
{app_name} Team
        """.strip()
        
        from_email = getattr(settings, 'DEFAULT_FROM_EMAIL', None) or settings.EMAIL_HOST_USER
        
        send_mail(
            subject=subject,
            message=plain_message,
            from_email=from_email,
            recipient_list=[email],
            html_message=html_message,
            fail_silently=False
        )
        
        logger.info(f"[otp] ✅ OTP email sent successfully to {email}")
        return {"status": "success", "email": email}
        
    except Exception as e:
        logger.error(f"[otp] ❌ Failed to send OTP email to {email}: {str(e)}")
        raise


def send_otp_email_thread(email: str, otp: str):
    """
    Send OTP email in a background thread for non-blocking immediate delivery.
    This is faster than Celery for simple email tasks.
    """
    def _send():
        try:
            _send_otp_email_sync(email, otp)
        except Exception as e:
            logger.error(f"[otp] Thread email failed for {email}: {str(e)}")
    
    thread = threading.Thread(target=_send, daemon=True)
    thread.start()
    logger.info(f"[otp] 📧 OTP email thread started for {email}")


@shared_task(
    bind=True,
    autoretry_for=(Exception,),
    retry_kwargs={'max_retries': 3},
    retry_backoff=True,
    retry_backoff_max=60,
    name="authentication.otp.send_otp_email"
)
def send_otp_email(self, email: str, otp: str):
    """
    Celery task to send OTP email (for backward compatibility).
    Prefer send_otp_email_thread for faster delivery.
    """
    return _send_otp_email_sync(email, otp)
