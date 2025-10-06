# Android Data Flow

## Data Flow Architecture

### 1. Network → Cache → UI Flow

```
Backend API → Repository → ViewModel → UI State → Compose UI
     ↑              ↓           ↓         ↓
     ← Error Handling ← Flow<T> ← State Updates ← User Actions
```

### 2. Detailed Data Flow

#### Event Data Flow
```kotlin
// 1. UI triggers data request
LaunchedEffect(Unit) {
    eventRepository.getEventsForUser(username)
        .collect { result ->
            when {
                result.isSuccess -> events.value = result.getOrNull() ?: emptyList()
                result.isFailure -> errorMessage.value = result.exceptionOrNull()?.message
            }
        }
}

// 2. Repository makes API call
fun getEventsForUser(username: String): Flow<Result<List<StudyEventMap>>> = flow {
    try {
        val response = apiService.getStudyEvents(username)
        if (response.isSuccessful) {
            val events = response.body()?.events?.map { it.toStudyEventMap() }
            emit(Result.success(events ?: emptyList()))
        } else {
            emit(Result.failure(Exception("API Error: ${response.code()}")))
        }
    } catch (e: Exception) {
        emit(Result.failure(e))
    }
}.flowOn(Dispatchers.IO)

// 3. ViewModel updates state
val events = mutableStateOf<List<StudyEventMap>>(emptyList())
val isLoading = mutableStateOf(false)
val errorMessage = mutableStateOf<String?>(null)
```

#### User Profile Data Flow
```kotlin
// 1. Profile loading
fun loadProfile(username: String) {
    viewModelScope.launch {
        isLoading.value = true
        profileRepository.getUserProfile(username)
            .collect { result ->
                when {
                    result.isSuccess -> {
                        profile.value = result.getOrNull()
                        isLoading.value = false
                    }
                    result.isFailure -> {
                        errorMessage.value = result.exceptionOrNull()?.message
                        isLoading.value = false
                    }
                }
            }
    }
}
```

## Threading Model

### 1. Coroutines Usage
```kotlin
// Repository layer - IO dispatcher for network calls
fun getEventsForUser(username: String): Flow<Result<List<StudyEventMap>>> = flow {
    // Network operation
}.flowOn(Dispatchers.IO)

// ViewModel layer - Main dispatcher for UI updates
viewModelScope.launch(Dispatchers.Main) {
    // UI state updates
}

// UI layer - Main dispatcher for Compose
LaunchedEffect(Unit) {
    // UI operations
}
```

### 2. Thread Safety
- **Repository**: All network operations on IO dispatcher
- **ViewModel**: State updates on Main dispatcher
- **UI**: Compose operations on Main dispatcher
- **Shared State**: MutableState is thread-safe for UI updates

## Error Handling Strategy

### 1. Repository Level
```kotlin
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

### 2. ViewModel Level
```kotlin
fun loadEvents() {
    viewModelScope.launch {
        try {
            isLoading.value = true
            eventRepository.getEventsForUser(currentUser)
                .collect { result ->
                    when {
                        result.isSuccess -> {
                            events.value = result.getOrNull() ?: emptyList()
                            errorMessage.value = null
                        }
                        result.isFailure -> {
                            errorMessage.value = result.exceptionOrNull()?.message
                            events.value = emptyList()
                        }
                    }
                    isLoading.value = false
                }
        } catch (e: Exception) {
            errorMessage.value = e.message
            isLoading.value = false
        }
    }
}
```

### 3. UI Level
```kotlin
@Composable
fun EventList(events: List<StudyEventMap>, errorMessage: String?) {
    if (errorMessage != null) {
        ErrorDialog(
            message = errorMessage,
            onDismiss = { /* Clear error */ }
        )
    }
    
    LazyColumn {
        items(events) { event ->
            EventCard(event = event)
        }
    }
}
```

## State Management

### 1. Compose State
```kotlin
@Composable
fun EventDetailView(event: StudyEvent) {
    var isLoading by remember { mutableStateOf(true) }
    var localEvent by remember { mutableStateOf(event) }
    var showError by remember { mutableStateOf(false) }
    
    // State updates trigger recomposition
    LaunchedEffect(event.id) {
        isLoading = true
        // Load event details
        isLoading = false
    }
}
```

### 2. ViewModel State
```kotlin
class ProfileViewModel : ViewModel() {
    val profile = mutableStateOf<UserProfile?>(null)
    val isLoading = mutableStateOf(false)
    val errorMessage = mutableStateOf<String?>(null)
    val editableInterests = mutableStateListOf<String>()
    
    // State updates are reactive
    fun loadProfile(username: String) {
        // Updates trigger UI recomposition
    }
}
```

### 3. Shared State
```kotlin
// UserAccountManager - shared across app
class UserAccountManager : ViewModel() {
    var currentUser by mutableStateOf<String?>(null)
    var isLoggedIn by mutableStateOf(false)
    var friends by mutableStateOf<List<String>>(emptyList())
    
    // State changes propagate to all observers
}
```

## Data Persistence

### 1. SharedPreferences
```kotlin
// User preferences and cache
private fun saveToSharedPreferences(friendsList: List<String>) {
    val sharedPrefs = appContext!!.getSharedPreferences("PinItPrefs", Context.MODE_PRIVATE)
    val friendsJson = JSONArray(friendsList).toString()
    sharedPrefs.edit()
        .putString("${currentUser}_friends", friendsJson)
        .apply()
}
```

### 2. In-Memory Cache
```kotlin
// Repository-level caching
class EventRepository {
    private val eventCache = mutableMapOf<String, List<StudyEventMap>>()
    
    fun getEventsForUser(username: String): Flow<Result<List<StudyEventMap>>> = flow {
        // Check cache first
        eventCache[username]?.let { cachedEvents ->
            emit(Result.success(cachedEvents))
            return@flow
        }
        
        // Fetch from API and cache
        val events = fetchFromAPI(username)
        eventCache[username] = events
        emit(Result.success(events))
    }
}
```

## Reactive Data Streams

### 1. Flow Usage
```kotlin
// Repository returns Flow
fun getEventsForUser(username: String): Flow<Result<List<StudyEventMap>>> = flow {
    // Emit data
    emit(Result.success(events))
}.flowOn(Dispatchers.IO)

// ViewModel collects Flow
viewModelScope.launch {
    eventRepository.getEventsForUser(username)
        .collect { result ->
            // Handle result
        }
}
```

### 2. StateFlow (Alternative)
```kotlin
// For hot streams that need to be shared
private val _events = MutableStateFlow<List<StudyEventMap>>(emptyList())
val events: StateFlow<List<StudyEventMap>> = _events.asStateFlow()

// Collect in UI
LaunchedEffect(Unit) {
    viewModel.events.collect { events ->
        // Update UI
    }
}
```

## Data Transformation

### 1. API Response to Domain Model
```kotlin
// API response model
data class EventResponse(
    val id: String,
    val title: String,
    val latitude: Double,
    val longitude: Double,
    val time: String
)

// Domain model
data class StudyEventMap(
    val id: String,
    val title: String,
    val coordinate: Pair<Double, Double>,
    val time: LocalDateTime
)

// Transformation
fun EventResponse.toStudyEventMap(): StudyEventMap {
    return StudyEventMap(
        id = this.id,
        title = this.title,
        coordinate = Pair(this.longitude, this.latitude),
        time = LocalDateTime.parse(this.time)
    )
}
```

### 2. UI State Transformation
```kotlin
// Transform domain model to UI state
@Composable
fun EventCard(event: StudyEventMap) {
    val formattedTime = remember(event.time) {
        event.time.format(DateTimeFormatter.ofPattern("MMM dd, HH:mm"))
    }
    
    Card {
        Text(event.title)
        Text(formattedTime)
    }
}
```

## Performance Optimizations

### 1. Lazy Loading
```kotlin
// LazyColumn for large lists
LazyColumn {
    items(events) { event ->
        EventCard(event = event)
    }
}
```

### 2. State Hoisting
```kotlin
// Hoist state to minimize recomposition
@Composable
fun EventList(
    events: List<StudyEventMap>,
    onEventClick: (StudyEventMap) -> Unit
) {
    LazyColumn {
        items(events) { event ->
            EventCard(
                event = event,
                onClick = { onEventClick(event) }
            )
        }
    }
}
```

### 3. Memoization
```kotlin
// Remember expensive calculations
@Composable
fun EventCard(event: StudyEventMap) {
    val formattedTime = remember(event.time) {
        event.time.format(DateTimeFormatter.ofPattern("MMM dd, HH:mm"))
    }
    
    // Use formattedTime
}
```

## Data Validation

### 1. Input Validation
```kotlin
// Form validation
fun validateEventForm(
    title: String,
    description: String,
    startDate: LocalDateTime
): ValidationResult {
    return when {
        title.isBlank() -> ValidationResult.Error("Title is required")
        description.isBlank() -> ValidationResult.Error("Description is required")
        startDate.isBefore(LocalDateTime.now()) -> ValidationResult.Error("Start date must be in the future")
        else -> ValidationResult.Success
    }
}
```

### 2. API Response Validation
```kotlin
// Validate API response
fun validateApiResponse(response: Response<ApiEventsResponse>): Boolean {
    return response.isSuccessful && 
           response.body() != null && 
           response.body()?.events != null
}
```

## Data Synchronization

### 1. Real-time Updates
```kotlin
// WebSocket for real-time updates
class EventWebSocketManager {
    fun connect() {
        // WebSocket connection
    }
    
    fun onEventUpdate(event: StudyEventMap) {
        // Update local state
    }
}
```

### 2. Conflict Resolution
```kotlin
// Handle data conflicts
fun resolveDataConflict(
    localData: StudyEventMap,
    remoteData: StudyEventMap
): StudyEventMap {
    return when {
        remoteData.time.isAfter(localData.time) -> remoteData
        else -> localData
    }
}
```

## Monitoring and Debugging

### 1. Data Flow Logging
```kotlin
// Log data flow for debugging
fun getEventsForUser(username: String): Flow<Result<List<StudyEventMap>>> = flow {
    Log.d("EventRepository", "Fetching events for user: $username")
    
    try {
        val response = apiService.getStudyEvents(username)
        Log.d("EventRepository", "API response: ${response.code()}")
        
        if (response.isSuccessful) {
            val events = response.body()?.events ?: emptyList()
            Log.d("EventRepository", "Fetched ${events.size} events")
            emit(Result.success(events))
        } else {
            Log.e("EventRepository", "API error: ${response.code()}")
            emit(Result.failure(Exception("API Error")))
        }
    } catch (e: Exception) {
        Log.e("EventRepository", "Exception: ${e.message}", e)
        emit(Result.failure(e))
    }
}
```

### 2. Performance Monitoring
```kotlin
// Monitor data flow performance
fun getEventsForUser(username: String): Flow<Result<List<StudyEventMap>>> = flow {
    val startTime = System.currentTimeMillis()
    
    try {
        // API call
        val result = apiService.getStudyEvents(username)
        
        val duration = System.currentTimeMillis() - startTime
        Log.d("Performance", "API call took ${duration}ms")
        
        emit(Result.success(result))
    } catch (e: Exception) {
        val duration = System.currentTimeMillis() - startTime
        Log.e("Performance", "API call failed after ${duration}ms", e)
        emit(Result.failure(e))
    }
}
```

