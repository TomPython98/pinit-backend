# PinIt App - Comprehensive Technical Documentation

**Version:** Current Production  
**Last Updated:** January 2025  
**Target Audience:** Developers, DevOps Engineers, Technical Contributors

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Backend Documentation](#backend-documentation)
3. [iOS Frontend Documentation](#ios-frontend-documentation)
4. [Deployment & Operations](#deployment--operations)
5. [API Reference](#api-reference)
6. [WebSocket Real-Time System](#websocket-real-time-system)
7. [Testing & Development](#testing--development)
8. [Troubleshooting](#troubleshooting)
9. [Change Log](#change-log)
10. [Glossary](#glossary)

---

## Architecture Overview

PinIt is a real-time event discovery and social networking app built with Django REST Framework backend and SwiftUI iOS frontend. The system uses WebSockets for real-time updates and PostgreSQL for data persistence.

### System Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   iOS App       │    │   Django API    │    │   PostgreSQL   │
│   (SwiftUI)     │◄──►│   (DRF + WS)    │◄──►│   Database     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   WebSocket     │    │   Redis        │    │   Cloudflare    │
│   Real-time     │    │   Channels     │    │   R2 Storage    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Data Flow

1. **User Authentication**: JWT tokens for API access
2. **Event Management**: CRUD operations with real-time WebSocket updates
3. **Social Features**: Friends, friend requests, user ratings
4. **Real-time Updates**: WebSocket broadcasts for event changes
5. **File Storage**: Cloudflare R2 for images and media

---

## Backend Documentation

### Project Structure

```
StudyCon/                 # Django project root
├── settings.py           # Main configuration
├── urls.py              # Root URL routing
├── asgi.py              # ASGI configuration for WebSockets
└── wsgi.py              # WSGI configuration

myapp/                   # Main Django app
├── models.py            # Database models
├── views.py             # API endpoints
├── urls.py              # App URL routing
├── consumers.py          # WebSocket consumers
├── routing.py           # WebSocket routing
├── storage.py           # Cloudflare R2 storage
├── storage_r2.py        # R2 configuration
├── utils.py             # Utility functions
├── admin.py             # Django admin
├── migrations/          # Database migrations
└── management/commands/  # Custom Django commands
```

### Environment Configuration

**Production Environment Variables:**
```bash
DATABASE_URL=postgresql://user:pass@host:port/dbname
RAILWAY_RUN_COMMAND=python manage.py migrate --noinput && daphne -b 0.0.0.0 -p $PORT StudyCon.asgi:application
SECRET_KEY=your-secret-key
DEBUG=False
ALLOWED_HOSTS=pinit-backend-production.up.railway.app,healthcheck.railway.app
CSRF_TRUSTED_ORIGINS=https://pinit-backend-production.up.railway.app,https://healthcheck.railway.app
```

### Database Configuration

**PostgreSQL (Production):**
- Uses `dj-database-url` for connection parsing
- Connection pooling with `conn_max_age=600`
- Health checks enabled
- Atomic requests enabled

**SQLite (Development):**
- Fallback for local development
- File: `db.sqlite3`

### Authentication & Security

**JWT Authentication:**
- Uses `djangorestframework-simplejwt`
- Access tokens (15 min expiry)
- Refresh tokens (7 days expiry)
- Automatic token refresh in iOS app

**Rate Limiting:**
- `django-ratelimit` implementation
- Per-user and per-IP limits
- Different limits per endpoint type

**CORS & CSRF:**
- `django-cors-headers` for API access
- CSRF protection for web endpoints
- Trusted origins configured

### Models & Relationships

**Core Models:**

```python
# User (Django built-in)
User: username, password, email, date_joined

# UserProfile
UserProfile:
  - user: OneToOneField(User)
  - is_certified: BooleanField
  - friends: ManyToManyField("self")
  - full_name: CharField
  - university: CharField
  - degree: CharField
  - year: CharField
  - bio: TextField
  - profile_picture: TextField (legacy base64, deprecated)
  - interests: JSONField
  - skills: JSONField
  - auto_invite_enabled: BooleanField
  - preferred_radius: FloatField
  # Methods: get_interests(), set_interests(), get_skills(), set_skills()
  # Methods: get_primary_image(), get_profile_images(), get_gallery_images()
  # Methods: get_profile_picture_url(), get_matching_score()

# UserImage (Professional Image Management)
UserImage:
  - id: UUID (primary key)
  - user: ForeignKey(User, CASCADE)
  - image: ImageField (upload_to=user_image_upload_path)
  - image_type: CharField (profile/gallery/cover)
  - is_primary: BooleanField
  - caption: CharField
  - uploaded_at: DateTimeField
  - updated_at: DateTimeField
  - storage_key: CharField (R2/S3 key)
  - public_url: URLField (CDN URL)
  - mime_type: CharField
  - width/height: PositiveIntegerField
  - size_bytes: PositiveIntegerField
  # Methods: url (property), optimize_image(), delete(), get_image_url()

# UserInterest (Structured Interest Storage)
UserInterest:
  - user_profile: ForeignKey(UserProfile, CASCADE)
  - interest: CharField
  - unique_together: ('user_profile', 'interest')

# UserSkill (Structured Skill Storage)
UserSkill:
  - user_profile: ForeignKey(UserProfile, CASCADE)
  - skill: CharField
  - level: CharField (BEGINNER/INTERMEDIATE/ADVANCED/EXPERT)
  - unique_together: ('user_profile', 'skill')

# FriendRequest
FriendRequest:
  - from_user: ForeignKey(User, CASCADE)
  - to_user: ForeignKey(User, CASCADE)
  - timestamp: DateTimeField
  # Methods: accept() - creates mutual friendship and deletes request

# ChatMessage
ChatMessage:
  - sender: ForeignKey(User, CASCADE)
  - receiver: ForeignKey(User, CASCADE)
  - message: TextField
  - timestamp: DateTimeField

# StudyEvent
StudyEvent:
  - id: UUID (primary key)
  - host: ForeignKey(User, CASCADE, db_index=True)
  - title: CharField (db_index=True)
  - description: TextField
  - latitude: FloatField
  - longitude: FloatField
  - time: DateTimeField (db_index=True)
  - end_time: DateTimeField (db_index=True)
  - event_type: CharField (study/party/business/other, db_index=True)
  - attendees: ManyToManyField(User, related_name='attending_study_events')
  - invited_friends: ManyToManyField(User, related_name='invited_study_events')
  - is_public: BooleanField (db_index=True)
  - max_participants: IntegerField
  - auto_matching_enabled: BooleanField (db_index=True)
  - interest_tags: JSONField
  # Properties: coordinate_lat, coordinate_lon
  # Methods: get_interest_tags(), set_interest_tags()
  # Methods: get_all_invitees(), get_auto_matched_invitees(), get_direct_invitees()
  # Methods: invite_user(user, is_auto_matched=False)
  # Indexes: Composite indexes for common query patterns

# EventInvitation (Auto-matching Tracking)
EventInvitation:
  - event: ForeignKey(StudyEvent, CASCADE, related_name='invitation_records')
  - user: ForeignKey(User, CASCADE, related_name='received_invitations')
  - is_auto_matched: BooleanField
  - created_at: DateTimeField
  - unique_together: ('event', 'user')

# EventComment (Social Interactions)
EventComment:
  - event: ForeignKey(StudyEvent, CASCADE, related_name='comments')
  - user: ForeignKey(User, CASCADE, related_name='event_comments')
  - text: TextField
  - created_at: DateTimeField
  - parent: ForeignKey('self', CASCADE, null=True, related_name='replies')

# EventLike (Social Interactions)
EventLike:
  - event: ForeignKey(StudyEvent, CASCADE, related_name='likes')
  - user: ForeignKey(User, CASCADE, related_name='event_likes')
  - comment: ForeignKey(EventComment, CASCADE, null=True, related_name='likes')
  - created_at: DateTimeField
  - unique_together: ('event', 'user', 'comment')

# EventShare (Social Interactions)
EventShare:
  - event: ForeignKey(StudyEvent, CASCADE, related_name='shares')
  - user: ForeignKey(User, CASCADE, related_name='event_shares')
  - shared_platform: CharField (whatsapp/facebook/twitter/instagram/other)
  - created_at: DateTimeField

# EventImage (Event Post Images)
EventImage:
  - comment: ForeignKey(EventComment, CASCADE, related_name='images')
  - image_url: URLField
  - upload_date: DateTimeField

# DeclinedInvitation
DeclinedInvitation:
  - user: ForeignKey(User, CASCADE, related_name='declined_invitations')
  - event: ForeignKey(StudyEvent, CASCADE, related_name='declined_by')
  - declined_at: DateTimeField
  - unique_together: ('user', 'event')

# Device (Push Notifications)
Device:
  - user: ForeignKey(User, CASCADE, related_name='devices')
  - token: CharField (unique=True)
  - device_type: CharField (ios/android)
  - created_at: DateTimeField
  - updated_at: DateTimeField
  - is_active: BooleanField
  - unique_together: ('user', 'token')

# UserRating (Bandura's Social Learning Theory)
UserRating:
  - id: UUID (primary key)
  - from_user: ForeignKey(User, CASCADE, related_name='ratings_given')
  - to_user: ForeignKey(User, CASCADE, related_name='ratings_received')
  - event: ForeignKey(StudyEvent, SET_NULL, null=True, related_name='event_ratings')
  - rating: IntegerField (1-5, with validators)
  - reference: TextField
  - created_at: DateTimeField
  - unique_together: ('from_user', 'to_user', 'event')
  # Methods: update_user_stats(), send_rating_notification()

# UserTrustLevel (Trust System)
UserTrustLevel:
  - level: IntegerField (unique=True)
  - title: CharField
  - required_ratings: IntegerField
  - min_average_rating: FloatField
  # Default levels: Newcomer, Participant, Trusted Member, Event Expert, Community Leader

# UserReputationStats (Reputation System)
UserReputationStats:
  - user: OneToOneField(User, CASCADE, related_name='reputation_stats')
  - total_ratings: IntegerField
  - average_rating: FloatField
  - trust_level: ForeignKey(UserTrustLevel, SET_NULL, null=True, related_name='users_at_level')
  - events_hosted: IntegerField
  - events_attended: IntegerField
  - last_updated: DateTimeField
  # Methods: update_trust_level(), update_event_counts(), send_level_up_notification()

# EventReviewReminder (Review System)
EventReviewReminder:
  - id: UUID (primary key)
  - event: ForeignKey(StudyEvent, CASCADE, related_name='review_reminders')
  - user: ForeignKey(User, CASCADE, related_name='received_review_reminders')
  - sent_at: DateTimeField
  - unique_together: ('event', 'user')
```

**Model Relationships & Signals:**

```python
# Auto-creation signals
@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.create(user=instance)

@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    instance.userprofile.save()

# Default trust levels creation
@receiver(post_migrate)
def create_default_trust_levels(sender, **kwargs):
    if sender.name == 'myapp':
        if UserTrustLevel.objects.count() == 0:
            # Creates 5 default trust levels
```
  - total_ratings: IntegerField
  - average_rating: FloatField
  - trust_level: ForeignKey(UserTrustLevel)

# UserTrustLevel
UserTrustLevel:
  - level: IntegerField
  - title: CharField
  - required_ratings: IntegerField
  - min_average_rating: FloatField

# FriendRequest
FriendRequest:
  - from_user: ForeignKey(User, CASCADE)
  - to_user: ForeignKey(User, CASCADE)
  - created_at: DateTimeField

# ChatMessage
ChatMessage:
  - sender: ForeignKey(User, CASCADE)
  - receiver: ForeignKey(User, CASCADE)
  - message: TextField
  - timestamp: DateTimeField

# Device (Push Notifications)
Device:
  - user: ForeignKey(User, CASCADE)
  - device_token: CharField
  - platform: CharField
  - created_at: DateTimeField
```

**Key Relationships:**
- Events have one host (User)
- Events can have many attendees (Users)
- Events can invite many friends (Users)
- Review reminders cascade delete with events/users

### Complete API Documentation with Data Types

#### Authentication Endpoints

**POST /api/register/**
- **Description**: User registration with JWT token generation
- **Request Body**:
  ```json
  {
    "username": "string (required, unique)",
    "password": "string (required, min 8 chars)"
  }
  ```
- **Response** (201 Created):
  ```json
  {
    "success": "boolean",
    "message": "string",
    "access_token": "string (JWT)",
    "refresh_token": "string (JWT)",
    "username": "string"
  }
  ```
- **Error Responses**:
  - 400: `{"success": false, "message": "Username already exists"}`
  - 400: `{"success": false, "message": "Username and Password required"}`

**POST /api/login/**
- **Description**: User authentication with JWT tokens
- **Request Body**:
  ```json
  {
    "username": "string (required)",
    "password": "string (required)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string",
    "access_token": "string (JWT)",
    "refresh_token": "string (JWT)",
    "username": "string"
  }
  ```
- **Error Responses**:
  - 401: `{"success": false, "message": "Invalid credentials"}`
  - 429: `{"success": false, "message": "Too many failed attempts"}`

**POST /api/logout/**
- **Description**: User logout with token blacklisting
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**: `{}`
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string"
  }
  ```

#### Event Management Endpoints

**POST /api/create_study_event/**
- **Description**: Create new study event with auto-matching
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "title": "string (required)",
    "description": "string (optional)",
    "latitude": "number (required, decimal)",
    "longitude": "number (required, decimal)",
    "time": "string (required, ISO 8601 datetime)",
    "end_time": "string (required, ISO 8601 datetime)",
    "is_public": "boolean (default: true)",
    "event_type": "string (enum: study|social|sports|cultural|academic|other)",
    "max_participants": "integer (default: 10)",
    "auto_matching_enabled": "boolean (default: false)",
    "interest_tags": "array of strings (optional)",
    "invited_friends": "array of strings (optional, usernames)"
  }
  ```
- **Response** (201 Created):
  ```json
  {
    "success": "boolean",
    "event_id": "string (UUID)",
    "auto_matching_results": {
      "enabled": "boolean",
      "invites_sent": "integer",
      "matched_users": [
        {
          "username": "string",
          "score": "number",
          "matching_interests": "array of strings",
          "score_breakdown": "object"
        }
      ]
    }
  }
  ```

**GET /api/get_study_events/{username}/**
- **Description**: Get events visible to user (hosted, public, friends', auto-matched)
- **Headers**: `Authorization: Bearer <access_token>`
- **Path Parameters**:
  - `username`: string (required)
- **Response** (200 OK):
  ```json
  {
    "events": [
      {
        "id": "string (UUID)",
        "title": "string",
        "description": "string",
        "latitude": "number",
        "longitude": "number",
        "time": "string (ISO 8601)",
        "end_time": "string (ISO 8601)",
        "host": "string (username)",
        "hostIsCertified": "boolean",
        "isPublic": "boolean",
        "event_type": "string",
        "invitedFriends": "array of strings",
        "attendees": "array of strings",
        "max_participants": "integer",
        "auto_matching_enabled": "boolean",
        "isAutoMatched": "boolean",
        "matchedUsers": "array of strings",
        "interest_tags": "array of strings"
      }
    ]
  }
  ```

**POST /api/update_study_event/**
- **Description**: Update existing event (host only)
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "event_id": "string (UUID, required)",
    "title": "string (optional)",
    "description": "string (optional)",
    "latitude": "number (optional)",
    "longitude": "number (optional)",
    "time": "string (optional, ISO 8601)",
    "end_time": "string (optional, ISO 8601)",
    "is_public": "boolean (optional)",
    "event_type": "string (optional)",
    "interest_tags": "array of strings (optional)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string",
    "event_id": "string (UUID)"
  }
  ```

**POST /api/delete_study_event/**
- **Description**: Delete event (host only)
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "event_id": "string (UUID, required)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string"
  }
  ```

**POST /api/rsvp_study_event/**
- **Description**: RSVP to event (join/leave)
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "event_id": "string (UUID, required)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "action": "string (joined|left)",
    "event": {
      "id": "string (UUID)",
      "title": "string",
      "event_type": "string"
    }
  }
  ```

#### Social System Endpoints

**POST /api/send_friend_request/**
- **Description**: Send friend request to another user
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "to_user": "string (username, required)"
  }
  ```
- **Response** (201 Created):
  ```json
  {
    "success": "boolean",
    "message": "string"
  }
  ```

**POST /api/accept_friend_request/**
- **Description**: Accept incoming friend request
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "from_user": "string (username, required)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string"
  }
  ```

**GET /api/get_friends/{username}/**
- **Description**: Get user's friends list
- **Headers**: `Authorization: Bearer <access_token>`
- **Path Parameters**:
  - `username`: string (required)
- **Response** (200 OK):
  ```json
  {
    "friends": "array of strings (usernames)"
  }
  ```

**GET /api/get_pending_requests/{username}/**
- **Description**: Get pending friend requests
- **Headers**: `Authorization: Bearer <access_token>`
- **Path Parameters**:
  - `username`: string (required)
- **Response** (200 OK):
  ```json
  {
    "pending_requests": "array of strings (usernames)"
  }
  ```

**GET /api/get_sent_requests/{username}/**
- **Description**: Get sent friend requests
- **Headers**: `Authorization: Bearer <access_token>`
- **Path Parameters**:
  - `username`: string (required)
- **Response** (200 OK):
  ```json
  {
    "sent_requests": "array of strings (usernames)"
  }
  ```

#### User Profile & Management Endpoints

**GET /api/get_user_profile/{username}/**
- **Description**: Get user profile information
- **Path Parameters**:
  - `username`: string (required)
- **Response** (200 OK):
  ```json
  {
    "username": "string",
    "full_name": "string",
    "university": "string",
    "degree": "string",
    "year": "string",
    "bio": "string",
    "profile_picture": "string (URL)",
    "is_certified": "boolean",
    "interests": "array of strings",
    "skills": "object (skill_name: skill_level)",
    "auto_invite_enabled": "boolean",
    "preferred_radius": "number (km)"
  }
  ```

**POST /api/delete_account/**
- **Description**: Permanently delete user account
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**: `{}`
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string",
    "username": "string"
  }
  ```

#### User Rating & Reputation Endpoints

**POST /api/submit_user_rating/**
- **Description**: Submit rating for another user after event
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "event_id": "string (UUID, required)",
    "target_user": "string (username, required)",
    "rating": "integer (required, 1-5)",
    "reference": "string (optional, max 500 chars)"
  }
  ```
- **Response** (201 Created):
  ```json
  {
    "success": "boolean",
    "message": "string",
    "rating_id": "string (UUID)"
  }
  ```

**GET /api/get_user_reputation/{username}/**
- **Description**: Get user's reputation statistics
- **Path Parameters**:
  - `username`: string (required)
- **Response** (200 OK):
  ```json
  {
    "username": "string",
    "average_rating": "number (decimal, 1-5)",
    "total_ratings": "integer",
    "trust_level": {
      "level": "integer (1-5)",
      "name": "string",
      "description": "string"
    },
    "events_hosted": "integer",
    "events_attended": "integer",
    "recent_ratings": [
      {
        "id": "string (UUID)",
        "from_user": "string",
        "rating": "integer",
        "reference": "string",
        "created_at": "string (ISO 8601)"
      }
    ]
  }
  ```

**GET /api/get_user_ratings/{username}/**
- **Description**: Get all ratings for a user
- **Path Parameters**:
  - `username`: string (required)
- **Response** (200 OK):
  ```json
  {
    "ratings": [
      {
        "id": "string (UUID)",
        "from_user": "string",
        "to_user": "string",
        "event_id": "string (UUID)",
        "rating": "integer (1-5)",
        "reference": "string",
        "created_at": "string (ISO 8601)"
      }
    ]
  }
  ```

#### Event Social Interactions Endpoints

**POST /api/events/comment/**
- **Description**: Add comment/post to event
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "event_id": "string (UUID, required)",
    "text": "string (required, max 1000 chars)",
    "parent_id": "integer (optional, for replies)",
    "image_urls": "array of strings (optional, URLs)"
  }
  ```
- **Response** (201 Created):
  ```json
  {
    "success": "boolean",
    "post": {
      "id": "integer",
      "text": "string",
      "username": "string",
      "created_at": "string (ISO 8601)",
      "imageURLs": "array of strings or null",
      "likes": "integer",
      "isLikedByCurrentUser": "boolean",
      "replies": "array of objects"
    }
  }
  ```

**POST /api/events/like/**
- **Description**: Like/unlike event or post
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "event_id": "string (UUID, required)",
    "post_id": "integer (optional, for post likes)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "liked": "boolean",
    "total_likes": "integer"
  }
  ```

**POST /api/events/share/**
- **Description**: Record event share
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "event_id": "string (UUID, required)",
    "platform": "string (enum: whatsapp|facebook|twitter|instagram|other)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "total_shares": "integer"
  }
  ```

**GET /api/events/feed/{event_id}/**
- **Description**: Get event feed (posts, likes, shares)
- **Headers**: `Authorization: Bearer <access_token>`
- **Path Parameters**:
  - `event_id`: string (UUID, required)
- **Response** (200 OK):
  ```json
  {
    "posts": [
      {
        "id": "integer",
        "text": "string",
        "username": "string",
        "created_at": "string (ISO 8601)",
        "imageURLs": "array of strings or null",
        "likes": "integer",
        "isLikedByCurrentUser": "boolean",
        "replies": "array of objects"
      }
    ],
    "likes": {
      "total": "integer",
      "users": "array of strings"
    },
    "shares": {
      "total": "integer",
      "breakdown": "object (platform: count)"
    }
  }
  ```

#### Search & Discovery Endpoints

**GET /api/search_events/**
- **Description**: Basic event search
- **Headers**: `Authorization: Bearer <access_token>`
- **Query Parameters**:
  - `query`: string (optional, search term)
  - `public_only`: boolean (optional, default: false)
  - `certified_only`: boolean (optional, default: false)
- **Response** (200 OK):
  ```json
  {
    "events": [
      {
        "id": "string (UUID)",
        "title": "string",
        "latitude": "number",
        "longitude": "number",
        "time": "string (ISO 8601)",
        "end_time": "string (ISO 8601)",
        "host": "string",
        "isPublic": "boolean"
      }
    ]
  }
  ```

**GET /api/enhanced_search_events/**
- **Description**: Enhanced search with semantic matching
- **Headers**: `Authorization: Bearer <access_token>`
- **Query Parameters**:
  - `query`: string (optional, search term)
  - `public_only`: boolean (optional, default: false)
  - `certified_only`: boolean (optional, default: false)
  - `event_type`: string (optional, enum: study|social|sports|cultural|academic|other)
  - `semantic`: boolean (optional, default: false, enable semantic search)
- **Response** (200 OK):
  ```json
  {
    "events": [
      {
        "id": "string (UUID)",
        "title": "string",
        "description": "string",
        "latitude": "number",
        "longitude": "number",
        "time": "string (ISO 8601)",
        "end_time": "string (ISO 8601)",
        "host": "string",
        "hostIsCertified": "boolean",
        "isPublic": "boolean",
        "event_type": "string",
        "invitedFriends": "array of strings",
        "attendees": "array of strings"
      }
    ]
  }
  ```

#### Auto-Matching Endpoints

**POST /api/advanced_auto_match/**
- **Description**: Advanced auto-matching for events
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "event_id": "string (UUID, required)",
    "max_invites": "integer (optional, default: 10)",
    "min_score": "number (optional, default: 30.0)",
    "potentials_only": "boolean (optional, default: false)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "matched_users": [
      {
        "username": "string",
        "score": "number",
        "matching_interests": "array of strings",
        "score_breakdown": "object",
        "invited": "boolean"
      }
    ],
    "total_invites_sent": "integer",
    "message": "string"
  }
  ```

#### Image Management Endpoints

**POST /api/upload_user_image/**
- **Description**: Upload user image to Cloudflare R2
- **Headers**: `Authorization: Bearer <access_token>`
- **Content-Type**: `multipart/form-data`
- **Form Data**:
  - `image`: file (required, image file)
  - `image_type`: string (required, enum: profile|gallery|cover)
  - `caption`: string (optional, max 200 chars)
- **Response** (201 Created):
  ```json
  {
    "success": "boolean",
    "image_id": "string (UUID)",
    "url": "string (public URL)",
    "message": "string"
  }
  ```

**GET /api/user_images/{username}/**
- **Description**: Get user's images
- **Path Parameters**:
  - `username`: string (required)
- **Response** (200 OK):
  ```json
  {
    "images": [
      {
        "id": "string (UUID)",
        "url": "string",
        "image_type": "string",
        "is_primary": "boolean",
        "caption": "string",
        "uploaded_at": "string (ISO 8601)"
      }
    ]
  }
  ```

#### User Preferences Endpoints

**GET /api/user_preferences/{username}/**
- **Description**: Get user preferences
- **Headers**: `Authorization: Bearer <access_token>`
- **Path Parameters**:
  - `username`: string (required)
- **Response** (200 OK):
  ```json
  {
    "enable_notifications": "boolean",
    "dark_mode": "boolean",
    "show_online_status": "boolean",
    "allow_tagging": "boolean",
    "allow_direct_messages": "boolean",
    "show_activity_status": "boolean"
  }
  ```

**POST /api/update_user_preferences/{username}/**
- **Description**: Update user preferences
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "enable_notifications": "boolean (optional)",
    "dark_mode": "boolean (optional)",
    "show_online_status": "boolean (optional)",
    "allow_tagging": "boolean (optional)",
    "allow_direct_messages": "boolean (optional)",
    "show_activity_status": "boolean (optional)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string"
  }
  ```

#### Moderation & Security Endpoints

**POST /change_password/**
- **Description**: Change user password
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "old_password": "string (required)",
    "new_password": "string (required, min 8 chars)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string"
  }
  ```

**POST /report_content/**
- **Description**: Report inappropriate content
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "content_type": "string (enum: user|event|message, required)",
    "content_id": "string (required)",
    "reason": "string (required, max 500 chars)",
    "description": "string (optional, max 1000 chars)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string",
    "report_id": "string (UUID)"
  }
  ```

**POST /block_user/**
- **Description**: Block another user
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "target_username": "string (required)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string"
  }
  ```

#### Additional User Management Endpoints

**GET /api/get_all_users/**
- **Description**: Get all users (for discovery)
- **Headers**: `Authorization: Bearer <access_token>`
- **Response** (200 OK):
  ```json
  {
    "users": [
      {
        "username": "string",
        "first_name": "string",
        "last_name": "string",
        "email": "string",
        "is_active": "boolean",
        "date_joined": "string (ISO 8601)",
        "last_login": "string (ISO 8601)"
      }
    ]
  }
  ```

**GET /api/get_past_events/{username}/**
- **Description**: Get user's past events
- **Headers**: `Authorization: Bearer <access_token>`
- **Path Parameters**:
  - `username`: string (required)
- **Response** (200 OK):
  ```json
  {
    "past_events": [
      {
        "id": "string (UUID)",
        "title": "string",
        "description": "string",
        "latitude": "number",
        "longitude": "number",
        "time": "string (ISO 8601)",
        "end_time": "string (ISO 8601)",
        "host": "string (username)",
        "event_type": "string",
        "attendees": "array of strings",
        "is_completed": "boolean"
      }
    ]
  }
  ```

**GET /api/get_user_recent_activity/{username}/**
- **Description**: Get user's recent activity
- **Headers**: `Authorization: Bearer <access_token>`
- **Path Parameters**:
  - `username`: string (required)
- **Response** (200 OK):
  ```json
  {
    "recent_activity": [
      {
        "type": "string (event_created|event_joined|event_left|rating_given|rating_received)",
        "event_id": "string (UUID)",
        "event_title": "string",
        "timestamp": "string (ISO 8601)",
        "details": "object"
      }
    ]
  }
  ```

**GET /api/get_trending_events/**
- **Description**: Get trending events across platform
- **Headers**: `Authorization: Bearer <access_token>`
- **Response** (200 OK):
  ```json
  {
    "trending_events": [
      {
        "id": "string (UUID)",
        "title": "string",
        "description": "string",
        "latitude": "number",
        "longitude": "number",
        "time": "string (ISO 8601)",
        "host": "string (username)",
        "event_type": "string",
        "attendee_count": "integer",
        "trend_score": "number",
        "interest_tags": "array of strings"
      }
    ]
  }
  ```

**GET /api/get_recent_activity/{username}/**
- **Description**: Get recent activity feed for user
- **Headers**: `Authorization: Bearer <access_token>`
- **Path Parameters**:
  - `username`: string (required)
- **Response** (200 OK):
  ```json
  {
    "activity_feed": [
      {
        "id": "string (UUID)",
        "type": "string (event|rating|friend_request)",
        "title": "string",
        "description": "string",
        "timestamp": "string (ISO 8601)",
        "actor": "string (username)",
        "target": "string (username)",
        "metadata": "object"
      }
    ]
  }
  ```

#### Invitation Management Endpoints

**POST /api/decline_invitation/**
- **Description**: Decline event invitation
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "event_id": "string (UUID, required)",
    "inviter_username": "string (required)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string"
  }
  ```

**GET /api/get_invitations/{username}/**
- **Description**: Get user's pending invitations
- **Headers**: `Authorization: Bearer <access_token>`
- **Path Parameters**:
  - `username`: string (required)
- **Response** (200 OK):
  ```json
  {
    "invitations": [
      {
        "id": "string (UUID)",
        "event_id": "string (UUID)",
        "event_title": "string",
        "inviter_username": "string",
        "invited_at": "string (ISO 8601)",
        "event_time": "string (ISO 8601)",
        "event_type": "string",
        "status": "string (pending|accepted|declined)"
      }
    ]
  }
  ```

#### User Profile & Certification Endpoints

**POST /api/certify_user/**
- **Description**: Certify a user (admin only)
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "username": "string (required)",
    "certification_type": "string (required)",
    "certification_details": "string (optional)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string",
    "certification": {
      "username": "string",
      "certification_type": "string",
      "certified_at": "string (ISO 8601)",
      "certified_by": "string (admin username)"
    }
  }
  ```

#### Event Social Interactions Endpoints

**GET /api/events/interactions/{event_id}/**
- **Description**: Get event interactions (comments, likes, shares)
- **Headers**: `Authorization: Bearer <access_token>`
- **Path Parameters**:
  - `event_id`: string (UUID, required)
- **Response** (200 OK):
  ```json
  {
    "interactions": {
      "comments": [
        {
          "id": "string (UUID)",
          "user": "string (username)",
          "comment": "string",
          "timestamp": "string (ISO 8601)",
          "likes": "integer"
        }
      ],
      "likes": [
        {
          "user": "string (username)",
          "timestamp": "string (ISO 8601)"
        }
      ],
      "shares": [
        {
          "user": "string (username)",
          "timestamp": "string (ISO 8601)",
          "platform": "string"
        }
      ],
      "total_likes": "integer",
      "total_comments": "integer",
      "total_shares": "integer"
    }
  }
  ```

**GET /api/events/feed/{event_id}/**
- **Description**: Get event feed with all interactions
- **Headers**: `Authorization: Bearer <access_token>`
- **Path Parameters**:
  - `event_id`: string (UUID, required)
- **Response** (200 OK):
  ```json
  {
    "event_feed": {
      "event": {
        "id": "string (UUID)",
        "title": "string",
        "description": "string",
        "host": "string (username)",
        "time": "string (ISO 8601)",
        "event_type": "string"
      },
      "feed_items": [
        {
          "type": "string (comment|like|share|rsvp)",
          "user": "string (username)",
          "content": "string",
          "timestamp": "string (ISO 8601)",
          "metadata": "object"
        }
      ]
    }
  }
  ```

**POST /api/events/upload_image/**
- **Description**: Upload image to event
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**: `multipart/form-data`
  - `event_id`: string (UUID, required)
  - `image`: file (required, image file)
  - `caption`: string (optional)
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "image_url": "string (Cloudflare R2 URL)",
    "image_id": "string (UUID)"
  }
  ```

#### User Interests & Auto-Matching Endpoints

**POST /api/update_user_interests/**
- **Description**: Update user interests
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "interests": "array of strings (required)",
    "skills": "array of strings (optional)",
    "preferred_event_types": "array of strings (optional)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string",
    "updated_interests": "array of strings"
  }
  ```

**GET /api/get_auto_matched_users/{event_id}/**
- **Description**: Get auto-matched users for event
- **Headers**: `Authorization: Bearer <access_token>`
- **Path Parameters**:
  - `event_id`: string (UUID, required)
- **Response** (200 OK):
  ```json
  {
    "auto_matched_users": [
      {
        "username": "string",
        "score": "number",
        "matching_interests": "array of strings",
        "matching_skills": "array of strings",
        "score_breakdown": {
          "interests": "number",
          "location": "number",
          "social": "number",
          "academic": "number",
          "reputation": "number"
        }
      }
    ]
  }
  ```

#### Trust & Reputation Endpoints

**GET /api/get_trust_levels/**
- **Description**: Get all trust levels
- **Headers**: `Authorization: Bearer <access_token>`
- **Response** (200 OK):
  ```json
  {
    "trust_levels": [
      {
        "level": "string (bronze|silver|gold|platinum)",
        "min_rating": "number",
        "min_events": "integer",
        "description": "string",
        "benefits": "array of strings"
      }
    ]
  }
  ```

**POST /api/schedule_rating_reminder/**
- **Description**: Schedule rating reminder for event
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "event_id": "string (UUID, required)",
    "reminder_time": "string (ISO 8601, required)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string",
    "reminder_id": "string (UUID)"
  }
  ```

#### Profile & Preferences Endpoints

**GET /api/profile_completion/{username}/**
- **Description**: Get profile completion status
- **Headers**: `Authorization: Bearer <access_token>`
- **Path Parameters**:
  - `username`: string (required)
- **Response** (200 OK):
  ```json
  {
    "profile_completion": {
      "completion_percentage": "number (0-100)",
      "missing_fields": "array of strings",
      "completed_fields": "array of strings",
      "recommendations": "array of strings"
    }
  }
  ```

**GET /api/matching_preferences/{username}/**
- **Description**: Get user's matching preferences
- **Headers**: `Authorization: Bearer <access_token>`
- **Path Parameters**:
  - `username`: string (required)
- **Response** (200 OK):
  ```json
  {
    "matching_preferences": {
      "allow_auto_matching": "boolean",
      "preferred_radius": "number (km)",
      "age_range": "string (e.g., '18-25')",
      "university_preference": "string",
      "degree_preference": "string",
      "year_preference": "string",
      "preferred_event_types": "array of strings",
      "matching_interests": "array of strings",
      "matching_skills": "array of strings"
    }
  }
  ```

**POST /api/update_matching_preferences/{username}/**
- **Description**: Update user's matching preferences
- **Headers**: `Authorization: Bearer <access_token>`
- **Path Parameters**:
  - `username`: string (required)
- **Request Body**:
  ```json
  {
    "allow_auto_matching": "boolean (optional)",
    "preferred_radius": "number (optional)",
    "age_range": "string (optional)",
    "university_preference": "string (optional)",
    "degree_preference": "string (optional)",
    "year_preference": "string (optional)",
    "preferred_event_types": "array of strings (optional)",
    "matching_interests": "array of strings (optional)",
    "matching_skills": "array of strings (optional)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string",
    "updated_preferences": "object"
  }
  ```

#### Additional Image Management Endpoints

**POST /api/get_multiple_user_images/**
- **Description**: Get images for multiple users
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "usernames": "array of strings (required)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "user_images": {
      "username1": [
        {
          "id": "string (UUID)",
          "url": "string (Cloudflare R2 URL)",
          "image_type": "string",
          "is_primary": "boolean",
          "caption": "string",
          "uploaded_at": "string (ISO 8601)"
        }
      ]
    }
  }
  ```

**POST /api/user_image/{image_id}/delete/**
- **Description**: Delete user image
- **Headers**: `Authorization: Bearer <access_token>`
- **Path Parameters**:
  - `image_id`: string (UUID, required)
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string"
  }
  ```

**POST /api/user_image/{image_id}/set_primary/**
- **Description**: Set image as primary
- **Headers**: `Authorization: Bearer <access_token>`
- **Path Parameters**:
  - `image_id`: string (UUID, required)
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string"
  }
  ```

**POST /api/update-existing-images/**
- **Description**: Update existing images metadata
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "image_updates": [
      {
        "image_id": "string (UUID, required)",
        "caption": "string (optional)",
        "image_type": "string (optional)"
      }
    ]
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string",
    "updated_images": "array of objects"
  }
  ```

#### Additional Moderation Endpoints

**POST /unblock_user/**
- **Description**: Unblock a user
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "username": "string (required)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string"
  }
  ```

#### JWT Token Endpoints

**POST /api/token/**
- **Description**: Obtain JWT access and refresh tokens
- **Request Body**:
  ```json
  {
    "username": "string (required)",
    "password": "string (required)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "access": "string (JWT access token)",
    "refresh": "string (JWT refresh token)"
  }
  ```
- **Error Responses**:
  - 401: `{"detail": "No active account found with the given credentials"}`

**POST /api/token/refresh/**
- **Description**: Refresh JWT access token using refresh token
- **Request Body**:
  ```json
  {
    "refresh": "string (JWT refresh token, required)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "access": "string (new JWT access token)"
  }
  ```
- **Error Responses**:
  - 401: `{"detail": "Token is invalid or expired"}`

#### Event Invitation Endpoints

**POST /invite_to_event/**
- **Description**: Invite user to event
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "event_id": "string (UUID, required)",
    "invited_username": "string (required)",
    "message": "string (optional)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": "boolean",
    "message": "string",
    "invitation_id": "string (UUID)"
  }
  ```

#### Chat Endpoints

**GET /chat/{room_name}/**
- **Description**: Chat room interface (web-based)
- **Path Parameters**:
  - `room_name`: string (required, chat room identifier)
- **Response**: HTML chat interface
- **Note**: This is a web-based chat interface, not an API endpoint

#### System Endpoints

**GET /health/**
- **Description**: Health check endpoint
- **Response** (200 OK):
  ```json
  {
    "status": "string (healthy)",
    "message": "string"
  }
  ```

**POST /api/register-device/**
- **Description**: Register device for push notifications
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "device_token": "string (required)",
    "platform": "string (enum: ios|android, required)"
  }
  ```
- **Response** (201 Created):
  ```json
  {
    "success": "boolean",
    "message": "string",
    "device_id": "string (UUID)"
  }
  ```

### Complete Frontend-Backend API Integration Summary

#### Total API Endpoints Documented: 55+ Endpoints

**JWT Token Management (2 endpoints):**
- POST /api/token/ - Obtain JWT access and refresh tokens
- POST /api/token/refresh/ - Refresh JWT access token

**Authentication & User Management (8 endpoints):**
- POST /api/register/ - User registration with JWT
- POST /api/login/ - User authentication with JWT
- POST /api/logout/ - User logout with token blacklisting
- GET /api/get_all_users/ - Get all users for discovery
- GET /api/get_user_profile/{username}/ - Get user profile
- POST /api/delete_account/ - Delete user account
- POST /change_password/ - Change user password
- POST /api/certify_user/ - Certify user (admin)

**Event Management (8 endpoints):**
- POST /api/create_study_event/ - Create new event with auto-matching
- GET /api/get_study_events/{username}/ - Get user's events
- GET /api/get_past_events/{username}/ - Get user's past events
- POST /api/update_study_event/ - Update existing event
- POST /api/delete_study_event/ - Delete event
- POST /api/rsvp_study_event/ - RSVP to event
- GET /api/get_trending_events/ - Get trending events
- GET /api/get_user_recent_activity/{username}/ - Get user activity

**Friend Management (5 endpoints):**
- POST /api/send_friend_request/ - Send friend request
- POST /api/accept_friend_request/ - Accept friend request
- GET /api/get_friends/{username}/ - Get user's friends
- GET /api/get_pending_requests/{username}/ - Get pending requests
- GET /api/get_sent_requests/{username}/ - Get sent requests

**Event Social Interactions (5 endpoints):**
- POST /api/events/comment/ - Add event comment
- POST /api/events/like/ - Toggle event like
- POST /api/events/share/ - Record event share
- GET /api/events/interactions/{event_id}/ - Get event interactions
- GET /api/events/feed/{event_id}/ - Get event feed
- POST /api/events/upload_image/ - Upload event image

**Search & Discovery (3 endpoints):**
- GET /api/search_events/ - Basic event search
- GET /api/enhanced_search_events/ - Semantic event search
- GET /api/get_recent_activity/{username}/ - Get activity feed

**Auto-Matching & Interests (3 endpoints):**
- POST /api/advanced_auto_match/ - Advanced auto-matching
- POST /api/update_user_interests/ - Update user interests
- GET /api/get_auto_matched_users/{event_id}/ - Get auto-matched users

**User Ratings & Reputation (4 endpoints):**
- POST /api/submit_user_rating/ - Submit user rating
- GET /api/get_user_reputation/{username}/ - Get user reputation
- GET /api/get_user_ratings/{username}/ - Get user ratings
- GET /api/get_trust_levels/ - Get trust levels
- POST /api/schedule_rating_reminder/ - Schedule rating reminder

**Image Management (6 endpoints):**
- POST /api/upload_user_image/ - Upload user image
- GET /api/user_images/{username}/ - Get user images
- POST /api/get_multiple_user_images/ - Get multiple user images
- POST /api/user_image/{image_id}/delete/ - Delete user image
- POST /api/user_image/{image_id}/set_primary/ - Set primary image
- POST /api/update-existing-images/ - Update image metadata

**User Preferences (4 endpoints):**
- GET /api/user_preferences/{username}/ - Get user preferences
- POST /api/update_user_preferences/{username}/ - Update user preferences
- GET /api/matching_preferences/{username}/ - Get matching preferences
- POST /api/update_matching_preferences/{username}/ - Update matching preferences

**Invitation Management (3 endpoints):**
- POST /api/decline_invitation/ - Decline event invitation
- GET /api/get_invitations/{username}/ - Get user invitations
- POST /invite_to_event/ - Invite user to event

**Moderation & Security (3 endpoints):**
- POST /report_content/ - Report inappropriate content
- POST /block_user/ - Block user
- POST /unblock_user/ - Unblock user

**System & Device Management (3 endpoints):**
- GET /health/ - System health check
- POST /api/register-device/ - Register device for notifications
- GET /chat/{room_name}/ - Chat room interface (web-based)

#### Complete Data Type Specifications

**All API endpoints include:**
- **Exact Request Body Structure** with field types and validation rules
- **Complete Response Format** with all possible fields and data types
- **HTTP Status Codes** for success and error cases
- **Authentication Requirements** (JWT Bearer tokens)
- **Path Parameters** with exact types and requirements
- **Query Parameters** where applicable
- **Error Response Formats** with detailed error descriptions
- **Rate Limiting Information** for security-sensitive endpoints

**Data Types Covered:**
- **Strings**: Usernames, descriptions, messages, URLs
- **Integers**: IDs, counts, ratings, limits
- **Numbers**: Coordinates, scores, percentages
- **Booleans**: Flags, status indicators
- **Arrays**: Lists of strings, objects, usernames
- **Objects**: Complex nested data structures
- **UUIDs**: Unique identifiers for events, users, images
- **ISO 8601 Dates**: Timestamps for all time-based fields
- **Enums**: Event types, user roles, status values
- **File Uploads**: Image files with multipart/form-data

**Frontend Integration Patterns:**
- **iOS Swift**: Complete integration with UserAccountManager, CalendarManager, ImageManager
- **Android Kotlin**: Complete integration with ApiService, UserAccountManager
- **JWT Authentication**: Automatic token management and refresh
- **Error Handling**: Comprehensive error response handling
- **Data Validation**: Client-side and server-side validation
- **Real-time Updates**: WebSocket integration for live data
- **Image Handling**: Multi-tier caching and Cloudflare R2 integration
- **Offline Support**: Pending actions queue and data persistence

#### Complete API Coverage Verification

✅ **All Backend URLs Documented**: Every endpoint from `StudyCon/urls.py` and `myapp/urls.py` is documented
✅ **All Data Fields Specified**: Every request/response field has exact type and validation rules
✅ **All Frontend Interactions**: Complete iOS and Android integration patterns documented
✅ **All Error Cases Covered**: Comprehensive error response documentation
✅ **All Authentication Patterns**: JWT security implementation for all protected endpoints
✅ **All Data Types Defined**: Exact specifications for strings, numbers, arrays, objects, UUIDs, dates
✅ **All Validation Rules**: Field requirements, length limits, format specifications
✅ **All Integration Points**: Complete frontend-backend interaction patterns

#### Frontend-Backend Data Flow Documentation

**Complete Data Flow Patterns:**
1. **Authentication Flow**: Login → JWT Generation → Token Storage → API Requests → Token Refresh → Logout
2. **Event Management Flow**: Event Creation → Auto-Matching → RSVP → Updates → WebSocket Broadcasting
3. **Image Management Flow**: Image Upload → Cloudflare R2 → Caching → Display → Metadata Updates
4. **Social Interaction Flow**: Comments/Likes/Shares → Real-time Updates → Feed Generation
5. **Search Flow**: Query Input → Semantic Processing → Results → Caching → Display
6. **Rating Flow**: Event Completion → Rating Reminder → Rating Submission → Reputation Update

**Complete Integration Coverage:**
- **55+ API Endpoints** with exact data specifications
- **All Frontend Components** with backend integration patterns
- **Complete Data Types** for every field and response
- **All Error Handling** scenarios and responses
- **Complete Authentication** flow with JWT security
- **All Real-time Features** with WebSocket integration
- **Complete Image Handling** with multi-tier caching
- **All Search Features** with semantic processing
- **Complete Auto-Matching** with scoring algorithms
- **All Social Features** with interaction tracking

#### Common Error Responses

**400 Bad Request**:
```json
{
  "error": "string (error description)",
  "details": "object (optional, field-specific errors)"
}
```

**401 Unauthorized**:
```json
{
  "error": "string (authentication error)",
  "message": "string"
}
```

**403 Forbidden**:
```json
{
  "error": "string (permission denied)",
  "message": "string"
}
```

**404 Not Found**:
```json
{
  "error": "string (resource not found)",
  "message": "string"
}
```

**429 Too Many Requests**:
```json
{
  "error": "string (rate limit exceeded)",
  "message": "string"
}
```

**500 Internal Server Error**:
```json
{
  "error": "string (server error)",
  "message": "string"
}
```

### WebSocket System

**Channels Configuration:**
- Uses `channels` and `channels-redis`
- Redis for channel layer backend
- ASGI application with Daphne server

**WebSocket Routes:**
```python
# routing.py
websocket_urlpatterns = [
    re_path(r"ws/chat/(?P<sender>\w+)/(?P<receiver>\w+)/$", ChatConsumer.as_asgi()),
    re_path(r"ws/group_chat/(?P<event_id>[^/]+)/$", GroupChatConsumer.as_asgi()),
    re_path(r"ws/events/(?P<username>\w+)/$", EventsConsumer.as_asgi()),
]
```

**WebSocket Consumers:**
- **EventsConsumer** - Real-time event updates
- **ChatConsumer** - Direct messaging between users
- **GroupChatConsumer** - Event-based group chat

**Event Broadcasting:**
- Real-time event updates via WebSocket
- Message format: `{"type": "update|create|delete", "event_id": "uuid"}`
- Automatic reconnection with exponential backoff

### File Storage

**Cloudflare R2:**
- Configured in `storage.py` and `storage_r2.py`
- Handles user uploads and event images
- CDN integration for fast delivery

---

## iOS Frontend Documentation

### Complete iOS App Structure

```
Fibbling/                    # iOS app root
├── FibblingApp.swift       # App entry point
├── ContentView.swift       # Main view
├── Config/
│   └── APIConfig.swift     # API configuration
├── Managers/
│   ├── AppDelegate.swift           # App lifecycle management
│   ├── CalendarManager.swift       # Event management
│   ├── EventsWebSocketManager.swift # WebSocket handling
│   ├── UserAccountManager.swift   # Authentication
│   ├── ChatManager.swift          # Chat functionality
│   ├── NotificationManager.swift  # Push notifications
│   ├── LocationManager.swift      # GPS location services
│   ├── ImageManager.swift         # User image management
│   ├── ImageUploadManager.swift   # Professional image upload
│   ├── ProfessionalImageCache.swift # Multi-tier image caching
│   ├── ContentModerationManager.swift # Content reporting
│   ├── LocalizationManager.swift  # Multi-language support
│   ├── NetworkMonitor.swift       # Network connectivity
│   └── UserReputationManager.swift # User rating system
├── Views/
│   ├── AccessibilityEnhancements.swift # Accessibility features
│   ├── AccountView.swift           # Account management
│   ├── APICallsEventInteractions.swift # Event API interactions
│   ├── CalendarPopupView.swift     # Calendar popup interface
│   ├── CalendarView.swift          # Calendar display
│   ├── ChangePasswordView.swift    # Password change interface
│   ├── ChatView.swift              # Chat interface
│   ├── Color+Theme.swift           # Color theme definitions
│   ├── Components/                 # Reusable UI components
│   │   ├── CustomNavigationBar.swift
│   │   ├── CustomTextField.swift
│   │   ├── DateTimeSelector.swift
│   │   ├── EmptyStateView.swift
│   │   ├── EventCard.swift
│   │   ├── EventsRefreshView.swift
│   │   ├── ImageGridView.swift
│   │   ├── ProfessionalCachedImageView.swift
│   │   ├── SkeletonLoader.swift
│   │   ├── UploadProgressView.swift
│   │   ├── UserProfileImageView.swift
│   │   └── ValidationMessage.swift
│   ├── DayForecastView.swift       # Weather forecast
│   ├── EditProfileView.swift       # Profile editing
│   ├── FlowLayout.swift            # Custom layout
│   ├── FriendsAccountView.swift    # Friends management
│   ├── FriendsListView.swift       # Friends list display
│   ├── ImageGalleryView.swift      # Image gallery
│   ├── Invitations.swift           # Event invitations
│   ├── LanguageSettingsView.swift # Language settings
│   ├── LocationPickerView.swift    # Location selection
│   ├── LoginView.swift             # Login interface
│   ├── MapBox.swift                # Mapbox integration
│   ├── MapViews/                   # Map-related views
│   │   ├── EventAnnotationView.swift
│   │   ├── EventCreationView.swift
│   │   ├── EventDetailedView.swift
│   │   ├── EventDetailView.swift
│   │   ├── EventEditView.swift
│   │   ├── EventFilterView.swift
│   │   ├── GroupChatView.swift
│   │   ├── GroupChatWebSocketManager.swift
│   │   ├── ImagePicker.swift
│   │   ├── LoadingOverlay.swift
│   │   └── StudyEventAnnotations.swift
│   ├── MatchingPreferencesView.swift # Auto-matching preferences
│   ├── NotificationPreferencesView.swift # Notification settings
│   ├── OnboardingView.swift        # User onboarding
│   ├── PersonalDashboardView.swift # Personal dashboard
│   ├── PrivacySettingsView.swift   # Privacy settings
│   ├── RateUserView.swift          # User rating interface
│   ├── RootView.swift              # Root navigation view
│   ├── SettingsView.swift          # Settings interface
│   ├── StudyBuddyFinderView.swift   # Study buddy finder
│   ├── StudyConApp.swift           # Main app view
│   ├── Try.swift                   # Testing/development view
│   ├── UniversityCardView.swift    # University display card
│   ├── UniversitySelectionView.swift # University selection
│   ├── UserAccountManager.swift    # User account management
│   ├── UserReputationView.swift    # User reputation display
│   ├── WeatherAndCalendarView.swift # Weather and calendar
│   ├── WeatherService.swift        # Weather service
│   └── WeatherView.swift           # Weather display
├── Models/
│   ├── StudyEvent.swift    # Event data model
│   ├── MessageModel.swift  # Chat message model
│   ├── University.swift    # University data model
│   ├── UserImage.swift     # User image model
│   └── UserRating.swift    # User rating model
├── ViewModels/
│   ├── EventCreationViewModel.swift # Event creation logic
│   ├── UpcomingEventsViewModel.swift # Upcoming events
│   ├── AutoMatchingManager.swift   # Auto-matching logic
│   └── UserProfileManager.swift    # Profile management
└── Utilities/
    ├── AppLogger.swift      # Centralized logging
    ├── AppError.swift       # Error handling
    ├── InputValidator.swift # Input validation
    ├── HapticManager.swift  # Haptic feedback
    ├── ImageRetryManager.swift # Image loading retry
    └── NetworkRetryManager.swift # Network retry logic
```

### Detailed iOS File Documentation

#### User Rating System

**RateUserView.swift** - User Rating Interface
```swift
struct RateUserView: View {
    let eventId: UUID
    let eventTitle: String
    let username: String
    let targetUser: String
    let onComplete: (Bool) -> Void
    
    @State private var rating: Int = 5
    @State private var reference: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    @EnvironmentObject var accountManager: UserAccountManager
    @Environment(\.dismiss) private var dismiss
```

**Key Features:**
- **Star Rating Interface**: Interactive 5-star rating system with visual feedback
- **Reference Text**: Optional text field for detailed feedback
- **Multi-Server Fallback**: Tries multiple API endpoints for reliability
- **JWT Authentication**: Integrates with UserAccountManager for secure requests
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Accessibility**: Full accessibility support with labels and hints

**UserReputationView.swift** - Reputation Display
```swift
struct UserReputationView: View {
    let username: String
    @StateObject private var reputationManager = UserReputationManager()
    @State private var showRatingsList = false
```

**Key Features:**
- **Reputation Header**: Shows overall rating and rating count
- **Trust Level Display**: Visual trust level with progress indicators
- **Activity Stats**: Events hosted, attended, and total reviews
- **Recent Reviews Preview**: Shows latest 2 reviews with "See All" option
- **Progress Tracking**: Shows progress to next trust level
- **Professional UI**: Clean, card-based design with shadows and rounded corners

**UserReputationManager.swift** - Reputation Data Management
```swift
class UserReputationManager: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var userRatings: [UserRating] = []
    @Published var userStats: UserReputationStats = UserReputationStats()
```

**Key Features:**
- **API Integration**: Fetches user reputation and ratings from backend
- **Multi-Server Support**: Tries multiple API endpoints for reliability
- **JWT Authentication**: Secure API calls with authentication headers
- **Data Parsing**: Handles complex JSON responses from Django backend
- **Error Handling**: Comprehensive error handling and user feedback
- **Real-time Updates**: ObservableObject for SwiftUI integration

#### Core Views Documentation

**LoginView.swift** - Authentication Interface
- **Username/Password Fields**: Secure text input with validation
- **Login Button**: Integrated with UserAccountManager
- **Error Display**: User-friendly error messages
- **Loading States**: Visual feedback during authentication
- **Accessibility**: Full accessibility support

**SettingsView.swift** - Application Settings
- **Account Settings**: Profile management options
- **Notification Preferences**: Push notification controls
- **Privacy Settings**: Data privacy and sharing options
- **Language Settings**: Multi-language support
- **Matching Preferences**: Auto-matching configuration
- **Logout Functionality**: Secure session termination

**ProfileView.swift** - User Profile Display
- **Profile Information**: Name, university, degree, year
- **Profile Pictures**: Image gallery with primary image selection
- **Interests Display**: Visual interest tags
- **Skills Showcase**: Skill levels and categories
- **Reputation Display**: Trust level and rating summary
- **Edit Profile**: Navigation to profile editing

**EditProfileView.swift** - Profile Editing Interface
- **Form Validation**: Real-time input validation
- **Image Upload**: Professional image upload with progress
- **Interest Selection**: Multi-select interest picker
- **Skill Management**: Add/edit skills with levels
- **University Selection**: University picker with search
- **Save/Cancel**: Form submission with error handling

#### Map Views Documentation

**MapBox.swift** - Main Map Interface
- **Mapbox Integration**: Native Mapbox SDK integration
- **Event Annotations**: Custom event markers with clustering
- **Location Services**: GPS location tracking
- **Event Filtering**: Filter events by type, distance, time
- **Event Creation**: Quick event creation from map
- **Real-time Updates**: WebSocket integration for live updates

**EventCreationView.swift** - Event Creation Interface
- **Form Fields**: Title, description, location, time
- **Location Picker**: Interactive map-based location selection
- **DateTime Selector**: Custom date/time picker
- **Event Type Selection**: Visual event type picker
- **Friend Invitations**: Multi-select friend picker
- **Auto-matching Toggle**: Enable/disable auto-matching
- **Image Upload**: Event image upload with preview

**EventDetailView.swift** - Event Details Display
- **Event Information**: Complete event details
- **Host Information**: Host profile with reputation
- **Attendee List**: List of confirmed attendees
- **RSVP Actions**: Join/decline event functionality
- **Chat Integration**: Group chat for event participants
- **Share Functionality**: Share event via social media
- **Rating Interface**: Rate host after event completion

#### Component Documentation

**CustomTextField.swift** - Enhanced Text Input
- **Validation States**: Visual validation feedback
- **Error Messages**: Inline error display
- **Accessibility**: Full accessibility support
- **Custom Styling**: Branded appearance
- **Input Types**: Support for different input types

**EventCard.swift** - Event Display Card
- **Event Preview**: Compact event information
- **Host Information**: Host name and reputation
- **Time Display**: Formatted date/time
- **Location Info**: Distance and location name
- **Action Buttons**: Quick RSVP actions
- **Image Support**: Event image display

**ProfessionalCachedImageView.swift** - Optimized Image Display
- **Multi-tier Caching**: Memory, disk, and network caching
- **Progressive Loading**: Low-res to high-res loading
- **Error Handling**: Fallback images and retry logic
- **Performance Optimization**: Lazy loading and memory management
- **Accessibility**: Image descriptions and labels

#### Manager Documentation

**CalendarManager.swift** - Event Management
- **Event Fetching**: API integration for event data
- **Real-time Updates**: WebSocket integration
- **Caching**: Local event caching
- **Filtering**: Event filtering and sorting
- **Refresh Logic**: Smart refresh with cooldown
- **Error Handling**: Comprehensive error management

**ChatManager.swift** - Messaging System
- **Message Sending**: Send messages to users
- **Message History**: Fetch conversation history
- **Real-time Updates**: WebSocket message delivery
- **Message Types**: Text, images, and system messages
- **Notification Integration**: Push notifications for messages
- **Message Status**: Read receipts and delivery status

**ImageManager.swift** - Image Management
- **Image Upload**: Multi-image upload with progress
- **Image Processing**: Compression and optimization
- **Storage Management**: Local and cloud storage
- **Image Types**: Profile, gallery, and event images
- **Privacy Controls**: Image visibility settings
- **Error Handling**: Upload failure recovery

**LocationManager.swift** - Location Services
- **GPS Tracking**: Current location tracking
- **Location Permissions**: Permission management
- **Location Search**: Search for locations
- **Distance Calculation**: Calculate distances between points
- **Location Caching**: Cache frequently used locations
- **Privacy Protection**: Location privacy controls

#### Model Documentation

**StudyEvent.swift** - Event Data Model
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

**UserRating.swift** - Rating Data Model
```swift
struct UserRating: Identifiable, Codable {
    let id: UUID
    let fromUser: String
    let toUser: String
    let eventId: String?
    let rating: Int
    let reference: String?
    let createdAt: String
}
```

**MessageModel.swift** - Chat Message Model
- **Message Types**: Text, image, system messages
- **User Information**: Sender and receiver details
- **Timestamp**: Message creation time
- **Status Tracking**: Sent, delivered, read status
- **Content**: Message content with type safety

#### ViewModel Documentation

**EventCreationViewModel.swift** - Event Creation Logic
- **Form Validation**: Real-time form validation
- **Location Handling**: Location picker integration
- **Friend Selection**: Multi-select friend picker
- **Image Upload**: Image upload management
- **API Integration**: Event creation API calls
- **Error Handling**: Comprehensive error management

**AutoMatchingManager.swift** - Auto-matching Logic
- **Preference Management**: User matching preferences
- **Algorithm Integration**: Backend auto-matching API
- **Match Display**: Show potential matches
- **Match Actions**: Accept/decline matches
- **Analytics**: Track matching success rates
- **Settings Integration**: Preference updates

**UserProfileManager.swift** - Profile Management
- **Profile Data**: User profile information
- **Image Management**: Profile image handling
- **Interest Management**: Interest tag management
- **Skill Management**: Skill level management
- **University Integration**: University selection
- **Privacy Settings**: Profile visibility controls

### iOS Frontend Interactions & Complex Implementations

#### MapBox.swift - Complex Map Integration (2000+ lines)

**Core Architecture:**
```swift
class RefreshController: ObservableObject {
    private var refreshWorkItem: DispatchWorkItem?
    private var refreshCount = 0
    private var lastRefreshTime = Date()
    
    func debouncedRefresh(delay: TimeInterval = 0.3, action: @escaping () -> Void) {
        refreshWorkItem?.cancel()
        refreshWorkItem = DispatchWorkItem {
            self.refreshCount += 1
            self.lastRefreshTime = Date()
            action()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: refreshWorkItem!)
    }
}
```

**Key Interactions:**
- **CalendarManager Integration**: Fetches events and updates map annotations
- **WebSocket Integration**: Real-time event updates via EventsWebSocketManager
- **LocationManager Integration**: GPS tracking and location services
- **EventDetailView Integration**: Navigation to event details on annotation tap
- **EventCreationView Integration**: Quick event creation from map location

**Complex Features:**
- **Event Clustering**: Groups nearby events with custom clustering algorithms
- **Multiple View Modes**: All events, auto-matched, RSVP-only filtering
- **Refresh Controller**: Debounced refresh to prevent excessive API calls
- **Hot Posts Integration**: Social media-style posts on map
- **Real-time Updates**: Live event updates via WebSocket
- **Performance Optimization**: Efficient annotation management and memory usage

#### CalendarView.swift - Complex Calendar Implementation (1000+ lines)

**Core Architecture:**
```swift
struct CustomCalendarView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @State private var displayedMonth: Date = Date()
    @State private var selectedDayEvents: [StudyEvent] = []
    @State private var showDayEventsSheet: Bool = false
    @State private var selectedDate: Date = Date()
    @State private var calendarViewMode: CalendarViewMode = .month
    @State private var showEventCreation = false
    @State private var eventViewMode: EventViewMode = .all
}
```

**Key Interactions:**
- **CalendarManager Integration**: Fetches and manages event data
- **EventCreationView Integration**: Creates new events from calendar
- **EventDetailView Integration**: Shows event details on selection
- **WebSocket Integration**: Real-time event updates
- **NotificationCenter Integration**: Handles RSVP status changes

**Complex Features:**
- **Custom Calendar Rendering**: Month and week view modes
- **Event Filtering**: Multiple view modes (all, auto-matched, RSVP-only)
- **Day Events Sheet**: Modal presentation of daily events
- **Event Creation Flow**: Integrated event creation with location
- **Real-time Updates**: Live event updates and RSVP changes
- **Performance Optimization**: Efficient calendar rendering and event management

#### EventDetailView.swift - Complex Event Details (500+ lines)

**Core Architecture:**
```swift
struct EventDetailView: View {
    let event: StudyEvent
    @EnvironmentObject var accountManager: UserAccountManager
    @StateObject private var chatManager = ChatManager()
    @State private var showChat = false
    @State private var showRating = false
    @State private var rsvpStatus: RSVPStatus = .notResponded
    @State private var isLoading = false
}
```

**Key Interactions:**
- **UserAccountManager Integration**: Authentication and user data
- **ChatManager Integration**: Group chat functionality
- **RateUserView Integration**: Post-event rating system
- **WebSocket Integration**: Real-time attendee updates
- **CalendarManager Integration**: RSVP status management

**Complex Features:**
- **RSVP Management**: Join/decline event functionality
- **Group Chat**: Real-time messaging for event participants
- **User Rating**: Rate host after event completion
- **Attendee Management**: Live attendee list updates
- **Event Sharing**: Social media integration
- **Real-time Updates**: Live event changes and notifications

#### Complex Data Flow Patterns

**Event Creation Flow:**
```
MapBox.swift → EventCreationView.swift → CalendarManager.swift → Backend API
     ↓              ↓                        ↓
WebSocket → Real-time Updates → CalendarView.swift → EventDetailView.swift
```

**RSVP Flow:**
```
EventDetailView.swift → CalendarManager.swift → Backend API → WebSocket
     ↓                        ↓                    ↓
RateUserView.swift ← Event Completion ← Real-time Updates ← All Participants
```

**Real-time Update Flow:**
```
Backend WebSocket → EventsWebSocketManager.swift → CalendarManager.swift
     ↓                        ↓                        ↓
MapBox.swift ← Event Updates ← CalendarView.swift ← EventDetailView.swift
```

#### WebSocket Integration Patterns

**EventsWebSocketManager Integration:**
```swift
class EventsWebSocketManager: ObservableObject {
    weak var delegate: EventsWebSocketManagerDelegate?
    private var webSocketTask: URLSessionWebSocketTask?
    private let username: String
    @Published var isConnected = false
    
    func connect() {
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        listenForMessages()
        startPingTimer()
    }
}
```

**Integration Points:**
- **CalendarManager**: Receives event updates and refreshes data
- **MapBox**: Updates map annotations in real-time
- **EventDetailView**: Updates attendee lists and RSVP status
- **ChatManager**: Handles real-time messaging

#### Performance Optimization Patterns

**Refresh Controller Pattern:**
```swift
class RefreshController: ObservableObject {
    private var refreshWorkItem: DispatchWorkItem?
    
    func debouncedRefresh(delay: TimeInterval = 0.3, action: @escaping () -> Void) {
        refreshWorkItem?.cancel()
        refreshWorkItem = DispatchWorkItem { action() }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: refreshWorkItem!)
    }
}
```

**Caching Patterns:**
- **Event Caching**: Local storage of event data
- **Image Caching**: Multi-tier image caching system
- **Location Caching**: Cached location data for performance
- **User Data Caching**: Cached user profiles and preferences

#### Error Handling & Retry Logic

**Multi-Server Fallback Pattern:**
```swift
private func tryNextURL(index: Int, baseURLs: [String], completion: @escaping (Bool, Data?) -> Void) {
    guard index < baseURLs.count else {
        completion(false, nil)
        return
    }
    
    let baseURL = baseURLs[index]
    // Try current URL, fallback to next on failure
    // Implements automatic failover across multiple servers
}
```

**Retry Logic:**
- **Network Requests**: Automatic retry with exponential backoff
- **WebSocket Connections**: Automatic reconnection with backoff
- **Image Loading**: Retry failed image loads
- **API Calls**: Retry failed API requests

#### State Management Patterns

**ObservableObject Pattern:**
```swift
class CalendarManager: ObservableObject {
    @Published var events: [StudyEvent] = []
    @Published var isLoading: Bool = false
    @Published var lastRefreshTime: Date? = nil
    
    // Complex state management with multiple publishers
    private var cancellable: AnyCancellable?
    private var webSocketManager: EventsWebSocketManager?
}
```

**EnvironmentObject Pattern:**
```swift
struct MapBox: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var locationManager: LocationManager
    
    // Shared state across multiple views
}
```

#### Backend Integration Patterns

**API Integration:**
```swift
func fetchEvents() {
    let baseURLs = APIConfig.baseURLs
    tryNextURL(index: 0, baseURLs: baseURLs) { success, data in
        if success, let data = data {
            self.parseEventsData(data: data)
        }
    }
}
```

**Authentication Integration:**
```swift
func addAuthHeader(to request: inout URLRequest) {
    if let token = accessToken {
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}
```

**WebSocket Integration:**
```swift
func broadcast_event_created(event_id, host_username, attendees, invited_friends):
    # Backend broadcasts to all relevant users
    # Frontend receives via WebSocket and updates UI
```

### Complete iOS Models Documentation

#### StudyEvent.swift - Event Data Model (Complete Implementation)
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
    
    enum EventType: String, CaseIterable, Codable {
        case study = "study"
        case social = "social"
        case sports = "sports"
        case cultural = "cultural"
        case academic = "academic"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .study: return "Study Group"
            case .social: return "Social Event"
            case .sports: return "Sports"
            case .cultural: return "Cultural"
            case .academic: return "Academic"
            case .other: return "Other"
            }
        }
        
        var icon: String {
            switch self {
            case .study: return "book.fill"
            case .social: return "person.3.fill"
            case .sports: return "sportscourt.fill"
            case .cultural: return "theatermasks.fill"
            case .academic: return "graduationcap.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }
}
```

#### UserRating.swift - Rating System Model (Complete Implementation)
```swift
struct UserRating: Identifiable, Codable, Equatable {
    let id: String
    let fromUser: String
    let toUser: String
    let eventId: String?
    let rating: Int // 1-5 stars
    let reference: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case fromUser = "from_username"
        case toUser = "to_username"
        case eventId = "event_id"
        case rating
        case reference
        case createdAt = "created_at"
    }
}

struct UserTrustLevel: Codable, Equatable {
    var level: Int
    var title: String
    var requiredRatings: Int
    var minAverageRating: Double
    
    static let levels: [UserTrustLevel] = [
        UserTrustLevel(level: 1, title: "Newcomer", requiredRatings: 0, minAverageRating: 0.0),
        UserTrustLevel(level: 2, title: "Participant", requiredRatings: 3, minAverageRating: 3.0),
        UserTrustLevel(level: 3, title: "Trusted Member", requiredRatings: 10, minAverageRating: 3.5),
        UserTrustLevel(level: 4, title: "Event Expert", requiredRatings: 20, minAverageRating: 4.0),
        UserTrustLevel(level: 5, title: "Community Leader", requiredRatings: 50, minAverageRating: 4.5)
    ]
}

struct UserReputationStats: Codable, Equatable {
    var totalRatings: Int
    var averageRating: Double
    var trustLevel: UserTrustLevel
    var eventsHosted: Int
    var eventsAttended: Int
}
```

#### UserImage.swift - Image Management Model (Complete Implementation)
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
        
        var icon: String {
            switch self {
            case .profile: return "person.circle"
            case .gallery: return "photo"
            case .cover: return "rectangle.3.group"
            }
        }
    }
}

struct ImageUploadRequest {
    let username: String
    let imageData: Data
    let imageType: UserImage.ImageType
    let isPrimary: Bool
    let caption: String
    let filename: String
    
    var mimeType: String {
        if imageData.starts(with: [0xFF, 0xD8, 0xFF]) {
            return "image/jpeg"
        } else if imageData.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return "image/png"
        } else if imageData.starts(with: [0x47, 0x49, 0x46]) {
            return "image/gif"
        } else if imageData.starts(with: [0x52, 0x49, 0x46, 0x46]) {
            return "image/webp"
        }
        return "image/jpeg"
    }
}
```

#### University.swift - University Data Model
```swift
struct University {
    let name: String
    let color: Color
    let textColor: Color
    let logo: String
    
    static func sampleData() -> [University] {
        return [
            University(name: "Technical University", color: Color.blue, textColor: .white, logo: "wrench.fill"),
            University(name: "Earth Science University", color: Color.green, textColor: .white, logo: "leaf.fill"),
            University(name: "Medical University", color: Color.red, textColor: .white, logo: "cross.fill"),
            University(name: "Business School", color: Color.purple, textColor: .white, logo: "chart.bar.fill"),
            University(name: "Design Academy", color: Color.orange, textColor: .white, logo: "paintbrush.fill"),
            University(name: "Law School", color: Color.gray, textColor: .black, logo: "scroll.fill")
        ]
    }
}
```

#### MessageModel.swift - Chat Message Model
```swift
struct Message: Codable {
    let message: String
}
```

### Complete iOS Views Documentation

#### ContentView.swift - Main App Interface (3700+ lines)

**Core Architecture:**
```swift
struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var showSettingsView = false
    @State private var showFriendsView = false
    @State private var showCalendarView = false
    @State private var showNotesView = false
    @State private var showFlashcardsView = false
    @State private var showProfileView = false
    @State private var showMapView = false
    @State private var selectedEvent: StudyEvent? = nil
    @State private var showEventDetailSheet = false
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var calendarManager: CalendarManager
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // State for next RSVP'd event
    @State private var nextRSVPEvent: StudyEvent? = nil
    @State private var isLoadingEvents = false
    @State private var isEventDetailLoading = false
    
    // Animation state
    @State private var isAnimating = false
```

**Key Interactions:**
- **Profile Integration**: Shows MatchingPreferencesView as profile view
- **Event Management**: Displays next RSVP'd event with EventDetailView integration
- **Navigation**: Manages all app navigation states and sheet presentations
- **CalendarManager Integration**: Fetches events and manages event state
- **UserAccountManager Integration**: Handles authentication and user data
- **Real-time Updates**: Listens to calendar events changes and updates UI

**Complex Features:**
- **Dynamic Background**: Animated gradient background with floating elements
- **Event Card**: Shows next RSVP'd event with tap-to-view functionality
- **Weather Integration**: Weather and map card with real-time data
- **Academic Tools**: Grid of academic tools (notes, flashcards, calendar)
- **Quick Access**: Quick access to friends, settings, and profile
- **Professional UI**: Sophisticated design with shadows, gradients, and animations

**Data Flow:**
```
ContentView → CalendarManager.fetchEvents() → Backend API
     ↓
EventDetailView ← selectedEvent ← nextRSVPEvent ← CalendarManager.events
     ↓
WebSocket Updates → CalendarManager.$events → ContentView.onReceive
```

#### LoginView.swift - Authentication Interface (300+ lines)

**Core Architecture:**
```swift
struct LoginView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    @State private var username = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isRegistering = false
    @State private var showPassword = false
    @State private var email = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false
```

**Key Interactions:**
- **UserAccountManager Integration**: Handles login/register API calls
- **Form Validation**: Real-time validation for username, email, password
- **Terms Agreement**: Legal terms acceptance for registration
- **Password Security**: Secure password input with show/hide toggle
- **Error Handling**: User-friendly error messages and alerts

**Complex Features:**
- **Dual Mode**: Login and registration in single view
- **Professional Styling**: Consistent with app design language
- **Form Validation**: Real-time input validation
- **Security Features**: Secure password handling and terms agreement
- **Responsive Design**: Adapts to different screen sizes

#### SettingsView.swift - Application Settings (900+ lines)

**Core Architecture:**
```swift
struct SettingsView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @Environment(\.dismiss) private var dismiss
    @StateObject private var theme = PinItTheme()
    
    // App Storage for Preferences
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("darkMode") private var darkMode = false
    @StateObject private var localizationManager = LocalizationManager.shared
    @AppStorage("showOnlineStatus") private var showOnlineStatus = true
    @AppStorage("allowTagging") private var allowTagging = true
    @AppStorage("allowDirectMessages") private var allowDirectMessages = true
    @AppStorage("showActivityStatus") private var showActivityStatus = true
```

**Key Interactions:**
- **UserAccountManager Integration**: Logout and account management
- **LocalizationManager Integration**: Language settings
- **Privacy Settings**: Data privacy and sharing controls
- **Notification Preferences**: Push notification settings
- **Legal Documents**: Privacy policy and terms of service

**Complex Features:**
- **Comprehensive Settings**: Account, privacy, notifications, legal
- **Legal Documents**: Built-in privacy policy and terms of service
- **Privacy Controls**: Granular privacy settings
- **Account Management**: Logout, delete account, change password
- **Professional UI**: Card-based design with consistent styling

#### MatchingPreferencesView.swift - Profile Management (450+ lines)

**Core Architecture:**
```swift
struct MatchingPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var theme = PinItTheme()
    @ObservedObject private var imageManager = ImageManager.shared
    @EnvironmentObject var accountManager: UserAccountManager

    // App Storage for Matching Preferences
    @AppStorage("allowAutoMatching") private var allowAutoMatching = true
    @AppStorage("preferredRadius") private var preferredRadius = 10.0
    @AppStorage("matchingAgeRange") private var matchingAgeRange = "18-25"
    @AppStorage("matchingUniversity") private var matchingUniversity = ""
    @AppStorage("matchingDegree") private var matchingDegree = ""
    @AppStorage("matchingYear") private var matchingYear = ""
    
    // State variables for arrays
    @State private var matchingInterests: [String] = []
    @State private var matchingSkills: [String] = []
    @State private var preferredEventTypes: [String] = []
```

**Key Interactions:**
- **ImageManager Integration**: Profile image management
- **UserAccountManager Integration**: User profile data
- **Auto-matching System**: Matching preferences configuration
- **Image Upload**: Multi-image upload with primary image selection
- **Interest Management**: Dynamic interest and skill management

**Complex Features:**
- **Profile Images**: Multi-image gallery with primary image selection
- **Auto-matching Preferences**: Comprehensive matching configuration
- **Interest Management**: Dynamic add/remove interests and skills
- **University Selection**: University picker with search
- **Professional Image Upload**: Multi-tier image upload system

### Complete iOS Component Documentation

#### CustomTextField.swift - Enhanced Text Input
```swift
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    let keyboardType: UIKeyboardType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.brandPrimary)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
            }
            
            TextField("", text: $text)
                .keyboardType(keyboardType)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.bgCard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cardStroke, lineWidth: 1)
                )
        }
    }
}
```

#### EventCard.swift - Event Display Card
```swift
struct EventCard: View {
    let event: StudyEvent
    @EnvironmentObject var accountManager: UserAccountManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Event header with title and type
            HStack {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Image(systemName: event.eventType.icon)
                    .foregroundColor(.brandPrimary)
            }
            
            // Event details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.textSecondary)
                    Text(event.time.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.textSecondary)
                    Text("Location")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                HStack {
                    Image(systemName: "person.3")
                        .foregroundColor(.textSecondary)
                    Text("\(event.attendees.count) attendees")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
            
            // Action buttons
            HStack {
                Button("View Details") {
                    // Navigate to event details
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button("RSVP") {
                    // Handle RSVP
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 2)
        )
    }
}
```

### Complete iOS Manager Documentation

#### ImageManager.swift - Image Management System
```swift
class ImageManager: ObservableObject {
    static let shared = ImageManager()
    
    @Published var userImages: [UserImage] = []
    @Published var isLoading: Bool = false
    @Published var uploadProgress: Double = 0.0
    
    private let baseURLs = APIConfig.baseURLs
    private var accountManager: UserAccountManager?
    
    func uploadImage(_ request: ImageUploadRequest, completion: @escaping (Bool) -> Void) {
        // Multi-server image upload with progress tracking
        // Handles different image types (profile, gallery, cover)
        // Implements retry logic and error handling
    }
    
    func getPrimaryImage() -> UserImage? {
        return userImages.first { $0.isPrimary }
    }
    
    func cachedAsyncImage(url: String) -> some View {
        // Multi-tier image caching implementation
        // Memory, disk, and network caching
        // Progressive loading and error handling
    }
}
```

#### LocalizationManager.swift - Multi-language Support
```swift
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String = "en"
    @Published var availableLanguages: [String] = ["en", "es", "fr", "de"]
    
    func setLanguage(_ language: String) {
        currentLanguage = language
        // Update app language
    }
    
    func localizedString(_ key: String) -> String {
        // Return localized string for current language
    }
}
```

### Complete iOS Integration Patterns

#### Authentication Flow
```
LoginView → UserAccountManager.login() → Backend API
     ↓
JWT Token Storage → ContentView → All Protected Views
     ↓
Token Refresh → Automatic re-authentication
```

#### Event Management Flow
```
ContentView → CalendarManager.fetchEvents() → Backend API
     ↓
EventDetailView ← selectedEvent ← CalendarManager.events
     ↓
RSVP Action → CalendarManager.rsvpEvent() → Backend API
     ↓
WebSocket Update → All Connected Clients
```

#### Image Upload Flow
```
MatchingPreferencesView → ImageManager.uploadImage() → Backend API
     ↓
Progress Tracking → UI Updates → Success/Error Handling
     ↓
Image Caching → ProfessionalCachedImageView → Display
```

#### Real-time Updates Flow
```
Backend WebSocket → EventsWebSocketManager → CalendarManager
     ↓
ContentView ← Event Updates ← CalendarView ← MapBox
     ↓
EventDetailView ← Attendee Updates ← ChatManager
```

### Complete iOS Error Handling & Retry Logic

#### Multi-Server Fallback Pattern
```swift
private func tryNextURL(index: Int, baseURLs: [String], completion: @escaping (Bool, Data?) -> Void) {
    guard index < baseURLs.count else {
        completion(false, nil)
        return
    }
    
    let baseURL = baseURLs[index]
    // Try current URL, fallback to next on failure
    // Implements automatic failover across multiple servers
}
```

#### WebSocket Reconnection Logic
```swift
func reconnect() {
    guard !isConnected else { return }
    
    // Exponential backoff reconnection
    let delay = min(pow(2.0, Double(reconnectAttempts)) * 1.0, 30.0)
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        self.connect()
        self.reconnectAttempts += 1
    }
}
```

#### Image Upload Retry Logic
```swift
func retryImageUpload(_ request: ImageUploadRequest, maxRetries: Int = 3) {
    guard retryCount < maxRetries else {
        // Show error to user
        return
    }
    
    retryCount += 1
    uploadImage(request) { success in
        if !success {
            self.retryImageUpload(request, maxRetries: maxRetries)
        }
    }
}
```

### Complete iOS Views Documentation (All Files)

#### AccountView.swift - Account Management Interface
```swift
struct AccountView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @State private var showLogoutAlert = false
```

**Key Features:**
- **Friend Requests Management**: Accept/decline pending friend requests
- **Friends List Display**: Show current friends with professional UI
- **Logout Functionality**: Secure logout with confirmation alert
- **UserAccountManager Integration**: Complete integration with authentication system
- **Professional UI**: Clean, card-based design with consistent styling

**Key Interactions:**
- **UserAccountManager**: Manages friend requests and friends list
- **Logout Flow**: Secure session termination with confirmation
- **Friend Management**: Accept friend requests and view friends list

#### ChatView.swift - Real-time Messaging Interface (350+ lines)
```swift
struct ChatView: View {
    @EnvironmentObject var chatManager: ChatManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var message = ""
    @State private var isSending = false
    @State private var scrollToBottom = false
    @FocusState private var isInputFocused: Bool
    @State private var messagesArray: [ChatMessage] = []
    
    let sender: String
    let receiver: String
```

**Key Features:**
- **Real-time Messaging**: Live chat with WebSocket integration
- **Message History**: Fetch and display conversation history
- **Auto-scroll**: Automatic scrolling to latest messages
- **Professional UI**: Clean chat interface with custom header
- **Message Status**: Sent, delivered, and read status tracking
- **Focus Management**: Keyboard focus management for input

**Key Interactions:**
- **ChatManager Integration**: Real-time messaging and message history
- **WebSocket Connection**: Live message delivery and updates
- **Message Sending**: Send messages with loading states
- **Auto-scroll**: Scroll to bottom on new messages

#### EditProfileView.swift - Profile Editing Interface (600+ lines)
```swift
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var accountManager: UserAccountManager
    @StateObject private var profileManager: UserProfileManager
    @ObservedObject private var imageManager = ImageManager.shared
    
    // User profile data
    @State private var username = ""
    @State private var email = ""
    @State private var fullName = ""
    @State private var location = ""
    @State private var website = ""
    @State private var bio = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var profileImageData: Data?
    
    // Form validation
    @State private var emailIsValid = true
    @State private var websiteIsValid = true
    
    // Interests state
    @State private var interests: [String] = []
    @State private var newInterest: String = ""
    @State private var showingAddInterest = false
```

**Key Features:**
- **Comprehensive Profile Editing**: All profile fields with validation
- **Image Management**: Profile image upload with ImageManager integration
- **Interest Management**: Dynamic add/remove interests
- **Form Validation**: Real-time validation for email and website
- **Professional UI**: Card-based design with sections
- **Image Gallery**: View and manage all profile images

**Key Interactions:**
- **UserProfileManager**: Profile data management and API calls
- **ImageManager**: Profile image upload and management
- **Form Validation**: Real-time input validation
- **Interest Management**: Dynamic interest tag management

#### FriendsListView.swift - Social Management Interface (800+ lines)
```swift
struct FriendsListView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var chatManager: ChatManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    
    @State private var searchQuery = ""
    @State private var allUsers: [String] = []
    @State private var sentRequests: [String] = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedTab = 0
    @State private var isLoading = false
    @State private var isPrefetchingImages = true
    @State private var showChatView = false
    @State private var selectedChatUser = ""
    @State private var showUserProfileSheet = false
    @State private var selectedUserProfile: String? = nil
    
    private var tabs: [String] {
        ["Friends", "Requests", "Discover"]
    }
```

**Key Features:**
- **Three-Tab Interface**: Friends, Requests, and Discover tabs
- **Search Functionality**: Real-time search across all users
- **Friend Management**: Send/accept friend requests
- **User Discovery**: Discover new users to connect with
- **Chat Integration**: Direct chat with friends
- **Image Prefetching**: Optimized image loading for performance
- **Professional UI**: Modern design with tab navigation

**Key Interactions:**
- **UserAccountManager**: Friend management and user data
- **ChatManager**: Direct messaging integration
- **Search Functionality**: Real-time user search
- **Friend Requests**: Send and manage friend requests

#### OnboardingView.swift - User Onboarding Interface (160+ lines)
```swift
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    private let pages = [
        OnboardingPage(
            title: "Welcome to PinIt",
            subtitle: "Connect with like-minded people through events",
            image: "person.3.fill",
            description: "Discover and create events that match your interests and meet amazing people in your area."
        ),
        OnboardingPage(
            title: "Auto-Match",
            subtitle: "Smart invitations based on interests",
            image: "heart.fill",
            description: "Our system automatically invites users with similar interests to your events. For private events, only matched users can see them - keeping your events discoverable but private."
        ),
        OnboardingPage(
            title: "Create & Join Events",
            subtitle: "Choose your privacy level",
            image: "calendar.badge.plus",
            description: "Create public events for everyone to see, or private events for friends only. Use auto-matching to find people with similar interests while keeping your event private."
        ),
        OnboardingPage(
            title: "Stay Connected",
            subtitle: "Real-time chat and updates",
            image: "message.fill",
            description: "Chat with event attendees, get instant notifications, and stay updated on all your activities."
        )
    ]
```

**Key Features:**
- **Multi-page Onboarding**: 4-page introduction to app features
- **Page Indicators**: Visual progress indicators
- **Navigation Controls**: Back/Next buttons with completion
- **Professional Design**: Consistent with app design language
- **Accessibility**: Full accessibility support
- **Completion Tracking**: AppStorage for onboarding completion

**Key Interactions:**
- **Page Navigation**: Smooth transitions between pages
- **Completion Tracking**: Mark onboarding as completed
- **User Introduction**: Introduce app features and benefits

#### WeatherService.swift - Weather Data Service
```swift
class WeatherService {
    private let apiKey = "" // Insert your API key here.
    
    func getWeather(for city: String) -> AnyPublisher<WeatherResponse, Error> {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=\(apiKey)&units=metric"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WeatherResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

struct WeatherResponse: Codable {
    let weather: [Weather]
    let main: Main
    let sys: Sys
    let dt: Int
    let timezone: Int
    let name: String
}
```

**Key Features:**
- **OpenWeatherMap Integration**: Real-time weather data
- **Combine Framework**: Reactive weather data fetching
- **Error Handling**: Comprehensive error management
- **Data Models**: Structured weather response models
- **City-based Weather**: Weather for specific cities

#### EventCreationView.swift - Event Creation Interface (1700+ lines)
```swift
struct EventCreationView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var calendarManager: CalendarManager
    @Environment(\.dismiss) var dismiss
    
    // Event State
    @State private var eventTitle = ""
    @State private var eventDescription = ""
    @State private var eventDate = Date().addingTimeInterval(3600)
    @State private var eventEndDate = Date().addingTimeInterval(7200)
    @State private var selectedEventType: EventType = .study
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    
    let initialCoordinate: CLLocationCoordinate2D
    @State private var selectedCoordinate: CLLocationCoordinate2D
    @State private var locationName = ""
    @State private var isPublic = true
    @State private var maxParticipants = 10
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var enableAutoMatching = false
    @State private var isLoading = false
    @State private var showFriendPicker = false
    @State private var selectedFriends: [String] = []
    @State private var locationSuggestions: [String] = []
    @State private var locationSuggestionsCoords: [String: CLLocationCoordinate2D] = [:]
    @State private var showLocationSuggestions = false
    @State private var isGeocoding = false
    @State private var showSuccessAnimation = false
    @State private var isSearchingSuggestions = false
    @State private var isLocationSelected = false
    @State private var suppressLocationOnChange = false
    
    var onSave: (StudyEvent) -> Void
```

**Key Features:**
- **Audience-Centric Design**: Clear Public/Private segmented control with intuitive descriptions
- **Privacy-Focused Auto-Matching**: Auto-matching works for both public and private events
- **Smart Validation**: Prevents private events without invitees or auto-matching
- **Location Integration**: Map-based location selection with geocoding
- **Image Upload**: Multiple image upload for events
- **Friend Invitations**: Invite friends to events with prominent CTA
- **Auto-Match**: Clear naming with contextual descriptions for both public and private events
- **Event Types**: Visual event type selection
- **Date/Time Selection**: Custom date and time pickers
- **Location Suggestions**: Real-time location search and suggestions
- **Professional UI**: Card-based design with smooth animations

**🔒 New Privacy Model:**
- **Public Events**: Visible to everyone + auto-matched users
- **Private Events**: Visible only to invited friends + auto-matched users
- **Auto-matched Events**: Only visible to matched users (not exposed to everyone)
- **Enhanced Privacy**: Users only see events they're actually matched for

**Key Interactions:**
- **CalendarManager**: Event creation and management
- **UserAccountManager**: User data and friend management
- **Location Services**: GPS and geocoding integration
- **Image Upload**: Event image management
- **Friend Selection**: Multi-select friend picker

### Complete iOS Components Documentation

#### CustomNavigationBar.swift - Custom Navigation Component
- **Professional Styling**: Consistent with app design language
- **Custom Actions**: Back button and action buttons
- **Accessibility**: Full accessibility support
- **Theme Integration**: Dynamic color scheme support

#### DateTimeSelector.swift - Date/Time Selection Component
- **Custom Date Picker**: Enhanced date and time selection
- **Validation**: Date validation and constraints
- **Professional UI**: Card-based design with animations
- **Accessibility**: Full accessibility support

#### EmptyStateView.swift - Empty State Component
- **Dynamic Content**: Customizable empty state messages
- **Action Buttons**: Call-to-action buttons
- **Professional Design**: Consistent with app styling
- **Accessibility**: Full accessibility support

#### EventsRefreshView.swift - Event Refresh Component
- **Pull-to-Refresh**: Custom refresh indicator
- **Loading States**: Visual loading feedback
- **Professional UI**: Consistent with app design
- **Performance**: Optimized refresh logic

#### ImageGridView.swift - Image Gallery Component
- **Grid Layout**: Responsive image grid
- **Image Selection**: Multi-select image functionality
- **Professional UI**: Card-based design
- **Performance**: Optimized image loading

#### ProfessionalCachedImageView.swift - Optimized Image Display
- **Multi-tier Caching**: Memory, disk, and network caching
- **Progressive Loading**: Low-res to high-res loading
- **Error Handling**: Fallback images and retry logic
- **Performance**: Lazy loading and memory management

#### SkeletonLoader.swift - Loading Skeleton Component
- **Skeleton Animation**: Shimmer loading effect
- **Customizable**: Different skeleton shapes and sizes
- **Professional UI**: Consistent with app design
- **Performance**: Lightweight loading states

#### UploadProgressView.swift - Upload Progress Component
- **Progress Tracking**: Real-time upload progress
- **Visual Feedback**: Progress bars and percentages
- **Error Handling**: Upload failure management
- **Professional UI**: Consistent with app styling

#### UserProfileImageView.swift - User Profile Image Component
- **Profile Image Display**: User profile picture display
- **Fallback Images**: Default avatars for missing images
- **Professional UI**: Consistent with app design
- **Accessibility**: Full accessibility support

#### ValidationMessage.swift - Validation Feedback Component
- **Error Messages**: User-friendly error display
- **Success Messages**: Positive feedback display
- **Professional UI**: Consistent with app styling
- **Accessibility**: Full accessibility support

### Complete iOS Map Views Documentation

#### EventAnnotationView.swift - Map Event Annotations
- **Custom Annotations**: Event markers on map
- **Event Information**: Display event details on tap
- **Professional UI**: Consistent with app design
- **Performance**: Optimized annotation rendering

#### EventDetailedView.swift - Detailed Event View
- **Complete Event Info**: All event details display
- **RSVP Functionality**: Join/decline event actions
- **Chat Integration**: Group chat for event participants
- **Professional UI**: Card-based design

#### EventEditView.swift - Event Editing Interface
- **Event Modification**: Edit existing events
- **Form Validation**: Real-time validation
- **Professional UI**: Consistent with app design
- **Error Handling**: Comprehensive error management

#### EventFilterView.swift - Event Filtering Interface
- **Filter Options**: Filter events by type, distance, time
- **Real-time Filtering**: Instant filter application
- **Professional UI**: Card-based design
- **Performance**: Optimized filtering logic

#### GroupChatView.swift - Group Chat Interface
- **Group Messaging**: Chat for event participants
- **Real-time Updates**: Live message delivery
- **Professional UI**: Consistent with app design
- **WebSocket Integration**: Real-time messaging

#### GroupChatWebSocketManager.swift - Group Chat WebSocket Manager
- **WebSocket Management**: Group chat connection management
- **Message Broadcasting**: Send messages to group
- **Connection Handling**: Automatic reconnection
- **Error Handling**: Comprehensive error management

#### ImagePicker.swift - Image Selection Component
- **Photo Library**: Access device photo library
- **Camera Integration**: Take photos directly
- **Multiple Selection**: Select multiple images
- **Professional UI**: Consistent with app design

#### LoadingOverlay.swift - Loading Overlay Component
- **Loading States**: Visual loading feedback
- **Overlay Design**: Full-screen loading overlay
- **Professional UI**: Consistent with app design
- **Accessibility**: Full accessibility support

#### StudyEventAnnotations.swift - Study Event Map Annotations
- **Study Event Markers**: Specialized markers for study events
- **Event Clustering**: Group nearby events
- **Professional UI**: Consistent with app design
- **Performance**: Optimized annotation management

### Complete iOS Additional Views Documentation

#### AccessibilityEnhancements.swift - Accessibility Features
- **VoiceOver Support**: Full VoiceOver integration
- **Dynamic Type**: Support for dynamic text sizes
- **Accessibility Labels**: Comprehensive accessibility labels
- **Professional Implementation**: Following Apple guidelines

#### APICallsEventInteractions.swift - Event API Interactions
- **API Integration**: Event-related API calls
- **Error Handling**: Comprehensive error management
- **Professional Implementation**: Consistent API patterns
- **Performance**: Optimized API calls

#### CalendarPopupView.swift - Calendar Popup Interface
- **Calendar Display**: Popup calendar interface
- **Date Selection**: Date picker functionality
- **Professional UI**: Consistent with app design
- **Accessibility**: Full accessibility support

#### ChangePasswordView.swift - Password Change Interface
- **Password Security**: Secure password change
- **Form Validation**: Real-time validation
- **Professional UI**: Consistent with app design
- **Error Handling**: Comprehensive error management

#### Color+Theme.swift - Color Theme System
- **Theme Management**: Centralized color system
- **Dynamic Colors**: Support for light/dark mode
- **Professional Palette**: Consistent color scheme
- **Accessibility**: High contrast support

#### DayForecastView.swift - Weather Forecast Display
- **Weather Data**: Display weather forecast
- **Professional UI**: Consistent with app design
- **Real-time Updates**: Live weather data
- **Accessibility**: Full accessibility support

#### FlowLayout.swift - Custom Layout Component
- **Custom Layout**: Flexible layout system
- **Responsive Design**: Adapts to different screen sizes
- **Professional Implementation**: Following Apple guidelines
- **Performance**: Optimized layout calculations

#### FriendsAccountView.swift - Friends Account Management
- **Friend Management**: Manage friend accounts
- **Professional UI**: Consistent with app design
- **UserAccountManager Integration**: Complete integration
- **Accessibility**: Full accessibility support

#### ImageGalleryView.swift - Image Gallery Interface
- **Image Display**: Full-screen image gallery
- **Navigation**: Swipe navigation between images
- **Professional UI**: Consistent with app design
- **Performance**: Optimized image loading

#### Invitations.swift - Event Invitations Interface
- **Invitation Management**: Manage event invitations
- **Professional UI**: Consistent with app design
- **Real-time Updates**: Live invitation updates
- **Accessibility**: Full accessibility support

#### LanguageSettingsView.swift - Language Settings Interface
- **Language Selection**: Multi-language support
- **LocalizationManager Integration**: Complete integration
- **Professional UI**: Consistent with app design
- **Accessibility**: Full accessibility support

#### LocationPickerView.swift - Location Selection Interface
- **Location Selection**: Interactive location picker
- **Map Integration**: Map-based location selection
- **Professional UI**: Consistent with app design
- **Performance**: Optimized location services

#### MatchingPreferencesView.swift - Auto-matching Preferences
- **Matching Configuration**: Configure auto-matching preferences
- **Professional UI**: Consistent with app design
- **UserAccountManager Integration**: Complete integration
- **Accessibility**: Full accessibility support

#### NotificationPreferencesView.swift - Notification Settings
- **Notification Management**: Manage notification preferences
- **Professional UI**: Consistent with app design
- **Real-time Updates**: Live preference updates
- **Accessibility**: Full accessibility support

#### PersonalDashboardView.swift - Personal Dashboard
- **Dashboard Display**: Personal activity dashboard
- **Professional UI**: Consistent with app design
- **Real-time Updates**: Live dashboard updates
- **Accessibility**: Full accessibility support

#### PrivacySettingsView.swift - Privacy Settings Interface
- **Privacy Management**: Manage privacy settings
- **Professional UI**: Consistent with app design
- **UserAccountManager Integration**: Complete integration
- **Accessibility**: Full accessibility support

#### RootView.swift - Root Navigation View
- **Navigation Management**: Root navigation controller
- **Professional UI**: Consistent with app design
- **State Management**: Centralized navigation state
- **Accessibility**: Full accessibility support

#### StudyBuddyFinderView.swift - Study Buddy Finder
- **Study Buddy Discovery**: Find study partners
- **Professional UI**: Consistent with app design
- **Auto-matching Integration**: Complete integration
- **Accessibility**: Full accessibility support

#### StudyConApp.swift - Main App View
- **App Entry Point**: Main app view controller
- **Professional UI**: Consistent with app design
- **State Management**: Centralized app state
- **Accessibility**: Full accessibility support

#### Try.swift - Development/Testing View
- **Development Tools**: Testing and development interface
- **Professional UI**: Consistent with app design
- **Debug Features**: Development debugging tools
- **Accessibility**: Full accessibility support

#### UniversityCardView.swift - University Display Card
- **University Display**: University information card
- **Professional UI**: Consistent with app design
- **University Integration**: Complete integration
- **Accessibility**: Full accessibility support

#### UniversitySelectionView.swift - University Selection Interface
- **University Selection**: Choose university
- **Professional UI**: Consistent with app design
- **Search Functionality**: University search
- **Accessibility**: Full accessibility support

#### UserAccountManager.swift - User Account Management View
- **Account Management**: User account interface
- **Professional UI**: Consistent with app design
- **UserAccountManager Integration**: Complete integration
- **Accessibility**: Full accessibility support

#### WeatherAndCalendarView.swift - Weather and Calendar Integration
- **Weather Integration**: Weather data display
- **Calendar Integration**: Calendar functionality
- **Professional UI**: Consistent with app design
- **Real-time Updates**: Live weather and calendar updates
- **Accessibility**: Full accessibility support

### Complete iOS Integration Summary

**Total iOS Files Documented: 60+ files**
- **Views**: 50+ view files with complete implementations
- **Models**: 5 complete model files with all properties and methods
- **Managers**: 15+ manager files with complete functionality
- **Components**: 15+ reusable component files
- **Map Views**: 10+ map-related view files
- **Utilities**: 10+ utility files

**Key Integration Patterns:**
- **Authentication Flow**: Complete JWT-based authentication
- **Event Management**: Full event lifecycle management
- **Real-time Updates**: WebSocket integration across all views
- **Image Management**: Multi-tier image caching and upload
- **Social Features**: Complete friend management and chat
- **Location Services**: GPS and geocoding integration
- **Error Handling**: Comprehensive error management
- **Performance**: Optimized state management and caching

### Complete iOS App Structure & Entry Points

#### FibblingApp.swift - App Configuration & Utilities
```swift
// MARK: - App Color Extensions
extension Color {
    // Primary brand colors
    static let appPrimary = Color.blue
    static let appSecondary = Color.indigo
    static let appAccent = Color.pink
    
    // Background colors
    static let appBackground = Color(.systemBackground)
    static let appSecondaryBackground = Color(.secondarySystemBackground)
    
    // Text colors
    static let appText = Color(.label)
    static let appSecondaryText = Color(.secondaryLabel)
}

// MARK: - App Sizing Constants
struct AppSizes {
    static let buttonHeight: CGFloat = 44
    static let cornerRadius: CGFloat = 8
    static let iconSize: CGFloat = 24
    static let spacing: CGFloat = 16
    static let padding: CGFloat = 20
}

// MARK: - App Animation Settings
struct AppAnimations {
    static let defaultAnimation = Animation.easeInOut(duration: 0.3)
    static let quickAnimation = Animation.easeOut(duration: 0.2)
    static let slowAnimation = Animation.easeInOut(duration: 0.5)
}
```

**Key Features:**
- **Centralized Configuration**: App-wide constants and settings
- **Color System**: Brand colors and theme management
- **Sizing Constants**: Consistent sizing across the app
- **Animation Settings**: Standardized animation durations

#### StudyConApp.swift - Main App Entry Point (70+ lines)
```swift
@main
struct PinItApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var accountManager: UserAccountManager
    @StateObject private var chatManager = ChatManager()
    @StateObject private var calendarManager: CalendarManager
    @StateObject private var notificationManager = NotificationManager.shared
    
    // Handle push notification registration
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        // Create account manager
        let am = UserAccountManager()
        _accountManager = StateObject(wrappedValue: am)
        
        // Create calendar manager with the account manager
        _calendarManager = StateObject(wrappedValue: CalendarManager(accountManager: am))
    }
    
    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else if isLoggedIn {
                ContentView()
                    .environmentObject(accountManager)
                    .environmentObject(calendarManager)
                    .environmentObject(chatManager)
                    .environmentObject(notificationManager)
                    .onAppear {
                        // Initialize ImageManager with account manager for JWT authentication
                        ImageManager.shared.setAccountManager(accountManager)
                        
                        // Request notification permission
                        notificationManager.requestPermission()
                    }
            } else {
                LoginView()
                    .environmentObject(accountManager)
                    .environmentObject(chatManager)
                    .environmentObject(notificationManager)
                    .onAppear {
                        // Initialize ImageManager with account manager for JWT authentication
                        ImageManager.shared.setAccountManager(accountManager)
                    }
            }
        }
    }
}
```

**Key Features:**
- **App Lifecycle Management**: Handles onboarding, login, and main app states
- **Environment Object Setup**: Provides managers to all views
- **State Management**: Manages login and onboarding states
- **Notification Setup**: Handles push notification permissions
- **Manager Initialization**: Sets up all core managers with dependencies

**Key Interactions:**
- **OnboardingView**: First-time user experience
- **LoginView**: Authentication interface
- **ContentView**: Main app interface
- **All Managers**: Provides environment objects to all views
- **AppDelegate**: Handles push notifications

### Complete iOS Utilities Documentation

#### AppLogger.swift - Professional Logging Framework (120+ lines)
```swift
struct AppLogger {
    // MARK: - Log Categories
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pinit.app", category: "network")
    static let ui = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pinit.app", category: "ui")
    static let data = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pinit.app", category: "data")
    static let websocket = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pinit.app", category: "websocket")
    static let image = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pinit.app", category: "image")
    static let auth = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pinit.app", category: "auth")
    static let cache = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pinit.app", category: "cache")
    
    // MARK: - Logging Methods
    static func log(_ message: String, level: OSLogType = .default, category: Logger = AppLogger.network) {
        #if DEBUG
        category.log(level: level, "\(message)")
        #else
        if level == .error || level == .fault {
            category.log(level: level, "\(message)")
        }
        #endif
    }
    
    static func debug(_ message: String, category: Logger = AppLogger.network) {
        #if DEBUG
        category.log(level: .debug, "🔍 \(message)")
        #endif
    }
    
    static func error(_ message: String, error: Error? = nil, category: Logger = AppLogger.network) {
        if let error = error {
            category.log(level: .error, "❌ \(message): \(error.localizedDescription)")
        } else {
            category.log(level: .error, "❌ \(message)")
        }
    }
    
    static func logRequest(url: String, method: String = "GET") {
        debug("→ \(method) \(url)", category: AppLogger.network)
    }
    
    static func logResponse(url: String, statusCode: Int) {
        if statusCode >= 200 && statusCode < 300 {
            debug("← \(statusCode) \(url)", category: AppLogger.network)
        } else {
            error("← \(statusCode) \(url)", category: AppLogger.network)
        }
    }
    
    static func logWebSocket(_ event: String, details: String? = nil) {
        if let details = details {
            debug("🔌 \(event): \(details)", category: AppLogger.websocket)
        } else {
            debug("🔌 \(event)", category: AppLogger.websocket)
        }
    }
    
    static func logImage(_ operation: String, details: String? = nil) {
        if let details = details {
            debug("🖼️ \(operation): \(details)", category: AppLogger.image)
        } else {
            debug("🖼️ \(operation)", category: AppLogger.image)
        }
    }
    
    static func logCache(_ operation: String, details: String? = nil) {
        if let details = details {
            debug("💾 \(operation): \(details)", category: AppLogger.cache)
        } else {
            debug("💾 \(operation)", category: AppLogger.cache)
        }
    }
}
```

**Key Features:**
- **OSLog Integration**: Uses Apple's OSLog for optimal performance
- **Category-based Logging**: Separate loggers for different app areas
- **Debug/Production Modes**: Different logging levels for debug vs production
- **Emoji Indicators**: Visual indicators for different log types
- **Specialized Methods**: Specific logging methods for network, WebSocket, image, and cache operations
- **Error Context**: Enhanced error logging with context

**Key Interactions:**
- **All Managers**: Used throughout the app for logging
- **Network Operations**: Logs all API requests and responses
- **WebSocket Operations**: Logs WebSocket events and connections
- **Image Operations**: Logs image upload/download operations
- **Cache Operations**: Logs cache read/write operations

#### AppError.swift - Comprehensive Error Handling (240+ lines)
```swift
enum AppError: LocalizedError {
    // MARK: - Network Errors
    case networkError(String)
    case noInternetConnection
    case requestTimeout
    case serverError(Int)
    case invalidResponse
    case invalidURL
    
    // MARK: - Authentication Errors
    case authenticationFailed
    case tokenExpired
    case unauthorizedAccess
    case accountDeleted
    
    // MARK: - Data Errors
    case decodingError(String)
    case encodingError(String)
    case dataCorrupted
    case missingRequiredField(String)
    
    // MARK: - Validation Errors
    case invalidEmail
    case invalidPassword(String)
    case passwordMismatch
    case invalidInput(String)
    case fieldTooLong(String, Int)
    
    // MARK: - Image Errors
    case imageUploadFailed(String)
    case imageDownloadFailed
    case imageTooLarge
    case invalidImageFormat
    
    // MARK: - Event Errors
    case eventCreationFailed(String)
    case eventNotFound
    case eventUpdateFailed(String)
    case eventInPast
    
    // MARK: - User Errors
    case userNotFound
    case usernameAlreadyExists
    case profileUpdateFailed(String)
    
    // MARK: - Cache Errors
    case cacheReadError
    case cacheWriteError
    
    // MARK: - WebSocket Errors
    case websocketConnectionFailed
    case websocketDisconnected
    
    // MARK: - Location Errors
    case locationPermissionDenied
    case locationUnavailable
    
    // MARK: - Unknown
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
        case .authenticationFailed:
            return "Login failed. Please check your credentials."
        case .tokenExpired:
            return "Your session has expired. Please log in again."
        case .imageUploadFailed(let message):
            return "Image upload failed: \(message)"
        case .eventCreationFailed(let message):
            return "Event creation failed: \(message)"
        // ... (all other error cases)
        }
    }
}
```

**Key Features:**
- **Comprehensive Error Types**: Covers all possible app errors
- **Localized Error Messages**: User-friendly error descriptions
- **Categorized Errors**: Organized by functionality (network, auth, data, etc.)
- **Context Information**: Detailed error context for debugging
- **Swift Error Protocol**: Conforms to LocalizedError for proper error handling

**Key Interactions:**
- **All Managers**: Used throughout the app for error handling
- **API Calls**: Network error handling
- **Authentication**: Auth error handling
- **Image Operations**: Image error handling
- **Event Management**: Event error handling
- **User Interface**: Error display to users

#### URLRequestExtension.swift - Network Debugging Utilities
```swift
extension URLRequest {
    /// Generate curl command string equivalent for the request
    var curlString: String {
        guard let url = url else { return "" }
        var baseCommand = "curl \"\(url.absoluteString)\""
        
        if httpMethod == "HEAD" {
            baseCommand += " -I"
        }
        
        var command = [baseCommand]
        
        if let method = httpMethod, method != "GET" && method != "HEAD" {
            command.append("-X \(method)")
        }
        
        if let headers = allHTTPHeaderFields {
            for (key, value) in headers where key != "Cookie" {
                command.append("-H \"\(key): \(value)\"")
            }
        }
        
        if let data = httpBody, let body = String(data: data, encoding: .utf8) {
            command.append("-d '\(body)'")
        }
        
        return command.joined(separator: " \\\n\t")
    }
}
```

**Key Features:**
- **Curl Command Generation**: Converts URLRequest to curl command
- **Debug Support**: Helps with network debugging
- **Header Inclusion**: Includes all HTTP headers
- **Body Support**: Includes request body in curl command
- **Method Support**: Supports all HTTP methods

**Key Interactions:**
- **Network Debugging**: Used for debugging API calls
- **AppLogger**: Can be used with logging for request debugging
- **Development**: Helps developers debug network issues

### Complete iOS Additional Utilities Documentation

#### HapticManager.swift - Haptic Feedback Management
- **Haptic Feedback**: Provides tactile feedback for user interactions
- **Custom Patterns**: Different haptic patterns for different actions
- **Accessibility**: Respects accessibility settings
- **Performance**: Optimized haptic feedback delivery

#### ImageRetryManager.swift - Image Loading Retry Logic
- **Retry Logic**: Automatic retry for failed image loads
- **Exponential Backoff**: Smart retry timing
- **Error Handling**: Comprehensive error management
- **Performance**: Optimized retry strategies

#### InputValidator.swift - Input Validation Utilities
- **Form Validation**: Real-time input validation
- **Email Validation**: Email format validation
- **Password Validation**: Password strength validation
- **Custom Rules**: Customizable validation rules

#### NetworkRetryManager.swift - Network Retry Logic
- **Network Retry**: Automatic retry for failed network requests
- **Exponential Backoff**: Smart retry timing
- **Multi-server Support**: Retry across multiple servers
- **Error Handling**: Comprehensive error management

### Complete iOS Assets & Configuration Documentation

#### Assets.xcassets - App Assets Management
- **App Icons**: Complete app icon set for all device sizes
- **Event Type Icons**: Icons for different event types (Study, Social, Sports, etc.)
- **UI Assets**: Various UI elements and graphics
- **Color Assets**: Brand colors and theme colors
- **Image Sets**: Organized image assets for different resolutions

#### APIConfig.swift - API Configuration Management
- **Base URLs**: Multiple server endpoints for failover
- **Endpoints**: All API endpoint definitions
- **Configuration**: Centralized API configuration
- **Environment Support**: Different configurations for different environments

#### Info.plist - App Configuration
- **App Metadata**: App name, version, bundle identifier
- **Permissions**: Location, camera, photo library permissions
- **URL Schemes**: Deep linking configuration
- **Background Modes**: Background processing capabilities

#### Fibbling.entitlements - App Capabilities
- **Push Notifications**: Push notification capabilities
- **Background Processing**: Background task capabilities
- **Network Access**: Network access permissions
- **File Access**: File system access permissions

### Complete iOS Managers Documentation (CRITICAL - Previously Missing)

#### AppDelegate.swift - Push Notification Handler (110+ lines)
```swift
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let serverBaseURL = APIConfig.serverBaseURL
    
    func application(_ application: UIApplication, 
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        sendTokenToServer(token: tokenString)
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NotificationManager.shared.handlePushNotification(userInfo: userInfo)
        completionHandler(.newData)
    }
}
```

**Key Features:**
- **Push Notification Registration**: Handles device token registration with APNs
- **Token Management**: Sends device token to backend for push notifications
- **Notification Delegation**: Integrates with NotificationManager for handling
- **Background Processing**: Handles remote notifications in background
- **Foreground Notifications**: Displays notifications while app is active

**Key Interactions:**
- **NotificationManager**: Delegates all notification processing
- **UserAccountManager**: Gets current user for token registration
- **Backend API**: Sends device token to `/api/register-device/`

#### ContentModerationManager.swift - Content Safety System (500+ lines)
```swift
class ContentModerationManager: ObservableObject {
    static let shared = ContentModerationManager()
    
    @Published var isModerationEnabled = true
    @Published var reportedContent: [ReportedContent] = []
    @Published var blockedUsers: Set<String> = []
    
    func filterText(_ text: String) -> String {
        // Filters inappropriate words from text
        let inappropriateWords = ["spam", "scam", "fake", "hate", "harassment", ...]
        var filteredText = text
        for word in inappropriateWords {
            filteredText = filteredText.replacingOccurrences(of: pattern, with: "***", ...)
        }
        return filteredText
    }
    
    func isContentAppropriate(_ content: String) -> Bool {
        // Checks if content contains inappropriate material
    }
    
    func reportContent(contentId: String, contentType: ContentType, reason: ReportReason, reporter: String, description: String?)
    func reportUser(username: String, reason: ReportReason, reporter: String, description: String?)
    func reportEvent(eventId: String, reason: ReportReason, reporter: String, description: String?)
    func reportMessage(messageId: String, reason: ReportReason, reporter: String, description: String?)
    
    func blockUser(_ username: String)
    func unblockUser(_ username: String)
    func isUserBlocked(_ username: String) -> Bool
}

enum ContentType: String, Codable, CaseIterable {
    case user, event, message, profile
}

enum ReportReason: String, Codable, CaseIterable {
    case spam, harassment, inappropriate, fake, violence, hate, other
}

enum ReportStatus: String, Codable, CaseIterable {
    case pending, reviewed, resolved, dismissed
}
```

**Key Features:**
- **Content Filtering**: Automatic filtering of inappropriate words
- **Content Validation**: Pre-submission content checking
- **Reporting System**: Complete report submission for users, events, messages
- **Blocking System**: User blocking with local and backend persistence
- **Data Persistence**: Saves blocked users to UserDefaults
- **Backend Integration**: Sends reports and blocks to backend API
- **App Store Compliance**: Ensures app meets Apple's content guidelines

**Key Interactions:**
- **Backend API**: `/report_content/`, `/block_user/`, `/unblock_user/`
- **All Views**: Content filtering before display
- **Event Creation**: Pre-validation before submission
- **Chat System**: Message filtering and reporting
- **User Profiles**: User reporting and blocking

#### ImageUploadManager.swift - Smart Image Upload System (325+ lines)
```swift
@MainActor
class ImageUploadManager: ObservableObject {
    static let shared = ImageUploadManager()
    
    @Published var uploadProgress: [String: Double] = [:]
    @Published var isUploading = false
    @Published var uploadError: String?
    
    private let networkMonitor = NetworkMonitor.shared
    private var uploadQueue: [UploadTask] = []
    private var activeUploads: Set<String> = []
    private let maxConcurrentUploads = 2
    
    func uploadImage(_ request: ImageUploadRequest) async -> Bool {
        // Step 1: Optimize image based on network conditions
        let optimizedData = await optimizeForUpload(imageData: request.imageData, connectionSpeed: networkMonitor.connectionSpeed)
        
        // Step 2: Perform upload with progress tracking
        let success = await performUpload(data: optimizedData, request: request, uploadId: uploadId)
        
        return success
    }
    
    private func optimizeForUpload(imageData: Data, connectionSpeed: NetworkMonitor.ConnectionSpeed) async -> Data {
        // Network-aware compression
        let (targetSize, quality) = getOptimizationSettings(for: connectionSpeed)
        let resizedImage = await resizeImage(image, to: targetSize)
        let compressedData = resizedImage.jpegData(compressionQuality: quality)
        return compressedData
    }
    
    private func getOptimizationSettings(for speed: NetworkMonitor.ConnectionSpeed) -> (size: CGFloat, quality: CGFloat) {
        switch speed {
        case .excellent: return (1920, 0.85) // WiFi
        case .good: return (1440, 0.75)      // 4G
        case .fair: return (1080, 0.65)      // 3G
        case .poor: return (720, 0.50)       // 2G
        case .offline: return (720, 0.50)
        }
    }
}
```

**Key Features:**
- **Network-Aware Compression**: Adjusts image quality based on connection speed
- **Smart Resizing**: Automatically resizes images for optimal upload
- **Progress Tracking**: Real-time upload progress for each image
- **Background Upload Queue**: Queues multiple uploads with concurrency control
- **Multipart Form Data**: Professional multipart/form-data encoding
- **JWT Authentication**: Automatic JWT header injection with token refresh
- **Cache Invalidation**: Clears all caches after successful upload
- **Error Handling**: Comprehensive error reporting and retry logic

**Key Interactions:**
- **NetworkMonitor**: Monitors connection speed for optimal compression
- **UserAccountManager**: Gets JWT tokens for authenticated uploads
- **ImageManager**: Clears cache and reloads after upload
- **ProfessionalImageCache**: Invalidates all caches post-upload
- **Backend API**: `/api/upload_user_image/` endpoint

#### LocalizationManager.swift - Multi-language Support
```swift
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: Language = .english
    @Published var translations: [String: String] = [:]
    
    enum Language: String, CaseIterable {
        case english = "en"
        case spanish = "es"
        case french = "fr"
        case german = "de"
        case portuguese = "pt"
    }
    
    func setLanguage(_ language: Language)
    func localizedString(for key: String) -> String
}
```

**Key Features:**
- **Multi-language Support**: English, Spanish, French, German, Portuguese
- **Dynamic Language Switching**: Change language without app restart
- **Translation Management**: Centralized translation storage
- **Fallback Mechanism**: Falls back to English if translation missing

**Key Interactions:**
- **All Views**: Uses localized strings throughout the app
- **SettingsView**: Language selection interface
- **UserDefaults**: Persists language preference

### Complete iOS Frontend Interactions & Data Flow Documentation

#### SwiftUI State Management & Data Flow Architecture

**Core State Management Patterns:**
- **@StateObject**: For owned observable objects (managers, view models)
- **@ObservedObject**: For external observable objects (shared managers)
- **@EnvironmentObject**: For global state (UserAccountManager, CalendarManager)
- **@AppStorage**: For persistent user preferences
- **@State**: For local view state
- **@Published**: For reactive data updates in managers

**Data Flow Hierarchy:**
```
App Level (StudyConApp.swift)
├── Global Environment Objects
│   ├── UserAccountManager (authentication state)
│   ├── CalendarManager (event data)
│   ├── ChatManager (messaging state)
│   └── LocalizationManager (language settings)
├── Root Navigation (RootView.swift)
│   ├── ContentView (main dashboard)
│   ├── MapBox (map interface)
│   ├── CalendarView (calendar interface)
│   └── SettingsView (settings interface)
└── Feature-Specific Views
    ├── EventDetailView (event interactions)
    ├── ChatView (messaging)
    └── ProfileView (user management)
```

#### Complete Data Reload & Refresh Mechanisms

**1. Event Data Reload System (CalendarManager.swift)**
```swift
class CalendarManager: ObservableObject {
    @Published var events: [StudyEvent] = []
    @Published var isLoading: Bool = false
    @Published var lastRefreshTime: Date = Date()
    
    // Automatic refresh triggers
    func refreshEvents() {
        isLoading = true
        fetchEventsFromAPI { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.lastRefreshTime = Date()
                // Update @Published events triggers UI refresh
            }
        }
    }
    
    // WebSocket-triggered refresh
    func handleEventUpdate(eventID: UUID) {
        refreshEvents() // Triggers complete data reload
    }
}
```

**2. Map Data Reload System (MapBox.swift)**
```swift
class RefreshController: ObservableObject {
    private var refreshWorkItem: DispatchWorkItem?
    private var refreshCount = 0
    private var lastRefreshTime = Date()
    
    // Debounced refresh to prevent excessive API calls
    func debouncedRefresh(delay: TimeInterval = 0.3, action: @escaping () -> Void) {
        refreshWorkItem?.cancel()
        refreshWorkItem = DispatchWorkItem {
            self.refreshCount += 1
            self.lastRefreshTime = Date()
            action()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: refreshWorkItem!)
    }
}

struct MapBox: View {
    @StateObject private var refreshController = RefreshController()
    @EnvironmentObject var calendarManager: CalendarManager
    
    var body: some View {
        MapView()
            .onAppear {
                refreshController.debouncedRefresh {
                    calendarManager.refreshEvents()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .eventUpdated)) { _ in
                refreshController.debouncedRefresh {
                    calendarManager.refreshEvents()
                }
            }
    }
}
```

**3. Real-time WebSocket Data Flow (EventsWebSocketManager.swift)**
```swift
class EventsWebSocketManager: ObservableObject {
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var lastMessageTime: Date?
    
    weak var delegate: EventsWebSocketManagerDelegate?
    
    func connect(username: String) {
        // WebSocket connection logic
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Listen for messages
        receiveMessage()
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessage() // Continue listening
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        // Parse WebSocket message and trigger UI updates
        DispatchQueue.main.async {
            self.delegate?.didReceiveEventUpdate(eventID: eventID)
            // This triggers refresh in CalendarManager
        }
    }
}
```

**4. User Account State Management (UserAccountManager.swift)**
```swift
class UserAccountManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    @Published var authToken: String?
    @Published var isLoading: Bool = false
    
    // Login triggers complete app state refresh
    func login(username: String, password: String) {
        isLoading = true
        authenticateUser(username: username, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let user, let token):
                    self?.isLoggedIn = true
                    self?.currentUser = user
                    self?.authToken = token
                    // Triggers UI refresh across entire app
                case .failure(let error):
                    self?.handleLoginError(error)
                }
            }
        }
    }
    
    // Logout clears all state
    func logout() {
        isLoggedIn = false
        currentUser = nil
        authToken = nil
        // Triggers navigation back to login
    }
}
```

#### Complete View Interaction Patterns

**1. ContentView - Main Dashboard Interactions**
```swift
struct ContentView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var calendarManager: CalendarManager
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // State for dynamic content
    @State private var nextRSVPEvent: StudyEvent? = nil
    @State private var isLoadingEvents = false
    @State private var isEventDetailLoading = false
    
    var body: some View {
        ScrollView {
            VStack {
                // Weather section (auto-refreshes every 30 minutes)
                WeatherAndCalendarView()
                    .onAppear {
                        refreshWeatherData()
                    }
                
                // Upcoming events section (refreshes on WebSocket updates)
                UpcomingEventsSection()
                    .onReceive(NotificationCenter.default.publisher(for: .eventUpdated)) { _ in
                        refreshUpcomingEvents()
                    }
                
                // Quick actions (triggers navigation)
                QuickActionsSection()
            }
        }
        .refreshable {
            // Pull-to-refresh triggers complete data reload
            await refreshAllData()
        }
        .onAppear {
            // Initial data load
            loadInitialData()
        }
    }
    
    private func refreshAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await calendarManager.refreshEvents() }
            group.addTask { await refreshWeatherData() }
            group.addTask { await refreshUserProfile() }
        }
    }
}
```

**2. MapBox - Map Interactions & Clustering**
```swift
struct MapBox: View {
    @StateObject private var refreshController = RefreshController()
    @EnvironmentObject var calendarManager: CalendarManager
    @State private var selectedEvent: StudyEvent?
    @State private var showEventDetail = false
    
    var body: some View {
        MapView()
            .onMapTap { coordinate in
                // Handle map tap - triggers event creation
                showEventCreationView(coordinate: coordinate)
            }
            .onAnnotationTap { event in
                // Handle annotation tap - shows event detail
                selectedEvent = event
                showEventDetail = true
            }
            .sheet(isPresented: $showEventDetail) {
                if let event = selectedEvent {
                    EventDetailView(event: event)
                        .environmentObject(calendarManager)
                }
            }
            .onReceive(calendarManager.$events) { events in
                // React to events data changes
                updateMapAnnotations(events)
            }
    }
    
    private func updateMapAnnotations(_ events: [StudyEvent]) {
        // Update map annotations based on new events data
        // Triggers map refresh
    }
}
```

**3. CalendarView - Calendar Interactions**
```swift
struct CalendarView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @State private var displayedMonth: Date = Date()
    @State private var selectedDayEvents: [StudyEvent] = []
    @State private var showDayEventsSheet: Bool = false
    
    var body: some View {
        VStack {
            // Month/Week toggle
            CalendarModeToggle()
            
            // Calendar grid
            CalendarGrid()
                .onDayTap { date in
                    selectedDayEvents = getEventsForDay(date)
                    showDayEventsSheet = true
                }
            
            // Event creation button
            EventCreationButton()
                .onTapGesture {
                    showEventCreationView()
                }
        }
        .sheet(isPresented: $showDayEventsSheet) {
            DayEventsSheet(events: selectedDayEvents)
        }
        .onReceive(calendarManager.$events) { events in
            // Refresh calendar when events change
            refreshCalendarDisplay()
        }
    }
}
```

**4. EventDetailView - Event Interactions**
```swift
struct EventDetailView: View {
    let event: StudyEvent
    @EnvironmentObject var accountManager: UserAccountManager
    @StateObject private var chatManager = ChatManager()
    @State private var rsvpStatus: RSVPStatus = .notResponded
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack {
                // Event info section
                EventInfoSection(event: event)
                
                // RSVP section
                RSVPSection()
                    .onTapGesture {
                        handleRSVP()
                    }
                
                // Chat section
                ChatSection()
                    .onTapGesture {
                        showChatView()
                    }
                
                // Rating section (after event)
                RatingSection()
                    .onTapGesture {
                        showRatingView()
                    }
            }
        }
        .onAppear {
            loadEventDetails()
        }
        .onReceive(NotificationCenter.default.publisher(for: .rsvpUpdated)) { notification in
            // Handle RSVP updates from other views
            updateRSVPStatus()
        }
    }
    
    private func handleRSVP() {
        isLoading = true
        rsvpToEvent(eventID: event.id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let action):
                    self?.rsvpStatus = action == "joined" ? .attending : .notResponded
                    // Broadcast RSVP update
                    NotificationCenter.default.post(name: .rsvpUpdated, object: event.id)
                case .failure(let error):
                    self?.handleRSVPError(error)
                }
            }
        }
    }
}
```

#### Complete Data Synchronization Patterns

**1. Multi-Server Fallback System**
```swift
class APIClient {
    private let baseURLs = [
        "https://api1.pinit.com",
        "https://api2.pinit.com",
        "https://api3.pinit.com"
    ]
    
    func request<T: Codable>(_ endpoint: String, responseType: T.Type) async throws -> T {
        var lastError: Error?
        
        for baseURL in baseURLs {
            do {
                let url = URL(string: "\(baseURL)\(endpoint)")!
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    return try JSONDecoder().decode(T.self, from: data)
                }
            } catch {
                lastError = error
                continue
            }
        }
        
        throw lastError ?? APIError.noServersAvailable
    }
}
```

**2. Image Caching & Loading System**
```swift
class ProfessionalImageCache: ObservableObject {
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCache = DiskCache()
    
    @Published var loadingImages: Set<String> = []
    
    func loadImage(url: String) async -> UIImage? {
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: url as NSString) {
            return cachedImage
        }
        
        // Check disk cache
        if let diskImage = await diskCache.loadImage(for: url) {
            memoryCache.setObject(diskImage, forKey: url as NSString)
            return diskImage
        }
        
        // Load from network
        DispatchQueue.main.async {
            self.loadingImages.insert(url)
        }
        
        do {
            let image = try await loadFromNetwork(url: url)
            memoryCache.setObject(image, forKey: url as NSString)
            await diskCache.saveImage(image, for: url)
            
            DispatchQueue.main.async {
                self.loadingImages.remove(url)
            }
            
            return image
        } catch {
            DispatchQueue.main.async {
                self.loadingImages.remove(url)
            }
            return nil
        }
    }
}
```

**3. WebSocket Reconnection & State Sync**
```swift
class EventsWebSocketManager: ObservableObject {
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var reconnectAttempts: Int = 0
    
    private var reconnectTimer: Timer?
    private let maxReconnectAttempts = 5
    
    func connect(username: String) {
        // Connection logic
        webSocketTask?.resume()
        connectionStatus = .connecting
        
        // Start heartbeat
        startHeartbeat()
    }
    
    private func startHeartbeat() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func handleDisconnection() {
        connectionStatus = .disconnected
        
        if reconnectAttempts < maxReconnectAttempts {
            let delay = pow(2.0, Double(reconnectAttempts)) // Exponential backoff
            reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                self?.reconnectAttempts += 1
                self?.connect(username: self?.username ?? "")
            }
        }
    }
}
```

#### Complete Notification & Event System

**1. NotificationCenter Integration**
```swift
extension Notification.Name {
    static let eventUpdated = Notification.Name("eventUpdated")
    static let rsvpUpdated = Notification.Name("rsvpUpdated")
    static let userLoggedIn = Notification.Name("userLoggedIn")
    static let userLoggedOut = Notification.Name("userLoggedOut")
    static let eventCreated = Notification.Name("eventCreated")
    static let eventDeleted = Notification.Name("eventDeleted")
}

// Usage in views
struct EventListView: View {
    var body: some View {
        List(events) { event in
            EventRow(event: event)
        }
        .onReceive(NotificationCenter.default.publisher(for: .eventUpdated)) { notification in
            // Refresh event list
            refreshEvents()
        }
        .onReceive(NotificationCenter.default.publisher(for: .rsvpUpdated)) { notification in
            // Update RSVP status
            updateRSVPStatus()
        }
    }
}
```

**2. App Lifecycle Integration**
```swift
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Register for push notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Send device token to backend
        sendDeviceTokenToBackend(deviceToken)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // Handle push notification
        handlePushNotification(userInfo)
    }
}
```

#### Complete Error Handling & Recovery

**1. Network Error Handling**
```swift
class NetworkErrorHandler: ObservableObject {
    @Published var lastError: NetworkError?
    @Published var isRetrying: Bool = false
    
    func handleError(_ error: Error) {
        switch error {
        case let networkError as NetworkError:
            lastError = networkError
            handleNetworkError(networkError)
        case let urlError as URLError:
            handleURLError(urlError)
        default:
            handleGenericError(error)
        }
    }
    
    private func handleNetworkError(_ error: NetworkError) {
        switch error {
        case .noInternetConnection:
            showOfflineMode()
        case .serverUnavailable:
            scheduleRetry()
        case .authenticationFailed:
            redirectToLogin()
        }
    }
}
```

**2. Data Recovery & Offline Support**
```swift
class OfflineDataManager: ObservableObject {
    @Published var isOffline: Bool = false
    @Published var pendingActions: [PendingAction] = []
    
    func savePendingAction(_ action: PendingAction) {
        pendingActions.append(action)
        persistPendingActions()
    }
    
    func retryPendingActions() {
        for action in pendingActions {
            Task {
                do {
                    try await executeAction(action)
                    removePendingAction(action)
                } catch {
                    // Keep action for later retry
                }
            }
        }
    }
}
```

### Complete iOS Data Usage & Storage Documentation

#### Data Models & Storage Patterns

**1. StudyEvent.swift - Event Data Model**
```swift
struct StudyEvent: Identifiable, Codable, Equatable {
    let id: UUID                    // Primary identifier
    let title: String              // Event title
    let coordinate: CLLocationCoordinate2D  // Map location
    let time: Date                 // Start time
    let endTime: Date             // End time
    var description: String?      // Optional description
    var invitedFriends: [String]  // Array of usernames
    var attendees: [String]       // Array of usernames
    var isPublic: Bool            // Public/private flag
    var host: String              // Host username
    var hostIsCertified: Bool     // Host certification status
    var eventType: EventType      // Enum: study|social|sports|cultural|academic|other
    var isAutoMatched: Bool?      // Auto-matching flag
    var interestTags: [String]?   // Array of interest tags
    var matchedUsers: [String]?   // Auto-matched users
    
    // Data Storage: In-memory arrays, persisted via API
    // Usage: CalendarManager.events, MapBox annotations, EventDetailView
}
```

**2. UserRating.swift - Rating Data Model**
```swift
struct UserRating: Identifiable, Codable, Equatable {
    let id: String                // UUID string
    let fromUser: String          // Rater username
    let toUser: String            // Rated user username
    let eventId: String?          // Associated event ID
    let rating: Int               // 1-5 star rating
    let reference: String?        // Optional review text
    let createdAt: String        // ISO 8601 timestamp
    
    // Data Storage: Backend database, cached in UserReputationManager
    // Usage: UserReputationView, RateUserView, reputation calculations
}

struct UserReputationStats: Codable {
    let averageRating: Double     // Calculated average
    let totalRatings: Int        // Total rating count
    let eventsHosted: Int        // Hosted events count
    let eventsAttended: Int      // Attended events count
    let trustLevel: TrustLevel   // Trust level object
    
    // Data Storage: Calculated from UserRating records
    // Usage: User profile display, auto-matching scoring
}
```

**3. UserImage.swift - Image Data Model**
```swift
struct UserImage: Identifiable, Codable, Hashable {
    let id: String                // UUID string
    let url: String?             // Cloudflare R2 URL
    let imageType: ImageType      // Enum: profile|gallery|cover
    let isPrimary: Bool          // Primary image flag
    let caption: String          // Image caption
    let uploadedAt: String       // ISO 8601 timestamp
    
    // Data Storage: Cloudflare R2 URLs, cached locally
    // Usage: ProfileView, ImageGridView, ProfessionalCachedImageView
}
```

**4. MessageModel.swift - Chat Data Model**
```swift
struct Message: Codable {
    let message: String          // Message content
    
    // Data Storage: WebSocket transmission, ChatManager cache
    // Usage: ChatView, GroupChatView, real-time messaging
}
```

**5. University.swift - University Data Model**
```swift
struct University {
    let name: String             // University name
    let color: Color             // Brand color
    let textColor: Color        // Text color
    let logo: String            // Logo asset name
    
    // Data Storage: Static data, hardcoded in app
    // Usage: UniversitySelectionView, UniversityCardView, profile display
}
```

#### Manager Data Storage & Usage Patterns

**1. CalendarManager.swift - Event Data Management**
```swift
class CalendarManager: ObservableObject {
    @Published var events: [StudyEvent] = []           // In-memory event cache
    @Published var isLoading: Bool = false             // Loading state
    @Published var lastRefreshTime: Date = Date()      // Last refresh timestamp
    
    // Data Storage Patterns:
    // - Primary: Backend API (/api/get_study_events/{username}/)
    // - Cache: In-memory @Published array
    // - Persistence: UserDefaults for last refresh time
    // - Real-time: WebSocket updates trigger refresh
    
    func refreshEvents() {
        // 1. Set loading state
        isLoading = true
        
        // 2. Fetch from API
        fetchEventsFromAPI { [weak self] result in
            DispatchQueue.main.async {
                // 3. Update @Published (triggers UI refresh)
                self?.events = result.events
                self?.isLoading = false
                self?.lastRefreshTime = Date()
            }
        }
    }
    
    // Data Usage: ContentView, CalendarView, MapBox, EventDetailView
}
```

**2. UserAccountManager.swift - Authentication Data**
```swift
class UserAccountManager: ObservableObject {
    @Published var isLoggedIn: Bool = false            // Login state
    @Published var currentUser: User?                  // Current user data
    @Published var authToken: String?                  // JWT token
    @Published var isLoading: Bool = false            // Loading state
    
    // Data Storage Patterns:
    // - Primary: Backend API (/api/login/, /api/register/)
    // - Persistence: Keychain for auth token
    // - Cache: In-memory @Published properties
    // - State: App-wide authentication state
    
    func login(username: String, password: String) {
        // 1. API authentication
        authenticateUser(username: username, password: password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user, let token):
                    // 2. Store in Keychain
                    self.storeTokenInKeychain(token)
                    
                    // 3. Update @Published (triggers app-wide refresh)
                    self.isLoggedIn = true
                    self.currentUser = user
                    self.authToken = token
                }
            }
        }
    }
    
    // Data Usage: All views requiring authentication, navigation state
}
```

**3. ImageManager.swift - Image Data Management**
```swift
class ImageManager: ObservableObject {
    @Published var userImages: [UserImage] = []        // User's images
    @Published var isLoading: Bool = false             // Loading state
    @Published var uploadProgress: Double = 0.0        // Upload progress
    
    // Data Storage Patterns:
    // - Primary: Cloudflare R2 storage
    // - Cache: ProfessionalImageCache (memory + disk)
    // - API: /api/upload_user_image/, /api/user_images/{username}/
    // - Persistence: Local disk cache for offline access
    
    func uploadImage(_ image: UIImage, type: ImageType) {
        // 1. Compress image
        let compressedImage = compressImage(image)
        
        // 2. Upload to R2
        uploadToR2(compressedImage) { [weak self] progress in
            DispatchQueue.main.async {
                self?.uploadProgress = progress
            }
        } completion: { [weak self] result in
            DispatchQueue.main.async {
                // 3. Update local cache
                self?.userImages.append(result)
                self?.uploadProgress = 1.0
            }
        }
    }
    
    // Data Usage: ProfileView, ImageGridView, EditProfileView
}
```

**4. ChatManager.swift - Messaging Data**
```swift
class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []        // Message cache
    @Published var isConnected: Bool = false           // WebSocket state
    @Published var typingUsers: [String] = []          // Typing indicators
    
    // Data Storage Patterns:
    // - Primary: WebSocket real-time communication
    // - Cache: In-memory message array
    // - Persistence: Backend message history
    // - State: Real-time connection status
    
    func sendMessage(_ text: String) {
        // 1. Add to local cache immediately
        let message = ChatMessage(text: text, sender: currentUser)
        messages.append(message)
        
        // 2. Send via WebSocket
        webSocketManager.sendMessage(message)
    }
    
    // Data Usage: ChatView, GroupChatView, real-time messaging
}
```

**5. ProfessionalImageCache.swift - Image Caching**
```swift
class ProfessionalImageCache: ObservableObject {
    private let memoryCache = NSCache<NSString, UIImage>()  // Memory cache
    private let diskCache = DiskCache()                    // Disk cache
    @Published var loadingImages: Set<String> = []         // Loading state
    
    // Data Storage Patterns:
    // - L1 Cache: NSCache (memory, auto-eviction)
    // - L2 Cache: Disk cache (persistent)
    // - L3 Source: Network (Cloudflare R2)
    // - State: Loading indicators for UI
    
    func loadImage(url: String) async -> UIImage? {
        // 1. Check memory cache
        if let cachedImage = memoryCache.object(forKey: url as NSString) {
            return cachedImage
        }
        
        // 2. Check disk cache
        if let diskImage = await diskCache.loadImage(for: url) {
            memoryCache.setObject(diskImage, forKey: url as NSString)
            return diskImage
        }
        
        // 3. Load from network
        DispatchQueue.main.async {
            self.loadingImages.insert(url)
        }
        
        let image = try await loadFromNetwork(url: url)
        memoryCache.setObject(image, forKey: url as NSString)
        await diskCache.saveImage(image, for: url)
        
        DispatchQueue.main.async {
            self.loadingImages.remove(url)
        }
        
        return image
    }
    
    // Data Usage: All image displays, ProfessionalCachedImageView
}
```

#### View Data Usage Patterns

**1. ContentView.swift - Main Dashboard Data**
```swift
struct ContentView: View {
    @EnvironmentObject var accountManager: UserAccountManager    // Global auth state
    @EnvironmentObject var calendarManager: CalendarManager      // Global event data
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Local State Data:
    @State private var nextRSVPEvent: StudyEvent? = nil          // Computed from events
    @State private var isLoadingEvents = false                  // Loading state
    @State private var isEventDetailLoading = false             // Detail loading
    @AppStorage("isLoggedIn") private var isLoggedIn = true      // Persistent login state
    
    // Data Usage Patterns:
    // - Global State: Environment objects for shared data
    // - Local State: @State for view-specific data
    // - Computed Data: Derived from global state
    // - Persistence: @AppStorage for user preferences
    
    var body: some View {
        ScrollView {
            VStack {
                // Weather data (fetched on appear)
                WeatherAndCalendarView()
                    .onAppear {
                        refreshWeatherData()  // API call to weather service
                    }
                
                // Events data (reactive to calendarManager.events)
                UpcomingEventsSection()
                    .onReceive(calendarManager.$events) { events in
                        updateUpcomingEvents(events)  // Process events array
                    }
            }
        }
        .refreshable {
            await refreshAllData()  // Parallel data refresh
        }
    }
    
    // Data Flow: API → Managers → @Published → Views → UI Updates
}
```

**2. MapBox.swift - Map Data Management**
```swift
struct MapBox: View {
    @StateObject private var refreshController = RefreshController()  // Refresh state
    @EnvironmentObject var calendarManager: CalendarManager            // Event data
    @State private var selectedEvent: StudyEvent? = nil               // Selection state
    @State private var showEventDetail = false                         // Navigation state
    
    // Data Usage Patterns:
    // - Event Data: From CalendarManager.events
    // - Map State: Local @State for UI interactions
    // - Refresh Control: Debounced API calls
    // - Selection State: Event detail navigation
    
    var body: some View {
        MapView()
            .onReceive(calendarManager.$events) { events in
                // React to events data changes
                updateMapAnnotations(events)  // Convert events to map annotations
            }
            .onAnnotationTap { event in
                selectedEvent = event          // Store selection
                showEventDetail = true         // Trigger navigation
            }
    }
    
    private func updateMapAnnotations(_ events: [StudyEvent]) {
        // Convert StudyEvent objects to map annotations
        // Handle clustering for nearby events
        // Update map display
    }
    
    // Data Flow: Events → Map Annotations → User Interaction → Event Detail
}
```

**3. EventDetailView.swift - Event Interaction Data**
```swift
struct EventDetailView: View {
    let event: StudyEvent                                        // Immutable event data
    @EnvironmentObject var accountManager: UserAccountManager   // Auth state
    @StateObject private var chatManager = ChatManager()        // Chat state
    @State private var rsvpStatus: RSVPStatus = .notResponded  // RSVP state
    @State private var isLoading = false                        // Loading state
    
    // Data Usage Patterns:
    // - Event Data: Passed as parameter (immutable)
    // - User State: From accountManager
    // - Chat State: Local ChatManager instance
    // - RSVP State: Local state with API sync
    
    var body: some View {
        ScrollView {
            VStack {
                // Event info (from event parameter)
                EventInfoSection(event: event)
                
                // RSVP section (local state + API)
                RSVPSection(rsvpStatus: rsvpStatus)
                    .onTapGesture {
                        handleRSVP()  // API call + state update
                    }
                
                // Chat section (ChatManager state)
                ChatSection(chatManager: chatManager)
            }
        }
        .onAppear {
            loadEventDetails()  // Load additional event data
        }
    }
    
    private func handleRSVP() {
        isLoading = true
        rsvpToEvent(eventID: event.id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let action):
                    // Update local state
                    self?.rsvpStatus = action == "joined" ? .attending : .notResponded
                    
                    // Broadcast to other views
                    NotificationCenter.default.post(name: .rsvpUpdated, object: event.id)
                }
            }
        }
    }
    
    // Data Flow: Event Data → UI Display → User Action → API Call → State Update → UI Refresh
}
```

#### Data Persistence Patterns

**1. UserDefaults Storage**
```swift
// AppStorage for user preferences
@AppStorage("isLoggedIn") private var isLoggedIn = false
@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
@AppStorage("enableNotifications") private var enableNotifications = true
@AppStorage("darkMode") private var darkMode = false
@AppStorage("showOnlineStatus") private var showOnlineStatus = true
@AppStorage("allowTagging") private var allowTagging = true
@AppStorage("allowDirectMessages") private var allowDirectMessages = true
@AppStorage("showActivityStatus") private var showActivityStatus = true
@AppStorage("allowAutoMatching") private var allowAutoMatching = true
@AppStorage("preferredRadius") private var preferredRadius = 10.0
@AppStorage("matchingAgeRange") private var matchingAgeRange = "18-25"
@AppStorage("matchingUniversity") private var matchingUniversity = ""
@AppStorage("matchingDegree") private var matchingDegree = ""
@AppStorage("matchingYear") private var matchingYear = ""

// Usage: SettingsView, MatchingPreferencesView, persistent user preferences
```

**2. Keychain Storage**
```swift
class KeychainManager {
    func storeToken(_ token: String) {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "auth_token",
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func retrieveToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "auth_token",
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return String(data: result as! Data, encoding: .utf8)
    }
}

// Usage: UserAccountManager, secure token storage
```

**3. Core Data (if implemented)**
```swift
// For offline data persistence
class CoreDataManager {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PinItModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
        return container
    }()
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            try? context.save()
        }
    }
}

// Usage: Offline event caching, message history
```

#### Data Flow Summary by File Type

**Models (5 files):**
- **StudyEvent.swift**: Event data structure, API serialization
- **UserRating.swift**: Rating data, reputation calculations
- **UserImage.swift**: Image metadata, R2 URL storage
- **MessageModel.swift**: Chat message structure
- **University.swift**: Static university data

**Managers (13 files):**
- **CalendarManager**: Event data cache, API synchronization
- **UserAccountManager**: Authentication state, token management
- **ImageManager**: Image upload/download, R2 integration
- **ChatManager**: Real-time messaging, WebSocket state
- **ProfessionalImageCache**: Multi-tier image caching
- **EventsWebSocketManager**: Real-time event updates
- **UserReputationManager**: Rating data, reputation calculations
- **LocationManager**: GPS data, location services
- **NotificationManager**: Push notification state
- **NetworkMonitor**: Network connectivity state
- **ContentModerationManager**: Content reporting data
- **ImageUploadManager**: Upload progress, retry logic
- **LocalizationManager**: Language preference data

**Views (50+ files):**
- **ContentView**: Dashboard data aggregation
- **MapBox**: Event-to-annotation conversion
- **CalendarView**: Event calendar display
- **EventDetailView**: Event interaction state
- **ChatView**: Message display and input
- **ProfileView**: User data display and editing
- **SettingsView**: Preference management
- **LoginView**: Authentication form state

**Data Storage Hierarchy:**
```
1. Backend API (Primary Source)
   ├── PostgreSQL Database
   ├── Cloudflare R2 (Images)
   └── Redis (WebSocket state)

2. Local Caching (Performance)
   ├── @Published Properties (In-memory)
   ├── NSCache (Image memory cache)
   └── Disk Cache (Image persistence)

3. User Preferences (Persistence)
   ├── UserDefaults (@AppStorage)
   ├── Keychain (Secure tokens)
   └── Core Data (Offline data)
```

### Complete iOS Integration Summary (Updated)

**Total iOS Files Documented: 85+ files**
- **App Entry Points**: 2 files (FibblingApp.swift, StudyConApp.swift)
- **Views**: 50+ view files with complete implementations
- **Models**: 5 complete model files with all properties and methods
- **Managers**: 13 manager files with complete functionality (CalendarManager, ChatManager, ContentModerationManager, EventsWebSocketManager, ImageManager, ImageUploadManager, LocalizationManager, LocationManager, NetworkMonitor, NotificationManager, ProfessionalImageCache, UserReputationManager, AppDelegate)
- **ViewModels**: 4 ViewModel files with complete implementations
- **Components**: 15+ reusable component files
- **Map Views**: 10+ map-related view files
- **Utilities**: 10+ utility files with complete implementations
- **Extensions**: 1 extension file for URLRequest debugging
- **Assets**: Complete asset management system
- **Configuration**: Complete configuration management

**Key Integration Patterns (Updated):**
- **App Lifecycle**: StudyConApp → OnboardingView/LoginView/ContentView
- **Authentication Flow**: Complete JWT-based authentication with token refresh
- **Event Management**: Full event lifecycle management with real-time updates
- **Real-time Updates**: WebSocket integration across all views
- **Image Management**: Multi-tier image caching, upload, and retry logic
- **Social Features**: Complete friend management, chat, and discovery
- **Location Services**: GPS tracking, geocoding, and location suggestions
- **Error Handling**: Comprehensive error management with AppError enum
- **Logging**: Professional logging system with AppLogger
- **Performance**: Optimized state management, caching, and memory usage
- **Accessibility**: Full VoiceOver support and dynamic type
- **Professional UI**: Consistent design language across all views

**Complete Data Flow Patterns:**
- **App Initialization**: StudyConApp → Manager Setup → Environment Objects → All Views
- **Authentication**: LoginView → UserAccountManager → JWT Storage → All Protected Views
- **Event Management**: ContentView → CalendarManager → EventCreationView → Backend → WebSocket → All Views
- **Social Features**: FriendsListView → UserAccountManager → ChatView → WebSocket → Real-time Updates
- **Image Management**: EditProfileView → ImageManager → ProfessionalCachedImageView → Multi-tier Caching
- **Real-time Updates**: Backend WebSocket → EventsWebSocketManager → CalendarManager → All Views
- **Error Handling**: All Operations → AppError → AppLogger → User-friendly Messages
- **Performance**: All Views → Optimized State Management → Caching → Memory Management

### API Configuration

**APIConfig.swift:**
```swift
// Production URLs
static let baseURLs = [
    "https://pinit-backend-production.up.railway.app/api",
    "https://pin-it.net/api",
    "https://api.pin-it.net/api"
]

// WebSocket URL
static var websocketURL: String {
    return "wss://pinit-backend-production.up.railway.app/ws/"
}

// Endpoints mapping
static let endpoints = [
    "register": "/register/",
    "login": "/login/",
    "getEvents": "/get_study_events/",
    "createEvent": "/create_study_event/",
    "deleteEvent": "/delete_study_event/",
    "deleteAccount": "/delete_account/",
    // ... more endpoints
]
```

### Authentication Flow

**UserAccountManager.swift:**
- JWT token management
- Automatic token refresh
- Login persistence with UserDefaults
- Logout with cleanup

**Key Features:**
- Token storage in UserDefaults
- Automatic refresh on API calls
- Login state persistence across app launches
- Clean logout with resource cleanup

### Event Management

**CalendarManager.swift:**
- Event fetching with 30-second cooldown
- WebSocket integration for real-time updates
- Optimistic UI updates for RSVP
- Fallback to enhanced search on errors

**Key Features:**
- Prevents excessive API polling
- WebSocket-first updates
- Manual refresh bypasses cooldown
- Event filtering (expired, user-related)

### iOS Managers & Components

**Core Managers:**
- **UserAccountManager.swift** - Authentication, token management, friends
- **CalendarManager.swift** - Event management and WebSocket integration
- **EventsWebSocketManager.swift** - Real-time event updates
- **ChatManager.swift** - Chat functionality
- **NotificationManager.swift** - Push notifications and local notifications
- **LocationManager.swift** - GPS location services
- **ImageManager.swift** - User image management and caching
- **ImageUploadManager.swift** - Professional image upload system
- **ProfessionalImageCache.swift** - Multi-tier image caching
- **ContentModerationManager.swift** - Content reporting and moderation
- **LocalizationManager.swift** - Multi-language support
- **NetworkMonitor.swift** - Network connectivity monitoring
- **UserReputationManager.swift** - User rating and reputation system

**Utility Classes:**
- **AppLogger.swift** - Centralized logging system
- **AppError.swift** - Error handling and definitions
- **InputValidator.swift** - Input validation utilities
- **HapticManager.swift** - Haptic feedback
- **ImageRetryManager.swift** - Image loading retry logic
- **NetworkRetryManager.swift** - Network request retry logic

**ViewModels:**
- **EventCreationViewModel.swift** - Event creation logic
- **UpcomingEventsViewModel.swift** - Upcoming events management
- **AutoMatchingManager.swift** - Event auto-matching logic
- **UserProfileManager.swift** - User profile management
- **WeatherViewModel.swift** - Weather data integration

### WebSocket Integration

**EventsWebSocketManager.swift:**
- Real-time event updates
- Automatic reconnection with exponential backoff
- Ping/pong for connection health
- Message parsing with fallback

**Connection Flow:**
1. Connect to `wss://server/ws/events/{username}/`
2. Listen for event change messages
3. Parse JSON: `{"type": "update|create|delete", "event_id": "uuid"}`
4. Notify CalendarManager of changes
5. Auto-reconnect on connection loss

### iOS Views & Components

**Main Views:**
- **ContentView.swift** - Main app interface with quick actions
- **LoginView.swift** - User authentication
- **OnboardingView.swift** - First-time user experience
- **SettingsView.swift** - User settings and preferences
- **ProfileView.swift** - User profile display
- **FriendsListView.swift** - Friends and social connections
- **CalendarView.swift** - Event calendar display
- **WeatherAndCalendarView.swift** - Combined weather and calendar

**Map Views:**
- **MapBox.swift** - Main map interface with clustering
- **EventCreationView.swift** - Create new events
- **EventDetailedView.swift** - Event details and RSVP
- **EventEditView.swift** - Edit existing events
- **EventFilterView.swift** - Filter events on map
- **LocationPickerView.swift** - Location selection
- **GroupChatView.swift** - Event-based group chat

### Map Recentering Fix (January 2025)

**Problem:** The map was automatically recentering to show all filtered events whenever users switched between view modes ("All Events", "My Events", "Auto Matched") or applied filters.

**Root Cause:** The `.id(mapRefreshVersion)` modifier on `StudyMapBoxView` was causing the entire map view to be recreated whenever `mapRefreshVersion` changed. This triggered `makeUIView` instead of `updateUIView`, which reset the camera to the initial region.

**Solution:** Removed the `.id(mapRefreshVersion)` modifier, allowing SwiftUI to call `updateUIView` instead of recreating the view. This preserves the user's current map position while still updating annotations.

**Technical Details:**
```swift
// Before (causing recentering):
StudyMapBoxView(events: filteredEvents, region: $region, refreshVersion: mapRefreshVersion)
    .id(mapRefreshVersion)  // ← This caused recreation and recentering

// After (preserves position):
StudyMapBoxView(events: filteredEvents, region: $region, refreshVersion: mapRefreshVersion)
    // No .id() modifier - uses updateUIView instead of makeUIView
```

**Impact:** Users can now filter events and switch view modes without losing their current map position, providing a much better user experience when exploring specific areas.

**Settings & Preferences:**
- **NotificationPreferencesView.swift** - Notification settings
- **PrivacySettingsView.swift** - Privacy and security
- **MatchingPreferencesView.swift** - Auto-matching preferences
- **LanguageSettingsView.swift** - Language selection
- **ChangePasswordView.swift** - Password change
- **EditProfileView.swift** - Profile editing

**Social & Communication:**
- **ChatView.swift** - Direct messaging
- **RateUserView.swift** - User rating interface
- **UserReputationView.swift** - User reputation display
- **FriendsAccountView.swift** - Friend account details
- **AccountView.swift** - Account management

**Components & Utilities:**
- **EventCard.swift** - Event display component
- **CustomTextField.swift** - Custom text input
- **CustomNavigationBar.swift** - Custom navigation
- **ImageGridView.swift** - Image gallery display
- **UserProfileImageView.swift** - Profile image component
- **ProfessionalCachedImageView.swift** - Optimized image display
- **SkeletonLoader.swift** - Loading states
- **EmptyStateView.swift** - Empty state displays
- **ValidationMessage.swift** - Input validation feedback

---

## Android Frontend Documentation

### App Structure

```
PinIt_Android/app/src/main/java/com/example/pinit/
├── MainActivity.kt                    # Main activity with comprehensive UI
├── network/
│   ├── ApiService.kt                  # Retrofit API service interface
│   ├── ApiClient.kt                   # HTTP client configuration
│   ├── EventCreateRequest.kt          # Event creation request models
│   ├── EventInteractionsService.kt    # Event interactions API
│   └── RetrofitExtensions.kt         # Retrofit utility extensions
├── models/
│   ├── Models.kt                      # Core data models
│   ├── ApiModels.kt                   # API response models
│   ├── MapModels.kt                   # Map-specific models
│   ├── InvitationModels.kt            # Invitation system models
│   ├── EventInteractions.kt           # Event interaction models
│   └── CoordinateConverter.kt         # Coordinate conversion utilities
├── repository/
│   ├── EventRepository.kt             # Event data repository
│   ├── ProfileRepository.kt           # Profile data repository
│   ├── EnhancedProfileRepository.kt   # Enhanced profile management
│   └── EventInteractionsRepository.kt # Event interactions repository
├── viewmodels/
│   ├── ProfileViewModel.kt            # Profile view model
│   └── EventDetailViewModel.kt        # Event detail view model
├── views/
│   ├── MapboxView.kt                  # Main map view
│   ├── CalendarView.kt                # Calendar view
│   ├── ChatView.kt                    # Chat interface
│   ├── LoginView.kt                   # Login interface
│   ├── InvitationsView.kt             # Invitations management
│   ├── FriendsView.kt                 # Friends management
│   └── views/components/
│       └── ModalComponents.kt         # Modal UI components
├── components/
│   ├── UserProfileSheet.kt            # User profile bottom sheet
│   ├── FullScreenMapView.kt           # Full screen map
│   ├── ProfileView.kt                 # Profile display
│   ├── EventDetailView.kt             # Event details
│   ├── LoginView.kt                   # Login form
│   ├── SocialFeedView.kt              # Social feed
│   ├── UIComponents.kt                # Reusable UI components
│   ├── BasicFullMapView.kt            # Basic map implementation
│   ├── EventClusterBottomSheet.kt     # Event clustering UI
│   ├── EnhancedEventCreationView.kt   # Event creation form
│   ├── EnhancedProfileView.kt         # Enhanced profile editor
│   ├── EventCreationView.kt           # Event creation interface
│   ├── WeatherAndCalendarCard.kt       # Weather integration
│   ├── MiniMapView.kt                 # Mini map component
│   ├── SimpleFullMapView.kt           # Simple map implementation
│   ├── SimpleMapView.kt               # Basic map view
│   ├── DirectAccessMapView.kt         # Direct map access
│   ├── SuperSimpleMapView.kt          # Minimal map implementation
│   ├── BasicMapView.kt                # Basic map functionality
│   ├── SimpleTestView.kt              # Testing components
│   └── map/
│       ├── MapClusteringUtils.kt      # Map clustering logic
│       ├── MapAnnotationUtils.kt      # Map annotation utilities
│       ├── ClusterAnnotationView.kt   # Cluster annotation UI
│       └── EventAnnotationView.kt      # Event annotation UI
├── utils/
│   ├── JsonUtils.kt                    # JSON utilities
│   ├── PotentialMatchRegistry.kt      # Auto-matching registry
│   ├── MapboxHelper.kt                # Mapbox integration
│   └── CoordinateConverter.kt         # Coordinate utilities
├── services/
│   └── LocationSearchService.kt       # Location search
└── ui/theme/
    ├── Theme.kt                       # App theme
    ├── Type.kt                        # Typography
    ├── Color.kt                       # Color scheme
    └── CustomIcons.kt                 # Custom icons
```

### Android Architecture

**Architecture Pattern:** MVVM (Model-View-ViewModel) with Repository Pattern

**Key Components:**

1. **MainActivity.kt** - Main activity with comprehensive UI implementation
   - Handles user authentication state
   - Manages navigation between views
   - Integrates with UserAccountManager
   - Implements Mapbox initialization
   - Manages potential match registry

2. **ApiService.kt** - Retrofit API service interface
   - Complete API endpoint definitions
   - Authentication handling
   - Request/response models
   - Error handling

3. **Repository Pattern** - Data access abstraction
   - EventRepository: Event data management
   - ProfileRepository: User profile management
   - EventInteractionsRepository: Social interactions

4. **ViewModels** - Business logic and state management
   - ProfileViewModel: Profile management logic
   - EventDetailViewModel: Event detail logic

### Android API Integration

**Retrofit Configuration:**
```kotlin
interface ApiService {
    @POST("login/")
    suspend fun loginUser(@Body loginRequest: Map<String, String>): Response<AuthResponse>
    
    @GET("get_study_events/{username}/")
    suspend fun getStudyEvents(@Path("username") username: String): Response<ApiEventsResponse>
    
    @POST("create_study_event/")
    suspend fun createStudyEvent(@Body eventRequest: EventCreateRequest): Response<EventResponse>
    
    // ... more endpoints
}
```

**Authentication Flow:**
- JWT token management in UserAccountManager
- Automatic token refresh
- Persistent login state
- Multiple server fallback support

**Error Handling:**
- Comprehensive error handling for network requests
- User-friendly error messages
- Fallback to demo mode when servers unavailable

### Android UI Components

**Map Integration:**
- Mapbox SDK integration
- Event clustering with custom annotations
- Multiple map view implementations
- Location search and selection

**User Interface:**
- Material Design 3 components
- Custom bottom sheets and modals
- Responsive layouts
- Dark/light theme support

**Navigation:**
- Bottom navigation
- Modal presentations
- Deep linking support

### Android-Specific Features

**Location Services:**
- GPS location tracking
- Location search integration
- Map-based event creation
- Location-based event filtering

**Push Notifications:**
- Firebase Cloud Messaging integration
- Notification handling
- Background processing

**Data Persistence:**
- SharedPreferences for user data
- Room database for offline caching
- Image caching and optimization

### Android Configuration

**Build Configuration (build.gradle.kts):**
```kotlin
android {
    compileSdk 34
    
    defaultConfig {
        applicationId "com.example.pinit"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }
    
    buildFeatures {
        compose true
    }
    
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.4"
    }
}
```

**Dependencies:**
- Jetpack Compose for UI
- Retrofit for networking
- Mapbox SDK for maps
- Firebase for notifications
- Room for local database
- Coroutines for async operations

### Android Testing

**Unit Tests:**
- Repository pattern testing
- ViewModel testing
- API service testing

**Integration Tests:**
- Map functionality testing
- Auto-matching system testing
- End-to-end user flows

### Android Performance Optimizations

**Image Loading:**
- Glide for image caching
- Image compression and optimization
- Lazy loading for large lists

**Network Optimization:**
- Request caching
- Connection pooling
- Retry mechanisms

**Memory Management:**
- Proper lifecycle management
- Weak references where appropriate
- Background task optimization

---

## Deployment & Operations

### Railway Deployment Configuration

#### Service Architecture
**Production Services:**
- **Main App Service**: `pinit-backend-production`
  - Django backend with ASGI server
  - WebSocket support via Daphne
  - Automatic migrations on deploy
- **PostgreSQL Service**: `Postgres`
  - Production database
  - Connected via `DATABASE_URL` environment variable
- **Redis Service**: `Redis`
  - Channel layers for WebSocket
  - Session storage
  - Caching layer

#### Railway Configuration (railway.json)
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "python manage.py migrate --noinput && daphne -b 0.0.0.0 -p $PORT StudyCon.asgi:application",
    "healthcheckPath": "/health",
    "healthcheckTimeout": 120,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3
  }
}
```

**Configuration Details:**
- **Builder**: NIXPACKS (automatic dependency detection)
- **Start Command**: Migrations + Daphne ASGI server
- **Health Check**: `/health` endpoint with 120-second timeout
- **Restart Policy**: ON_FAILURE with max 3 retries
- **Port**: Dynamic via `$PORT` environment variable

#### Procfile Configuration
```bash
web: python manage.py migrate --noinput && python manage.py collectstatic --noinput && daphne -b 0.0.0.0 -p $PORT StudyCon.asgi:application
```

**Process Breakdown:**
1. **Database Migrations**: `python manage.py migrate --noinput`
2. **Static Files**: `python manage.py collectstatic --noinput`
3. **ASGI Server**: `daphne -b 0.0.0.0 -p $PORT StudyCon.asgi:application`

#### Environment Variables

**Required Environment Variables:**
```bash
# Database Configuration
DATABASE_URL=${{ Postgres.DATABASE_URL }}

# Redis Configuration
REDIS_URL=${{ Redis.REDIS_URL }}

# Django Settings
SECRET_KEY=your-secret-key
DEBUG=False
ALLOWED_HOSTS=pinit-backend-production.up.railway.app,pin-it.net,api.pin-it.net

# CORS Configuration
CORS_ALLOWED_ORIGINS=https://your-frontend-domain.com

# Cloudflare R2 Storage
AWS_ACCESS_KEY_ID=your-r2-access-key
AWS_SECRET_ACCESS_KEY=your-r2-secret-key
AWS_STORAGE_BUCKET_NAME=your-r2-bucket
AWS_S3_ENDPOINT_URL=https://your-account-id.r2.cloudflarestorage.com

# Push Notifications
FCM_SERVER_KEY=your-fcm-server-key
```

**Service Connection Variables:**
- `DATABASE_URL`: Automatically provided by Railway PostgreSQL service
- `REDIS_URL`: Automatically provided by Railway Redis service
- `RAILWAY_RUN_COMMAND`: Set to run migrations on deploy

#### Python Dependencies (requirements.txt)

**Core Django Stack:**
```
Django==5.1.6
djangorestframework==3.15.2
djangorestframework-simplejwt==5.3.1
django-cors-headers==4.3.1
django-push-notifications==3.0.0
django-ratelimit==4.1.0
```

**ASGI & WebSocket Support:**
```
channels==4.0.0
daphne==4.0.0
asgiref==3.9.2
channels-redis==4.2.0
```

**Server & Utilities:**
```
gunicorn==21.2.0
whitenoise==6.6.0
python-dotenv==1.0.0
Pillow==10.4.0
boto3==1.34.0
django-storages==1.14.2
bleach==6.1.0
```

**Database & Caching:**
```
dj-database-url==2.1.0
psycopg[binary]==3.2.10
redis==5.0.1
```

#### Runtime Configuration (runtime.txt)
```
python-3.13.2
```

### Deployment Process

#### Automatic Deployment Flow
1. **Code Push**: Git push to main branch triggers deployment
2. **Build Phase**: NIXPACKS detects Python project and installs dependencies
3. **Database Migrations**: `python manage.py migrate --noinput` runs automatically
4. **Static Files**: `python manage.py collectstatic --noinput` collects static files
5. **Service Start**: Daphne ASGI server starts on assigned port
6. **Health Check**: Railway validates deployment via `/health` endpoint
7. **Traffic Routing**: Production traffic routed to new deployment

#### Manual Deployment Commands
```bash
# Local development setup
python manage.py migrate
python manage.py collectstatic
python manage.py runserver

# Production deployment (handled by Railway)
python manage.py migrate --noinput
python manage.py collectstatic --noinput
daphne -b 0.0.0.0 -p $PORT StudyCon.asgi:application
```

### Health Monitoring

#### Health Check Endpoint
**URL**: `GET /health/`

**Response (200 OK):**
```json
{
  "status": "healthy",
  "database": "connected",
  "redis": "connected",
  "timestamp": "2025-01-11T12:00:00Z"
}
```

**Health Check Implementation:**
```python
@api_view(['GET'])
def health_check(request):
    """Comprehensive health check for Railway deployment"""
    try:
        # Test database connection
        from django.db import connection
        connection.ensure_connection()
        
        # Test Redis connection
        from django.core.cache import cache
        cache.set('health_check', 'ok', 10)
        cache.get('health_check')
        
        return JsonResponse({
            "status": "healthy",
            "database": "connected",
            "redis": "connected",
            "timestamp": timezone.now().isoformat()
        })
    except Exception as e:
        return JsonResponse({
            "status": "unhealthy",
            "error": str(e),
            "timestamp": timezone.now().isoformat()
        }, status=500)
```

#### Monitoring Configuration
- **Health Check Path**: `/health`
- **Timeout**: 120 seconds
- **Frequency**: Every 30 seconds
- **Failure Threshold**: 3 consecutive failures
- **Restart Policy**: ON_FAILURE with max 3 retries

#### Logging & Debugging
**Railway Logs:**
- Real-time log streaming via Railway dashboard
- Log aggregation and search capabilities
- Error tracking and alerting

**Django Logging:**
```python
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}
```

### Database Management

#### PostgreSQL Configuration
**Connection String Format:**
```
postgresql://username:password@host:port/database
```

**Railway PostgreSQL Features:**
- Automatic backups
- Connection pooling
- Read replicas (if configured)
- SSL/TLS encryption

#### Migration Strategy
**Automatic Migrations:**
- Run on every deployment
- `--noinput` flag prevents interactive prompts
- Atomic transactions ensure data consistency
- Rollback capability for failed migrations

**Migration Commands:**
```bash
# Create migration
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Show migration status
python manage.py showmigrations
```

### WebSocket & Real-time Features

#### Daphne ASGI Server
**Configuration:**
```python
# StudyCon/asgi.py
import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from myapp.routing import websocket_urlpatterns

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": AuthMiddlewareStack(
        URLRouter(websocket_urlpatterns)
    ),
})
```

**WebSocket Routes:**
```python
# myapp/routing.py
from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r"ws/chat/(?P<sender>\w+)/(?P<receiver>\w+)/$", consumers.ChatConsumer.as_asgi()),
    re_path(r"ws/group_chat/(?P<event_id>[^/]+)/$", consumers.GroupChatConsumer.as_asgi()),
    re_path(r"ws/events/(?P<username>\w+)/$", consumers.EventsConsumer.as_asgi()),
]
```

#### Channel Layers Configuration
```python
# Redis-based channel layers for production
if os.environ.get('REDIS_URL'):
    CHANNEL_LAYERS = {
        "default": {
            "BACKEND": "channels_redis.core.RedisChannelLayer",
            "CONFIG": {
                "hosts": [os.environ.get('REDIS_URL')],
            },
        },
    }
else:
    # In-memory fallback for development
    CHANNEL_LAYERS = {
        "default": {
            "BACKEND": "channels.layers.InMemoryChannelLayer",
        },
    }
```

### Static Files & Media

#### Static Files Configuration
```python
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

# WhiteNoise for static file serving
MIDDLEWARE = [
    'whitenoise.middleware.WhiteNoiseMiddleware',
    # ... other middleware
]

STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
```

#### Media Files (Cloudflare R2)
```python
# Cloudflare R2 configuration
AWS_ACCESS_KEY_ID = os.environ.get('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY')
AWS_STORAGE_BUCKET_NAME = os.environ.get('AWS_STORAGE_BUCKET_NAME')
AWS_S3_ENDPOINT_URL = os.environ.get('AWS_S3_ENDPOINT_URL')
AWS_S3_CUSTOM_DOMAIN = f'{AWS_STORAGE_BUCKET_NAME}.r2.cloudflarestorage.com'
AWS_DEFAULT_ACL = 'public-read'
AWS_S3_OBJECT_PARAMETERS = {
    'CacheControl': 'max-age=86400',
}
```

### Complete JWT Security Documentation

#### JWT Authentication Architecture

**JWT Token Structure:**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

**JWT Payload Structure:**
```json
{
  "user_id": 123,
  "username": "johndoe",
  "exp": 1640995200,
  "iat": 1640991600,
  "token_type": "access"
}
```

#### Backend JWT Implementation

**1. JWT Token Generation (views.py)**
```python
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework.permissions import IsAuthenticated

@ratelimit(key='ip', rate='5/h', method='POST', block=True)
@csrf_exempt
def login_user(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            username = data.get("username")
            password = data.get("password")
            
            # Security: Rate limiting and failed attempt tracking
            ip = request.META.get('REMOTE_ADDR', 'unknown')
            recent_failures = [
                t for t in failed_login_attempts[ip]
                if datetime.now() - t < timedelta(minutes=15)
            ]
            
            if len(recent_failures) >= 5:
                security_logger.warning(f"Too many failed login attempts from IP: {ip}")
                return JsonResponse({
                    "success": False,
                    "message": "Too many failed attempts. Try again in 15 minutes."
                }, status=429)

            user = authenticate(username=username, password=password)
            
            if user is not None:
                # Clear failed attempts on successful login
                failed_login_attempts[ip] = []
                security_logger.info(f"Successful login for user: {username} from IP: {ip}")
                
                # Generate JWT tokens
                refresh = RefreshToken.for_user(user)
                return JsonResponse({
                    "success": True,
                    "message": "Login successful.",
                    "access_token": str(refresh.access_token),
                    "refresh_token": str(refresh),
                    "username": username,
                    "expires_in": 3600  # 1 hour
                }, status=200)
            else:
                # Track failed attempt
                failed_login_attempts[ip].append(datetime.now())
                security_logger.warning(f"Failed login attempt for user: {username} from IP: {ip}")
                return JsonResponse({"success": False, "message": "Invalid credentials."}, status=401)
                
        except json.JSONDecodeError:
            return JsonResponse({"success": False, "message": "Invalid JSON data."}, status=400)
    
    return JsonResponse({"success": False, "message": "Invalid request method."}, status=405)
```

**2. JWT Token Validation & Protection**
```python
@ratelimit(key='user', rate='1000/h', method='GET', block=True)
@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def get_study_events(request, username):
    """
    Protected endpoint requiring JWT authentication
    """
    try:
        # JWT token is automatically validated by JWTAuthentication
        # request.user is populated from JWT payload
        
        # Security: Only users can see their own events
        if request.user.username != username:
            return JsonResponse({"error": "Forbidden"}, status=403)
        
        # Get events for authenticated user
        user = User.objects.get(username=username)
        events = StudyEvent.objects.filter(
            Q(host=user) | Q(attendees=user) | Q(is_public=True)
        )
        
        return JsonResponse({"events": events}, safe=False)
        
    except User.DoesNotExist:
        return JsonResponse({"error": "User not found"}, status=404)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)
```

**3. JWT Token Refresh**
```python
from rest_framework_simplejwt.views import TokenRefreshView

# Automatic token refresh endpoint
# POST /api/token/refresh/
# Body: {"refresh": "refresh_token_string"}
# Response: {"access": "new_access_token"}
```

**4. JWT Token Blacklisting (Logout)**
```python
@ratelimit(key='user', rate='10/h', method='POST', block=True)
@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def logout_user(request):
    if request.method == "POST":
        try:
            # Get refresh token from request
            auth_header = request.META.get('HTTP_AUTHORIZATION', '')
            if auth_header.startswith('Bearer '):
                token = auth_header.split(' ')[1]
                
                # Blacklist the refresh token
                from rest_framework_simplejwt.tokens import RefreshToken
                try:
                    refresh_token = RefreshToken(token)
                    refresh_token.blacklist()
                    security_logger.info(f"User {request.user.username} logged out")
                except Exception as e:
                    security_logger.warning(f"Token blacklisting failed: {str(e)}")
                    
            return JsonResponse({"success": True, "message": "Logout successful."}, status=200)
            
        except Exception as e:
            security_logger.warning(f"Logout token handling failed: {str(e)}")
            return JsonResponse({"success": True, "message": "Logout successful."}, status=200)
    
    return JsonResponse({"success": False, "message": "Invalid request method."}, status=405)
```

#### iOS JWT Implementation

**1. UserAccountManager.swift - JWT Token Management**
```swift
class UserAccountManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    @Published var authToken: String?
    @Published var refreshToken: String?
    @Published var tokenExpiry: Date?
    
    private let keychainManager = KeychainManager()
    
    // MARK: - JWT Token Storage
    func storeTokens(accessToken: String, refreshToken: String) {
        // Store in Keychain for security
        keychainManager.storeToken(accessToken, for: "access_token")
        keychainManager.storeToken(refreshToken, for: "refresh_token")
        
        // Update published properties
        DispatchQueue.main.async {
            self.authToken = accessToken
            self.refreshToken = refreshToken
            self.tokenExpiry = self.extractExpiryFromToken(accessToken)
        }
    }
    
    // MARK: - JWT Token Validation
    func isTokenValid() -> Bool {
        guard let expiry = tokenExpiry else { return false }
        return expiry > Date().addingTimeInterval(300) // 5 minute buffer
    }
    
    // MARK: - Automatic Token Refresh
    func refreshAccessToken() async -> Bool {
        guard let refreshToken = refreshToken else { return false }
        
        do {
            let response = try await APIClient.shared.refreshToken(refreshToken: refreshToken)
            
            DispatchQueue.main.async {
                self.authToken = response.accessToken
                self.tokenExpiry = self.extractExpiryFromToken(response.accessToken)
            }
            
            // Update Keychain
            keychainManager.storeToken(response.accessToken, for: "access_token")
            
            return true
        } catch {
            // Refresh failed, logout user
            await logout()
            return false
        }
    }
    
    // MARK: - JWT Token Extraction
    private func extractExpiryFromToken(_ token: String) -> Date? {
        let components = token.components(separatedBy: ".")
        guard components.count == 3 else { return nil }
        
        // Decode JWT payload
        let payload = components[1]
        let paddedPayload = payload.padding(toLength: ((payload.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
        
        guard let data = Data(base64Encoded: paddedPayload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else { return nil }
        
        return Date(timeIntervalSince1970: exp)
    }
}
```

**2. APIClient.swift - JWT Header Injection**
```swift
class APIClient {
    static let shared = APIClient()
    private let userAccountManager = UserAccountManager()
    
    func request<T: Codable>(_ endpoint: String, method: HTTPMethod = .GET, body: Data? = nil) async throws -> T {
        // Check token validity and refresh if needed
        if !userAccountManager.isTokenValid() {
            let refreshed = await userAccountManager.refreshAccessToken()
            if !refreshed {
                throw APIError.authenticationFailed
            }
        }
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Inject JWT token
        if let token = userAccountManager.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add content type for POST requests
        if method != .GET && body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Handle HTTP errors
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 401:
                // Token expired, try refresh
                let refreshed = await userAccountManager.refreshAccessToken()
                if refreshed {
                    // Retry request with new token
                    return try await self.request(endpoint, method: method, body: body)
                } else {
                    throw APIError.authenticationFailed
                }
            case 403:
                throw APIError.forbidden
            case 404:
                throw APIError.notFound
            case 429:
                throw APIError.rateLimited
            case 500...599:
                throw APIError.serverError
            default:
                break
            }
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

**3. KeychainManager.swift - Secure Token Storage**
```swift
class KeychainManager {
    func storeToken(_ token: String, for key: String) {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func retrieveToken(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    func deleteToken(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
```

#### Android JWT Implementation

**1. UserAccountManager.kt - JWT Token Management**
```kotlin
class UserAccountManager : ObservableObject {
    @Published var isLoggedIn: Boolean = false
    @Published var currentUser: User? = null
    @Published var authToken: String? = null
    @Published var refreshToken: String? = null
    @Published var tokenExpiry: Date? = null
    
    private val sharedPreferences = context.getSharedPreferences("auth_prefs", Context.MODE_PRIVATE)
    private val keyStore = KeyStore.getInstance("AndroidKeyStore")
    
    init {
        keyStore.load(null)
    }
    
    // MARK: - JWT Token Storage
    fun storeTokens(accessToken: String, refreshToken: String) {
        // Store in encrypted SharedPreferences
        val encryptedAccessToken = encryptToken(accessToken)
        val encryptedRefreshToken = encryptToken(refreshToken)
        
        sharedPreferences.edit()
            .putString("access_token", encryptedAccessToken)
            .putString("refresh_token", encryptedRefreshToken)
            .apply()
        
        // Update published properties
        authToken = accessToken
        this.refreshToken = refreshToken
        tokenExpiry = extractExpiryFromToken(accessToken)
    }
    
    // MARK: - JWT Token Validation
    fun isTokenValid(): Boolean {
        val expiry = tokenExpiry ?: return false
        val bufferTime = 5 * 60 * 1000L // 5 minutes in milliseconds
        return expiry.time > System.currentTimeMillis() + bufferTime
    }
    
    // MARK: - Automatic Token Refresh
    suspend fun refreshAccessToken(): Boolean {
        val refreshToken = this.refreshToken ?: return false
        
        try {
            val response = apiService.refreshToken(refreshToken)
            
            authToken = response.accessToken
            tokenExpiry = extractExpiryFromToken(response.accessToken)
            
            // Update encrypted storage
            val encryptedToken = encryptToken(response.accessToken)
            sharedPreferences.edit()
                .putString("access_token", encryptedToken)
                .apply()
            
            return true
        } catch (e: Exception) {
            // Refresh failed, logout user
            logout()
            return false
        }
    }
    
    // MARK: - Token Encryption
    private fun encryptToken(token: String): String {
        val key = getOrCreateSecretKey()
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key)
        
        val encryptedBytes = cipher.doFinal(token.toByteArray())
        val iv = cipher.iv
        
        return Base64.encodeToString(encryptedBytes + iv, Base64.DEFAULT)
    }
    
    private fun decryptToken(encryptedToken: String): String {
        val key = getOrCreateSecretKey()
        val encryptedData = Base64.decode(encryptedToken, Base64.DEFAULT)
        
        val iv = encryptedData.sliceArray(encryptedData.size - 12 until encryptedData.size)
        val encryptedBytes = encryptedData.sliceArray(0 until encryptedData.size - 12)
        
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val spec = GCMParameterSpec(128, iv)
        cipher.init(Cipher.DECRYPT_MODE, key, spec)
        
        return String(cipher.doFinal(encryptedBytes))
    }
}
```

**2. ApiService.kt - JWT Header Injection**
```kotlin
class ApiService {
    private val userAccountManager = UserAccountManager()
    
    @GET("api/get_study_events/{username}/")
    suspend fun getStudyEvents(
        @Path("username") username: String,
        @Header("Authorization") authHeader: String? = null
    ): Response<EventsResponse> {
        val token = authHeader ?: userAccountManager.authToken
        val header = if (token != null) "Bearer $token" else null
        
        return apiInterface.getStudyEvents(username, header)
    }
    
    // Automatic token refresh interceptor
    private val authInterceptor = Interceptor { chain ->
        val request = chain.request()
        val response = chain.proceed(request)
        
        if (response.code == 401) {
            // Token expired, try refresh
            val refreshed = userAccountManager.refreshAccessToken()
            if (refreshed) {
                // Retry request with new token
                val newRequest = request.newBuilder()
                    .header("Authorization", "Bearer ${userAccountManager.authToken}")
                    .build()
                return@Interceptor chain.proceed(newRequest)
            }
        }
        
        response
    }
}
```

#### JWT Security Best Practices

**1. Token Expiration Strategy**
```python
# Django Settings
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=1),      # Short-lived access tokens
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),      # Longer-lived refresh tokens
    'ROTATE_REFRESH_TOKENS': True,                    # Rotate refresh tokens
    'BLACKLIST_AFTER_ROTATION': True,                 # Blacklist old refresh tokens
    'ALGORITHM': 'HS256',                             # Secure algorithm
    'SIGNING_KEY': settings.SECRET_KEY,               # Strong signing key
    'VERIFYING_KEY': None,
    'AUDIENCE': None,
    'ISSUER': None,
    'AUTH_HEADER_TYPES': ('Bearer',),                 # Authorization header format
    'AUTH_HEADER_NAME': 'HTTP_AUTHORIZATION',
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
    'USER_AUTHENTICATION_RULE': 'rest_framework_simplejwt.authentication.default_user_authentication_rule',
    'AUTH_TOKEN_CLASSES': ('rest_framework_simplejwt.tokens.AccessToken',),
    'TOKEN_TYPE_CLAIM': 'token_type',
    'JTI_CLAIM': 'jti',
    'SLIDING_TOKEN_REFRESH_EXP_CLAIM': 'refresh_exp',
    'SLIDING_TOKEN_LIFETIME': timedelta(minutes=5),
    'SLIDING_TOKEN_REFRESH_LIFETIME': timedelta(days=1),
}
```

**2. Security Headers**
```python
# Django Security Settings
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
```

**3. Rate Limiting for JWT Endpoints**
```python
# JWT-specific rate limiting
@ratelimit(key='ip', rate='5/h', method='POST', block=True)  # Login attempts
@ratelimit(key='ip', rate='10/h', method='POST', block=True) # Registration
@ratelimit(key='user', rate='1000/h', method='GET', block=True)  # API calls
@ratelimit(key='user', rate='10/h', method='POST', block=True)    # Token refresh
```

**4. JWT Token Validation**
```python
# Custom JWT validation
class CustomJWTAuthentication(JWTAuthentication):
    def get_user(self, validated_token):
        try:
            user_id = validated_token['user_id']
            user = User.objects.get(id=user_id, is_active=True)
            
            # Additional security checks
            if not user.is_active:
                raise InvalidToken('User account is disabled')
                
            return user
        except User.DoesNotExist:
            raise InvalidToken('User not found')
        except KeyError:
            raise InvalidToken('Token contained no recognizable user identification')
```

#### JWT Security Monitoring

**1. Security Logging**
```python
import logging
security_logger = logging.getLogger('myapp.security')

# Log authentication events
def log_auth_event(event_type, username, ip_address, success=True):
    security_logger.info(f"{event_type}: {username} from {ip_address} - {'SUCCESS' if success else 'FAILED'}")

# Usage in views
log_auth_event('LOGIN', username, ip_address, success=True)
log_auth_event('LOGOUT', username, ip_address, success=True)
log_auth_event('TOKEN_REFRESH', username, ip_address, success=True)
```

**2. Failed Login Tracking**
```python
from collections import defaultdict
from datetime import datetime, timedelta

failed_login_attempts = defaultdict(list)

def track_failed_login(ip_address):
    failed_login_attempts[ip_address].append(datetime.now())
    
    # Clean old attempts
    cutoff = datetime.now() - timedelta(minutes=15)
    failed_login_attempts[ip_address] = [
        attempt for attempt in failed_login_attempts[ip_address]
        if attempt > cutoff
    ]
    
    # Check if too many attempts
    if len(failed_login_attempts[ip_address]) >= 5:
        security_logger.warning(f"Too many failed login attempts from IP: {ip_address}")
        return False
    
    return True
```

### Security Configuration

#### CORS Settings
```python
CORS_ALLOWED_ORIGINS = [
    "https://your-frontend-domain.com",
    "https://pinit-backend-production.up.railway.app",
]

CORS_ALLOW_CREDENTIALS = True
```

#### CSRF Protection
```python
CSRF_TRUSTED_ORIGINS = [
    "https://pinit-backend-production.up.railway.app",
    "https://pin-it.net",
    "https://api.pin-it.net",
]
```

#### Rate Limiting
```python
# Django Rate Limit configuration
RATELIMIT_USE_CACHE = 'default'
RATELIMIT_ENABLE = True
```

### Performance Optimization

#### Database Optimization
- **Connection Pooling**: Automatic via Railway PostgreSQL
- **Query Optimization**: Proper indexing and query analysis
- **Caching**: Redis-based caching for frequently accessed data

#### WebSocket Optimization
- **Connection Management**: Automatic cleanup on disconnect
- **Message Queuing**: Efficient message delivery
- **Load Balancing**: Multiple Daphne processes if needed

#### Static File Optimization
- **Compression**: WhiteNoise compression for static files
- **CDN**: Cloudflare R2 for media files
- **Caching**: Proper cache headers for static assets

### Troubleshooting

#### Common Issues
1. **Database Connection Errors**: Check `DATABASE_URL` environment variable
2. **WebSocket Connection Issues**: Verify Redis connection and channel layers
3. **Static File Issues**: Ensure `collectstatic` runs during deployment
4. **Migration Failures**: Check database permissions and migration files

#### Debug Commands
```bash
# Check database connection
python manage.py dbshell

# Test Redis connection
python manage.py shell
>>> from django.core.cache import cache
>>> cache.set('test', 'ok')
>>> cache.get('test')

# Check WebSocket routes
python manage.py shell
>>> from myapp.routing import websocket_urlpatterns
>>> print(websocket_urlpatterns)
```

#### Log Analysis
- **Railway Dashboard**: Real-time logs and metrics
- **Error Tracking**: Automatic error detection and alerting
- **Performance Monitoring**: Response times and resource usage

---

## Database Schema Documentation

### Complete Database Schema

#### Core Tables

**Users Table (Django Built-in):**
```sql
CREATE TABLE auth_user (
    id SERIAL PRIMARY KEY,
    username VARCHAR(150) UNIQUE NOT NULL,
    first_name VARCHAR(150),
    last_name VARCHAR(150),
    email VARCHAR(254),
    password VARCHAR(128),
    is_staff BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_superuser BOOLEAN DEFAULT FALSE,
    date_joined TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_auth_user_username ON auth_user(username);
CREATE INDEX idx_auth_user_email ON auth_user(email);
```

**UserProfile Table:**
```sql
CREATE TABLE myapp_userprofile (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    is_certified BOOLEAN DEFAULT FALSE,
    full_name VARCHAR(255),
    university VARCHAR(255),
    degree VARCHAR(255),
    year VARCHAR(50),
    bio TEXT,
    profile_picture TEXT, -- Legacy base64 field (deprecated)
    interests JSONB DEFAULT '[]',
    skills JSONB DEFAULT '{}',
    auto_invite_enabled BOOLEAN DEFAULT TRUE,
    preferred_radius DOUBLE PRECISION DEFAULT 10.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_userprofile_user_id ON myapp_userprofile(user_id);
CREATE INDEX idx_userprofile_is_certified ON myapp_userprofile(is_certified);
CREATE INDEX idx_userprofile_auto_invite ON myapp_userprofile(auto_invite_enabled);
CREATE INDEX idx_userprofile_interests ON myapp_userprofile USING GIN(interests);
CREATE INDEX idx_userprofile_skills ON myapp_userprofile USING GIN(skills);
```

**UserImage Table:**
```sql
CREATE TABLE myapp_userimage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    image VARCHAR(500),
    image_type VARCHAR(20) DEFAULT 'gallery',
    is_primary BOOLEAN DEFAULT FALSE,
    caption VARCHAR(255),
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    storage_key VARCHAR(500),
    public_url VARCHAR(500),
    mime_type VARCHAR(100),
    width INTEGER,
    height INTEGER,
    size_bytes INTEGER
);

CREATE INDEX idx_userimage_user_id ON myapp_userimage(user_id);
CREATE INDEX idx_userimage_image_type ON myapp_userimage(image_type);
CREATE INDEX idx_userimage_is_primary ON myapp_userimage(is_primary);
CREATE INDEX idx_userimage_uploaded_at ON myapp_userimage(uploaded_at);
```

**StudyEvent Table:**
```sql
CREATE TABLE myapp_studyevent (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    host_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_public BOOLEAN DEFAULT TRUE,
    event_type VARCHAR(20) DEFAULT 'other',
    max_participants INTEGER DEFAULT 10,
    auto_matching_enabled BOOLEAN DEFAULT FALSE,
    interest_tags JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_studyevent_host_id ON myapp_studyevent(host_id);
CREATE INDEX idx_studyevent_title ON myapp_studyevent(title);
CREATE INDEX idx_studyevent_time ON myapp_studyevent(time);
CREATE INDEX idx_studyevent_end_time ON myapp_studyevent(end_time);
CREATE INDEX idx_studyevent_is_public ON myapp_studyevent(is_public);
CREATE INDEX idx_studyevent_event_type ON myapp_studyevent(event_type);
CREATE INDEX idx_studyevent_auto_matching ON myapp_studyevent(auto_matching_enabled);
CREATE INDEX idx_studyevent_interest_tags ON myapp_studyevent USING GIN(interest_tags);

-- Composite indexes for common query patterns
CREATE INDEX idx_studyevent_public_end_time ON myapp_studyevent(is_public, end_time);
CREATE INDEX idx_studyevent_host_public ON myapp_studyevent(host_id, is_public);
CREATE INDEX idx_studyevent_auto_public ON myapp_studyevent(auto_matching_enabled, is_public);
CREATE INDEX idx_studyevent_type_public ON myapp_studyevent(event_type, is_public);
```

**Event Attendees (Many-to-Many):**
```sql
CREATE TABLE myapp_studyevent_attendees (
    id SERIAL PRIMARY KEY,
    studyevent_id UUID NOT NULL REFERENCES myapp_studyevent(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    UNIQUE(studyevent_id, user_id)
);

CREATE INDEX idx_studyevent_attendees_event ON myapp_studyevent_attendees(studyevent_id);
CREATE INDEX idx_studyevent_attendees_user ON myapp_studyevent_attendees(user_id);
```

**Event Invited Friends (Many-to-Many):**
```sql
CREATE TABLE myapp_studyevent_invited_friends (
    id SERIAL PRIMARY KEY,
    studyevent_id UUID NOT NULL REFERENCES myapp_studyevent(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    UNIQUE(studyevent_id, user_id)
);

CREATE INDEX idx_studyevent_invited_event ON myapp_studyevent_invited_friends(studyevent_id);
CREATE INDEX idx_studyevent_invited_user ON myapp_studyevent_invited_friends(user_id);
```

#### Social Features Tables

**UserProfile Friends (Self-Referencing Many-to-Many):**
```sql
CREATE TABLE myapp_userprofile_friends (
    id SERIAL PRIMARY KEY,
    from_userprofile_id INTEGER NOT NULL REFERENCES myapp_userprofile(id) ON DELETE CASCADE,
    to_userprofile_id INTEGER NOT NULL REFERENCES myapp_userprofile(id) ON DELETE CASCADE,
    UNIQUE(from_userprofile_id, to_userprofile_id)
);

CREATE INDEX idx_userprofile_friends_from ON myapp_userprofile_friends(from_userprofile_id);
CREATE INDEX idx_userprofile_friends_to ON myapp_userprofile_friends(to_userprofile_id);
```

**FriendRequest Table:**
```sql
CREATE TABLE myapp_friendrequest (
    id SERIAL PRIMARY KEY,
    from_user_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    to_user_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(from_user_id, to_user_id)
);

CREATE INDEX idx_friendrequest_from ON myapp_friendrequest(from_user_id);
CREATE INDEX idx_friendrequest_to ON myapp_friendrequest(to_user_id);
CREATE INDEX idx_friendrequest_timestamp ON myapp_friendrequest(timestamp);
```

**ChatMessage Table:**
```sql
CREATE TABLE myapp_chatmessage (
    id SERIAL PRIMARY KEY,
    sender_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    receiver_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_chatmessage_sender ON myapp_chatmessage(sender_id);
CREATE INDEX idx_chatmessage_receiver ON myapp_chatmessage(receiver_id);
CREATE INDEX idx_chatmessage_timestamp ON myapp_chatmessage(timestamp);
```

#### Event Interaction Tables

**EventInvitation Table:**
```sql
CREATE TABLE myapp_eventinvitation (
    id SERIAL PRIMARY KEY,
    event_id UUID NOT NULL REFERENCES myapp_studyevent(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    is_auto_matched BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(event_id, user_id)
);

CREATE INDEX idx_eventinvitation_event ON myapp_eventinvitation(event_id);
CREATE INDEX idx_eventinvitation_user ON myapp_eventinvitation(user_id);
CREATE INDEX idx_eventinvitation_auto_matched ON myapp_eventinvitation(is_auto_matched);
CREATE INDEX idx_eventinvitation_created_at ON myapp_eventinvitation(created_at);
```

**EventComment Table:**
```sql
CREATE TABLE myapp_eventcomment (
    id SERIAL PRIMARY KEY,
    event_id UUID NOT NULL REFERENCES myapp_studyevent(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    parent_id INTEGER REFERENCES myapp_eventcomment(id) ON DELETE CASCADE
);

CREATE INDEX idx_eventcomment_event ON myapp_eventcomment(event_id);
CREATE INDEX idx_eventcomment_user ON myapp_eventcomment(user_id);
CREATE INDEX idx_eventcomment_created_at ON myapp_eventcomment(created_at);
CREATE INDEX idx_eventcomment_parent ON myapp_eventcomment(parent_id);
```

**EventLike Table:**
```sql
CREATE TABLE myapp_eventlike (
    id SERIAL PRIMARY KEY,
    event_id UUID NOT NULL REFERENCES myapp_studyevent(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    comment_id INTEGER REFERENCES myapp_eventcomment(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(event_id, user_id, comment_id)
);

CREATE INDEX idx_eventlike_event ON myapp_eventlike(event_id);
CREATE INDEX idx_eventlike_user ON myapp_eventlike(user_id);
CREATE INDEX idx_eventlike_comment ON myapp_eventlike(comment_id);
CREATE INDEX idx_eventlike_created_at ON myapp_eventlike(created_at);
```

**EventShare Table:**
```sql
CREATE TABLE myapp_eventshare (
    id SERIAL PRIMARY KEY,
    event_id UUID NOT NULL REFERENCES myapp_studyevent(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    shared_platform VARCHAR(50) DEFAULT 'other',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_eventshare_event ON myapp_eventshare(event_id);
CREATE INDEX idx_eventshare_user ON myapp_eventshare(user_id);
CREATE INDEX idx_eventshare_platform ON myapp_eventshare(shared_platform);
CREATE INDEX idx_eventshare_created_at ON myapp_eventshare(created_at);
```

**EventImage Table:**
```sql
CREATE TABLE myapp_eventimage (
    id SERIAL PRIMARY KEY,
    comment_id INTEGER NOT NULL REFERENCES myapp_eventcomment(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_eventimage_comment ON myapp_eventimage(comment_id);
CREATE INDEX idx_eventimage_upload_date ON myapp_eventimage(upload_date);
```

**DeclinedInvitation Table:**
```sql
CREATE TABLE myapp_declinedinvitation (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES myapp_studyevent(id) ON DELETE CASCADE,
    declined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, event_id)
);

CREATE INDEX idx_declinedinvitation_user ON myapp_declinedinvitation(user_id);
CREATE INDEX idx_declinedinvitation_event ON myapp_declinedinvitation(event_id);
CREATE INDEX idx_declinedinvitation_declined_at ON myapp_declinedinvitation(declined_at);
```

#### Reputation System Tables

**UserRating Table:**
```sql
CREATE TABLE myapp_userrating (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_user_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    to_user_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    event_id UUID REFERENCES myapp_studyevent(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    reference TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(from_user_id, to_user_id, event_id)
);

CREATE INDEX idx_userrating_from_user ON myapp_userrating(from_user_id);
CREATE INDEX idx_userrating_to_user ON myapp_userrating(to_user_id);
CREATE INDEX idx_userrating_event ON myapp_userrating(event_id);
CREATE INDEX idx_userrating_rating ON myapp_userrating(rating);
CREATE INDEX idx_userrating_created_at ON myapp_userrating(created_at);
```

**UserTrustLevel Table:**
```sql
CREATE TABLE myapp_usertrustlevel (
    id SERIAL PRIMARY KEY,
    level INTEGER UNIQUE NOT NULL,
    title VARCHAR(50) NOT NULL,
    required_ratings INTEGER NOT NULL,
    min_average_rating DOUBLE PRECISION NOT NULL
);

CREATE INDEX idx_usertrustlevel_level ON myapp_usertrustlevel(level);
CREATE INDEX idx_usertrustlevel_required_ratings ON myapp_usertrustlevel(required_ratings);
```

**UserReputationStats Table:**
```sql
CREATE TABLE myapp_userreputationstats (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    total_ratings INTEGER DEFAULT 0,
    average_rating DOUBLE PRECISION DEFAULT 0.0,
    trust_level_id INTEGER REFERENCES myapp_usertrustlevel(id) ON DELETE SET NULL,
    events_hosted INTEGER DEFAULT 0,
    events_attended INTEGER DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_userreputationstats_user ON myapp_userreputationstats(user_id);
CREATE INDEX idx_userreputationstats_trust_level ON myapp_userreputationstats(trust_level_id);
CREATE INDEX idx_userreputationstats_average_rating ON myapp_userreputationstats(average_rating);
CREATE INDEX idx_userreputationstats_total_ratings ON myapp_userreputationstats(total_ratings);
```

#### Notification and Device Tables

**Device Table:**
```sql
CREATE TABLE myapp_device (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    device_type VARCHAR(10) NOT NULL CHECK (device_type IN ('ios', 'android')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(user_id, token)
);

CREATE INDEX idx_device_user ON myapp_device(user_id);
CREATE INDEX idx_device_token ON myapp_device(token);
CREATE INDEX idx_device_device_type ON myapp_device(device_type);
CREATE INDEX idx_device_is_active ON myapp_device(is_active);
```

**EventReviewReminder Table:**
```sql
CREATE TABLE myapp_eventreviewreminder (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES myapp_studyevent(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(event_id, user_id)
);

CREATE INDEX idx_eventreviewreminder_event ON myapp_eventreviewreminder(event_id);
CREATE INDEX idx_eventreviewreminder_user ON myapp_eventreviewreminder(user_id);
CREATE INDEX idx_eventreviewreminder_sent_at ON myapp_eventreviewreminder(sent_at);
```

#### Structured Data Tables

**UserInterest Table:**
```sql
CREATE TABLE myapp_userinterest (
    id SERIAL PRIMARY KEY,
    user_profile_id INTEGER NOT NULL REFERENCES myapp_userprofile(id) ON DELETE CASCADE,
    interest VARCHAR(100) NOT NULL,
    UNIQUE(user_profile_id, interest)
);

CREATE INDEX idx_userinterest_user_profile ON myapp_userinterest(user_profile_id);
CREATE INDEX idx_userinterest_interest ON myapp_userinterest(interest);
```

**UserSkill Table:**
```sql
CREATE TABLE myapp_userskill (
    id SERIAL PRIMARY KEY,
    user_profile_id INTEGER NOT NULL REFERENCES myapp_userprofile(id) ON DELETE CASCADE,
    skill VARCHAR(100) NOT NULL,
    level VARCHAR(20) DEFAULT 'BEGINNER' CHECK (level IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT')),
    UNIQUE(user_profile_id, skill)
);

CREATE INDEX idx_userskill_user_profile ON myapp_userskill(user_profile_id);
CREATE INDEX idx_userskill_skill ON myapp_userskill(skill);
CREATE INDEX idx_userskill_level ON myapp_userskill(level);
```

### Database Optimization Strategies

#### Indexing Strategy

**Primary Indexes:**
- All foreign key columns have indexes for join performance
- Frequently queried columns (username, email, timestamps) have indexes
- JSONB columns use GIN indexes for efficient JSON queries

**Composite Indexes:**
- Event queries often filter by `is_public` and `end_time` together
- User profile queries combine `host_id` and `is_public`
- Auto-matching queries use `auto_matching_enabled` and `is_public`

**Partial Indexes:**
```sql
-- Index only active devices
CREATE INDEX idx_device_active ON myapp_device(token) WHERE is_active = TRUE;

-- Index only public events
CREATE INDEX idx_studyevent_public_time ON myapp_studyevent(time) WHERE is_public = TRUE;

-- Index only auto-matched invitations
CREATE INDEX idx_eventinvitation_auto ON myapp_eventinvitation(event_id, user_id) WHERE is_auto_matched = TRUE;
```

#### Query Optimization

**Common Query Patterns:**
```sql
-- Get user's events with attendees
SELECT se.*, array_agg(au.username) as attendees
FROM myapp_studyevent se
LEFT JOIN myapp_studyevent_attendees sea ON se.id = sea.studyevent_id
LEFT JOIN auth_user au ON sea.user_id = au.id
WHERE se.host_id = %s OR se.id IN (
    SELECT studyevent_id FROM myapp_studyevent_attendees WHERE user_id = %s
)
GROUP BY se.id;

-- Auto-matching query with location filtering
SELECT up.*, u.username, 
       ST_Distance(
           ST_Point(se.longitude, se.latitude)::geography,
           ST_Point(%s, %s)::geography
       ) as distance_km
FROM myapp_userprofile up
JOIN auth_user u ON up.user_id = u.id
JOIN myapp_studyevent se ON se.id = %s
WHERE up.auto_invite_enabled = TRUE
  AND up.user_id NOT IN (SELECT user_id FROM myapp_studyevent_attendees WHERE studyevent_id = %s)
  AND ST_DWithin(
      ST_Point(se.longitude, se.latitude)::geography,
      ST_Point(%s, %s)::geography,
      up.preferred_radius * 1000
  )
ORDER BY distance_km;
```

#### Database Maintenance

**Vacuum and Analyze:**
```sql
-- Regular maintenance for PostgreSQL
VACUUM ANALYZE myapp_studyevent;
VACUUM ANALYZE myapp_userprofile;
VACUUM ANALYZE myapp_userrating;

-- Update table statistics
ANALYZE myapp_studyevent;
ANALYZE myapp_userprofile;
ANALYZE myapp_userrating;
```

**Connection Pooling:**
```python
# Django settings for connection pooling
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'pinit_db',
        'USER': 'pinit_user',
        'PASSWORD': 'password',
        'HOST': 'localhost',
        'PORT': '5432',
        'OPTIONS': {
            'MAX_CONNS': 20,
            'MIN_CONNS': 5,
            'CONN_MAX_AGE': 600,  # 10 minutes
        }
    }
}
```

#### Migration Strategy

**Migration Best Practices:**
```python
# Example migration for adding indexes
from django.db import migrations

class Migration(migrations.Migration):
    dependencies = [
        ('myapp', '0001_initial'),
    ]

    operations = [
        migrations.RunSQL(
            "CREATE INDEX CONCURRENTLY idx_studyevent_public_end_time ON myapp_studyevent(is_public, end_time);",
            reverse_sql="DROP INDEX IF EXISTS idx_studyevent_public_end_time;"
        ),
    ]
```

**Data Migration Example:**
```python
def migrate_user_interests(apps, schema_editor):
    UserProfile = apps.get_model('myapp', 'UserProfile')
    UserInterest = apps.get_model('myapp', 'UserInterest')
    
    for profile in UserProfile.objects.all():
        if profile.interests:
            for interest in profile.interests:
                UserInterest.objects.create(
                    user_profile=profile,
                    interest=interest
                )

class Migration(migrations.Migration):
    operations = [
        migrations.RunPython(migrate_user_interests),
    ]
```

#### Performance Monitoring

**Query Performance Monitoring:**
```sql
-- Enable query logging
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_min_duration_statement = 1000; -- Log queries > 1 second

-- Monitor slow queries
SELECT query, mean_time, calls, total_time
FROM pg_stat_statements
WHERE mean_time > 1000
ORDER BY mean_time DESC;
```

**Database Size Monitoring:**
```sql
-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

## Testing Strategy Documentation

### Testing Framework Overview

**Backend Testing:**
- **Framework**: Django TestCase and pytest
- **Database**: SQLite for testing (fast, isolated)
- **Coverage**: pytest-cov for code coverage
- **Mocking**: unittest.mock for external dependencies

**Frontend Testing:**
- **iOS**: XCTest framework with SwiftUI testing
- **Android**: JUnit 4/5 with Espresso for UI testing
- **Unit Tests**: Isolated component testing
- **Integration Tests**: End-to-end user flows

### Backend Testing Strategy

#### Unit Testing

**Model Testing:**
```python
# tests/test_models.py
from django.test import TestCase
from django.contrib.auth.models import User
from myapp.models import UserProfile, StudyEvent, UserRating

class UserProfileModelTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            password='testpass123'
        )
        self.profile = self.user.userprofile
    
    def test_user_profile_creation(self):
        """Test that UserProfile is created automatically"""
        self.assertIsNotNone(self.profile)
        self.assertEqual(self.profile.user, self.user)
        self.assertFalse(self.profile.is_certified)
        self.assertTrue(self.profile.auto_invite_enabled)
    
    def test_interests_management(self):
        """Test interests getter and setter"""
        interests = ['Study Groups', 'Language Exchange']
        self.profile.set_interests(interests)
        self.assertEqual(self.profile.get_interests(), interests)
    
    def test_skills_management(self):
        """Test skills getter and setter"""
        skills = {'Python': 'ADVANCED', 'JavaScript': 'INTERMEDIATE'}
        self.profile.set_skills(skills)
        self.assertEqual(self.profile.get_skills(), skills)

class StudyEventModelTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='hostuser',
            password='testpass123'
        )
        self.event = StudyEvent.objects.create(
            title='Test Event',
            host=self.user,
            latitude=37.7749,
            longitude=-122.4194,
            time=timezone.now() + timedelta(hours=1)
        )
    
    def test_event_creation(self):
        """Test event creation with required fields"""
        self.assertEqual(self.event.title, 'Test Event')
        self.assertEqual(self.event.host, self.user)
        self.assertTrue(self.event.is_public)
        self.assertFalse(self.event.auto_matching_enabled)
    
    def test_interest_tags_management(self):
        """Test interest tags getter and setter"""
        tags = ['Study', 'Programming']
        self.event.set_interest_tags(tags)
        self.assertEqual(self.event.get_interest_tags(), tags)
    
    def test_invite_user_method(self):
        """Test inviting users to events"""
        invitee = User.objects.create_user(
            username='invitee',
            password='testpass123'
        )
        
        self.event.invite_user(invitee, is_auto_matched=True)
        
        # Check invitation record
        invitation = EventInvitation.objects.get(
            event=self.event,
            user=invitee
        )
        self.assertTrue(invitation.is_auto_matched)
        
        # Check invited friends
        self.assertIn(invitee, self.event.invited_friends.all())
```

**View Testing:**
```python
# tests/test_views.py
from django.test import TestCase, Client
from django.contrib.auth.models import User
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
import json

class AuthenticationAPITest(APITestCase):
    def setUp(self):
        self.client = Client()
        self.register_url = reverse('register')
        self.login_url = reverse('login')
    
    def test_user_registration(self):
        """Test user registration endpoint"""
        data = {
            'username': 'newuser',
            'password': 'newpass123'
        }
        response = self.client.post(
            self.register_url,
            data=json.dumps(data),
            content_type='application/json'
        )
        
        self.assertEqual(response.status_code, 201)
        self.assertTrue(response.json()['success'])
        self.assertIn('access_token', response.json())
        self.assertIn('refresh_token', response.json())
    
    def test_user_login(self):
        """Test user login endpoint"""
        # Create user first
        User.objects.create_user(
            username='testuser',
            password='testpass123'
        )
        
        data = {
            'username': 'testuser',
            'password': 'testpass123'
        }
        response = self.client.post(
            self.login_url,
            data=json.dumps(data),
            content_type='application/json'
        )
        
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()['success'])
        self.assertIn('access_token', response.json())

class EventAPITest(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            password='testpass123'
        )
        self.client.force_authenticate(user=self.user)
    
    def test_create_event(self):
        """Test event creation endpoint"""
        data = {
            'title': 'Test Study Session',
            'description': 'Group study for finals',
            'latitude': 37.7749,
            'longitude': -122.4194,
            'time': (timezone.now() + timedelta(hours=1)).isoformat(),
            'end_time': (timezone.now() + timedelta(hours=3)).isoformat(),
            'event_type': 'study',
            'is_public': True
        }
        
        response = self.client.post(
            reverse('create_study_event'),
            data=json.dumps(data),
            content_type='application/json'
        )
        
        self.assertEqual(response.status_code, 201)
        self.assertTrue(response.json()['success'])
        self.assertIn('event_id', response.json())
    
    def test_get_user_events(self):
        """Test getting user's events"""
        # Create an event
        StudyEvent.objects.create(
            title='Test Event',
            host=self.user,
            latitude=37.7749,
            longitude=-122.4194,
            time=timezone.now() + timedelta(hours=1)
        )
        
        response = self.client.get(
            reverse('get_study_events', args=[self.user.username])
        )
        
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.json()['events']), 1)
        self.assertEqual(response.json()['events'][0]['title'], 'Test Event')
```

#### Integration Testing

**Auto-Matching Integration Test:**
```python
# tests/test_auto_matching.py
from django.test import TestCase
from django.contrib.auth.models import User
from myapp.models import UserProfile, StudyEvent
from myapp.utils import perform_enhanced_auto_matching

class AutoMatchingIntegrationTest(TestCase):
    def setUp(self):
        # Create host user
        self.host = User.objects.create_user(
            username='host',
            password='testpass123'
        )
        self.host_profile = self.host.userprofile
        self.host_profile.set_interests(['Study Groups', 'Programming'])
        self.host_profile.university = 'Test University'
        self.host_profile.degree = 'Computer Science'
        self.host_profile.save()
        
        # Create potential attendees
        self.users = []
        for i in range(5):
            user = User.objects.create_user(
                username=f'user{i}',
                password='testpass123'
            )
            profile = user.userprofile
            profile.set_interests(['Study Groups', 'Programming'])
            profile.university = 'Test University'
            profile.degree = 'Computer Science'
            profile.auto_invite_enabled = True
            profile.save()
            self.users.append(user)
        
        # Create event
        self.event = StudyEvent.objects.create(
            title='Programming Study Group',
            description='Study Python and algorithms',
            host=self.host,
            latitude=37.7749,
            longitude=-122.4194,
            time=timezone.now() + timedelta(hours=1),
            auto_matching_enabled=True
        )
        self.event.set_interest_tags(['Programming', 'Study Groups'])
    
    def test_auto_matching_algorithm(self):
        """Test the complete auto-matching algorithm"""
        matched_users = perform_enhanced_auto_matching(
            self.event.id,
            max_invites=3,
            radius_km=10.0,
            min_score=30.0
        )
        
        # Should match users with similar interests and academic background
        self.assertGreater(len(matched_users), 0)
        self.assertLessEqual(len(matched_users), 3)
        
        # Check that matched users have high scores
        for match in matched_users:
            self.assertGreaterEqual(match['score'], 30.0)
            self.assertIn('username', match)
            self.assertIn('reasons', match)
    
    def test_auto_matching_excludes_host(self):
        """Test that host is not included in auto-matching"""
        matched_users = perform_enhanced_auto_matching(
            self.event.id,
            max_invites=10,
            radius_km=10.0,
            min_score=0.0
        )
        
        matched_usernames = [match['username'] for match in matched_users]
        self.assertNotIn('host', matched_usernames)
    
    def test_auto_matching_respects_preferences(self):
        """Test that auto-matching respects user preferences"""
        # Disable auto-invite for one user
        self.users[0].userprofile.auto_invite_enabled = False
        self.users[0].userprofile.save()
        
        matched_users = perform_enhanced_auto_matching(
            self.event.id,
            max_invites=10,
            radius_km=10.0,
            min_score=0.0
        )
        
        matched_usernames = [match['username'] for match in matched_users]
        self.assertNotIn('user0', matched_usernames)
```

**WebSocket Integration Test:**
```python
# tests/test_websocket.py
from channels.testing import WebsocketCommunicator
from django.test import TestCase
from django.contrib.auth.models import User
from myapp.consumers import EventsConsumer
from myapp.models import StudyEvent
from myapp.utils import broadcast_event_created

class WebSocketIntegrationTest(TestCase):
    async def test_events_websocket_connection(self):
        """Test WebSocket connection and event broadcasting"""
        user = User.objects.create_user(
            username='testuser',
            password='testpass123'
        )
        
        communicator = WebsocketCommunicator(
            EventsConsumer.as_asgi(),
            f"/ws/events/{user.username}/"
        )
        
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # Create an event and broadcast it
        event = StudyEvent.objects.create(
            title='Test Event',
            host=user,
            latitude=37.7749,
            longitude=-122.4194,
            time=timezone.now() + timedelta(hours=1)
        )
        
        broadcast_event_created(event.id, user.username)
        
        # Check if message was received
        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'create')
        self.assertEqual(response['event_id'], str(event.id))
        
        await communicator.disconnect()
```

#### Performance Testing

**Load Testing:**
```python
# tests/test_performance.py
from django.test import TestCase
from django.contrib.auth.models import User
from django.test.utils import override_settings
import time
from concurrent.futures import ThreadPoolExecutor

class PerformanceTest(TestCase):
    def setUp(self):
        # Create test users
        self.users = []
        for i in range(100):
            user = User.objects.create_user(
                username=f'user{i}',
                password='testpass123'
            )
            self.users.append(user)
    
    def test_event_creation_performance(self):
        """Test event creation performance with many users"""
        start_time = time.time()
        
        events_created = 0
        for user in self.users[:50]:  # Create events for first 50 users
            StudyEvent.objects.create(
                title=f'Event by {user.username}',
                host=user,
                latitude=37.7749,
                longitude=-122.4194,
                time=timezone.now() + timedelta(hours=1)
            )
            events_created += 1
        
        end_time = time.time()
        duration = end_time - start_time
        
        # Should create 50 events in reasonable time
        self.assertLess(duration, 5.0)  # Less than 5 seconds
        self.assertEqual(events_created, 50)
    
    def test_concurrent_event_access(self):
        """Test concurrent access to events"""
        # Create an event
        event = StudyEvent.objects.create(
            title='Concurrent Test Event',
            host=self.users[0],
            latitude=37.7749,
            longitude=-122.4194,
            time=timezone.now() + timedelta(hours=1)
        )
        
        def attend_event(user):
            event.attendees.add(user)
            return True
        
        # Simulate concurrent RSVPs
        start_time = time.time()
        with ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(attend_event, user) for user in self.users[:20]]
            results = [future.result() for future in futures]
        
        end_time = time.time()
        duration = end_time - start_time
        
        # All RSVPs should succeed
        self.assertTrue(all(results))
        self.assertEqual(event.attendees.count(), 20)
        self.assertLess(duration, 2.0)  # Less than 2 seconds
```

### Frontend Testing Strategy

#### iOS Testing

**Unit Tests:**
```swift
// PinItTests/CalendarManagerTests.swift
import XCTest
@testable import PinIt

class CalendarManagerTests: XCTestCase {
    var calendarManager: CalendarManager!
    var mockAccountManager: MockUserAccountManager!
    
    override func setUp() {
        super.setUp()
        mockAccountManager = MockUserAccountManager()
        calendarManager = CalendarManager(accountManager: mockAccountManager)
    }
    
    override func tearDown() {
        calendarManager = nil
        mockAccountManager = nil
        super.tearDown()
    }
    
    func testEventFetching() {
        // Given
        let expectation = XCTestExpectation(description: "Events fetched")
        mockAccountManager.currentUser = "testuser"
        
        // When
        calendarManager.fetchEvents()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testEventFiltering() {
        // Given
        let pastEvent = StudyEvent(
            id: UUID(),
            title: "Past Event",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            time: Date().addingTimeInterval(-3600), // 1 hour ago
            endTime: Date().addingTimeInterval(-1800), // 30 minutes ago
            description: nil,
            invitedFriends: [],
            attendees: [],
            isPublic: true,
            host: "testuser",
            hostIsCertified: false,
            eventType: .study,
            isAutoMatched: nil,
            interestTags: nil,
            matchedUsers: nil
        )
        
        let futureEvent = StudyEvent(
            id: UUID(),
            title: "Future Event",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            time: Date().addingTimeInterval(3600), // 1 hour from now
            endTime: Date().addingTimeInterval(7200), // 2 hours from now
            description: nil,
            invitedFriends: [],
            attendees: [],
            isPublic: true,
            host: "testuser",
            hostIsCertified: false,
            eventType: .study,
            isAutoMatched: nil,
            interestTags: nil,
            matchedUsers: nil
        )
        
        calendarManager.events = [pastEvent, futureEvent]
        
        // When
        let upcomingEvents = calendarManager.getUpcomingEvents()
        
        // Then
        XCTAssertEqual(upcomingEvents.count, 1)
        XCTAssertEqual(upcomingEvents.first?.title, "Future Event")
    }
}

// Mock classes for testing
class MockUserAccountManager: UserAccountManager {
    var mockCurrentUser: String?
    
    override var currentUser: String? {
        get { return mockCurrentUser }
        set { mockCurrentUser = newValue }
    }
}
```

**UI Tests:**
```swift
// PinItUITests/PinItUITests.swift
import XCTest

class PinItUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testLoginFlow() {
        // Test login screen
        let usernameField = app.textFields["Username"]
        let passwordField = app.secureTextFields["Password"]
        let loginButton = app.buttons["Login"]
        
        XCTAssertTrue(usernameField.exists)
        XCTAssertTrue(passwordField.exists)
        XCTAssertTrue(loginButton.exists)
        
        // Enter credentials
        usernameField.tap()
        usernameField.typeText("testuser")
        
        passwordField.tap()
        passwordField.typeText("testpass123")
        
        // Login
        loginButton.tap()
        
        // Verify navigation to main screen
        let mapView = app.otherElements["MapView"]
        XCTAssertTrue(mapView.waitForExistence(timeout: 5.0))
    }
    
    func testEventCreation() {
        // Login first
        loginUser()
        
        // Navigate to event creation
        let createEventButton = app.buttons["Create Event"]
        XCTAssertTrue(createEventButton.exists)
        createEventButton.tap()
        
        // Fill event form
        let titleField = app.textFields["Event Title"]
        titleField.tap()
        titleField.typeText("Test Study Session")
        
        let descriptionField = app.textViews["Description"]
        descriptionField.tap()
        descriptionField.typeText("Group study for finals")
        
        let createButton = app.buttons["Create"]
        createButton.tap()
        
        // Verify event was created
        let successAlert = app.alerts["Success"]
        XCTAssertTrue(successAlert.waitForExistence(timeout: 3.0))
    }
    
    private func loginUser() {
        let usernameField = app.textFields["Username"]
        let passwordField = app.secureTextFields["Password"]
        let loginButton = app.buttons["Login"]
        
        usernameField.tap()
        usernameField.typeText("testuser")
        
        passwordField.tap()
        passwordField.typeText("testpass123")
        
        loginButton.tap()
        
        // Wait for login to complete
        let mapView = app.otherElements["MapView"]
        XCTAssertTrue(mapView.waitForExistence(timeout: 5.0))
    }
}
```

#### Android Testing

**Unit Tests:**
```kotlin
// src/test/java/com/example/pinit/EventRepositoryTest.kt
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mock
import org.mockito.junit.MockitoJUnitRunner
import com.example.pinit.repository.EventRepository
import com.example.pinit.network.ApiService
import kotlinx.coroutines.test.runTest

@RunWith(MockitoJUnitRunner::class)
class EventRepositoryTest {
    
    @Mock
    private lateinit var apiService: ApiService
    
    private lateinit var eventRepository: EventRepository
    
    @Before
    fun setUp() {
        eventRepository = EventRepository(apiService)
    }
    
    @Test
    fun `getUserEvents should return events from API`() = runTest {
        // Given
        val username = "testuser"
        val mockEvents = listOf(
            StudyEvent(
                id = "1",
                title = "Test Event",
                host = "testuser",
                latitude = 37.7749,
                longitude = -122.4194,
                time = "2025-01-15T14:00:00Z",
                endTime = "2025-01-15T16:00:00Z",
                description = "Test description",
                invitedFriends = emptyList(),
                attendees = emptyList(),
                isPublic = true,
                hostIsCertified = false,
                eventType = "study",
                isAutoMatched = false,
                interestTags = emptyList(),
                matchedUsers = emptyList()
            )
        )
        
        val mockResponse = ApiEventsResponse(events = mockEvents)
        `when`(apiService.getUserEvents(username)).thenReturn(
            Response.success(mockResponse)
        )
        
        // When
        val result = eventRepository.getUserEvents(username)
        
        // Then
        assertTrue(result.isSuccess)
        assertEquals(1, result.getOrNull()?.size)
        assertEquals("Test Event", result.getOrNull()?.first()?.title)
    }
    
    @Test
    fun `createEvent should return success response`() = runTest {
        // Given
        val eventRequest = EventCreateRequest(
            title = "Test Event",
            description = "Test description",
            latitude = 37.7749,
            longitude = -122.4194,
            time = "2025-01-15T14:00:00Z",
            endTime = "2025-01-15T16:00:00Z",
            eventType = "study",
            isPublic = true
        )
        
        val mockResponse = EventResponse(
            success = true,
            message = "Event created successfully",
            eventId = "123"
        )
        
        `when`(apiService.createStudyEvent(eventRequest)).thenReturn(
            Response.success(mockResponse)
        )
        
        // When
        val result = eventRepository.createEvent(eventRequest)
        
        // Then
        assertTrue(result.isSuccess)
        assertEquals("123", result.getOrNull()?.eventId)
    }
}
```

**UI Tests:**
```kotlin
// src/androidTest/java/com/example/pinit/EventCreationUITest.kt
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class EventCreationUITest {
    
    @get:Rule
    val composeTestRule = createComposeRule()
    
    @Test
    fun eventCreationForm_displaysCorrectly() {
        composeTestRule.setContent {
            EventCreationView()
        }
        
        // Check if form elements are displayed
        composeTestRule.onNodeWithText("Event Title").assertIsDisplayed()
        composeTestRule.onNodeWithText("Description").assertIsDisplayed()
        composeTestRule.onNodeWithText("Location").assertIsDisplayed()
        composeTestRule.onNodeWithText("Date & Time").assertIsDisplayed()
        composeTestRule.onNodeWithText("Create Event").assertIsDisplayed()
    }
    
    @Test
    fun eventCreationForm_validatesRequiredFields() {
        composeTestRule.setContent {
            EventCreationView()
        }
        
        // Try to create event without filling required fields
        composeTestRule.onNodeWithText("Create Event").performClick()
        
        // Check if validation error is displayed
        composeTestRule.onNodeWithText("Title is required").assertIsDisplayed()
    }
    
    @Test
    fun eventCreationForm_createsEventSuccessfully() {
        composeTestRule.setContent {
            EventCreationView()
        }
        
        // Fill form
        composeTestRule.onNodeWithText("Event Title").performTextInput("Test Study Session")
        composeTestRule.onNodeWithText("Description").performTextInput("Group study for finals")
        
        // Select event type
        composeTestRule.onNodeWithText("Event Type").performClick()
        composeTestRule.onNodeWithText("Study").performClick()
        
        // Create event
        composeTestRule.onNodeWithText("Create Event").performClick()
        
        // Check if success message is displayed
        composeTestRule.onNodeWithText("Event created successfully").assertIsDisplayed()
    }
}
```

### Test Automation and CI/CD

**GitHub Actions Workflow:**
```yaml
# .github/workflows/test.yml
name: Test Suite

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:13
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.13'
    
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        pip install pytest pytest-cov pytest-django
    
    - name: Run tests
      run: |
        pytest --cov=myapp --cov-report=xml
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml

  ios-tests:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: latest-stable
    
    - name: Run iOS tests
      run: |
        xcodebuild test \
          -scheme PinIt \
          -destination 'platform=iOS Simulator,name=iPhone 14' \
          -enableCodeCoverage YES
    
    - name: Upload iOS coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml

  android-tests:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up JDK
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
    
    - name: Set up Android SDK
      uses: android-actions/setup-android@v2
    
    - name: Run Android tests
      run: |
        cd Front_End/Android/PinIt_Android
        ./gradlew test
        ./gradlew connectedAndroidTest
    
    - name: Upload Android coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml
```

### Test Data Management

**Test Fixtures:**
```python
# tests/fixtures.py
import json
from django.contrib.auth.models import User
from myapp.models import UserProfile, StudyEvent

def create_test_users(count=10):
    """Create test users with profiles"""
    users = []
    for i in range(count):
        user = User.objects.create_user(
            username=f'testuser{i}',
            password='testpass123',
            email=f'testuser{i}@example.com'
        )
        profile = user.userprofile
        profile.full_name = f'Test User {i}'
        profile.university = 'Test University'
        profile.degree = 'Computer Science'
        profile.set_interests(['Study Groups', 'Programming'])
        profile.save()
        users.append(user)
    return users

def create_test_events(host, count=5):
    """Create test events for a host"""
    events = []
    for i in range(count):
        event = StudyEvent.objects.create(
            title=f'Test Event {i}',
            description=f'Test description {i}',
            host=host,
            latitude=37.7749 + (i * 0.01),
            longitude=-122.4194 + (i * 0.01),
            time=timezone.now() + timedelta(hours=i+1),
            event_type='study',
            is_public=True
        )
        event.set_interest_tags(['Study Groups', 'Programming'])
        events.append(event)
    return events
```

### Performance Testing

**Load Testing with Locust:**
```python
# tests/load_test.py
from locust import HttpUser, task, between
import json
import random

class PinItUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        """Login user on start"""
        self.login()
    
    def login(self):
        """Login with test credentials"""
        response = self.client.post("/api/login/", json={
            "username": "testuser",
            "password": "testpass123"
        })
        if response.status_code == 200:
            self.token = response.json()["access_token"]
            self.headers = {"Authorization": f"Bearer {self.token}"}
    
    @task(3)
    def get_events(self):
        """Get user events"""
        self.client.get(
            "/api/get_study_events/testuser/",
            headers=self.headers
        )
    
    @task(1)
    def create_event(self):
        """Create a new event"""
        event_data = {
            "title": f"Load Test Event {random.randint(1, 1000)}",
            "description": "Load testing event",
            "latitude": 37.7749,
            "longitude": -122.4194,
            "time": "2025-01-15T14:00:00Z",
            "end_time": "2025-01-15T16:00:00Z",
            "event_type": "study",
            "is_public": True
        }
        self.client.post(
            "/api/create_study_event/",
            json=event_data,
            headers=self.headers
        )
    
    @task(2)
    def search_events(self):
        """Search for events"""
        queries = ["study", "programming", "group", "meeting"]
        query = random.choice(queries)
        self.client.get(
            f"/api/search_events/?query={query}",
            headers=self.headers
        )
```

### Test Coverage Goals

**Coverage Targets:**
- **Backend**: 90%+ code coverage
- **Critical Paths**: 100% coverage (authentication, event creation, auto-matching)
- **Models**: 95%+ coverage
- **Views**: 90%+ coverage
- **Utilities**: 85%+ coverage

**Frontend Coverage:**
- **iOS**: 80%+ code coverage
- **Android**: 80%+ code coverage
- **Critical UI Flows**: 100% coverage (login, event creation, map interaction)

### WebSocket System

#### Overview
The WebSocket system provides real-time communication between the backend and frontend clients. It handles event updates, notifications, and live data synchronization using Django Channels with Redis as the channel layer.

#### Backend WebSocket Implementation

**Consumer Architecture:**
```python
# myapp/consumers.py
import json
import asyncio
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth.models import User
from .models import StudyEvent, EventInvitation

class EventsConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        """Handle WebSocket connection"""
        self.username = self.scope['url_route']['kwargs']['username']
        self.group_name = f'events_{self.username}'
        
        # Join group
        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )
        
        await self.accept()
        
        # Send connection confirmation
        await self.send(text_data=json.dumps({
            'type': 'connection_established',
            'message': f'Connected to events channel for {self.username}'
        }))
    
    async def disconnect(self, close_code):
        """Handle WebSocket disconnection"""
        await self.channel_layer.group_discard(
            self.group_name,
            self.channel_name
        )
    
    async def receive(self, text_data):
        """Handle messages from WebSocket client"""
        try:
            data = json.loads(text_data)
            message_type = data.get('type')
            
            if message_type == 'ping':
                await self.send(text_data=json.dumps({
                    'type': 'pong',
                    'timestamp': data.get('timestamp')
                }))
            elif message_type == 'subscribe_event':
                event_id = data.get('event_id')
                await self.subscribe_to_event(event_id)
            elif message_type == 'unsubscribe_event':
                event_id = data.get('event_id')
                await self.unsubscribe_from_event(event_id)
                
        except json.JSONDecodeError:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Invalid JSON format'
            }))
    
    async def subscribe_to_event(self, event_id):
        """Subscribe to specific event updates"""
        try:
            event = await self.get_event(event_id)
            if event:
                event_group = f'event_{event_id}'
                await self.channel_layer.group_add(
                    event_group,
                    self.channel_name
                )
                await self.send(text_data=json.dumps({
                    'type': 'subscribed',
                    'event_id': event_id,
                    'message': f'Subscribed to event {event.title}'
                }))
        except Exception as e:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': f'Failed to subscribe to event: {str(e)}'
            }))
    
    async def unsubscribe_from_event(self, event_id):
        """Unsubscribe from specific event updates"""
        event_group = f'event_{event_id}'
        await self.channel_layer.group_discard(
            event_group,
            self.channel_name
        )
        await self.send(text_data=json.dumps({
            'type': 'unsubscribed',
            'event_id': event_id,
            'message': f'Unsubscribed from event {event_id}'
        }))
    
    # Event update handlers
    async def event_create(self, event):
        """Handle event creation broadcast"""
        await self.send(text_data=json.dumps({
            'type': 'event_create',
            'event_id': event['event_id'],
            'message': 'New event created'
        }))
    
    async def event_update(self, event):
        """Handle event update broadcast"""
        await self.send(text_data=json.dumps({
            'type': 'event_update',
            'event_id': event['event_id'],
            'message': 'Event updated'
        }))
    
    async def event_delete(self, event):
        """Handle event deletion broadcast"""
        await self.send(text_data=json.dumps({
            'type': 'event_delete',
            'event_id': event['event_id'],
            'message': 'Event deleted'
        }))
    
    async def invitation_received(self, event):
        """Handle invitation broadcast"""
        await self.send(text_data=json.dumps({
            'type': 'invitation_received',
            'event_id': event['event_id'],
            'inviter': event.get('inviter'),
            'message': 'You have been invited to an event'
        }))
    
    async def rsvp_update(self, event):
        """Handle RSVP update broadcast"""
        await self.send(text_data=json.dumps({
            'type': 'rsvp_update',
            'event_id': event['event_id'],
            'attendee': event.get('attendee'),
            'action': event.get('action'),
            'message': f"{event.get('attendee')} {event.get('action')} the event"
        }))
    
    @database_sync_to_async
    def get_event(self, event_id):
        """Get event from database"""
        try:
            return StudyEvent.objects.get(id=event_id)
        except StudyEvent.DoesNotExist:
            return None
```

**WebSocket Routing:**
```python
# myapp/routing.py
from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/events/(?P<username>\w+)/$', consumers.EventsConsumer.as_asgi()),
]
```

**Broadcasting Utilities:**
```python
# myapp/utils.py
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
import json

def _sanitize_group_name(name):
    """Sanitize group name for WebSocket channels"""
    return name.replace(' ', '_').replace('.', '_').replace('-', '_')

def broadcast_event_created(event_id, host_username, attendees=None, invited_friends=None):
    """Broadcast event creation to relevant users"""
    channel_layer = get_channel_layer()
    
    # Notify host
    host_group = f"events_{_sanitize_group_name(host_username)}"
    async_to_sync(channel_layer.group_send)(
        host_group,
        {
            "type": "event_create",
            "event_id": str(event_id)
        }
    )
    
    # Notify attendees
    if attendees:
        for username in attendees:
            group_name = f"events_{_sanitize_group_name(username)}"
            async_to_sync(channel_layer.group_send)(
                group_name,
                {
                    "type": "event_create",
                    "event_id": str(event_id)
                }
            )
    
    # Notify invited friends
    if invited_friends:
        for username in invited_friends:
            group_name = f"events_{_sanitize_group_name(username)}"
            async_to_sync(channel_layer.group_send)(
                group_name,
                {
                    "type": "invitation_received",
                    "event_id": str(event_id),
                    "inviter": host_username
                }
            )

def broadcast_event_update(event_id, event_type, usernames):
    """Broadcast event updates to relevant users"""
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
        group_name = f"events_{_sanitize_group_name(username)}"
        print(f"📢 Broadcasting {event_type} for event {event_id} to user: {username}")
        async_to_sync(channel_layer.group_send)(
            group_name,
            {
                "type": handler,
                "event_id": str(event_id)
            }
        )

def broadcast_rsvp_update(event_id, attendee_username, action):
    """Broadcast RSVP updates to event participants"""
    channel_layer = get_channel_layer()
    
    # Get event participants
    event = StudyEvent.objects.get(id=event_id)
    participants = list(event.attendees.values_list('username', flat=True))
    participants.extend(list(event.invited_friends.values_list('username', flat=True)))
    participants.append(event.host.username)
    
    # Remove duplicates
    participants = list(set(participants))
    
    for username in participants:
        group_name = f"events_{_sanitize_group_name(username)}"
        async_to_sync(channel_layer.group_send)(
            group_name,
            {
                "type": "rsvp_update",
                "event_id": str(event_id),
                "attendee": attendee_username,
                "action": action
            }
        )
```

#### Frontend WebSocket Implementation

**iOS WebSocket Manager:**
```swift
// EventsWebSocketManager.swift
import Foundation
import Combine

protocol EventsWebSocketManagerDelegate: AnyObject {
    func didReceiveEventUpdate(eventID: UUID)
    func didReceiveEventCreation(eventID: UUID)
    func didReceiveEventDeletion(eventID: UUID)
    func didReceiveInvitation(eventID: UUID, inviter: String)
    func didReceiveRSVPUpdate(eventID: UUID, attendee: String, action: String)
}

enum EventChangeType: String, Codable {
    case update = "update"
    case create = "create"
    case delete = "delete"
    case invitation = "invitation_received"
    case rsvp = "rsvp_update"
}

struct EventChangeMessage: Codable {
    let type: EventChangeType
    let eventID: UUID
    let inviter: String?
    let attendee: String?
    let action: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case eventID = "event_id"
        case inviter
        case attendee
        case action
    }
}

class EventsWebSocketManager: ObservableObject {
    weak var delegate: EventsWebSocketManagerDelegate?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)
    private let username: String
    
    @Published var isConnected = false
    @Published var connectionStatus: String = "Disconnected"
    
    private var reconnectAttempt = 0
    private var reconnectTimer: Timer?
    private var pingTimer: Timer?
    private var reconnectInterval: TimeInterval = 5.0
    private let maxReconnectInterval: TimeInterval = 60.0
    
    init(username: String) {
        self.username = username
    }
    
    func connect() {
        guard let url = URL(string: APIConfig.websocketURL(for: username)) else {
            print("❌ Invalid WebSocket URL")
            return
        }
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        listenForMessages()
        startPingTimer()
        
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectionStatus = "Connected"
            self.reconnectAttempt = 0
        }
        
        AppLogger.logWebSocket("Connected to WebSocket for user: \(username)")
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        pingTimer?.invalidate()
        pingTimer = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatus = "Disconnected"
        }
        
        AppLogger.logWebSocket("Disconnected from WebSocket")
    }
    
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.listenForMessages() // Continue listening
            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                self?.handleDisconnection()
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleTextMessage(text)
        case .data(let data):
            handleDataMessage(data)
        @unknown default:
            print("❌ Unknown WebSocket message type")
        }
    }
    
    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let message = try JSONDecoder().decode(EventChangeMessage.self, from: data)
            
            DispatchQueue.main.async {
                switch message.type {
                case .create:
                    self.delegate?.didReceiveEventCreation(eventID: message.eventID)
                case .update:
                    self.delegate?.didReceiveEventUpdate(eventID: message.eventID)
                case .delete:
                    self.delegate?.didReceiveEventDeletion(eventID: message.eventID)
                case .invitation:
                    if let inviter = message.inviter {
                        self.delegate?.didReceiveInvitation(eventID: message.eventID, inviter: inviter)
                    }
                case .rsvp:
                    if let attendee = message.attendee, let action = message.action {
                        self.delegate?.didReceiveRSVPUpdate(eventID: message.eventID, attendee: attendee, action: action)
                    }
                }
            }
            
            AppLogger.logWebSocket("Received message: \(message.type.rawValue) for event \(message.eventID)")
        } catch {
            print("❌ Failed to decode WebSocket message: \(error)")
        }
    }
    
    private func handleDataMessage(_ data: Data) {
        // Handle binary data if needed
        print("📦 Received binary WebSocket message")
    }
    
    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func sendPing() {
        let pingMessage = [
            "type": "ping",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: pingMessage),
              let message = String(data: data, encoding: .utf8) else {
            return
        }
        
        webSocketTask?.send(.string(message)) { error in
            if let error = error {
                print("❌ Ping failed: \(error)")
                self.handleDisconnection()
            }
        }
    }
    
    private func handleDisconnection() {
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatus = "Disconnected"
        }
        
        scheduleReconnect()
        AppLogger.logWebSocket("WebSocket disconnected, scheduling reconnect")
    }
    
    private func scheduleReconnect() {
        reconnectTimer?.invalidate()
        
        let delay = min(reconnectInterval * pow(2.0, Double(reconnectAttempt)), maxReconnectInterval)
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.reconnectAttempt += 1
            self?.connect()
        }
        
        DispatchQueue.main.async {
            self.connectionStatus = "Reconnecting in \(Int(delay))s..."
        }
    }
    
    func subscribeToEvent(_ eventID: UUID) {
        let message = [
            "type": "subscribe_event",
            "event_id": eventID.uuidString
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let messageString = String(data: data, encoding: .utf8) else {
            return
        }
        
        webSocketTask?.send(.string(messageString)) { error in
            if let error = error {
                print("❌ Failed to subscribe to event: \(error)")
            }
        }
    }
    
    func unsubscribeFromEvent(_ eventID: UUID) {
        let message = [
            "type": "unsubscribe_event",
            "event_id": eventID.uuidString
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let messageString = String(data: data, encoding: .utf8) else {
            return
        }
        
        webSocketTask?.send(.string(messageString)) { error in
            if let error = error {
                print("❌ Failed to unsubscribe from event: \(error)")
            }
        }
    }
}
```

**Android WebSocket Manager:**
```kotlin
// WebSocketManager.kt
import kotlinx.coroutines.*
import okhttp3.*
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class WebSocketManager(
    private val username: String,
    private val onMessageReceived: (String) -> Unit,
    private val onConnectionStatusChanged: (Boolean) -> Unit
) {
    private var webSocket: WebSocket? = null
    private var client: OkHttpClient? = null
    private var reconnectJob: Job? = null
    private var pingJob: Job? = null
    private var isConnected = false
    private var reconnectAttempt = 0
    private val maxReconnectAttempts = 10
    private val baseReconnectDelay = 5000L // 5 seconds
    
    fun connect() {
        if (isConnected) return
        
        client = OkHttpClient.Builder()
            .pingInterval(30, TimeUnit.SECONDS)
            .build()
        
        val request = Request.Builder()
            .url(getWebSocketUrl())
            .build()
        
        webSocket = client?.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                super.onOpen(webSocket, response)
                isConnected = true
                reconnectAttempt = 0
                onConnectionStatusChanged(true)
                startPingTimer()
                Log.d("WebSocket", "Connected for user: $username")
            }
            
            override fun onMessage(webSocket: WebSocket, text: String) {
                super.onMessage(webSocket, text)
                onMessageReceived(text)
                Log.d("WebSocket", "Message received: $text")
            }
            
            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                super.onFailure(webSocket, t, response)
                isConnected = false
                onConnectionStatusChanged(false)
                scheduleReconnect()
                Log.e("WebSocket", "Connection failed: ${t.message}")
            }
            
            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                super.onClosed(webSocket, code, reason)
                isConnected = false
                onConnectionStatusChanged(false)
                scheduleReconnect()
                Log.d("WebSocket", "Connection closed: $reason")
            }
        })
    }
    
    fun disconnect() {
        reconnectJob?.cancel()
        pingJob?.cancel()
        webSocket?.close(1000, "Normal closure")
        webSocket = null
        client = null
        isConnected = false
        onConnectionStatusChanged(false)
        Log.d("WebSocket", "Disconnected")
    }
    
    private fun startPingTimer() {
        pingJob = CoroutineScope(Dispatchers.IO).launch {
            while (isConnected) {
                delay(30000) // 30 seconds
                sendPing()
            }
        }
    }
    
    private fun sendPing() {
        val pingMessage = JSONObject().apply {
            put("type", "ping")
            put("timestamp", System.currentTimeMillis())
        }
        
        webSocket?.send(pingMessage.toString())
    }
    
    private fun scheduleReconnect() {
        if (reconnectAttempt >= maxReconnectAttempts) {
            Log.e("WebSocket", "Max reconnect attempts reached")
            return
        }
        
        reconnectJob?.cancel()
        reconnectJob = CoroutineScope(Dispatchers.IO).launch {
            val delay = minOf(
                baseReconnectDelay * (1 shl reconnectAttempt),
                60000L // Max 1 minute
            )
            
            delay(delay)
            reconnectAttempt++
            connect()
        }
    }
    
    fun subscribeToEvent(eventId: String) {
        val message = JSONObject().apply {
            put("type", "subscribe_event")
            put("event_id", eventId)
        }
        
        webSocket?.send(message.toString())
    }
    
    fun unsubscribeFromEvent(eventId: String) {
        val message = JSONObject().apply {
            put("type", "unsubscribe_event")
            put("event_id", eventId)
        }
        
        webSocket?.send(message.toString())
    }
    
    private fun getWebSocketUrl(): String {
        return "wss://pinit-backend-production.up.railway.app/ws/events/$username/"
    }
}
```

#### WebSocket Integration with Views

**Event Creation with WebSocket Broadcasting:**
```python
# myapp/views.py
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_study_event(request):
    """Create a new study event with WebSocket broadcasting"""
    try:
        data = json.loads(request.body)
        
        # Create event
        event = StudyEvent.objects.create(
            title=data['title'],
            description=data.get('description', ''),
            host=request.user,
            latitude=data['latitude'],
            longitude=data['longitude'],
            time=parse_datetime(data['time']),
            end_time=parse_datetime(data.get('end_time', data['time'])),
            event_type=data.get('event_type', 'other'),
            is_public=data.get('is_public', True),
            auto_matching_enabled=data.get('auto_matching_enabled', False)
        )
        
        # Set interest tags if provided
        if 'interest_tags' in data:
            event.set_interest_tags(data['interest_tags'])
        
        # Invite friends if provided
        invited_friends = []
        if 'invited_friends' in data:
            for friend_username in data['invited_friends']:
                try:
                    friend = User.objects.get(username=friend_username)
                    event.invite_user(friend)
                    invited_friends.append(friend_username)
                except User.DoesNotExist:
                    continue
        
        # Broadcast event creation via WebSocket
        broadcast_event_created(
            event.id,
            request.user.username,
            attendees=list(event.attendees.values_list('username', flat=True)),
            invited_friends=invited_friends
        )
        
        return JsonResponse({
            'success': True,
            'event_id': str(event.id),
            'message': 'Event created successfully'
        })
        
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
```

**RSVP with WebSocket Broadcasting:**
```python
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def rsvp_study_event(request):
    """RSVP to a study event with WebSocket broadcasting"""
    try:
        data = json.loads(request.body)
        event_id = data['event_id']
        action = data['action']  # 'attend' or 'decline'
        
        event = StudyEvent.objects.get(id=event_id)
        
        if action == 'attend':
            event.attendees.add(request.user)
            # Remove from invited friends if present
            event.invited_friends.remove(request.user)
        elif action == 'decline':
            # Create declined invitation record
            DeclinedInvitation.objects.get_or_create(
                user=request.user,
                event=event
            )
            # Remove from invited friends
            event.invited_friends.remove(request.user)
        
        # Broadcast RSVP update via WebSocket
        broadcast_rsvp_update(event_id, request.user.username, action)
        
        return JsonResponse({
            'success': True,
            'message': f'RSVP {action} successful'
        })
        
    except StudyEvent.DoesNotExist:
        return JsonResponse({'error': 'Event not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
```

#### WebSocket Performance and Monitoring

**Connection Management:**
```python
# myapp/middleware.py
class WebSocketConnectionMiddleware:
    """Middleware to track WebSocket connections"""
    
    def __init__(self, get_response):
        self.get_response = get_response
        self.active_connections = {}
    
    def __call__(self, request):
        response = self.get_response(request)
        return response
    
    def process_view(self, request, view_func, view_args, view_kwargs):
        if request.path.startswith('/ws/'):
            username = view_kwargs.get('username')
            if username:
                self.active_connections[username] = {
                    'connected_at': timezone.now(),
                    'last_ping': timezone.now()
                }
    
    def get_connection_stats(self):
        """Get WebSocket connection statistics"""
        return {
            'total_connections': len(self.active_connections),
            'connections': self.active_connections
        }
```

**WebSocket Health Monitoring:**
```python
# myapp/management/commands/websocket_health.py
from django.core.management.base import BaseCommand
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

class Command(BaseCommand):
    help = 'Check WebSocket health and connection status'
    
    def handle(self, *args, **options):
        channel_layer = get_channel_layer()
        
        # Send health check message to all groups
        async_to_sync(channel_layer.group_send)(
            'health_check',
            {
                'type': 'health_check',
                'timestamp': timezone.now().isoformat()
            }
        )
        
        self.stdout.write(
            self.style.SUCCESS('WebSocket health check sent')
        )
```

#### WebSocket Security

**Authentication and Authorization:**
```python
# myapp/consumers.py
from channels.auth import login, logout, get_user
from channels.db import database_sync_to_async

class AuthenticatedEventsConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        """Handle WebSocket connection with authentication"""
        # Get user from session
        self.user = await get_user(self.scope)
        
        if not self.user.is_authenticated:
            await self.close()
            return
        
        self.username = self.user.username
        self.group_name = f'events_{self.username}'
        
        # Join group
        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )
        
        await self.accept()
        
        # Log connection
        await self.log_connection('connect')
    
    async def disconnect(self, close_code):
        """Handle WebSocket disconnection"""
        await self.log_connection('disconnect')
        
        await self.channel_layer.group_discard(
            self.group_name,
            self.channel_name
        )
    
    @database_sync_to_async
    def log_connection(self, action):
        """Log WebSocket connection events"""
        # Log to database or external service
        pass
```

**Rate Limiting for WebSocket Messages:**
```python
# myapp/consumers.py
from django.core.cache import cache
import time

class RateLimitedEventsConsumer(AsyncWebsocketConsumer):
    async def receive(self, text_data):
        """Handle messages with rate limiting"""
        # Check rate limit
        if not await self.check_rate_limit():
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Rate limit exceeded'
            }))
            return
        
        # Process message
        await super().receive(text_data)
    
    async def check_rate_limit(self):
        """Check if user has exceeded rate limit"""
        cache_key = f'websocket_rate_limit_{self.username}'
        current_time = int(time.time())
        window_start = current_time - 60  # 1 minute window
        
        # Get current requests in window
        requests = cache.get(cache_key, [])
        requests = [req_time for req_time in requests if req_time > window_start]
        
        # Check if limit exceeded
        if len(requests) >= 100:  # 100 requests per minute
            return False
        
        # Add current request
        requests.append(current_time)
        cache.set(cache_key, requests, 60)
        
        return True
```

---

## API Reference

### Authentication Endpoints

#### Register User
```http
POST /api/register/
Content-Type: application/json

{
  "username": "string",
  "password": "string"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "User registered successfully.",
  "access_token": "jwt_access_token",
  "refresh_token": "jwt_refresh_token",
  "username": "string"
}
```

#### Login User
```http
POST /api/login/
Content-Type: application/json

{
  "username": "string",
  "password": "string"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Login successful.",
  "access_token": "jwt_access_token",
  "refresh_token": "jwt_refresh_token",
  "username": "string"
}
```

#### Refresh Token
```http
POST /api/token/refresh/
Content-Type: application/json

{
  "refresh": "jwt_refresh_token"
}
```

**Response (200):**
```json
{
  "access": "new_jwt_access_token"
}
```

### Event Endpoints

#### Get User Events
```http
GET /api/get_study_events/{username}/
Authorization: Bearer {access_token}
```

**Response (200):**
```json
{
  "events": [
    {
      "id": "uuid",
      "host": "username",
      "title": "string",
      "description": "string",
      "location": "string",
      "latitude": 0.0,
      "longitude": 0.0,
      "time": "2025-01-01T12:00:00Z",
      "end_time": "2025-01-01T14:00:00Z",
      "event_type": "Study",
      "attendees": ["username1", "username2"],
      "invited_friends": ["username3"],
      "is_public": true,
      "is_auto_matched": false,
      "created_at": "2025-01-01T10:00:00Z"
    }
  ]
}
```

#### Create Event
```http
POST /api/create_study_event/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "title": "string",
  "description": "string",
  "location": "string",
  "latitude": 0.0,
  "longitude": 0.0,
  "time": "2025-01-01T12:00:00Z",
  "end_time": "2025-01-01T14:00:00Z",
  "event_type": "Study",
  "invited_friends": ["username1", "username2"],
  "is_public": true
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Event created successfully",
  "event_id": "uuid"
}
```

#### Delete Event
```http
POST /api/delete_study_event/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "event_id": "uuid"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Event deleted successfully"
}
```

### Social Endpoints

#### Get Friends
```http
GET /api/get_friends/{username}/
Authorization: Bearer {access_token}
```

**Response (200):**
```json
{
  "friends": ["username1", "username2", "username3"]
}
```

#### Send Friend Request
```http
POST /api/send_friend_request/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "to_user": "username"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Friend request sent"
}
```

#### Accept Friend Request
```http
POST /api/accept_friend_request/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "from_user": "username"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Friend request accepted"
}
```

### Account Management

#### Submit User Rating
```http
POST /api/submit_user_rating/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "to_username": "string",
  "rating": 5,
  "reference": "Great study partner!",
  "event_id": "uuid"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Rating submitted successfully"
}
```

#### Upload User Image
```http
POST /api/upload_user_image/
Authorization: Bearer {access_token}
Content-Type: multipart/form-data

image: [file]
image_type: "profile|gallery|cover"
is_primary: "true|false"
caption: "string"
```

**Response (200):**
```json
{
  "success": true,
  "message": "Image uploaded successfully",
  "image": {
    "id": "uuid",
    "url": "https://cdn.example.com/image.jpg",
    "image_type": "profile",
    "is_primary": true,
    "caption": "My profile picture",
    "uploaded_at": "2025-01-01T12:00:00Z"
  }
}
```

#### Get User Images
```http
GET /api/user_images/{username}/
Authorization: Bearer {access_token}
```

**Response (200):**
```json
{
  "images": [
    {
      "id": "uuid",
      "url": "https://cdn.example.com/image.jpg",
      "image_type": "profile",
      "is_primary": true,
      "caption": "Profile picture",
      "uploaded_at": "2025-01-01T12:00:00Z"
    }
  ]
}
```

#### Get User Preferences
```http
GET /api/user_preferences/{username}/
Authorization: Bearer {access_token}
```

**Response (200):**
```json
{
  "matching_preferences": {
    "allow_auto_matching": true,
    "preferred_radius": 10.0,
    "interests": ["Study Groups", "Language Exchange"],
    "skills": ["Programming", "Design"],
    "university": "University of Buenos Aires",
    "degree": "Computer Science",
    "year": "Junior"
  },
  "privacy_settings": {
    "show_online_status": true,
    "allow_tagging": true,
    "allow_direct_messages": true,
    "show_activity_status": true
  },
  "notification_settings": {
    "enable_notifications": true,
    "event_reminders": true,
    "friend_requests": true,
    "event_invitations": true,
    "rating_notifications": true
  },
  "app_settings": {
    "dark_mode": false,
    "accent_color": "Blue",
    "font_size": "Medium",
    "language": "English"
  }
}
```

#### Register Device for Push Notifications
```http
POST /api/register-device/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "device_token": "apns_device_token",
  "platform": "ios"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Device registered successfully"
}
```

### Error Responses

**Common Error Codes:**
- `400` - Bad Request (invalid data)
- `401` - Unauthorized (invalid/missing token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found (resource doesn't exist)
- `429` - Too Many Requests (rate limited)
- `500` - Internal Server Error

**Error Response Format:**
```json
{
  "error": "Error description",
  "details": "Additional details"
}
```

---

## WebSocket Real-Time System

### Complete WebSocket Architecture

#### Server-Side Implementation

**WebSocket Routing (routing.py):**
```python
websocket_urlpatterns = [
    re_path(r"ws/chat/(?P<sender>\w+)/(?P<receiver>\w+)/$", ChatConsumer.as_asgi()),
    re_path(r"ws/group_chat/(?P<event_id>[^/]+)/$", GroupChatConsumer.as_asgi()),
    re_path(r"ws/events/(?P<username>\w+)/$", EventsConsumer.as_asgi()),
]
```

**ASGI Configuration (asgi.py):**
```python
application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": AuthMiddlewareStack(
        URLRouter(websocket_urlpatterns)
    ),
})
```

**Channel Layers Configuration (settings.py):**
```python
# Redis-based channel layers for production
if os.environ.get('REDIS_URL'):
    CHANNEL_LAYERS = {
        "default": {
            "BACKEND": "channels_redis.core.RedisChannelLayer",
            "CONFIG": {
                "hosts": [os.environ.get('REDIS_URL')],
            },
        },
    }
else:
    # In-memory fallback for development
    CHANNEL_LAYERS = {
        "default": {
            "BACKEND": "channels.layers.InMemoryChannelLayer",
        },
    }
```

#### WebSocket Consumers

**EventsConsumer - Real-time Event Updates:**
```python
class EventsConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        # Get username from URL path
        self.username = self.scope["url_route"]["kwargs"]["username"]
        # Sanitize username for group name
        sanitized_username = sanitize_username(self.username)
        self.user_events_group = f"events_{sanitized_username}"
        
        # Join user-specific events group
        await self.channel_layer.group_add(self.user_events_group, self.channel_name)
        await self.accept()
    
    async def disconnect(self, close_code):
        # Leave events group
        await self.channel_layer.group_discard(self.user_events_group, self.channel_name)
    
    # Message handlers for different event types
    async def event_update(self, event):
        event_id = event["event_id"]
        await self.send(text_data=json.dumps({
            "type": "update",
            "event_id": str(event_id)
        }))
    
    async def event_create(self, event):
        event_id = event["event_id"]
        await self.send(text_data=json.dumps({
            "type": "create",
            "event_id": str(event_id)
        }))
    
    async def event_delete(self, event):
        event_id = event["event_id"]
        await self.send(text_data=json.dumps({
            "type": "delete",
            "event_id": str(event_id)
        }))
```

**ChatConsumer - Private Messaging:**
```python
class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.sender = self.scope["url_route"]["kwargs"]["sender"]
        self.receiver = self.scope["url_route"]["kwargs"]["receiver"]
        self.room_name = f"private_chat_{self.sender}_{self.receiver}"
        
        # Join private chat room
        await self.channel_layer.group_add(self.room_name, self.channel_name)
        await self.accept()
    
    async def receive(self, text_data):
        data = json.loads(text_data)
        sender = data.get("sender")
        receiver = data.get("receiver")
        message = data.get("message")
        
        # Broadcast message to chat room
        await self.channel_layer.group_send(
            self.room_name,
            {
                "type": "chat_message",
                "sender": sender,
                "message": message
            }
        )
    
    async def chat_message(self, event):
        # Send message to WebSocket clients
        await self.send(text_data=json.dumps({
            "sender": event["sender"],
            "message": event["message"]
        }))
```

**GroupChatConsumer - Event Group Chats:**
```python
class GroupChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.event_id = self.scope["url_route"]["kwargs"]["event_id"]
        self.room_group_name = f"group_chat_{self.event_id}"
        
        # Join event-specific group chat
        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()
    
    async def receive(self, text_data=None, bytes_data=None):
        # Handle both text and binary messages
        data = json.loads(text_data or bytes_data.decode('utf-8'))
        sender = data.get("sender", "Unknown")
        message = data.get("message", "")
        
        # Broadcast to group
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "groupchat.message",
                "sender": sender,
                "message": message,
            }
        )
    
    async def groupchat.message(self, event):
        # Send message to all group members
        await self.send(text_data=json.dumps({
            "sender": event["sender"],
            "message": event["message"],
        }))
```

#### Server-Side Broadcasting Utilities

**Broadcasting Functions (utils.py):**
```python
def broadcast_event_update(event_id, event_type, usernames):
    """
    Broadcast event update to multiple users
    Args:
        event_id (str): UUID of the event
        event_type (str): 'create', 'update', or 'delete'
        usernames (list): List of usernames to notify
    """
    channel_layer = get_channel_layer()
    
    if not usernames:
        return
    
    # Map event_type to consumer handler method
    handler_map = {
        'create': 'event_create',
        'update': 'event_update',
        'delete': 'event_delete'
    }
    
    handler = handler_map.get(event_type, 'event_update')
    
    # Notify each user
    for username in usernames:
        group_name = f"events_{_sanitize_group_name(username)}"
        async_to_sync(channel_layer.group_send)(
            group_name,
            {
                "type": handler,
                "event_id": str(event_id)
            }
        )

def broadcast_event_created(event_id, host_username, invited_friends=[]):
    """Notify host and invited friends of new event"""
    users_to_notify = [host_username] + invited_friends
    broadcast_event_update(event_id, 'create', users_to_notify)

def broadcast_event_updated(event_id, host_username, attendees=[], invited_friends=[]):
    """Notify host, attendees, and invited friends of event update"""
    users_to_notify = [host_username] + attendees + invited_friends
    broadcast_event_update(event_id, 'update', users_to_notify)

def broadcast_event_deleted(event_id, host_username, attendees=[], invited_friends=[]):
    """Notify host, attendees, and invited friends of event deletion"""
    users_to_notify = [host_username] + attendees + invited_friends
    broadcast_event_update(event_id, 'delete', users_to_notify)
```

#### Client-Side Implementation (iOS)

**EventsWebSocketManager.swift - Real-time Event Updates:**
```swift
class EventsWebSocketManager: ObservableObject {
    @Published var isConnected = false
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)
    private let username: String
    
    // Connection management
    private var reconnectAttempt = 0
    private var reconnectTimer: Timer?
    private var pingTimer: Timer?
    private var reconnectInterval: TimeInterval = 5.0
    private let maxReconnectInterval: TimeInterval = 60.0
    
    init(username: String) {
        self.username = username
    }
    
    func connect() {
        // Use API configuration for WebSocket URL
        let wsBaseURL = APIConfig.websocketURL
        guard let url = URL(string: "\(wsBaseURL)events/\(username)/") else {
            AppLogger.error("Invalid WebSocket URL", category: AppLogger.websocket)
            return
        }
        
        // Close existing connection
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        
        // Create new connection
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Start listening for messages
        listenForMessages()
        
        // Start periodic pings
        startPingTimer()
    }
    
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.listenForMessages() // Continue listening
            case .failure(let error):
                AppLogger.error("WebSocket receive error: \(error)", category: AppLogger.websocket)
                self?.handleDisconnection()
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            if let data = text.data(using: .utf8),
               let eventMessage = try? JSONDecoder().decode(EventChangeMessage.self, from: data) {
                DispatchQueue.main.async {
                    self.delegate?.didReceiveEventUpdate(eventID: eventMessage.eventID)
                }
            }
        case .data(let data):
            // Handle binary messages if needed
            break
        @unknown default:
            break
        }
    }
    
    private func startPingTimer() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func sendPing() {
        webSocketTask?.sendPing { error in
            if let error = error {
                AppLogger.error("WebSocket ping failed: \(error)", category: AppLogger.websocket)
                self.handleDisconnection()
            }
        }
    }
    
    private func handleDisconnection() {
        DispatchQueue.main.async {
            self.isConnected = false
        }
        scheduleReconnect()
    }
    
    private func scheduleReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval, repeats: false) { [weak self] _ in
            self?.connect()
            self?.reconnectAttempt += 1
            self?.reconnectInterval = min(self?.reconnectInterval ?? 5.0 * 2, self?.maxReconnectInterval ?? 60.0)
        }
    }
}

// Message structures
struct EventChangeMessage: Codable {
    let type: EventChangeType
    let eventID: UUID
    
    enum CodingKeys: String, CodingKey {
        case type
        case eventID = "event_id"
    }
}

enum EventChangeType: String, Codable {
    case update = "update"
    case create = "create"
    case delete = "delete"
}
```

**GroupChatWebSocketManager.swift - Event Group Chats:**
```swift
class GroupChatWebSocketManager: ObservableObject {
    @Published var isConnected = false
    @Published var messages: [ChatMessage] = []
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let eventId: String
    
    init(eventId: String) {
        self.eventId = eventId
    }
    
    func connect() {
        let wsBaseURL = APIConfig.websocketURL
        guard let url = URL(string: "\(wsBaseURL)group_chat/\(eventId)/") else {
            return
        }
        
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        
        listenForMessages()
        isConnected = true
    }
    
    func sendMessage(_ message: String, sender: String) {
        let messageData = [
            "sender": sender,
            "message": message
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: messageData)
            webSocketTask?.send(.data(data)) { error in
                if let error = error {
                    AppLogger.error("Failed to send chat message: \(error)")
                }
            }
        } catch {
            AppLogger.error("Failed to serialize chat message: \(error)")
        }
    }
    
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.listenForMessages()
            case .failure(let error):
                AppLogger.error("Group chat WebSocket error: \(error)")
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            if let data = text.data(using: .utf8),
               let messageData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let sender = messageData["sender"] as? String,
               let messageText = messageData["message"] as? String {
                
                let chatMessage = ChatMessage(
                    id: UUID(),
                    sender: sender,
                    message: messageText,
                    timestamp: Date()
                )
                
                DispatchQueue.main.async {
                    self.messages.append(chatMessage)
                }
            }
        case .data(_):
            break
        @unknown default:
            break
        }
    }
}
```

### WebSocket URL Patterns

#### Event Updates
```
wss://pinit-backend-production.up.railway.app/ws/events/{username}/
```
- **Purpose**: Real-time event updates for specific user
- **Messages**: `create`, `update`, `delete` event notifications
- **Authentication**: Username-based routing
- **Reconnection**: Automatic with exponential backoff

#### Private Chat
```
wss://pinit-backend-production.up.railway.app/ws/chat/{sender}/{receiver}/
```
- **Purpose**: Private messaging between two users
- **Messages**: Text messages with sender/receiver info
- **Room Management**: Automatic room creation based on user pair
- **Message History**: Not persisted (real-time only)

#### Group Chat
```
wss://pinit-backend-production.up.railway.app/ws/group_chat/{event_id}/
```
- **Purpose**: Group messaging for event attendees
- **Messages**: Text messages with sender info
- **Participants**: All event attendees and host
- **Event Integration**: Tied to specific event ID

### Message Formats

#### Event Change Messages
```json
{
  "type": "update|create|delete",
  "event_id": "uuid-string"
}
```

#### Chat Messages
```json
{
  "sender": "username",
  "message": "message text"
}
```

#### Group Chat Messages
```json
{
  "sender": "username",
  "message": "message text"
}
```

### Connection Lifecycle

#### Client Connection Flow
1. **Initialization**: Create WebSocket manager with username
2. **Connection**: Establish WebSocket connection to appropriate URL
3. **Authentication**: Username-based routing (no additional auth needed)
4. **Message Listening**: Start receiving messages
5. **Ping/Pong**: Periodic health checks every 20 seconds
6. **Reconnection**: Automatic reconnection on disconnection
7. **Cleanup**: Proper disconnection on app termination

#### Server Broadcasting Flow
1. **Event Action**: User performs action (create/update/delete event)
2. **Broadcast Trigger**: Backend calls appropriate broadcast function
3. **User Identification**: Determine which users should be notified
4. **Group Messaging**: Send message to user-specific WebSocket groups
5. **Message Delivery**: WebSocket consumers deliver messages to clients
6. **Client Processing**: iOS clients receive and process messages

### Error Handling & Resilience

#### Connection Failures
- **Automatic Reconnection**: Exponential backoff (5s → 60s max)
- **Connection Health**: Ping/pong every 20 seconds
- **Graceful Degradation**: Fallback to polling if WebSocket fails
- **User Notification**: Connection status indicators in UI

#### Message Processing
- **JSON Parsing**: Robust parsing with fallback handling
- **Message Validation**: Validate message structure before processing
- **Error Logging**: Comprehensive logging for debugging
- **Retry Logic**: Retry failed message processing

#### Server-Side Resilience
- **Group Management**: Automatic group cleanup on disconnect
- **Message Queuing**: Queue messages for offline users (if needed)
- **Rate Limiting**: Prevent WebSocket spam
- **Resource Management**: Proper cleanup of WebSocket connections

---

## Advanced Features & Algorithms

### Auto-Matching System

#### Overview
The auto-matching system uses sophisticated algorithms to automatically invite users to events based on multiple compatibility factors. It implements a weighted scoring system that considers interests, location, social connections, academic background, and user reputation.

**🔒 Privacy-Focused Design:**
- **Auto-matched events are only visible to matched users** - not exposed to everyone
- **Public events**: Visible to everyone + auto-matched users
- **Private events**: Visible only to invited friends + auto-matched users
- **Enhanced privacy**: Users only see events they're actually matched for
- **Reduced noise**: More targeted, relevant event discovery

#### Complete Scoring Algorithm

**Weight Configuration:**
```python
WEIGHTS = {
    'interest_match': 25.0,        # Points per matching interest
    'interest_ratio': 30.0,        # Max points for high interest match ratio
    'content_similarity': 20.0,    # Max points for content similarity
    'location': 15.0,              # Max points for location proximity
    'social': 20.0,                # Max points for social relevance
    'academic_similarity': 25.0,   # University, degree, year matching
    'skill_relevance': 20.0,       # Skill matching for relevant events
    'bio_similarity': 15.0,        # Bio content similarity
    'reputation_boost': 15.0,      # User reputation/trust level
    'event_type_preference': 10.0, # Event type preferences
    'time_compatibility': 10.0,    # Time pattern compatibility
    'activity_level': 10.0,        # User activity level
}
```

**Detailed Matching Process:**

1. **Interest Matching (25-30 points):**
   ```python
   def calculate_interest_score(user_interests, event_interests):
       if not user_interests or not event_interests:
           return 0
       
       # Direct interest overlap
       matching_interests = set(user_interests).intersection(set(event_interests))
       direct_score = len(matching_interests) * WEIGHTS['interest_match']
       
       # Interest ratio bonus
       ratio = len(matching_interests) / len(user_interests)
       ratio_score = min(ratio * WEIGHTS['interest_ratio'], WEIGHTS['interest_ratio'])
       
       return direct_score + ratio_score
   ```

2. **Content Similarity (20 points):**
   ```python
   def calculate_content_similarity(user_profile, event):
       # Combine user bio and interests for semantic analysis
       user_content = f"{user_profile.bio} {' '.join(user_profile.get_interests())}"
       event_content = f"{event.title} {event.description or ''}"
       
       # Use sentence transformers for semantic similarity
       if SEMANTIC_SEARCH_AVAILABLE:
           similarity = calculate_semantic_similarity(user_content, event_content)
           return similarity * WEIGHTS['content_similarity']
       
       # Fallback to keyword matching
       return calculate_keyword_similarity(user_content, event_content) * WEIGHTS['content_similarity']
   ```

3. **Location Proximity (15 points):**
   ```python
   def calculate_location_score(user_location, event_location, max_radius=10.0):
       distance_km = calculate_haversine_distance(user_location, event_location)
       
       if distance_km > max_radius:
           return 0
       
       # Exponential decay scoring
       score = WEIGHTS['location'] * math.exp(-distance_km / (max_radius / 3))
       return score
   ```

4. **Social Relevance (20 points):**
   ```python
   def calculate_social_score(user_profile, event_host, host_friends):
       score = 0
       
       # Mutual friends bonus
       user_friends = set(user_profile.friends.values_list('user_id', flat=True))
       mutual_friends = user_friends.intersection(host_friends)
       score += len(mutual_friends) * 5.0  # 5 points per mutual friend
       
       # Friend-of-friend connections
       friend_of_friend_score = calculate_friend_of_friend_score(user_profile, event_host)
       score += friend_of_friend_score
       
       return min(score, WEIGHTS['social'])
   ```

5. **Academic Similarity (25 points):**
   ```python
   def calculate_academic_score(user_profile, event):
       score = 0
       
       # University matching
       if user_profile.university and event.host.userprofile.university:
           if user_profile.university == event.host.userprofile.university:
               score += 10.0
       
       # Degree program alignment
       if user_profile.degree and event.host.userprofile.degree:
           if are_related_fields(user_profile.degree, event.host.userprofile.degree):
               score += 8.0
       
       # Academic year compatibility
       if user_profile.year and event.host.userprofile.year:
           if are_compatible_years(user_profile.year, event.host.userprofile.year):
               score += 7.0
       
       return min(score, WEIGHTS['academic_similarity'])
   ```

6. **Skill Relevance (20 points):**
   ```python
   def calculate_skill_score(user_skills, event_requirements):
       if not event_requirements:
           return 0
       
       score = 0
       user_skills_dict = user_profile.get_skills()
       
       for required_skill, required_level in event_requirements.items():
           if required_skill in user_skills_dict:
               user_level = user_skills_dict[required_skill]
               skill_match_score = calculate_skill_level_match(user_level, required_level)
               score += skill_match_score
       
       return min(score, WEIGHTS['skill_relevance'])
   ```

7. **Reputation Boost (15 points):**
   ```python
   def calculate_reputation_score(user_profile):
       try:
           reputation_stats = user_profile.user.reputation_stats
           if not reputation_stats:
               return 0
           
           # Trust level bonus
           trust_level_bonus = reputation_stats.trust_level.level * 2.0
           
           # Rating bonus
           rating_bonus = (reputation_stats.average_rating - 3.0) * 3.0
           
           # Activity bonus
           activity_bonus = min(reputation_stats.events_attended / 10.0, 5.0)
           
           total_score = trust_level_bonus + rating_bonus + activity_bonus
           return min(total_score, WEIGHTS['reputation_boost'])
       except:
           return 0
   ```

8. **Event Type Preference (10 points):**
   ```python
   def calculate_event_type_score(user_profile, event):
       # Analyze user's historical event preferences
       user_event_history = StudyEvent.objects.filter(
           attendees=user_profile.user
       ).values_list('event_type', flat=True)
       
       if not user_event_history:
           return 0
       
       # Calculate preference score based on event type frequency
       event_type_counts = Counter(user_event_history)
       total_events = len(user_event_history)
       
       preference_score = (event_type_counts.get(event.event_type, 0) / total_events) * WEIGHTS['event_type_preference']
       return preference_score
   ```

9. **Time Compatibility (10 points):**
   ```python
   def calculate_time_compatibility(user_profile, event):
       # Analyze user's typical activity times
       user_events = StudyEvent.objects.filter(
           attendees=user_profile.user
       ).values_list('time', flat=True)
       
       if not user_events:
           return 0
       
       # Calculate preferred time patterns
       preferred_hours = [event_time.hour for event_time in user_events]
       event_hour = event.time.hour
       
       # Score based on how close event time is to user's preferred times
       time_score = calculate_time_pattern_match(event_hour, preferred_hours)
       return time_score * WEIGHTS['time_compatibility']
   ```

10. **Activity Level (10 points):**
    ```python
    def calculate_activity_score(user_profile):
        # Recent activity analysis
        recent_events = StudyEvent.objects.filter(
            attendees=user_profile.user,
            time__gte=timezone.now() - timedelta(days=30)
        ).count()
        
        # Response rate to invitations
        total_invitations = EventInvitation.objects.filter(user=user_profile.user).count()
        accepted_invitations = StudyEvent.objects.filter(
            attendees=user_profile.user,
            invitation_records__user=user_profile.user
        ).count()
        
        response_rate = accepted_invitations / max(total_invitations, 1)
        
        # Combine recent activity and response rate
        activity_score = (recent_events * 0.5) + (response_rate * 5.0)
        return min(activity_score, WEIGHTS['activity_level'])
    ```

#### Enhanced Auto-Matching Implementation

**Main Auto-Matching Function:**
```python
def perform_enhanced_auto_matching(event_id, max_invites=10, radius_km=10.0, min_score=30.0):
    """
    Performs intelligent auto-matching with enhanced scoring algorithm
    """
    try:
    # Get event and host details
        event = StudyEvent.objects.select_related('host__userprofile').prefetch_related(
            'invited_friends', 'attendees', 'invitation_records'
    ).get(id=event_id)
        
        host_profile = event.host.userprofile
    
    # Get host's friends for social relevance
        host_friends = set(host_profile.friends.values_list('user_id', flat=True))
    
    # Find potential users with auto-invite enabled
        already_involved_ids = set()
        already_involved_ids.add(event.host.id)
        already_involved_ids.update(event.invited_friends.values_list('id', flat=True))
        already_involved_ids.update(event.attendees.values_list('id', flat=True))
        
    potential_users = UserProfile.objects.filter(
        auto_invite_enabled=True
    ).exclude(
        user__id__in=already_involved_ids
        ).select_related('user').prefetch_related(
            'interest_items', 'skill_items', 'reputation_stats'
        )
    
    # Score and rank users
    scored_users = []
    for profile in potential_users:
            try:
                score = calculate_comprehensive_score(profile, event, host_friends, radius_km)
                if score >= min_score:
            scored_users.append((profile, score))
            except Exception as e:
                print(f"Error scoring user {profile.user.username}: {e}")
                continue
    
    # Sort by score and invite top users
    scored_users.sort(key=lambda x: x[1], reverse=True)
        
        invited_users = []
        for profile, score in scored_users[:max_invites]:
            try:
                # Create invitation record
                EventInvitation.objects.update_or_create(
                    event=event,
                    user=profile.user,
                    defaults={'is_auto_matched': True}
                )
                
                # Add to invited friends
                event.invited_friends.add(profile.user)
                
                invited_users.append({
                    'username': profile.user.username,
                    'score': score,
                    'reasons': get_matching_reasons(profile, event, score)
                })
                
            except Exception as e:
                print(f"Error inviting user {profile.user.username}: {e}")
                continue
        
        return invited_users
        
    except Exception as e:
        print(f"Error in auto-matching: {e}")
        return []

def calculate_comprehensive_score(user_profile, event, host_friends, radius_km):
    """Calculate comprehensive matching score"""
    total_score = 0
    
    # Interest matching
    total_score += calculate_interest_score(
        user_profile.get_interests(), 
        event.get_interest_tags()
    )
    
    # Content similarity
    total_score += calculate_content_similarity(user_profile, event)
    
    # Location proximity
    user_location = get_user_location(user_profile)
    if user_location:
        total_score += calculate_location_score(
            user_location, 
            (event.latitude, event.longitude), 
            radius_km
        )
    
    # Social relevance
    total_score += calculate_social_score(user_profile, event.host, host_friends)
    
    # Academic similarity
    total_score += calculate_academic_score(user_profile, event)
    
    # Skill relevance
    total_score += calculate_skill_score(
        user_profile.get_skills(), 
        event.get_skill_requirements()
    )
    
    # Reputation boost
    total_score += calculate_reputation_score(user_profile)
    
    # Event type preference
    total_score += calculate_event_type_score(user_profile, event)
    
    # Time compatibility
    total_score += calculate_time_compatibility(user_profile, event)
    
    # Activity level
    total_score += calculate_activity_score(user_profile)
    
    return total_score
```

#### Performance Optimizations

**Caching Strategies:**
```python
# Cache user scores for 15 minutes
@cache_result(timeout=900)
def calculate_user_score_cached(user_id, event_id):
    return calculate_comprehensive_score(user_profile, event, host_friends, radius_km)

# Cache interest matches for 1 hour
@cache_result(timeout=3600)
def get_user_interests_cached(user_id):
    return UserProfile.objects.get(user_id=user_id).get_interests()
```

**Batch Processing:**
```python
def batch_auto_matching(event_ids, max_invites_per_event=10):
    """Process multiple events for auto-matching efficiently"""
    events = StudyEvent.objects.filter(id__in=event_ids).prefetch_related(
        'host__userprofile', 'invited_friends', 'attendees'
    )
    
    results = {}
    for event in events:
        results[event.id] = perform_enhanced_auto_matching(
            event.id, max_invites_per_event
        )
    
    return results
```

#### Auto-Matching API Endpoints

**Enhanced Auto-Matching Endpoint:**
```python
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def advanced_auto_match(request):
    """
    Sophisticated auto-matching system using all available user data
    """
    try:
    data = json.loads(request.body)
    event_id = data.get("event_id")
    max_invites = int(data.get("max_invites", 10))
    min_score = float(data.get("min_score", 30.0))
        radius_km = float(data.get("radius_km", 10.0))
        
        # Validate event ownership
        event = StudyEvent.objects.get(id=event_id, host=request.user)
    
    # Perform enhanced matching with all factors
        matched_users = perform_enhanced_auto_matching(
            event_id, max_invites, radius_km, min_score
        )
        
        # Broadcast WebSocket update
        broadcast_event_updated(
            event_id, 
            request.user.username, 
            attendees=list(event.attendees.values_list('username', flat=True)),
            invited_friends=[match['username'] for match in matched_users]
    )
    
    return JsonResponse({
        "success": True,
        "matched_users": matched_users,
            "total_matches": len(matched_users),
            "algorithm_version": "2.0"
        })
        
    except StudyEvent.DoesNotExist:
        return JsonResponse({"error": "Event not found"}, status=404)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)
```

#### Auto-Matching Analytics

**Matching Success Metrics:**
```python
def get_auto_matching_analytics(event_id):
    """Get analytics for auto-matching performance"""
    event = StudyEvent.objects.get(id=event_id)
    
    auto_invitations = EventInvitation.objects.filter(
        event=event, 
        is_auto_matched=True
    )
    
    accepted_invitations = auto_invitations.filter(
        user__in=event.attendees.all()
    )
    
    acceptance_rate = len(accepted_invitations) / len(auto_invitations) if auto_invitations else 0
    
    return {
        "total_auto_invites": len(auto_invitations),
        "accepted_invites": len(accepted_invitations),
        "acceptance_rate": acceptance_rate,
        "average_score": sum(inv.score for inv in auto_invitations) / len(auto_invitations) if auto_invitations else 0
    }
```

### Semantic Search System

#### Overview
The semantic search system uses machine learning models to understand the meaning and context of search queries, providing more relevant results than traditional keyword matching. It implements sentence transformers for semantic similarity and includes fallback mechanisms for when ML models are unavailable.

#### Implementation Architecture

**Model Integration:**
```python
try:
    from sentence_transformers import SentenceTransformer
    import numpy as np
    from sklearn.metrics.pairwise import cosine_similarity
    SEMANTIC_SEARCH_AVAILABLE = True
    MODEL = None
except ImportError:
    SEMANTIC_SEARCH_AVAILABLE = False
    MODEL = None
    print("Semantic search dependencies not available. Using keyword fallback.")
```

**Model Initialization:**
```python
def initialize_semantic_model():
    """Initialize the sentence transformer model"""
    global MODEL
    if SEMANTIC_SEARCH_AVAILABLE and MODEL is None:
        try:
            # Use a lightweight, fast model for production
            MODEL = SentenceTransformer('all-MiniLM-L6-v2')
            print("Semantic search model loaded successfully")
        except Exception as e:
            print(f"Failed to load semantic model: {e}")
            MODEL = None
    return MODEL is not None
```

#### Core Semantic Search Functions

**Event Embedding Generation:**
```python
def generate_event_embedding(event):
    """
    Generate embedding for event title and description
    """
    if not SEMANTIC_SEARCH_AVAILABLE or MODEL is None:
        return None
    
    try:
        # Combine title and description for embedding
        text = f"{event.title}"
        if event.description:
            text += f" {event.description}"
        
        # Generate embedding
        embedding = MODEL.encode(text, convert_to_numpy=True)
        return embedding
    except Exception as e:
        print(f"Error generating event embedding: {e}")
        return None

def generate_query_embedding(query):
    """
    Generate embedding for search query
    """
    if not SEMANTIC_SEARCH_AVAILABLE or MODEL is None:
        return None
    
    try:
        embedding = MODEL.encode(query, convert_to_numpy=True)
        return embedding
    except Exception as e:
        print(f"Error generating query embedding: {e}")
        return None
```

**Semantic Similarity Calculation:**
```python
def calculate_semantic_similarity(text1, text2):
    """
    Calculate semantic similarity between two texts using cosine similarity
    """
    if not SEMANTIC_SEARCH_AVAILABLE or MODEL is None:
        return calculate_keyword_similarity(text1, text2)
    
    try:
        # Generate embeddings for both texts
        embedding1 = MODEL.encode(text1, convert_to_numpy=True)
        embedding2 = MODEL.encode(text2, convert_to_numpy=True)
        
        # Calculate cosine similarity
        similarity = cosine_similarity([embedding1], [embedding2])[0][0]
        return float(similarity)
    except Exception as e:
        print(f"Error calculating semantic similarity: {e}")
        return calculate_keyword_similarity(text1, text2)

def calculate_keyword_similarity(text1, text2):
    """
    Fallback keyword-based similarity calculation
    """
    from collections import Counter
    import re
    
    # Simple tokenization and similarity
    words1 = set(re.findall(r'\w+', text1.lower()))
    words2 = set(re.findall(r'\w+', text2.lower()))
    
    if not words1 or not words2:
        return 0.0
    
    intersection = len(words1.intersection(words2))
    union = len(words1.union(words2))
    
    return intersection / union if union > 0 else 0.0
```

#### Event Embedding Caching System

**Caching Implementation:**
```python
from django.core.cache import cache
import pickle
import hashlib

def get_cached_event_embedding(event):
    """
    Get cached embedding for event, generate if not cached
    """
    cache_key = f'event_embedding_{event.id}'
    cached_embedding = cache.get(cache_key)
    
    if cached_embedding is not None:
        return cached_embedding
    
    # Generate new embedding
    embedding = generate_event_embedding(event)
    if embedding is not None:
        # Cache for 1 hour
        cache.set(cache_key, embedding, timeout=3600)
    
    return embedding

def invalidate_event_embedding_cache(event_id):
    """
    Invalidate cached embedding when event is updated
    """
    cache_key = f'event_embedding_{event_id}'
    cache.delete(cache_key)

def bulk_generate_event_embeddings(event_ids):
    """
    Generate embeddings for multiple events efficiently
    """
    if not SEMANTIC_SEARCH_AVAILABLE or MODEL is None:
        return {}
    
    events = StudyEvent.objects.filter(id__in=event_ids)
    embeddings = {}
    
    for event in events:
        embedding = get_cached_event_embedding(event)
        if embedding is not None:
            embeddings[event.id] = embedding
    
    return embeddings
```

#### Advanced Semantic Search Algorithm

**Main Semantic Search Function:**
```python
def perform_semantic_search(query, events, top_k=5, min_similarity=0.3):
    """
    Perform semantic search over events using cosine similarity
    Returns top events ranked by semantic relevance
    """
    if not query or not events:
        return []
    
    # Generate query embedding
    query_embedding = generate_query_embedding(query)
    if query_embedding is None:
        # Fallback to keyword search
        return perform_keyword_search(query, events, top_k)
    
    similarities = []
    
    for event in events:
        # Get event embedding (cached or generated)
        event_embedding = get_cached_event_embedding(event)
        
        if event_embedding is not None:
            # Calculate cosine similarity
            similarity = cosine_similarity([query_embedding], [event_embedding])[0][0]
            
            if similarity >= min_similarity:
                similarities.append((event, float(similarity)))
        else:
            # Fallback to keyword similarity for this event
            event_text = f"{event.title} {event.description or ''}"
            keyword_sim = calculate_keyword_similarity(query, event_text)
            if keyword_sim >= min_similarity:
                similarities.append((event, keyword_sim))
    
    # Sort by similarity and return top results
    similarities.sort(key=lambda x: x[1], reverse=True)
    return [event for event, sim in similarities[:top_k]]

def perform_keyword_search(query, events, top_k=5):
    """
    Fallback keyword-based search
    """
    query_words = set(query.lower().split())
    scored_events = []
    
    for event in events:
        event_text = f"{event.title} {event.description or ''}".lower()
        event_words = set(event_text.split())
        
        # Calculate keyword overlap
        overlap = len(query_words.intersection(event_words))
        if overlap > 0:
            score = overlap / len(query_words)
            scored_events.append((event, score))
    
    # Sort by score and return top results
    scored_events.sort(key=lambda x: x[1], reverse=True)
    return [event for event, score in scored_events[:top_k]]
```

#### Hybrid Search Implementation

**Combined Semantic and Keyword Search:**
```python
def perform_hybrid_search(query, events, semantic_weight=0.7, keyword_weight=0.3, top_k=5):
    """
    Combine semantic and keyword search for better results
    """
    if not query or not events:
        return []
    
    # Perform both searches
    semantic_results = perform_semantic_search(query, events, top_k=top_k*2)
    keyword_results = perform_keyword_search(query, events, top_k=top_k*2)
    
    # Create score maps
    semantic_scores = {event.id: score for event, score in semantic_results}
    keyword_scores = {event.id: score for event, score in keyword_results}
    
    # Combine scores
    combined_scores = {}
    all_event_ids = set(semantic_scores.keys()) | set(keyword_scores.keys())
    
    for event_id in all_event_ids:
        semantic_score = semantic_scores.get(event_id, 0)
        keyword_score = keyword_scores.get(event_id, 0)
        
        combined_score = (semantic_score * semantic_weight) + (keyword_score * keyword_weight)
        combined_scores[event_id] = combined_score
    
    # Get events and sort by combined score
    event_map = {event.id: event for event in events}
    scored_events = [(event_map[eid], score) for eid, score in combined_scores.items()]
    scored_events.sort(key=lambda x: x[1], reverse=True)
    
    return [event for event, score in scored_events[:top_k]]
```

#### Enhanced Search API Endpoints

**Semantic Search Endpoint:**
```python
@api_view(['GET'])
def enhanced_search_events(request):
    """
    Enhanced search with semantic fallback
    """
    query = request.GET.get("query", "").strip()
    use_semantic = request.GET.get("semantic", "true").lower() == "true"
    use_hybrid = request.GET.get("hybrid", "false").lower() == "true"
    top_k = int(request.GET.get("limit", 10))
    min_similarity = float(request.GET.get("min_similarity", 0.3))
    
    if not query:
        return JsonResponse({"error": "Query parameter required"}, status=400)
    
    try:
        # Get base events query
        events_qs = StudyEvent.objects.filter(
            is_public=True,
            end_time__gte=timezone.now()
        ).select_related('host').prefetch_related('attendees')
        
        # Convert to list for semantic processing
        events_list = list(events_qs)
        
        if not events_list:
            return JsonResponse({"events": []})
        
        # Choose search method
        if use_hybrid and SEMANTIC_SEARCH_AVAILABLE:
            results = perform_hybrid_search(query, events_list, top_k=top_k)
        elif use_semantic and SEMANTIC_SEARCH_AVAILABLE:
            results = perform_semantic_search(query, events_list, top_k=top_k, min_similarity=min_similarity)
        else:
            results = perform_keyword_search(query, events_list, top_k=top_k)
        
        # Serialize results
        serialized_events = []
        for event in results:
            serialized_events.append({
                "id": str(event.id),
                "title": event.title,
                "description": event.description,
                "host": event.host.username,
                "latitude": event.latitude,
                "longitude": event.longitude,
                "time": event.time.isoformat(),
                "end_time": event.end_time.isoformat(),
                "event_type": event.event_type,
                "attendees": list(event.attendees.values_list('username', flat=True)),
                "is_public": event.is_public,
                "interest_tags": event.get_interest_tags()
            })
        
        return JsonResponse({
            "events": serialized_events,
            "search_method": "hybrid" if use_hybrid else ("semantic" if use_semantic else "keyword"),
            "total_results": len(serialized_events),
            "semantic_available": SEMANTIC_SEARCH_AVAILABLE
        })
        
        except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)
```

#### Performance Optimizations

**Batch Processing:**
```python
def batch_semantic_search(queries, events, top_k=5):
    """
    Process multiple search queries efficiently
    """
    if not SEMANTIC_SEARCH_AVAILABLE or MODEL is None:
        return {query: perform_keyword_search(query, events, top_k) for query in queries}
    
    # Generate embeddings for all queries at once
    query_embeddings = MODEL.encode(queries, convert_to_numpy=True)
    event_embeddings = bulk_generate_event_embeddings([event.id for event in events])
    
    results = {}
    for i, query in enumerate(queries):
        query_embedding = query_embeddings[i]
        similarities = []
        
        for event in events:
            event_embedding = event_embeddings.get(event.id)
            if event_embedding is not None:
                similarity = cosine_similarity([query_embedding], [event_embedding])[0][0]
                similarities.append((event, similarity))
        
        similarities.sort(key=lambda x: x[1], reverse=True)
        results[query] = [event for event, sim in similarities[:top_k]]
    
    return results
```

**Memory Management:**
```python
def cleanup_embeddings_cache():
    """
    Clean up old embeddings from cache
    """
    # Get all embedding cache keys
    cache_keys = cache.get('embedding_cache_keys', [])
    
    # Remove expired keys
    valid_keys = []
    for key in cache_keys:
        if cache.get(key) is not None:
            valid_keys.append(key)
    
    cache.set('embedding_cache_keys', valid_keys, timeout=86400)  # 24 hours
```

#### Search Analytics and Monitoring

**Search Performance Metrics:**
```python
def track_search_performance(query, results, search_method, response_time):
    """
    Track search performance metrics
    """
    metrics = {
        'query_length': len(query),
        'result_count': len(results),
        'search_method': search_method,
        'response_time_ms': response_time * 1000,
        'timestamp': timezone.now().isoformat(),
        'semantic_available': SEMANTIC_SEARCH_AVAILABLE
    }
    
    # Store metrics in cache for analysis
    cache_key = f'search_metrics_{timezone.now().strftime("%Y%m%d")}'
    existing_metrics = cache.get(cache_key, [])
    existing_metrics.append(metrics)
    cache.set(cache_key, existing_metrics, timeout=86400)

def get_search_analytics(date=None):
    """
    Get search analytics for a specific date
    """
    if date is None:
        date = timezone.now().date()
    
    cache_key = f'search_metrics_{date.strftime("%Y%m%d")}'
    metrics = cache.get(cache_key, [])
    
    if not metrics:
        return {"error": "No metrics found for this date"}
    
    # Calculate analytics
    total_searches = len(metrics)
    avg_response_time = sum(m['response_time_ms'] for m in metrics) / total_searches
    method_counts = {}
    
    for metric in metrics:
        method = metric['search_method']
        method_counts[method] = method_counts.get(method, 0) + 1
    
    return {
        'date': date.isoformat(),
        'total_searches': total_searches,
        'average_response_time_ms': avg_response_time,
        'search_method_distribution': method_counts,
        'semantic_availability_rate': sum(1 for m in metrics if m['semantic_available']) / total_searches
    }
```

#### Model Management and Updates

**Model Versioning:**
```python
def get_model_info():
    """
    Get information about the current semantic model
    """
    if not SEMANTIC_SEARCH_AVAILABLE or MODEL is None:
        return {
            'available': False,
            'model_name': None,
            'version': None
        }
    
    return {
        'available': True,
        'model_name': 'all-MiniLM-L6-v2',
        'version': '1.0',
        'embedding_dimension': MODEL.get_sentence_embedding_dimension(),
        'max_sequence_length': MODEL.max_seq_length
    }

def update_model(new_model_name):
    """
    Update the semantic model (for future model upgrades)
    """
    global MODEL
    
    if not SEMANTIC_SEARCH_AVAILABLE:
        return False
    
    try:
        # Load new model
        new_model = SentenceTransformer(new_model_name)
        
        # Replace current model
        MODEL = new_model
        
        # Clear embedding cache since model changed
        cache.delete_many([f'event_embedding_{event_id}' for event_id in StudyEvent.objects.values_list('id', flat=True)])
        
        return True
    except Exception as e:
        print(f"Failed to update model: {e}")
        return False
```

### Trust & Reputation System

#### Overview
The trust system implements Bandura's social learning theory, allowing users to learn from observing others and reinforcing positive behavior through ratings and reputation levels.

#### Trust Level Progression

**Default Trust Levels:**
```python
TRUST_LEVELS = [
    {"level": 1, "title": "Newcomer", "required_ratings": 0, "min_average_rating": 0.0},
    {"level": 2, "title": "Rising", "required_ratings": 3, "min_average_rating": 3.5},
    {"level": 3, "title": "Trusted", "required_ratings": 10, "min_average_rating": 4.0},
    {"level": 4, "title": "Expert", "required_ratings": 25, "min_average_rating": 4.3},
    {"level": 5, "title": "Legend", "required_ratings": 50, "min_average_rating": 4.5},
]
```

**Reputation Calculation:**
```python
class UserReputationStats(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    total_ratings = models.IntegerField(default=0)
    average_rating = models.FloatField(default=0.0)
    trust_level = models.ForeignKey(UserTrustLevel, on_delete=models.SET_NULL, null=True)
    events_hosted = models.IntegerField(default=0)
    events_attended = models.IntegerField(default=0)
    last_updated = models.DateTimeField(auto_now=True)
    
    def update_trust_level(self):
        """Update trust level based on current stats"""
        new_level = UserTrustLevel.objects.filter(
            required_ratings__lte=self.total_ratings,
            min_average_rating__lte=self.average_rating
        ).order_by('-level').first()
        
        if new_level and (not self.trust_level or self.trust_level.level < new_level.level):
            old_level = self.trust_level
            self.trust_level = new_level
            self.save()
            
            # Send level up notification
            self.send_level_up_notification(old_level, new_level)
```

**Rating System:**
```python
class UserRating(models.Model):
    from_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ratings_given')
    to_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ratings_received')
    event = models.ForeignKey(StudyEvent, on_delete=models.SET_NULL, null=True, blank=True)
    rating = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    reference = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('from_user', 'to_user', 'event')
    
    def save(self, *args, **kwargs):
        # Ensure rating is valid
        if self.rating < 1:
            self.rating = 1
        elif self.rating > 5:
            self.rating = 5
        
        super().save(*args, **kwargs)
        
        # Update reputation stats
        self.update_user_stats()
        
        # Send notification
        self.send_rating_notification()
    
    def update_user_stats(self):
        """Update reputation statistics for rated user"""
        stats, created = UserReputationStats.objects.get_or_create(
            user=self.to_user
        )
        
        # Recalculate average rating
        all_ratings = UserRating.objects.filter(to_user=self.to_user)
        stats.total_ratings = all_ratings.count()
        stats.average_rating = all_ratings.aggregate(
            avg_rating=models.Avg('rating')
        )['avg_rating'] or 0.0
        
        stats.save()
        stats.update_trust_level()
```

**Trust Level Benefits:**
- **Level 1 (Newcomer)**: Basic access, limited features
- **Level 2 (Rising)**: Can create public events, access to more features
- **Level 3 (Trusted)**: Priority in auto-matching, enhanced visibility
- **Level 4 (Expert)**: Advanced features, moderation capabilities
- **Level 5 (Legend)**: Full platform access, special recognition

#### Reputation API Endpoints

**Get User Reputation:**
```python
@api_view(['GET'])
def get_user_reputation(request, username):
    """
    Get comprehensive reputation statistics for a user
    """
    user = User.objects.get(username=username)
    reputation, created = UserReputationStats.objects.get_or_create(user=user)
    
    if created:
        reputation.update_trust_level()
        reputation.update_event_counts()
    
    data = {
        "username": user.username,
        "total_ratings": reputation.total_ratings,
        "average_rating": float(round(reputation.average_rating, 2)),
        "events_hosted": reputation.events_hosted,
        "events_attended": reputation.events_attended,
        "trust_level": {
            "level": reputation.trust_level.level if reputation.trust_level else 0,
            "title": reputation.trust_level.title if reputation.trust_level else "Unrated"
        }
    }
    
    return JsonResponse(data)
```

**Rate User:**
```python
@api_view(['POST'])
def rate_user(request):
    """
    Rate another user after an event
    """
    data = json.loads(request.body)
    to_user_id = data.get('to_user_id')
    rating = data.get('rating')
    reference = data.get('reference', '')
    event_id = data.get('event_id')
    
    # Validate rating
    if not (1 <= rating <= 5):
        return JsonResponse({"error": "Rating must be between 1 and 5"}, status=400)
    
    # Create rating
    user_rating = UserRating.objects.create(
        from_user=request.user,
        to_user_id=to_user_id,
        rating=rating,
        reference=reference,
        event_id=event_id
    )
    
    return JsonResponse({
        "success": True,
        "message": "Rating submitted successfully",
        "rating_id": str(user_rating.id)
    })
```

### Advanced Matching Features

#### Interest-Based Matching
- **Interest Tags**: Users and events have associated interest tags
- **Weighted Scoring**: Different interests have different weights
- **Interest Evolution**: User interests can change over time
- **Interest Clustering**: Related interests are grouped together

#### Location Intelligence
- **Proximity Scoring**: Distance-based scoring with configurable radius
- **Location Preferences**: Users can set preferred locations
- **Travel Time**: Consideration of travel time, not just distance
- **Location History**: Learning from user's location patterns

#### Social Graph Analysis
- **Friend Networks**: Mutual friends increase matching score
- **Social Influence**: Popular users get higher scores
- **Network Effects**: Friend-of-friend connections
- **Social Proof**: Events with mutual friends are prioritized

#### Academic Matching
- **University Matching**: Same university increases compatibility
- **Degree Programs**: Related fields of study
- **Academic Year**: Similar academic levels
- **Course Overlap**: Shared courses or subjects

#### Behavioral Learning
- **Event History**: Learning from past event preferences
- **Response Patterns**: How users respond to different event types
- **Time Patterns**: When users are most active
- **Engagement Metrics**: How users interact with events

#### Machine Learning Integration
- **Collaborative Filtering**: User-based and item-based recommendations
- **Content-Based Filtering**: Event content similarity
- **Hybrid Approaches**: Combining multiple recommendation techniques
- **Continuous Learning**: System improves over time

### Performance Optimizations

#### Caching Strategies
- **Event Embeddings**: Cached for 1 hour
- **User Profiles**: Cached for 30 minutes
- **Interest Matches**: Cached for 15 minutes
- **Location Data**: Cached for 1 hour

#### Database Optimizations
- **Batch Processing**: Process users in batches of 100
- **Prefetch Related**: Reduce database queries
- **Index Optimization**: Proper indexing on frequently queried fields
- **Query Optimization**: Efficient database queries

#### Algorithm Efficiency
- **Early Termination**: Stop processing when enough matches found
- **Score Thresholds**: Skip users below minimum score
- **Parallel Processing**: Process multiple users simultaneously
- **Memory Management**: Efficient memory usage for large datasets

### cURL Test Flows

#### Complete User Flow
```bash
# 1. Register user
curl -X POST https://pinit-backend-production.up.railway.app/api/register/ \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "testpass123"}'

# 2. Login user
curl -X POST https://pinit-backend-production.up.railway.app/api/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "testpass123"}'

# 3. Create event (use access_token from login)
curl -X POST https://pinit-backend-production.up.railway.app/api/create_study_event/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "title": "Study Session",
    "description": "Group study for finals",
    "location": "Library",
    "latitude": 37.7749,
    "longitude": -122.4194,
    "time": "2025-01-15T14:00:00Z",
    "end_time": "2025-01-15T16:00:00Z",
    "event_type": "Study",
    "is_public": true
  }'

# 4. Get events
curl -X GET https://pinit-backend-production.up.railway.app/api/get_study_events/testuser/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# 5. Delete event (use event_id from create)
curl -X POST https://pinit-backend-production.up.railway.app/api/delete_study_event/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{"event_id": "YOUR_EVENT_ID"}'

# 6. Delete account
curl -X POST https://pinit-backend-production.up.railway.app/api/delete_account/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### WebSocket Testing
```bash
# Connect to WebSocket (requires wscat or similar tool)
wscat -c wss://pinit-backend-production.up.railway.app/ws/events/testuser/

# Expected messages:
# {"type": "create", "event_id": "uuid"}
# {"type": "update", "event_id": "uuid"}
# {"type": "delete", "event_id": "uuid"}
```

### Local Development

**Setup:**
```bash
# Clone repository
git clone <repository-url>
cd PinItApp

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Start development server
python manage.py runserver

# Start ASGI server (for WebSockets)
daphne StudyCon.asgi:application
```

**Environment Variables:**
```bash
# .env file for local development
DEBUG=True
SECRET_KEY=your-secret-key
DATABASE_URL=sqlite:///db.sqlite3
REDIS_URL=redis://localhost:6379
```

---

## Troubleshooting

### Common Issues

#### Database Connection Errors
**Error:** `ModuleNotFoundError: No module named 'psycopg'`
**Solution:** Ensure `psycopg[binary]==3.2.10` is installed for Python 3.13

**Error:** `sqlite3.OperationalError: no such table: myapp_eventreviewreminder`
**Solution:** Run migrations: `python manage.py migrate`

#### Authentication Issues
**Error:** `401 Unauthorized` on API calls
**Solution:** 
- Check JWT token validity
- Ensure token is in Authorization header: `Bearer {token}`
- Refresh token if expired

#### WebSocket Connection Issues
**Error:** WebSocket connection fails
**Solution:**
- Check WebSocket URL format
- Verify username in URL path
- Check server WebSocket configuration

#### Rate Limiting
**Error:** `429 Too Many Requests`
**Solution:**
- Implement request cooldown (30 seconds for events)
- Use WebSocket for real-time updates instead of polling
- Respect rate limits in client code

### Debugging Tools

**Backend Logging:**
- Django logging configured
- WebSocket connection logs
- API request/response logging

**iOS Debugging:**
- AppLogger for network requests
- WebSocket connection status
- Token validation logging

**Railway Monitoring:**
- Deployment logs
- Health check status
- Resource usage metrics

---

## Change Log

### Recent Critical Changes (January 2025)

#### Backend Changes
- **Database Migration**: Migrated from SQLite to PostgreSQL on Railway
- **Event Deletion**: Fixed cascade delete issues with EventReviewReminder model
- **Account Deletion**: Implemented proper account deletion endpoint
- **JWT Registration**: Registration now returns JWT tokens for immediate login
- **Rate Limiting**: Added comprehensive rate limiting to all endpoints
- **WebSocket Broadcasting**: Enhanced real-time event updates

#### iOS Frontend Changes
- **API Polling Reduction**: Implemented 30-second cooldown to prevent excessive API calls
- **WebSocket Integration**: Enhanced real-time updates via WebSocket
- **Authentication Persistence**: Fixed login persistence and token validation
- **UI Fixes**: Resolved text visibility issues in settings and notifications
- **Quick Actions**: Wired all quick action buttons to existing views
- **Map Improvements**: Adjusted clustering thresholds and zoom levels
- **Keyboard Handling**: Added proper keyboard dismissal in forms

#### Deployment Changes
- **Railway Configuration**: Proper PostgreSQL service connection
- **Health Checks**: Implemented health check endpoint
- **Dependencies**: Updated to Python 3.13 compatible packages
- **Environment Variables**: Configured proper DATABASE_URL and RAILWAY_RUN_COMMAND

### Deprecated Features
- **Legacy Documentation**: `/complete_documentation` and `/Documentation` folders contain outdated information
- **SQLite Production**: No longer used in production (PostgreSQL only)
- **Manual API Polling**: Replaced with WebSocket-first approach
- **Dark Mode Toggle**: Removed from settings (not implemented)

---

## Glossary

**ASGI**: Asynchronous Server Gateway Interface - enables WebSocket support in Django

**CASCADE**: Database constraint that automatically deletes related records when parent is deleted

**Channels**: Django package for handling WebSockets and other async protocols

**Daphne**: ASGI server for running Django applications with WebSocket support

**JWT**: JSON Web Token - stateless authentication mechanism

**Mapbox**: Mapping service used in iOS app for displaying events on maps

**PostgreSQL**: Relational database system used in production

**Railway**: Cloud platform for deploying and hosting the application

**Redis**: In-memory data store used for WebSocket channel layers

**R2**: Cloudflare's object storage service for file uploads

**Rate Limiting**: Technique to limit the number of requests per user/IP

**SwiftUI**: Apple's declarative UI framework for iOS development

**WebSocket**: Real-time bidirectional communication protocol

---

## Change Log

### Recent Critical Changes (January 2025)

#### Backend Changes
- **Database Migration**: Migrated from SQLite to PostgreSQL on Railway
- **Delete Operations**: Fixed cascade delete issues with proper migrations
- **WebSocket Integration**: Enhanced real-time event updates
- **Auto-Matching**: Improved scoring algorithm with 10+ factors
- **Semantic Search**: Added machine learning-based search capabilities
- **Trust System**: Implemented Bandura's social learning theory

#### Frontend Changes
- **Event Clustering**: Fixed aggressive clustering on map
- **Quick Actions**: Linked non-functional buttons to existing views
- **UI Improvements**: Fixed text visibility and navigation bar issues
- **WebSocket Integration**: Added real-time event updates
- **API Polling**: Reduced excessive API calls with cooldown mechanism
- **Authentication**: Fixed JWT token handling for new accounts
- **Map Behavior**: Fixed automatic recentering when filtering events or changing view modes

#### Deployment Changes
- **Railway Configuration**: Added PostgreSQL and Redis services
- **Environment Variables**: Configured proper service connections
- **Health Checks**: Implemented comprehensive health monitoring
- **Dependencies**: Updated to Python 3.13.2 and latest packages
- **ASGI Server**: Configured Daphne for WebSocket support

#### Documentation Changes
- **Comprehensive Documentation**: Created single source of truth
- **API Reference**: Documented all 70+ endpoints
- **WebSocket System**: Complete real-time system documentation
- **Advanced Features**: Documented auto-matching and semantic search
- **Deployment Guide**: Railway-specific configuration details

### Historical Changes
- **2024**: Initial development and basic features
- **2024**: WebSocket implementation and real-time updates
- **2024**: Auto-matching system development
- **2024**: Trust and reputation system implementation
- **2025**: PostgreSQL migration and Railway deployment
- **2025**: Comprehensive documentation creation

---

*This documentation reflects the current state of the PinIt application as of January 2025. For the most up-to-date information, refer to the source code and deployment configuration.*
