# Backend Implementation Documentation

## Overview
This document details the backend implementation of the image system in the PinIt app, including models, views, URLs, and storage configuration.

---

## Project Structure

### Main Backend (No Image Support)
```
Back_End/StudyCon/StudyCon/
├── settings.py          # Main app settings
├── urls.py             # Main URL routing
└── wsgi.py             # WSGI configuration
```

### Image Backend (Complete Image System)
```
backend_deployment/
├── myapp/
│   ├── models.py       # UserImage model
│   ├── views.py        # Image API endpoints
│   └── urls.py         # Image URL routing
├── StudyCon/
│   ├── settings.py     # Image backend settings
│   └── urls.py         # Main URL routing
└── requirements.txt    # Dependencies
```

---

## Models

### UserImage Model
**File**: `backend_deployment/myapp/models.py`

```python
class UserImage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.CharField(max_length=150)
    image = models.ImageField(upload_to=get_upload_path)
    image_type = models.CharField(max_length=20, choices=IMAGE_TYPE_CHOICES)
    is_primary = models.BooleanField(default=False)
    caption = models.TextField(blank=True, null=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    width = models.PositiveIntegerField(null=True, blank=True)
    height = models.PositiveIntegerField(null=True, blank=True)
    size_bytes = models.PositiveIntegerField(null=True, blank=True)
    mime_type = models.CharField(max_length=100, blank=True, null=True)
    url = models.URLField(blank=True, null=True)  # R2 URL storage
```

#### Image Type Choices
```python
IMAGE_TYPE_CHOICES = [
    ('profile', 'Profile Picture'),
    ('gallery', 'Gallery Image'),
    ('cover', 'Cover Photo'),
]
```

#### Upload Path Function
```python
def get_upload_path(instance, filename):
    """Generate upload path for R2 storage"""
    timestamp = int(time.time() * 1000000)  # Microsecond precision
    extension = os.path.splitext(filename)[1]
    return f"users/{instance.user}/images/{instance.image_type}_{timestamp}{extension}"
```

#### Save Method (Critical Implementation)
```python
def save(self, *args, **kwargs):
    # CRITICAL: Set all other images to non-primary BEFORE saving
    if self.is_primary:
        UserImage.objects.filter(user=self.user, is_primary=True).exclude(id=self.id).update(is_primary=False)
    
    super().save(*args, **kwargs)
    
    # Generate R2 URL after save
    if self.image:
        self.url = self.generate_r2_url()
        super().save(update_fields=['url'])
```

#### R2 URL Generation
```python
def generate_r2_url(self):
    """Generate public R2 URL for the image"""
    if not self.image:
        return None
    
    # Extract the key from the file path
    file_key = self.image.name
    
    # Generate public R2 URL
    public_domain = "pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev"
    return f"https://{public_domain}/{file_key}"
```

---

## API Views

### 1. Upload User Image
**File**: `backend_deployment/myapp/views.py`
**Function**: `upload_user_image`

```python
@csrf_exempt
def upload_user_image(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
    
    try:
        username = request.POST.get('username')
        image_file = request.FILES.get('image')
        image_type = request.POST.get('image_type')
        is_primary = request.POST.get('is_primary', 'false').lower() == 'true'
        caption = request.POST.get('caption', '')
        
        # Validation
        if not all([username, image_file, image_type]):
            return JsonResponse({'error': 'Missing required fields'}, status=400)
        
        # Create UserImage instance
        user_image = UserImage(
            user=username,
            image=image_file,
            image_type=image_type,
            is_primary=is_primary,
            caption=caption
        )
        
        # Save (triggers R2 upload and URL generation)
        user_image.save()
        
        # Return success response
        return JsonResponse({
            'success': True,
            'message': 'Image uploaded successfully',
            'image': {
                'id': str(user_image.id),
                'url': user_image.url,
                'image_type': user_image.image_type,
                'is_primary': user_image.is_primary,
                'caption': user_image.caption,
                'uploaded_at': user_image.uploaded_at.isoformat(),
                'width': user_image.width,
                'height': user_image.height,
                'size_bytes': user_image.size_bytes,
                'mime_type': user_image.mime_type
            }
        })
        
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
```

### 2. Get User Images
**Function**: `get_user_images`

```python
def get_user_images(request, username):
    try:
        images = UserImage.objects.filter(user=username).order_by('-uploaded_at')
        
        images_data = []
        for img in images:
            images_data.append({
                'id': str(img.id),
                'url': img.url or f"/api/user_image/{img.id}/serve/",
                'image_type': img.image_type,
                'is_primary': img.is_primary,
                'caption': img.caption or '',
                'uploaded_at': img.uploaded_at.isoformat(),
                'width': img.width,
                'height': img.height,
                'size_bytes': img.size_bytes,
                'mime_type': img.mime_type
            })
        
        return JsonResponse({
            'success': True,
            'images': images_data,
            'count': len(images_data)
        })
        
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
```

### 3. Delete User Image
**Function**: `delete_user_image`

```python
def delete_user_image(request, image_id):
    try:
        user_image = UserImage.objects.get(id=image_id)
        
        # Delete from R2 storage
        if user_image.image:
            user_image.image.delete(save=False)
        
        # Delete from database
        user_image.delete()
        
        return JsonResponse({
            'success': True,
            'message': 'Image deleted successfully'
        })
        
    except UserImage.DoesNotExist:
        return JsonResponse({'error': 'Image not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
```

### 4. Set Primary Image
**Function**: `set_primary_image`

```python
def set_primary_image(request, image_id):
    try:
        user_image = UserImage.objects.get(id=image_id)
        
        # Set all other images to non-primary
        UserImage.objects.filter(user=user_image.user, is_primary=True).update(is_primary=False)
        
        # Set this image as primary
        user_image.is_primary = True
        user_image.save()
        
        return JsonResponse({
            'success': True,
            'message': 'Primary image updated successfully'
        })
        
    except UserImage.DoesNotExist:
        return JsonResponse({'error': 'Image not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
```

### 5. Serve Image
**Function**: `serve_user_image`

```python
def serve_user_image(request, image_id):
    try:
        user_image = UserImage.objects.get(id=image_id)
        
        if not user_image.image:
            return JsonResponse({'error': 'Image file not found'}, status=404)
        
        # Serve the image file
        response = HttpResponse(user_image.image.read(), content_type=user_image.mime_type or 'image/jpeg')
        response['Content-Disposition'] = f'inline; filename="{user_image.image.name}"'
        return response
        
    except UserImage.DoesNotExist:
        return JsonResponse({'error': 'Image not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
```

---

## URL Configuration

### Main URLs
**File**: `backend_deployment/StudyCon/urls.py`

```python
urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('myapp.urls')),
]
```

### Image URLs
**File**: `backend_deployment/myapp/urls.py`

```python
urlpatterns = [
    path('upload_user_image/', views.upload_user_image, name='upload_user_image'),
    path('user_images/<str:username>/', views.get_user_images, name='get_user_images'),
    path('user_image/<uuid:image_id>/delete/', views.delete_user_image, name='delete_user_image'),
    path('user_image/<uuid:image_id>/set_primary/', views.set_primary_image, name='set_primary_image'),
    path('user_image/<uuid:image_id>/serve/', views.serve_user_image, name='serve_user_image'),
    path('debug/r2-status/', views.debug_r2_status, name='debug_r2_status'),
    path('test-r2-storage/', views.test_r2_storage, name='test_r2_storage'),
]
```

---

## Storage Configuration

### R2 Storage Settings
**File**: `backend_deployment/StudyCon/settings.py`

```python
# Cloudflare R2 Storage Configuration
R2_ACCOUNT_ID = os.getenv('R2_ACCOUNT_ID')
R2_ACCESS_KEY_ID = os.getenv('R2_ACCESS_KEY_ID')
R2_SECRET_ACCESS_KEY = os.getenv('R2_SECRET_ACCESS_KEY')
R2_BUCKET_NAME = os.getenv('R2_BUCKET_NAME', 'pinit-images')
R2_PUBLIC_DOMAIN = os.getenv('R2_PUBLIC_DOMAIN', 'pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev')

# Django Storage Configuration
DEFAULT_FILE_STORAGE = 'myapp.storage_r2.R2Storage'
STATICFILES_STORAGE = 'myapp.storage_r2.R2StaticStorage'

# R2 Storage Settings
R2_STORAGE_SETTINGS = {
    'account_id': R2_ACCOUNT_ID,
    'access_key_id': R2_ACCESS_KEY_ID,
    'secret_access_key': R2_SECRET_ACCESS_KEY,
    'bucket_name': R2_BUCKET_NAME,
    'region_name': 'auto',
    'endpoint_url': 'https://da76c95301856b7cd9fee0a8f758097a.r2.cloudflarestorage.com',
    'public_domain': R2_PUBLIC_DOMAIN,
}
```

### R2 Storage Implementation
**File**: `backend_deployment/myapp/storage_r2.py`

```python
from storages.backends.s3boto3 import S3Boto3Storage
from django.conf import settings

class R2Storage(S3Boto3Storage):
    """Cloudflare R2 Storage implementation"""
    
    def __init__(self, *args, **kwargs):
        kwargs.update({
            'bucket_name': settings.R2_STORAGE_SETTINGS['bucket_name'],
            'region_name': settings.R2_STORAGE_SETTINGS['region_name'],
            'endpoint_url': settings.R2_STORAGE_SETTINGS['endpoint_url'],
            'access_key': settings.R2_STORAGE_SETTINGS['access_key_id'],
            'secret_key': settings.R2_STORAGE_SETTINGS['secret_access_key'],
        })
        super().__init__(*args, **kwargs)
    
    def url(self, name):
        """Generate public URL for R2 files"""
        if self.public_domain:
            return f"https://{self.public_domain}/{name}"
        return super().url(name)
    
    @property
    def public_domain(self):
        return settings.R2_STORAGE_SETTINGS.get('public_domain')
```

---

## Database Schema

### UserImage Table
```sql
CREATE TABLE myapp_userimage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user VARCHAR(150) NOT NULL,
    image VARCHAR(100) NOT NULL,
    image_type VARCHAR(20) NOT NULL CHECK (image_type IN ('profile', 'gallery', 'cover')),
    is_primary BOOLEAN DEFAULT FALSE,
    caption TEXT,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    width INTEGER,
    height INTEGER,
    size_bytes INTEGER,
    mime_type VARCHAR(100),
    url TEXT
);

-- Indexes for performance
CREATE INDEX idx_userimage_user ON myapp_userimage(user);
CREATE INDEX idx_userimage_type ON myapp_userimage(image_type);
CREATE INDEX idx_userimage_primary ON myapp_userimage(is_primary);
CREATE INDEX idx_userimage_uploaded ON myapp_userimage(uploaded_at);
```

---

## Error Handling

### Common Error Scenarios

#### 1. File Upload Errors
```python
# File too large
if image_file.size > 10 * 1024 * 1024:  # 10MB
    return JsonResponse({'error': 'File size exceeds 10MB limit'}, status=413)

# Invalid file type
allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
if image_file.content_type not in allowed_types:
    return JsonResponse({'error': 'Unsupported file format'}, status=415)
```

#### 2. Database Errors
```python
try:
    user_image = UserImage.objects.get(id=image_id)
except UserImage.DoesNotExist:
    return JsonResponse({'error': 'Image not found'}, status=404)
except Exception as e:
    return JsonResponse({'error': f'Database error: {str(e)}'}, status=500)
```

#### 3. Storage Errors
```python
try:
    user_image.save()  # Triggers R2 upload
except Exception as e:
    return JsonResponse({'error': f'Storage error: {str(e)}'}, status=500)
```

---

## Security Considerations

### 1. File Validation
```python
def validate_image_file(file):
    """Validate uploaded image file"""
    # Check file size
    if file.size > 10 * 1024 * 1024:
        raise ValueError("File too large")
    
    # Check file type
    allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
    if file.content_type not in allowed_types:
        raise ValueError("Invalid file type")
    
    # Check file extension
    allowed_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp']
    if not any(file.name.lower().endswith(ext) for ext in allowed_extensions):
        raise ValueError("Invalid file extension")
    
    return True
```

### 2. User Authorization
```python
def check_user_permission(request, username):
    """Check if user can access/modify images"""
    # Implement your authentication logic here
    # For example, check if request.user.username == username
    # or if user has admin permissions
    pass
```

### 3. Input Sanitization
```python
def sanitize_input(data):
    """Sanitize user input"""
    # Remove HTML tags
    data = re.sub(r'<[^>]+>', '', data)
    
    # Limit length
    data = data[:1000]
    
    # Escape special characters
    data = html.escape(data)
    
    return data
```

---

## Performance Optimization

### 1. Database Queries
```python
# Use select_related for foreign keys
images = UserImage.objects.select_related('user').filter(user=username)

# Use only() to fetch only needed fields
images = UserImage.objects.only('id', 'url', 'image_type', 'is_primary')

# Use prefetch_related for many-to-many relationships
# (if applicable)
```

### 2. Caching
```python
from django.core.cache import cache

def get_user_images_cached(username):
    """Get user images with caching"""
    cache_key = f"user_images_{username}"
    images = cache.get(cache_key)
    
    if images is None:
        images = list(UserImage.objects.filter(user=username).values())
        cache.set(cache_key, images, 300)  # 5 minutes
    
    return images
```

### 3. Image Processing
```python
from PIL import Image
import io

def process_image(image_file):
    """Process and optimize image"""
    # Open image
    img = Image.open(image_file)
    
    # Resize if too large
    max_size = (1920, 1920)
    if img.size[0] > max_size[0] or img.size[1] > max_size[1]:
        img.thumbnail(max_size, Image.Resampling.LANCZOS)
    
    # Convert to RGB if necessary
    if img.mode in ('RGBA', 'LA', 'P'):
        img = img.convert('RGB')
    
    # Save with optimization
    output = io.BytesIO()
    img.save(output, format='JPEG', quality=85, optimize=True)
    output.seek(0)
    
    return output
```

---

## Monitoring and Logging

### 1. Request Logging
```python
import logging

logger = logging.getLogger(__name__)

def upload_user_image(request):
    logger.info(f"Image upload request from user: {request.POST.get('username')}")
    
    try:
        # Upload logic
        logger.info(f"Image uploaded successfully: {user_image.id}")
    except Exception as e:
        logger.error(f"Image upload failed: {str(e)}")
        raise
```

### 2. Performance Monitoring
```python
import time
from django.db import connection

def get_user_images(request, username):
    start_time = time.time()
    
    # Query execution
    images = UserImage.objects.filter(user=username)
    
    # Log performance
    execution_time = time.time() - start_time
    query_count = len(connection.queries)
    
    logger.info(f"User images query: {execution_time:.2f}s, {query_count} queries")
    
    return images
```

---

## Testing

### 1. Unit Tests
```python
from django.test import TestCase
from django.core.files.uploadedfile import SimpleUploadedFile

class UserImageModelTest(TestCase):
    def test_image_upload(self):
        """Test image upload functionality"""
        image_file = SimpleUploadedFile(
            "test.jpg",
            b"file_content",
            content_type="image/jpeg"
        )
        
        user_image = UserImage.objects.create(
            user="test_user",
            image=image_file,
            image_type="profile",
            is_primary=True
        )
        
        self.assertEqual(user_image.user, "test_user")
        self.assertTrue(user_image.is_primary)
```

### 2. API Tests
```python
from django.test import Client
from django.urls import reverse

class ImageAPITest(TestCase):
    def setUp(self):
        self.client = Client()
    
    def test_upload_image(self):
        """Test image upload API"""
        with open('test_image.jpg', 'rb') as f:
            response = self.client.post('/api/upload_user_image/', {
                'username': 'test_user',
                'image': f,
                'image_type': 'profile',
                'is_primary': 'true'
            })
        
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()['success'])
```

This documentation provides complete details about the backend implementation of the image system.

