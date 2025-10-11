"""
Django settings for Railway deployment with security enhancements
"""
from pathlib import Path
import os
from datetime import timedelta
import dj_database_url

BASE_DIR = Path(__file__).resolve().parent.parent

# ✅ SECURITY: Use environment variable for SECRET_KEY
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', '&i+0_qgk943=xr&!fdh519l6h7xjm1w_%@t9i^p%eo%cz6elef')

DEBUG = False

# ✅ SECURITY: Restrict ALLOWED_HOSTS to specific domains
ALLOWED_HOSTS = [
    'pinit-backend-production.up.railway.app',
    'healthcheck.railway.app',
    'localhost',
    '127.0.0.1',
]

INSTALLED_APPS = [
    "daphne",  # Django Channels
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    "storages",  # Required for S3/R2 storage
    "myapp",
    "corsheaders", 
    'rest_framework',
    'rest_framework.authtoken',
    'rest_framework_simplejwt',  # ✅ JWT Authentication
    'channels',
    'push_notifications',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'StudyCon.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'StudyCon.wsgi.application'

# WebSocket configuration
CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels.layers.InMemoryChannelLayer",  # For Railway deployment
    },
}

# Set Django Channels as the ASGI server
ASGI_APPLICATION = "StudyCon.asgi.application"

# SQLite Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

# Media files configuration - Using Cloudflare R2 for production
if DEBUG:
    # Development: use local storage
    MEDIA_URL = '/media/'
    MEDIA_ROOT = os.path.join(BASE_DIR, 'media')
    DEFAULT_FILE_STORAGE = 'django.core.files.storage.FileSystemStorage'
else:
    # Production: use Cloudflare R2 with S3-compatible credentials
    print("🔧 Configuring R2 storage with S3-compatible credentials...")
    AWS_ACCESS_KEY_ID = os.environ.get('R2_ACCESS_KEY_ID', '5bc85e1cd49529516bf4f1e62cd662a3')
    AWS_SECRET_ACCESS_KEY = os.environ.get('R2_SECRET_ACCESS_KEY', '6dbdbab1d5a91cc0e0693a3921eb1b74904f78569f44fa347f4e9ace47a7ce15')
    AWS_STORAGE_BUCKET_NAME = os.environ.get('R2_BUCKET_NAME', 'pinit-images')
    AWS_S3_ENDPOINT_URL = os.environ.get('R2_ENDPOINT_URL', 'https://da76c95301856b7cd9fee0a8f758097a.r2.cloudflarestorage.com')
    AWS_S3_REGION_NAME = 'auto'
    AWS_S3_SIGNATURE_VERSION = 's3v4'
    AWS_DEFAULT_ACL = 'public-read'
    AWS_S3_OBJECT_PARAMETERS = {
        'CacheControl': 'max-age=86400',
    }
    AWS_S3_CUSTOM_DOMAIN = os.environ.get('R2_CUSTOM_DOMAIN', 'pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev')
    AWS_QUERYSTRING_AUTH = False  # public URLs
    DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
    
    # Force R2 storage for all file fields
    from storages.backends.s3boto3 import S3Boto3Storage
    
    class R2Storage(S3Boto3Storage):
        bucket_name = AWS_STORAGE_BUCKET_NAME
        custom_domain = AWS_S3_CUSTOM_DOMAIN
        file_overwrite = False
        default_acl = 'public-read'
        querystring_auth = False
    
    # Modern Django 4.2+ STORAGES configuration
    STORAGES = {
        "default": {
            "BACKEND": "storages.backends.s3.S3Storage",
        },
        "staticfiles": {
            "BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage",
        },
    }
    MEDIA_URL = f'https://{AWS_S3_CUSTOM_DOMAIN}/'
    print(f"✅ R2 configured with S3-compatible credentials")
    print(f"✅ Endpoint: {AWS_S3_ENDPOINT_URL}")
    print(f"✅ Bucket: {AWS_STORAGE_BUCKET_NAME}")
    print(f"✅ Media URL: {MEDIA_URL}")

# File upload settings
FILE_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024  # 10MB
DATA_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024  # 10MB
FILE_UPLOAD_PERMISSIONS = 0o644

# Image processing settings
ALLOWED_IMAGE_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.gif', '.webp']
MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10MB
MAX_IMAGES_PER_USER = 20

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# ✅ SECURITY: CORS Configuration
CORS_ALLOWED_ORIGINS = [
    "http://10.0.0.30",
    "http://localhost:3000",
    "https://pinit-backend-production.up.railway.app",
]
CORS_ALLOW_CREDENTIALS = True

# ✅ SECURITY: REST Framework Configuration
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

# ✅ SECURITY: JWT Configuration
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'VERIFYING_KEY': None,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
}

# ✅ SECURITY: Database Configuration
if os.environ.get('DATABASE_URL'):
    DATABASES = {
        'default': dj_database_url.config(
            default=os.environ.get('DATABASE_URL'),
            conn_max_age=600,
            ssl_require=True
        )
    }
    DATABASES['default']['OPTIONS'] = {
        'sslmode': 'require',
    }
else:
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }

# ✅ SECURITY: Logging Configuration
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'security_file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': 'security.log',
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'myapp.security': {
            'handlers': ['security_file'],
            'level': 'INFO',
            'propagate': True,
        },
    },
}

# Push Notifications Settings
PUSH_NOTIFICATIONS_SETTINGS = {
    "APNS_CERTIFICATE": "/path/to/your/certificate.pem",  # Replace with actual path for production
    "APNS_TOPIC": "com.yourdomain.studycon",  # Replace with your app bundle ID
    "APNS_USE_SANDBOX": True,  # Set to False for production
}

# ✅ SECURITY: Security Headers
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
SECURE_HSTS_SECONDS = 31536000  # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# ✅ SECURITY: Request Size Limits (removed duplicates - using settings above)

# ✅ SECURITY: Additional Security Settings
SECURE_REFERRER_POLICY = 'strict-origin-when-cross-origin'
SECURE_CROSS_ORIGIN_OPENER_POLICY = 'same-origin'
