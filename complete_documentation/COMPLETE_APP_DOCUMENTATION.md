# PinIt App - Complete System Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Backend Architecture](#backend-architecture)
3. [Frontend Architecture](#frontend-architecture)
4. [Database Schema](#database-schema)
5. [API Documentation](#api-documentation)
6. [Authentication & Security](#authentication--security)
7. [Real-time Features](#real-time-features)
8. [File Storage & CDN](#file-storage--cdn)
9. [Deployment & Infrastructure](#deployment--infrastructure)
10. [Testing & Quality Assurance](#testing--quality-assurance)

---

## System Overview

PinIt is a comprehensive social study platform that connects students for collaborative learning, event organization, and academic networking. The app supports multiple platforms (iOS, Android, Web) with a Django REST API backend and Cloudflare R2 storage.

### Core Features
- **User Management**: Registration, authentication, profile management
- **Social Features**: Friend requests, messaging, user discovery
- **Event System**: Study events, RSVPs, real-time updates
- **Image Management**: Profile pictures, galleries, CDN integration
- **Real-time Communication**: WebSocket-based chat and notifications
- **Location Services**: GPS-based event discovery
- **Auto-matching**: AI-powered study partner suggestions

### Technology Stack
- **Backend**: Django 4.2, Django REST Framework, PostgreSQL
- **Frontend**: SwiftUI (iOS), Jetpack Compose (Android)
- **Storage**: Cloudflare R2, PostgreSQL
- **Real-time**: Django Channels, WebSockets
- **Deployment**: Railway, Cloudflare
- **CDN**: Cloudflare R2 with custom domain

---

## Backend Architecture

### Project Structure
```
PinItApp/
├── myapp/                    # Main Django app
│   ├── models.py            # Database models
│   ├── views.py             # API endpoints
│   ├── urls.py              # URL routing
│   ├── consumers.py         # WebSocket handlers
│   ├── utils.py             # Utility functions
│   └── storage_r2.py        # Cloudflare R2 integration
├── StudyCon/                # Django project settings
│   ├── settings.py          # Main settings
│   ├── settings_production.py # Production config
│   └── urls.py              # Root URL config
└── backend_deployment/      # Production deployment
```

### Core Models

#### UserImage Model
```python
class UserImage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    image = models.ImageField(upload_to=user_image_upload_path)
    image_type = models.CharField(choices=IMAGE_TYPES)  # profile, gallery, cover
    is_primary = models.BooleanField(default=False)
    caption = models.CharField(max_length=255, blank=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    
    # Object storage metadata
    storage_key = models.CharField(max_length=500, blank=True)
    public_url = models.URLField(blank=True)
    mime_type = models.CharField(max_length=100, blank=True)
    width = models.PositiveIntegerField(blank=True)
    height = models.PositiveIntegerField(blank=True)
    size_bytes = models.PositiveIntegerField(blank=True)
```

#### StudyEvent Model
```python
class StudyEvent(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    title = models.CharField(max_length=200)
    description = models.TextField()
    host = models.ForeignKey(User, on_delete=models.CASCADE)
    location = models.CharField(max_length=200)
    latitude = models.FloatField()
    longitude = models.FloatField()
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    max_attendees = models.PositiveIntegerField(default=10)
    attendees = models.ManyToManyField(User, related_name='attended_events')
    interest_tags = models.JSONField(default=list)
    is_auto_matched = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
```

#### UserProfile Model
```python
class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    full_name = models.CharField(max_length=100, blank=True)
    university = models.CharField(max_length=100, blank=True)
    degree = models.CharField(max_length=100, blank=True)
    year = models.CharField(max_length=20, blank=True)
    bio = models.TextField(blank=True)
    skills = models.JSONField(default=dict)
    interests = models.JSONField(default=list)
    location = models.CharField(max_length=100, blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    profile_picture = models.TextField(blank=True)  # Legacy base64
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
```

### API Endpoints

#### Authentication Endpoints
- `POST /api/register/` - User registration
- `POST /api/login/` - User login
- `POST /api/logout/` - User logout

#### User Management
- `GET /api/user_profile/{username}/` - Get user profile
- `PUT /api/user_profile/{username}/` - Update user profile
- `GET /api/user_images/{username}/` - Get user images
- `POST /api/upload_user_image/` - Upload user image
- `DELETE /api/user_image/{image_id}/delete/` - Delete image
- `POST /api/user_image/{image_id}/set_primary/` - Set primary image

#### Social Features
- `POST /api/friend-requests/send/` - Send friend request
- `POST /api/friend-requests/accept/` - Accept friend request
- `POST /api/friend-requests/decline/` - Decline friend request
- `GET /api/get_friends/{username}/` - Get user's friends
- `GET /api/get_pending_requests/{username}/` - Get pending requests
- `GET /api/get_all_users/` - Get all users

#### Event Management
- `GET /api/study_events/{username}/` - Get user's events
- `POST /api/create_study_event/` - Create new event
- `PUT /api/study_event/{event_id}/` - Update event
- `DELETE /api/study_event/{event_id}/` - Delete event
- `POST /api/study_event/{event_id}/rsvp/` - RSVP to event
- `POST /api/study_event/{event_id}/unrsvp/` - Cancel RSVP

#### Real-time Features
- `WebSocket /ws/events/` - Real-time event updates
- `WebSocket /ws/chat/{room_id}/` - Chat room
- `WebSocket /ws/notifications/` - Push notifications

---

## Frontend Architecture

### iOS App (SwiftUI)

#### Project Structure
```
Fibbling_BackUp/Fibbling/
├── Managers/                 # Business logic managers
│   ├── ImageManager.swift   # Image loading & caching
│   ├── ImageUploadManager.swift # Image upload handling
│   ├── ProfessionalImageCache.swift # Multi-tier caching
│   ├── NetworkMonitor.swift # Network condition monitoring
│   ├── ChatManager.swift    # Real-time messaging
│   └── LocationManager.swift # GPS services
├── Views/                   # SwiftUI views
│   ├── ContentView.swift    # Main app view
│   ├── Components/          # Reusable UI components
│   ├── MapViews/           # Map-related views
│   └── [Feature Views]     # Feature-specific views
├── Models/                  # Data models
│   ├── UserImage.swift     # Image model
│   ├── StudyEvent.swift    # Event model
│   └── MessageModel.swift  # Chat model
└── Utilities/              # Helper classes
    ├── ImageRetryManager.swift # Retry logic
    └── NetworkRetryManager.swift # Network retry
```

#### Key Components

##### ImageManager (Singleton)
- **Purpose**: Central coordinator for all image operations
- **Features**: Account-based caching, prefetch queue, optimized URLSession
- **Cache Strategy**: 4-tier caching (memory, disk, URLSession, user-specific)

##### ProfessionalImageCache
- **Purpose**: Multi-tier image caching system
- **Tiers**: Thumbnail (200x200), Full resolution, Blur hash
- **Features**: LRU eviction, disk persistence, thread-safe operations

##### ProfessionalCachedImageView
- **Purpose**: Advanced image view with progressive loading
- **States**: Blur hash → Thumbnail → Full resolution
- **Features**: Network-aware quality, retry logic, smooth transitions

### Android App (Jetpack Compose)

#### Project Structure
```
PinIt_Android/app/src/main/java/com/example/pinit/
├── views/                   # Compose UI screens
│   ├── MainActivity.kt     # Main activity
│   ├── ProfileView.kt      # User profile
│   ├── EventsView.kt       # Events list
│   └── FriendsView.kt      # Friends management
├── models/                 # Data classes
│   ├── Models.kt          # Core data models
│   └── ApiModels.kt       # API response models
├── utils/                 # Utility functions
│   ├── JsonUtils.kt       # JSON handling
│   └── NetworkUtils.kt    # Network operations
└── components/            # Reusable UI components
    ├── EventCard.kt       # Event display card
    └── UserCard.kt        # User profile card
```

---

## Database Schema

### Core Tables

#### Users & Authentication
- `auth_user` - Django's built-in user model
- `myapp_userprofile` - Extended user profile information
- `myapp_userimage` - User profile pictures and gallery images

#### Social Features
- `myapp_friendrequest` - Friend request system
- `myapp_userrating` - User rating and feedback
- `myapp_userreputationstats` - Reputation statistics
- `myapp_usertrustlevel` - Trust level calculations

#### Event System
- `myapp_studyevent` - Study events and meetups
- `myapp_eventinvitation` - Event invitations
- `myapp_declinedinvitation` - Declined invitations

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

---

## API Documentation

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

## Real-time Features

### WebSocket Implementation
- **Technology**: Django Channels with Redis
- **Endpoints**:
  - `/ws/events/` - Event updates
  - `/ws/chat/{room_id}/` - Chat rooms
  - `/ws/notifications/` - Push notifications

### Event Broadcasting
- Event creation/updates
- RSVP changes
- Friend request notifications
- Chat messages

### Push Notifications
- **iOS**: APNS (Apple Push Notification Service)
- **Android**: FCM (Firebase Cloud Messaging)
- **Backend**: django-push-notifications

---

## File Storage & CDN

### Cloudflare R2 Integration
- **Storage**: Cloudflare R2 object storage
- **CDN**: Custom domain with Cloudflare CDN
- **Configuration**: `storage_r2.py` with custom storage backend

### Image Processing
- **Optimization**: Automatic resizing and compression
- **Formats**: JPEG, PNG, GIF, WebP support
- **Metadata**: Width, height, size, MIME type tracking

### URL Structure
- **Upload Path**: `users/{username}/images/{filename}`
- **Public URL**: `https://pub-3df36a2ba44f4af9a779dc24cb9097a8.r2.dev/`
- **Cache Busting**: Timestamp-based query parameters

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

## Testing & Quality Assurance

### Current Testing
- **Backend**: Django test framework
- **Frontend**: Manual testing
- **API**: Postman collections

### Test Coverage Areas
- User registration/login
- Image upload/retrieval
- Event creation/management
- Friend request system
- Real-time messaging

### Recommended Improvements
- Unit tests for all models
- Integration tests for API endpoints
- Frontend automated testing
- Performance testing
- Security testing

---

## Performance Optimizations

### Backend Optimizations
- Database query optimization
- Image compression and resizing
- Caching strategies
- Connection pooling

### Frontend Optimizations
- Image caching and prefetching
- Lazy loading for lists
- Network-aware loading
- Memory management

### CDN Optimizations
- Cloudflare R2 for global distribution
- Image format optimization
- Cache headers configuration
- Compression enabled

---

## Monitoring & Analytics

### Current Monitoring
- Railway platform metrics
- Cloudflare analytics
- Django logging

### Recommended Additions
- Application performance monitoring (APM)
- Error tracking (Sentry)
- User analytics
- Performance metrics

---

## Future Enhancements

### Planned Features
- Video call integration
- Advanced matching algorithms
- Mobile app store deployment
- Web application
- Admin dashboard

### Technical Improvements
- Microservices architecture
- GraphQL API
- Advanced caching (Redis)
- Machine learning integration
- Real-time analytics

---

This documentation provides a comprehensive overview of the PinIt app's architecture, implementation, and deployment. Each section can be expanded with more detailed technical specifications as needed.
