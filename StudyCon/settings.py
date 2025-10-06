"""
Minimal Django settings for Railway deployment
"""
from pathlib import Path
import os

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'django-insecure-g241opytiwg*n5loc&_n)8nro2hdxd==#qus9s@u9v&9mvyz%6'
DEBUG = False
ALLOWED_HOSTS = ['*', 'healthcheck.railway.app']

INSTALLED_APPS = [
    "daphne",  # Django Channels
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    "myapp",
    "corsheaders", 
    'rest_framework',
    'rest_framework.authtoken',
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
    AWS_ACCESS_KEY_ID = '7a4467aff561cea6f89a877a6ad9fc58'
    AWS_SECRET_ACCESS_KEY = '5e6345fc231451d46694d10e90e8e1d85d9110a27f0860019a47b4eb005705b8'
    AWS_STORAGE_BUCKET_NAME = 'pinit-images'
    AWS_S3_ENDPOINT_URL = 'https://da76c95301856b7cd9fee0a8f758097a.r2.cloudflarestorage.com'
    AWS_S3_REGION_NAME = 'auto'
    AWS_S3_SIGNATURE_VERSION = 's3v4'
    AWS_DEFAULT_ACL = 'public-read'
    AWS_S3_OBJECT_PARAMETERS = {
        'CacheControl': 'max-age=86400',
    }
    DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
    
    # Force R2 storage for all file fields
    DEFAULT_FILE_STORAGE = 'myapp.storage_r2.R2Storage'
    STATICFILES_STORAGE = 'myapp.storage_r2.R2Storage'
    MEDIA_URL = 'https://pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev/'
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

CORS_ALLOW_ALL_ORIGINS = True

# Push Notifications Settings
PUSH_NOTIFICATIONS_SETTINGS = {
    "APNS_CERTIFICATE": "/path/to/your/certificate.pem",  # Replace with actual path for production
    "APNS_TOPIC": "com.yourdomain.studycon",  # Replace with your app bundle ID
    "APNS_USE_SANDBOX": True,  # Set to False for production
}
