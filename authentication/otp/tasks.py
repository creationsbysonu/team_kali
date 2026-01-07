"""
Celery Tasks for OTP Email Delivery
"""
import logging
from celery import shared_task
from django.conf import settings
from django.core.mail import send_mail
from django.template.loader import render_to_string

logger = logging.getLogger(__name__)


@shared_task(
    bind=True,
    autoretry_for=(Exception,),
    retry_kwargs={'max_retries': 3},
    retry_backoff=True,
    retry_backoff_max=60,
    name="authentication.otp.send_otp_email"
)
def send_otp_email_task(self, email: str, otp: str):
    """
    Celery task to send OTP email.
    
    Args:
        email: Recipient email address
        otp: OTP code to send
    """
    try:
        logger.info(f"[otp_task] Sending OTP email to {email}")
        
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
            logger.warning(f"[otp_task] Template not found, using plain text: {str(template_error)}")
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
        
        logger.info(f"[otp_task] OTP email sent successfully to {email}")
        return {"status": "success", "email": email}
        
    except Exception as e:
        logger.error(f"[otp_task] Failed to send OTP email to {email} on attempt {self.request.retries + 1}: {str(e)}")
        raise
