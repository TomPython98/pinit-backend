# Swift Frontend Documentation

## Overview
The PinIt iOS app is built using SwiftUI and follows a modern iOS architecture pattern. The app provides a comprehensive study group management platform with real-time features, social interactions, and location-based event discovery.

## Architecture

### Core Components

#### 1. **UserAccountManager** (`UserAccountManager.swift`)
**Purpose**: Central authentication and user management system

**Key Features**:
- JWT token management (access & refresh tokens)
- User authentication (login/register/logout)
- Friend request management
- User session persistence

**Key Methods**:
```swift
// Authentication
func login(username: String, password: String, completion: @escaping (Bool, String) -> Void)
func register(username: String, password: String, completion: @escaping (Bool, String) -> Void)
func logout()

// Token Management
func saveTokens(access: String, refresh: String)
func addAuthHeader(to request: inout URLRequest)
func clearTokens()

// Friend Management
func fetchFriends()
func fetchFriendRequests()
func sendFriendRequest(to username: String, completion: @escaping (Bool, String) -> Void)
func acceptFriendRequest(from username: String, completion: @escaping (Bool, String) -> Void)
```

**State Variables**:
```swift
@Published var currentUser: String?
@Published var friends: [String] = []
@Published var friendRequests: [String] = []
@Published var accessToken: String?
@Published var refreshToken: String?
```

#### 2. **ImageManager** (`ImageManager.swift`)
**Purpose**: Handles image loading, caching, and optimization

**Key Features**:
- Multi-tier image caching (thumbnail, full resolution)
- JWT-authenticated image requests
- Batch image prefetching
- Memory and disk cache management

**Key Methods**:
```swift
func loadCachedImage(from url: String) async -> (image: UIImage?, fromCache: Bool)
func preloadImages() async
func clearCache()
func cachedAsyncImage(url: String, contentMode: ContentMode, targetSize: CGSize?) -> some View
```

#### 3. **FriendsListView** (`FriendsListView.swift`)
**Purpose**: Main interface for friend management and user discovery

**Key Features**:
- Tabbed interface (Friends, Requests, Discover)
- Real-time friend request updates
- User profile image display
- Search and filtering capabilities

**State Management**:
```swift
@State private var selectedTab = 0
@State private var allUsers: [String] = []
@State private var isLoading = false
@State private var isPrefetchingImages = false
```

#### 4. **EventDetailedView** (`EventDetailedView.swift`)
**Purpose**: Detailed event view with social interactions

**Key Features**:
- Event information display
- Comment system with JWT authentication
- Like and share functionality
- Real-time updates via WebSocket

**Comment System**:
```swift
private func addPost() {
    // JWT-authenticated comment posting
    accountManager.addAuthHeader(to: &request)
    // Posts to: /api/events/comment/
}
```

## Authentication Flow

### JWT Token Management
1. **Login Process**:
   ```
   User enters credentials → API call to /api/login/ → 
   Backend returns JWT tokens → Tokens saved to UserDefaults → 
   Tokens used for subsequent API calls
   ```

2. **Token Persistence**:
   - Access tokens stored in `UserDefaults` with key `access_token`
   - Refresh tokens stored with key `refresh_token`
   - Tokens loaded on app startup if user was previously logged in

3. **Request Authentication**:
   ```swift
   func addAuthHeader(to request: inout URLRequest) {
       if let token = accessToken {
           request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
       }
   }
   ```

## API Integration

### Base Configuration
```swift
// APIConfig.swift
let primaryBaseURL = "https://pinit-backend-production.up.railway.app/api"
```

### Key Endpoints

#### Authentication
- `POST /api/login/` - User login
- `POST /api/register/` - User registration
- `POST /api/logout/` - User logout

#### Friend Management
- `GET /api/get_friends/{username}/` - Get user's friends
- `GET /api/get_pending_requests/{username}/` - Get pending friend requests
- `POST /api/send_friend_request/` - Send friend request
- `POST /api/accept_friend_request/` - Accept friend request
- `GET /api/get_all_users/` - Get all users for discovery

#### Social Features
- `POST /api/events/comment/` - Post event comment
- `POST /api/toggle_event_like/` - Like/unlike event
- `POST /api/record_event_share/` - Share event

#### User Profile
- `GET /api/get_user_profile/{username}/` - Get user profile
- `POST /api/update_user_profile/` - Update user profile

## Real-time Features

### WebSocket Integration
```swift
// WebSocket connection for real-time updates
let webSocketURL = "wss://pinit-backend-production.up.railway.app/ws/events/{username}/"
```

**Features**:
- Real-time event updates
- Live comment notifications
- Friend request notifications
- Connection status monitoring

## Image Management System

### Caching Strategy
1. **Memory Cache**: Fast access for recently viewed images
2. **Disk Cache**: Persistent storage for offline access
3. **Network Fetch**: JWT-authenticated requests to backend

### Image Loading Flow
```
User requests image → Check memory cache → 
Check disk cache → Network request with JWT → 
Cache result → Display image
```

### Batch Prefetching
```swift
// Prefetch images for visible users
func prefetchVisibleImages() async {
    let usersToPrefetch = getVisibleUsers()
    await ImageManager.shared.batchPrefetch(users: usersToPrefetch)
}
```

## Debugging System

### Comprehensive Logging
The app includes extensive debugging throughout all major components:

#### Authentication Debugging
```swift
print("🔍 🔐 login() called for username: \(username)")
print("🔍 🔐 Access token received: \(accessToken != nil ? "Yes" : "No")")
print("🔍 🔐 Added JWT token to request: \(String(token.prefix(20)))...")
```

#### Network Debugging
```swift
print("🔍 → GET \(url.absoluteString)")
print("🔍 ← \(httpResponse.statusCode) \(url.absoluteString)")
print("🔍 DEBUG: Data received, length: \(data.count) bytes")
```

#### Image Loading Debugging
```swift
print("🔍 🖼️ ImageManager: Adding JWT auth header for \(username)")
print("🔍 🖼️ ImageManager: HTTP response status: \(httpResponse.statusCode)")
```

## State Management

### ObservableObject Pattern
Key managers use `@Published` properties for reactive UI updates:

```swift
class UserAccountManager: ObservableObject {
    @Published var currentUser: String?
    @Published var friends: [String] = []
    @Published var friendRequests: [String] = []
    @Published var accessToken: String?
}
```

### Data Flow
1. **User Action** → Manager Method
2. **Manager Method** → API Call
3. **API Response** → Update @Published Properties
4. **UI Updates** → SwiftUI Reactive Updates

## Error Handling

### Network Error Handling
```swift
if let httpResponse = response as? HTTPURLResponse {
    switch httpResponse.statusCode {
    case 200...299:
        // Success
    case 401:
        // Authentication error - redirect to login
    case 403:
        // Permission denied
    case 500...599:
        // Server error
    default:
        // Unknown error
    }
}
```

### User-Friendly Error Messages
- Network connectivity issues
- Authentication failures
- Permission denied scenarios
- Server errors with fallback options

## Performance Optimizations

### Image Optimization
- Lazy loading of profile images
- Batch prefetching for visible users
- Memory-efficient caching with size limits
- Background image processing

### Network Optimization
- Request deduplication
- Intelligent caching strategies
- Connection pooling
- Timeout management

## Security Features

### JWT Token Security
- Secure token storage in UserDefaults
- Automatic token refresh handling
- Token validation before API calls
- Secure logout with token cleanup

### API Security
- All authenticated endpoints require JWT tokens
- CORS headers properly configured
- Rate limiting implemented
- Input validation on all user inputs

## Testing and Debugging

### Debug Logs
The app includes comprehensive logging for:
- Authentication flow
- API requests/responses
- Image loading operations
- WebSocket connections
- Error conditions

### Common Debug Patterns
```swift
// Authentication debugging
print("🔍 🔐 [Component]: [Action] for [User]")

// Network debugging  
print("🔍 → [METHOD] [URL]")
print("🔍 ← [STATUS] [URL]")

// Image debugging
print("🔍 🖼️ ImageManager: [Action] for [User]")
```

## Current Status

### ✅ Working Features
- User authentication (login/register/logout)
- Friend request system (send/accept/view)
- JWT token management
- Real-time WebSocket connections
- Event creation and management
- Comment posting with authentication
- Profile image management
- User discovery system

### ⚠️ Known Issues
- Image loading returns 403 for other users (permission issue)
- Some profile completion endpoints connect to non-existent servers
- JSON parsing errors on some endpoints (HTML responses)

### 🔧 Recent Fixes
- Fixed duplicate friend request functions
- Added JWT authentication to comment posting
- Unified data sources for friend requests
- Added comprehensive debugging throughout the app

## Future Enhancements

### Planned Features
- Push notifications for friend requests
- Real-time chat system
- Advanced event filtering
- Offline mode support
- Enhanced image compression
- Background sync capabilities

### Performance Improvements
- Implement image compression
- Add request retry logic
- Optimize WebSocket reconnection
- Implement proper error recovery
- Add analytics and monitoring

---

*This documentation reflects the current state of the Swift frontend as of the latest debugging session. The app demonstrates a robust, well-architected iOS application with comprehensive authentication, real-time features, and social interaction capabilities.*
