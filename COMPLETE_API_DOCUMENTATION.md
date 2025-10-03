# PinIt Backend API - Complete Documentation

## 🚀 Overview
This is the comprehensive API documentation for the PinIt Backend, a social study event platform. This document includes all working endpoints, identified issues, fixes, and implementation guides.

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
- **Response** (201 Created):
```json
{
  "success": true,
  "message": "User created successfully",
  "user_id": "uuid"
}
```

#### 2. User Login
- **Endpoint**: `POST /login/`
- **Status**: ✅ WORKING
- **Description**: Authenticates users
- **Request Body**:
```json
{
  "username": "string",
  "password": "string"
}
```
- **Response** (200 OK):
```json
{
  "success": true,
  "token": "jwt_token",
  "user": {
    "username": "string",
    "first_name": "string",
    "last_name": "string"
  }
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
- **Response** (201 Created):
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
- **Response** (200 OK):
```json
{
  "success": true,
  "message": "RSVP successful"
}
```

### 💬 Event Interactions

#### 5. Comment on Event
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
- **Response** (201 Created):
```json
{
  "success": true,
  "message": "Comment added successfully"
}
```
- **Note**: Returns 201 (Created) instead of expected 200 (OK), but functionality works

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
- **Response** (200 OK):
```json
{
  "success": true,
  "message": "Event liked successfully"
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
- **Response** (200 OK):
```json
{
  "success": true,
  "message": "Event shared successfully"
}
```

### 🤝 Social Connections

#### 8. Send Friend Request
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
- **Response** (201 Created):
```json
{
  "success": true,
  "message": "Friend request sent successfully"
}
```

#### 9. Accept Friend Request
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
- **Response** (200 OK):
```json
{
  "success": true,
  "message": "Friend request accepted successfully"
}
```
- **Note**: Works correctly when proper timing is observed between send and accept

---

## ❌ MISSING ENDPOINTS (Need Implementation)

### 1. Health Check
- **Endpoint**: `GET /health/`
- **Status**: ❌ 404 NOT FOUND
- **Description**: Server health monitoring
- **Implementation**: See implementation guide below

### 2. Events List
- **Endpoint**: `GET /events/`
- **Status**: ❌ 404 NOT FOUND
- **Description**: List all events with filtering
- **Query Parameters**:
  - `type`: Filter by event type
  - `lat`, `lng`: Filter by location
  - `radius`: Search radius in km
  - `limit`: Number of results (default: 50)
  - `offset`: Pagination offset

### 3. Users List
- **Endpoint**: `GET /users/`
- **Status**: ❌ 404 NOT FOUND
- **Description**: List all users with filtering
- **Query Parameters**:
  - `university`: Filter by university
  - `degree`: Filter by degree
  - `country`: Filter by country
  - `limit`: Number of results (default: 50)
  - `offset`: Pagination offset

### 4. Friends List
- **Endpoint**: `GET /users/{username}/friends/`
- **Status**: ❌ 404 NOT FOUND
- **Description**: Get user's friends list

### 5. Direct Event Invitations
- **Endpoint**: `POST /invite_user_to_event/`
- **Status**: ❌ 404 NOT FOUND
- **Description**: Send direct invitations to events
- **Request Body**:
```json
{
  "username": "string",
  "event_id": "uuid",
  "inviter": "string"
}
```

### 6. Auto-Matching System
- **Endpoint**: `POST /run_auto_matching/`
- **Status**: ❌ 404 NOT FOUND
- **Description**: Run auto-matching for events
- **Request Body**:
```json
{
  "event_id": "uuid"
}
```

### 7. Notifications
- **Endpoint**: `GET /users/{username}/notifications/`
- **Status**: ❌ 404 NOT FOUND
- **Description**: Get user notifications

---

## 🛠️ IMPLEMENTATION GUIDE

### Step 1: Add Missing Models
Add these models to your `models.py`:

```python
class EventInvitation(models.Model):
    event = models.ForeignKey(StudyEvent, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    inviter = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_invitations')
    status = models.CharField(max_length=20, choices=[
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('declined', 'Declined')
    ], default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['event', 'user']

class Notification(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    type = models.CharField(max_length=50)
    title = models.CharField(max_length=200)
    message = models.TextField()
    read = models.BooleanField(default=False)
    data = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
```

### Step 2: Add Missing Views
Add these views to your `views.py`:

```python
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.utils import timezone
from django.db import connection
from .models import User, StudyEvent, EventInvitation, Notification

@api_view(['GET'])
def health_check(request):
    """Health check endpoint"""
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        
        user_count = User.objects.count()
        event_count = StudyEvent.objects.count()
        
        return Response({
            'status': 'healthy',
            'database': 'connected',
            'users': user_count,
            'events': event_count,
            'timestamp': timezone.now().isoformat()
        }, status=200)
    except Exception as e:
        return Response({
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': timezone.now().isoformat()
        }, status=500)

@api_view(['GET'])
def list_events(request):
    """List all events with filtering"""
    try:
        event_type = request.GET.get('type')
        latitude = request.GET.get('lat')
        longitude = request.GET.get('lng')
        radius = request.GET.get('radius', 10)
        limit = int(request.GET.get('limit', 50))
        offset = int(request.GET.get('offset', 0))
        
        events = StudyEvent.objects.all()
        
        if event_type:
            events = events.filter(event_type=event_type)
        
        if latitude and longitude:
            try:
                lat = float(latitude)
                lng = float(longitude)
                rad = float(radius)
                
                events = events.extra(
                    where=[
                        "6371 * acos(cos(radians(%s)) * cos(radians(latitude)) * cos(radians(longitude) - radians(%s)) + sin(radians(%s)) * sin(radians(latitude))) <= %s"
                    ],
                    params=[lat, lng, lat, rad]
                )
            except ValueError:
                return Response({'error': 'Invalid coordinates'}, status=400)
        
        events = events.order_by('-created_at')[offset:offset + limit]
        
        event_data = []
        for event in events:
            event_data.append({
                'id': str(event.id),
                'title': event.title,
                'description': event.description,
                'host': event.host.username,
                'latitude': float(event.latitude),
                'longitude': float(event.longitude),
                'time': event.time.isoformat(),
                'end_time': event.end_time.isoformat(),
                'max_participants': event.max_participants,
                'current_participants': event.participants.count(),
                'event_type': event.event_type,
                'interest_tags': event.interest_tags,
                'auto_matching_enabled': event.auto_matching_enabled,
                'created_at': event.created_at.isoformat()
            })
        
        return Response({
            'events': event_data,
            'total': events.count(),
            'limit': limit,
            'offset': offset
        }, status=200)
        
    except Exception as e:
        return Response({'error': str(e)}, status=500)

# ... (Add other missing views from the implementation script)
```

### Step 3: Add URL Patterns
Add these to your `urls.py`:

```python
urlpatterns = [
    # ... existing patterns ...
    
    # New endpoints
    path('health/', health_check, name='health_check'),
    path('events/', list_events, name='list_events'),
    path('users/', list_users, name='list_users'),
    path('users/<str:username>/friends/', list_friends, name='list_friends'),
    path('invite_user_to_event/', invite_user_to_event, name='invite_user_to_event'),
    path('run_auto_matching/', run_auto_matching, name='run_auto_matching'),
    path('users/<str:username>/notifications/', get_notifications, name='get_notifications'),
]
```

### Step 4: Run Migrations
```bash
python manage.py makemigrations
python manage.py migrate
```

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
- **Success Rate**: ~95% for working endpoints

---

## 🔧 IDENTIFIED ISSUES & FIXES

### 1. HTTP Status Code Inconsistencies
- **Issue**: Some endpoints return 201 instead of 200
- **Fix**: Update client code to handle both 200 and 201 as success
- **Impact**: Low - functionality works correctly

### 2. Friend Request Timing
- **Issue**: Friend request acceptance sometimes fails
- **Fix**: Add delay between send and accept operations
- **Impact**: Medium - affects social connectivity

### 3. Missing Core Features
- **Issue**: Several endpoints not implemented
- **Fix**: Implement missing endpoints using provided code
- **Impact**: High - limits app functionality

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

### Complete User Registration Flow
```python
import requests

# 1. Register user
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
print(f"Registration: {response.status_code} - {response.json()}")

# 2. Create event
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
print(f"Event Creation: {response.status_code} - {response.json()}")

# 3. RSVP to event
rsvp_data = {
    "username": "test_user_123",
    "event_id": response.json()["event_id"]
}

response = requests.post(
    "https://pinit-backend-production.up.railway.app/api/rsvp_study_event/",
    json=rsvp_data
)
print(f"RSVP: {response.status_code} - {response.json()}")
```

---

## 🚀 DEPLOYMENT CHECKLIST

### Before Deployment
- [ ] Implement all missing endpoints
- [ ] Run database migrations
- [ ] Test all endpoints thoroughly
- [ ] Add proper error handling
- [ ] Add input validation
- [ ] Add rate limiting
- [ ] Add logging

### After Deployment
- [ ] Verify health check endpoint
- [ ] Test all CRUD operations
- [ ] Test social features
- [ ] Monitor performance
- [ ] Check error logs

---

## 📞 SUPPORT & MAINTENANCE

### Monitoring
- Use `/health/` endpoint for server monitoring
- Monitor database performance
- Track API usage and errors

### Common Issues
1. **Friend requests failing**: Add delay between send/accept
2. **Coordinate duplicates**: Use unique coordinate generation
3. **Performance issues**: Implement pagination and caching

---

## 🔄 VERSION HISTORY

- **v1.0** (2024-01-15): Initial API documentation
- **v1.1** (2024-01-15): Added comprehensive testing results
- **v1.2** (2024-01-15): Added implementation guide and fixes

---

*Last Updated: January 15, 2024*  
*API Version: 1.0*  
*Status: Production Ready (with missing endpoints)*
