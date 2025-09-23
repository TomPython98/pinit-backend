# StudyCon Frontend Architecture Documentation

## 📱 iOS App Overview

**Platform**: iOS 17+
**Framework**: SwiftUI
**Architecture**: MVVM (Model-View-ViewModel)
**Language**: Swift 5.9+

## 🏗️ Project Structure

```
Front_End/Fibbling_BackUp/Fibbling/
├── Views/                          # SwiftUI Views
│   ├── StudyConApp.swift          # Main app entry point
│   ├── ContentView.swift          # Central hub view
│   ├── CalendarView.swift         # Calendar and events display
│   ├── MapBox.swift               # Interactive map with clustering
│   ├── LoginView.swift            # Authentication interface
│   ├── UserReputationView.swift   # User rating and reputation
│   ├── EventDetailedView.swift    # Event detail screen
│   ├── EventCreationView.swift    # Create new event
│   ├── InvitationsView.swift      # Manage invitations
│   ├── EventSocialFeedView.swift  # Event social interactions
│   └── [40+ other views]          # Various UI components
├── Models/                         # Data models
│   ├── StudyEvent.swift           # Event data model
│   ├── UserRating.swift           # Rating and reputation models
│   ├── University.swift           # University data
│   └── MessageModel.swift         # Chat message model
├── Managers/                       # Business logic managers
│   ├── UserAccountManager.swift   # Authentication & user session
│   ├── CalendarManager.swift      # Event management & WebSocket
│   ├── UserReputationManager.swift # Rating system management
│   ├── ChatManager.swift          # Real-time messaging
│   ├── NotificationManager.swift  # Push notifications
│   ├── AutoMatchingManager.swift  # Smart matching logic
│   └── AppDelegate.swift          # App lifecycle management
├── ViewModels/                     # MVVM view models
│   ├── UserProfileManager.swift   # User profile management
│   ├── WeatherViewModel.swift     # Weather integration
│   └── [2 other view models]      # Additional view models
├── Extensions/                     # Swift extensions
│   └── URLRequestExtension.swift  # HTTP request utilities
├── Assets.xcassets/                # App assets and icons
└── Info.plist                     # App configuration
```

## 🎯 Core Architecture Patterns

### 1. MVVM (Model-View-ViewModel)
```swift
// Model
struct StudyEvent: Identifiable, Codable {
    let id: UUID
    let title: String
    let host: String
    // ... other properties
}

// ViewModel
class CalendarManager: ObservableObject {
    @Published var events: [StudyEvent] = []
    @Published var isLoading: Bool = false
    
    func fetchEvents() {
        // Business logic
    }
}

// View
struct CalendarView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    
    var body: some View {
        List(calendarManager.events) { event in
            EventRow(event: event)
        }
    }
}
```

### 2. Environment Object Dependency Injection
```swift
// App level - StudyConApp.swift
struct StudyConApp: App {
    @StateObject private var accountManager = UserAccountManager()
    @StateObject private var calendarManager: CalendarManager
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(accountManager)
                .environmentObject(calendarManager)
        }
    }
}

// View level - Any view can access managers
struct SomeView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var calendarManager: CalendarManager
}
```

### 3. ObservableObject Reactive Updates
```swift
class CalendarManager: ObservableObject {
    @Published var events: [StudyEvent] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Views automatically update when @Published properties change
}
```

## 📊 Data Models

### StudyEvent Model
```swift
struct StudyEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let coordinate: CLLocationCoordinate2D
    let time: Date
    let endTime: Date
    var description: String?
    var invitedFriends: [String]
    var attendees: [String]
    var isPublic: Bool
    var host: String
    var hostIsCertified: Bool
    var eventType: EventType
    var isAutoMatched: Bool?
    var interestTags: [String]?
    var matchedUsers: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, time, description, invitedFriends,
             attendees, isPublic, host, hostIsCertified, latitude, longitude
        case endTime = "end_time"
        case eventType = "event_type"
        case isAutoMatched = "isAutoMatched"
        case interestTags = "interest_tags"
        case matchedUsers = "matchedUsers"
    }
}
```

### EventType Enum
```swift
enum EventType: String, Codable, CaseIterable, Identifiable {
    case study, party, business, other, cultural, academic, 
         networking, social, language_exchange
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .study: return "Study"
        case .party: return "Party"
        case .business: return "Business"
        case .cultural: return "Cultural"
        case .academic: return "Academic"
        case .networking: return "Networking"
        case .social: return "Social"
        case .language_exchange: return "Language Exchange"
        case .other: return "Other"
        }
    }
}
```

### UserRating Models
```swift
struct UserRating: Identifiable, Codable, Equatable {
    let id: String
    let fromUser: String
    let toUser: String
    let eventId: String?
    let rating: Int // 1-5 stars
    let reference: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case fromUser = "from_username"
        case toUser = "to_username"
        case eventId = "event_id"
        case rating
        case reference
        case createdAt = "created_at"
    }
}

struct UserReputationStats: Codable, Equatable {
    var totalRatings: Int
    var averageRating: Double
    var trustLevel: UserTrustLevel
    var eventsHosted: Int
    var eventsAttended: Int
    
    enum CodingKeys: String, CodingKey {
        case totalRatings = "total_ratings"
        case averageRating = "average_rating"
        case eventsHosted = "events_hosted"
        case eventsAttended = "events_attended"
        case trustLevel = "trust_level"
    }
}
```

## 🔧 Manager Classes

### UserAccountManager
```swift
class UserAccountManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let baseURLs = [
        "http://127.0.0.1:8000/api",
        "http://localhost:8000/api",
        "http://10.0.0.30:8000/api"
    ]
    
    func login(username: String, password: String, completion: @escaping (Bool) -> Void) {
        // Authentication logic
    }
    
    func logout() {
        // Cleanup session
    }
}
```

### CalendarManager
```swift
class CalendarManager: ObservableObject {
    @Published var events: [StudyEvent] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let accountManager: UserAccountManager
    private var webSocketTask: URLSessionWebSocketTask?
    
    init(accountManager: UserAccountManager) {
        self.accountManager = accountManager
    }
    
    func fetchEvents() {
        // Fetch events from API
    }
    
    func connectWebSocket() {
        // Real-time updates via WebSocket
    }
    
    func addEvent(_ event: StudyEvent) {
        // Add event to local array
    }
    
    func removeEvent(withID id: UUID) {
        // Remove event from local array
    }
}
```

### UserReputationManager
```swift
class UserReputationManager: ObservableObject {
    @Published var userStats: UserReputationStats?
    @Published var userRatings: [UserRating] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func fetchUserReputation(username: String, completion: @escaping (Bool) -> Void) {
        // Fetch reputation data
    }
    
    func fetchUserRatings(username: String, completion: @escaping (Bool) -> Void) {
        // Fetch user ratings
    }
    
    func submitRating(fromUser: String, toUser: String, eventId: String?, 
                     rating: Int, reference: String?, completion: @escaping (Bool) -> Void) {
        // Submit new rating
    }
}
```

## 🗺️ Map Integration

### MapKit Integration
```swift
import MapKit
import MapboxMaps

struct StudyMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816), // Buenos Aires
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var filteredEvents: [StudyEvent] {
        // Filter events based on user preferences
        calendarManager.events.filter { event in
            // Filtering logic
        }
    }
}
```

### Event Clustering
```swift
struct Cluster: Equatable {
    var events: [StudyEvent]
    
    var coordinate: CLLocationCoordinate2D {
        let lat = events.map { $0.coordinate.latitude }.reduce(0, +) / Double(events.count)
        let lon = events.map { $0.coordinate.longitude }.reduce(0, +) / Double(events.count)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

private func clusterEvents(_ events: [StudyEvent], region: MKCoordinateRegion) -> [Cluster] {
    let clusterDistance: Double = 0.01 // ~1km at equator
    var clusters: [Cluster] = []
    
    for event in events {
        var addedToCluster = false
        
        // Try to add to existing cluster
        for i in 0..<clusters.count {
            if distance(from: event.coordinate, to: clusters[i].coordinate) < clusterDistance {
                clusters[i].events.append(event)
                addedToCluster = true
                break
            }
        }
        
        // Create new cluster if not added to existing one
        if !addedToCluster {
            clusters.append(Cluster(events: [event]))
        }
    }
    
    return clusters
}
```

## 🌐 Network Layer

### API Communication
```swift
class NetworkManager {
    private let baseURLs = [
        "http://127.0.0.1:8000/api",
        "http://localhost:8000/api",
        "http://10.0.0.30:8000/api"
    ]
    
    func makeRequest<T: Codable>(endpoint: String, method: HTTPMethod, 
                                body: Data? = nil, responseType: T.Type, 
                                completion: @escaping (Result<T, Error>) -> Void) {
        // Generic API request method
    }
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}
```

### WebSocket Integration
```swift
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
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    // Handle binary data
                @unknown default:
                    break
                }
                self?.receiveMessage() // Continue listening
            case .failure(let error):
                print("WebSocket error: \(error)")
            }
        }
    }
    
    private func handleMessage(_ message: String) {
        // Parse and handle WebSocket messages
        if let data = message.data(using: .utf8) {
            // Handle real-time updates
        }
    }
}
```

## 🎨 UI Components

### Custom Views
```swift
// Event Card Component
struct EventCard: View {
    let event: StudyEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(event.title)
                    .font(.headline)
                Spacer()
                Text(event.eventType.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(eventTypeColor.opacity(0.2))
                    .foregroundColor(eventTypeColor)
                    .cornerRadius(8)
            }
            
            Text(event.description ?? "")
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Label(event.time.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                Spacer()
                Text("\(event.attendees.count) attendees")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var eventTypeColor: Color {
        switch event.eventType {
        case .study: return .blue
        case .party: return .purple
        case .business: return .green
        case .cultural: return .orange
        case .academic: return .green
        case .networking: return .pink
        case .social: return .red
        case .language_exchange: return .teal
        case .other: return .orange
        }
    }
}
```

### Navigation Structure
```swift
struct ContentView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var calendarManager: CalendarManager
    
    var body: some View {
        TabView {
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
            
            StudyMapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            
            UserReputationView()
                .tabItem {
                    Image(systemName: "star")
                    Text("Reputation")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
    }
}
```

## 🔔 Push Notifications

### NotificationManager
```swift
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized: Bool = false
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }
    
    func scheduleNotification(title: String, body: String, timeInterval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
```

## 🎯 State Management

### App State Flow
```
App Launch → Login Check → Load User Data → Initialize Managers → Show Main UI
     ↓
User Login → Fetch Events → Connect WebSocket → Update UI
     ↓
Real-time Updates → Update Local State → Refresh UI
     ↓
User Logout → Cleanup Session → Show Login Screen
```

### Data Flow Architecture
```
API Response → Manager → @Published Property → View Update
     ↓
User Action → View → Manager Method → API Call → Response → Update State
     ↓
WebSocket Message → Manager → @Published Property → View Update
```

## 🧪 Testing Strategy

### Unit Testing
```swift
import XCTest
@testable import Fibbling

class CalendarManagerTests: XCTestCase {
    var calendarManager: CalendarManager!
    var accountManager: UserAccountManager!
    
    override func setUp() {
        super.setUp()
        accountManager = UserAccountManager()
        calendarManager = CalendarManager(accountManager: accountManager)
    }
    
    func testAddEvent() {
        let event = StudyEvent(title: "Test Event", ...)
        calendarManager.addEvent(event)
        XCTAssertEqual(calendarManager.events.count, 1)
    }
}
```

### UI Testing
```swift
import XCTest

class FibblingUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testLoginFlow() {
        app.textFields["Username"].tap()
        app.textFields["Username"].typeText("testuser")
        
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText("testpass")
        
        app.buttons["Login"].tap()
        
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }
}
```

## 🚀 Performance Optimization

### Image Loading
```swift
// Lazy loading for images
struct AsyncImageView: View {
    let url: String
    
    var body: some View {
        AsyncImage(url: URL(string: url)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        } placeholder: {
            ProgressView()
        }
    }
}
```

### List Performance
```swift
// Efficient list rendering
List(events, id: \.id) { event in
    EventRow(event: event)
}
.id(UUID()) // Force refresh when needed
```

### Memory Management
```swift
// Proper cleanup in managers
deinit {
    webSocketTask?.cancel()
    notificationCenter.removeObserver(self)
}
```

## 🔧 Configuration

### Info.plist Configuration
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to show nearby events</string>

<key>NSUserNotificationsUsageDescription</key>
<string>This app sends notifications for event updates</string>

<key>CFBundleDisplayName</key>
<string>StudyCon</string>
```

### Build Configuration
- **Development**: Debug build with verbose logging
- **Staging**: Release build with test server
- **Production**: Optimized release build

---

**Last Updated**: January 2025
**Frontend Version**: 1.0.0

