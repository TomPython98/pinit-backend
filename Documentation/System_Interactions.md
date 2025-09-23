# StudyCon System Interactions Documentation

## 🔄 System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                StudyCon Ecosystem                                │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐              │
│  │   iOS Frontend  │    │  Django Backend │    │   SQLite DB     │              │
│  │   (SwiftUI)    │◄──►│   (REST API)    │◄──►│   (Database)    │              │
│  │                 │    │                 │    │                 │              │
│  │ • SwiftUI Views │    │ • Django Views  │    │ • User Models   │              │
│  │ • Managers      │    │ • WebSockets    │    │ • Event Models  │              │
│  │ • Models        │    │ • Auto Matching │    │ • Social Models │              │
│  │ • MapKit        │    │ • Push Notifs   │    │ • Rating Models │              │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘              │
│           │                       │                       │                     │
│           │                       │                       │                     │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐              │
│  │   WebSocket     │    │   Redis Cache   │    │   File Storage  │              │
│  │   (Real-time)   │◄──►│   (Sessions)    │    │   (Static)     │              │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘              │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 📱 Frontend-Backend Communication Flow

### 1. Authentication Flow
```
iOS App → Login Request → Django API → User Authentication → Token Response → iOS App
    │                                                                           │
    └── Store Token ───────────────────────────────────────────────────────────┘
```

**Detailed Flow:**
1. **User Input**: User enters username/password in `LoginView`
2. **API Call**: `UserAccountManager.login()` sends POST to `/api/login/`
3. **Backend Processing**: Django authenticates user, generates token
4. **Response**: Token returned to iOS app
5. **Storage**: Token stored in iOS app for future requests
6. **Navigation**: App navigates to `ContentView`

### 2. Event Management Flow
```
iOS App → Fetch Events → Django API → Database Query → Event Data → iOS App
    │                                                                    │
    └── Update UI ───────────────────────────────────────────────────────┘
```

**Detailed Flow:**
1. **Trigger**: User opens calendar or map view
2. **API Call**: `CalendarManager.fetchEvents()` calls `/api/get_study_events/<username>/`
3. **Backend Processing**: Django queries database for user's events
4. **Data Processing**: Events filtered by user relationships (host, attendee, invited)
5. **Response**: JSON array of events returned
6. **Parsing**: iOS app parses JSON into `StudyEvent` models
7. **UI Update**: SwiftUI views automatically update via `@Published` properties

### 3. Real-time Updates Flow
```
iOS App ← WebSocket Connection ← Django Channels ← Database Changes ← User Actions
    │                                                                        │
    └── Update Local State ──────────────────────────────────────────────────┘
```

**Detailed Flow:**
1. **Connection**: iOS app connects to WebSocket endpoint `/ws/events/<username>/`
2. **Backend Setup**: Django Channels establishes WebSocket connection
3. **Event Monitoring**: Backend monitors database changes for user's events
4. **Real-time Updates**: When events change, WebSocket sends updates to iOS app
5. **Local Updates**: iOS app updates local `CalendarManager.events` array
6. **UI Refresh**: SwiftUI views automatically refresh with new data

## 🗄️ Database Interaction Patterns

### 1. User Registration & Profile Creation
```
User Registration → User Model → UserProfile Creation → Database Storage
```

**Database Operations:**
```python
# User creation
user = User.objects.create_user(username=username, password=password)

# Profile creation (via signal)
@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.create(user=instance)
```

### 2. Event Creation & Management
```
Event Creation → StudyEvent Model → Database Storage → WebSocket Broadcast → UI Update
```

**Database Operations:**
```python
# Event creation
event = StudyEvent.objects.create(
    title=title,
    host=user,
    time=time,
    latitude=latitude,
    longitude=longitude
)

# Auto-matching
matched_users = find_matching_users(event)
event.matched_users.set(matched_users)

# WebSocket broadcast
broadcast_event_created(event)
```

### 3. Social Interactions
```
Social Action → Model Creation → Database Storage → API Response → UI Update
```

**Database Operations:**
```python
# Comment creation
comment = EventComment.objects.create(
    event=event,
    user=user,
    content=content
)

# Like toggle
like, created = EventLike.objects.get_or_create(
    event=event,
    user=user
)
if not created:
    like.delete()
```

## 🌐 API Endpoint Interactions

### 1. Event Discovery Flow
```
Map View → Location Request → API Call → Database Query → Filtered Results → Map Pins
```

**API Interaction:**
```swift
// iOS: Map view requests nearby events
func fetchNearbyEvents(latitude: Double, longitude: Double) {
    let url = "\(baseURL)/api/get_study_events/\(username)/"
    // API call with location parameters
}

// Django: Filter events by location and user relationships
def get_study_events(request, username):
    events = StudyEvent.objects.filter(
        end_time__gt=timezone.now()
    ).filter(
        Q(host__username=username) |
        Q(attendees__username=username) |
        Q(invited_friends__username=username) |
        Q(matched_users__username=username)
    )
```

### 2. Smart Matching Flow
```
Event Creation → Auto-Match Trigger → Algorithm Processing → Database Update → Invitation Creation
```

**API Interaction:**
```swift
// iOS: Create event with auto-matching
func createEventWithMatching(eventData: [String: Any]) {
    // Create event
    createEvent(eventData)
    
    // Trigger auto-matching
    triggerAutoMatching(eventId: event.id)
}

// Django: Auto-matching algorithm
def advanced_auto_match(request):
    event = StudyEvent.objects.get(id=event_id)
    matched_users = find_users_by_interests(event.interest_tags)
    matched_users = filter_by_location(matched_users, event)
    matched_users = filter_by_availability(matched_users, event.time)
    
    # Create invitations
    for user in matched_users:
        EventInvitation.objects.create(
            event=event,
            user=user,
            is_auto_matched=True
        )
```

### 3. Social Feed Flow
```
Event Selection → Feed Request → Database Query → Social Data → UI Display
```

**API Interaction:**
```swift
// iOS: Request event social feed
func fetchEventFeed(eventId: UUID) {
    let url = "\(baseURL)/api/events/feed/\(eventId)/"
    // Fetch comments, likes, shares
}

// Django: Aggregate social data
def get_event_feed(request, event_id):
    event = StudyEvent.objects.get(id=event_id)
    comments = EventComment.objects.filter(event=event)
    likes = EventLike.objects.filter(event=event)
    shares = EventShare.objects.filter(event=event)
    
    return JsonResponse({
        'event': event_data,
        'comments': comments_data,
        'likes': likes_data,
        'shares': shares_data
    })
```

## 🔄 Data Synchronization Patterns

### 1. Optimistic Updates
```
User Action → Local State Update → API Call → Success/Error → State Reconciliation
```

**Implementation:**
```swift
// iOS: Optimistic like toggle
func toggleLike(event: StudyEvent) {
    // Update local state immediately
    if event.isLiked {
        event.likes.removeAll { $0.user == currentUser }
    } else {
        event.likes.append(EventLike(user: currentUser))
    }
    
    // Make API call
    apiCall.toggleLike(eventId: event.id) { success in
        if !success {
            // Revert local state on error
            self.revertLikeState(event)
        }
    }
}
```

### 2. Conflict Resolution
```
Concurrent Updates → Conflict Detection → Resolution Strategy → State Update
```

**Implementation:**
```python
# Django: Handle concurrent event updates
def update_event(request, event_id):
    try:
        event = StudyEvent.objects.select_for_update().get(id=event_id)
        # Update event fields
        event.save()
        return JsonResponse({'success': True})
    except StudyEvent.DoesNotExist:
        return JsonResponse({'error': 'Event not found'}, status=404)
```

### 3. Cache Invalidation
```
Data Change → Cache Invalidation → WebSocket Broadcast → Client Cache Update
```

**Implementation:**
```python
# Django: Invalidate cache on event update
def update_event(request, event_id):
    event = StudyEvent.objects.get(id=event_id)
    event.save()
    
    # Invalidate related caches
    cache.delete(f'event_{event_id}')
    cache.delete(f'user_events_{event.host.username}')
    
    # Broadcast update
    broadcast_event_updated(event)
```

## 🎯 State Management Patterns

### 1. Centralized State Management
```
User Actions → Manager Methods → State Updates → UI Refresh
```

**Implementation:**
```swift
// iOS: Centralized event management
class CalendarManager: ObservableObject {
    @Published var events: [StudyEvent] = []
    @Published var isLoading: Bool = false
    
    func addEvent(_ event: StudyEvent) {
        events.append(event)
        // Trigger UI update
    }
    
    func removeEvent(withID id: UUID) {
        events.removeAll { $0.id == id }
        // Trigger UI update
    }
}
```

### 2. Reactive Data Flow
```
Data Source → ObservableObject → @Published Properties → SwiftUI Views
```

**Implementation:**
```swift
// iOS: Reactive data binding
struct EventListView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    
    var body: some View {
        List(calendarManager.events) { event in
            EventRow(event: event)
        }
        .onAppear {
            calendarManager.fetchEvents() // Triggers @Published update
        }
    }
}
```

### 3. Dependency Injection
```
App Launch → Manager Initialization → Environment Object Injection → View Access
```

**Implementation:**
```swift
// iOS: Dependency injection
struct StudyConApp: App {
    @StateObject private var accountManager = UserAccountManager()
    @StateObject private var calendarManager: CalendarManager
    
    init() {
        _calendarManager = StateObject(wrappedValue: CalendarManager(accountManager: accountManager))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(accountManager)
                .environmentObject(calendarManager)
        }
    }
}
```

## 🔔 Real-time Communication Patterns

### 1. WebSocket Connection Management
```
App Launch → WebSocket Connection → Message Handling → State Updates → UI Refresh
```

**Implementation:**
```swift
// iOS: WebSocket management
class WebSocketManager: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    @Published var isConnected: Bool = false
    
    func connect(username: String) {
        let url = URL(string: "ws://localhost:8000/ws/events/\(username)/")!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessage() // Continue listening
            case .failure(let error):
                print("WebSocket error: \(error)")
            }
        }
    }
}
```

### 2. Push Notification Integration
```
Event Update → Push Service → Device Token → iOS Notification → User Action
```

**Implementation:**
```python
# Django: Send push notification
def send_event_notification(event, users):
    for user in users:
        devices = Device.objects.filter(user=user, is_active=True)
        for device in devices:
            send_push_notification(
                device_token=device.device_token,
                title=f"New Event: {event.title}",
                body=event.description,
                data={'event_id': str(event.id)}
            )
```

## 🔍 Error Handling Patterns

### 1. Network Error Handling
```
API Call → Network Error → Retry Logic → Fallback → User Notification
```

**Implementation:**
```swift
// iOS: Network error handling
func makeAPICall<T: Codable>(endpoint: String, responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            // Network error
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(APIError.invalidResponse))
            return
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            // Success
            completion(.success(parsedData))
        case 400...499:
            // Client error
            completion(.failure(APIError.clientError(httpResponse.statusCode)))
        case 500...599:
            // Server error
            completion(.failure(APIError.serverError(httpResponse.statusCode)))
        default:
            completion(.failure(APIError.unknownError))
        }
    }.resume()
}
```

### 2. Data Validation
```
User Input → Client Validation → API Call → Server Validation → Database Storage
```

**Implementation:**
```python
# Django: Server-side validation
def create_study_event(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            
            # Validate required fields
            if not data.get('title'):
                return JsonResponse({'error': 'Title is required'}, status=400)
            
            if not data.get('time'):
                return JsonResponse({'error': 'Time is required'}, status=400)
            
            # Validate time format
            try:
                time = datetime.fromisoformat(data['time'].replace('Z', '+00:00'))
            except ValueError:
                return JsonResponse({'error': 'Invalid time format'}, status=400)
            
            # Create event
            event = StudyEvent.objects.create(
                title=data['title'],
                host=request.user,
                time=time
            )
            
            return JsonResponse({'success': True, 'event_id': str(event.id)})
            
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)
```

## 📊 Performance Optimization Patterns

### 1. Lazy Loading
```
View Load → Minimal Data → User Scroll → Additional Data → Progressive Loading
```

**Implementation:**
```swift
// iOS: Lazy loading for events
struct EventListView: View {
    @State private var loadedEvents: [StudyEvent] = []
    @State private var isLoadingMore = false
    
    var body: some View {
        List(loadedEvents) { event in
            EventRow(event: event)
                .onAppear {
                    if event == loadedEvents.last {
                        loadMoreEvents()
                    }
                }
        }
        .onAppear {
            loadInitialEvents()
        }
    }
    
    func loadMoreEvents() {
        isLoadingMore = true
        // Load next batch of events
        calendarManager.fetchMoreEvents { newEvents in
            loadedEvents.append(contentsOf: newEvents)
            isLoadingMore = false
        }
    }
}
```

### 2. Caching Strategy
```
Data Request → Cache Check → Cache Hit/Miss → API Call → Cache Update → Data Return
```

**Implementation:**
```python
# Django: Redis caching
from django.core.cache import cache

def get_user_events(username):
    cache_key = f'user_events_{username}'
    cached_events = cache.get(cache_key)
    
    if cached_events:
        return cached_events
    
    events = StudyEvent.objects.filter(
        Q(host__username=username) |
        Q(attendees__username=username) |
        Q(invited_friends__username=username)
    ).values()
    
    # Cache for 5 minutes
    cache.set(cache_key, list(events), 300)
    return events
```

---

**Last Updated**: January 2025
**Interaction Version**: 1.0.0

