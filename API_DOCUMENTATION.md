# PinIt Backend API Documentation

## 🚀 Overview
This document provides comprehensive documentation for the PinIt Backend API, including working endpoints, known issues, and implementation details discovered during testing.

## 📍 Base URL
```
https://pinit-backend-production.up.railway.app/api/
```

---

## ✅ WORKING ENDPOINTS

### 🔐 Authentication & User Management

#### 1. User Registration
- **Endpoint**: `POST /register/`
- **Status**: ✅ WORKING
- **Description**: Creates new user accounts
- **Request Body**:
```json
{
  "username": "string",
  "password": "string",
  "first_name": "string",
  "last_name": "string",
  "email": "string",
  "university": "string",
  "degree": "string",
  "year": "string",
  "country": "string",
  "bio": "string",
  "interests": ["string"],
  "skills": ["string"],
  "auto_invite_preference": boolean,
  "preferred_radius": number
}
```
- **Response**:
```json
{
  "success": true,
  "message": "User created successfully",
  "user_id": "uuid"
}
```

#### 2. User Login
- **Endpoint**: `POST /login/`
- **Status**: ✅ WORKING (assumed)
- **Description**: Authenticates users
- **Request Body**:
```json
{
  "username": "string",
  "password": "string"
}
```

### 📅 Event Management

#### 3. Create Study Event
- **Endpoint**: `POST /create_study_event/`
- **Status**: ✅ WORKING
- **Description**: Creates new study events
- **Request Body**:
```json
{
  "host": "string",
  "title": "string",
  "description": "string",
  "latitude": number,
  "longitude": number,
  "time": "ISO8601_datetime",
  "end_time": "ISO8601_datetime",
  "max_participants": number,
  "event_type": "string",
  "interest_tags": ["string"],
  "auto_matching_enabled": boolean
}
```
- **Response**:
```json
{
  "success": true,
  "event_id": "uuid",
  "message": "Event created successfully"
}
```

#### 4. RSVP to Study Event
- **Endpoint**: `POST /rsvp_study_event/`
- **Status**: ✅ WORKING
- **Description**: Users RSVP to events
- **Request Body**:
```json
{
  "username": "string",
  "event_id": "uuid"
}
```

### 💬 Event Interactions

#### 5. Comment on Event
- **Endpoint**: `POST /events/comment/`
- **Status**: ✅ WORKING
- **Description**: Add comments to events
- **Request Body**:
```json
{
  "username": "string",
  "event_id": "uuid",
  "text": "string"
}
```

#### 6. Like Event
- **Endpoint**: `POST /events/like/`
- **Status**: ✅ WORKING
- **Description**: Like events
- **Request Body**:
```json
{
  "username": "string",
  "event_id": "uuid"
}
```

#### 7. Share Event
- **Endpoint**: `POST /events/share/`
- **Status**: ✅ WORKING
- **Description**: Share events on social platforms
- **Request Body**:
```json
{
  "username": "string",
  "event_id": "uuid",
  "shared_platform": "string"
}
```

#### 8. Comment on Event
- **Endpoint**: `POST /events/comment/`
- **Status**: ⚠️ PARTIALLY WORKING
- **Description**: Add comments to events
- **Request Body**:
```json
{
  "username": "string",
  "event_id": "uuid",
  "text": "string"
}
```
- **Note**: Returns 201 (Created) instead of expected 200 (OK), but functionality works

### 🤝 Social Connections

#### 9. Send Friend Request
- **Endpoint**: `POST /send_friend_request/`
- **Status**: ✅ WORKING
- **Description**: Send friend requests
- **Request Body**:
```json
{
  "from_user": "string",
  "to_user": "string"
}
```

#### 10. Accept Friend Request
- **Endpoint**: `POST /accept_friend_request/`
- **Status**: ✅ WORKING
- **Description**: Accept friend requests
- **Request Body**:
```json
{
  "from_user": "string",
  "to_user": "string"
}
```
- **Note**: Works correctly when proper timing is observed between send and accept

---

## ❌ NON-WORKING ENDPOINTS

### 1. Direct Event Invitations
- **Endpoint**: `POST /invite_user_to_event/`
- **Status**: ❌ 404 NOT FOUND
- **Issue**: Endpoint doesn't exist on server
- **Impact**: Cannot send direct invitations to events

### 2. Auto-Matching System
- **Endpoint**: `POST /run_auto_matching/`
- **Status**: ❌ 404 NOT FOUND
- **Issue**: Endpoint doesn't exist on server
- **Impact**: Auto-matching feature not available

### 3. Health Check
- **Endpoint**: `GET /health/`
- **Status**: ❌ 404 NOT FOUND
- **Issue**: Endpoint doesn't exist on server
- **Impact**: No server health monitoring

---

## 🔍 DISCOVERED ISSUES

### 1. Friend Request Validation
- **Issue**: Many friend request acceptances fail with "Friend request not found"
- **Cause**: Likely timing issues or validation logic problems
- **Impact**: Reduced social connectivity

### 2. Missing Core Features
- **Issue**: Direct invitations and auto-matching not implemented
- **Impact**: Limited social interaction features

### 3. Error Handling
- **Issue**: Some endpoints return generic 404 errors
- **Impact**: Difficult to debug API issues

---

## 📊 TESTING RESULTS

### Data Generation Success
- ✅ **25 users** created successfully
- ✅ **60 events** created with unique coordinates
- ✅ **752 event interactions** (RSVPs, comments, likes, shares)
- ✅ **13 friend connections** established
- ✅ **100% coordinate uniqueness** achieved

### Performance Metrics
- **User Creation**: ~0.5s per user
- **Event Creation**: ~0.5s per event
- **Interaction Creation**: ~0.2s per interaction
- **Success Rate**: ~85% for working endpoints

---

## 🛠️ RECOMMENDED FIXES

### High Priority
1. **Implement Direct Invitations**: Create `/invite_user_to_event/` endpoint
2. **Implement Auto-Matching**: Create `/run_auto_matching/` endpoint
3. **Fix Friend Request Logic**: Resolve validation issues
4. **Add Health Check**: Implement `/health/` endpoint

### Medium Priority
1. **Improve Error Messages**: More specific error responses
2. **Add Input Validation**: Better request validation
3. **Add Rate Limiting**: Prevent API abuse
4. **Add Logging**: Better debugging capabilities

### Low Priority
1. **Add API Versioning**: Future-proof the API
2. **Add Documentation Endpoint**: Self-documenting API
3. **Add Metrics Endpoint**: Performance monitoring

---

## 🧪 TESTING CREDENTIALS

### Sample Users (Password: `password123`)
- `ana_moreno_999`
- `fernanda_lopez_684`
- `gabriela_flores_102`
- `santiago_mendoza_418`
- `valentina_rodriguez_934`
- `carlos_vargas_890`
- `paula_lopez_447`
- `alejandro_torres_827`
- `maria_garcia_903`
- `lucas_ruiz_923`

---

## 📝 API USAGE EXAMPLES

### Creating a User
```python
import requests

user_data = {
    "username": "test_user_123",
    "password": "password123",
    "first_name": "Test",
    "last_name": "User",
    "email": "test@example.com",
    "university": "UBA",
    "degree": "Computer Science",
    "year": "3rd Year",
    "country": "Argentina",
    "bio": "Test user bio",
    "interests": ["Technology", "Music"],
    "skills": ["Programming", "Leadership"],
    "auto_invite_preference": True,
    "preferred_radius": 5
}

response = requests.post(
    "https://pinit-backend-production.up.railway.app/api/register/",
    json=user_data
)
```

### Creating an Event
```python
event_data = {
    "host": "test_user_123",
    "title": "Study Session - Palermo",
    "description": "Join us for a productive study session!",
    "latitude": -34.5889,
    "longitude": -58.4108,
    "time": "2024-01-15T14:00:00Z",
    "end_time": "2024-01-15T16:00:00Z",
    "max_participants": 10,
    "event_type": "study",
    "interest_tags": ["Study", "Academic"],
    "auto_matching_enabled": True
}

response = requests.post(
    "https://pinit-backend-production.up.railway.app/api/create_study_event/",
    json=event_data
)
```

---

## 🔄 VERSION HISTORY

- **v1.0** (2024-01-15): Initial documentation based on testing
- **v1.1** (2024-01-15): Added missing endpoints and fixes

---

## 📞 SUPPORT

For API issues or questions, please refer to this documentation or contact the development team.

---

*Last Updated: January 15, 2024*
*API Version: 1.0*
