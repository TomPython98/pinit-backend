# Frontend Components Documentation

## Overview
This document details all frontend components related to image handling in the PinIt iOS app.

---

## Core Components

### 1. ImageManager
**File**: `Front_End/Fibbling_BackUp/Fibbling/Managers/ImageManager.swift`

**Purpose**: Centralized image management, caching, and API communication.

#### Key Properties
```swift
@Published var userImages: [UserImage] = []
@Published var isLoading = false
@Published var errorMessage: String?

let baseURL = "https://pinit-backend-production.up.railway.app"
var currentUsername: String?
var userImageCache: [String: [UserImage]] = [:]
private var imageCache: [String: UIImage] = [:]
```

#### Key Methods

##### `loadUserImages(username: String) async`
Loads all images for a specific user from the backend.

**Flow**:
1. Check if images are already cached
2. If not cached, make API call to `/api/user_images/{username}/`
3. Parse response and update cache
4. Handle errors gracefully

**Error Handling**:
- HTTP 404: User has no images → Return empty array
- Network errors: Log error and return empty array
- Invalid JSON: Log error and return empty array

##### `uploadImage(_ request: ImageUploadRequest) async -> Bool`
Uploads a new image for a user.

**Flow**:
1. Create multipart form data
2. Send POST request to `/api/upload_user_image/`
3. Parse response and update cache
4. Return success status

**Parameters**:
- `username`: Target user
- `imageData`: Raw image data
- `imageType`: profile/gallery/cover
- `isPrimary`: Whether this is the primary image
- `caption`: Optional description

##### `getFullImageURL(_ image: UserImage) -> String`
Generates the complete URL for an image.

**URL Generation**:
1. Check if URL already contains "http" (R2 URL)
2. If R2 URL, convert to public domain
3. If API URL, use as-is
4. Return complete URL

**R2 URL Conversion**:
```
From: https://da76c95301856b7cd9fee0a8f758097a.r2.cloudflarestorage.com/pinit-images/users/username/images/file.jpg
To:   https://pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev/pinit-images/users/username/images/file.jpg
```

##### `getPrimaryImage() -> UserImage?`
Determines the primary image for display.

**Priority Order**:
1. Image marked as `isPrimary: true`
2. Most recent profile image
3. Most recent image of any type
4. Return `nil` if no images

---

### 2. UserProfileImageView
**File**: `Front_End/Fibbling_BackUp/Fibbling/Views/Components/UserProfileImageView.swift`

**Purpose**: Reusable component for displaying user profile pictures with fallbacks.

#### Initialization
```swift
UserProfileImageView(
    username: String,
    size: CGFloat = 50,
    showBorder: Bool = true,
    borderColor: Color = .blue,
    enableFullScreen: Bool = false
)
```

#### Display States

##### 1. Loading State
```swift
Circle()
    .fill(Color(.systemGray6))
    .frame(width: size, height: size)
    .overlay(
        ProgressView()
            .scaleEffect(0.6)
    )
```

##### 2. Image State
```swift
ImageManager.shared.cachedAsyncImage(
    url: ImageManager.shared.getFullImageURL(primaryImage),
    contentMode: .fill
)
.frame(width: size, height: size)
.clipShape(Circle())
.overlay(
    Circle()
        .stroke(showBorder ? borderColor : Color.clear, lineWidth: showBorder ? 2 : 0)
)
```

##### 3. Fallback State (No Image)
```swift
Circle()
    .fill(
        LinearGradient(
            colors: [
                borderColor.opacity(0.2),
                borderColor.opacity(0.1),
                borderColor.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .frame(width: size, height: size)
    .overlay(
        VStack(spacing: 2) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: size * 0.4))
                .foregroundColor(borderColor)
            Text(username.prefix(1).uppercased())
                .font(.system(size: size * 0.25, weight: .bold))
                .foregroundColor(borderColor)
        }
    )
```

#### Lifecycle Methods

##### `loadUserImages()`
1. Check if images are cached
2. If not cached, trigger API call
3. Update local state with cached images

##### `getPrimaryImage() -> UserImage?`
1. Find image marked as primary
2. Fallback to most recent profile image
3. Fallback to most recent image of any type

---

### 3. CachedAsyncImageView
**File**: `Front_End/Fibbling_BackUp/Fibbling/Managers/ImageManager.swift`

**Purpose**: Optimized image loading with memory caching.

#### Properties
```swift
let url: String
let contentMode: ContentMode
@State private var loadedImage: UIImage?
@State private var isLoading = true
@State private var loadError: String?
```

#### Loading Process
1. Check memory cache first
2. If not cached, load from network
3. Cache successful loads
4. Handle errors gracefully

#### Display States
- **Loading**: Progress indicator
- **Success**: Display image
- **Error**: Error message with icon

---

## Integration Points

### 1. FriendsListView
**File**: `Front_End/Fibbling_BackUp/Fibbling/Views/FriendsListView.swift`

**Usage**:
```swift
// Friends section
UserProfileImageView(
    username: friend.username,
    size: 40,
    showBorder: true,
    borderColor: .blue
)

// Friend requests section
UserProfileImageView(
    username: request.fromUsername,
    size: 35,
    showBorder: true,
    borderColor: .orange
)

// Discover users section
UserProfileImageView(
    username: user.username,
    size: 45,
    showBorder: true,
    borderColor: .green
)
```

### 2. EventDetailedView
**File**: `Front_End/Fibbling_BackUp/Fibbling/Views/MapViews/EventDetailedView.swift`

**Usage**:
```swift
// Host profile
UserProfileImageView(
    username: event.hostUsername,
    size: 60,
    showBorder: true,
    borderColor: .brandPrimary,
    enableFullScreen: true
)

// Attendees list
UserProfileImageView(
    username: attendee.username,
    size: 40,
    showBorder: true,
    borderColor: .blue
)

// Social posts
UserProfileImageView(
    username: post.username,
    size: 30,
    showBorder: false
)
```

### 3. SettingsView
**File**: `Front_End/Fibbling_BackUp/Fibbling/Views/SettingsView.swift`

**Usage**:
```swift
// Current user profile
UserProfileImageView(
    username: accountManager.currentUser ?? "Guest",
    size: 100,
    showBorder: true,
    borderColor: .brandPrimary,
    enableFullScreen: true
)
```

### 4. EventCreationView
**File**: `Front_End/Fibbling_BackUp/Fibbling/Views/MapViews/EventCreationView.swift`

**Usage**:
```swift
// Friends selection
UserProfileImageView(
    username: friend.username,
    size: 30,
    showBorder: false
)
```

---

## Full-Screen Image Viewing

### FullScreenImageView
**File**: `Front_End/Fibbling_BackUp/Fibbling/Views/MapViews/EventDetailedView.swift`

**Purpose**: Displays user images in full-screen mode with navigation.

#### Features
- TabView for multiple images
- Page indicators
- Loading states
- Error handling
- Navigation controls

#### Usage
```swift
.sheet(isPresented: $showFullScreenImage) {
    FullScreenImageView(username: username)
}
```

#### Implementation
```swift
TabView(selection: $currentImageIndex) {
    ForEach(Array(userImages.enumerated()), id: \.offset) { index, image in
        ImageManager.shared.cachedAsyncImage(
            url: ImageManager.shared.getFullImageURL(image),
            contentMode: .fit
        )
        .tag(index)
    }
}
.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
```

---

## Data Flow

### 1. Image Loading Flow
```
UserProfileImageView.onAppear
    ↓
loadUserImages()
    ↓
ImageManager.loadUserImages(username)
    ↓
Check userImageCache[username]
    ↓
If not cached: API call to /api/user_images/{username}/
    ↓
Parse response and update cache
    ↓
Update userImages state
    ↓
getPrimaryImage() determines display image
    ↓
CachedAsyncImageView loads image
    ↓
Display image or fallback
```

### 2. Image Upload Flow
```
User selects image
    ↓
ImageUploadRequest created
    ↓
ImageManager.uploadImage(request)
    ↓
Multipart form data created
    ↓
POST to /api/upload_user_image/
    ↓
Parse response
    ↓
Clear cache for user
    ↓
Reload user images
    ↓
Update UI
```

### 3. Cache Management Flow
```
App launch
    ↓
ImageManager.shared initialized
    ↓
userImageCache = [:]
imageCache = [:]
    ↓
User logs in
    ↓
Load user images
    ↓
Cache images by username
    ↓
User switches accounts
    ↓
Clear previous user cache
    ↓
Load new user images
    ↓
User logs out
    ↓
clearAllCaches()
```

---

## Error Handling

### Network Errors
- **No connection**: Show offline state
- **Timeout**: Retry with exponential backoff
- **Server error**: Show error message

### Image Errors
- **404 Not Found**: Show user initials
- **403 Forbidden**: Show "Image expired" message
- **Invalid format**: Show error icon

### Cache Errors
- **Memory pressure**: Clear old cache entries
- **Corrupted data**: Clear cache and reload
- **Race conditions**: Use thread-safe operations

---

## Performance Considerations

### Memory Management
- **Image cache**: Limited to 100 images
- **User cache**: Unlimited (cleared on logout)
- **Automatic cleanup**: On memory warnings

### Network Optimization
- **Caching**: Avoid redundant API calls
- **Batch loading**: Load multiple users at once
- **Lazy loading**: Load images when visible

### UI Performance
- **Async loading**: Non-blocking image loads
- **Smooth transitions**: Animated state changes
- **Efficient rendering**: Optimized view updates

---

## Customization

### Styling Options
```swift
// Size variations
UserProfileImageView(username: "user", size: 30)  // Small
UserProfileImageView(username: "user", size: 50)  // Medium
UserProfileImageView(username: "user", size: 100) // Large

// Border options
UserProfileImageView(username: "user", showBorder: true, borderColor: .blue)
UserProfileImageView(username: "user", showBorder: false)

// Full-screen support
UserProfileImageView(username: "user", enableFullScreen: true)
```

### Color Themes
- **Primary**: `.brandPrimary`
- **Secondary**: `.brandSecondary`
- **Success**: `.green`
- **Warning**: `.orange`
- **Error**: `.red`

---

## Testing

### Unit Tests
```swift
// Test image loading
func testLoadUserImages() async {
    let imageManager = ImageManager.shared
    await imageManager.loadUserImages(username: "test_user")
    XCTAssertFalse(imageManager.userImages.isEmpty)
}

// Test cache functionality
func testImageCaching() {
    let imageManager = ImageManager.shared
    let images = imageManager.getUserImagesFromCache(username: "test_user")
    XCTAssertNotNil(images)
}
```

### UI Tests
```swift
// Test profile picture display
func testProfilePictureDisplay() {
    let profileView = UserProfileImageView(username: "test_user")
    // Verify initial state
    // Verify loading state
    // Verify image display
    // Verify fallback state
}
```

This documentation provides complete details about frontend image components and their usage.
