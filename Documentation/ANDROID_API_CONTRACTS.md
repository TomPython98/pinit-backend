# Android API Contracts

## Base Configuration

### Base URL
```
https://pinit-backend-production.up.railway.app/api/
```

### Authentication
- **Method**: Username/Password
- **Headers**: `Content-Type: application/json`
- **Session**: Stateless (no tokens)

### Timeout Settings
- **Connect Timeout**: 60 seconds
- **Read Timeout**: 60 seconds
- **Write Timeout**: 60 seconds

## API Endpoints

### Authentication Endpoints

#### POST /api/login/
**Description**: User login
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
  "message": "Login successful"
}
```
**Error Codes**: 400, 401, 500

#### POST /api/register/
**Description**: User registration
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
  "message": "Registration successful"
}
```
**Error Codes**: 400, 409, 500

### Event Endpoints

#### GET /api/get_study_events/{username}/
**Description**: Get events for a user
**Path Parameters**:
- `username`: string (required)
**Query Parameters**:
- `event_id`: string (optional) - Get specific event
**Response**:
```json
{
  "events": [
    {
      "id": "string",
      "title": "string",
      "description": "string",
      "latitude": 0.0,
      "longitude": 0.0,
      "time": "2024-01-01T10:00:00Z",
      "end_time": "2024-01-01T12:00:00Z",
      "host": "string",
      "hostIsCertified": true,
      "isPublic": true,
      "event_type": "study",
      "invitedFriends": ["string"],
      "attendees": ["string"],
      "isAutoMatched": false
    }
  ]
}
```
**Error Codes**: 400, 404, 500

#### POST /api/create_study_event/
**Description**: Create a new event
**Request Body**:
```json
{
  "title": "string",
  "description": "string",
  "latitude": 0.0,
  "longitude": 0.0,
  "time": "2024-01-01T10:00:00Z",
  "end_time": "2024-01-01T12:00:00Z",
  "host": "string",
  "isPublic": true,
  "event_type": "study",
  "invitedFriends": ["string"],
  "maxParticipants": 10,
  "interestTags": ["string"],
  "autoMatchingEnabled": false
}
```
**Response**:
```json
{
  "id": "string",
  "title": "string",
  "description": "string",
  "latitude": 0.0,
  "longitude": 0.0,
  "time": "2024-01-01T10:00:00Z",
  "end_time": "2024-01-01T12:00:00Z",
  "host": "string",
  "hostIsCertified": true,
  "isPublic": true,
  "event_type": "study"
}
```
**Error Codes**: 400, 401, 500

#### POST /api/rsvp_study_event/
**Description**: RSVP to an event
**Request Body**:
```json
{
  "username": "string",
  "event_id": "string"
}
```
**Response**:
```json
{
  "success": true,
  "message": "RSVP successful"
}
```
**Error Codes**: 400, 404, 500

#### GET /api/search_events/
**Description**: Search events
**Query Parameters**:
- `query`: string (required)
- `public_only`: boolean (optional, default: false)
- `certified_only`: boolean (optional, default: false)
- `event_type`: string (optional)
- `semantic`: boolean (optional, default: false)
**Response**:
```json
{
  "events": [
    {
      "id": "string",
      "title": "string",
      "description": "string",
      "latitude": 0.0,
      "longitude": 0.0,
      "time": "2024-01-01T10:00:00Z",
      "end_time": "2024-01-01T12:00:00Z",
      "host": "string",
      "hostIsCertified": true,
      "isPublic": true,
      "event_type": "study"
    }
  ]
}
```
**Error Codes**: 400, 500

### User Profile Endpoints

#### GET /api/get_user_profile/{username}/
**Description**: Get user profile
**Path Parameters**:
- `username`: string (required)
**Response**:
```json
{
  "username": "string",
  "is_certified": true,
  "interests": ["string"],
  "skills": {
    "string": "string"
  },
  "auto_invite_enabled": true,
  "preferred_radius": 10.0,
  "full_name": "string",
  "university": "string",
  "degree": "string",
  "year": "string",
  "bio": "string"
}
```
**Error Codes**: 400, 404, 500

#### POST /api/update_user_interests/
**Description**: Update user interests and preferences
**Request Body**:
```json
{
  "username": "string",
  "interests": ["string"],
  "skills": {
    "string": "string"
  },
  "auto_invite_preference": true,
  "preferred_radius": 10.0,
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
  "message": "Profile updated successfully"
}
```
**Error Codes**: 400, 401, 500

#### GET /api/profile_completion/{username}/
**Description**: Get profile completion details
**Path Parameters**:
- `username`: string (required)
**Response**:
```json
{
  "completion_percentage": 75.0,
  "missing_items": ["string"],
  "benefits_message": "string",
  "completion_level": "string",
  "category_breakdown": {
    "string": {
      "string": "any"
    }
  }
}
```
**Error Codes**: 400, 404, 500

### Auto-matching Endpoints

#### POST /api/auto_match_event/
**Description**: Auto-match users to an event
**Request Body**:
```json
{
  "event_id": "string",
  "username": "string"
}
```
**Response**:
```json
{
  "matches": {
    "username": 0.85
  }
}
```
**Error Codes**: 400, 404, 500

#### POST /api/advanced_auto_match/
**Description**: Advanced auto-matching algorithm
**Request Body**:
```json
{
  "event_id": "string",
  "max_invites": 10,
  "min_score": 30.0
}
```
**Response**:
```json
{
  "matches": {
    "username": 0.85
  },
  "total_matches": 5,
  "algorithm_version": "2.0"
}
```
**Error Codes**: 400, 404, 500

#### POST /api/invite_to_event/
**Description**: Invite a user to an event
**Request Body**:
```json
{
  "event_id": "string",
  "username": "string",
  "is_auto_matched": false
}
```
**Response**:
```json
{
  "success": true,
  "message": "Invitation sent successfully"
}
```
**Error Codes**: 400, 404, 500

### Social Features Endpoints

#### GET /api/get_friends/{username}/
**Description**: Get user's friends list
**Path Parameters**:
- `username`: string (required)
**Response**:
```json
{
  "friends": ["string"]
}
```
**Error Codes**: 400, 404, 500

#### POST /api/send_friend_request/
**Description**: Send friend request
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
**Error Codes**: 400, 404, 500

#### POST /api/accept_friend_request/
**Description**: Accept friend request
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
  "message": "Friend request accepted",
  "from_user_friends": ["string"],
  "to_user_friends": ["string"]
}
```
**Error Codes**: 400, 404, 500

#### GET /api/get_pending_requests/{username}/
**Description**: Get pending friend requests
**Path Parameters**:
- `username`: string (required)
**Response**:
```json
{
  "pending_requests": ["string"]
}
```
**Error Codes**: 400, 404, 500

#### GET /api/get_sent_requests/{username}/
**Description**: Get sent friend requests
**Path Parameters**:
- `username`: string (required)
**Response**:
```json
{
  "sent_requests": ["string"]
}
```
**Error Codes**: 400, 404, 500

### Reputation System Endpoints

#### GET /api/get_user_reputation/{username}/
**Description**: Get user reputation statistics
**Path Parameters**:
- `username`: string (required)
**Response**:
```json
{
  "username": "string",
  "total_ratings": 10,
  "average_rating": 4.5,
  "events_hosted": 5,
  "events_attended": 15,
  "trust_level": {
    "level": 3,
    "title": "Trusted"
  }
}
```
**Error Codes**: 400, 404, 500

#### GET /api/get_user_ratings/{username}/
**Description**: Get detailed user ratings
**Path Parameters**:
- `username`: string (required)
**Response**:
```json
{
  "username": "string",
  "ratings_received": [
    {
      "id": "string",
      "from_username": "string",
      "to_username": "string",
      "rating": 5,
      "reference": "string",
      "event_id": "string",
      "event_title": "string",
      "created_at": "2024-01-01T10:00:00Z"
    }
  ],
  "ratings_given": [
    {
      "id": "string",
      "from_username": "string",
      "to_username": "string",
      "rating": 4,
      "reference": "string",
      "event_id": "string",
      "event_title": "string",
      "created_at": "2024-01-01T10:00:00Z"
    }
  ],
  "total_received": 10,
  "total_given": 8
}
```
**Error Codes**: 400, 404, 500

#### POST /api/submit_user_rating/
**Description**: Submit a user rating
**Request Body**:
```json
{
  "from_username": "string",
  "to_username": "string",
  "rating": 5,
  "reference": "string",
  "event_id": "string"
}
```
**Response**:
```json
{
  "success": true,
  "message": "Rating submitted successfully"
}
```
**Error Codes**: 400, 401, 500

### Event Interactions Endpoints

#### GET /api/events/feed/{eventId}/
**Description**: Get event social feed
**Path Parameters**:
- `eventId`: string (required)
**Query Parameters**:
- `current_user`: string (required)
**Response**:
```json
{
  "event_id": "string",
  "posts": [
    {
      "id": "string",
      "username": "string",
      "text": "string",
      "images": ["string"],
      "created_at": "2024-01-01T10:00:00Z"
    }
  ],
  "likes": [
    {
      "id": "string",
      "username": "string",
      "created_at": "2024-01-01T10:00:00Z"
    }
  ],
  "comments": [
    {
      "id": "string",
      "username": "string",
      "text": "string",
      "created_at": "2024-01-01T10:00:00Z"
    }
  ],
  "shares": [
    {
      "id": "string",
      "username": "string",
      "created_at": "2024-01-01T10:00:00Z"
    }
  ]
}
```
**Error Codes**: 400, 404, 500

## Error Handling

### Standard Error Response
```json
{
  "error": "string",
  "message": "string",
  "details": "string"
}
```

### HTTP Status Codes
- **200**: Success
- **201**: Created
- **400**: Bad Request
- **401**: Unauthorized
- **404**: Not Found
- **409**: Conflict
- **500**: Internal Server Error

### Error Handling in Android
```kotlin
// Repository error handling
fun getEventsForUser(username: String): Flow<Result<List<StudyEventMap>>> = flow {
    try {
        val response = apiService.getStudyEvents(username)
        if (response.isSuccessful) {
            emit(Result.success(response.body()?.events ?: emptyList()))
        } else {
            emit(Result.failure(ApiException("HTTP ${response.code()}")))
        }
    } catch (e: Exception) {
        emit(Result.failure(e))
    }
}
```

## Rate Limiting

### Current Status
- **Rate Limiting**: Not implemented
- **Throttling**: Not implemented
- **Caching**: Basic in-memory caching

### Recommendations
- Implement rate limiting for API calls
- Add request throttling
- Implement proper caching strategy
- Add retry logic with exponential backoff

## Data Models

### Event Types
```kotlin
enum class EventType(val displayName: String) {
    STUDY("Study"),
    PARTY("Party"),
    BUSINESS("Business"),
    CULTURAL("Cultural"),
    ACADEMIC("Academic"),
    NETWORKING("Networking"),
    SOCIAL("Social"),
    LANGUAGE_EXCHANGE("Language Exchange"),
    OTHER("Other")
}
```

### User Profile Model
```kotlin
data class UserProfile(
    val username: String,
    val isCertified: Boolean = false,
    val interests: List<String> = emptyList(),
    val skills: Map<String, String> = emptyMap(),
    val autoInviteEnabled: Boolean = true,
    val preferredRadius: Float = 10.0f,
    val fullName: String = "",
    val university: String = "",
    val degree: String = "",
    val year: String = "",
    val bio: String = ""
)
```

### Event Model
```kotlin
data class StudyEventMap(
    val id: String? = null,
    val title: String,
    val coordinate: Pair<Double, Double>? = null,
    val time: LocalDateTime,
    val endTime: LocalDateTime? = null,
    val description: String? = null,
    val invitedFriends: List<String> = emptyList(),
    val attendees: Int = 0,
    val attendeesList: List<String> = emptyList(),
    val isPublic: Boolean = true,
    val host: String,
    val hostIsCertified: Boolean = false,
    val eventType: EventType? = EventType.STUDY,
    val isUserAttending: Boolean = false,
    val interestTags: List<String> = emptyList(),
    val maxParticipants: Int = 10,
    val autoMatchingEnabled: Boolean = false,
    val isAutoMatched: Boolean = false,
    val matchedUsers: List<String> = emptyList(),
    val eventImages: List<String> = emptyList()
)
```

## Testing

### API Testing
```kotlin
// Unit test for API service
@Test
fun `test get events for user`() = runTest {
    val mockResponse = ApiEventsResponse(
        events = listOf(
            EventResponse(
                id = "1",
                title = "Test Event",
                description = "Test Description",
                latitude = -34.6037,
                longitude = -58.3816,
                time = "2024-01-01T10:00:00Z",
                endTime = "2024-01-01T12:00:00Z",
                host = "testuser",
                hostIsCertified = true,
                isPublic = true,
                eventType = "study"
            )
        )
    )
    
    coEvery { apiService.getStudyEvents("testuser") } returns Response.success(mockResponse)
    
    val result = eventRepository.getEventsForUser("testuser").first()
    
    assertTrue(result.isSuccess)
    assertEquals(1, result.getOrNull()?.size)
}
```

### Integration Testing
```kotlin
// Integration test for API client
@Test
fun `test API client configuration`() {
    val apiClient = ApiClient()
    val apiService = apiClient.apiService
    
    assertNotNull(apiService)
    assertEquals("https://pinit-backend-production.up.railway.app/api/", apiClient.getBaseUrl())
}
```

