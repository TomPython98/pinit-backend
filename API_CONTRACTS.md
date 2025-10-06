# PinIt API Contracts Documentation

## Overview
This document defines the complete API contract for the PinIt backend, including all endpoints, request/response shapes, authentication, and error handling patterns.

## Base Configuration

### Base URLs
- **Production**: `https://pinit-backend-production.up.railway.app/api`
- **Development**: `http://127.0.0.1:8000/api`
- **Health Check**: `https://pinit-backend-production.up.railway.app/health/`

### Authentication
- **Method**: Session-based authentication
- **Headers**: `Content-Type: application/json`
- **CSRF**: Disabled for mobile clients (`@csrf_exempt`)

### Response Format
All responses follow this structure:
```json
{
  "success": boolean,
  "message": string,
  "data": object | array | null
}
```

## Authentication Endpoints

### Register User
**Endpoint**: `POST /api/register/`

**Request Body**:
```json
{
  "username": "string",
  "password": "string"
}
```

**Response**:
```json
{
  "success": true,
  "message": "User registered successfully."
}
```

**Error Responses**:
- `400`: Username already exists
- `400`: Username and Password required
- `400`: Invalid JSON data

### Login User
**Endpoint**: `POST /api/login/`

**Request Body**:
```json
{
  "username": "string",
  "password": "string"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Login successful."
}
```

**Error Responses**:
- `401`: Invalid credentials
- `400`: Username and password are required

### Logout User
**Endpoint**: `POST /api/logout/`

**Response**:
```json
{
  "success": true,
  "message": "Logout successful."
}
```

## User Profile Endpoints

### Get User Profile
**Endpoint**: `GET /api/get_user_profile/{username}/`

**Response**:
```json
{
  "username": "string",
  "is_certified": boolean,
  "full_name": "string",
  "university": "string",
  "degree": "string",
  "year": "string",
  "bio": "string",
  "profile_picture": "string",
  "interests": ["string"],
  "skills": {
    "skill_name": "BEGINNER|INTERMEDIATE|ADVANCED|EXPERT"
  },
  "auto_invite_enabled": boolean,
  "preferred_radius": number
}
```

### Update User Interests
**Endpoint**: `POST /api/update_user_interests/`

**Request Body**:
```json
{
  "username": "string",
  "interests": ["string"],
  "skills": {
    "skill_name": "BEGINNER|INTERMEDIATE|ADVANCED|EXPERT"
  },
  "auto_invite_enabled": boolean,
  "preferred_radius": number,
  "full_name": "string",
  "university": "string",
  "degree": "string",
  "year": "string",
  "bio": "string"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Profile updated successfully."
}
```

### Get Profile Completion
**Endpoint**: `GET /api/profile_completion/{username}/`

**Response**:
```json
{
  "completion_percentage": number,
  "missing_fields": ["string"],
  "is_complete": boolean,
  "suggestions": ["string"]
}
```

## Event Management Endpoints

### Create Study Event
**Endpoint**: `POST /api/create_study_event/`

**Request Body**:
```json
{
  "title": "string",
  "description": "string",
  "host": "string",
  "latitude": number,
  "longitude": number,
  "time": "2024-01-01T12:00:00Z",
  "end_time": "2024-01-01T14:00:00Z",
  "is_public": boolean,
  "invited_friends": ["string"],
  "event_type": "study|party|business|cultural|academic|networking|social|language_exchange|other",
  "max_participants": number,
  "auto_matching_enabled": boolean,
  "interest_tags": ["string"]
}
```

**Response**:
```json
{
  "success": true,
  "event": {
    "id": "uuid",
    "title": "string",
    "description": "string",
    "host": "string",
    "latitude": number,
    "longitude": number,
    "time": "2024-01-01T12:00:00Z",
    "end_time": "2024-01-01T14:00:00Z",
    "is_public": boolean,
    "invited_friends": ["string"],
    "attendees": ["string"],
    "event_type": "string",
    "max_participants": number,
    "auto_matching_enabled": boolean,
    "interest_tags": ["string"]
  }
}
```

### Get Study Events
**Endpoint**: `GET /api/get_study_events/{username}/`

**Response**:
```json
{
  "events": [
    {
      "id": "uuid",
      "title": "string",
      "description": "string",
      "host": "string",
      "host_is_certified": boolean,
      "latitude": number,
      "longitude": number,
      "time": "2024-01-01T12:00:00Z",
      "end_time": "2024-01-01T14:00:00Z",
      "is_public": boolean,
      "invited_friends": ["string"],
      "attendees": ["string"],
      "event_type": "string",
      "max_participants": number,
      "auto_matching_enabled": boolean,
      "interest_tags": ["string"],
      "is_auto_matched": boolean,
      "matched_users": ["string"]
    }
  ]
}
```

### RSVP Study Event
**Endpoint**: `POST /api/rsvp_study_event/`

**Request Body**:
```json
{
  "event_id": "uuid",
  "username": "string",
  "action": "join|leave"
}
```

**Response**:
```json
{
  "success": true,
  "message": "RSVP successful."
}
```

### Delete Study Event
**Endpoint**: `POST /api/delete_study_event/`

**Request Body**:
```json
{
  "event_id": "uuid",
  "username": "string"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Event deleted successfully."
}
```

### Search Events
**Endpoint**: `POST /api/search_events/`

**Request Body**:
```json
{
  "query": "string",
  "public_only": boolean,
  "certified_only": boolean,
  "event_type": "string",
  "semantic": boolean
}
```

**Response**:
```json
{
  "events": [
    {
      "id": "uuid",
      "title": "string",
      "description": "string",
      "host": "string",
      "latitude": number,
      "longitude": number,
      "time": "2024-01-01T12:00:00Z",
      "end_time": "2024-01-01T14:00:00Z",
      "event_type": "string",
      "is_public": boolean
    }
  ]
}
```

## Social Features Endpoints

### Send Friend Request
**Endpoint**: `POST /api/send_friend_request/`

**Request Body**:
```json
{
  "from_user": "string",
  "to_user": "string"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Friend request sent successfully"
}
```

### Accept Friend Request
**Endpoint**: `POST /api/accept_friend_request/`

**Request Body**:
```json
{
  "from_user": "string",
  "to_user": "string"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Friend request accepted"
}
```

### Get Friends
**Endpoint**: `GET /api/get_friends/{username}/`

**Response**:
```json
{
  "friends": ["string"]
}
```

### Get Pending Requests
**Endpoint**: `GET /api/get_pending_requests/{username}/`

**Response**:
```json
{
  "pending_requests": ["string"]
}
```

### Get Sent Requests
**Endpoint**: `GET /api/get_sent_requests/{username}/`

**Response**:
```json
{
  "sent_requests": ["string"]
}
```

## Event Interactions Endpoints

### Add Event Comment
**Endpoint**: `POST /api/events/comment/`

**Request Body**:
```json
{
  "event_id": "uuid",
  "username": "string",
  "text": "string",
  "parent_id": "uuid"
}
```

**Response**:
```json
{
  "success": true,
  "comment": {
    "id": "uuid",
    "text": "string",
    "user": "string",
    "created_at": "2024-01-01T12:00:00Z",
    "parent_id": "uuid"
  }
}
```

### Toggle Event Like
**Endpoint**: `POST /api/events/like/`

**Request Body**:
```json
{
  "event_id": "uuid",
  "username": "string",
  "comment_id": "uuid"
}
```

**Response**:
```json
{
  "success": true,
  "liked": boolean,
  "like_count": number
}
```

### Record Event Share
**Endpoint**: `POST /api/events/share/`

**Request Body**:
```json
{
  "event_id": "uuid",
  "username": "string",
  "shared_platform": "whatsapp|facebook|twitter|instagram|other"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Share recorded"
}
```

### Get Event Interactions
**Endpoint**: `GET /api/events/interactions/{event_id}/`

**Response**:
```json
{
  "likes": [
    {
      "user": "string",
      "created_at": "2024-01-01T12:00:00Z",
      "comment_id": "uuid"
    }
  ],
  "comments": [
    {
      "id": "uuid",
      "text": "string",
      "user": "string",
      "created_at": "2024-01-01T12:00:00Z",
      "parent_id": "uuid",
      "likes": number,
      "replies": [
        {
          "id": "uuid",
          "text": "string",
          "user": "string",
          "created_at": "2024-01-01T12:00:00Z"
        }
      ]
    }
  ],
  "shares": [
    {
      "user": "string",
      "shared_platform": "string",
      "created_at": "2024-01-01T12:00:00Z"
    }
  ]
}
```

### Get Event Feed
**Endpoint**: `GET /api/events/feed/{event_id}/`

**Response**:
```json
{
  "event": {
    "id": "uuid",
    "title": "string",
    "description": "string",
    "host": "string",
    "time": "2024-01-01T12:00:00Z",
    "end_time": "2024-01-01T14:00:00Z"
  },
  "feed": [
    {
      "type": "comment|like|share",
      "user": "string",
      "content": "string",
      "created_at": "2024-01-01T12:00:00Z",
      "metadata": {}
    }
  ]
}
```

## Auto-Matching Endpoints

### Advanced Auto Match
**Endpoint**: `POST /api/advanced_auto_match/`

**Request Body**:
```json
{
  "event_id": "uuid",
  "max_invites": number,
  "min_score": number,
  "mark_as_auto_matched": boolean
}
```

**Response**:
```json
{
  "success": true,
  "matched_users": [
    {
      "username": "string",
      "score": number,
      "reasons": ["string"]
    }
  ],
  "invites_sent": number,
  "total_potential_matches": number
}
```

### Get Auto Matched Users
**Endpoint**: `GET /api/get_auto_matched_users/{event_id}/`

**Response**:
```json
{
  "auto_matched_users": [
    {
      "username": "string",
      "score": number,
      "matched_at": "2024-01-01T12:00:00Z"
    }
  ]
}
```

## Invitation Endpoints

### Get Invitations
**Endpoint**: `GET /api/get_invitations/{username}/`

**Response**:
```json
{
  "direct_invitations": [
    {
      "event_id": "uuid",
      "event_title": "string",
      "host": "string",
      "time": "2024-01-01T12:00:00Z",
      "is_auto_matched": false
    }
  ],
  "auto_matched_invitations": [
    {
      "event_id": "uuid",
      "event_title": "string",
      "host": "string",
      "time": "2024-01-01T12:00:00Z",
      "is_auto_matched": true,
      "match_score": number
    }
  ]
}
```

### Decline Invitation
**Endpoint**: `POST /api/decline_invitation/`

**Request Body**:
```json
{
  "event_id": "uuid",
  "username": "string"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Invitation declined"
}
```

### Invite to Event
**Endpoint**: `POST /invite_to_event/`

**Request Body**:
```json
{
  "event_id": "uuid",
  "username": "string",
  "mark_as_auto_matched": boolean
}
```

**Response**:
```json
{
  "success": true,
  "message": "User invited successfully"
}
```

## Reputation System Endpoints

### Submit User Rating
**Endpoint**: `POST /api/submit_user_rating/`

**Request Body**:
```json
{
  "from_user": "string",
  "to_user": "string",
  "event_id": "uuid",
  "rating": number,
  "reference": "string"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Rating submitted successfully"
}
```

### Get User Reputation
**Endpoint**: `GET /api/get_user_reputation/{username}/`

**Response**:
```json
{
  "username": "string",
  "total_ratings": number,
  "average_rating": number,
  "trust_level": {
    "level": number,
    "title": "string"
  },
  "events_hosted": number,
  "events_attended": number,
  "last_updated": "2024-01-01T12:00:00Z"
}
```

### Get User Ratings
**Endpoint**: `GET /api/get_user_ratings/{username}/`

**Response**:
```json
{
  "ratings": [
    {
      "id": "uuid",
      "from_user": "string",
      "rating": number,
      "reference": "string",
      "event_title": "string",
      "created_at": "2024-01-01T12:00:00Z"
    }
  ]
}
```

### Get Trust Levels
**Endpoint**: `GET /api/get_trust_levels/`

**Response**:
```json
{
  "trust_levels": [
    {
      "level": number,
      "title": "string",
      "required_ratings": number,
      "min_average_rating": number
    }
  ]
}
```

## User Preferences Endpoints

### Get User Preferences
**Endpoint**: `GET /api/user_preferences/{username}/`

**Response**:
```json
{
  "notifications": {
    "push_enabled": boolean,
    "email_enabled": boolean,
    "friend_requests": boolean,
    "event_invitations": boolean,
    "event_updates": boolean
  },
  "privacy": {
    "profile_visibility": "public|friends|private",
    "location_sharing": boolean,
    "activity_status": boolean
  },
  "appearance": {
    "theme": "light|dark|system",
    "language": "string"
  }
}
```

### Update User Preferences
**Endpoint**: `POST /api/update_user_preferences/{username}/`

**Request Body**:
```json
{
  "notifications": {
    "push_enabled": boolean,
    "email_enabled": boolean,
    "friend_requests": boolean,
    "event_invitations": boolean,
    "event_updates": boolean
  },
  "privacy": {
    "profile_visibility": "public|friends|private",
    "location_sharing": boolean,
    "activity_status": boolean
  },
  "appearance": {
    "theme": "light|dark|system",
    "language": "string"
  }
}
```

### Get Matching Preferences
**Endpoint**: `GET /api/matching_preferences/{username}/`

**Response**:
```json
{
  "auto_invite_enabled": boolean,
  "preferred_radius": number,
  "interest_weight": number,
  "skill_weight": number,
  "location_weight": number,
  "time_weight": number,
  "min_match_score": number
}
```

### Update Matching Preferences
**Endpoint**: `POST /api/update_matching_preferences/{username}/`

**Request Body**:
```json
{
  "auto_invite_enabled": boolean,
  "preferred_radius": number,
  "interest_weight": number,
  "skill_weight": number,
  "location_weight": number,
  "time_weight": number,
  "min_match_score": number
}
```

## Push Notification Endpoints

### Register Device
**Endpoint**: `POST /api/register-device/`

**Request Body**:
```json
{
  "user_id": number,
  "token": "string",
  "device_type": "ios|android"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Device registered successfully"
}
```

## Utility Endpoints

### Health Check
**Endpoint**: `GET /health/`

**Response**:
```json
{
  "status": "healthy",
  "message": "PinIt API is running - Railway deployment test"
}
```

### Get All Users
**Endpoint**: `GET /api/get_all_users/`

**Response**:
```json
["username1", "username2", "username3"]
```

### Certify User
**Endpoint**: `POST /api/certify_user/`

**Request Body**:
```json
{
  "username": "string"
}
```

**Response**:
```json
{
  "success": true,
  "message": "User certified successfully"
}
```

## Error Handling

### Standard Error Response Format
```json
{
  "success": false,
  "message": "Error description",
  "error_code": "ERROR_CODE",
  "details": {}
}
```

### Common HTTP Status Codes
- `200`: Success
- `201`: Created
- `400`: Bad Request
- `401`: Unauthorized
- `403`: Forbidden
- `404`: Not Found
- `500`: Internal Server Error

### Error Codes
- `VALIDATION_ERROR`: Input validation failed
- `AUTHENTICATION_ERROR`: Authentication failed
- `PERMISSION_ERROR`: Insufficient permissions
- `NOT_FOUND_ERROR`: Resource not found
- `SERVER_ERROR`: Internal server error
- `NETWORK_ERROR`: Network communication error

## Rate Limiting
- **Default**: 1000 requests per hour per IP
- **Authentication**: 10 login attempts per minute per IP
- **Event Creation**: 10 events per hour per user
- **Friend Requests**: 50 requests per hour per user

## WebSocket Endpoints

### Events WebSocket
**Endpoint**: `wss://pinit-backend-production.up.railway.app/ws/events/`

**Message Types**:
- `event_created`: New event created
- `event_updated`: Event updated
- `event_deleted`: Event deleted
- `user_joined`: User joined event
- `user_left`: User left event

**Message Format**:
```json
{
  "type": "event_created",
  "event": {
    "id": "uuid",
    "title": "string",
    "host": "string",
    "time": "2024-01-01T12:00:00Z"
  }
}
```

This API contract documentation provides a complete reference for all PinIt backend endpoints, ensuring consistent integration across iOS and Android clients.

