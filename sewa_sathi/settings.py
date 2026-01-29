import os
from decouple import config
from pathlib import Path
from datetime import timedelta

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent


SECRET_KEY = config('SECRET_KEY')

DEBUG = config('DEBUG', default = False, cast=bool)

ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='*', cast=lambda v:[s.strip() for s in v.split(',')])

# Base URL for the server (used for generating absolute URLs)
# In production, set this to your domain (e.g., https://api.sewasathi.com)
BASE_URL = config('BASE_URL', default='http://localhost:8000')


# Application definition

INSTALLED_APPS = [
    'daphne',  # ASGI server for WebSocket support (must be first)
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    
    # Third party apps
    'corsheaders',
    'rest_framework',
    'cloudinary_storage',
    'cloudinary',
    'channels',  # Django Channels for WebSocket support
    
    # Local apps
    'core',
    'authentication',
    'places',   # Decentralized locations (Kathmandu, Biratnagar, etc.)
    'ministry',  # Ministries belong to Places
    'services',  # Services belong to Ministries
    'staff',     # Staff belong to Services (created by Ministry Admins)
    'officials',  # Ministry officials (chairperson, secretary, etc.) for progress tracking
    'attendance',  # Unified attendance tracking for staff and officials
    'holidays',  # Universal holiday management (all holidays apply to everyone)
    'queue_management',  # Queue configuration, daily queues, tokens, audit logs, progress tracking
    'notifications',  # In-app notifications for citizens and staff
    'mobile_initial',  # Mobile app profile setup for citizens
    'get_token',  # Citizen token booking flow (Flutter app)
    'citizen_api',  # Optimized API for Flutter mobile app (v1)
    
    # Notice Portal apps
    'notices',      # Government notices with file attachments
    'filters',      # Notice filtering service
    'rag_bridge',   # RAG server communication bridge
    'citizen_chat', # Citizen chat via WebSocket
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    'core.db_middleware.DatabaseConnectionMiddleware',  # Fresh DB connections for Supabase
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'ministry.core.middleware.MinistryMiddleware',  # Multi-tenancy middleware
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'sewa_sathi.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'sewa_sathi.wsgi.application'


# Database
# https://docs.djangoproject.com/en/6.0/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DB_NAME'),
        'USER': config('DB_USER'),
        'PASSWORD': config('DB_PASSWORD'),
        'HOST': config('DB_HOST'),
        'PORT': config('DB_PORT'),  
        'OPTIONS': {
            'sslmode': 'require',
            'connect_timeout': 10,
            'options': '-c statement_timeout=30000',
            'keepalives': 1,
            'keepalives_idle': 30,
            'keepalives_interval': 10,
            'keepalives_count': 5,
        },
        # Supabase Pooler settings - use new connection per request
        'CONN_MAX_AGE': 0,  # Don't persist connections
        'CONN_HEALTH_CHECKS': True,
        'DISABLE_SERVER_SIDE_CURSORS': True,  # Required for PgBouncer
        'TIME_ZONE': 'Asia/Kathmandu',
        'ATOMIC_REQUESTS': False,
        'AUTOCOMMIT': True, 
    }
}


# Password validation
# https://docs.djangoproject.com/en/6.0/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Cloudinary configuration
CLOUDINARY_STORAGE = {
    'CLOUD_NAME': config('CLOUDINARY_CLOUD_NAME'),
    'API_KEY': config('CLOUDINARY_API_KEY'),
    'API_SECRET': config('CLOUDINARY_API_SECRET'),
}

# Use Cloudinary for media files
DEFAULT_FILE_STORAGE = 'cloudinary_storage.storage.MediaCloudinaryStorage'

# Media settings
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')


# Internationalization
# https://docs.djangoproject.com/en/6.0/topics/i18n/

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'Asia/Kathmandu'

USE_I18N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/5.2/howto/static-files/

STATIC_URL = 'static/'
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# Default primary key field type
# https://docs.djangoproject.com/en/5.2/ref/settings/#default-auto-field

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'


SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME':timedelta(minutes=15), 
    'REFRESH_TOKEN_LIFETIME': timedelta(days = 14), 
    'ROTATE_REFRESH_TOKENS' : True, 
    'BLACKLIST_AFTER_ROTATION': True, 
    'ALGORITHM': 'HS256', 
    'SIGNING_KEY': SECRET_KEY, 
    'AUTH_HEADER_TYPES' : ('Bearer',),
    'USER_ID_FIELD':'id', 
    'USER_ID_CLAIM': 'user_id', 
    'AUTH_TOKEN_CLASSES': ('rest_framework_simplejwt.tokens.AccessToken',), 
    'TOKEN_TYPE_CLAIM': 'token_type', 
    
}

# JWT Cookie Settings
JWT_COOKIE_SECURE = config('JWT_COOKIE_SECURE', default = False, cast = bool)
JWT_COOKIE_NAME = 'refresh_token'
JWT_COOKIE_SAMESITE = 'Lax' # Use 'Strict' if possible


# Redis Configuration (Docker-ready)
# Use REDIS_HOST env var for Docker, defaults to localhost for local dev
REDIS_HOST = config('REDIS_HOST', default='localhost')
REDIS_PORT = config('REDIS_PORT', default='6379')

# Cache Configuration (Docker-ready)
# Uses same Redis instance as Celery but different DB
CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache", 
        "LOCATION": f'redis://{REDIS_HOST}:{REDIS_PORT}/1',  # DB 1 for cache
        "OPTIONS" : {
            "CLIENT_CLASS" : "django_redis.client.DefaultClient", 
            "SOCKET_CONNECT_TIMEOUT": 5, 
            "SOCKET_TIMEOUT": 5, 
            "IGNORE_EXCEPTIONS": True,
        }, 
        "TIMEOUT": 3600, 
    }
}


# REST Framework settings
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': ('authentication.core.authentication.MultiUserTypeJWTAuthentication',), 
    'DEFAULT_PERMISSION_CLASSES': ('rest_framework.permissions.IsAuthenticated',), 
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle', 
        'rest_framework.throttling.UserRateThrottle',
    ], 
}

# Celery Configuration (uses REDIS_HOST defined above)
CELERY_TIMEZONE = "Asia/Kathmandu"
CELERY_TASK_TRACK_STARTED = True
CELERY_TASK_TIME_LIMIT = 30*60
CELERY_RESULT_BACKEND = f'redis://{REDIS_HOST}:{REDIS_PORT}/0'
CELERY_BROKER_URL = f'redis://{REDIS_HOST}:{REDIS_PORT}/0'
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'

FRONTEND_URL ='http://127.0.0.1/api'


# Email verificaiton settings
REQUIRE_EMAIL_VERIFICATION = True
EMAIL_VERIFICATION_TIMEOUT = 3600*24*3  # 3 days verification link
APP_NAME = 'Sewa Sathi'
DEFAULT_FROM_EMAIL = 'Sewa Sathi <noreply@sewasathi.com>'

# OTP Settings
OTP_EXPIRY = 300  # 5 minutes
OTP_LENGTH = 6
MAX_OTP_ATTEMPTS = 5
MAX_OTP_REQUESTS_PER_HOUR = 5


AUTH_USER_MODEL = 'authentication.CustomUser'

# Email settings
#For Gmail SMTP
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = 'smtp.gmail.com'
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = config('EMAIL_HOST_USER', default = 'your-gmail@gmail.com')
EMAIL_HOST_PASSWORD = config('EMAIL_HOST_PASSWORD', default = '')

# Fix for macOS SSL certificate verification issue
import ssl
import certifi
EMAIL_SSL_CONTEXT = ssl.create_default_context(cafile=certifi.where())


# cors configurations
CORS_ALLOW_CREDENTIALS = True

# Development vs Production CORS settings
if DEBUG:
    # Allow all origins in development for Flutter web testing
    CORS_ALLOW_ALL_ORIGINS = True
    CORS_ALLOW_HEADERS = [
        'accept', 
        'accept-encoding', 
        'authorization', 
        'content-type',
        'dnt', 
        'origin', 
        'user-agent', 
        'x-csrftoken', 
        'x-requested-with',
        'x-ministry-id',  # Custom header for ministry context
    ]
else:
    # Production settings - specific origins only
    CORS_ALLOW_ALL_ORIGINS = True
    CORS_ALLOWED_ORIGINS = config(
        'CORS_ALLOWED_ORIGINS', 
        default = 'https://yourdomain.com', 
        cast = lambda v: [s.strip() for s in v.split(',')]
    )
    
# Allow specific methods
CORS_ALLOWED_METHODS = [
    'DELETE', 
    'GET', 
    'OPTIONS', 
    'PATCH', 
    'POST', 
    'PUT',
]

# CORS preflight cache
CORS_PREFLIGHT_MAX_AGE = 86400


# ===================================
# Django Channels Configuration
# ===================================
ASGI_APPLICATION = 'sewa_sathi.asgi.application'

# Channel layers using Redis
CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            'hosts': [(REDIS_HOST, int(REDIS_PORT))],
            'capacity': 1500,
            'expiry': 10,
        },
    },
}


# ===================================
# Notice Portal Settings
# ===================================
# Allowed file extensions for notice uploads
ALLOWED_NOTICE_EXTENSIONS = ['pdf', 'png', 'jpg', 'jpeg']

# Maximum file size (10 MB)
MAX_UPLOAD_SIZE = 10 * 1024 * 1024


# ===================================
# RAG Server Configuration
# ===================================
# Base URL for HTTP requests (used by services.py and ws_client.py)
RAG_SERVER_URL = config('RAG_SERVER_URL', default='http://192.168.1.118:8001')
RAG_API_KEY = config('RAG_API_KEY', default='')
RAG_CONNECTION_TIMEOUT = config('RAG_CONNECTION_TIMEOUT', default=10, cast=int)
RAG_INGEST_TIMEOUT = config('RAG_INGEST_TIMEOUT', default=120, cast=int)
RAG_MAX_RETRIES = config('RAG_MAX_RETRIES', default=3, cast=int)