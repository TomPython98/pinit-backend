# Image System Troubleshooting Guide

## Overview
This guide helps diagnose and resolve common issues with the PinIt app image system.

---

## Common Issues and Solutions

### 1. Images Not Loading

#### Symptoms
- Profile pictures show user initials instead of images
- "Failed to load" or "Image couldn't load" messages
- White screens when viewing images

#### Diagnosis Steps

1. **Check Network Connection**
   ```bash
   # Test backend connectivity
   curl -I https://pinit-backend-production.up.railway.app/api/debug/r2-status/
   ```

2. **Check Backend Status**
   ```bash
   # Test image endpoint
   curl https://pinit-backend-production.up.railway.app/api/user_images/test_user/
   ```

3. **Check R2 Storage**
   ```bash
   # Test R2 connection
   curl https://pinit-backend-production.up.railway.app/api/test-r2-storage/
   ```

4. **Check Console Logs**
   Look for these error patterns:
   ```
   ⚠️ ImageManager: HTTP 404 for user username
   ⚠️ ImageManager: Error loading images for username: error description
   ❌ ProfessionalCachedImageView: HTTP Error 403 for https://...
   ```

#### Solutions

**A. Backend API Issues**
- **404 Not Found**: User has no images → This is normal, show initials
- **500 Server Error**: Backend issue → Check server logs
- **Network Error**: Connection issue → Check network connectivity

**B. R2 Storage Issues**
- **403 Forbidden**: Image URL expired → Refresh user images
- **404 Not Found**: Image doesn't exist → Check if image was properly uploaded

**C. Frontend Issues**
- **Cache Problems**: Clear app cache and restart
- **Memory Issues**: Restart app to clear memory cache
- **Race Conditions**: Ensure proper async handling

### 2. Wrong Images Showing

#### Symptoms
- User A's image appears for User B
- Images switch between users randomly
- Cached images show for wrong users

#### Root Causes
1. **Cache Not Isolated**: User images not properly separated in cache
2. **Race Conditions**: Multiple async operations interfering
3. **Shared State**: Components sharing image state

#### Solutions

**A. Fix Cache Isolation**
```swift
// Ensure proper user isolation
func loadUserImages(username: String) async {
    // Clear any existing data for different user
    if currentUsername != username {
        userImages = []
        currentUsername = username
    }
    
    // Load images for specific user
    // ... rest of implementation
}
```

**B. Fix Race Conditions**
```swift
// Use proper async/await patterns
@MainActor
func loadUserImages(username: String) async {
    // Ensure main actor isolation
    // ... implementation
}
```

**C. Clear Shared State**
```swift
// Clear cache when switching users
func clearUserCache(username: String) {
    userImageCache.removeValue(forKey: username)
    if currentUsername == username {
        userImages = []
        currentUsername = nil
    }
}
```

### 3. Slow Loading Performance

#### Symptoms
- Images take 5+ seconds to load
- Loading indicators show for extended periods
- App becomes unresponsive during image loading

#### Root Causes
1. **Large Image Files**: Images not optimized
2. **Multiple API Calls**: Redundant network requests
3. **Inefficient Caching**: Cache not working properly
4. **Network Issues**: Slow or unstable connection

#### Solutions

**A. Optimize Image Sizes**
```python
# Backend: Resize large images
def process_image(image_file):
    img = Image.open(image_file)
    max_size = (1920, 1920)
    if img.size[0] > max_size[0] or img.size[1] > max_size[1]:
        img.thumbnail(max_size, Image.Resampling.LANCZOS)
    return img
```

**B. Implement Proper Caching**
```swift
// Frontend: Check cache first
func loadUserImages(username: String) async {
    if let cachedImages = userImageCache[username] {
        userImages = cachedImages
        return
    }
    // Only make API call if not cached
}
```

**C. Batch API Calls**
```swift
// Load multiple users at once
func loadMultipleUserImages(usernames: [String]) async {
    await withTaskGroup(of: Void.self) { group in
        for username in usernames {
            group.addTask {
                await self.loadUserImages(username: username)
            }
        }
    }
}
```

### 4. Upload Failures

#### Symptoms
- Image uploads fail silently
- "Upload failed" error messages
- Images not appearing after upload

#### Diagnosis Steps

1. **Check File Size**
   ```swift
   // Frontend: Check file size before upload
   if imageData.count > 10 * 1024 * 1024 { // 10MB
       showError("File too large")
       return
   }
   ```

2. **Check File Format**
   ```swift
   // Frontend: Validate file type
   let allowedTypes = ["image/jpeg", "image/png", "image/gif", "image/webp"]
   if !allowedTypes.contains(mimeType) {
       showError("Unsupported file format")
       return
   }
   ```

3. **Check Backend Logs**
   Look for upload errors in backend logs

#### Solutions

**A. File Validation**
```swift
func validateImageFile(_ data: Data, mimeType: String) -> Bool {
    // Check size
    guard data.count <= 10 * 1024 * 1024 else { return false }
    
    // Check type
    let allowedTypes = ["image/jpeg", "image/png", "image/gif", "image/webp"]
    guard allowedTypes.contains(mimeType) else { return false }
    
    return true
}
```

**B. Error Handling**
```swift
func uploadImage(_ request: ImageUploadRequest) async -> Bool {
    do {
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200, 201:
                return true
            case 413:
                errorMessage = "File too large"
            case 415:
                errorMessage = "Unsupported file format"
            default:
                errorMessage = "Upload failed (Status: \(httpResponse.statusCode))"
            }
        }
    } catch {
        errorMessage = "Upload failed: \(error.localizedDescription)"
    }
    
    return false
}
```

### 5. Full-Screen View Issues

#### Symptoms
- White screen when tapping profile pictures
- Images not loading in full-screen mode
- Navigation issues in full-screen view

#### Solutions

**A. Fix White Screen**
```swift
// Ensure proper image loading in FullScreenImageView
struct FullScreenImageView: View {
    @StateObject private var imageManager = ImageManager.shared
    @State private var userImages: [UserImage] = []
    @State private var isLoading = true
    
    var body: some View {
        if isLoading {
            ProgressView()
        } else if userImages.isEmpty {
            Text("No images available")
        } else {
            TabView {
                ForEach(userImages, id: \.id) { image in
                    ImageManager.shared.cachedAsyncImage(
                        url: ImageManager.shared.getFullImageURL(image),
                        contentMode: .fit
                    )
                }
            }
        }
    }
}
```

**B. Fix Navigation**
```swift
// Ensure proper sheet presentation
.sheet(isPresented: $showFullScreenImage) {
    FullScreenImageView(username: username)
}
```

---

## Debug Tools and Commands

### 1. Backend Debug Endpoints

#### Check R2 Status
```bash
curl https://pinit-backend-production.up.railway.app/api/debug/r2-status/
```

Expected response:
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

#### Test R2 Storage
```bash
curl https://pinit-backend-production.up.railway.app/api/test-r2-storage/
```

Expected response:
```json
{
  "success": true,
  "message": "R2 storage test completed successfully",
  "tests": {
    "connection": true,
    "upload": true,
    "download": true,
    "delete": true
  }
}
```

### 2. Frontend Debug Logging

#### Enable Debug Logs
```swift
// Add to ImageManager
func loadUserImages(username: String) async {
    print("🔍 Loading images for user: \(username)")
    
    // ... API call ...
    
    if let httpResponse = response as? HTTPURLResponse {
        print("📊 HTTP Status: \(httpResponse.statusCode)")
    }
    
    // ... rest of implementation ...
}
```

#### Check Cache Status
```swift
// Add to ImageManager
func debugCacheStatus() {
    print("📦 Cache status:")
    print("  - User cache: \(userImageCache.keys)")
    print("  - Image cache: \(imageCache.keys.count) images")
    print("  - Current user: \(currentUsername ?? "none")")
}
```

### 3. Network Debugging

#### Test API Endpoints
```bash
# Test user images endpoint
curl -v https://pinit-backend-production.up.railway.app/api/user_images/test_user/

# Test image upload
curl -X POST https://pinit-backend-production.up.railway.app/api/upload_user_image/ \
  -F "username=test_user" \
  -F "image=@test.jpg" \
  -F "image_type=profile" \
  -F "is_primary=true"
```

#### Check Image URLs
```bash
# Test R2 URL directly
curl -I https://pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev/pinit-images/users/test_user/images/profile_123456.jpg

# Test API serve endpoint
curl -I https://pinit-backend-production.up.railway.app/api/user_image/{image_id}/serve/
```

---

## Performance Monitoring

### 1. Frontend Performance

#### Image Loading Times
```swift
func loadUserImages(username: String) async {
    let startTime = CFAbsoluteTimeGetCurrent()
    
    // ... load images ...
    
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("⏱️ Image loading took \(timeElapsed) seconds")
}
```

#### Memory Usage
```swift
func checkMemoryUsage() {
    let memoryInfo = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &memoryInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_,
                     task_flavor_t(MACH_TASK_BASIC_INFO),
                     $0,
                     &count)
        }
    }
    
    if kerr == KERN_SUCCESS {
        print("💾 Memory usage: \(memoryInfo.resident_size / 1024 / 1024) MB")
    }
}
```

### 2. Backend Performance

#### Database Query Performance
```python
import time
from django.db import connection

def get_user_images(request, username):
    start_time = time.time()
    
    # Query with timing
    images = UserImage.objects.filter(user=username)
    images_list = list(images)
    
    # Log performance
    execution_time = time.time() - start_time
    query_count = len(connection.queries)
    
    print(f"📊 Query performance: {execution_time:.2f}s, {query_count} queries")
    
    return images_list
```

#### R2 Upload Performance
```python
def upload_user_image(request):
    start_time = time.time()
    
    # ... upload logic ...
    
    upload_time = time.time() - start_time
    print(f"📤 Upload performance: {upload_time:.2f}s")
    
    return response
```

---

## Error Recovery Strategies

### 1. Automatic Retry
```swift
func loadUserImagesWithRetry(username: String, maxRetries: Int = 3) async {
    for attempt in 1...maxRetries {
        do {
            await loadUserImages(username: username)
            return // Success
        } catch {
            if attempt == maxRetries {
                print("❌ Failed after \(maxRetries) attempts")
                return
            }
            
            // Wait before retry
            try await Task.sleep(nanoseconds: UInt64(attempt * 1000_000_000))
        }
    }
}
```

### 2. Fallback Strategies
```swift
func loadUserImages(username: String) async {
    // Try primary endpoint first
    if await loadFromPrimaryEndpoint(username: username) {
        return
    }
    
    // Fallback to secondary endpoint
    if await loadFromSecondaryEndpoint(username: username) {
        return
    }
    
    // Fallback to cached data
    if let cachedImages = userImageCache[username] {
        userImages = cachedImages
        return
    }
    
    // Final fallback: show initials
    userImages = []
}
```

### 3. Cache Recovery
```swift
func recoverFromCacheCorruption() {
    // Clear corrupted cache
    userImageCache.removeAll()
    imageCache.removeAll()
    
    // Reload current user's images
    if let username = currentUsername {
        Task {
            await loadUserImages(username: username)
        }
    }
}
```

---

## Prevention Strategies

### 1. Input Validation
```swift
func validateImageUpload(_ data: Data, mimeType: String) -> ValidationResult {
    // Size validation
    guard data.count <= 10 * 1024 * 1024 else {
        return .failure("File too large")
    }
    
    // Type validation
    let allowedTypes = ["image/jpeg", "image/png", "image/gif", "image/webp"]
    guard allowedTypes.contains(mimeType) else {
        return .failure("Unsupported file format")
    }
    
    // Content validation
    guard UIImage(data: data) != nil else {
        return .failure("Invalid image data")
    }
    
    return .success
}
```

### 2. Rate Limiting
```swift
class RateLimiter {
    private var requestCounts: [String: Int] = [:]
    private let maxRequests = 10
    private let timeWindow: TimeInterval = 60 // 1 minute
    
    func canMakeRequest(for key: String) -> Bool {
        let now = Date()
        // Implementation of rate limiting logic
        return true
    }
}
```

### 3. Monitoring
```swift
class ImageSystemMonitor {
    static func logImageLoad(username: String, success: Bool, duration: TimeInterval) {
        // Log to analytics service
        Analytics.log("image_load", parameters: [
            "username": username,
            "success": success,
            "duration": duration
        ])
    }
}
```

---

## Emergency Procedures

### 1. Complete System Reset
```swift
func emergencyReset() {
    // Clear all caches
    ImageManager.shared.clearAllCaches()
    
    // Reset user state
    currentUsername = nil
    userImages = []
    
    // Restart image loading
    if let username = getCurrentUser() {
        Task {
            await ImageManager.shared.loadUserImages(username: username)
        }
    }
}
```

### 2. Fallback to Offline Mode
```swift
func enableOfflineMode() {
    // Disable network requests
    isOfflineMode = true
    
    // Show cached images only
    // Display "Offline" indicator
    // Allow local image viewing
}
```

### 3. Emergency Contact
- **Backend Issues**: Check Railway deployment logs
- **R2 Storage Issues**: Check Cloudflare R2 dashboard
- **Frontend Issues**: Check Xcode console logs
- **Database Issues**: Check Django admin panel

This troubleshooting guide provides comprehensive solutions for common image system issues.

