from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager
import uuid


class UserManager(BaseUserManager):
    """Custom user manager for email-based authentication"""
    
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError("The email field must be set")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        if password:
            user.set_password(password)
        user.save(using=self._db)
        return user
    
    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_verified', True)
        extra_fields.setdefault('user_type', 'super_admin')
        return self.create_user(email, password, **extra_fields)


class CustomUser(AbstractBaseUser, PermissionsMixin):
    """
    Custom user model with email as username.
    
    Citizens: Only email required (login via OTP)
    Ministry/Admin: Email + password (login via password)
    """
    
    class UserType(models.TextChoices):
        CITIZEN = 'citizen', 'Citizen'
        STAFF = 'staff', 'Staff'
        ADMIN = 'admin', 'Admin'
        SUPER_ADMIN = 'super_admin', 'Super Admin'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    
    user_type = models.CharField(
        max_length=20,
        choices=UserType.choices,
        default=UserType.CITIZEN
    )
    
    is_verified = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    objects = UserManager()
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []
    
    class Meta:
        verbose_name = 'User'
        verbose_name_plural = 'Users'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['email']),
            models.Index(fields=['user_type']),
            models.Index(fields=['is_active', 'is_verified']),
        ]
    
    def __str__(self):
        return self.email
    
    @property
    def is_citizen(self):
        return self.user_type == self.UserType.CITIZEN
    
    @property
    def is_admin_user(self):
        return self.user_type in [self.UserType.ADMIN, self.UserType.SUPER_ADMIN]


class OTPLog(models.Model):
    """Log OTP requests for audit and rate limiting"""
    
    class OTPPurpose(models.TextChoices):
        LOGIN = 'login', 'Login'
        REGISTRATION = 'registration', 'Registration'
        VERIFICATION = 'verification', 'Email Verification'
        PASSWORD_RESET = 'password_reset', 'Password Reset'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField()
    purpose = models.CharField(max_length=20, choices=OTPPurpose.choices)
    otp_hash = models.CharField(max_length=128)  # Store hashed OTP
    is_used = models.BooleanField(default=False)
    attempts = models.IntegerField(default=0)
    
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    used_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['email', 'purpose']),
            models.Index(fields=['created_at']),
            models.Index(fields=['expires_at']),
        ]
    
    def __str__(self):
        return f"OTP for {self.email} - {self.purpose}"