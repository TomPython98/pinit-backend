# StudyCon API Documentation

## 🌐 Base URL
```
Development: http://localhost:8000
Production: https://pinit-backend-production.up.railway.app
```

### Production Status
- **Platform**: Railway
- **Status**: ✅ Live and operational
- **Health Check**: https://pinit-backend-production.up.railway.app/api/health/
- **Database**: SQLite3 with 29 users and 150+ events

## 🔐 Authentication

### Register User
```http
POST /api/register/
Content-Type: application/json

{
    "username": "string",
    "password": "string"
}
```

**Response:**
```json
{
    "success": true,
    "message": "User registered successfully."
}
```

### Login User
```http
POST /api/login/
Content-Type: application/json

{
    "username": "string",
    "password": "string"
}
```

**Response:**
```json
{
    "success": true,
    "message": "Login successful.",
    "token": "your_auth_token"
}
```

### Logout User
```http
POST /api/logout/
Authorization: Token your_auth_token
```

## 👥 User Management

### Get All Users
```http
GET /api/get_all_users/
Authorization: Token your_auth_token
```

**Response:**
```json
[
    {
        "id": 1,
        "username": "user1",
        "email": "",
        "first_name": "",
        "last_name": "",
        "date_joined": "2025-01-01T00:00:00Z"
    }
]
```

### Get User Profile
```http
GET /api/get_user_profile/<username>/
Authorization: Token your_auth_token
```

**Response:**
```json
{
    "username": "user1",
    "is_certified": true,
    "full_name": "John Doe",
    "university": "University of Vienna",
    "degree": "Computer Science",
    "year": "3rd Year",
    "bio": "Student interested in AI and machine learning",
    "interests": ["programming", "AI", "machine learning"],
    "skills": {
        "python": "ADVANCED",
        "javascript": "INTERMEDIATE"
    },
    "auto_invite_enabled": true,
    "preferred_radius": 10.0
}
```

### Profile Completion
```http
GET /api/profile_completion/<username>/
Authorization: Token your_auth_token
```

**Response:**
```json
{
    "completion_percentage": 85,
    "missing_fields": ["bio", "skills"],
    "is_complete": false
}
```

## 👫 Social Features

### Send Friend Request
```http
POST /api/send_friend_request/
Content-Type: application/json
Authorization: Token your_auth_token

{
    "from_username": "user1",
    "to_username": "user2"
}
```

### Accept Friend Request
```http
POST /api/accept_friend_request/
Content-Type: application/json
Authorization: Token your_auth_token

{
    "from_username": "user1",
    "to_username": "user2"
}
```

### Get Friends
```http
GET /api/get_friends/<username>/
Authorization: Token your_auth_token
```

**Response:**
```json
{
    "friends": ["user2", "user3", "user4"],
    "count": 3
}
```

### Get Pending Requests
```http
GET /api/get_pending_requests/<username>/
Authorization: Token your_auth_token
```

**Response:**
```json
{
    "pending_requests": ["user5", "user6"],
    "count": 2
}
```

### Get Sent Requests
```http
GET /api/get_sent_requests/<username>/
Authorization: Token your_auth_token
```

## 📅 Event Management

### Get Study Events
```http
GET /api/get_study_events/<username>/
Authorization: Token your_auth_token
```

**Response:**
```json
{
    "events": [
        {
            "id": "uuid-string",
            "title": "Study Group: Machine Learning",
            "description": "Weekly ML study session",
            "host": "user1",
            "time": "2025-01-15T14:00:00Z",
            "end_time": "2025-01-15T16:00:00Z",
            "latitude": 48.2082,
            "longitude": 16.3738,
            "is_public": true,
            "event_type": "study",
            "attendees": ["user2", "user3"],
            "invited_friends": ["user4"],
            "matched_users": ["user5"],
            "interest_tags": ["AI", "machine learning"],
            "isAutoMatched": false,
            "hostIsCertified": true
        }
    ],
    "count": 1
}
```

### Create Study Event
```http
POST /api/create_study_event/
Content-Type: application/json
Authorization: Token your_auth_token

{
    "title": "Study Group: Python",
    "description": "Learning Python basics",
    "time": "2025-01-20T10:00:00Z",
    "end_time": "2025-01-20T12:00:00Z",
    "latitude": 48.2082,
    "longitude": 16.3738,
    "is_public": true,
    "event_type": "study",
    "interest_tags": ["python", "programming"]
}
```

**Response:**
```json
{
    "success": true,
    "event_id": "uuid-string",
    "message": "Event created successfully"
}
```

### RSVP to Event
```http
POST /api/rsvp_study_event/
Content-Type: application/json
Authorization: Token your_auth_token

{
    "event_id": "uuid-string",
    "username": "user1",
    "action": "join"  // or "leave"
}
```

### Delete Study Event
```http
POST /api/delete_study_event/
Content-Type: application/json
Authorization: Token your_auth_token

{
    "event_id": "uuid-string",
    "username": "user1"
}
```

## 📨 Invitations

### Get Invitations
```http
GET /api/get_invitations/<username>/
Authorization: Token your_auth_token
```

**Response:**
```json
{
    "invitations": [
        {
            "id": "uuid-string",
            "event": {
                "id": "event-uuid",
                "title": "Study Group: Data Science",
                "time": "2025-01-25T15:00:00Z",
                "host": "user2"
            },
            "is_auto_matched": false,
            "created_at": "2025-01-10T10:00:00Z"
        }
    ],
    "count": 1
}
```

### Decline Invitation
```http
POST /api/decline_invitation/
Content-Type: application/json
Authorization: Token your_auth_token

{
    "invitation_id": "uuid-string",
    "username": "user1"
}
```

## 🤖 Smart Matching

### Advanced Auto Match
```http
POST /api/advanced_auto_match/
Content-Type: application/json
Authorization: Token your_auth_token

{
    "event_id": "uuid-string",
    "max_matches": 5
}
```

### Get Auto Matched Users
```http
GET /api/get_auto_matched_users/<event_id>/
Authorization: Token your_auth_token
```

**Response:**
```json
{
    "matched_users": ["user3", "user4", "user5"],
    "count": 3,
    "matching_criteria": {
        "interests_match": 0.8,
        "skills_match": 0.6,
        "location_proximity": 0.9
    }
}
```

## 💬 Event Social Interactions

### Add Event Comment
```http
POST /api/events/comment/
Content-Type: application/json
Authorization: Token your_auth_token

{
    "event_id": "uuid-string",
    "user": "user1",
    "content": "Great study session!"
}
```

### Toggle Event Like
```http
POST /api/events/like/
Content-Type: application/json
Authorization: Token your_auth_token

{
    "event_id": "uuid-string",
    "user": "user1"
}
```

### Record Event Share
```http
POST /api/events/share/
Content-Type: application/json
Authorization: Token your_auth_token

{
    "event_id": "uuid-string",
    "user": "user1",
    "platform": "whatsapp"
}
```

### Get Event Feed
```http
GET /api/events/feed/<event_id>/?current_user=<username>
Authorization: Token your_auth_token
```

**Response:**
```json
{
    "event": {
        "id": "uuid-string",
        "title": "Study Group: AI",
        "host": "user1"
    },
    "comments": [
        {
            "id": "uuid-string",
            "user": "user2",
            "content": "Looking forward to this!",
            "created_at": "2025-01-10T10:00:00Z"
        }
    ],
    "likes": [
        {
            "id": "uuid-string",
            "user": "user3",
            "created_at": "2025-01-10T10:05:00Z"
        }
    ],
    "shares": [
        {
            "id": "uuid-string",
            "user": "user4",
            "platform": "whatsapp",
            "created_at": "2025-01-10T10:10:00Z"
        }
    ],
    "stats": {
        "total_comments": 5,
        "total_likes": 12,
        "total_shares": 3
    }
}
```

## ⭐ User Rating & Reputation

### Submit User Rating
```http
POST /api/submit_user_rating/
Content-Type: application/json
Authorization: Token your_auth_token

{
    "from_username": "user1",
    "to_username": "user2",
    "event_id": "uuid-string",
    "rating": 5,
    "reference": "Great study partner!"
}
```

### Get User Reputation
```http
GET /api/get_user_reputation/<username>/
Authorization: Token your_auth_token
```

**Response:**
```json
{
    "username": "user1",
    "total_ratings": 17,
    "average_rating": 3.65,
    "events_hosted": 4,
    "events_attended": 12,
    "trust_level": {
        "level": 3,
        "title": "Trusted Member"
    }
}
```

### Get User Ratings
```http
GET /api/get_user_ratings/<username>/
Authorization: Token your_auth_token
```

**Response:**
```json
{
    "ratings_received": [
        {
            "id": "uuid-string",
            "from_username": "user2",
            "to_username": "user1",
            "event_id": "uuid-string",
            "rating": 5,
            "reference": "Excellent organizer!",
            "created_at": "2025-01-10T10:00:00Z"
        }
    ],
    "count": 1
}
```

### Get Trust Levels
```http
GET /api/get_trust_levels/
Authorization: Token your_auth_token
```

**Response:**
```json
[
    {
        "level": 1,
        "title": "Newcomer",
        "required_ratings": 0,
        "min_average_rating": 0.0
    },
    {
        "level": 2,
        "title": "Participant",
        "required_ratings": 3,
        "min_average_rating": 3.0
    },
    {
        "level": 3,
        "title": "Trusted Member",
        "required_ratings": 10,
        "min_average_rating": 3.5
    }
]
```

## 🔍 Search & Discovery

### Search Events
```http
POST /api/search_events/
Content-Type: application/json
Authorization: Token your_auth_token

{
    "query": "machine learning",
    "latitude": 48.2082,
    "longitude": 16.3738,
    "radius": 10.0,
    "event_type": "study"
}
```

### Enhanced Search Events
```http
POST /api/enhanced_search_events/
Content-Type: application/json
Authorization: Token your_auth_token

{
    "interests": ["AI", "machine learning"],
    "skills": {"python": "INTERMEDIATE"},
    "latitude": 48.2082,
    "longitude": 16.3738,
    "radius": 10.0,
    "time_range": {
        "start": "2025-01-15T00:00:00Z",
        "end": "2025-01-20T23:59:59Z"
    }
}
```

## 🔌 WebSocket Endpoints

### Real-time Event Updates
```javascript
// Connect to WebSocket
const ws = new WebSocket('ws://localhost:8000/ws/events/user1/');

ws.onopen = function(event) {
    console.log('WebSocket connected');
};

ws.onmessage = function(event) {
    const data = JSON.parse(event.data);
    console.log('Received:', data);
    
    // Handle different message types
    switch(data.type) {
        case 'event_created':
            // Handle new event
            break;
        case 'event_updated':
            // Handle event update
            break;
        case 'event_deleted':
            // Handle event deletion
            break;
        case 'invitation_received':
            // Handle new invitation
            break;
    }
};

ws.onclose = function(event) {
    console.log('WebSocket disconnected');
};
```

## 📱 Push Notifications

### Register Device
```http
POST /api/register-device/
Content-Type: application/json
Authorization: Token your_auth_token

{
    "device_token": "ios_device_token",
    "platform": "ios"
}
```

### Schedule Rating Reminder
```http
POST /api/schedule_rating_reminder/
Content-Type: application/json
Authorization: Token your_auth_token

{
    "event_id": "uuid-string",
    "user": "user1",
    "reminder_time": "2025-01-15T18:00:00Z"
}
```

## 🚨 Error Responses

### Common Error Codes
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Authentication required
- `403 Forbidden`: Access denied
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

### Error Response Format
```json
{
    "success": false,
    "message": "Error description",
    "error_code": "SPECIFIC_ERROR_CODE",
    "details": {
        "field": "Additional error details"
    }
}
```

## 📊 Rate Limiting

- **Authentication**: 5 requests per minute
- **Event Creation**: 10 events per hour
- **Social Interactions**: 100 requests per hour
- **Search**: 50 requests per hour

## 🔒 Security Notes

1. **Authentication**: Use token-based authentication for all protected endpoints
2. **HTTPS**: Always use HTTPS in production
3. **CORS**: Configure CORS properly for your frontend domain
4. **Input Validation**: All inputs are validated on the server
5. **Rate Limiting**: Implemented to prevent abuse

---

**Last Updated**: January 2025
**API Version**: 1.0.0

