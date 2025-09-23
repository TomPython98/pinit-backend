# StudyCon - Comprehensive Documentation

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Backend Documentation](#backend-documentation)
4. [Frontend Documentation](#frontend-documentation)
5. [Database Schema](#database-schema)
6. [API Documentation](#api-documentation)
7. [Virtual Environment Setup](#virtual-environment-setup)
8. [Deployment Guide](#deployment-guide)
9. [Development Workflow](#development-workflow)
10. [Troubleshooting](#troubleshooting)

## 🎯 Project Overview

**StudyCon** is a comprehensive social networking platform designed for international students to connect, organize study groups, and participate in cultural exchange events. The application combines real-time communication, event management, and intelligent matching algorithms to create meaningful connections within academic communities.

### Key Features
- **Event Management**: Create, join, and manage study groups and social events
- **Smart Matching**: AI-powered algorithm to suggest relevant events and connections
- **Real-time Communication**: WebSocket-based chat and live updates
- **Social Features**: Friend requests, ratings, reputation system
- **Geographic Integration**: Map-based event discovery with clustering
- **Cross-platform**: iOS native app with Django REST API backend

## 🏗️ Architecture

### System Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   iOS Frontend  │    │  Django Backend │    │   SQLite DB     │
│   (SwiftUI)     │◄──►│   (REST API)    │◄──►│   (Database)    │
│                 │    │                 │    │                 │
│ • SwiftUI Views │    │ • Django Views  │    │ • User Models   │
│ • Managers      │    │ • WebSockets    │    │ • Event Models  │
│ • Models        │    │ • Auto Matching │    │ • Social Models │
│ • MapKit        │    │ • Push Notifs   │    │ • Rating Models │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Technology Stack
- **Backend**: Django 5.1.6, Django REST Framework, Django Channels
- **Frontend**: SwiftUI, iOS 17+, MapKit, MapboxMaps
- **Database**: SQLite3 (development), PostgreSQL (production ready)
- **Real-time**: WebSockets via Django Channels
- **Authentication**: Django Token Authentication
- **Push Notifications**: Django Push Notifications
- **Maps**: MapboxMaps SDK for iOS

## 🔧 Backend Documentation

### Project Structure
```
Back_End/StudyCon/
├── StudyCon/                 # Django project settings
│   ├── settings.py          # Main configuration
│   ├── urls.py              # URL routing
│   ├── asgi.py              # ASGI configuration for WebSockets
│   └── wsgi.py              # WSGI configuration
├── myapp/                   # Main Django application
│   ├── models.py            # Database models
│   ├── views.py             # API endpoints and business logic
│   ├── urls.py              # App-specific URL patterns
│   ├── consumers.py         # WebSocket consumers
│   ├── routing.py           # WebSocket routing
│   └── migrations/          # Database migrations
├── requirements.txt         # Python dependencies
├── manage.py               # Django management script
└── db.sqlite3             # SQLite database
```

### Key Dependencies
- **Django 5.1.6**: Web framework
- **daphne 4.0.0**: ASGI server for WebSockets
- **channels 4.0.0**: WebSocket support
- **djangorestframework 3.15.2**: REST API framework
- **django-cors-headers 4.3.1**: CORS support for frontend
- **django-push-notifications 3.0.0**: Push notification support

### Configuration Files
- **settings.py**: Database, CORS, WebSocket, and app configuration
- **requirements.txt**: Python package dependencies
- **SERVER_SETUP.md**: Server setup instructions

## 📱 Frontend Documentation

### Project Structure
```
Front_End/Fibbling_BackUp/Fibbling/
├── Views/                   # SwiftUI Views
│   ├── StudyConApp.swift   # Main app entry point
│   ├── ContentView.swift   # Main content view
│   ├── CalendarView.swift  # Calendar and events
│   ├── MapBox.swift        # Map view with clustering
│   ├── LoginView.swift     # Authentication
│   └── [50+ other views]   # Various UI components
├── Models/                  # Data models
│   ├── StudyEvent.swift    # Event model
│   ├── UserRating.swift    # Rating and reputation
│   ├── University.swift    # University data
│   └── MessageModel.swift  # Chat messages
├── Managers/               # Business logic managers
│   ├── UserAccountManager.swift    # User authentication
│   ├── CalendarManager.swift       # Event management
│   ├── UserReputationManager.swift # Rating system
│   └── [4 other managers]          # Various managers
├── ViewModels/             # MVVM view models
├── Extensions/             # Swift extensions
└── Assets.xcassets/        # App assets and icons
```

### Key Components
- **StudyConApp**: Main app entry point with environment object injection
- **ContentView**: Central hub with navigation and user reputation
- **CalendarManager**: Handles event fetching, filtering, and WebSocket updates
- **MapBox**: Interactive map with event clustering and filtering
- **UserAccountManager**: Authentication and user session management

### Architecture Patterns
- **MVVM**: Model-View-ViewModel pattern for data binding
- **Environment Objects**: Dependency injection for managers
- **ObservableObject**: Reactive data updates
- **Combine**: Reactive programming for API calls

## 🗄️ Database Schema

### Core Models

#### UserProfile
```python
class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    is_certified = models.BooleanField(default=False)
    friends = models.ManyToManyField("self", blank=True, symmetrical=True)
    
    # Profile information
    full_name = models.CharField(max_length=255, blank=True)
    university = models.CharField(max_length=255, blank=True)
    degree = models.CharField(max_length=255, blank=True)
    year = models.CharField(max_length=50, blank=True)
    bio = models.TextField(blank=True)
    
    # Smart matching
    interests = models.JSONField(default=list, blank=True)
    skills = models.JSONField(default=dict, blank=True)
    auto_invite_enabled = models.BooleanField(default=True)
    preferred_radius = models.FloatField(default=10.0)
```

#### StudyEvent
```python
class StudyEvent(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    host = models.ForeignKey(User, on_delete=models.CASCADE)
    time = models.DateTimeField()
    end_time = models.DateTimeField()
    latitude = models.FloatField()
    longitude = models.FloatField()
    is_public = models.BooleanField(default=True)
    event_type = models.CharField(max_length=50, choices=EVENT_TYPE_CHOICES)
    attendees = models.ManyToManyField(User, related_name='attended_events', blank=True)
    invited_friends = models.ManyToManyField(User, related_name='invited_events', blank=True)
    matched_users = models.ManyToManyField(User, related_name='matched_events', blank=True)
    interest_tags = models.JSONField(default=list, blank=True)
```

#### Social Models
```python
class EventComment(models.Model):
    event = models.ForeignKey(StudyEvent, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

class EventLike(models.Model):
    event = models.ForeignKey(StudyEvent, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)

class UserRating(models.Model):
    from_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ratings_given')
    to_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ratings_received')
    event = models.ForeignKey(StudyEvent, on_delete=models.CASCADE, null=True, blank=True)
    rating = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    reference = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
```

## 🌐 API Documentation

### Authentication Endpoints
- `POST /api/register/` - User registration
- `POST /api/login/` - User login
- `POST /api/logout/` - User logout

### Event Management
- `GET /api/get_study_events/<username>/` - Get user's events
- `POST /api/create_study_event/` - Create new event
- `POST /api/rsvp_study_event/` - RSVP to event
- `POST /api/delete_study_event/` - Delete event

### Social Features
- `GET /api/get_friends/<username>/` - Get user's friends
- `POST /api/send_friend_request/` - Send friend request
- `POST /api/accept_friend_request/` - Accept friend request
- `GET /api/get_invitations/<username>/` - Get user's invitations

### Event Interactions
- `POST /api/events/comment/` - Add event comment
- `POST /api/events/like/` - Toggle event like
- `POST /api/events/share/` - Record event share
- `GET /api/events/feed/<event_id>/` - Get event social feed

### User Reputation
- `POST /api/submit_user_rating/` - Submit user rating
- `GET /api/get_user_reputation/<username>/` - Get user reputation
- `GET /api/get_user_ratings/<username>/` - Get user ratings

### Smart Matching
- `POST /api/advanced_auto_match/` - Trigger auto-matching
- `GET /api/get_auto_matched_users/<event_id>/` - Get matched users

### WebSocket Endpoints
- `ws://localhost:8000/ws/events/<username>/` - Real-time event updates

## 🐍 Virtual Environment Setup

### Prerequisites
- Python 3.13+
- pip package manager

### Setup Instructions
```bash
# Navigate to backend directory
cd /Users/tombesinger/Desktop/Real_App/Back_End/StudyCon

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run database migrations
python manage.py migrate

# Create superuser (optional)
python manage.py createsuperuser

# Start development server
python manage.py runserver 0.0.0.0:8000
```

### Environment Variables
- `DEBUG=True` - Development mode
- `SECRET_KEY` - Django secret key
- `ALLOWED_HOSTS` - Allowed host addresses
- `CORS_ALLOW_ALL_ORIGINS=True` - CORS configuration

## 🚀 Deployment Guide

### Production Checklist
1. **Security**: Set `DEBUG=False`, use secure secret key
2. **Database**: Migrate to PostgreSQL for production
3. **CORS**: Configure specific allowed origins
4. **WebSockets**: Use Redis for channel layers
5. **Static Files**: Configure static file serving
6. **SSL**: Enable HTTPS for production

### Server Configuration
```python
# Production settings example
DEBUG = False
ALLOWED_HOSTS = ['yourdomain.com']
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'studycon_prod',
        'USER': 'your_db_user',
        'PASSWORD': 'your_db_password',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
```

## 🔄 Development Workflow

### Backend Development
1. **Feature Development**: Create new models, views, URLs
2. **Database Changes**: Create and run migrations
3. **API Testing**: Use Django admin or API testing tools
4. **WebSocket Testing**: Test real-time features

### Frontend Development
1. **UI Components**: Create SwiftUI views
2. **Data Models**: Update Swift models to match API
3. **Managers**: Implement business logic
4. **Testing**: Test on iOS Simulator or device

### Integration Testing
1. **API Integration**: Test frontend-backend communication
2. **Real-time Features**: Test WebSocket connections
3. **Cross-platform**: Test on different iOS versions
4. **Performance**: Monitor API response times

## 🐛 Troubleshooting

### Common Issues

#### Backend Issues
- **Import Errors**: Check virtual environment activation
- **Database Errors**: Run migrations with `python manage.py migrate`
- **CORS Errors**: Verify CORS settings in settings.py
- **WebSocket Issues**: Check channel layers configuration

#### Frontend Issues
- **API Connection**: Verify backend server is running
- **Model Parsing**: Check JSON structure matches Swift models
- **Map Issues**: Verify Mapbox API key configuration
- **Build Errors**: Check Xcode project settings

#### Database Issues
- **Migration Errors**: Reset database and run migrations
- **Data Inconsistency**: Use Django admin to verify data
- **Performance**: Add database indexes for large datasets

### Debug Tools
- **Django Debug Toolbar**: For backend debugging
- **Xcode Debugger**: For frontend debugging
- **WebSocket Inspector**: For real-time debugging
- **Network Inspector**: For API call debugging

## 📞 Support

For technical support or questions:
1. Check this documentation first
2. Review error logs in Django console
3. Check Xcode console for iOS errors
4. Verify network connectivity and API endpoints

---

**Last Updated**: January 2025
**Version**: 1.0.0
**Maintainer**: Development Team

