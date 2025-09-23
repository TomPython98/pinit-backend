# StudyCon Auto-Refresh System Documentation

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Refresh Mechanisms](#refresh-mechanisms)
4. [Implementation Details](#implementation-details)
5. [Configuration](#configuration)
6. [Troubleshooting](#troubleshooting)
7. [Performance Considerations](#performance-considerations)

## 🎯 Overview

The StudyCon Auto-Refresh System is a comprehensive multi-layered data synchronization solution that ensures users always see the most current information without requiring manual refresh or login/logout cycles. This system addresses the critical user experience issue where data would become stale and require app restart to update.

### Key Benefits
- **Real-time Updates**: Instant data synchronization via WebSocket connections
- **Reliable Fallback**: Periodic refresh ensures data freshness even if WebSocket fails
- **Battery Efficient**: Smart refresh logic prevents unnecessary API calls
- **User-friendly**: Seamless experience without user intervention
- **Robust Error Handling**: Graceful degradation and recovery mechanisms

## 🏗️ Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                    Auto-Refresh System                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   WebSocket     │    │   Periodic      │    │   App       │  │
│  │   Real-time     │◄──►│   Timer         │◄──►│   Lifecycle │  │
│  │   Updates       │    │   (60s)         │    │   Refresh   │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
│           │                       │                       │     │
│           │                       │                       │     │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   Manual        │    │   Smart         │    │   Error     │  │
│  │   Refresh       │    │   Logic         │    │   Handling  │  │
│  │   (User-init)   │    │   (Debouncing)  │    │   (Fallback)│  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Primary Path**: WebSocket real-time updates
2. **Backup Path**: Periodic timer refresh
3. **Recovery Path**: App lifecycle refresh
4. **User Path**: Manual refresh button

## 🔄 Refresh Mechanisms

### 1. WebSocket Real-time Updates (Primary)

**Purpose**: Provide instant updates when data changes
**Trigger**: Backend events (create, update, delete)
**Coverage**: All connected users
**Latency**: Immediate (< 100ms)

#### Implementation
```swift
class EventsWebSocketManager: ObservableObject {
    func connect() {
        let url = URL(string: "ws://127.0.0.1:8000/ws/events/\(username)/")!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
    }
    
    private func handleMessage(_ message: EventChangeMessage) {
        switch message.type {
        case .create: delegate?.didReceiveEventCreation(eventID: message.eventID)
        case .update: delegate?.didReceiveEventUpdate(eventID: message.eventID)
        case .delete: delegate?.didReceiveEventDeletion(eventID: message.eventID)
        }
    }
}
```

#### Backend Integration
```python
class EventsConsumer(AsyncWebsocketConsumer):
    async def event_create(self, event):
        await self.send(text_data=json.dumps({
            "type": "create",
            "event_id": str(event_id)
        }))
```

### 2. Periodic Auto-Refresh Timer (Backup)

**Purpose**: Ensure data freshness even if WebSocket fails
**Frequency**: 60 seconds
**Scope**: Full data refresh
**Conditions**: Only when user is logged in and not loading

#### Implementation
```swift
private func startAutoRefresh() {
    autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
        guard !self.username.isEmpty && !self.isLoading else { return }
        self.fetchEvents()
    }
}
```

### 3. App Lifecycle Refresh (Recovery)

**Purpose**: Catch missed updates when user returns to app
**Trigger**: App becomes active
**Scope**: Full data refresh
**Conditions**: Only if user is logged in and not loading

#### Implementation
```swift
@objc private func handleAppBecameActive() {
    guard !username.isEmpty && !isLoading else { return }
    fetchEvents()
}
```

### 4. Manual Refresh (User-initiated)

**Purpose**: Allow users to force immediate updates
**Trigger**: User taps refresh button
**Scope**: Immediate data fetch
**Debouncing**: Prevents multiple simultaneous calls

#### Implementation
```swift
private func refreshEvents(forceUpdate: Bool = false) {
    guard !calendarManager.isLoading || forceUpdate else { return }
    calendarManager.fetchEvents()
}
```

## 🔧 Implementation Details

### Frontend (iOS) Components

#### CalendarManager Enhancements
```swift
class CalendarManager: ObservableObject {
    // Auto-refresh properties
    private var autoRefreshTimer: Timer?
    private let autoRefreshInterval: TimeInterval = 60.0
    private var webSocketManager: EventsWebSocketManager?
    
    // Setup auto-refresh system
    private func setupWebSocket() {
        webSocketManager = EventsWebSocketManager(username: username)
        webSocketManager?.delegate = self
        webSocketManager?.connect()
        startAutoRefresh()
    }
    
    // Start periodic refresh timer
    private func startAutoRefresh() {
        stopAutoRefresh()
        guard !username.isEmpty else { return }
        
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: autoRefreshInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !self.username.isEmpty && !self.isLoading {
                self.fetchEvents()
            }
        }
    }
    
    // Stop auto-refresh timer
    private func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }
}
```

#### WebSocket Manager
```swift
class EventsWebSocketManager: ObservableObject {
    weak var delegate: EventsWebSocketManagerDelegate?
    private var webSocketTask: URLSessionWebSocketTask?
    private var reconnectAttempt = 0
    private var reconnectTimer: Timer?
    
    func connect() {
        // WebSocket connection logic with reconnection
    }
    
    private func handleConnectionError() {
        // Exponential backoff reconnection logic
    }
}
```

### Backend (Django) Components

#### WebSocket Consumer
```python
class EventsConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.username = self.scope["url_route"]["kwargs"]["username"]
        self.user_events_group = f"events_{sanitize_username(self.username)}"
        await self.channel_layer.group_add(self.user_events_group, self.channel_name)
        await self.accept()
    
    async def event_create(self, event):
        await self.send(text_data=json.dumps({
            "type": "create",
            "event_id": str(event["event_id"])
        }))
```

#### Broadcast Utilities
```python
def broadcast_event_created(event_id, host_username, invited_friends=[]):
    users_to_notify = [host_username] + invited_friends
    broadcast_event_update(event_id, 'create', users_to_notify)

def broadcast_event_update(event_id, event_type, usernames):
    channel_layer = get_channel_layer()
    for username in usernames:
        group_name = f"events_{username}"
        async_to_sync(channel_layer.group_send)(
            group_name,
            {"type": f"event_{event_type}", "event_id": str(event_id)}
        )
```

## ⚙️ Configuration

### Refresh Intervals
- **WebSocket**: Real-time (immediate)
- **Periodic Timer**: 60 seconds (configurable)
- **App Lifecycle**: On activation
- **Manual**: On demand

### Error Handling Configuration
- **WebSocket Reconnection**: Exponential backoff (5s, 10s, 20s, 60s max)
- **API Retry Logic**: 3 attempts with 1s, 2s, 4s delays
- **Network Timeout**: 30 seconds
- **Debounce Delay**: 0.5 seconds for manual refresh

### Performance Settings
- **Max Concurrent Requests**: 3
- **Cache Duration**: 5 minutes for static data
- **Memory Management**: Automatic cleanup on app background

## 🐛 Troubleshooting

### Common Issues

#### WebSocket Connection Failures
**Symptoms**: No real-time updates, periodic refresh works
**Causes**: Network issues, server restart, WebSocket server down
**Solutions**:
- Check WebSocket server status
- Verify network connectivity
- Check browser console for WebSocket errors
- Periodic refresh will maintain data freshness

#### Periodic Refresh Not Working
**Symptoms**: Data becomes stale, no updates
**Causes**: Timer not started, user logged out, app in background
**Solutions**:
- Verify user is logged in
- Check if app is in foreground
- Restart app to reinitialize timers

#### App Lifecycle Refresh Issues
**Symptoms**: Stale data when returning to app
**Causes**: Notification observer not set up, app state issues
**Solutions**:
- Verify notification observer registration
- Check app lifecycle state
- Force refresh manually

### Debug Tools

#### Frontend Debugging
```swift
// Enable debug logging
print("🔄 [CalendarManager] Auto-refresh triggered")
print("📱 [CalendarManager] App became active, refreshing data")
print("🔌 [EventsWebSocketManager] WebSocket connected")
```

#### Backend Debugging
```python
# Enable WebSocket logging
print(f"✅ WebSocket CONNECTED: User {self.username} subscribed to event updates")
print(f"📤 Sent event CREATE notification to {self.username} for event: {event_id}")
```

### Performance Monitoring

#### Metrics to Track
- **WebSocket Connection Uptime**: Should be > 95%
- **API Response Times**: Should be < 2 seconds
- **Refresh Frequency**: Should match configured intervals
- **Memory Usage**: Should remain stable over time

#### Monitoring Tools
- **Xcode Instruments**: For iOS performance monitoring
- **Django Debug Toolbar**: For backend performance
- **WebSocket Inspector**: For real-time connection monitoring

## 📊 Performance Considerations

### Battery Life Optimization
- **Smart Refresh Logic**: Only refresh when necessary
- **Background Throttling**: Reduce refresh frequency when app is backgrounded
- **Network Efficiency**: Batch API calls when possible
- **Timer Management**: Proper cleanup to prevent memory leaks

### Network Usage
- **WebSocket Efficiency**: Real-time updates reduce polling
- **API Optimization**: Only fetch changed data when possible
- **Caching Strategy**: Cache static data to reduce API calls
- **Compression**: Use gzip compression for API responses

### Memory Management
- **Timer Cleanup**: Proper invalidation of timers
- **WebSocket Cleanup**: Close connections on app termination
- **Observer Cleanup**: Remove notification observers on deinit
- **Memory Monitoring**: Track memory usage patterns

### Scalability Considerations
- **WebSocket Scaling**: Use Redis for channel layers in production
- **API Rate Limiting**: Implement rate limiting for API endpoints
- **Database Optimization**: Index frequently queried fields
- **Caching Layer**: Implement Redis caching for frequently accessed data

---

**Last Updated**: January 2025
**Version**: 1.1.0
**Maintainer**: Development Team
