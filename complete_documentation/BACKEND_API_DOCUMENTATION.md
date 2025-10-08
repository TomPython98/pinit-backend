# Backend API Documentation

## Overview
This document provides comprehensive documentation for the PinIt backend API, including all endpoints, data models, and integration details.

## Base URL
```
https://pinit-backend-production.up.railway.app
```

## Authentication
Most endpoints do not require authentication. Some endpoints may require user identification via username parameters.

## Core Endpoints

### User Management

#### Register User
- **Endpoint**: `POST /api/register/`
- **Description**: Register a new user
- **Request Body**:
  ```json
  {
    "username": "string",
    "password": "string"
  }
  ```
- **Response**: `201 Created`
  ```json
  {
    "success": true,
    "message": "User registered successfully."
  }
  ```

#### Login User
- **Endpoint**: `POST /api/login/`
- **Description**: Authenticate user
- **Request Body**:
  ```json
  {
    "username": "string",
    "password": "string"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "success": true,
    "message": "Login successful."
  }
  ```

#### Get All Users
- **Endpoint**: `GET /api/get_all_users/`
- **Description**: Get list of all usernames
- **Response**: `200 OK`
  ```json
  ["username1", "username2", ...]
  ```

### Friend Management

#### Send Friend Request
- **Endpoint**: `POST /api/send_friend_request/`
- **Description**: Send a friend request
- **Request Body**:
  ```json
  {
    "from_user": "string",
    "to_user": "string"
  }
  ```
- **Response**: `201 Created`
  ```json
  {
    "success": true,
    "message": "Friend request sent successfully"
  }
  ```

#### Accept Friend Request
- **Endpoint**: `POST /api/accept_friend_request/`
- **Description**: Accept a friend request
- **Request Body**:
  ```json
  {
    "from_user": "string",
    "to_user": "string"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "success": true,
    "message": "User1 and User2 are now friends!"
  }
  ```

#### Get Friends
- **Endpoint**: `GET /api/get_friends/{username}/`
- **Description**: Get user's friends list
- **Response**: `200 OK`
  ```json
  {
    "friends": ["friend1", "friend2", ...]
  }
  ```

#### Get Pending Requests
- **Endpoint**: `GET /api/get_pending_requests/{username}/`
- **Description**: Get pending friend requests for user
- **Response**: `200 OK`
  ```json
  {
    "pending_requests": ["requester1", "requester2", ...]
  }
  ```

#### Get Sent Requests
- **Endpoint**: `GET /api/get_sent_requests/{username}/`
- **Description**: Get friend requests sent by user
- **Response**: `200 OK`
  ```json
  {
    "sent_requests": ["recipient1", "recipient2", ...]
  }
  ```

### Event Management

#### Create Study Event
- **Endpoint**: `POST /api/create_study_event/`
- **Description**: Create a new study event
- **Request Body**:
  ```json
  {
    "host": "string",
    "title": "string",
    "description": "string",
    "location": "string",
    "latitude": "number",
    "longitude": "number",
    "time": "ISO 8601 datetime string",
    "end_time": "ISO 8601 datetime string",
    "max_participants": "number",
    "event_type": "string",
    "interest_tags": ["tag1", "tag2", ...],
    "auto_matching_enabled": "boolean",
    "is_public": "boolean",
    "invited_friends": ["user1", "user2", ...]
  }
  ```
- **Response**: `201 Created`
  ```json
  {
    "success": true,
    "event_id": "UUID string",
    "message": "Event created successfully"
  }
  ```

#### Get Study Events
- **Endpoint**: `GET /api/get_study_events/{username}/`
- **Description**: Get events visible to user
- **Response**: `200 OK`
  ```json
  {
    "events": [
      {
        "id": "UUID string",
        "title": "string",
        "description": "string",
        "latitude": "number",
        "longitude": "number",
        "time": "ISO 8601 datetime string",
        "end_time": "ISO 8601 datetime string",
        "host": "string",
        "hostIsCertified": "boolean",
        "isPublic": "boolean",
        "event_type": "string",
        "invitedFriends": ["user1", "user2", ...],
        "attendees": ["user1", "user2", ...]
      }
    ]
  }
  ```

#### RSVP Study Event
- **Endpoint**: `POST /api/rsvp_study_event/`
- **Description**: RSVP to an event
- **Request Body**:
  ```json
  {
    "username": "string",
    "event_id": "UUID string"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "success": true,
    "message": "RSVP successful"
  }
  ```

#### Delete Study Event
- **Endpoint**: `POST /api/delete_study_event/`
- **Description**: Delete an event
- **Request Body**:
  ```json
  {
    "username": "string",
    "event_id": "UUID string"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "success": true,
    "message": "Event deleted successfully"
  }
  ```

### Event Social Interactions

#### Add Event Comment
- **Endpoint**: `POST /api/events/comment/`
- **Description**: Add a comment to an event
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
    "comment_id": "UUID string",
    "message": "Comment added successfully"
  }
  ```

#### Toggle Event Like
- **Endpoint**: `POST /api/events/like/`
- **Description**: Like or unlike an event
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
    "liked": "boolean",
    "message": "Like toggled successfully"
  }
  ```

#### Record Event Share
- **Endpoint**: `POST /api/events/share/`
- **Description**: Record an event share
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

#### Get Event Interactions
- **Endpoint**: `GET /api/events/interactions/{event_id}/`
- **Description**: Get all interactions for an event
- **Response**: `200 OK`
  ```json
  {
    "comments": [...],
    "likes": [...],
    "shares": [...]
  }
  ```

#### Get Event Feed
- **Endpoint**: `GET /api/events/feed/{event_id}/`
- **Description**: Get event feed data
- **Response**: `200 OK`
  ```json
  {
    "posts": [
      {
        "id": "UUID string",
        "type": "comment|like|share",
        "username": "string",
        "content": "string",
        "timestamp": "ISO 8601 datetime string"
      }
    ]
  }
  ```

### Invitations

#### Invite to Event
- **Endpoint**: `POST /invite_to_event/`
- **Description**: Invite a user to an event
- **Request Body**:
  ```json
  {
    "event_id": "UUID string",
    "username": "string",
    "mark_as_auto_matched": "boolean"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "success": true,
    "message": "User invited to event successfully",
    "is_auto_matched": "boolean"
  }
  ```

#### Get Invitations
- **Endpoint**: `GET /api/get_invitations/{username}/`
- **Description**: Get user's invitations
- **Response**: `200 OK`
  ```json
  {
    "invitations": [
      {
        "id": "UUID string",
        "title": "string",
        "description": "string",
        "latitude": "number",
        "longitude": "number",
        "time": "ISO 8601 datetime string",
        "end_time": "ISO 8601 datetime string",
        "host": "string",
        "hostIsCertified": "boolean",
        "isPublic": "boolean",
        "event_type": "string",
        "isAutoMatched": "boolean",
        "invitedFriends": ["user1", "user2", ...],
        "attendees": ["user1", "user2", ...]
      }
    ]
  }
  ```

#### Decline Invitation
- **Endpoint**: `POST /api/decline_invitation/`
- **Description**: Decline an event invitation
- **Request Body**:
  ```json
  {
    "username": "string",
    "event_id": "UUID string"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "success": true,
    "message": "Invitation declined successfully"
  }
  ```

### User Profiles

#### Get User Profile
- **Endpoint**: `GET /api/get_user_profile/{username}/`
- **Description**: Get user profile information
- **Response**: `200 OK`
  ```json
  {
    "username": "string",
    "full_name": "string",
    "university": "string",
    "degree": "string",
    "year": "string",
    "bio": "string",
    "profile_picture": "string",
    "is_certified": "boolean",
    "interests": ["interest1", "interest2", ...],
    "skills": {
      "skill1": "level",
      "skill2": "level"
    }
  }
  ```

#### Update User Interests
- **Endpoint**: `POST /api/update_user_interests/`
- **Description**: Update user profile and interests
- **Request Body**:
  ```json
  {
    "username": "string",
    "full_name": "string (optional)",
    "university": "string (optional)",
    "degree": "string (optional)",
    "year": "string (optional)",
    "bio": "string (optional)",
    "profile_picture": "string (optional)",
    "interests": ["interest1", "interest2", ...],
    "skills": {
      "skill1": "BEGINNER|INTERMEDIATE|ADVANCED|EXPERT",
      "skill2": "BEGINNER|INTERMEDIATE|ADVANCED|EXPERT"
    },
    "auto_invite_preference": "boolean",
    "preferred_radius": "number"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "success": true,
    "message": "Profile updated successfully"
  }
  ```

#### Certify User
- **Endpoint**: `POST /api/certify_user/`
- **Description**: Certify a user
- **Request Body**:
  ```json
  {
    "username": "string"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "success": true,
    "message": "User certified."
  }
  ```

### User Ratings and Reputation

#### Submit User Rating
- **Endpoint**: `POST /api/submit_user_rating/`
- **Description**: Submit a rating for another user
- **Request Body**:
  ```json
  {
    "from_username": "string",
    "to_username": "string",
    "event_id": "UUID string (optional)",
    "rating": "number (1-5)",
    "reference": "string (optional)"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "success": true,
    "message": "Rating submitted successfully",
    "rating_id": "UUID string"
  }
  ```

#### Get User Reputation
- **Endpoint**: `GET /api/get_user_reputation/{username}/`
- **Description**: Get user reputation statistics
- **Response**: `200 OK`
  ```json
  {
    "username": "string",
    "average_rating": "number",
    "total_ratings": "number",
    "trust_level": "number",
    "events_hosted": "number",
    "events_attended": "number"
  }
  ```

#### Get User Ratings
- **Endpoint**: `GET /api/get_user_ratings/{username}/`
- **Description**: Get detailed ratings for a user
- **Response**: `200 OK`
  ```json
  {
    "given_ratings": [...],
    "received_ratings": [...]
  }
  ```

#### Get Trust Levels
- **Endpoint**: `GET /api/get_trust_levels/`
- **Description**: Get all available trust levels
- **Response**: `200 OK`
  ```json
  {
    "trust_levels": [
      {
        "level": "number",
        "name": "string",
        "description": "string"
      }
    ]
  }
  ```

### Image Management

#### Upload User Image
- **Endpoint**: `POST /api/upload_user_image/`
- **Description**: Upload a user image
- **Request Type**: `multipart/form-data`
- **Form Data**:
  - `image`: File
  - `username`: String
  - `image_type`: String (profile, gallery, etc.)
  - `is_primary`: Boolean
  - `caption`: String
- **Response**: `200 OK`
  ```json
  {
    "success": true,
    "image_id": "UUID string",
    "url": "string",
    "message": "Image uploaded successfully"
  }
  ```

#### Get User Images
- **Endpoint**: `GET /api/user_images/{username}/`
- **Description**: Get all images for a user
- **Response**: `200 OK`
  ```json
  {
    "images": [
      {
        "id": "UUID string",
        "url": "string",
        "image_type": "string",
        "is_primary": "boolean",
        "caption": "string",
        "created_at": "ISO 8601 datetime string"
      }
    ]
  }
  ```

#### Get Multiple User Images
- **Endpoint**: `POST /api/multiple_user_images/`
- **Description**: Get images for multiple users
- **Request Body**:
  ```json
  {
    "usernames": ["user1", "user2", ...]
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "user_images": {
      "user1": [
        {
          "id": "UUID string",
          "url": "string",
          "image_type": "string",
          "is_primary": "boolean"
        }
      ]
    }
  }
  ```

### Search and Discovery

#### Search Events
- **Endpoint**: `GET /api/search_events/`
- **Description**: Search for events
- **Query Parameters**:
  - `query`: String (search term)
  - `public_only`: Boolean
  - `certified_only`: Boolean
- **Response**: `200 OK`
  ```json
  {
    "events": [...]
  }
  ```

#### Enhanced Search Events
- **Endpoint**: `GET /api/enhanced_search_events/`
- **Description**: Enhanced event search with filters
- **Query Parameters**:
  - `query`: String
  - `public_only`: Boolean
  - `certified_only`: Boolean
  - `event_type`: String
- **Response**: `200 OK`
  ```json
  {
    "events": [...]
  }
  ```

### Auto-Matching

#### Advanced Auto Match
- **Endpoint**: `POST /api/advanced_auto_match/`
- **Description**: Perform advanced auto-matching for an event
- **Request Body**:
  ```json
  {
    "event_id": "UUID string",
    "max_invites": "number",
    "min_score": "number",
    "potentials_only": "boolean"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "success": true,
    "matched_users": [...],
    "invites_sent": "number"
  }
  ```

#### Get Auto Matched Users
- **Endpoint**: `GET /api/get_auto_matched_users/{event_id}/`
- **Description**: Get users auto-matched for an event
- **Response**: `200 OK`
  ```json
  {
    "auto_matched_users": [...]
  }
  ```

### Utility Endpoints

#### Health Check
- **Endpoint**: `GET /health/`
- **Description**: Check API health
- **Response**: `200 OK`
  ```json
  {
    "status": "healthy",
    "message": "PinIt API is running - Railway deployment test"
  }
  ```

## Error Responses

All endpoints may return the following error responses:

### 400 Bad Request
```json
{
  "error": "Error description",
  "message": "Detailed error message"
}
```

### 404 Not Found
```json
{
  "error": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error"
}
```

## Data Models

### StudyEvent
```json
{
  "id": "UUID string",
  "title": "string",
  "description": "string",
  "latitude": "number",
  "longitude": "number",
  "time": "ISO 8601 datetime string",
  "end_time": "ISO 8601 datetime string",
  "host": "string",
  "hostIsCertified": "boolean",
  "isPublic": "boolean",
  "event_type": "string",
  "max_participants": "number",
  "auto_matching_enabled": "boolean",
  "invitedFriends": ["string"],
  "attendees": ["string"],
  "interest_tags": ["string"]
}
```

### UserProfile
```json
{
  "username": "string",
  "full_name": "string",
  "university": "string",
  "degree": "string",
  "year": "string",
  "bio": "string",
  "profile_picture": "string",
  "is_certified": "boolean",
  "interests": ["string"],
  "skills": {
    "skill_name": "BEGINNER|INTERMEDIATE|ADVANCED|EXPERT"
  },
  "auto_invite_preference": "boolean",
  "preferred_radius": "number"
}
```

### EventInvitation
```json
{
  "event": "UUID string",
  "user": "string",
  "is_auto_matched": "boolean",
  "created_at": "ISO 8601 datetime string"
}
```

## Rate Limiting
Currently no rate limiting is implemented, but it may be added in the future.

## CORS
CORS is configured to allow requests from the frontend application.

## Deployment
The API is deployed on Railway and automatically updates when changes are pushed to the main branch of the pinit-backend repository.
