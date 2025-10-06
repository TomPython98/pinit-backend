# PinIt App Data Flow Documentation

## Overview
This document describes how data flows through the PinIt application across all layers: UI, ViewModels, Repositories, Network, and Backend. It covers data movement patterns, threading, error handling, and state management.

## Data Flow Architecture

### High-Level Data Flow
```
User Interaction → UI Layer → ViewModel → Repository → Network → Backend API
                ↓
User Interface ← UI Layer ← ViewModel ← Repository ← Network ← Backend API
```

## Backend Data Flow

### Request Processing Flow
1. **HTTP Request** → Django URL routing
2. **View Function** → Business logic processing
3. **Model Operations** → Database queries
4. **Response Generation** → JSON serialization
5. **HTTP Response** → Client response

### Database Operations
```python
# Example: Event Creation Flow
def create_study_event(request):
    # 1. Parse JSON request
    data = json.loads(request.body)
    
    # 2. Validate data
    if not data.get("title"):
        return JsonResponse({"error": "Title required"}, status=400)
    
    # 3. Create model instance
    event = StudyEvent.objects.create(
        title=data["title"],
        host=User.objects.get(username=data["host"]),
        latitude=data["latitude"],
        longitude=data["longitude"],
        time=parse_datetime(data["time"])
    )
    
    # 4. Trigger auto-matching if enabled
    if data.get("auto_matching_enabled"):
        perform_auto_matching(event.id)
    
    # 5. Broadcast real-time update
    broadcast_event_created(event)
    
    # 6. Return response
    return JsonResponse(event.to_dict())
```

### Real-time Data Broadcasting
```python
# WebSocket Broadcasting
def broadcast_event_created(event):
    channel_layer = get_channel_layer()
    async_to_sync(channel_layer.group_send)(
        "events",
        {
            "type": "event_created",
            "event": event.to_dict()
        }
    )
```

## iOS Data Flow

### SwiftUI Data Flow Pattern
```swift
// 1. User Interaction
Button("Create Event") {
    viewModel.createEvent()
}

// 2. ViewModel Processing
class EventCreationViewModel: ObservableObject {
    @Published var events: [StudyEvent] = []
    @Published var isLoading = false
    
    func createEvent() {
        isLoading = true
        repository.createEvent(eventData) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let event):
                    self.events.append(event)
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
}

// 3. Repository Data Access
class EventRepository {
    func createEvent(_ event: StudyEvent, completion: @escaping (Result<StudyEvent, Error>) -> Void) {
        // Network call to backend
        apiService.createEvent(event) { response in
            completion(response)
        }
    }
}
```

### State Management Flow
```swift
// ObservableObject Pattern
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repository = ProfileRepository()
    
    func loadProfile() {
        isLoading = true
        repository.getProfile { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let profile):
                    self?.profile = profile
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
```

### Real-time Updates (WebSocket)
```swift
class EventsWebSocketManager: ObservableObject {
    @Published var events: [StudyEvent] = []
    private var webSocketTask: URLSessionWebSocketTask?
    
    func connect() {
        let url = URL(string: "wss://api.pin-it.net/ws/events/")!
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

## Android Data Flow

### Compose Data Flow Pattern
```kotlin
// 1. User Interaction
@Composable
fun EventCreationScreen(viewModel: EventCreationViewModel) {
    Button(onClick = { viewModel.createEvent() }) {
        Text("Create Event")
    }
}

// 2. ViewModel Processing
class EventCreationViewModel : ViewModel() {
    private val repository = EventRepository()
    
    val events = mutableStateOf<List<StudyEventMap>>(emptyList())
    val isLoading = mutableStateOf(false)
    val errorMessage = mutableStateOf<String?>(null)
    
    fun createEvent() {
        viewModelScope.launch {
            isLoading.value = true
            try {
                repository.createEvent(eventData).collect { result ->
                    result.fold(
                        onSuccess = { event ->
                            events.value = events.value + event
                            isLoading.value = false
                        },
                        onFailure = { error ->
                            errorMessage.value = error.message
                            isLoading.value = false
                        }
                    )
                }
            }
        }
    }
}
```

### Repository Pattern with Flow
```kotlin
class EventRepository {
    fun getEventsForUser(username: String): Flow<Result<List<StudyEventMap>>> = flow {
        try {
            val response = apiService.getStudyEvents(username)
            if (response.isSuccessful) {
                val events = response.body()?.events?.map { it.toStudyEventMap() } ?: emptyList()
                emit(Result.success(events))
            } else {
                emit(Result.failure(Exception("API Error: ${response.code()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }.flowOn(Dispatchers.IO)
}
```

### State Management with Compose
```kotlin
@Composable
fun ProfileScreen(viewModel: ProfileViewModel) {
    val profile by viewModel.profile.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    
    LaunchedEffect(Unit) {
        viewModel.loadProfile()
    }
    
    when {
        isLoading -> LoadingScreen()
        profile != null -> ProfileContent(profile!!)
        else -> ErrorScreen()
    }
}
```

## Threading and Concurrency

### Backend Threading
- **Django**: Single-threaded request handling
- **Database**: Connection pooling for concurrent requests
- **WebSocket**: Async handling via Django Channels
- **Background Tasks**: Synchronous processing (Celery planned)

### iOS Threading
```swift
// Main Thread for UI Updates
DispatchQueue.main.async {
    self.isLoading = false
    self.events = newEvents
}

// Background Thread for Network Calls
URLSession.shared.dataTask(with: request) { data, response, error in
    // Process on background thread
    let events = parseEvents(data)
    
    // Update UI on main thread
    DispatchQueue.main.async {
        self.events = events
    }
}.resume()

// Combine for Reactive Programming
func loadEvents() -> AnyPublisher<[StudyEvent], Error> {
    return apiService.getEvents()
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
}
```

### Android Threading
```kotlin
// Coroutines for Async Operations
viewModelScope.launch {
    try {
        val events = repository.getEvents()
        // Update state on main thread
        _events.value = events
    } catch (e: Exception) {
        _errorMessage.value = e.message
    }
}

// Flow with Dispatchers
fun getEvents(): Flow<List<StudyEvent>> = flow {
    val events = apiService.getEvents()
    emit(events)
}.flowOn(Dispatchers.IO) // Background thread
 .flowOn(Dispatchers.Main) // Main thread for collection
```

## Error Handling Patterns

### Backend Error Handling
```python
@csrf_exempt
def create_study_event(request):
    try:
        data = json.loads(request.body)
        
        # Validation
        if not data.get("title"):
            return JsonResponse({
                "success": False,
                "message": "Title is required"
            }, status=400)
        
        # Business logic
        event = StudyEvent.objects.create(**data)
        
        return JsonResponse({
            "success": True,
            "event": event.to_dict()
        })
        
    except json.JSONDecodeError:
        return JsonResponse({
            "success": False,
            "message": "Invalid JSON data"
        }, status=400)
        
    except Exception as e:
        return JsonResponse({
            "success": False,
            "message": f"Server error: {str(e)}"
        }, status=500)
```

### iOS Error Handling
```swift
// Result-based Error Handling
func createEvent(_ event: StudyEvent) -> AnyPublisher<StudyEvent, Error> {
    return apiService.createEvent(event)
        .map { response in
            if response.success {
                return response.event
            } else {
                throw APIError.serverError(response.message)
            }
        }
        .catch { error in
            // Handle specific error types
            if error is URLError {
                return Fail(error: APIError.networkError)
            } else {
                return Fail(error: error)
            }
        }
        .eraseToAnyPublisher()
}

// Error Handling in ViewModel
class EventCreationViewModel: ObservableObject {
    @Published var errorMessage: String?
    
    func createEvent() {
        repository.createEvent(event)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { event in
                    self.events.append(event)
                }
            )
            .store(in: &cancellables)
    }
}
```

### Android Error Handling
```kotlin
// Result-based Error Handling
fun createEvent(event: StudyEventMap): Flow<Result<StudyEventMap>> = flow {
    try {
        val response = apiService.createEvent(event)
        if (response.isSuccessful) {
            val createdEvent = response.body()?.toStudyEventMap()
            emit(Result.success(createdEvent ?: event))
        } else {
            emit(Result.failure(Exception("API Error: ${response.code()}")))
        }
    } catch (e: Exception) {
        emit(Result.failure(e))
    }
}

// Error Handling in ViewModel
class EventCreationViewModel : ViewModel() {
    val errorMessage = mutableStateOf<String?>(null)
    
    fun createEvent() {
        viewModelScope.launch {
            repository.createEvent(event).collect { result ->
                result.fold(
                    onSuccess = { event ->
                        events.value = events.value + event
                    },
                    onFailure = { error ->
                        errorMessage.value = error.message
                    }
                )
            }
        }
    }
}
```

## State Management Patterns

### iOS State Management
```swift
// ObservableObject Pattern
class EventListViewModel: ObservableObject {
    @Published var events: [StudyEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadEvents() {
        isLoading = true
        errorMessage = nil
        
        repository.getEvents()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] events in
                    self?.events = events
                }
            )
            .store(in: &cancellables)
    }
}
```

### Android State Management
```kotlin
// State Management with Compose
class EventListViewModel : ViewModel() {
    private val _events = mutableStateOf<List<StudyEventMap>>(emptyList())
    val events: State<List<StudyEventMap>> = _events
    
    private val _isLoading = mutableStateOf(false)
    val isLoading: State<Boolean> = _isLoading
    
    private val _errorMessage = mutableStateOf<String?>(null)
    val errorMessage: State<String?> = _errorMessage
    
    fun loadEvents() {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            
            repository.getEvents().collect { result ->
                _isLoading.value = false
                result.fold(
                    onSuccess = { events ->
                        _events.value = events
                    },
                    onFailure = { error ->
                        _errorMessage.value = error.message
                    }
                )
            }
        }
    }
}
```

## Data Caching Strategies

### Backend Caching
```python
# Django Caching (planned)
from django.core.cache import cache

def get_events_for_user(username):
    cache_key = f"events_{username}"
    events = cache.get(cache_key)
    
    if events is None:
        events = StudyEvent.objects.filter(
            Q(host__username=username) |
            Q(invited_friends__username=username) |
            Q(attendees__username=username)
        ).distinct()
        cache.set(cache_key, events, 300)  # 5 minutes
    
    return events
```

### iOS Caching
```swift
// Simple In-Memory Caching
class EventCache {
    private var cache: [String: [StudyEvent]] = [:]
    private let cacheExpiry: TimeInterval = 300 // 5 minutes
    private var cacheTimestamps: [String: Date] = [:]
    
    func getEvents(for username: String) -> [StudyEvent]? {
        guard let timestamp = cacheTimestamps[username],
              Date().timeIntervalSince(timestamp) < cacheExpiry else {
            return nil
        }
        return cache[username]
    }
    
    func setEvents(_ events: [StudyEvent], for username: String) {
        cache[username] = events
        cacheTimestamps[username] = Date()
    }
}
```

### Android Caching
```kotlin
// Repository-level Caching
class EventRepository {
    private val cache = mutableMapOf<String, List<StudyEventMap>>()
    private val cacheTimestamps = mutableMapOf<String, Long>()
    private val cacheExpiry = 300_000L // 5 minutes
    
    fun getEventsForUser(username: String): Flow<Result<List<StudyEventMap>>> = flow {
        // Check cache first
        val cachedEvents = getCachedEvents(username)
        if (cachedEvents != null) {
            emit(Result.success(cachedEvents))
            return@flow
        }
        
        // Fetch from API
        try {
            val response = apiService.getStudyEvents(username)
            if (response.isSuccessful) {
                val events = response.body()?.events?.map { it.toStudyEventMap() } ?: emptyList()
                cacheEvents(username, events)
                emit(Result.success(events))
            } else {
                emit(Result.failure(Exception("API Error: ${response.code()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    private fun getCachedEvents(username: String): List<StudyEventMap>? {
        val timestamp = cacheTimestamps[username] ?: return null
        if (System.currentTimeMillis() - timestamp > cacheExpiry) {
            cache.remove(username)
            cacheTimestamps.remove(username)
            return null
        }
        return cache[username]
    }
}
```

## Real-time Data Synchronization

### WebSocket Data Flow
```python
# Backend WebSocket Broadcasting
def broadcast_event_created(event):
    channel_layer = get_channel_layer()
    async_to_sync(channel_layer.group_send)(
        "events",
        {
            "type": "event_created",
            "event": event.to_dict()
        }
    )

def broadcast_event_updated(event):
    channel_layer = get_channel_layer()
    async_to_sync(channel_layer.group_send)(
        "events",
        {
            "type": "event_updated",
            "event": event.to_dict()
        }
    )
```

### iOS Real-time Updates
```swift
class RealTimeEventManager: ObservableObject {
    @Published var events: [StudyEvent] = []
    private var webSocketTask: URLSessionWebSocketTask?
    
    func connect() {
        let url = URL(string: "wss://api.pin-it.net/ws/events/")!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessage()
            case .failure(let error):
                print("WebSocket error: \(error)")
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            if let data = text.data(using: .utf8),
               let eventData = try? JSONDecoder().decode(EventMessage.self, from: data) {
                DispatchQueue.main.async {
                    self.updateEvents(with: eventData)
                }
            }
        case .data(let data):
            // Handle binary data if needed
            break
        @unknown default:
            break
        }
    }
}
```

## Data Validation and Sanitization

### Backend Validation
```python
def validate_event_data(data):
    errors = []
    
    # Required fields
    if not data.get("title"):
        errors.append("Title is required")
    
    if not data.get("latitude") or not data.get("longitude"):
        errors.append("Location coordinates are required")
    
    # Data type validation
    try:
        float(data.get("latitude", 0))
        float(data.get("longitude", 0))
    except (ValueError, TypeError):
        errors.append("Invalid coordinate format")
    
    # Business logic validation
    if data.get("max_participants", 0) > 100:
        errors.append("Maximum participants cannot exceed 100")
    
    return errors
```

### Frontend Validation
```swift
// iOS Validation
struct EventValidator {
    static func validate(_ event: StudyEvent) -> [String] {
        var errors: [String] = []
        
        if event.title.isEmpty {
            errors.append("Title is required")
        }
        
        if event.coordinate.latitude == 0 && event.coordinate.longitude == 0 {
            errors.append("Location is required")
        }
        
        if event.time < Date() {
            errors.append("Event time must be in the future")
        }
        
        return errors
    }
}
```

```kotlin
// Android Validation
object EventValidator {
    fun validate(event: StudyEventMap): List<String> {
        val errors = mutableListOf<String>()
        
        if (event.title.isBlank()) {
            errors.add("Title is required")
        }
        
        if (event.coordinate == null) {
            errors.add("Location is required")
        }
        
        if (event.time.isBefore(LocalDateTime.now())) {
            errors.add("Event time must be in the future")
        }
        
        return errors
    }
}
```

## Performance Optimization

### Data Loading Optimization
- **Pagination**: Load events in batches
- **Lazy Loading**: Load data on demand
- **Prefetching**: Preload likely-needed data
- **Caching**: Cache frequently accessed data
- **Compression**: Compress API responses

### Memory Management
- **Weak References**: Prevent retain cycles
- **Resource Cleanup**: Proper disposal of resources
- **Image Caching**: Efficient image loading
- **State Cleanup**: Clear unused state

This data flow documentation provides a comprehensive understanding of how data moves through the PinIt application, ensuring consistent patterns and efficient data handling across all platforms.

