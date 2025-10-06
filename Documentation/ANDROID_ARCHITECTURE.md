# Android Frontend Architecture

## Overview
The Android frontend follows MVVM (Model-View-ViewModel) architecture with Repository pattern, built using Jetpack Compose and Material 3 design system.

## Architecture Layers

### 1. UI Layer (Jetpack Compose)
- **MainActivity.kt**: Single Activity architecture with modal navigation
- **Components**: Reusable UI components in `components/` package
- **Views**: Screen-level composables in `views/` package
- **Theme**: Material 3 theming in `ui/theme/` package

### 2. ViewModel Layer
- **UserAccountManager**: Centralized user authentication and state management
- **ProfileViewModel**: User profile state and operations
- **EventDetailViewModel**: Event detail view logic
- **WeatherViewModel**: Weather data management
- **ChatManager**: Chat functionality management

### 3. Repository Layer
- **EventRepository**: Event data operations and API communication
- **ProfileRepository**: User profile data management
- **EnhancedProfileRepository**: Extended profile functionality
- **EventInteractionsRepository**: Event interactions (likes, comments, shares)

### 4. Network Layer
- **ApiClient**: Retrofit configuration with OkHttp
- **ApiService**: Interface defining all API endpoints
- **EventCreateRequest**: Request models for API calls

### 5. Data Models
- **StudyEventMap**: Core event model with map features
- **UserProfile**: User profile with enhanced fields
- **EventType**: Event category enumeration
- **ApiModels**: API response models with Gson annotations

## Module Boundaries

### Package Structure
```
com.example.pinit/
├── MainActivity.kt                 # App entry point
├── components/                     # Reusable UI components
│   ├── EventDetailView.kt
│   ├── EventCreationView.kt
│   ├── EnhancedProfileView.kt
│   └── map/                       # Map-specific components
├── models/                        # Data models
│   ├── Models.kt
│   ├── ApiModels.kt
│   └── MapModels.kt
├── network/                       # Network layer
│   ├── ApiClient.kt
│   └── ApiService.kt
├── repository/                    # Data repositories
│   ├── EventRepository.kt
│   └── ProfileRepository.kt
├── viewmodels/                    # ViewModels
│   ├── ProfileViewModel.kt
│   └── EventDetailViewModel.kt
├── views/                         # Screen composables
│   ├── LoginView.kt
│   ├── FriendsView.kt
│   └── MapboxView.kt
├── ui/theme/                      # Theming
│   ├── Color.kt
│   ├── Theme.kt
│   └── Type.kt
└── utils/                         # Utilities
    ├── MapboxHelper.kt
    └── JsonUtils.kt
```

## Dependency Injection
- **Manual DI**: ViewModels created manually with dependencies
- **Context Injection**: Application context passed to managers
- **Repository Injection**: Repositories instantiated in ViewModels

## Navigation Approach
- **Modal Navigation**: Bottom sheets and dialogs for secondary screens
- **State-based Navigation**: Boolean flags control view visibility
- **Single Activity**: All navigation handled within MainActivity
- **Composition Local**: UserAccountManager shared via CompositionLocal

## Key Design Patterns

### 1. Repository Pattern
```kotlin
class EventRepository {
    fun getEventsForUser(username: String): Flow<Result<List<StudyEventMap>>>
    fun createEvent(event: StudyEventMap): Flow<Result<StudyEventMap>>
    fun searchEvents(query: String): Flow<Result<List<StudyEventMap>>>
}
```

### 2. MVVM Pattern
```kotlin
class ProfileViewModel(private val accountManager: UserAccountManager) : ViewModel() {
    val profile = mutableStateOf<UserProfile?>(null)
    val isLoading = mutableStateOf(false)
    
    fun loadProfile(username: String) { /* ... */ }
}
```

### 3. State Management
```kotlin
@Composable
fun EventDetailView(event: StudyEvent) {
    var isLoading by remember { mutableStateOf(true) }
    var localEvent by remember { mutableStateOf(event) }
    // State management logic
}
```

## Data Flow
1. **UI Events** → ViewModel methods
2. **ViewModel** → Repository calls
3. **Repository** → API service calls
4. **API Response** → Flow emission
5. **Flow** → UI state updates
6. **State Change** → UI recomposition

## Error Handling
- **Repository Level**: Try-catch with Result<T> wrapper
- **ViewModel Level**: Error state management
- **UI Level**: Error dialogs and user feedback
- **Network Level**: HTTP error handling with fallbacks

## Performance Considerations
- **Flow-based**: Reactive data streams for efficient updates
- **Coroutines**: Non-blocking operations
- **Lazy Loading**: LazyColumn for large lists
- **State Hoisting**: Proper state management to minimize recomposition
- **Caching**: Strategic data caching in repositories

