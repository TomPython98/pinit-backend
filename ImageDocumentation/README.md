# PinIt App - Image System Documentation

## Overview
This documentation provides a comprehensive guide to the image system in the PinIt app, including architecture, API endpoints, data flow, and implementation details for AI assistants and developers.

## Table of Contents
1. [System Architecture](#system-architecture)
2. [Backend API Endpoints](#backend-api-endpoints)
3. [Frontend Components](#frontend-components)
4. [Data Models](#data-models)
5. [Image Storage & URLs](#image-storage--urls)
6. [Caching System](#caching-system)
7. [Error Handling](#error-handling)
8. [Usage Examples](#usage-examples)
9. [Troubleshooting](#troubleshooting)
10. [Future Improvements](#future-improvements)

---

## System Architecture

### Backend Structure
The image system uses **two separate backend deployments**:

1. **Main Backend** (`Back_End/StudyCon/StudyCon/`)
   - URL: `https://pinit-backend-production.up.railway.app`
   - Contains: User management, events, social features
   - **Does NOT have image endpoints**

2. **Image Backend** (`backend_deployment/`)
   - URL: `https://pinit-backend-production.up.railway.app` (same URL, different deployment)
   - Contains: All image-related endpoints and models
   - **Has complete image system**

### Frontend Structure
- **iOS App**: `Front_End/Fibbling_BackUp/Fibbling/`
- **Android App**: `Front_End/Android/PinIt_Android/`

---

## Backend API Endpoints

### Image Management Endpoints
All endpoints are prefixed with: `https://pinit-backend-production.up.railway.app`

| Endpoint | Method | Purpose | Parameters |
|----------|--------|---------|------------|
| `/api/upload_user_image/` | POST | Upload new image | `username`, `image`, `image_type`, `is_primary`, `caption` |
| `/api/user_images/<username>/` | GET | Get all images for user | `username` in URL |
| `/api/user_image/<image_id>/delete/` | DELETE | Delete specific image | `image_id` in URL |
| `/api/user_image/<image_id>/set_primary/` | POST | Set image as primary | `image_id` in URL |
| `/api/user_image/<image_id>/serve/` | GET | Serve image file | `image_id` in URL |
| `/api/debug/r2-status/` | GET | Check R2 storage status | None |
| `/api/test-r2-storage/` | GET | Test R2 connection | None |

### Request/Response Formats

#### Upload Image Request
```json
{
  "username": "string",
  "image": "file_data",
  "image_type": "profile|gallery|cover",
  "is_primary": boolean,
  "caption": "string"
}
```

#### User Images Response
```json
{
  "success": true,
  "images": [
    {
      "id": "uuid",
      "url": "https://pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev/pinit-images/users/username/images/filename.jpg",
      "image_type": "profile",
      "is_primary": true,
      "caption": "Profile Picture",
      "uploaded_at": "2024-01-01T00:00:00Z",
      "width": 800,
      "height": 600,
      "size_bytes": 125000,
      "mime_type": "image/jpeg"
    }
  ],
  "count": 1
}
```

---

## Frontend Components

### Core Components

#### 1. ImageManager (`Managers/ImageManager.swift`)
**Purpose**: Centralized image management and caching
**Key Features**:
- User-based image caching
- API communication
- Image URL generation
- Cache management

**Key Methods**:
```swift
func loadUserImages(username: String) async
func uploadImage(_ request: ImageUploadRequest) async -> Bool
func deleteImage(imageId: String, username: String) async -> Bool
func setPrimaryImage(imageId: String, username: String) async -> Bool
func getFullImageURL(_ image: UserImage) -> String
func getUserImagesFromCache(username: String) -> [UserImage]
```

#### 2. UserProfileImageView (`Views/Components/UserProfileImageView.swift`)
**Purpose**: Reusable component for displaying user profile pictures
**Features**:
- Automatic image loading
- Fallback to user initials
- Loading states
- Full-screen viewing support
- Customizable size and styling

**Usage**:
```swift
UserProfileImageView(
    username: "john_doe",
    size: 50,
    showBorder: true,
    borderColor: .blue,
    enableFullScreen: true
)
```

#### 3. CachedAsyncImageView (`Managers/ImageManager.swift`)
**Purpose**: Optimized image loading with caching
**Features**:
- Memory caching
- Network loading
- Error handling
- Loading indicators

### Integration Points

#### Views Using Profile Pictures
1. **FriendsListView** - Friends, requests, discover sections
2. **EventDetailedView** - Host, attendees, social posts
3. **SettingsView** - User profile section
4. **EventCreationView** - Friends selection
5. **UserProfileView** - Full user profile display

---

## Data Models

### UserImage Model
```swift
struct UserImage: Identifiable, Codable, Hashable {
    let id: String                    // UUID
    let url: String                   // Full image URL
    let imageType: ImageType          // profile|gallery|cover
    let isPrimary: Bool              // Primary profile picture
    let caption: String              // Image description
    let uploadedAt: String           // ISO8601 timestamp
    
    enum ImageType: String, CaseIterable, Codable {
        case profile = "profile"
        case gallery = "gallery"
        case cover = "cover"
    }
}
```

### ImageUploadRequest Model
```swift
struct ImageUploadRequest {
    let username: String
    let imageData: Data
    let imageType: UserImage.ImageType
    let isPrimary: Bool
    let caption: String
    let filename: String
    let mimeType: String
    let fileExtension: String
}
```

### Response Models
```swift
struct UserImagesResponse: Codable {
    let success: Bool
    let images: [UserImage]
    let count: Int
}

struct ImageUploadResponse: Codable {
    let success: Bool
    let message: String
    let image: UserImage?
}
```

---

## Image Storage & URLs

### Storage Provider
- **Cloudflare R2** (S3-compatible object storage)
- **Public Domain**: `pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev`
- **Bucket**: `pinit-images`

### URL Structure
```
https://pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev/pinit-images/users/{username}/images/{filename}
```

### URL Generation Process
1. **Backend Upload**: Image uploaded to R2 storage
2. **URL Storage**: R2 URL stored in database
3. **Frontend Access**: Direct R2 URL used for display
4. **Fallback**: API endpoint `/api/user_image/{id}/serve/` if R2 URL fails

### Image Optimization
- **Max Size**: 1920x1920 pixels
- **Quality**: 85% JPEG compression
- **Formats**: JPEG, PNG, GIF, WebP supported
- **Auto-resize**: Large images automatically resized

---

## Caching System

### Cache Levels

#### 1. User Image Cache
```swift
var userImageCache: [String: [UserImage]] = [:]
// Key: username, Value: array of UserImage objects
```

#### 2. Image Data Cache
```swift
private var imageCache: [String: UIImage] = [:]
// Key: image URL, Value: UIImage object
```

### Cache Management
- **Account-based**: Cache cleared on logout
- **Memory efficient**: LRU eviction for image cache
- **Thread-safe**: Concurrent queue for cache operations
- **Automatic cleanup**: Cache cleared when switching users

### Cache Lifecycle
1. **Load**: Check cache first, then API
2. **Store**: Cache successful API responses
3. **Update**: Refresh cache on image changes
4. **Clear**: Clear cache on logout/error

---

## Error Handling

### API Error Scenarios
1. **404 Not Found**: User has no images → Show initials
2. **403 Forbidden**: Image URL expired → Refresh images
3. **500 Server Error**: Backend issue → Show error message
4. **Network Error**: No connection → Show offline state

### Fallback Strategy
```
1. Try to load cached image
2. Try to load from network
3. Show loading indicator
4. If error: Show user initials
5. If no images: Show placeholder
```

### Error States
- **Loading**: Progress indicator
- **Error**: User initials with error styling
- **Empty**: Placeholder with "No images" message
- **Success**: Actual image display

---

## Usage Examples

### Basic Profile Picture
```swift
UserProfileImageView(username: "john_doe", size: 50)
```

### Custom Styled Profile Picture
```swift
UserProfileImageView(
    username: "jane_smith",
    size: 100,
    showBorder: true,
    borderColor: .green,
    enableFullScreen: true
)
```

### Loading User Images Programmatically
```swift
let imageManager = ImageManager.shared
await imageManager.loadUserImages(username: "user123")
let images = imageManager.getUserImagesFromCache(username: "user123")
```

### Uploading New Image
```swift
let request = ImageUploadRequest(
    username: "user123",
    imageData: imageData,
    imageType: .profile,
    isPrimary: true,
    caption: "New profile picture"
)
let success = await imageManager.uploadImage(request)
```

---

## Troubleshooting

### Common Issues

#### 1. Images Not Loading
**Symptoms**: Profile pictures show initials instead of images
**Causes**:
- Backend API not responding
- Invalid image URLs
- Network connectivity issues
- R2 storage problems

**Solutions**:
- Check network connection
- Verify backend status
- Check console logs for errors
- Test with different users

#### 2. Wrong Images Showing
**Symptoms**: User A's image shows for User B
**Causes**:
- Cache not properly isolated per user
- Race conditions in async loading
- Shared state between components

**Solutions**:
- Ensure proper user isolation in cache
- Use unique identifiers for each user
- Clear cache when switching users

#### 3. Slow Loading
**Symptoms**: Images take long time to appear
**Causes**:
- Large image files
- Slow network connection
- Inefficient caching
- Multiple API calls

**Solutions**:
- Implement image optimization
- Use proper caching strategy
- Batch API calls
- Show loading indicators

### Debug Information
Enable debug logging by checking console output:
```
⚠️ ImageManager: HTTP 404 for user username
⚠️ ImageManager: Error loading images for username: error description
✅ ImageManager: Successfully loaded 3 images for username
```

---

## Future Improvements

### Planned Enhancements
1. **Image Compression**: Client-side image compression before upload
2. **Progressive Loading**: Show low-res images first, then high-res
3. **CDN Integration**: Use Cloudflare CDN for faster delivery
4. **Batch Operations**: Upload multiple images at once
5. **Image Editing**: Crop, rotate, filter images before upload

### Performance Optimizations
1. **Lazy Loading**: Load images only when visible
2. **Preloading**: Preload images for likely-to-be-viewed users
3. **Memory Management**: Better memory usage for large image sets
4. **Background Sync**: Sync images in background

### UI/UX Improvements
1. **Skeleton Loading**: Better loading states
2. **Image Transitions**: Smooth transitions between states
3. **Gesture Support**: Pinch to zoom, swipe gestures
4. **Accessibility**: Better accessibility support

---

## API Reference

### ImageManager Methods

#### `loadUserImages(username: String) async`
Loads all images for a specific user
- **Parameters**: `username` - The user's username
- **Returns**: Void (updates internal cache)
- **Side Effects**: Updates `userImages` and `userImageCache`

#### `uploadImage(_ request: ImageUploadRequest) async -> Bool`
Uploads a new image for a user
- **Parameters**: `request` - Image upload request object
- **Returns**: `Bool` - Success status
- **Side Effects**: Updates cache, triggers UI refresh

#### `deleteImage(imageId: String, username: String) async -> Bool`
Deletes a specific image
- **Parameters**: 
  - `imageId` - UUID of image to delete
  - `username` - Owner's username
- **Returns**: `Bool` - Success status
- **Side Effects**: Removes from cache, triggers UI refresh

#### `setPrimaryImage(imageId: String, username: String) async -> Bool`
Sets an image as the primary profile picture
- **Parameters**:
  - `imageId` - UUID of image to set as primary
  - `username` - Owner's username
- **Returns**: `Bool` - Success status
- **Side Effects**: Updates primary status, triggers UI refresh

#### `getFullImageURL(_ image: UserImage) -> String`
Generates the full URL for an image
- **Parameters**: `image` - UserImage object
- **Returns**: `String` - Complete image URL
- **Notes**: Handles R2 URL conversion

#### `getUserImagesFromCache(username: String) -> [UserImage]`
Retrieves cached images for a user
- **Parameters**: `username` - The user's username
- **Returns**: `[UserImage]` - Array of cached images
- **Notes**: Returns empty array if not cached

---

## Configuration

### Environment Variables
```bash
# Backend URL
PINIT_BACKEND_URL=https://pinit-backend-production.up.railway.app

# R2 Storage
R2_ACCOUNT_ID=your_account_id
R2_ACCESS_KEY_ID=your_access_key
R2_SECRET_ACCESS_KEY=your_secret_key
R2_BUCKET_NAME=pinit-images
R2_PUBLIC_DOMAIN=pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev
```

### Constants
```swift
// ImageManager.swift
private let baseURL = "https://pinit-backend-production.up.railway.app"

// Image optimization
let maxImageSize = CGSize(width: 1920, height: 1920)
let imageQuality: CGFloat = 0.85
```

---

This documentation provides a complete understanding of the image system for AI assistants and developers working on the PinIt app. For specific implementation details, refer to the source code files mentioned in each section.

