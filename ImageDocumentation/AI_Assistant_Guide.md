# AI Assistant Guide for PinIt Image System

## Overview
This guide is specifically designed for AI assistants working on the PinIt app image system. It provides quick reference, common patterns, and best practices.

---

## Quick Reference

### Key Files and Locations
```
Frontend (iOS):
├── Managers/ImageManager.swift                    # Core image management
├── Views/Components/UserProfileImageView.swift    # Profile picture component
├── Views/MapViews/EventDetailedView.swift         # Full-screen image view
├── Views/FriendsListView.swift                    # Friends list integration
├── Views/SettingsView.swift                       # Settings integration
└── Views/MapViews/EventCreationView.swift         # Event creation integration

Backend:
├── backend_deployment/myapp/models.py             # UserImage model
├── backend_deployment/myapp/views.py              # API endpoints
├── backend_deployment/myapp/urls.py               # URL routing
└── backend_deployment/StudyCon/settings.py        # R2 configuration
```

### Critical URLs
- **Backend API**: `https://pinit-backend-production.up.railway.app`
- **R2 Public Domain**: `pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev`
- **Image Endpoint**: `/api/user_images/{username}/`
- **Upload Endpoint**: `/api/upload_user_image/`

---

## Common Patterns

### 1. Adding Profile Pictures to New Views

#### Basic Integration
```swift
// 1. Import the component
import SwiftUI

// 2. Add to your view
UserProfileImageView(
    username: "user123",
    size: 50,
    showBorder: true,
    borderColor: .blue
)
```

#### With Full-Screen Support
```swift
UserProfileImageView(
    username: "user123",
    size: 50,
    showBorder: true,
    borderColor: .blue,
    enableFullScreen: true  // Enables tap-to-fullscreen
)
```

#### Custom Styling
```swift
UserProfileImageView(
    username: "user123",
    size: 100,
    showBorder: true,
    borderColor: .brandPrimary,  // Use app's brand colors
    enableFullScreen: true
)
```

### 2. Loading Images Programmatically

#### Load Single User Images
```swift
let imageManager = ImageManager.shared
await imageManager.loadUserImages(username: "user123")
let images = imageManager.getUserImagesFromCache(username: "user123")
```

#### Load Multiple Users
```swift
let usernames = ["user1", "user2", "user3"]
await imageManager.loadMultipleUserImages(usernames: usernames)
```

#### Get Primary Image
```swift
let primaryImage = imageManager.getPrimaryImage()
if let image = primaryImage {
    let imageURL = imageManager.getFullImageURL(image)
    // Use imageURL for display
}
```

### 3. Uploading Images

#### Create Upload Request
```swift
let request = ImageUploadRequest(
    username: "user123",
    imageData: imageData,
    imageType: .profile,
    isPrimary: true,
    caption: "My profile picture"
)
```

#### Perform Upload
```swift
let success = await imageManager.uploadImage(request)
if success {
    print("Upload successful")
} else {
    print("Upload failed: \(imageManager.errorMessage ?? "Unknown error")")
}
```

### 4. Error Handling Patterns

#### Check for Errors
```swift
if let error = imageManager.errorMessage {
    // Handle error
    print("Error: \(error)")
    imageManager.clearError()
}
```

#### Handle Loading States
```swift
if imageManager.isLoading {
    ProgressView("Loading images...")
} else if imageManager.userImages.isEmpty {
    Text("No images available")
} else {
    // Display images
}
```

---

## Common Issues and Fixes

### 1. "userImageCache is inaccessible due to private protection level"

**Problem**: Trying to access private properties
**Solution**: Change `private var` to `var` in ImageManager.swift

```swift
// Change this:
private var userImageCache: [String: [UserImage]] = [:]

// To this:
var userImageCache: [String: [UserImage]] = [:]
```

### 2. "Cannot find 'UserProfileImageView' in scope"

**Problem**: Component not imported or not found
**Solution**: Ensure the file exists and is properly imported

```swift
// Check if file exists at:
// Front_End/Fibbling_BackUp/Fibbling/Views/Components/UserProfileImageView.swift
```

### 3. Images Not Loading

**Problem**: Various causes
**Solution**: Check in order:

1. **Network connectivity**
2. **Backend status**: `curl https://pinit-backend-production.up.railway.app/api/debug/r2-status/`
3. **User has images**: `curl https://pinit-backend-production.up.railway.app/api/user_images/{username}/`
4. **R2 URLs**: Check if URLs are accessible

### 4. Wrong Images Showing

**Problem**: Cache not properly isolated per user
**Solution**: Ensure proper user isolation

```swift
// Clear cache when switching users
func switchUser(newUsername: String) {
    if currentUsername != newUsername {
        imageManager.clearUserCache(username: currentUsername ?? "")
        currentUsername = newUsername
    }
}
```

### 5. "Main actor-isolated property cannot be accessed from outside of the actor"

**Problem**: Accessing @MainActor properties from background thread
**Solution**: Use MainActor.run

```swift
await MainActor.run {
    self.userImageCache[username] = images
}
```

---

## Code Templates

### 1. New View with Profile Pictures

```swift
import SwiftUI

struct MyNewView: View {
    let username: String
    @StateObject private var imageManager = ImageManager.shared
    
    var body: some View {
        VStack {
            // Profile picture
            UserProfileImageView(
                username: username,
                size: 80,
                showBorder: true,
                borderColor: .blue,
                enableFullScreen: true
            )
            
            // Other content
            Text("Hello, \(username)!")
        }
        .onAppear {
            Task {
                await imageManager.loadUserImages(username: username)
            }
        }
    }
}
```

### 2. Image Gallery View

```swift
import SwiftUI

struct ImageGalleryView: View {
    let username: String
    @StateObject private var imageManager = ImageManager.shared
    @State private var userImages: [UserImage] = []
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                ForEach(userImages, id: \.id) { image in
                    ImageManager.shared.cachedAsyncImage(
                        url: imageManager.getFullImageURL(image),
                        contentMode: .fill
                    )
                    .frame(height: 100)
                    .clipped()
                }
            }
        }
        .onAppear {
            loadImages()
        }
    }
    
    private func loadImages() {
        Task {
            await imageManager.loadUserImages(username: username)
            await MainActor.run {
                userImages = imageManager.getUserImagesFromCache(username: username)
            }
        }
    }
}
```

### 3. Image Upload View

```swift
import SwiftUI
import PhotosUI

struct ImageUploadView: View {
    let username: String
    @StateObject private var imageManager = ImageManager.shared
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var caption = ""
    
    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
            }
            
            Button("Select Image") {
                showingImagePicker = true
            }
            
            TextField("Caption", text: $caption)
            
            Button("Upload") {
                uploadImage()
            }
            .disabled(selectedImage == nil || imageManager.isLoading)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
    
    private func uploadImage() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let request = ImageUploadRequest(
            username: username,
            imageData: imageData,
            imageType: .profile,
            isPrimary: true,
            caption: caption
        )
        
        Task {
            let success = await imageManager.uploadImage(request)
            if success {
                selectedImage = nil
                caption = ""
            }
        }
    }
}
```

---

## Testing Patterns

### 1. Unit Test Template

```swift
import XCTest
@testable import Fibbling

class ImageManagerTests: XCTestCase {
    var imageManager: ImageManager!
    
    override func setUp() {
        super.setUp()
        imageManager = ImageManager.shared
    }
    
    func testLoadUserImages() async {
        // Given
        let username = "test_user"
        
        // When
        await imageManager.loadUserImages(username: username)
        
        // Then
        let images = imageManager.getUserImagesFromCache(username: username)
        XCTAssertNotNil(images)
    }
    
    func testGetPrimaryImage() {
        // Given
        let images = [
            UserImage(id: "1", url: "url1", imageType: .profile, isPrimary: false, caption: "", uploadedAt: "2024-01-01"),
            UserImage(id: "2", url: "url2", imageType: .profile, isPrimary: true, caption: "", uploadedAt: "2024-01-02")
        ]
        imageManager.userImages = images
        
        // When
        let primaryImage = imageManager.getPrimaryImage()
        
        // Then
        XCTAssertEqual(primaryImage?.id, "2")
    }
}
```

### 2. UI Test Template

```swift
import XCTest

class ImageUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testProfilePictureDisplay() {
        // Given
        let profileView = app.otherElements["ProfileView"]
        
        // When
        profileView.tap()
        
        // Then
        let profilePicture = app.images["ProfilePicture"]
        XCTAssertTrue(profilePicture.exists)
    }
    
    func testFullScreenImage() {
        // Given
        let profilePicture = app.images["ProfilePicture"]
        
        // When
        profilePicture.tap()
        
        // Then
        let fullScreenView = app.otherElements["FullScreenImageView"]
        XCTAssertTrue(fullScreenView.exists)
    }
}
```

---

## Performance Optimization

### 1. Lazy Loading

```swift
struct LazyProfileView: View {
    let username: String
    @State private var isVisible = false
    
    var body: some View {
        UserProfileImageView(username: username)
            .onAppear {
                isVisible = true
            }
            .onDisappear {
                isVisible = false
            }
    }
}
```

### 2. Memory Management

```swift
class ImageMemoryManager {
    private let maxCacheSize = 100
    private var imageCache: [String: UIImage] = [:]
    
    func setImage(_ image: UIImage, for key: String) {
        if imageCache.count >= maxCacheSize {
            // Remove oldest entries
            let keysToRemove = Array(imageCache.keys.prefix(imageCache.count - maxCacheSize + 1))
            keysToRemove.forEach { imageCache.removeValue(forKey: $0) }
        }
        
        imageCache[key] = image
    }
}
```

### 3. Batch Operations

```swift
func loadMultipleUsersEfficiently(usernames: [String]) async {
    await withTaskGroup(of: Void.self) { group in
        for username in usernames {
            group.addTask {
                await self.loadUserImages(username: username)
            }
        }
    }
}
```

---

## Debugging Tools

### 1. Debug Logging

```swift
class ImageDebugger {
    static func logImageLoad(username: String, success: Bool, duration: TimeInterval) {
        print("🖼️ Image Load: \(username) - \(success ? "✅" : "❌") - \(String(format: "%.2f", duration))s")
    }
    
    static func logCacheStatus(_ imageManager: ImageManager) {
        print("📦 Cache Status:")
        print("  - Users: \(imageManager.userImageCache.keys)")
        print("  - Current: \(imageManager.currentUsername ?? "none")")
        print("  - Images: \(imageManager.userImages.count)")
    }
}
```

### 2. Network Monitoring

```swift
class NetworkMonitor {
    static func testImageEndpoint(username: String) async -> Bool {
        guard let url = URL(string: "https://pinit-backend-production.up.railway.app/api/user_images/\(username)/") else {
            return false
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            print("❌ Network error: \(error)")
        }
        
        return false
    }
}
```

---

## Best Practices

### 1. Always Use Async/Await
```swift
// ✅ Good
Task {
    await imageManager.loadUserImages(username: username)
}

// ❌ Bad
imageManager.loadUserImages(username: username) // Missing await
```

### 2. Handle Loading States
```swift
// ✅ Good
if imageManager.isLoading {
    ProgressView()
} else {
    // Display content
}

// ❌ Bad
// No loading state handling
```

### 3. Use Proper Error Handling
```swift
// ✅ Good
do {
    let success = await imageManager.uploadImage(request)
    if !success {
        showError(imageManager.errorMessage ?? "Upload failed")
    }
} catch {
    showError("Network error: \(error.localizedDescription)")
}

// ❌ Bad
let success = await imageManager.uploadImage(request)
// No error handling
```

### 4. Clear Caches Appropriately
```swift
// ✅ Good
func logout() {
    imageManager.clearAllCaches()
    // ... other logout logic
}

// ❌ Bad
// Never clearing caches
```

---

## Common Commands

### 1. Git Operations
```bash
# Check status
git status

# Add changes
git add .

# Commit with message
git commit -m "feat: Add profile pictures to new view"

# Push changes
git push origin main
```

### 2. Backend Testing
```bash
# Test image endpoint
curl https://pinit-backend-production.up.railway.app/api/user_images/test_user/

# Test R2 status
curl https://pinit-backend-production.up.railway.app/api/debug/r2-status/

# Test upload
curl -X POST https://pinit-backend-production.up.railway.app/api/upload_user_image/ \
  -F "username=test_user" \
  -F "image=@test.jpg" \
  -F "image_type=profile" \
  -F "is_primary=true"
```

### 3. File Operations
```bash
# Find image-related files
find . -name "*Image*" -type f

# Search for specific patterns
grep -r "UserProfileImageView" Front_End/

# Check file sizes
ls -la Front_End/Fibbling_BackUp/Fibbling/Views/Components/
```

This guide provides AI assistants with everything needed to work effectively with the PinIt image system.

