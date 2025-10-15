import Foundation
import SwiftUI
import Combine

/// Wrapper to decode backend responses. Assumes your backend returns a JSON object with an "events" array.
public struct StudyEventsResponse: Codable {
    let events: [StudyEvent]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode events one by one so a single event failing doesn't break everything
        var eventsArray: [StudyEvent] = []
        var eventsContainer = try container.nestedUnkeyedContainer(forKey: .events)
        let eventsIterator = eventsContainer
        
        while !eventsContainer.isAtEnd {
            do {
                let event = try eventsContainer.decode(StudyEvent.self)
                eventsArray.append(event)
            } catch {
                // Skip this event but continue with others
                _ = try? eventsContainer.decode(EmptyDecodable.self)
            }
            
            // Check if we've reached the end
            if eventsContainer.currentIndex == eventsIterator.count {
                break
            }
        }
        
        self.events = eventsArray
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(events, forKey: .events)
    }
    
    enum CodingKeys: String, CodingKey {
        case events
    }
}

// Empty decodable struct for skipping elements
private struct EmptyDecodable: Decodable {}

/// Manages calendar events and handles backend fetch.
class CalendarManager: ObservableObject {
    @Published var events: [StudyEvent] = []
    @Published var isLoading: Bool = false
    @Published var lastRefreshTime: Date? = nil
    @Published var userJoinRequests: [String] = [] // Array of event IDs where user has pending join requests
    
    // Username should be set once the user is logged in.
    var username: String = ""
    
    /// Computed property for pending notifications count (invitations + join requests to my events)
    var pendingNotificationsCount: Int {
        guard !username.isEmpty else { return 0 }
        
        // Get set of event IDs where user has pending join requests
        let pendingRequestEventIds = Set(userJoinRequests.map { $0.lowercased() })
        
        // Count event invitations (events where I'm invited but not attending yet)
        // EXCLUDE events where user already has a pending join request
        let invitations = events.filter { event in
            let eventIdLower = event.id.uuidString.lowercased()
            return event.invitedFriends.contains(username) &&
                   !event.attendees.contains(username) &&
                   event.host != username &&
                   !pendingRequestEventIds.contains(eventIdLower)
        }.count
        
        // Count pending join requests to MY events (would need separate API call)
        // For now, just count invitations
        return invitations
    }
    private var hasFetchedInitialEvents = false // Flag to track initial fetch
    private var accountManager: UserAccountManager? // Reference to account manager for auth
    
    // Use APIConfig for consistent base URL
    private let baseURL = APIConfig.primaryBaseURL
    private var cancellable: AnyCancellable?
    private var webSocketManager: EventsWebSocketManager?
    private var lastFetchAttempt: Date? = nil
    private let minimumFetchInterval: TimeInterval = 30.0
    
    // Automatic refresh timer
    private var autoRefreshTimer: Timer?
    private let autoRefreshInterval: TimeInterval = 300.0 // Refresh every 5 minutes (reduced from 60 seconds)
    
    // Cache keys
    private let eventsCacheKey = "cached_events"
    private let eventsCacheTimestampKey = "events_cache_timestamp"
    
    /// Dependency Injection initializer. You can pass in your account manager.
    init(accountManager: UserAccountManager) {
        self.accountManager = accountManager
        
        // Load cached events FIRST for instant display
        self.loadEventsCache()
        
        // Listen for logout notification
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(handleUserWillLogout),
                                              name: NSNotification.Name("UserWillLogout"),
                                              object: nil)
        
        // Listen for WebSocket refresh requests
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(handleWebSocketRefresh),
                                              name: NSNotification.Name("RefreshWebSocketConnection"),
                                              object: nil)
        
        // Listen for app becoming active to refresh data
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(handleAppBecameActive),
                                              name: UIApplication.didBecomeActiveNotification,
                                              object: nil)
        
        cancellable = accountManager.$currentUser.sink { [weak self] (newUser: String?) in
            guard let self = self else { return }
            
            let previousUsername = self.username
            self.username = newUser ?? ""
            
            // Fetch events only when username becomes valid for the first time or changes from a non-empty value
            if !self.username.isEmpty && !self.hasFetchedInitialEvents {
                // Start fetch and WebSocket in parallel for maximum performance
                self.setupWebSocket() // Connect immediately
                self.fetchEvents()    // Fetch in parallel
                self.hasFetchedInitialEvents = true // Mark initial fetch as done
            } else if self.username.isEmpty && !previousUsername.isEmpty {
                // User logged out
                self.disconnectWebSocket()
                self.events = [] // Clear events on logout
                self.hasFetchedInitialEvents = false // Reset flag for next login
            } else if !self.username.isEmpty && self.username != previousUsername {
                 // Handle user switching without logout (if applicable)
                 self.disconnectWebSocket() // Disconnect old socket
                 self.events = []           // Clear old user's events
                 self.hasFetchedInitialEvents = false // Reset flag
                 // Start both in parallel
                 self.setupWebSocket()      // Connect new socket immediately
                 self.fetchEvents()         // Fetch in parallel
                 self.hasFetchedInitialEvents = true
            }
        }
    }
    
    deinit {
        // Clean up resources
        stopAutoRefresh()
        disconnectWebSocket()
        cancellable?.cancel()
        
        // Remove the notification observer
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Notification Handlers
    
    // Handler for user logout notification
    @objc private func handleUserWillLogout() {
        stopAutoRefresh()
        disconnectWebSocket()
        DispatchQueue.main.async {
             self.events = [] // Clear events
             self.username = ""
             self.hasFetchedInitialEvents = false // Reset flag
        }
    }
    
    // Handler for WebSocket refresh request
    @objc private func handleWebSocketRefresh() {
        
        // If we have a username, reconnect the WebSocket
        if !username.isEmpty {
            
            // Disconnect and reconnect the WebSocket
            disconnectWebSocket()
            setupWebSocket()
            
            // Update last refresh time
            DispatchQueue.main.async {
                self.lastRefreshTime = Date()
            }
        } else {
        }
    }
    
    // Handler for app becoming active
    @objc private func handleAppBecameActive() {
        
        // WebSocket handles real-time updates - no need for app lifecycle refreshes
        // Only refresh if WebSocket is disconnected and it's been a while
        if !username.isEmpty && !isLoading {
            let webSocketConnected = webSocketManager?.isConnected ?? false
            if !webSocketConnected {
                let timeSinceLastRefresh = lastRefreshTime?.timeIntervalSinceNow ?? -999999
                if abs(timeSinceLastRefresh) > 300 { // 5 minutes only if WebSocket is down
                    fetchEvents()
                }
            }
        }
    }
    
    // MARK: - Refresh Mechanisms - Simplified to just WebSocket setup
    
    /// Setup WebSocket for real-time updates
    private func setupWebSocket() {
        // Ensure disconnect happens first if needed
        disconnectWebSocket()
        
        guard !username.isEmpty else {
            return
        }
        
        webSocketManager = EventsWebSocketManager(username: username)
        webSocketManager?.delegate = self
        webSocketManager?.connect()
        
        // WebSocket handles real-time updates - no need for backup polling
        // startAutoRefresh() // Disabled - WebSocket provides real-time updates
    }
    
    /// Disconnect WebSocket
    private func disconnectWebSocket() {
        // Stop auto-refresh when disconnecting
        stopAutoRefresh()
        
        // Check if manager exists before trying to disconnect
        if webSocketManager != nil {
             webSocketManager?.disconnect()
             webSocketManager?.delegate = nil // Prevent dangling delegate reference
             webSocketManager = nil
        } else {
        }
    }
    
    // MARK: - Automatic Refresh Timer
    
    /// Start automatic refresh timer (DISABLED - relying on WebSockets + manual refresh)
    private func startAutoRefresh() {
        // Auto-refresh timer disabled to reduce redundant fetches
        // Relying on WebSocket updates and manual refresh button instead
    }
    
    /// Stop automatic refresh timer
    private func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }
    
    /// Fetch events for the current user. Uses a cooldown to avoid rapid polling.
    func fetchEvents(force: Bool = false) {
        guard !username.isEmpty,
              let url = URL(string: "\(baseURL)/get_study_events/\(username)/")
        else {
            return
        }
        // Cooldown: prevent frequent calls unless forced (e.g., manual refresh)
        let now = Date()
        if !force, let last = lastFetchAttempt, now.timeIntervalSince(last) < minimumFetchInterval {
            return
        }
        lastFetchAttempt = now
        
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        var request = URLRequest(url: url)
        // Add JWT authentication header
        accountManager?.addAuthHeader(to: &request)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Always set isLoading to false when done
            defer {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.lastRefreshTime = Date()
                }
            }
            
            if let error = error {
                // Fallback to enhanced search on network error
                self.fetchEventsEnhancedFallback()
                return
            }
            
            // Log HTTP status for debugging
            if let httpResponse = response as? HTTPURLResponse {
                // If rate limited or forbidden, fallback to enhanced endpoint
                if httpResponse.statusCode == 403 || httpResponse.statusCode == 429 {
                    self.fetchEventsEnhancedFallback()
                    return
                }
            }
            
            guard let data = data else {
                // Fallback if no data
                self.fetchEventsEnhancedFallback()
                return
            }
            
            // Debug: Log raw response (truncated for readability)
            if let responseString = String(data: data, encoding: .utf8) {
                let truncatedResponse = String(responseString.prefix(500)) + (responseString.count > 500 ? "..." : "")
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(StudyEventsResponse.self, from: data)
                
                
                DispatchQueue.main.async {
                    // Early exit if no events were successfully decoded
                    if response.events.isEmpty {
                        self.events = []
                        return
                    }
                    
                    // Filter out events that have already ended AND filter out pending invitations.
                    // In CalendarManager.fetchEvents() method, update the filtering logic:
                    
                    let filteredEvents = response.events.filter { event in
                        // Check if the user is related to this event - either as host or attendee
                        let isUserEvent = event.host == self.username ||
                                          event.attendees.contains(self.username)
                        
                        // Check if this is an auto-matched event for the user
                        let isAutoMatchedEvent = event.isAutoMatched ?? false
                        
                        // Check if the user is invited to this event
                        let isInvitedEvent = event.invitedFriends.contains(self.username)
                        
                        // Check if this is a public event that anyone can join
                        let isPublicEvent = event.isPublic ?? false
                        
                        // For debugging
                        let isExpired = event.endTime <= Date()
                        
                        // UPDATED: Include events where the user is attending, hosting, auto-matched, invited, OR public events
                        // This ensures RSVPed, created, auto-matched, invited, and discoverable public events are shown
                        let include = !isExpired && (isUserEvent || isAutoMatchedEvent || isInvitedEvent || isPublicEvent)
                        
                        if include {
                            
                            // Debug output to identify different event types
                            if event.attendees.contains(self.username) {
                            }
                            if event.host == self.username {
                            }
                            if isAutoMatchedEvent {
                            }
                            if isInvitedEvent {
                            }
                            if isPublicEvent {
                            }
                        } else {
                            if isExpired {
                            }
                        }
                        
                        return include
                    }
                    
                    
                    self.events = filteredEvents
                    
                    // Save to cache for instant display next time
                    self.saveEventsCache()
                    
                    // Print summary of included events
                    var hostCount = 0
                    var attendingCount = 0
                    var autoMatchedCount = 0
                    var invitedCount = 0
                    
                    for event in self.events {
                        if event.host == self.username {
                            hostCount += 1
                        }
                        if event.attendees.contains(self.username) {
                            attendingCount += 1
                        }
                        if event.isAutoMatched ?? false {
                            autoMatchedCount += 1
                        }
                        if event.invitedFriends.contains(self.username) {
                            invitedCount += 1
                        }
                    }
                    
                    
                    // Print all events ID and attendees for debugging
                    for event in self.events {
                    }
                }
            } catch {
                // Fallback to enhanced endpoint on decode errors (e.g., HTML 403 body)
                self.fetchEventsEnhancedFallback()
            }
        }.resume()
    }

    /// Fallback fetch using enhanced_search_events (less strict, not per-username)
    private func fetchEventsEnhancedFallback() {
        guard let url = URL(string: "\(baseURL)/enhanced_search_events/") else { return }
        var request = URLRequest(url: url)
        accountManager?.addAuthHeader(to: &request)
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                self.lastRefreshTime = Date()
            }
            if let error = error { return }
            guard let data = data else { return }
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(StudyEventsResponse.self, from: data)
                DispatchQueue.main.async {
                    // Apply same filtering logic as primary path
                    let filteredEvents = response.events.filter { event in
                        let isUserEvent = event.host == self.username || event.attendees.contains(self.username)
                        let isAutoMatchedEvent = event.isAutoMatched ?? false
                        let isInvitedEvent = event.invitedFriends.contains(self.username)
                        let isPublicEvent = event.isPublic ?? false
                        let isExpired = event.endTime <= Date()
                        return !isExpired && (isUserEvent || isAutoMatchedEvent || isInvitedEvent || isPublicEvent)
                    }
                    self.events = filteredEvents
                    self.objectWillChange.send()
                }
            } catch {
            }
        }.resume()
    }
    
    /// Add an event locally (avoids duplicates).
    func addEvent(_ event: StudyEvent) {
        
        DispatchQueue.main.async {
            // Check if the event is already in the events array
            if !self.events.contains(where: { $0.id == event.id }) {
                // Add the new event
                self.events.append(event)
            } else {
                // Update the existing event
                if let index = self.events.firstIndex(where: { $0.id == event.id }) {
                    self.events[index] = event
                }
            }
            
            // Debug output to verify the event is in the list
            
            // Force UI update
            self.objectWillChange.send()
        }
    }
    
    /// Remove an event locally by its id.
    func removeEvent(withID id: UUID) {
        
        DispatchQueue.main.async {
            let originalCount = self.events.count
            self.events.removeAll { $0.id == id }
            
            if originalCount != self.events.count {
            } else {
            }
            
            // Force UI update
            self.objectWillChange.send()
        }
    }
    
    /// RSVP call to the backend.
    func rsvpEvent(eventID: UUID, completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: "\(baseURL)rsvp_study_event/") else {
            completion(false, "Invalid URL")
            return
        }
        
        
        // Add event to local list immediately if user isn't already in attendees
        if let eventIndex = events.firstIndex(where: { $0.id == eventID }) {
            var updatedEvent = events[eventIndex]
            let isAttending = updatedEvent.attendees.contains(username)
            
            
            // Toggle attendance locally for immediate UI feedback
            if isAttending {
                // User is already attending, so remove
                updatedEvent.attendees.removeAll(where: { $0 == username })
            } else {
                // User is not attending, so add
                updatedEvent.attendees.append(username)
            }
            
            // Update the local array immediately
            DispatchQueue.main.async {
                self.events[eventIndex] = updatedEvent
                
                // Notify that data changed
                self.objectWillChange.send()
                
                // Send notification that RSVP was updated
                NotificationCenter.default.post(
                    name: Notification.Name("EventRSVPUpdated"),
                    object: nil,
                    userInfo: ["eventID": eventID]
                )
            }
        } else {
        }
        
        // DO NOT set isLoading to true for RSVP operations
        // This prevents the ContentView from showing "Loading your events..." during RSVP
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let rsvpData: [String: Any] = [
            "username": username,
            "event_id": eventID.uuidString
        ]
        
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: rsvpData)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                defer {
                    DispatchQueue.main.async {
                        self?.isLoading = false
                    }
                }
                
                // Log HTTP response
                if let httpResponse = response as? HTTPURLResponse {
                }
                
                // Log response data
                if let data = data, let responseStr = String(data: data, encoding: .utf8) {
                    
                    // Try to parse the response
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let success = json["success"] as? Bool, success {

                        } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                                  let message = json["message"] as? String {
                            // Log potential error messages from backend on RSVP failure
                       }
                    } catch {
                    }
                }
                
                if let error = error {
                    // Revert local change on error? Maybe fetch specific event state?
                    // For now, just call completion handler with error
                    DispatchQueue.main.async {
                        // Maybe revert the local optimistic update here if desired
                        completion(false, "RSVP network error: \(error.localizedDescription)")
                    }
                    return
                }

                // If successful (no error), call completion handler
                // The WebSocket update should handle refreshing the specific event state
                DispatchQueue.main.async {
                    completion(true, "RSVP submitted") // Changed message as we rely on WS for final state
                }
            }.resume()
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                completion(false, "Failed to encode RSVP data: \(error.localizedDescription)")
            }
        }
    }
}

extension CalendarManager {
    func recommendEvents(basedOn currentEvents: [StudyEvent]) -> [StudyEvent] {
        // Simple AI-like recommendation logic
        let eventTypes = currentEvents.map { $0.eventType }
        let typeCounts = Dictionary(grouping: eventTypes, by: { $0 })
        
        // Recommend events of types user hasn't explored much
        let underrepresentedTypes = EventType.allCases.filter { type in
            let count = typeCounts[type, default: []].count
            return count < 2 // Suggest events of types with few existing events
        }
        
        return events.filter { event in
            underrepresentedTypes.contains(event.eventType)
        }
    }
}

// MARK: - EventsWebSocketManager Delegate
extension CalendarManager: EventsWebSocketManagerDelegate {
    func didReceiveEventUpdate(eventID: UUID) {
        // Fetch just the specific event
        fetchSpecificEvent(eventID: eventID)
    }
    
    func didReceiveEventCreation(eventID: UUID) {
        // Fetch just the specific event
        fetchSpecificEvent(eventID: eventID)
    }
    
    func didReceiveEventDeletion(eventID: UUID) {
        // Remove the event locally immediately
        removeEvent(withID: eventID)
    }
    
    /// Fetch a specific event by its ID and update it in the local array
    func fetchSpecificEvent(eventID: UUID) {
        guard !username.isEmpty else {
            return
        }
        
        // First try using the multi-event endpoint with the current username
        let url = URL(string: "\(baseURL)/get_study_events/\(username)/")
        var request = URLRequest(url: url!)
        // Add JWT for protected endpoint
        accountManager?.addAuthHeader(to: &request)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                // Try fallback
                self.fetchEnhancedAndHandle(eventID: eventID)
                return
            }
            
            guard let data = data else {
                self.fetchEnhancedAndHandle(eventID: eventID)
                return
            }
            
            do {
                // This endpoint returns a StudyEventsResponse with an array of events
                let decoder = JSONDecoder()
                let response = try decoder.decode(StudyEventsResponse.self, from: data)
                
                // Find the specific event we're looking for
                if let updatedEvent = response.events.first(where: { $0.id == eventID }) {
                    self.handleUpdatedEvent(updatedEvent)
                } else {
                    
                    // If event not in response, it might have been removed from user's events
                    DispatchQueue.main.async {
                        // Remove the event if it exists
                        if let index = self.events.firstIndex(where: { $0.id == eventID }) {
                            self.events.remove(at: index)
                            self.objectWillChange.send()
                        } else {
                        }
                    }
                }
            } catch {
                // Fallback to enhanced fetch if decode fails
                self.fetchEnhancedAndHandle(eventID: eventID)
            }
        }.resume()
    }

    /// Fallback: fetch via enhanced_search_events and handle a specific event
    private func fetchEnhancedAndHandle(eventID: UUID) {
        guard let url = URL(string: "\(baseURL)/enhanced_search_events/") else {
            self.constructEventFromWebSocketMessage(eventID: eventID)
            return
        }
        var request = URLRequest(url: url)
        accountManager?.addAuthHeader(to: &request)
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            if let _ = error { self.constructEventFromWebSocketMessage(eventID: eventID); return }
            guard let data = data else { self.constructEventFromWebSocketMessage(eventID: eventID); return }
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(StudyEventsResponse.self, from: data)
                if let updatedEvent = response.events.first(where: { $0.id == eventID }) {
                    self.handleUpdatedEvent(updatedEvent)
                } else {
                    self.constructEventFromWebSocketMessage(eventID: eventID)
                }
            } catch {
                self.constructEventFromWebSocketMessage(eventID: eventID)
            }
        }.resume()
    }
    
    /// Constructs an updated event from existing data + WebSocket message
    private func constructEventFromWebSocketMessage(eventID: UUID) {
        DispatchQueue.main.async {
            // Check if we already have this event
            if let existingEvent = self.events.first(where: { $0.id == eventID }) {
                
                // We already have this event, so just notify UI that it changed
                // (The actual change will come from the server via WebSocket)
                self.objectWillChange.send()
                
                // Post a notification so views that are specifically waiting for this event can update
                NotificationCenter.default.post(
                    name: Notification.Name("EventUpdatedFromWebSocket"),
                    object: nil,
                    userInfo: ["eventID": eventID]
                )
            } else {
                // Event might be new - we'll wait for a CREATE WebSocket message instead
            }
        }
    }
    
    /// Handle an updated event received via WebSocket or direct API call
    private func handleUpdatedEvent(_ event: StudyEvent) {
        // Add detailed logging to see the event state
        
        let isUserEvent = event.host == self.username || event.attendees.contains(self.username)
        let isExpired = event.endTime <= Date()
        
        
        DispatchQueue.main.async {
            if isUserEvent && !isExpired {
                // Update or add the event to the local array
                self.updateOrAddEvent(event)
            } else {
                // Add more detailed logging about why the event might be excluded
                if !isUserEvent {
                }
                if isExpired {
                }
                
                if let index = self.events.firstIndex(where: { $0.id == event.id }) {
                    // Remove the event if it's no longer relevant to the user
                    self.events.remove(at: index)
                }
            }
            
            // Notify UI of the change
            self.objectWillChange.send()
            
            // Additionally post a notification for components that might not be directly observing the manager
            NotificationCenter.default.post(
                name: Notification.Name("EventUpdatedFromWebSocket"),
                object: nil,
                userInfo: ["eventID": event.id]
            )
        }
    }
    
    /// Update an existing event or add a new one without duplicating
    private func updateOrAddEvent(_ event: StudyEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            // Update existing event
            events[index] = event
        } else {
            // Add new event
            events.append(event)
        }
    }
    
    // MARK: - Cache Management (Performance Optimization)
    
    /// Load cached events on app startup for instant display
    private func loadEventsCache() {
        guard let data = UserDefaults.standard.data(forKey: eventsCacheKey) else {
            print("📦 No cached events found")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let cachedEvents = try decoder.decode([StudyEvent].self, from: data)
            
            // Check cache age (max 24 hours)
            if let timestamp = UserDefaults.standard.object(forKey: eventsCacheTimestampKey) as? Double {
                let cacheAge = Date().timeIntervalSince1970 - timestamp
                if cacheAge < 86400 { // 24 hours
                    self.events = cachedEvents
                    print("📦 Loaded \(cachedEvents.count) events from cache (age: \(Int(cacheAge/60))min)")
                } else {
                    print("📦 Cache expired (age: \(Int(cacheAge/3600))h), will fetch fresh data")
                }
            }
        } catch {
            print("❌ Failed to load cached events: \(error)")
        }
    }
    
    /// Save events to cache for next app launch
    private func saveEventsCache() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(events)
            UserDefaults.standard.set(data, forKey: eventsCacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: eventsCacheTimestampKey)
            print("📦 Saved \(events.count) events to cache")
        } catch {
            print("❌ Failed to save events cache: \(error)")
        }
    }
}
