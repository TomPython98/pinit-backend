# PinIt App - Social Interactions System Documentation

## Overview
This document provides comprehensive documentation for the social interactions system in PinIt, including comments, likes, shares, and the complete frontend-backend integration.

## System Architecture

### Backend Components

#### API Endpoints
- **Base URL**: `https://pinit-backend-production.up.railway.app`

#### 1. Event Comments
- **Endpoint**: `POST /api/events/comment/`
- **Description**: Add comments or replies to events
- **Request Body**:
  ```json
  {
    "username": "string",
    "event_id": "UUID string",
    "text": "string",
    "parent_id": "UUID string (optional)",
    "image_urls": ["url1", "url2", ...] (optional)
  }
  ```
- **Response**: `201 Created`
  ```json
  {
    "success": true,
    "post": {
      "id": 125,
      "text": "This is a test comment!",
      "username": "alex_cs_stanford",
      "created_at": "2025-10-08T15:58:49.554052+00:00",
      "imageURLs": null,
      "likes": 0,
      "isLikedByCurrentUser": false,
      "replies": []
    }
  }
  ```

#### 2. Event Likes
- **Endpoint**: `POST /api/events/like/`
- **Description**: Like or unlike events and comments
- **Request Body**:
  ```json
  {
    "username": "string",
    "event_id": "UUID string",
    "post_id": "UUID string (optional)"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "success": true,
    "liked": true,
    "message": "Like toggled successfully"
  }
  ```

#### 3. Event Shares
- **Endpoint**: `POST /api/events/share/`
- **Description**: Record event shares
- **Request Body**:
  ```json
  {
    "username": "string",
    "event_id": "UUID string",
    "platform": "string"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "success": true,
    "message": "Share recorded successfully"
  }
  ```

#### 4. Event Feed
- **Endpoint**: `GET /api/events/feed/{event_id}/?current_user={username}`
- **Description**: Get all social interactions for an event
- **Response**: `200 OK`
  ```json
  {
    "posts": [
      {
        "id": 125,
        "text": "This is a test comment!",
        "username": "alex_cs_stanford",
        "created_at": "2025-10-08T15:58:49.554052+00:00",
        "imageURLs": null,
        "likes": 0,
        "isLikedByCurrentUser": false,
        "replies": []
      }
    ],
    "likes": {
      "total": 0,
      "users": []
    },
    "shares": {
      "total": 0,
      "breakdown": {
        "whatsapp": 0,
        "facebook": 0,
        "twitter": 0,
        "instagram": 0,
        "other": 0
      }
    }
  }
  ```

### Frontend Components

#### 1. EventDetailedView.swift
**Location**: `Front_End/Fibbling_BackUp/Fibbling/Views/MapViews/EventDetailedView.swift`

**Key Features**:
- **Social Feed Button**: "Comments & Posts" button that opens `EventSocialFeedView`
- **Navigation**: Properly routes to social interactions via `showInteractions = true`
- **Integration**: Seamlessly connects main event view with social features

**Critical Fix Applied** (December 2024):
- **Issue**: "View Feed Button" was opening `EventFeedView` (photo sharing) instead of `EventSocialFeedView` (comments/posts)
- **Solution**: Changed button action from `showFeedView = true` to `showInteractions = true`
- **Result**: Users can now properly access posting functionality

#### 2. EventSocialFeedView.swift
**Location**: `Front_End/Fibbling_BackUp/Fibbling/Views/MapViews/EventDetailedView.swift` (lines 1770-3159)

**Components**:
- **Header View**: Navigation and event title
- **Create Post Section**: Text input, image picker, post button
- **Feed Stats**: Post count, likes, shares display
- **Posts List**: Scrollable list of comments and replies

**Key Features**:
- **Real-time Updates**: Optimistic UI updates with API synchronization
- **Image Support**: Multi-image upload with preview grid
- **Reply System**: Nested comments with proper threading
- **Like Functionality**: Heart button with haptic feedback
- **Character Limit**: 280 characters with visual counter
- **Error Handling**: Comprehensive error states and user feedback

#### 3. Data Models

##### EventInteractions
```swift
struct EventInteractions: Codable, Equatable {
    struct Post: Codable, Identifiable, Equatable {
        let id: Int
        let text: String
        let username: String
        let created_at: String
        let imageURLs: [String]?
        var likes: Int
        var isLikedByCurrentUser: Bool
        var replies: [Post]
    }
    
    struct Likes: Codable, Equatable {
        var total: Int
        var users: [String]
    }
    
    struct Shares: Codable, Equatable {
        var total: Int
        var breakdown: [String: Int]
    }
    
    var posts: [Post]
    var likes: Likes
    var shares: Shares
}
```

#### 4. API Integration

##### APICallsEventInteractions.swift
**Location**: `Front_End/Fibbling_BackUp/Fibbling/Views/APICallsEventInteractions.swift`

**Methods**:
- `fetchEventFeed()`: Load all interactions for an event
- `addPost()`: Create new comments with image support
- `toggleLike()`: Like/unlike posts and events
- `addReply()`: Reply to existing comments
- `shareEvent()`: Record sharing analytics

**Features**:
- **Combine Framework**: Reactive programming with publishers
- **Error Handling**: Comprehensive error states
- **Type Safety**: Strongly typed response models
- **Network Optimization**: Efficient request handling

## User Experience Flow

### 1. Accessing Social Features
1. User opens an event in `EventDetailedView`
2. Scrolls to "Social Feed Actions" section
3. Clicks "Comments & Posts" button
4. `EventSocialFeedView` opens in a sheet

### 2. Creating Posts
1. User types in text field (280 character limit)
2. Optionally adds images via camera/photo picker
3. Clicks "Post" button
4. Optimistic UI update shows post immediately
5. API call persists post to backend
6. Feed refreshes with real data

### 3. Interacting with Posts
1. **Like**: Tap heart button for haptic feedback
2. **Reply**: Tap reply button to add nested comment
3. **Share**: Tap share button to record analytics
4. **View Details**: Tap post for full-screen view

## Technical Implementation Details

### State Management
- **@State**: Local UI state (text input, loading states)
- **@EnvironmentObject**: Shared account manager
- **@Published**: Reactive data updates

### Network Handling
- **URLSession**: Native networking with proper error handling
- **JSON Decoding**: Type-safe data parsing
- **Optimistic Updates**: Immediate UI feedback
- **Error Recovery**: Graceful failure handling

### Performance Optimizations
- **Lazy Loading**: ScrollView with LazyVStack
- **Image Caching**: Integration with ProfessionalImageCache
- **Debounced Requests**: Prevents API spam
- **Memory Management**: Proper cleanup and cancellation

## Recent Fixes and Improvements

### December 2024 - Navigation Fix
**Problem**: Users couldn't access social posting functionality
**Root Cause**: "View Feed Button" opened wrong view (`EventFeedView` instead of `EventSocialFeedView`)
**Solution**: 
- Changed button action from `showFeedView = true` to `showInteractions = true`
- Updated button text to "Comments & Posts" for clarity
- Verified backend API integration

**Result**: Users can now properly access and use all social features

### Backend Verification
**API Testing Results**:
- ✅ Comment creation: `POST /api/events/comment/` working
- ✅ Feed retrieval: `GET /api/events/feed/{event_id}/` working
- ✅ Data format: Matches frontend expectations
- ✅ Error handling: Proper HTTP status codes

## Integration Points

### 1. Image System
- **Upload**: Integration with `ImageUploadManager`
- **Display**: Uses `ProfessionalCachedImageView`
- **Caching**: Leverages `ProfessionalImageCache`

### 2. User Management
- **Authentication**: Uses `UserAccountManager`
- **Profile Data**: Integrates with user profile system
- **Permissions**: Respects event access controls

### 3. Event System
- **Event Data**: Connected to `StudyEvent` model
- **RSVP Integration**: Links with attendance system
- **Auto-matching**: Respects event privacy settings

## Troubleshooting

### Common Issues

#### 1. Posts Not Appearing
**Symptoms**: User posts but doesn't see them in feed
**Causes**:
- Network connectivity issues
- API endpoint errors
- Data format mismatches

**Solutions**:
- Check network connection
- Verify API endpoint URLs
- Check console logs for errors
- Test with curl commands

#### 2. Cannot Access Social Feed
**Symptoms**: "Comments & Posts" button doesn't work
**Causes**:
- Navigation routing issues
- State management problems
- Sheet presentation errors

**Solutions**:
- Verify `showInteractions` state
- Check sheet presentation code
- Ensure proper environment objects

#### 3. Like Button Not Working
**Symptoms**: Heart button doesn't respond
**Causes**:
- API endpoint issues
- State update problems
- Network request failures

**Solutions**:
- Check API endpoint status
- Verify request payload format
- Test with network debugging

### Debug Commands

#### Test Comment Creation
```bash
curl -X POST "https://pinit-backend-production.up.railway.app/api/events/comment/" \
  -H "Content-Type: application/json" \
  -d '{"username": "test_user", "event_id": "event-uuid", "text": "Test comment"}'
```

#### Test Feed Retrieval
```bash
curl -X GET "https://pinit-backend-production.up.railway.app/api/events/feed/event-uuid/?current_user=test_user"
```

#### Test Like Functionality
```bash
curl -X POST "https://pinit-backend-production.up.railway.app/api/events/like/" \
  -H "Content-Type: application/json" \
  -d '{"username": "test_user", "event_id": "event-uuid", "post_id": 123}'
```

## Future Enhancements

### Planned Features
1. **Real-time Updates**: WebSocket integration for live comments
2. **Push Notifications**: Notify users of new comments/likes
3. **Rich Text**: Support for formatted text and mentions
4. **Media Sharing**: Video and audio support
5. **Moderation**: Content filtering and reporting

### Performance Improvements
1. **Pagination**: Load comments in batches
2. **Offline Support**: Cache comments for offline viewing
3. **Background Sync**: Sync comments when app becomes active
4. **Analytics**: Track engagement metrics

## Conclusion

The PinIt social interactions system provides a comprehensive platform for event-based communication. The recent navigation fix ensures users can properly access all social features, creating an engaging and interactive experience for collaborative learning.

The system is built with modern iOS development practices, including SwiftUI, Combine, and proper state management, ensuring a smooth and responsive user experience.

---

**Last Updated**: December 2024  
**Version**: 1.0  
**Status**: Production Ready ✅
