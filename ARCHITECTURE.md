# PinIt App Architecture Documentation

## Overview
PinIt is a location-based social study event platform with Django backend, Swift iOS frontend, and Android Kotlin frontend. The architecture follows clean separation of concerns with distinct layers for data, business logic, and presentation.

## System Architecture

### Backend (Django)
**Technology Stack:**
- Django 4.x with Django REST Framework
- SQLite database (production-ready for Railway deployment)
- Django Channels for WebSocket support
- Push notifications via django-push-notifications

**Architecture Pattern:** Django MVT (Model-View-Template) with REST API

**Core Components:**
- **Models** (`myapp/models.py`): Data layer with Django ORM
- **Views** (`myapp/views.py`): Business logic and API endpoints
- **URLs** (`StudyCon/urls.py`): API routing configuration
- **Utils** (`myapp/utils.py`): WebSocket broadcasting utilities

**Key Models:**
- `UserProfile`: Extended user data with interests, skills, preferences
- `StudyEvent`: Core event model with location, timing, auto-matching
- `EventInvitation`: Tracks invitations and auto-matching status
- `UserRating`: Reputation system based on Bandura's social learning theory
- `Device`: Push notification device tokens

### iOS Frontend (Swift)
**Technology Stack:**
- SwiftUI for UI framework
- Combine for reactive programming
- Core Location for GPS services
- MapKit for map integration
- URLSession for networking

**Architecture Pattern:** MVVM (Model-View-ViewModel) with Repository pattern

**Layer Structure:**
```
UI Layer (SwiftUI Views)
    ↓
ViewModel Layer (Business Logic)
    ↓
Repository Layer (Data Access)
    ↓
Network Layer (API Calls)
    ↓
Backend API
```

**Key Components:**
- **Models** (`Models/`): Data structures matching backend API
- **ViewModels** (`ViewModels/`): Business logic and state management
- **Managers** (`Managers/`): Service layer (LocationManager, NotificationManager, etc.)
- **Views** (`Views/`): SwiftUI presentation layer
- **Config** (`Config/APIConfig.swift`): API configuration and endpoint management

**Navigation:** SwiftUI NavigationView with programmatic navigation

### Android Frontend (Kotlin)
**Technology Stack:**
- Jetpack Compose for UI framework
- Kotlin Coroutines for async operations
- Retrofit for networking
- Mapbox SDK for maps
- ViewModel + LiveData for state management

**Architecture Pattern:** MVVM with Repository pattern

**Layer Structure:**
```
UI Layer (Compose Views)
    ↓
ViewModel Layer (State Management)
    ↓
Repository Layer (Data Access)
    ↓
Network Layer (Retrofit API)
    ↓
Backend API
```

**Key Components:**
- **Models** (`models/`): Data classes and API models
- **ViewModels** (`viewmodels/`): State management and business logic
- **Repository** (`repository/`): Data access abstraction
- **Network** (`network/`): Retrofit API service definitions
- **Components** (`components/`): Reusable UI components
- **Utils** (`utils/`): Helper utilities and converters

**Navigation:** Compose Navigation with type-safe navigation

## Module Boundaries

### Backend Modules
1. **Authentication Module**: User registration, login, session management
2. **Event Management Module**: CRUD operations for study events
3. **Social Module**: Friends, invitations, chat functionality
4. **Auto-Matching Module**: AI-powered event matching algorithm
5. **Reputation Module**: User rating and trust level system
6. **Notification Module**: Push notifications and WebSocket messaging

### iOS Modules
1. **Core Module**: Base models, managers, and utilities
2. **Map Module**: Location services and map integration
3. **Event Module**: Event creation, viewing, and management
4. **Social Module**: Friends, invitations, and chat
5. **Profile Module**: User profile and preferences
6. **Settings Module**: App configuration and preferences

### Android Modules
1. **Core Module**: Base models, repositories, and utilities
2. **Map Module**: Mapbox integration and location services
3. **Event Module**: Event management and display
4. **Social Module**: Social features and interactions
5. **Profile Module**: User profile management
6. **UI Module**: Reusable components and themes

## Data Flow Architecture

### Request Flow (iOS/Android → Backend)
1. **UI Layer**: User interaction triggers action
2. **ViewModel**: Processes business logic and state updates
3. **Repository**: Formats data and makes API call
4. **Network Layer**: HTTP request to Django backend
5. **Django Views**: Business logic processing
6. **Django Models**: Database operations
7. **Response**: JSON data back through the layers

### Real-time Updates (Backend → Frontend)
1. **Django Utils**: WebSocket broadcasting on data changes
2. **Django Channels**: WebSocket connection management
3. **iOS**: EventsWebSocketManager handles real-time updates
4. **Android**: WebSocket integration (planned)

## Dependency Injection

### iOS
- **Manual DI**: Dependency injection through initializers
- **Singleton Pattern**: Used for managers (LocationManager, NotificationManager)
- **Environment Objects**: SwiftUI environment for shared state

### Android
- **Manual DI**: Constructor injection in ViewModels and Repositories
- **Singleton Pattern**: ApiClient and other services
- **Composition**: Repository pattern for data access abstraction

## Navigation Architecture

### iOS Navigation
- **SwiftUI NavigationView**: Stack-based navigation
- **Programmatic Navigation**: ViewModel-driven navigation
- **Sheet Presentations**: Modal presentations for forms
- **TabView**: Main app navigation structure

### Android Navigation
- **Compose Navigation**: Type-safe navigation with NavController
- **Bottom Navigation**: Main app navigation
- **Modal Sheets**: Bottom sheet presentations
- **Deep Linking**: URL-based navigation support

## State Management

### iOS State Management
- **@State**: Local component state
- **@ObservedObject**: External state management
- **@Published**: Reactive state updates
- **Combine**: Reactive programming for async operations

### Android State Management
- **mutableStateOf**: Compose state management
- **ViewModel**: Business logic and state persistence
- **Flow**: Reactive streams for async operations
- **Coroutines**: Structured concurrency

## Error Handling

### Backend Error Handling
- **HTTP Status Codes**: Standard REST API error responses
- **JSON Error Messages**: Structured error responses
- **Exception Handling**: Try-catch blocks with logging
- **Validation**: Django form validation and model validation

### Frontend Error Handling
- **Result Types**: Swift Result<T, Error> for operations
- **Exception Handling**: Try-catch blocks with user feedback
- **Network Errors**: Specific handling for network failures
- **User Feedback**: Toast messages and error dialogs

## Security Architecture

### Authentication
- **Session-based**: Django sessions for web access
- **Token-based**: API tokens for mobile apps
- **Username/Password**: Simple authentication model

### Authorization
- **Model-level**: Django model permissions
- **View-level**: API endpoint access control
- **User-level**: Profile-based access control

### Data Protection
- **HTTPS**: All API communications encrypted
- **Input Validation**: Server-side validation for all inputs
- **SQL Injection**: Django ORM protection
- **XSS Protection**: Django's built-in XSS protection

## Performance Considerations

### Backend Performance
- **Database Indexing**: Optimized queries with proper indexes
- **Caching**: Django caching framework (planned)
- **Pagination**: API pagination for large datasets
- **Connection Pooling**: Database connection optimization

### Frontend Performance
- **Lazy Loading**: On-demand data loading
- **Image Caching**: Efficient image loading and caching
- **State Optimization**: Minimal state updates
- **Memory Management**: Proper resource cleanup

## Scalability Architecture

### Horizontal Scaling
- **Stateless Backend**: Django app can be scaled horizontally
- **Database**: SQLite can be migrated to PostgreSQL for scaling
- **CDN**: Static file serving through CDN
- **Load Balancing**: Multiple Django instances behind load balancer

### Vertical Scaling
- **Resource Optimization**: Efficient database queries
- **Caching Strategy**: Redis caching for frequently accessed data
- **Background Tasks**: Celery for async task processing
- **Database Optimization**: Query optimization and indexing

## Development Workflow

### Backend Development
1. **Model Changes**: Update Django models
2. **Migration**: Generate and apply database migrations
3. **API Updates**: Modify views and URL patterns
4. **Testing**: Unit tests for business logic
5. **Deployment**: Railway deployment pipeline

### Frontend Development
1. **API Integration**: Update API service definitions
2. **UI Updates**: Modify views and components
3. **State Management**: Update ViewModels and state
4. **Testing**: Unit tests for business logic
5. **Build**: Compile and package for distribution

## Monitoring and Logging

### Backend Monitoring
- **Django Logging**: Comprehensive logging throughout the application
- **Error Tracking**: Exception logging and monitoring
- **Performance Monitoring**: Request timing and database query monitoring
- **Health Checks**: API health check endpoints

### Frontend Monitoring
- **Crash Reporting**: Exception tracking and reporting
- **Analytics**: User behavior and app usage analytics
- **Performance Monitoring**: App performance metrics
- **Network Monitoring**: API call success/failure rates

