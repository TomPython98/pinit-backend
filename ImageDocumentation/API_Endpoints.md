# Image API Endpoints Documentation

## Base URL
```
https://pinit-backend-production.up.railway.app
```

## Authentication
All endpoints require proper authentication. Include authentication headers as needed.

---

## 1. Upload User Image

### Endpoint
```
POST /api/upload_user_image/
```

### Description
Uploads a new image for a user. Supports profile pictures, gallery images, and cover photos.

### Request Format
**Content-Type**: `multipart/form-data`

### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `username` | string | Yes | Username of the image owner |
| `image` | file | Yes | Image file data |
| `image_type` | string | Yes | Type of image: `profile`, `gallery`, or `cover` |
| `is_primary` | boolean | Yes | Whether this is the primary profile picture |
| `caption` | string | No | Optional caption for the image |

### Example Request
```bash
curl -X POST "https://pinit-backend-production.up.railway.app/api/upload_user_image/" \
  -F "username=john_doe" \
  -F "image=@profile.jpg" \
  -F "image_type=profile" \
  -F "is_primary=true" \
  -F "caption=My new profile picture"
```

### Response Format
```json
{
  "success": true,
  "message": "Image uploaded successfully",
  "image": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "url": "https://pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev/pinit-images/users/john_doe/images/profile_1640995200.jpg",
    "image_type": "profile",
    "is_primary": true,
    "caption": "My new profile picture",
    "uploaded_at": "2024-01-01T12:00:00Z",
    "width": 800,
    "height": 600,
    "size_bytes": 125000,
    "mime_type": "image/jpeg"
  }
}
```

### Error Responses
```json
{
  "success": false,
  "error": "Invalid image format"
}
```

---

## 2. Get User Images

### Endpoint
```
GET /api/user_images/{username}/
```

### Description
Retrieves all images for a specific user.

### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `username` | string | Yes | Username to get images for (in URL path) |

### Example Request
```bash
curl "https://pinit-backend-production.up.railway.app/api/user_images/john_doe/"
```

### Response Format
```json
{
  "success": true,
  "images": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "url": "https://pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev/pinit-images/users/john_doe/images/profile_1640995200.jpg",
      "image_type": "profile",
      "is_primary": true,
      "caption": "Profile Picture",
      "uploaded_at": "2024-01-01T12:00:00Z",
      "width": 800,
      "height": 600,
      "size_bytes": 125000,
      "mime_type": "image/jpeg"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "url": "https://pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev/pinit-images/users/john_doe/images/gallery_1640995300.jpg",
      "image_type": "gallery",
      "is_primary": false,
      "caption": "Gallery Image",
      "uploaded_at": "2024-01-01T12:01:00Z",
      "width": 1200,
      "height": 800,
      "size_bytes": 200000,
      "mime_type": "image/jpeg"
    }
  ],
  "count": 2
}
```

### Error Responses
```json
{
  "success": false,
  "error": "User not found"
}
```

---

## 3. Delete User Image

### Endpoint
```
DELETE /api/user_image/{image_id}/delete/
```

### Description
Deletes a specific image by its ID.

### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `image_id` | string | Yes | UUID of the image to delete (in URL path) |

### Example Request
```bash
curl -X DELETE "https://pinit-backend-production.up.railway.app/api/user_image/550e8400-e29b-41d4-a716-446655440000/delete/"
```

### Response Format
```json
{
  "success": true,
  "message": "Image deleted successfully"
}
```

### Error Responses
```json
{
  "success": false,
  "error": "Image not found"
}
```

---

## 4. Set Primary Image

### Endpoint
```
POST /api/user_image/{image_id}/set_primary/
```

### Description
Sets an image as the primary profile picture for a user.

### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `image_id` | string | Yes | UUID of the image to set as primary (in URL path) |

### Example Request
```bash
curl -X POST "https://pinit-backend-production.up.railway.app/api/user_image/550e8400-e29b-41d4-a716-446655440000/set_primary/"
```

### Response Format
```json
{
  "success": true,
  "message": "Primary image updated successfully"
}
```

### Error Responses
```json
{
  "success": false,
  "error": "Image not found"
}
```

---

## 5. Serve Image

### Endpoint
```
GET /api/user_image/{image_id}/serve/
```

### Description
Serves the actual image file. This is a fallback endpoint when direct R2 URLs are not accessible.

### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `image_id` | string | Yes | UUID of the image to serve (in URL path) |

### Example Request
```bash
curl "https://pinit-backend-production.up.railway.app/api/user_image/550e8400-e29b-41d4-a716-446655440000/serve/"
```

### Response Format
- **Content-Type**: `image/jpeg`, `image/png`, etc.
- **Body**: Raw image file data

### Error Responses
- **404 Not Found**: Image doesn't exist
- **403 Forbidden**: Access denied
- **500 Internal Server Error**: Server error

---

## 6. Debug R2 Status

### Endpoint
```
GET /api/debug/r2-status/
```

### Description
Checks the status of R2 storage connection and configuration.

### Example Request
```bash
curl "https://pinit-backend-production.up.railway.app/api/debug/r2-status/"
```

### Response Format
```json
{
  "status": "connected",
  "bucket": "pinit-images",
  "region": "auto",
  "public_domain": "pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev",
  "test_upload": true,
  "test_download": true
}
```

---

## 7. Test R2 Storage

### Endpoint
```
GET /api/test-r2-storage/
```

### Description
Performs a complete test of R2 storage functionality including upload, download, and cleanup.

### Example Request
```bash
curl "https://pinit-backend-production.up.railway.app/api/test-r2-storage/"
```

### Response Format
```json
{
  "success": true,
  "message": "R2 storage test completed successfully",
  "tests": {
    "connection": true,
    "upload": true,
    "download": true,
    "delete": true
  },
  "performance": {
    "upload_time_ms": 150,
    "download_time_ms": 75
  }
}
```

---

## HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created (for uploads) |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 413 | Payload Too Large |
| 415 | Unsupported Media Type |
| 500 | Internal Server Error |

---

## Rate Limiting

- **Upload**: 10 requests per minute per user
- **Download**: 100 requests per minute per user
- **General**: 1000 requests per hour per IP

---

## File Size Limits

- **Maximum file size**: 10MB
- **Supported formats**: JPEG, PNG, GIF, WebP
- **Recommended dimensions**: 800x800px for profile pictures
- **Auto-resize**: Images larger than 1920x1920px are automatically resized

---

## Security Considerations

1. **Authentication**: All endpoints require valid user authentication
2. **Authorization**: Users can only access their own images
3. **File validation**: Server validates file types and content
4. **Virus scanning**: Uploaded files are scanned for malware
5. **Rate limiting**: Prevents abuse and DoS attacks
6. **CORS**: Proper CORS headers for web access

---

## Error Handling

### Common Error Scenarios

1. **Invalid file format**
   ```json
   {
     "success": false,
     "error": "Unsupported file format. Please use JPEG, PNG, GIF, or WebP."
   }
   ```

2. **File too large**
   ```json
   {
     "success": false,
     "error": "File size exceeds 10MB limit."
   }
   ```

3. **User not found**
   ```json
   {
     "success": false,
     "error": "User not found"
   }
   ```

4. **Image not found**
   ```json
   {
     "success": false,
     "error": "Image not found"
   }
   ```

5. **Storage error**
   ```json
   {
     "success": false,
     "error": "Failed to store image. Please try again."
   }
   ```

---

## Testing

### Test Images
Use these test images for development:
- **Small**: 100x100px, ~5KB
- **Medium**: 800x600px, ~50KB
- **Large**: 1920x1080px, ~200KB
- **Oversized**: 4000x3000px, ~2MB (will be resized)

### Test Users
Create test users with known usernames:
- `test_user_1`
- `test_user_2`
- `test_user_3`

### Automated Testing
```bash
# Test upload
curl -X POST "https://pinit-backend-production.up.railway.app/api/upload_user_image/" \
  -F "username=test_user_1" \
  -F "image=@test_image.jpg" \
  -F "image_type=profile" \
  -F "is_primary=true"

# Test retrieval
curl "https://pinit-backend-production.up.railway.app/api/user_images/test_user_1/"

# Test deletion
curl -X DELETE "https://pinit-backend-production.up.railway.app/api/user_image/{image_id}/delete/"
```

This documentation provides complete API reference for the image system endpoints.
