# PinIt App - Detailed Technical Documentation

## Table of Contents
1. [System Architecture Overview](#system-architecture-overview)
2. [Backend Implementation Details](#backend-implementation-details)
3. [Frontend Implementation Details](#frontend-implementation-details)
4. [Database Schema & Models](#database-schema--models)
5. [API Endpoints & Contracts](#api-endpoints--contracts)
6. [Real-time Communication](#real-time-communication)
7. [Image Management System](#image-management-system)
8. [Authentication & Security](#authentication--security)
9. [File Storage & CDN](#file-storage--cdn)
10. [Deployment & Infrastructure](#deployment--infrastructure)
11. [Performance Optimizations](#performance-optimizations)
12. [Error Handling & Logging](#error-handling--logging)

---

## System Architecture Overview

### Technology Stack
- **Backend**: Django 4.2 + Django REST Framework + PostgreSQL
- **Frontend**: SwiftUI (iOS) + Jetpack Compose (Android)
- **Storage**: Cloudflare R2 (S3-compatible)
- **Real-time**: Django Channels + WebSockets
- **Deployment**: Railway + Cloudflare CDN
- **Authentication**: Django sessions + Token auth

### System Components
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   iOS App       │    │   Android App   │    │   Web Client    │
│   (SwiftUI)     │    │   (Compose)     │    │   (Future)      │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │      Django Backend       │
                    │   (REST API + WebSocket)  │
                    └─────────────┬─────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │     PostgreSQL DB         │
                    │   (User Data + Events)    │
                    └─────────────┬─────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │    Cloudflare R2          │
                    │   (Image Storage + CDN)   │
                    └───────────────────────────┘
```

---

## Backend Implementation Details

### Django Project Structure
```
PinItApp/
├── myapp/                           # Main Django application
│   ├── models.py                   # Database models (719 lines)
│   ├── views.py                    # API endpoints (4241 lines)
│   ├── urls.py                     # URL routing (27 lines)
│   ├── consumers.py                # WebSocket handlers (173 lines)
│   ├── utils.py                    # Utility functions (66 lines)
│   ├── storage_r2.py               # Cloudflare R2 integration (13 lines)
│   ├── admin.py                    # Django admin configuration
│   ├── apps.py                     # App configuration
│   ├── tests.py                    # Unit tests
│   ├── routing.py                  # WebSocket routing
│   └── management/                 # Custom management commands
├── StudyCon/                       # Django project settings
│   ├── settings.py                 # Main settings (165 lines)
│   ├── settings_production.py      # Production configuration
│   ├── urls.py                     # Root URL configuration (93 lines)
│   ├── asgi.py                     # ASGI configuration
│   └── wsgi.py                     # WSGI configuration
└── backend_deployment/             # Production deployment files
```

### Core Models Analysis

#### 1. UserImage Model (Lines 27-113)
```python
class UserImage(models.Model):
    """Professional model for storing user profile images with object storage support"""
    IMAGE_TYPES = [
        ('profile', 'Profile Picture'),
        ('gallery', 'Gallery Image'),
        ('cover', 'Cover Photo'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='images')
    image = models.ImageField(upload_to=user_image_upload_path, max_length=500, storage=None)
    image_type = models.CharField(max_length=20, choices=IMAGE_TYPES, default='gallery')
    is_primary = models.BooleanField(default=False, help_text="Primary profile picture")
    caption = models.CharField(max_length=255, blank=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Object storage metadata
    storage_key = models.CharField(max_length=500, blank=True, null=True)  # S3/R2 key
    public_url = models.URLField(blank=True, null=True)  # CDN URL
    mime_type = models.CharField(max_length=100, blank=True, null=True)
    width = models.PositiveIntegerField(blank=True, null=True)
    height = models.PositiveIntegerField(blank=True, null=True)
    size_bytes = models.PositiveIntegerField(blank=True, null=True)
```

**Key Features:**
- UUID primary key for better security
- Support for multiple image types (profile, gallery, cover)
- Object storage metadata for CDN integration
- Automatic image optimization on save
- Primary image constraint (one per user)

#### 2. UserProfile Model (Lines 115-216)
```python
class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    is_certified = models.BooleanField(default=False, help_text="True if this user can create public events.")
    friends = models.ManyToManyField("self", blank=True, symmetrical=True)
    
    # Basic profile information
    full_name = models.CharField(max_length=255, blank=True)
    university = models.CharField(max_length=255, blank=True)
    degree = models.CharField(max_length=255, blank=True)
    year = models.CharField(max_length=50, blank=True)
    bio = models.TextField(blank=True)
    
    # Legacy field - will be deprecated
    profile_picture = models.TextField(blank=True, help_text="Base64 encoded profile picture (deprecated)")
    
    # New fields for smart matching
    interests = models.JSONField(default=list, blank=True)
    skills = models.JSONField(default=dict, blank=True)
    auto_invite_enabled = models.BooleanField(default=True)
    preferred_radius = models.FloatField(default=10.0)
```

**Key Features:**
- One-to-one relationship with Django User
- Symmetrical friendship system
- JSON fields for flexible data storage
- Smart matching capabilities
- Legacy support for base64 images

#### 3. StudyEvent Model (Lines 294-380)
```python
class StudyEvent(models.Model):
    EVENT_TYPE_CHOICES = [
        ('study', 'Study'),
        ('party', 'Party'),
        ('business', 'Business'),
        ('other', 'Other'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255, db_index=True)
    description = models.TextField(blank=True, null=True)
    host = models.ForeignKey(User, on_delete=models.CASCADE, db_index=True)
    latitude = models.FloatField()
    longitude = models.FloatField()
    time = models.DateTimeField(db_index=True)
    end_time = models.DateTimeField(default=timezone.now, db_index=True)
    is_public = models.BooleanField(default=True, db_index=True)
    
    # Relationships
    invited_friends = models.ManyToManyField(User, related_name='invited_study_events', blank=True)
    attendees = models.ManyToManyField(User, related_name='attending_study_events', blank=True)
    event_type = models.CharField(max_length=20, choices=EVENT_TYPE_CHOICES, default='other', db_index=True)

    # Auto-matching fields
    max_participants = models.IntegerField(default=10)
    auto_matching_enabled = models.BooleanField(default=False, db_index=True)
    interest_tags = models.JSONField(default=list, blank=True)
```

**Key Features:**
- UUID primary key
- Location-based events with coordinates
- Public/private event system
- Auto-matching capabilities
- Comprehensive indexing for performance
- Many-to-many relationships for attendees and invitations

#### 4. Social Learning Models (Lines 517-719)
```python
class UserRating(models.Model):
    """Model to store user ratings and references based on Bandura's social learning theory"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    from_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ratings_given')
    to_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ratings_received')
    event = models.ForeignKey(StudyEvent, on_delete=models.SET_NULL, related_name='event_ratings', null=True, blank=True)
    rating = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    reference = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

class UserTrustLevel(models.Model):
    """Model to define trust levels based on Bandura's social learning theory"""
    level = models.IntegerField(unique=True)
    title = models.CharField(max_length=50)
    required_ratings = models.IntegerField(help_text="Minimum number of ratings needed")
    min_average_rating = models.FloatField(help_text="Minimum average rating needed")

class UserReputationStats(models.Model):
    """Model to store reputation statistics for users"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='reputation_stats')
    total_ratings = models.IntegerField(default=0)
    average_rating = models.FloatField(default=0.0)
    trust_level = models.ForeignKey(UserTrustLevel, on_delete=models.SET_NULL, null=True)
    events_hosted = models.IntegerField(default=0)
    events_attended = models.IntegerField(default=0)
    last_updated = models.DateTimeField(auto_now=True)
```

**Key Features:**
- Implements Bandura's social learning theory
- Trust level progression system
- Event-based rating system
- Automatic reputation calculation
- Push notification integration

### API Endpoints Analysis

#### Authentication Endpoints
```python
@csrf_exempt
def register_user(request):
    """User registration with username/password"""
    # Validates username and password
    # Creates Django User without email requirement
    # Returns success/error response

@csrf_exempt
def login_user(request):
    """User login with username/password"""
    # Authenticates user credentials
    # Returns success/error response

@csrf_exempt
def logout_user(request):
    """User logout"""
    # Simple logout endpoint
```

#### Image Management Endpoints
```python
@csrf_exempt
def upload_user_image(request):
    """Upload user image with multipart form data"""
    # Handles image upload to Cloudflare R2
    # Validates image type and size
    # Creates UserImage model instance
    # Returns image metadata

@api_view(['GET'])
def get_user_images(request, username):
    """Get all images for a user"""
    # Returns JSON array of UserImage objects
    # Includes CDN URLs and metadata

@api_view(['POST'])
def set_primary_image(request, image_id):
    """Set image as primary profile picture"""
    # Updates is_primary flag
    # Ensures only one primary image per user
```

#### Event Management Endpoints
```python
@csrf_exempt
def create_study_event(request):
    """Create new study event with auto-matching"""
    # Creates StudyEvent instance
    # Implements intelligent auto-matching
    # Broadcasts real-time updates
    # Returns event data

@api_view(['GET'])
def get_study_events(request, username):
    """Get events for a user"""
    # Returns user's hosted and attended events
    # Includes event metadata and attendee lists

@csrf_exempt
def rsvp_study_event(request):
    """RSVP to a study event"""
    # Adds user to event attendees
    # Broadcasts real-time updates
    # Handles capacity limits
```

#### Social Features Endpoints
```python
@csrf_exempt
def send_friend_request(request):
    """Send friend request to another user"""
    # Creates FriendRequest instance
    # Validates user existence
    # Prevents duplicate requests

@csrf_exempt
def accept_friend_request(request):
    """Accept friend request"""
    # Establishes mutual friendship
    # Deletes friend request
    # Updates both user profiles

@api_view(['GET'])
def get_friends(request, username):
    """Get user's friends list"""
    # Returns list of friend usernames
    # Handles user not found cases
```

### WebSocket Implementation

#### ChatConsumer (Lines 11-54)
```python
class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.sender = self.scope["url_route"]["kwargs"]["sender"]
        self.receiver = self.scope["url_route"]["kwargs"]["receiver"]
        self.room_name = f"private_chat_{self.sender}_{self.receiver}"
        await self.channel_layer.group_add(self.room_name, self.channel_name)
        await self.accept()

    async def receive(self, text_data):
        data = json.loads(text_data)
        sender = data.get("sender")
        receiver = data.get("receiver")
        message = data.get("message")
        
        if sender and receiver and message:
            await self.channel_layer.group_send(
                self.room_name,
                {
                    "type": "chat_message",
                    "sender": sender,
                    "message": message
                }
            )
```

#### EventsConsumer (Lines 110-173)
```python
class EventsConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.username = self.scope["url_route"]["kwargs"]["username"]
        sanitized_username = sanitize_username(self.username)
        self.user_events_group = f"events_{sanitized_username}"
        await self.channel_layer.group_add(self.user_events_group, self.channel_name)
        await self.accept()

    async def event_update(self, event):
        event_id = event["event_id"]
        await self.send(text_data=json.dumps({
            "type": "update",
            "event_id": str(event_id)
        }))
```

---

## Frontend Implementation Details

### iOS App Structure (SwiftUI)
```
Fibbling_BackUp/Fibbling/
├── ContentView.swift              # Main app view (3654 lines)
├── Models/                        # Data models
│   ├── UserImage.swift           # Image model (104 lines)
│   ├── StudyEvent.swift          # Event model (258 lines)
│   └── MessageModel.swift        # Chat model
├── Managers/                      # Business logic managers
│   ├── ImageManager.swift        # Image loading & caching
│   ├── ImageUploadManager.swift  # Image upload handling
│   ├── ProfessionalImageCache.swift # Multi-tier caching
│   ├── NetworkMonitor.swift      # Network condition monitoring
│   ├── ChatManager.swift         # Real-time messaging (93 lines)
│   └── LocationManager.swift     # GPS services
├── Views/                         # SwiftUI views
│   ├── Components/               # Reusable UI components
│   ├── MapViews/                 # Map-related views
│   └── [Feature Views]           # Feature-specific views
└── Utilities/                     # Helper classes
    ├── ImageRetryManager.swift   # Retry logic
    └── NetworkRetryManager.swift # Network retry
```

### Android App Structure (Jetpack Compose)
```
PinIt_Android/app/src/main/java/com/example/pinit/
├── views/                         # Compose UI screens
│   ├── MainActivity.kt           # Main activity
│   ├── ProfileView.kt            # User profile
│   ├── EventsView.kt             # Events list
│   └── FriendsView.kt            # Friends management
├── models/                        # Data classes
│   ├── Models.kt                 # Core data models
│   └── ApiModels.kt              # API response models
├── utils/                         # Utility functions
│   ├── JsonUtils.kt              # JSON handling
│   └── NetworkUtils.kt           # Network operations
└── components/                    # Reusable UI components
    ├── EventCard.kt              # Event display card
    └── UserCard.kt               # User profile card
```

### Key iOS Components Analysis

#### 1. ContentView (Main App View)
```swift
struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var showSettingsView = false
    @State private var showFriendsView = false
    @State private var showCalendarView = false
    @State private var showNotesView = false
    @State private var showFlashcardsView = false
    @State private var showProfileView = false
    @State private var selectedEvent: StudyEvent? = nil
    @State private var showEventDetailSheet = false
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var calendarManager: CalendarManager
    @StateObject private var localizationManager = LocalizationManager.shared
```

**Key Features:**
- Comprehensive state management
- Environment object integration
- Sheet-based navigation
- Localization support
- Animation states

#### 2. UserImage Model
```swift
struct UserImage: Identifiable, Codable, Hashable {
    let id: String
    let url: String?
    let imageType: ImageType
    let isPrimary: Bool
    let caption: String
    let uploadedAt: String
    
    enum ImageType: String, CaseIterable, Codable {
        case profile = "profile"
        case gallery = "gallery"
        case cover = "cover"
        
        var displayName: String {
            switch self {
            case .profile: return "Profile Picture"
            case .gallery: return "Gallery Image"
            case .cover: return "Cover Photo"
            }
        }
    }
}
```

**Key Features:**
- Codable for JSON serialization
- Hashable for SwiftUI list performance
- Type-safe image categories
- Display name localization

#### 3. StudyEvent Model
```swift
struct StudyEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let coordinate: CLLocationCoordinate2D
    let time: Date
    let endTime: Date
    var description: String?
    var invitedFriends: [String]
    var attendees: [String]
    var isPublic: Bool
    var host: String
    var hostIsCertified: Bool
    var eventType: EventType
    var isAutoMatched: Bool?
    var interestTags: [String]?
    var matchedUsers: [String]?
}
```

**Key Features:**
- CoreLocation integration
- Date handling with ISO8601
- Auto-matching support
- Interest-based tagging
- Comprehensive equality checking

#### 4. ChatManager
```swift
class ChatManager: ObservableObject {
    @Published var chatSessions: [ChatSession] = []
    private let storageKey = "chatMessages"

    func sendMessage(to receiver: String, sender: String, message: String) {
        let chatKey = [sender, receiver].sorted()
        let timestamp = getCurrentDateString()
        
        DispatchQueue.main.async {
            if let index = self.chatSessions.firstIndex(where: { $0.participants == chatKey }) {
                if self.chatSessions[index].messages.isEmpty {
                    self.chatSessions[index].messages.append(ChatMessage(sender: "📅", message: timestamp))
                }
                self.chatSessions[index].messages.append(ChatMessage(sender: sender, message: message))
            } else {
                let newChat = ChatSession(participants: chatKey, messages: [
                    ChatMessage(sender: "📅", message: timestamp),
                    ChatMessage(sender: sender, message: message)
                ])
                self.chatSessions.append(newChat)
            }
            self.saveMessages()
            self.objectWillChange.send()
        }
    }
}
```

**Key Features:**
- ObservableObject for SwiftUI integration
- Persistent storage with UserDefaults
- Sorted chat keys for consistency
- Timestamp management
- Thread-safe operations

---

## Database Schema & Models

### Core Tables

#### Users & Authentication
- `auth_user` - Django's built-in user model
- `myapp_userprofile` - Extended user profile information
- `myapp_userimage` - User profile pictures and gallery images

#### Social Features
- `myapp_friendrequest` - Friend request system
- `myapp_userrating` - User rating and feedback
- `myapp_userreputationstats` - Reputation statistics
- `myapp_usertrustlevel` - Trust level definitions

#### Event System
- `myapp_studyevent` - Study events and meetups
- `myapp_eventinvitation` - Event invitations
- `myapp_declinedinvitation` - Declined invitations
- `myapp_eventcomment` - Event comments
- `myapp_eventlike` - Event likes
- `myapp_eventshare` - Event shares

#### Real-time Communication
- `myapp_message` - Chat messages
- `myapp_chatroom` - Chat rooms
- `myapp_device` - Push notification devices

### Relationships
- User → UserProfile (One-to-One)
- User → UserImage (One-to-Many)
- User → StudyEvent (One-to-Many as host)
- StudyEvent → User (Many-to-Many as attendees)
- User → FriendRequest (One-to-Many as sender/receiver)
- User → UserRating (One-to-Many as rater/rated)

---

## API Endpoints & Contracts

### Authentication Flow
1. **Registration**: `POST /api/register/`
   ```json
   {
     "username": "string",
     "password": "string"
   }
   ```

2. **Login**: `POST /api/login/`
   ```json
   {
     "username": "string",
     "password": "string"
   }
   ```

### Image Management
1. **Upload Image**: `POST /api/upload_user_image/`
   - Multipart form data
   - Fields: username, image, image_type, is_primary, caption

2. **Get User Images**: `GET /api/user_images/{username}/`
   - Returns: Array of UserImage objects

3. **Set Primary Image**: `POST /api/user_image/{image_id}/set_primary/`
   - Sets image as primary profile picture

### Event Management
1. **Create Event**: `POST /api/create_study_event/`
   ```json
   {
     "title": "string",
     "description": "string",
     "location": "string",
     "latitude": 0.0,
     "longitude": 0.0,
     "start_time": "2024-01-01T10:00:00Z",
     "end_time": "2024-01-01T12:00:00Z",
     "max_attendees": 10,
     "interest_tags": ["study", "math"]
   }
   ```

2. **RSVP to Event**: `POST /api/study_event/{event_id}/rsvp/`
   - Adds user to event attendees

### Social Features
1. **Send Friend Request**: `POST /api/friend-requests/send/`
   ```json
   {
     "from": "username1",
     "to": "username2"
   }
   ```

2. **Accept Friend Request**: `POST /api/friend-requests/accept/`
   ```json
   {
     "from": "username1",
     "to": "username2"
   }
   ```

### Real-time Features
- `WebSocket /ws/events/` - Real-time event updates
- `WebSocket /ws/chat/{room_id}/` - Chat room
- `WebSocket /ws/notifications/` - Push notifications

---

## Real-time Communication

### WebSocket Implementation
- **Technology**: Django Channels with Redis
- **Endpoints**:
  - `/ws/events/` - Event updates
  - `/ws/chat/{room_id}/` - Chat rooms
  - `/ws/notifications/` - Push notifications

### Event Broadcasting
```python
def broadcast_event_update(event_id, event_type, usernames):
    """Broadcast an event update to all connected WebSocket clients"""
    channel_layer = get_channel_layer()
    
    if not usernames:
        return
    
    handler_map = {
        'create': 'event_create',
        'update': 'event_update',
        'delete': 'event_delete'
    }
    
    handler = handler_map.get(event_type, 'event_update')
    
    for username in usernames:
        group_name = f"events_{username}"
        async_to_sync(channel_layer.group_send)(
            group_name,
            {
                "type": handler,
                "event_id": str(event_id)
            }
        )
```

### Push Notifications
- **iOS**: APNS (Apple Push Notification Service)
- **Android**: FCM (Firebase Cloud Messaging)
- **Backend**: django-push-notifications

---

## Image Management System

### Cloudflare R2 Integration
```python
class R2Storage(S3Boto3Storage):
    bucket_name = getattr(settings, 'AWS_STORAGE_BUCKET_NAME', 'pinit-images')
    custom_domain = 'pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev'
    file_overwrite = False
    default_acl = 'public-read'
    querystring_auth = False
```

### Image Processing
- **Optimization**: Automatic resizing and compression
- **Formats**: JPEG, PNG, GIF, WebP support
- **Metadata**: Width, height, size, MIME type tracking
- **CDN**: Cloudflare R2 with custom domain

### URL Structure
- **Upload Path**: `users/{username}/images/{filename}`
- **Public URL**: `https://pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev/`
- **Cache Busting**: Timestamp-based query parameters

---

## Authentication & Security

### Current Implementation
- **Method**: Username/Password authentication
- **Session Management**: Django sessions
- **CSRF Protection**: Disabled for API endpoints (development)
- **CORS**: Configured for frontend domains

### Security Considerations
- Password hashing via Django's built-in system
- Input validation on all endpoints
- SQL injection protection via Django ORM
- XSS protection via template escaping

### Recommended Improvements
- JWT token authentication
- Rate limiting on API endpoints
- Input sanitization
- HTTPS enforcement
- API versioning

---

## File Storage & CDN

### Cloudflare R2 Configuration
```python
# Production settings
AWS_ACCESS_KEY_ID = '7a4467aff561cea6f89a877a6ad9fc58'
AWS_SECRET_ACCESS_KEY = '5e6345fc231451d46694d10e90e8e1d85d9110a27f0860019a47b4eb005705b8'
AWS_STORAGE_BUCKET_NAME = 'pinit-images'
AWS_S3_ENDPOINT_URL = 'https://da76c95301856b7cd9fee0a8f758097a.r2.cloudflarestorage.com'
AWS_S3_REGION_NAME = 'auto'
AWS_S3_SIGNATURE_VERSION = 's3v4'
AWS_DEFAULT_ACL = 'public-read'
AWS_S3_CUSTOM_DOMAIN = 'pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev'
```

### Storage Features
- **Global CDN**: Cloudflare R2 with worldwide distribution
- **Custom Domain**: `pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev`
- **Public Access**: No authentication required for image access
- **Cache Control**: 24-hour cache headers
- **File Overwrite**: Disabled to prevent accidental overwrites

---

## Deployment & Infrastructure

### Production Environment
- **Platform**: Railway
- **Database**: PostgreSQL (Railway managed)
- **Storage**: Cloudflare R2
- **CDN**: Cloudflare
- **Domain**: Custom domain with SSL

### Configuration Files
- `railway.json` - Railway deployment config
- `Procfile` - Process definitions
- `requirements.txt` - Python dependencies
- `runtime.txt` - Python version specification

### Environment Variables
- `DATABASE_URL` - PostgreSQL connection
- `R2_ACCESS_KEY_ID` - Cloudflare R2 access
- `R2_SECRET_ACCESS_KEY` - Cloudflare R2 secret
- `R2_BUCKET_NAME` - R2 bucket name
- `R2_ENDPOINT_URL` - R2 endpoint URL

---

## Performance Optimizations

### Backend Optimizations
- Database query optimization with select_related and prefetch_related
- Image compression and resizing
- Caching strategies with Redis
- Connection pooling
- Database indexing on frequently queried fields

### Frontend Optimizations
- Image caching and prefetching
- Lazy loading for lists
- Network-aware loading
- Memory management
- SwiftUI performance best practices

### CDN Optimizations
- Cloudflare R2 for global distribution
- Image format optimization
- Cache headers configuration
- Compression enabled

---

## Error Handling & Logging

### Backend Error Handling
```python
try:
    # API operation
    result = perform_operation()
    return JsonResponse({"success": True, "data": result})
except User.DoesNotExist:
    return JsonResponse({"success": False, "message": "User not found"}, status=404)
except json.JSONDecodeError:
    return JsonResponse({"success": False, "message": "Invalid JSON format"}, status=400)
except Exception as e:
    return JsonResponse({"success": False, "message": f"Server error: {str(e)}"}, status=500)
```

### Frontend Error Handling
- Network error handling with retry logic
- Image loading error states
- User-friendly error messages
- Graceful degradation for offline scenarios

### Logging
- Django logging configuration
- WebSocket connection logging
- Image upload/download logging
- Error tracking and monitoring

---

This comprehensive documentation covers every aspect of the PinIt app's implementation, from the database schema to the frontend components, providing a complete technical reference for developers and AI systems.
