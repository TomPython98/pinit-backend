//
//  EventDetailAndInteractions.swift
//  YourProjectName
//
//  Created by Your Name on 2025-03-XX.
//

import SwiftUI
import PhotosUI
import MapKit
import EventKit
import CoreLocation

//
//  EventDetailAndInteractions.swift
//  YourProjectName
//
//  Created by Your Name on 2025-03-XX.
//

import SwiftUI
import PhotosUI
import MapKit
import EventKit

// MARK: - Models for Event Interactions

/// Models for social interactions with the event
struct EventInteractions: Codable, Equatable {
    /// Represents a comment or reply in the event feed
    struct Post: Codable, Identifiable, Equatable {
        let id: Int
        let text: String
        let username: String
        let created_at: String
        let imageURLs: [String]?
        var likes: Int
        var isLikedByCurrentUser: Bool
        var replies: [Post]
        
        static func == (lhs: EventInteractions.Post, rhs: EventInteractions.Post) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    /// Stores like information
    struct Likes: Codable, Equatable {
        var total: Int
        var users: [String]
    }
    
    /// Tracks sharing analytics
    struct Shares: Codable, Equatable {
        var total: Int
        var breakdown: [String: Int]
    }
    
    var posts: [Post]
    var likes: Likes
    var shares: Shares
}

// MARK: - EventDetailView

struct EventDetailView: View {
    // MARK: - Properties
    let event: StudyEvent
    @Binding var studyEvents: [StudyEvent]
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var calendarManager: CalendarManager
    
    /// Callback for joining/leaving events
    let onRSVP: (UUID) -> Void
    
    // MARK: - View State
    @State private var showImagePicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var isLoadingContent = true
    @State private var showCalendarError = false
    @State private var localEvent: StudyEvent
    @State private var showInteractions = false
    @State private var hasInitialized = false
    @State private var attendanceStateChanged = UUID()
    @State private var showRateUserSheet = false
    @State private var selectedUserToRate: String? = nil
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    // Prevent double-like taps while request is in flight
    @State private var inFlightLikePostIds: Set<Int> = []
    @State private var showShareSheet = false
    @State private var showSocialFeedSheet = false
    @State private var showFeedView = false
    @State private var showUserProfileSheet = false
    @State private var selectedUserProfile: String? = nil
    @State private var showEditSheet = false
    @State private var showEventReportSheet = false
    @State private var navigateToMap = false
    @State private var resolvedAddress: String? = nil
    @State private var showDeleteAlert = false

    init(event: StudyEvent, studyEvents: Binding<[StudyEvent]>, onRSVP: @escaping (UUID) -> Void) {
        self.event = event
        self._studyEvents = studyEvents
        self.onRSVP = onRSVP
        
        // Check initial event's tags
        if let tags = event.interestTags, !tags.isEmpty {
            // Tags already available
        } else {
            // No tags available - check UserDefaults
            let eventTagsKey = "event_tags_\(event.id.uuidString)"
            if let savedTags = UserDefaults.standard.array(forKey: eventTagsKey) as? [String], !savedTags.isEmpty {
                // Found tags in UserDefaults
            } else {
                // Try by title as well
                let titleKey = "event_tags_title_\(event.title.lowercased())"
                if let savedTagsByTitle = UserDefaults.standard.array(forKey: titleKey) as? [String], !savedTagsByTitle.isEmpty {
                    // Found tags by title
                } else {
                    // No tags found anywhere
                }
            }
        }
        
        // Always use the passed event as the primary source, only use array for updates
        self._localEvent = State(initialValue: event)
        
        // 🔧 FIX: Try to find a more complete version in the array by matching title and host
        // This handles cases where the event ID might have changed (e.g., after backend creation)
        if let updatedEventInArray = studyEvents.wrappedValue.first(where: { 
            $0.id == event.id || 
            ($0.title == event.title && $0.host == event.host && abs($0.time.timeIntervalSince(event.time)) < 60)
        }) {
            // Found event in array (by ID or by matching title/host/time), use it for any additional data
            self._localEvent = State(initialValue: updatedEventInArray)
        } else {
        }

        // Address resolution moved to onAppear to avoid capturing self in init
    }
    
    var isAttending: Bool {
        // This will cause the property to be recalculated whenever attendanceStateChanged is updated
        _ = attendanceStateChanged
        
        // Check if the current user is in the attendees list
        let currentUser = accountManager.currentUser ?? ""
        return localEvent.attendees.contains(currentUser)
    }
    
    var isHosting: Bool {
        let currentUser = accountManager.currentUser ?? ""
        return localEvent.host == currentUser
    }
    
    var canManageAttendance: Bool {
        return isHosting && !isEventCompleted
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            if isLoadingContent {
                loadingView
            } else {
                contentView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.bgCard, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(Color.textPrimary)
                }
                .accessibilityLabel("Back")
            }
            ToolbarItem(placement: .principal) {
                Text(localEvent.title)
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(1)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if isHosting {
                    Menu {
                        Button(action: { showEditSheet = true }) {
                            Label("Edit Event", systemImage: "pencil")
                        }
                        
                        Button(action: { showDeleteAlert = true }) {
                            Label("Delete Event", systemImage: "trash")
                        }
                        .foregroundColor(.red)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .foregroundColor(Color.textPrimary)
                    }
                    .accessibilityLabel("Event Options")
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            EventImagePicker(selectedImages: $selectedImages)
        }
        .sheet(isPresented: $showInteractions) {
            NavigationStack {
                EventSocialFeedView(event: localEvent)
                    .environmentObject(accountManager)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareEventView(event: localEvent)
        }
        .sheet(isPresented: $showEditSheet) {
            EventEditView(event: localEvent, studyEvents: $studyEvents)
                .environmentObject(accountManager)
                .environmentObject(calendarManager)
        }
        .sheet(isPresented: $showEventReportSheet) {
            ReportContentView(
                contentType: .event,
                contentId: localEvent.id.uuidString
            )
        }
        .sheet(isPresented: $showSocialFeedSheet) {
            SocialFeedShareView(event: localEvent)
                .environmentObject(accountManager)
        }
        .sheet(isPresented: $showFeedView) {
            EventFeedView(event: localEvent)
                .environmentObject(accountManager)
        }
        .sheet(isPresented: $showUserProfileSheet, onDismiss: {
            selectedUserProfile = nil
        }) {
            if let selectedUser = selectedUserProfile {
                UserProfileView(username: selectedUser)
                    .environmentObject(accountManager)
            }
        }
        .alert("Calendar Access Required", isPresented: $showCalendarError) {
            Button("Open Settings", role: .none) { openSettings() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To add this event to your calendar, please enable calendar access in Settings.")
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Delete Event", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteEvent()
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
        .onAppear(perform: handleOnAppear)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("EventRSVPUpdated")).throttle(for: 1.0, scheduler: RunLoop.main, latest: true)) { notification in
            // Check if this notification is for our event
            if let eventID = notification.userInfo?["eventID"] as? UUID, 
               eventID == localEvent.id {
                // Received RSVP update notification
                // End loading state immediately
                if isLoadingContent {
                    withAnimation {
                        isLoadingContent = false
                    }
                }
                
                // Only refresh if we haven't done so recently
                if !hasInitialized {
                    refreshEventData()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        ProgressView("Loading...")
            .progressViewStyle(CircularProgressViewStyle(tint: Color.brandPrimary))
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.bgSurface)
    }
    
    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Event Header Card - matching ContentView style
                eventHeaderCard
                    .padding(.horizontal)
                
                // Event Details Card
                eventDetailsCard
                    .padding(.horizontal)
                
                // Attendees Card
                attendeesCard
                    .padding(.horizontal)
                
                // Action Buttons Card
                actionButtonsCard
                    .padding(.horizontal)
                
                // Social Feed Card
                socialFeedCard
                    .padding(.horizontal)
            }
            .padding(.vertical, 10)
            .padding(.bottom, 40)
        }
        .background(
            ZStack {
                // Refined background with subtle pattern - matching ContentView
                Color.bgSurface.ignoresSafeArea()
                
                // Enhanced layered background for depth
                LinearGradient(
                    colors: [
                        Color.gradientStart.opacity(0.05),
                        Color.gradientEnd.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        )
        .sheet(isPresented: $showRateUserSheet, onDismiss: {
            selectedUserToRate = nil
        }) {
            if let selectedUser = selectedUserToRate, let currentUser = accountManager.currentUser {
                // Show rate user view for a specific user
                RateUserView(
                    event: localEvent,
                    username: currentUser,
                    targetUser: selectedUser,
                    onComplete: { _ in
                        showRateUserSheet = false
                    }
                )
            } else if let currentUser = accountManager.currentUser {
                // Show a list of attendees to rate
                NavigationStack {
                    List {
                        Section(header: Text("Select an attendee to rate")) {
                            ForEach(localEvent.attendees.filter { $0 != currentUser }, id: \.self) { attendee in
                                Button(action: {
                                    selectedUserToRate = attendee
                                }) {
                                    HStack {
                                        Text(attendee)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(Color.textMuted)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Rate Attendees")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showRateUserSheet = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var socialFeedButton: some View {
        Button(action: { showInteractions = true }) {
            Label("Event Social Feed", systemImage: "text.bubble.fill")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.brandPrimary)
                .cornerRadius(12)
        }
        .padding(.horizontal)
        .accessibilityIdentifier("eventSocialFeedButton")
    }
    
    // MARK: - Actions
    
    private func handleOnAppear() {
        // Always refresh event data once when the view appears to get the latest attendance status
        refreshEventData()
        
        // Only run initialization code once
        if !hasInitialized {
            withAnimation(.easeInOut(duration: 0.2)) {
                isLoadingContent = false
            }
            
            // Fetch interest tags if this is an auto-matched event and tags are missing
            if localEvent.isAutoMatched ?? false && (localEvent.interestTags == nil || localEvent.interestTags?.isEmpty == true) {
                fetchEventTags()
            }
            
            // Prefetch images for attendees and host
            prefetchAttendeeImages()
            
            hasInitialized = true
        }
    }
    
    // MARK: - Delete Event
    private func deleteEvent() {
        guard let url = URL(string: APIConfig.fullURL(for: "deleteEvent")) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        accountManager.addAuthHeader(to: &request)
        
        let body = ["event_id": localEvent.id.uuidString]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        alertTitle = "Error"
                        alertMessage = "Failed to delete event: \(error.localizedDescription)"
                        showAlert = true
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            // Success - remove from local events and dismiss
                            studyEvents.removeAll { $0.id == localEvent.id }
                            dismiss()
                        } else {
                            alertTitle = "Error"
                            alertMessage = "Failed to delete event"
                            showAlert = true
                        }
                    }
                }
            }.resume()
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to prepare delete request"
            showAlert = true
        }
    }
    private func prefetchAttendeeImages() {
        var usernamesToPrefetch: [String] = []
        
        // Add host
        usernamesToPrefetch.append(localEvent.host)
        
        // Add attendees (limit to first 20 for performance)
        let attendeesToPrefetch = Array(localEvent.attendees.prefix(20))
        usernamesToPrefetch.append(contentsOf: attendeesToPrefetch)
        
        // Remove duplicates
        usernamesToPrefetch = Array(Set(usernamesToPrefetch))
        
        if !usernamesToPrefetch.isEmpty {
            Task {
                await ImageManager.shared.prefetchImagesForUsers(usernamesToPrefetch)
            }
        }
    }
    
    // MARK: - Network Requests
    
    private func fetchEventTags() {
        // Check if we already have tags in the event object
        if let existingTags = localEvent.interestTags, !existingTags.isEmpty {
            // Already have tags for this event
            return
        }

        // First check the original event passed to this view
        if let originalTags = event.interestTags, !originalTags.isEmpty {
            // Using tags from original event parameter
            DispatchQueue.main.async {
                var updatedEvent = self.localEvent
                updatedEvent.interestTags = originalTags
                self.localEvent = updatedEvent
            }
            return
        }

        // Next try to get tags from the studyEvents array (which should be freshly fetched)
        if let updatedEvent = studyEvents.first(where: { $0.id == localEvent.id }),
           let tags = updatedEvent.interestTags, !tags.isEmpty {
            DispatchQueue.main.async {
                var updatedLocalEvent = self.localEvent
                updatedLocalEvent.interestTags = tags
                self.localEvent = updatedLocalEvent
            }
            return
        }
        
        // Try to load from UserDefaults by event ID
        let eventTagsKey = "event_tags_\(localEvent.id.uuidString)"
        if let savedTags = UserDefaults.standard.array(forKey: eventTagsKey) as? [String], !savedTags.isEmpty {
            DispatchQueue.main.async {
                var updatedEvent = self.localEvent
                updatedEvent.interestTags = savedTags
                self.localEvent = updatedEvent
            }
            return
        }
        
        // Try to load from UserDefaults by event title
        let titleKey = "event_tags_title_\(localEvent.title.lowercased())"
        if let savedTagsByTitle = UserDefaults.standard.array(forKey: titleKey) as? [String], !savedTagsByTitle.isEmpty {
            
            // Save with the event ID for future reference
            UserDefaults.standard.set(savedTagsByTitle, forKey: eventTagsKey)
            
            DispatchQueue.main.async {
                var updatedEvent = self.localEvent
                updatedEvent.interestTags = savedTagsByTitle
                self.localEvent = updatedEvent
            }
            return
        }

        
        // As a fallback, try to reconstruct tags from the event title and type
        DispatchQueue.main.async {
            var updatedEvent = self.localEvent
            
            // Set default tags based on event type plus event title
            var defaultTags: [String] = [self.localEvent.title.lowercased()]
            
            switch self.localEvent.eventType {
            case .study:
                defaultTags.append(contentsOf: ["study", "education", "learning"])
            case .party:
                defaultTags.append(contentsOf: ["party", "social", "fun"])
            case .business:
                defaultTags.append(contentsOf: ["business", "networking", "professional"])
            case .cultural:
                defaultTags.append(contentsOf: ["cultural", "arts", "heritage"])
            case .academic:
                defaultTags.append(contentsOf: ["academic", "research", "scholarship"])
            case .networking:
                defaultTags.append(contentsOf: ["networking", "professional", "connections"])
            case .social:
                defaultTags.append(contentsOf: ["social", "friends", "community"])
            case .language_exchange:
                defaultTags.append(contentsOf: ["language", "exchange", "learning"])
            case .other:
                defaultTags.append(contentsOf: ["meeting", "gathering", "event"])
            }
            
            // Filter out duplicates and empty strings
            let uniqueTags = Array(Set(defaultTags.filter { !$0.isEmpty }))
            
            updatedEvent.interestTags = uniqueTags
            self.localEvent = updatedEvent
        }
    }
    
    // MARK: - Helper Methods
    
    /// Refreshes event data by requesting updated data for this event
    private func refreshEventData() {
        // Add a static cache to prevent calling refresh too frequently
        struct RefreshCache {
            static var lastRefreshTime: [UUID: Date] = [:]
        }
        
        // Check if we've refreshed this event recently (within 2 seconds)
        let now = Date()
        if let lastRefresh = RefreshCache.lastRefreshTime[localEvent.id],
           now.timeIntervalSince(lastRefresh) < 2.0 {
            return
        }
        
        
        // Update the last refresh time
        RefreshCache.lastRefreshTime[localEvent.id] = now
        
        let didUpdateFromStudyEvents = checkAndUpdateFromStudyEvents()
        
        // As a backup, check UserDefaults for this user's RSVP status if we didn't find updated data in studyEvents
        if !didUpdateFromStudyEvents {
            checkAndUpdateFromUserDefaults()
        }
    }
    
    // Helper to check and update from studyEvents array
    private func checkAndUpdateFromStudyEvents() -> Bool {
        // Find the current event in the studyEvents array and update our local copy
        if let updatedEvent = studyEvents.first(where: { $0.id == localEvent.id }) {
            
            // Only update if there are actual changes
            if updatedEvent.attendees != localEvent.attendees {
                localEvent = updatedEvent
                
                // Force UI to refresh by updating attendance state trigger
                attendanceStateChanged = UUID()
                return true
            }
        }
        return false
    }
    
    // Helper to check and update from UserDefaults
    private func checkAndUpdateFromUserDefaults() {
        let currentUser = accountManager.currentUser ?? ""
        if !currentUser.isEmpty {
            let key = "event_rsvp_\(localEvent.id.uuidString)_\(currentUser)"
            if UserDefaults.standard.object(forKey: key) != nil {
                let isAttendingInUserDefaults = UserDefaults.standard.bool(forKey: key)
                let isCurrentlyAttending = localEvent.attendees.contains(currentUser)
                
                // If UserDefaults doesn't match current state, update local event
                if isAttendingInUserDefaults != isCurrentlyAttending {
                    
                    if isAttendingInUserDefaults && !isCurrentlyAttending {
                        // Add user to attendees
                        localEvent.attendees.append(currentUser)
                    } else if !isAttendingInUserDefaults && isCurrentlyAttending {
                        // Remove user from attendees
                        if let index = localEvent.attendees.firstIndex(of: currentUser) {
                            localEvent.attendees.remove(at: index)
                        }
                    }
                    
                    // Force UI to refresh
                    attendanceStateChanged = UUID()
                    
                    // Also update studyEvents array
                    if let eventIndex = studyEvents.firstIndex(where: { $0.id == localEvent.id }) {
                        studyEvents[eventIndex] = localEvent
                    }
                }
            }
        }
    }
}

// MARK: - Calendar Sync Helper
extension EventDetailView {
    func syncEventToCalendar(event: StudyEvent) {
        let eventStore = EKEventStore()
        
        Task {
            do {
                let accessGranted: Bool
                
                if #available(iOS 17.0, *) {
                    accessGranted = try await requestCalendarAccessIOS17(store: eventStore)
                } else {
                    accessGranted = await requestCalendarAccessLegacy(store: eventStore)
                }
                
                if accessGranted {
                    await createCalendarEvent(event: event, eventStore: eventStore)
                } else {
                    await MainActor.run { showCalendarError = true }
                }
            } catch {
                await MainActor.run { showCalendarError = true }
            }
        }
    }
    
    @available(iOS 17.0, *)
    private func requestCalendarAccessIOS17(store: EKEventStore) async throws -> Bool {
        try await store.requestFullAccessToEvents()
    }
    
    private func requestCalendarAccessLegacy(store: EKEventStore) async -> Bool {
        return await withCheckedContinuation { continuation in
            let authStatus = EKEventStore.authorizationStatus(for: .event)
            
            switch authStatus {
            case .authorized:
                continuation.resume(returning: true)
                
            case .notDetermined:
                #if os(iOS)
                if #available(iOS 17.0, *) {
                    // Forward to the iOS 17 method, even though we shouldn't reach here
                    Task {
                        do {
                            let granted = try await store.requestFullAccessToEvents()
                            continuation.resume(returning: granted)
                        } catch {
                            continuation.resume(returning: false)
                        }
                    }
                } else {
                    // Legacy approach for iOS < 17
                    store.requestAccess(to: .event) { granted, _ in
                        continuation.resume(returning: granted)
                    }
                }
                #else
                store.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
                #endif
                
            case .denied, .restricted:
                continuation.resume(returning: false)
                
            @unknown default:
                continuation.resume(returning: false)
            }
        }
    }
    
    private func createCalendarEvent(event: StudyEvent, eventStore: EKEventStore) async {
        let calendarEvent = EKEvent(eventStore: eventStore)
        calendarEvent.title = event.title
        calendarEvent.startDate = event.time
        calendarEvent.endDate = event.endTime
        calendarEvent.notes = event.description ?? ""
        calendarEvent.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(calendarEvent, span: .thisEvent)
        } catch {
            await MainActor.run { showCalendarError = true }
        }
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else { return }
        UIApplication.shared.open(settingsUrl)
    }
}

// MARK: - Header Section
extension EventDetailView {
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Back")
                
                Spacer()
                
                Text(localEvent.eventType.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            Text(localEvent.title)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.brandPrimary, Color.brandPrimary]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(radius: 4)
    }
}

// MARK: - Event Header Card - ContentView Style
extension EventDetailView {
    private var eventHeaderCard: some View {
        VStack(spacing: 20) {
            // Event Title with enhanced styling
            VStack(spacing: 12) {
                HStack {
                    // Event Type Icon with gradient background
                    Image(systemName: eventTypeIcon)
                        .font(.system(size: 24))
                        .foregroundColor(.textLight)
                        .frame(width: 48, height: 48)
                        .background(
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [eventTypeColor, eventTypeColor.opacity(0.85)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: eventTypeColor.opacity(0.25), radius: 8, x: 0, y: 4)
                                
                                // Subtle inner highlight
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.6), .clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                                    .frame(width: 46, height: 46)
                            }
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localEvent.title)
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        Text(localEvent.eventType.displayName)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                }
                
                // Event Status Badge
                HStack {
                    if isHosting {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundColor(.textLight)
                            Text("Hosting")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.textLight)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.brandWarning)
                                .shadow(color: Color.brandWarning.opacity(0.25), radius: 4, x: 0, y: 2)
                        )
                    } else if isAttending {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.textLight)
                            Text("Attending")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.textLight)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.brandPrimary)
                                .shadow(color: Color.brandPrimary.opacity(0.25), radius: 4, x: 0, y: 2)
                        )
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
        .onAppear {
            // Resolve human-readable address for the event coordinate
            let coordinate = localEvent.coordinate
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first {
                    let parts: [String] = [
                        placemark.name,
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.postalCode,
                        placemark.country
                    ].compactMap { $0 }.filter { !$0.isEmpty }
                    if !parts.isEmpty {
                        resolvedAddress = parts.joined(separator: ", ")
                    }
                }
            }
        }
    }
    
    // MARK: - Event Details Card
    private var eventDetailsCard: some View {
        VStack(spacing: 20) {
            // Time Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.textLight)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.brandPrimary)
                                .shadow(color: Color.brandPrimary.opacity(0.25), radius: 4, x: 0, y: 2)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Event Schedule")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.textPrimary)
                        
                        Text("Start: \(localEvent.time.formatted(date: .abbreviated, time: .shortened))")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        
                        Text("End: \(localEvent.endTime.formatted(date: .abbreviated, time: .shortened))")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                }
            }
            
            // Host Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    UserProfileImageView(username: localEvent.host, size: 40, borderColor: Color.brandSecondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Event Host")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.textPrimary)
                        
                        HStack(spacing: 6) {
                            Text(localEvent.host)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.textPrimary)
                            
                            if localEvent.hostIsCertified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundColor(.textLight)
                                    .padding(2)
                                    .background(
                                        Circle()
                                            .fill(Color.brandPrimary)
                                    )
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            
            // Address Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 20))
                        .foregroundColor(.textLight)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.brandPrimary)
                                .shadow(color: Color.brandPrimary.opacity(0.25), radius: 4, x: 0, y: 2)
                        )
                    
                    Text("Location")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    if let address = resolvedAddress {
                        Text(address)
                            .font(.body)
                            .foregroundColor(.textPrimary)
                    } else {
                        // Fallback while resolving
                        Text(String(format: "Lat: %.5f, Lon: %.5f", localEvent.coordinate.latitude, localEvent.coordinate.longitude))
                            .font(.footnote)
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.leading, 52)
            }
            
            // Description Section
            if let description = localEvent.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 20))
                            .foregroundColor(.textLight)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.brandPrimary)
                                    .shadow(color: Color.brandPrimary.opacity(0.25), radius: 4, x: 0, y: 2)
                            )
                        
                        Text("Description")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                    }
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 52)
                }
            }
            
            // Auto-matching section
            if localEvent.isAutoMatched ?? false {
                autoMatchingSection
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Auto-matching Section
    private var autoMatchingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(.textLight)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.brandSuccess)
                            .shadow(color: Color.brandSuccess.opacity(0.25), radius: 4, x: 0, y: 2)
                    )
                
                        Text("Auto-Matched Event")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        Button(action: {
                            fetchEventTags()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        .foregroundColor(.textLight)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.brandPrimary)
                        )
                }
                    }
                    
                    Text("This event uses interest matching to connect people with similar interests.")
                        .font(.subheadline)
                .foregroundColor(.textSecondary)
                .padding(.leading, 52)
                    
                    if let tags = localEvent.interestTags, !tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Interest Tags")
                                    .font(.caption.weight(.bold))
                            .foregroundColor(.textSecondary)
                                
                                Spacer()
                                
                                Text("\(tags.count) tags")
                                    .font(.caption)
                            .foregroundColor(.textMuted)
                            }
                    .padding(.leading, 52)
                            
                    FlowLayout(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                        .fill(Color.brandPrimary.opacity(0.1))
                                        )
                                        .overlay(
                                            Capsule()
                                        .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
                                        )
                                        .foregroundColor(Color.brandPrimary)
                        }
                    }
                    .padding(.leading, 52)
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    private var eventTypeIcon: String {
        switch localEvent.eventType {
        case .study: return "book.fill"
        case .party: return "party.popper.fill"
        case .business: return "briefcase.fill"
        case .cultural: return "theatermasks.fill"
        case .academic: return "graduationcap.fill"
        case .networking: return "person.2.fill"
        case .social: return "heart.fill"
        case .language_exchange: return "globe"
        case .other: return "calendar"
        }
    }
    
    private var eventTypeColor: Color {
        switch localEvent.eventType {
        case .study: return Color.brandPrimary
        case .party: return Color.brandWarning
        case .business: return Color.brandSecondary
        case .cultural: return Color.brandWarning
        case .academic: return Color.brandSuccess
        case .networking: return Color.brandPrimary
        case .social: return Color.brandSuccess
        case .language_exchange: return Color.brandSecondary
        case .other: return Color.textSecondary
        }
    }
    
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Schedule")
                .font(.caption.weight(.bold))
                .foregroundColor(Color.textSecondary)
            
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Color.brandPrimary)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start Time")
                            .font(.caption)
                            .foregroundColor(Color.textMuted)
                        Text(localEvent.time.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(Color.textPrimary)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "clock.badge.checkmark.fill")
                        .foregroundColor(Color.brandPrimary)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("End Time")
                            .font(.caption)
                            .foregroundColor(Color.textMuted)
                        Text(localEvent.endTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(Color.textPrimary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color.bgCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    private var hostSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Host")
                .font(.caption.weight(.bold))
                .foregroundColor(Color.textSecondary)
            
            HStack(spacing: 12) {
                UserProfileImageView(username: localEvent.host, size: 30, borderColor: Color.brandPrimary)
                
                VStack(alignment: .leading, spacing: 2) {
                Text(localEvent.host)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.textPrimary)
                
                    HStack(spacing: 4) {
                if localEvent.hostIsCertified {
                    Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(Color.brandPrimary)
                        .font(.caption)
                            Text("Verified Host")
                                .font(.caption)
                                .foregroundColor(Color.brandPrimary)
                        } else {
                            Text("Host")
                                .font(.caption)
                                .foregroundColor(Color.textMuted)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.bgCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Attendees Card
extension EventDetailView {
    private var attendeesCard: some View {
        VStack(spacing: 20) {
            // Header with icon - ContentView style
                HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.textLight)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.brandPrimary)
                            .shadow(color: Color.brandPrimary.opacity(0.25), radius: 4, x: 0, y: 2)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Event Attendees")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("\(localEvent.attendees.count) attending")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                    
                    Spacer()
                    
                // Host badge if user is hosting
                    if isHosting {
                    HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                            .foregroundColor(.textLight)
                            Text("Host")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.textLight)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.brandWarning)
                            .shadow(color: Color.brandWarning.opacity(0.25), radius: 4, x: 0, y: 2)
                    )
                }
            }
            
            // Host Section
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.textLight)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.brandWarning)
                            .shadow(color: Color.brandWarning.opacity(0.25), radius: 4, x: 0, y: 2)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(localEvent.host)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.textPrimary)
                        
                        if localEvent.hostIsCertified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.textLight)
                                .padding(2)
                                .background(
                                    Circle()
                                        .fill(Color.brandPrimary)
                                )
                        }
                    }
                    
                    Text("Event Host")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cardStroke, lineWidth: 1)
                    )
            )
            
            // Attendees List - Better readability
            if !localEvent.attendees.isEmpty {
                VStack(spacing: 12) {
                            ForEach(Array(localEvent.attendees.enumerated()), id: \.offset) { index, attendee in
                        Button(action: {
                            selectedUserProfile = attendee
                            showUserProfileSheet = true
                        }) {
                            HStack(spacing: 12) {
                                // Profile Picture
                                UserProfileImageView(username: attendee, size: 50, borderColor: Color.brandPrimary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text(attendee)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.textPrimary)
                                            .lineLimit(1)
                                        
                                        if attendee == localEvent.host {
                                            HStack(spacing: 4) {
                                            Image(systemName: "crown.fill")
                                                .font(.caption2)
                                                    .foregroundColor(.textLight)
                                                Text("Host")
                                                    .font(.caption2.weight(.semibold))
                                                    .foregroundColor(.textLight)
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(
                                                Capsule()
                                                    .fill(Color.brandWarning)
                                            )
                                        }
                                        
                                        if localEvent.hostIsCertified && attendee == localEvent.host {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.caption)
                                                .foregroundColor(.textLight)
                                                .padding(2)
                                                .background(
                                                    Circle()
                                                        .fill(Color.brandPrimary)
                                                )
                                        }
                                    }
                                    
                                    Text("Tap to view profile")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                                
                                Spacer()
                                
                                // Action buttons
                                HStack(spacing: 8) {
                                    // Rate button (if event completed and not self)
                                    if attendee != accountManager.currentUser, isEventCompleted {
                                        Button(action: {
                                            selectedUserToRate = attendee
                                            showRateUserSheet = true
                                        }) {
                                        Image(systemName: "star")
                                            .font(.system(size: 20))
                                            .foregroundColor(.brandWarning)
                                    }
                                    }
                                    
                                    // Chevron to indicate clickable
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.textMuted)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle()) // Prevent default button styling
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.bgCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.cardStroke, lineWidth: 1)
                                )
                        )
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.textMuted)
                    
                    Text("No attendees yet")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.textSecondary)
                    
                    Text("Be the first to join this event!")
                        .font(.caption)
                        .foregroundColor(.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                }
                
                // Host management section
                if canManageAttendance {
                    hostManagementSection
                }
            }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
        .id(attendanceStateChanged)
    }
    
    private var hostManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .background(Color.cardStroke)
            
            Text("Host Management")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.textPrimary)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(Color.brandPrimary)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                    Text("Manage Attendance")
                            .font(.subheadline)
                        .fontWeight(.medium)
                            .foregroundColor(Color.textPrimary)
                        
                    Text("\(localEvent.attendees.count) attending")
                            .font(.caption)
                        .foregroundColor(Color.textSecondary)
                    }
                    
                    Spacer()
                }
                
                Text("As the host, you're automatically marked as attending. You can manage your event and invite others.")
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.leading)
                
                // Quick actions for hosts
                HStack(spacing: 12) {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption)
                            Text("Share Event")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.brandPrimary)
                        .cornerRadius(10)
                    }
                    
                    Spacer()
                }
            }
            .padding(.top, 8)
        }
    }
    
    // Helper to determine if an event has completed
    private var isEventCompleted: Bool {
        return localEvent.endTime < Date()
    }
}

// MARK: - Action Buttons Card - ContentView Style
extension EventDetailView {
    private var actionButtonsCard: some View {
        VStack(spacing: 20) {
            // Header with icon
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.textLight)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.brandSecondary)
                            .shadow(color: Color.brandSecondary.opacity(0.25), radius: 4, x: 0, y: 2)
                    )
                
                Text("Event Actions")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            // Action Buttons Grid
            VStack(spacing: 16) {
                // Main Action Button (Join/Leave/Hosting)
            joinLeaveButton
            
                // Secondary Actions Row
                HStack(spacing: 12) {
                    // Group Chat Button
                    groupChatButton
                }
                
                // Third Row
                HStack(spacing: 12) {
                    // Edit Button (if hosting)
            if isHosting && !isEventCompleted {
                        editEventButton
                    }
                    
                    // Report Button (if not hosting)
                    if !isHosting {
                        reportEventButton
                    }
                }
                
                // Rating Button (if event completed)
            if isEventCompleted && localEvent.attendees.contains(where: { $0 == accountManager.currentUser }) {
                    rateAttendeesButton
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Individual Action Buttons
    private var joinLeaveButton: some View {
        Button {
            handleRSVP()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isHosting ? "crown.fill" : (isAttending ? "xmark.circle.fill" : "checkmark.circle.fill"))
                    .font(.system(size: 20))
                    .foregroundColor(.textLight)
                
                Text(isHosting ? "Hosting Event" : (isAttending ? "Leave Event" : "Join Event"))
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.textLight)
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                isHosting ? Color.brandWarning : (isAttending ? Color.brandWarning : Color.brandSuccess),
                                isHosting ? Color.brandWarning.opacity(0.85) : (isAttending ? Color.brandWarning.opacity(0.85) : Color.brandSuccess.opacity(0.85))
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: (isHosting ? Color.brandWarning : (isAttending ? Color.brandWarning : Color.brandSuccess)).opacity(0.25), radius: 8, x: 0, y: 4)
            )
        }
        .disabled(isHosting)
        .id(attendanceStateChanged)
    }
    
    private var groupChatButton: some View {
        NavigationLink {
            GroupChatView(
                eventID: localEvent.id,
                currentUser: accountManager.currentUser ?? "Guest",
                eventTitle: localEvent.title
            )
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.textLight)
                
                Text("Group Chat")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.textLight)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brandPrimary)
                    .shadow(color: Color.brandPrimary.opacity(0.25), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    // Removed Show on Map button per user request
    
    private var editEventButton: some View {
        Button(action: { showEditSheet = true }) {
            HStack(spacing: 8) {
                Image(systemName: "pencil")
                    .font(.system(size: 16))
                    .foregroundColor(.textLight)
                
                Text("Edit Event")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.textLight)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brandPrimary)
                    .shadow(color: Color.brandPrimary.opacity(0.25), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    private var reportEventButton: some View {
        Button(action: { showEventReportSheet = true }) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 16))
                    .foregroundColor(.textLight)
                
                Text("Report")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.textLight)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brandWarning)
                    .shadow(color: Color.brandWarning.opacity(0.25), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    private var rateAttendeesButton: some View {
        Button(action: {
            showRateUserSheet = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.textLight)
                
                Text("Rate Attendees")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.textLight)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brandSuccess)
                    .shadow(color: Color.brandSuccess.opacity(0.25), radius: 4, x: 0, y: 2)
            )
        }
        .disabled(localEvent.attendees.count <= 1)
    }
    
    
    // MARK: - Social Feed Card
    private var socialFeedCard: some View {
        VStack(spacing: 20) {
            // Header with icon
            HStack {
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.textLight)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.brandPrimary)
                            .shadow(color: Color.brandPrimary.opacity(0.25), radius: 4, x: 0, y: 2)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Social Feed")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Share your experience")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
            }
            
            // Social Feed Actions
            VStack(spacing: 12) {
                // View Feed Button
                Button(action: {
                    showInteractions = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.textLight)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Comments & Posts")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.textLight)
                            
                            Text("Join the conversation")
                                .font(.caption)
                                .foregroundColor(.textLight.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14))
                            .foregroundColor(.textLight)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.brandPrimary)
                            .shadow(color: Color.brandPrimary.opacity(0.25), radius: 4, x: 0, y: 2)
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    private func handleRSVP() {
        
        // Immediately update the local event's attendees list
        let currentUser = accountManager.currentUser ?? ""
        if isAttending {
            // User is attending and wants to un-RSVP
            if let index = localEvent.attendees.firstIndex(of: currentUser) {
                localEvent.attendees.remove(at: index)
                
                // Store RSVP status in UserDefaults for this event
                let key = "event_rsvp_\(localEvent.id.uuidString)_\(currentUser)"
                UserDefaults.standard.set(false, forKey: key)
            }
        } else {
            // User is not attending and wants to RSVP
            if !localEvent.attendees.contains(currentUser) {
                localEvent.attendees.append(currentUser)
                
                // Store RSVP status in UserDefaults for this event
                let key = "event_rsvp_\(localEvent.id.uuidString)_\(currentUser)"
                UserDefaults.standard.set(true, forKey: key)
            }
        }
        
        // Toggle the state to refresh the UI
        attendanceStateChanged = UUID()
        
        // Call onRSVP immediately
        onRSVP(localEvent.id)
        
        // Update the studyEvents array with our local event
        if let eventIndex = studyEvents.firstIndex(where: { $0.id == localEvent.id }) {
            studyEvents[eventIndex] = localEvent
        }
        
        // Post a single notification instead of relying on multiple cascading updates
        // Use a delay to give the backend a chance to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(
                name: NSNotification.Name("EventRSVPUpdated"),
                object: nil,
                userInfo: ["eventID": self.localEvent.id]
            )
        }
    }
}

// MARK: - Event Social Feed View
struct EventSocialFeedView: View {
    // MARK: - Properties
    @EnvironmentObject var accountManager: UserAccountManager
    @Environment(\.dismiss) var dismiss
    var event: StudyEvent
    
    // MARK: - State
    @State private var interactions: EventInteractions?
    @State private var newPostText: String = ""
    @State private var selectedImages: [UIImage] = []
    @State private var isShowingImagePicker = false
    @State private var showingFullPost: EventInteractions.Post?
    @State private var isRefreshing = false
    @State private var errorMessage: String?
    // Track posts with like requests in flight to prevent double taps
    @State private var inFlightLikePostIds: Set<Int> = []
    // Force UI refresh when interactions change
    @State private var refreshTrigger: Int = 0
    
    // MARK: - View Body
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            createPostSection
            
            feedStats
            
            postsListView
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .sheet(isPresented: $isShowingImagePicker) {
            SocialImagePicker(selectedImages: $selectedImages, maxSelection: 4)
        }
        .sheet(item: $showingFullPost) { post in
            PostDetailView(
                post: post,
                onLike: { likePost(postID: post.id) },
                onReply: { text in
                    replyToPost(postID: post.id, text: text)
                    // Update the sheet's post to reflect the new reply
                    if var updatedPost = showingFullPost {
                        let optimisticReply = EventInteractions.Post(
                            id: Int.random(in: 9000...10000),
                            text: text,
                            username: accountManager.currentUser ?? "Guest",
                            created_at: Date().ISO8601Format(),
                            imageURLs: nil,
                            likes: 0,
                            isLikedByCurrentUser: false,
                            replies: []
                        )
                        updatedPost.replies.append(optimisticReply)
                        showingFullPost = updatedPost
                    }
                }
            )
            .environmentObject(accountManager)
        }
        .overlay(
            errorView
        )
        .onAppear { fetchInteractions() }
    }
    
    // MARK: - UI Components
    
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(Color.textPrimary)
                    .padding(8)
                    .background(Color.bgCard.opacity(0.8))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close")
            
            Spacer()
            
            Text(event.title)
                .font(.headline)
                .lineLimit(1)
                .foregroundColor(Color.black)
            
            Spacer()
            
            Button {
                refreshFeed()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(Color.textPrimary)
                    .padding(8)
                    .background(Color.bgCard.opacity(0.8))
                    .clipShape(Circle())
            }
            .disabled(isRefreshing)
            .accessibilityLabel("Refresh")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.white)
    }
    
    private var createPostSection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                // Profile Image
                UserProfileImageView(username: accountManager.currentUser ?? "Guest", size: 40, borderColor: .blue)
                
                // Text input and controls
                VStack(alignment: .leading, spacing: 10) {
                    ZStack(alignment: .topLeading) {
                        if newPostText.isEmpty {
                            Text("What's happening at this event?")
                                .foregroundColor(Color.gray.opacity(0.5))
                                .allowsHitTesting(false)
                        }
                        TextField("", text: $newPostText, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(Color.black)
                            .tint(.brandPrimary)
                    }
                    
                    // Image preview grid
                    if !selectedImages.isEmpty {
                        imagePreviewGrid
                    }
                    
                    HStack {
                        // Image attachment button
                        Button {
                            isShowingImagePicker = true
                        } label: {
                            Image(systemName: "photo")
                                .foregroundColor(Color.brandPrimary)
                                .font(.title3)
                        }
                        .accessibilityLabel("Add Photos")
                        
                        Spacer()
                        
                        // Character count
                        Text("\(280 - newPostText.count)")
                            .font(.caption)
                            .foregroundColor(characterCountColor)
                        
                        // Post button
                        Button {
                            addPost()
                        } label: {
                            Text("Post")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 16)
                                .background(isPostButtonEnabled ? Color.brandPrimary : Color.textMuted)
                                .cornerRadius(16)
                        }
                        .disabled(!isPostButtonEnabled)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color.white)
    }
    
    private var imagePreviewGrid: some View {
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
        return LazyVGrid(columns: columns, spacing: 5) {
            ForEach(0..<selectedImages.count, id: \.self) { index in
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: selectedImages[index])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    Button {
                        removeImage(at: index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .shadow(radius: 1)
                            .padding(5)
                    }
                    .accessibilityLabel("Remove image")
                }
            }
        }
    }
    
    private var feedStats: some View {
        VStack {
            Divider().padding(.vertical, 8)
            
            HStack(spacing: 20) {
                Label("\(interactions?.posts.count ?? 0) Posts", systemImage: "text.bubble")
                    .font(.subheadline)
                    .foregroundColor(Color.black)
                Label("\(interactions?.likes.total ?? 0) Likes", systemImage: "heart")
                    .font(.subheadline)
                    .foregroundColor(Color.black)
                Label("\(interactions?.shares.total ?? 0) Shares", systemImage: "square.and.arrow.up")
                    .font(.subheadline)
                    .foregroundColor(Color.black)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color.white)
    }
    
    private var postsListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if let interactions = interactions {
                    if interactions.posts.isEmpty {
                        emptyFeedView
                    } else {
                        ForEach(interactions.posts) { post in
                            EventPostView(
                                post: post,
                                onLike: {
                                    guard !inFlightLikePostIds.contains(post.id) else { return }
                                    inFlightLikePostIds.insert(post.id)
                                    likePost(postID: post.id)
                                },
                                onReply: { showReplySheet(for: post) }
                            )
                            .id("\(post.id)-\(post.likes)-\(post.isLikedByCurrentUser)-\(refreshTrigger)")
                            .padding(.bottom, 1)
                        }
                    }
                } else {
                    loadingView
                }
            }
            .padding(.bottom, 20)
        }
        .refreshable {
            await refreshWithDelay()
        }
    }
    
    private var emptyFeedView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            Text("Be the first to post about this event!")
                .font(.title3)
                .foregroundColor(Color.black)
            Spacer()
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Loading event feed...")
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(height: 300)
    }
    
    private var errorView: some View {
        Group {
            if let errorMessage = errorMessage {
                VStack {
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .padding()
                    
                    Button("Dismiss") {
                        self.errorMessage = nil
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
                .transition(.move(edge: .top))
                .zIndex(1)
            } else {
                EmptyView()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isPostButtonEnabled: Bool {
        !newPostText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var characterCountColor: Color {
        if newPostText.count > 260 {
            return newPostText.count > 280 ? Color.textMuted : Color.brandPrimary
        } else {
            return Color.textMuted
        }
    }
    
    // MARK: - Actions
    
    private func refreshWithDelay() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        refreshFeed()
        isRefreshing = false
    }
    
    private func removeImage(at index: Int) {
        selectedImages.remove(at: index)
    }
    
    // MARK: - Networking Functions
    

    // MARK: - Networking Functions for EventSocialFeedView
        
    private func fetchInteractions() {
        // Load real interactions from backend
        
        // Real API call
        guard let url = URL(string: "\(APIConfig.primaryBaseURL)/events/feed/\(event.id.uuidString)/") else {
            self.errorMessage = "Invalid URL"
            return
        }
        
        let currentUser = accountManager.currentUser ?? ""
        var finalUrl = url
        
        // Add current user as query parameter if available
        if !currentUser.isEmpty {
            if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                var queryItems = components.queryItems ?? []
                queryItems.append(URLQueryItem(name: "current_user", value: currentUser))
                components.queryItems = queryItems
                
                if let updatedUrl = components.url {
                    finalUrl = updatedUrl
                }
            }
        }
        
        // Check if we've already encountered a 403 error for this event (add this property to the class)
        // This prevents endless retries when a user doesn't have access
        if let lastForbiddenEventId = UserDefaults.standard.string(forKey: "lastForbiddenEventId"),
           lastForbiddenEventId == event.id.uuidString {
            // User previously got a 403 for this event, show appropriate message instead of retrying
            self.errorMessage = "You don't have access to this event's social feed."
            return
        }
        
        var request = URLRequest(url: finalUrl)
        accountManager.addAuthHeader(to: &request)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid response"
                    return
                }
                
                // Handle 403 Forbidden specifically - indicates user doesn't have access
                if httpResponse.statusCode == 403 {
                    // Remember that this event gave a 403 to prevent future requests
                    UserDefaults.standard.set(self.event.id.uuidString, forKey: "lastForbiddenEventId")
                    self.errorMessage = "You don't have access to this event's social feed."
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    self.errorMessage = "Server error: \(httpResponse.statusCode)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(EventInteractions.self, from: data)
                    self.interactions = decoded
                    // Merge any locally cached like states to avoid resetting to 0
                    self.mergeLikesWithCache()
                } catch {
                    self.errorMessage = "Failed to decode data: \(error.localizedDescription)"
                    
                    // Print the received data for debugging
                    if let dataString = String(data: data, encoding: .utf8) {
                    }
                }
            }
        }.resume()
    }

    
    
    private func refreshFeed() {
        fetchInteractions()
    }

    // MARK: - Like Cache (persists per-post likes across view reloads)
    private struct LikeCacheEntry: Codable {
        var likes: Int
        var isLiked: Bool
    }

    private func likeCacheKey() -> String {
        return "like_cache_\(event.id.uuidString)"
    }

    private func loadLikeCache() -> [Int: LikeCacheEntry] {
        let key = likeCacheKey()
        guard let data = UserDefaults.standard.data(forKey: key) else { return [:] }
        if let decoded = try? JSONDecoder().decode([String: LikeCacheEntry].self, from: data) {
            var byInt: [Int: LikeCacheEntry] = [:]
            for (k,v) in decoded { if let id = Int(k) { byInt[id] = v } }
            return byInt
        }
        return [:]
    }

    private func saveLikeCache(_ cache: [Int: LikeCacheEntry]) {
        var byString: [String: LikeCacheEntry] = [:]
        for (k,v) in cache { byString[String(k)] = v }
        if let data = try? JSONEncoder().encode(byString) {
            UserDefaults.standard.set(data, forKey: likeCacheKey())
        }
    }

    private func updateLikeCache(postID: Int, likes: Int, isLiked: Bool) {
        var cache = loadLikeCache()
        cache[postID] = LikeCacheEntry(likes: likes, isLiked: isLiked)
        saveLikeCache(cache)
    }

    private func mergeLikesWithCache() {
        guard var current = interactions else { return }
        let cache = loadLikeCache()
        current.posts = mergePostsWithCache(current.posts, cache: cache)
        interactions = current
    }

    private func mergePostsWithCache(_ posts: [EventInteractions.Post], cache: [Int: LikeCacheEntry]) -> [EventInteractions.Post] {
        var updated = posts
        for i in 0..<updated.count {
            let id = updated[i].id
            if let entry = cache[id] {
                if entry.likes > updated[i].likes { updated[i].likes = entry.likes }
                updated[i].isLikedByCurrentUser = entry.isLiked
            }
            if !updated[i].replies.isEmpty {
                updated[i].replies = mergePostsWithCache(updated[i].replies, cache: cache)
            }
        }
        return updated
    }
    
   
    // MARK: - Update the addPost function

    private func addPost() {
        
        guard isPostButtonEnabled else { 
            return 
        }
        
        // Show loading state
        _ = "Posting..." // Loading message available for future use if needed
        errorMessage = nil
        isRefreshing = true
        
        // API endpoint
        let urlString = "\(APIConfig.primaryBaseURL)/events/comment/"
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid API URL"
            isRefreshing = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Add JWT auth header once
        accountManager.addAuthHeader(to: &request)
        
        // Helper function to create and send post with given image URLs
        func createAndSendPost(withImageURLs imageURLs: [String]) {
            let username = accountManager.currentUser ?? "Guest"
            
            let postData: [String: Any] = [
                "username": username,
                "event_id": event.id.uuidString,
                "text": newPostText,
                "image_urls": imageURLs.isEmpty ? [] : imageURLs
            ]
            
            // Convert to JSON
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: postData)
            } catch {
                self.errorMessage = "Failed to encode post data: \(error.localizedDescription)"
                self.isRefreshing = false
                return
            }
            
            // Create a local copy of post while waiting for response
            let imageURLsOptional: [String]? = imageURLs.isEmpty ? nil : imageURLs
            let optimisticPost = EventInteractions.Post(
                id: Int.random(in: 9000...10000),  // Temporary ID that will be replaced
                text: newPostText,
                username: username,
                created_at: Date().ISO8601Format(),
                imageURLs: imageURLsOptional,
                likes: 0,
                isLikedByCurrentUser: false,
                replies: []
            )
            
            // Immediately update UI with optimistic post
            if var currentInteractions = self.interactions {
                currentInteractions.posts.insert(optimisticPost, at: 0)
                self.interactions = currentInteractions
            } else {
                // Create new interactions object if none exists
                self.interactions = EventInteractions(
                    posts: [optimisticPost],
                    likes: EventInteractions.Likes(total: 0, users: []),
                    shares: EventInteractions.Shares(total: 0, breakdown: [:])
                )
            }
            
            // Clear input immediately for good UX
            let savedText = newPostText
            let savedImages = self.selectedImages
            self.newPostText = ""
            self.selectedImages = []
            
            // Make API request
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    self.isRefreshing = false
                    
                    if let error = error {
                        self.errorMessage = "Failed to create post: \(error.localizedDescription)"
                        // Revert optimistic update on failure
                        if var current = self.interactions {
                            current.posts.removeAll { $0.id == optimisticPost.id }
                            self.interactions = current
                        }
                        // Restore input
                        self.newPostText = savedText
                        self.selectedImages = savedImages
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        self.errorMessage = "Invalid server response"
                        return
                    }
                    
                    if !(200...299).contains(httpResponse.statusCode) {
                        if httpResponse.statusCode == 401 {
                            // Try refreshing token and retry once
                            Task { @MainActor in
                                let refreshed = await self.accountManager.refreshAccessToken()
                                if refreshed {
                                    var retryReq = URLRequest(url: url)
                                    retryReq.httpMethod = "POST"
                                    retryReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
                                    self.accountManager.addAuthHeader(to: &retryReq)
                                    retryReq.httpBody = request.httpBody
                                    URLSession.shared.dataTask(with: retryReq) { data, response, error in
                                        DispatchQueue.main.async {
                                            guard let httpResp = response as? HTTPURLResponse else { return }
                                            if !(200...299).contains(httpResp.statusCode) {
                                                // Revert optimistic update on hard failure
                                                if var current = self.interactions {
                                                    current.posts.removeAll { $0.id == optimisticPost.id }
                                                    self.interactions = current
                                                }
                                                self.errorMessage = "Server error: \(httpResp.statusCode)"
                                                // Restore input
                                                self.newPostText = savedText
                                                self.selectedImages = savedImages
                                                return
                                            }
                                            // Success after refresh - parse response and update optimistic post
                                            if let data = data,
                                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                                               let postData = json["post"] as? [String: Any],
                                               let realID = postData["id"] as? Int {
                                                // Update optimistic post with real ID
                                                if var currentInteractions = self.interactions {
                                                    for i in 0..<currentInteractions.posts.count {
                                                        if currentInteractions.posts[i].id == optimisticPost.id {
                                                            currentInteractions.posts[i] = EventInteractions.Post(
                                                                id: realID,
                                                                text: currentInteractions.posts[i].text,
                                                                username: currentInteractions.posts[i].username,
                                                                created_at: currentInteractions.posts[i].created_at,
                                                                imageURLs: currentInteractions.posts[i].imageURLs,
                                                                likes: 0,
                                                                isLikedByCurrentUser: false,
                                                                replies: []
                                                            )
                                                            break
                                                        }
                                                    }
                                                    self.interactions = currentInteractions
                                                }
                                            }
                                        }
                                    }.resume()
                                } else {
                                    // Refresh failed: revert optimistic update
                                    if var current = self.interactions {
                                        current.posts.removeAll { $0.id == optimisticPost.id }
                                        self.interactions = current
                                    }
                                    self.errorMessage = "Session expired. Please log in again."
                                    // Restore input
                                    self.newPostText = savedText
                                    self.selectedImages = savedImages
                                }
                            }
                            return
                        } else {
                            self.errorMessage = "Server error: \(httpResponse.statusCode)"
                            // Revert optimistic update on failure
                            if var current = self.interactions {
                                current.posts.removeAll { $0.id == optimisticPost.id }
                                self.interactions = current
                            }
                            // Restore input
                            self.newPostText = savedText
                            self.selectedImages = savedImages
                            return
                        }
                    }
                    
                    // Post created successfully - parse response and update optimistic post with real ID
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let postData = json["post"] as? [String: Any],
                       let realID = postData["id"] as? Int {
                        // Update optimistic post with real ID
                        if var currentInteractions = self.interactions {
                            for i in 0..<currentInteractions.posts.count {
                                if currentInteractions.posts[i].id == optimisticPost.id {
                                    // Replace optimistic ID with real ID
                                    currentInteractions.posts[i] = EventInteractions.Post(
                                        id: realID,
                                        text: currentInteractions.posts[i].text,
                                        username: currentInteractions.posts[i].username,
                                        created_at: currentInteractions.posts[i].created_at,
                                        imageURLs: currentInteractions.posts[i].imageURLs,
                                        likes: 0,
                                        isLikedByCurrentUser: false,
                                        replies: []
                                    )
                                    break
                                }
                            }
                            self.interactions = currentInteractions
                        }
                    }
                }
            }.resume()
        }
        
        // 1) Upload images to backend to get R2 URLs (async)
        if !selectedImages.isEmpty {
            var uploadedURLs: [String] = []
            let dispatchGroup = DispatchGroup()
            for img in selectedImages {
                dispatchGroup.enter()
                if let jpegData = img.jpegData(compressionQuality: 0.8) {
                    let uploadURLString = "\(APIConfig.primaryBaseURL)/events/upload_image/"
                    if let uploadURL = URL(string: uploadURLString) {
                        var req = URLRequest(url: uploadURL)
                        req.httpMethod = "POST"
                        // Build simple multipart form
                        let boundary = "Boundary-\(UUID().uuidString)"
                        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                        accountManager.addAuthHeader(to: &req)
                        var body = Data()
                        func append(_ str: String) { body.append(str.data(using: .utf8)!) }
                        append("--\(boundary)\r\n")
                        append("Content-Disposition: form-data; name=\"event_id\"\r\n\r\n")
                        append("\(event.id.uuidString)\r\n")
                        append("--\(boundary)\r\n")
                        append("Content-Disposition: form-data; name=\"image\"; filename=\"post.jpg\"\r\n")
                        append("Content-Type: image/jpeg\r\n\r\n")
                        body.append(jpegData)
                        append("\r\n--\(boundary)--\r\n")
                        req.httpBody = body
                        URLSession.shared.dataTask(with: req) { data, response, error in
                            defer { dispatchGroup.leave() }
                            guard error == nil, let data = data,
                                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                                  let url = json["url"] as? String else { return }
                            uploadedURLs.append(url)
                        }.resume()
                    } else {
                        dispatchGroup.leave()
                    }
                } else {
                    dispatchGroup.leave()
                }
            }
            
            // When all uploads finish, create and send post
            dispatchGroup.notify(queue: .main) {
                createAndSendPost(withImageURLs: uploadedURLs)
            }
        } else {
            // No images: proceed immediately
            createAndSendPost(withImageURLs: [])
        }
    }
    // Updated helper function to set likes count from server response
    func updatePostLikeCount(posts: [EventInteractions.Post], postID: Int, newCount: Int, isLiked: Bool) -> [EventInteractions.Post] {
        var updatedPosts = posts
        
        for i in 0..<updatedPosts.count {
            if updatedPosts[i].id == postID {
                // Update with correct like count from server
                updatedPosts[i].likes = newCount
                updatedPosts[i].isLikedByCurrentUser = isLiked
                return updatedPosts
            }
            
            // Check replies
            if !updatedPosts[i].replies.isEmpty {
                let originalReplies = updatedPosts[i].replies
                updatedPosts[i].replies = updatePostLikeCount(
                    posts: originalReplies,
                    postID: postID,
                    newCount: newCount,
                    isLiked: isLiked
                )
                
                // Check if we found and updated the target post in replies
                if updatedPosts[i].replies != originalReplies {
                    return updatedPosts
                }
            }
        }
        
        return updatedPosts
    }

    
    // Enhanced likePost function with debugging and proper API call
    func likePost(postID: Int) {
        
        // Find the post to check its current state before update
        if let interactions = interactions {
            let foundPost = interactions.posts.first(where: { $0.id == postID }) ??
                            interactions.posts.flatMap { $0.replies }.first(where: { $0.id == postID })
            
            if let post = foundPost {
            } else {
            }
        }
        
        // Update local state optimistically
        if var currentInteractions = interactions {
            // Update the post and its replies recursively
            currentInteractions.posts = updateLikeStateInPosts(
                posts: currentInteractions.posts,
                postID: postID
            )
            interactions = currentInteractions
            refreshTrigger += 1  // Force UI refresh
        }
        
        // Make API call to persist the change
        guard let url = URL(string: "\(APIConfig.primaryBaseURL)/events/like/"),
              let currentUser = accountManager.currentUser else {
            self.errorMessage = "Cannot like post: Invalid user or URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header
        accountManager.addAuthHeader(to: &request)
        
        // IMPORTANT: The backend expects 'post_id' for comment likes
        let body: [String: Any] = [
            "username": currentUser,
            "event_id": event.id.uuidString,
            "post_id": postID  // This matches the backend expectation
        ]
        
        
        let bodyData: Data
        do {
            bodyData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = bodyData
        } catch {
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to like post: \(error.localizedDescription)"
                    // Revert the optimistic update if the API call fails
                    self.refreshFeed()
                    self.inFlightLikePostIds.remove(postID)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    return
                }
                
                
                if httpResponse.statusCode == 401 {
                    // Try to refresh token and retry once
                    Task { @MainActor in
                        let refreshed = await self.accountManager.refreshAccessToken()
                        if refreshed {
                            var retryReq = URLRequest(url: url)
                            retryReq.httpMethod = "POST"
                            retryReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
                            self.accountManager.addAuthHeader(to: &retryReq)
                            retryReq.httpBody = bodyData
                            URLSession.shared.dataTask(with: retryReq) { data, response, error in
                                DispatchQueue.main.async {
                                    guard let httpResp = response as? HTTPURLResponse else { return }
                                    if !(200...299).contains(httpResp.statusCode) {
                                        // Revert optimistic update on hard failure
                                        self.refreshFeed()
                                        self.inFlightLikePostIds.remove(postID)
                                        return
                                    }
                                    if let data = data {
                                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                                           let liked = json["liked"] as? Bool,
                                           let totalLikes = json["total_likes"] as? Int {
                                            if var updatedInteractions = self.interactions {
                                                updatedInteractions.posts = self.updatePostLikeCount(
                                                    posts: updatedInteractions.posts,
                                                    postID: postID,
                                                    newCount: totalLikes,
                                                    isLiked: liked
                                                )
                                                self.interactions = updatedInteractions
                                                self.updateLikeCache(postID: postID, likes: totalLikes, isLiked: liked)
                                                self.refreshTrigger += 1  // Force UI refresh
                                            }
                                            self.inFlightLikePostIds.remove(postID)
                                        }
                                    }
                                }
                            }.resume()
                        } else {
                            self.errorMessage = "Session expired. Please log in again to like posts."
                            // Revert optimistic update by refetching
                            self.refreshFeed()
                            self.inFlightLikePostIds.remove(postID)
                        }
                    }
                    return
                }

                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    
                    // Try to parse response for total_likes
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let _ = json["success"] as? Bool,
                           let liked = json["liked"] as? Bool,
                           let totalLikes = json["total_likes"] as? Int {
                            
                            
                            // Update the post with correct likes count from server
                            if var updatedInteractions = self.interactions {
                                updatedInteractions.posts = self.updatePostLikeCount(
                                    posts: updatedInteractions.posts,
                                    postID: postID,
                                    newCount: totalLikes,
                                    isLiked: liked
                                )
                                self.interactions = updatedInteractions
                                self.updateLikeCache(postID: postID, likes: totalLikes, isLiked: liked)
                                self.refreshTrigger += 1  // Force UI refresh
                            }
                            self.inFlightLikePostIds.remove(postID)
                        } else {
                            self.inFlightLikePostIds.remove(postID)
                        }
                    } catch {
                        self.inFlightLikePostIds.remove(postID)
                    }
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    self.errorMessage = "Server error: \(httpResponse.statusCode)"
                    self.refreshFeed()
                    self.inFlightLikePostIds.remove(postID)
                }
            }
        }.resume()
    }
       
       // Enhanced version of updateLikeStateInPosts with more debugging
       func updateLikeStateInPosts(posts: [EventInteractions.Post], postID: Int) -> [EventInteractions.Post] {
           var updatedPosts = posts
           
           for i in 0..<updatedPosts.count {
               if updatedPosts[i].id == postID {
                   // Toggle like state
                   let wasLiked = updatedPosts[i].isLikedByCurrentUser
                   updatedPosts[i].isLikedByCurrentUser = !wasLiked
                   updatedPosts[i].likes += wasLiked ? -1 : 1
                   
                   return updatedPosts
               }
               
               // Check replies
               if !updatedPosts[i].replies.isEmpty {
                   let originalReplies = updatedPosts[i].replies
                   updatedPosts[i].replies = updateLikeStateInPosts(posts: originalReplies, postID: postID)
                   
                   // Check if we found and updated the target post in replies
                   if updatedPosts[i].replies != originalReplies {
                       return updatedPosts
                   }
               }
           }
           
           return updatedPosts
       }
   
    
    private func showReplySheet(for post: EventInteractions.Post) {
        showingFullPost = post
    }
    
   
    private func replyToPost(postID: Int, text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Show loading state
        isRefreshing = true
        errorMessage = nil
        
        // API endpoint
        guard let url = URL(string: "\(APIConfig.primaryBaseURL)/events/comment/") else {
            errorMessage = "Invalid API URL"
            isRefreshing = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add JWT authentication header
        accountManager.addAuthHeader(to: &request)
        
        // Prepare reply data
        let username = accountManager.currentUser ?? "Guest"
        
        let replyData: [String: Any] = [
            "username": username,
            "event_id": event.id.uuidString,
            "text": text,
            "parent_id": postID
        ]
        
        // Convert to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: replyData)
        } catch {
            errorMessage = "Failed to encode reply data: \(error.localizedDescription)"
            isRefreshing = false
            return
        }
        
        // Create temporary reply for optimistic UI update
        let optimisticReply = EventInteractions.Post(
            id: Int.random(in: 9000...10000),  // Temporary ID
            text: text,
            username: username,
            created_at: Date().ISO8601Format(),
            imageURLs: nil,
            likes: 0,
            isLikedByCurrentUser: false,
            replies: []
        )
        
        // Apply optimistic update
        if var currentInteractions = interactions {
            currentInteractions.posts = addReplyToPost(
                posts: currentInteractions.posts,
                postID: postID,
                reply: optimisticReply
            )
            interactions = currentInteractions
            refreshTrigger += 1  // Force UI refresh
        }
        
        // Make API request
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isRefreshing = false
                
                if let error = error {
                    self.errorMessage = "Failed to add reply: \(error.localizedDescription)"
                    // Refresh to ensure data consistency
                    self.refreshFeed()
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid server response"
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    self.errorMessage = "Server error: \(httpResponse.statusCode)"
                    // Revert optimistic update on error
                    self.refreshFeed()
                    return
                }
                
                // Reply created successfully - parse response and update with real ID
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let postData = json["post"] as? [String: Any],
                   let realID = postData["id"] as? Int {
                    // Replace optimistic reply with real data
                    if var currentInteractions = self.interactions {
                        currentInteractions.posts = self.replaceOptimisticReply(
                            posts: currentInteractions.posts,
                            optimisticID: optimisticReply.id,
                            realID: realID,
                            replyText: text,
                            username: username
                        )
                        self.interactions = currentInteractions
                        self.refreshTrigger += 1  // Force UI refresh
                    }
                } else {
                    // If we can't parse, just refresh to be safe
                    self.refreshFeed()
                }
            }
        }.resume()
    }
    
    private func replaceOptimisticReply(posts: [EventInteractions.Post], optimisticID: Int, realID: Int, replyText: String, username: String) -> [EventInteractions.Post] {
        var updatedPosts = posts
        
        for i in 0..<updatedPosts.count {
            // Check replies of this post
            if let replyIndex = updatedPosts[i].replies.firstIndex(where: { $0.id == optimisticID }) {
                // Replace with real data
                updatedPosts[i].replies[replyIndex] = EventInteractions.Post(
                    id: realID,
                    text: replyText,
                    username: username,
                    created_at: updatedPosts[i].replies[replyIndex].created_at,
                    imageURLs: nil,
                    likes: 0,
                    isLikedByCurrentUser: false,
                    replies: []
                )
                return updatedPosts
            }
            
            // Recursively check nested replies
            if !updatedPosts[i].replies.isEmpty {
                updatedPosts[i].replies = replaceOptimisticReply(
                    posts: updatedPosts[i].replies,
                    optimisticID: optimisticID,
                    realID: realID,
                    replyText: replyText,
                    username: username
                )
            }
        }
        
        return updatedPosts
    }
    
    private func addReplyToPost(posts: [EventInteractions.Post], postID: Int, reply: EventInteractions.Post) -> [EventInteractions.Post] {
        var updatedPosts = posts
        
        for i in 0..<updatedPosts.count {
            if updatedPosts[i].id == postID {
                // Add reply to this post
                updatedPosts[i].replies.append(reply)
                return updatedPosts
            }
            
            // Check in replies
            if !updatedPosts[i].replies.isEmpty {
                updatedPosts[i].replies = addReplyToPost(
                    posts: updatedPosts[i].replies,
                    postID: postID,
                    reply: reply
                )
            }
        }
        
        return updatedPosts
    }
}

// MARK: - Post View
struct EventPostView: View {
    let post: EventInteractions.Post
    let onLike: () -> Void
    let onReply: () -> Void
    
    @State private var isAnimatingLike = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                // Profile image
                UserProfileImageView(username: post.username, size: 40, borderColor: .blue)
                
                // Post content
                VStack(alignment: .leading, spacing: 6) {
                    // User info and timestamp
                    HStack {
                        Text(post.username)
                            .font(.headline)
                            .foregroundColor(Color.textPrimary)
                        Spacer()
                        Text(formatDate(post.created_at))
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                    }
                    
                    // Post text
                    Text(post.text)
                        .font(.body)
                        .foregroundColor(Color.black)
                        .multilineTextAlignment(.leading)
                    
                    // Image grid if present
                    if let imageURLs = post.imageURLs, !imageURLs.isEmpty {
                        postImagesGrid(imageURLs: imageURLs)
                    }

                    
                    // Action buttons
                    HStack(spacing: 20) {
                        // Like button
                        Button(action: {
                            // Add haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            // Trigger animation
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                isAnimatingLike = true
                            }
                            
                            // Reset animation after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    isAnimatingLike = false
                                }
                            }
                            
                            // Call the like action
                            onLike()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                                    .foregroundColor(post.isLikedByCurrentUser ? .red : .gray)
                                    .scaleEffect(isAnimatingLike ? 1.3 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimatingLike)
                                
                                Text("\(post.likes)")
                                    .font(.caption)
                                    .foregroundColor(post.isLikedByCurrentUser ? .red : .gray)
                                    .contentTransition(.numericText())
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(post.isLikedByCurrentUser ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                            .cornerRadius(15)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: post.isLikedByCurrentUser)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: post.likes)
                        
                        // Reply button
                        Button(action: onReply) {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left")
                                    .foregroundColor(.gray)
                                Text("\(post.replies.count)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        // Share button
                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Show replies if any
                    if !post.replies.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(post.replies) { reply in
                                replyView(for: reply)
                            }
                        }
                        .padding(.top, 10)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.textMuted),
            alignment: .bottom
        )
    }
    
    private func postImagesGrid(imageURLs: [String]) -> some View {
        let columns = imageURLs.count == 1 ? [GridItem(.flexible())] : [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
        return LazyVGrid(columns: columns, spacing: 5) {
            ForEach(0..<imageURLs.count, id: \.self) { index in
                let urlString = imageURLs[index]
                let height: CGFloat = imageURLs.count == 1 ? 200 : 120
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: height)
                    
                    if let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: height)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            case .failure(_):
                                VStack(spacing: 6) {
                                    Image(systemName: "xmark.octagon")
                                        .foregroundColor(.red)
                                    Text("Image failed")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Invalid URL")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 5)
    }
    
    private func replyView(for reply: EventInteractions.Post) -> some View {
        HStack(alignment: .top, spacing: 8) {
            // Smaller profile image for replies
            UserProfileImageView(username: reply.username, size: 24, borderColor: .blue)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reply.username)
                        .font(.subheadline.bold())
                        .foregroundColor(.black)
                    Spacer()
                    Text(formatDate(reply.created_at))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Text(reply.text)
                    .font(.subheadline)
                    .foregroundColor(.black)
            }
        }
        .padding(8)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(8)
    }
    
    private func formatDate(_ dateString: String) -> String {
        // Simple date formatter that shows relative time
        // e.g., "2m" for 2 minutes ago, "5h" for 5 hours ago
        
        guard let date = ISO8601DateFormatter().date(from: dateString) else {
            return "Just now"
        }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let minutes = components.minute, minutes < 60 {
            return minutes < 1 ? "Just now" : "\(minutes)m"
        } else if let hours = components.hour, hours < 24 {
            return "\(hours)h"
        } else if let days = components.day {
            return "\(days)d"
        }
        
        return "Just now"
    }
}

// MARK: - Post Detail View
struct PostDetailView: View {
    let post: EventInteractions.Post
    let onLike: () -> Void
    let onReply: (String) -> Void
    
    // Keep a local, optimistically updated copy for immediate UI feedback
    @State private var localPost: EventInteractions.Post
    @State private var replyText = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var accountManager: UserAccountManager

    init(post: EventInteractions.Post, onLike: @escaping () -> Void, onReply: @escaping (String) -> Void) {
        self.post = post
        self.onLike = onLike
        self.onReply = onReply
        _localPost = State(initialValue: post)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                        .foregroundColor(Color.textPrimary)
                }
                .accessibilityLabel("Back")
                
                Spacer()
                
                Text("Post")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                Button {
                    // Share options
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Color.textPrimary)
                }
                .accessibilityLabel("Share Post")
            }
            .padding()
            .background(Color.white)
            
            ScrollView {
                VStack(spacing: 0) {
                    // Original post
                    EventPostView(
                        post: localPost,
                        onLike: {
                            // Optimistically toggle like state locally
                            let wasLiked = localPost.isLikedByCurrentUser
                            localPost.isLikedByCurrentUser.toggle()
                            localPost.likes += wasLiked ? -1 : 1
                            // Persist in backend / parent state
                            onLike()
                        },
                        onReply: {}
                    )
                        .padding(.bottom, 12)
                    
                    // Show replies if any
                    if !localPost.replies.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Replies (\(localPost.replies.count))")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.horizontal)
                            
                            ForEach(localPost.replies) { reply in
                                postDetailReplyView(for: reply)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    }
                    
                    Divider()
                    
                    // Reply composer
                    HStack(alignment: .top, spacing: 8) {
                        UserProfileImageView(username: accountManager.currentUser ?? "Guest", size: 30, borderColor: Color.brandPrimary)
                        
                        VStack(alignment: .trailing, spacing: 8) {
                            ZStack(alignment: .topLeading) {
                                if replyText.isEmpty {
                                    Text("Add your reply...")
                                        .foregroundColor(Color.gray.opacity(0.5))
                                        .allowsHitTesting(false)
                                }
                                TextField("", text: $replyText, axis: .vertical)
                                    .lineLimit(1...5)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .foregroundColor(Color.black)
                            }
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            
                            Button {
                                submitReply()
                            } label: {
                                Text("Reply")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(isReplyButtonEnabled ? Color.brandPrimary : Color.textMuted)
                                    .cornerRadius(16)
                            }
                            .disabled(!isReplyButtonEnabled)
                        }
                    }
                    .padding()
                }
            }
            .background(Color.white)
        }
    }
    
    private var isReplyButtonEnabled: Bool {
        !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func postDetailReplyView(for reply: EventInteractions.Post) -> some View {
        HStack(alignment: .top, spacing: 8) {
            // Smaller profile image for replies
            UserProfileImageView(username: reply.username, size: 24, borderColor: .blue)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reply.username)
                        .font(.subheadline.bold())
                        .foregroundColor(.black)
                    Spacer()
                    Text(formatDate(reply.created_at))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Text(reply.text)
                    .font(.subheadline)
                    .foregroundColor(.black)
            }
        }
        .padding(8)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(8)
    }
    
    private func formatDate(_ dateString: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: dateString) else {
            return "Just now"
        }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let minutes = components.minute, minutes < 60 {
            return minutes < 1 ? "Just now" : "\(minutes)m"
        } else if let hours = components.hour, hours < 24 {
            return "\(hours)h"
        } else if let days = components.day {
            return "\(days)d"
        }
        
        return "Just now"
    }
    
    private func submitReply() {
        guard isReplyButtonEnabled else { return }
        let textToSubmit = replyText
        
        // Create optimistic reply immediately in local state
        let optimisticReply = EventInteractions.Post(
            id: Int.random(in: 9000...10000),
            text: textToSubmit,
            username: accountManager.currentUser ?? "Guest",
            created_at: Date().ISO8601Format(),
            imageURLs: nil,
            likes: 0,
            isLikedByCurrentUser: false,
            replies: []
        )
        
        // Add to local UI immediately
        localPost.replies.append(optimisticReply)
        
        // Clear input
        replyText = ""
        
        // Send to backend
        onReply(textToSubmit)
        
        // Dismiss after a short delay to show the reply was added
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

// MARK: - Utility Views
struct EventCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.divider, lineWidth: 1)
                )
                .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
            content.padding()
        }
    }
}

struct AttendeeChip: View {
    let name: String
    
    var body: some View {
        Text(name)
            .font(.subheadline.weight(.medium))
            .foregroundColor(Color.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.bgCard))
            .shadow(radius: 2)
    }
}

struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(.white)
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color.black.opacity(0.6))
            .cornerRadius(20)
        }
    }
}

// MARK: - Image Pickers
struct EventImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 5
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: EventImagePicker
        
        init(_ parent: EventImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            let group = DispatchGroup()
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    group.enter()
                    
                    result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            return
                        }
                        
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.selectedImages.append(image)
                            }
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.parent.dismiss()
            }
        }
    }
}

// Enhanced version for the social feed
struct SocialImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    let maxSelection: Int
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = maxSelection
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: SocialImagePicker
        
        init(_ parent: SocialImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.selectedImages = [] // Reset to ensure order matches selected
            
            let group = DispatchGroup()
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    group.enter()
                    
                    result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            return
                        }
                        
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                // Process the image to reduce size if needed
                                let processedImage = self.processImage(image)
                                self.parent.selectedImages.append(processedImage)
                            }
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.parent.dismiss()
            }
        }
        
        private func processImage(_ image: UIImage) -> UIImage {
            // Resize large images to save memory
            let maxDimension: CGFloat = 1200
            
            let originalSize = image.size
            if originalSize.width <= maxDimension && originalSize.height <= maxDimension {
                return image
            }
            
            let aspectRatio = originalSize.width / originalSize.height
            var newSize: CGSize
            
            if originalSize.width > originalSize.height {
                newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
            } else {
                newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
            }
            
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1 // Use 1x scale to get exact pixel dimensions
            let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
            
            let processedImage = renderer.image { context in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
            
            return processedImage
        }
    }
}

// MARK: - Group Chat Stub
// MARK: - Preview
struct EventDetailAndInteractions_Previews: PreviewProvider {
    static var previews: some View {
        // Dummy StudyEvent for preview
        let dummyEvent = StudyEvent(
            id: UUID(),
            title: "Swift Programming Workshop",
            coordinate: CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816),
            time: Date(),
            endTime: Date().addingTimeInterval(3600 * 2),
            description: "Join us for a hands-on workshop where you'll learn advanced Swift techniques and best practices for building modern iOS apps.",
            invitedFriends: [],
            attendees: ["SwiftDev1", "iOSEnthusiast", "AppMaker"],
            isPublic: true,
            host: "SwiftGuru",
            hostIsCertified: true,
            eventType: .study
        )
        
        return Group {
            // Preview event detail
            NavigationStack {
                EventDetailView(event: dummyEvent, studyEvents: .constant([dummyEvent]), onRSVP: { _ in })
                    .environmentObject(UserAccountManager())
                    .environmentObject(CalendarManager(accountManager: UserAccountManager()))
            }
            .previewDisplayName("Event Detail")
            
            // Preview social feed
            EventSocialFeedView(event: dummyEvent)
                .environmentObject(UserAccountManager())
                .previewDisplayName("Social Feed")
        }
    }
}
// Enhanced EventPostView with better visual feedback for likes
struct EnhancedEventPostView: View {
    let post: EventInteractions.Post
    let onLike: () -> Void
    let onReply: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                // Profile image
                UserProfileImageView(username: post.username, size: 40, borderColor: .blue)
                
                // Post content
                VStack(alignment: .leading, spacing: 6) {
                    // User info and timestamp
                    HStack {
                        Text(post.username)
                            .font(.headline)
                            .foregroundColor(Color.textPrimary)
                        Spacer()
                        Text(formatDate(post.created_at))
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                    }
                    
                    // Post text
                    Text(post.text)
                        .font(.body)
                        .foregroundColor(Color.black)
                        .multilineTextAlignment(.leading)
                    
                    // Debug info during development
                    #if DEBUG
                    Text("Post ID: \(post.id), Likes: \(post.likes), Liked by me: \(post.isLikedByCurrentUser ? "Yes" : "No")")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                    #endif
                    
                    // Image grid if present
                    if let imageURLs = post.imageURLs, !imageURLs.isEmpty {
                        // Your existing image grid code
                    }
                    
                    // Action buttons with enhanced feedback
                    HStack(spacing: 20) {
                        // Like button
                        Button(action: {
                            // Add haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            // Call the like action
                            onLike()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                                    .foregroundColor(post.isLikedByCurrentUser ? .red : .gray)
                                
                                Text("\(post.likes)")
                                    .font(.caption)
                                    .foregroundColor(post.isLikedByCurrentUser ? .red : .gray)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(post.isLikedByCurrentUser ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                            .cornerRadius(15)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .animation(.spring(), value: post.isLikedByCurrentUser)
                        
                        // Reply button
                        Button(action: onReply) {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left")
                                    .foregroundColor(.gray)
                                Text("\(post.replies.count)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        // Share button
                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Show replies if any
                    if !post.replies.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(post.replies) { reply in
                                // Your existing reply view
                            }
                        }
                        .padding(.top, 10)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color.bgCard)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.textMuted),
            alignment: .bottom
        )
    }
    
    // Helper function for date formatting
    private func formatDate(_ dateString: String) -> String {
        // Your existing date formatting code
        return "now" // Replace with your actual implementation
    }
}

// MARK: - Social Feed Share View
struct SocialFeedShareView: View {
    let event: StudyEvent
    @EnvironmentObject var accountManager: UserAccountManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showImagePicker = false
    @State private var showSocialFeedSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.textLight)
                        .frame(width: 80, height: 80)
                        .background(
                            Circle()
                                .fill(Color.brandPrimary)
                                .shadow(color: Color.brandPrimary.opacity(0.25), radius: 8, x: 0, y: 4)
                        )
                    
                    Text("Share Photos")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Share your experience at \(event.title)")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Placeholder content
                VStack(spacing: 16) {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 20))
                                .foregroundColor(.textLight)
                            
                            Text("Select Photos")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.textLight)
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.brandPrimary)
                                .shadow(color: Color.brandPrimary.opacity(0.25), radius: 8, x: 0, y: 4)
                        )
                    }
                    
                    Button(action: {
                        showSocialFeedSheet = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 20))
                                .foregroundColor(.textLight)
                            
                            Text("Write a Post")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.textLight)
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.brandPrimary)
                                .shadow(color: Color.brandPrimary.opacity(0.25), radius: 8, x: 0, y: 4)
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .background(Color.bgSurface)
            .navigationTitle("Share Experience")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
            }
        }
    }
}

// MARK: - Event Feed View
struct EventFeedView: View {
    let event: StudyEvent
    @EnvironmentObject var accountManager: UserAccountManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "photo.stack.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.textLight)
                            .frame(width: 80, height: 80)
                            .background(
                                Circle()
                                    .fill(Color.brandPrimary)
                                    .shadow(color: Color.brandPrimary.opacity(0.25), radius: 8, x: 0, y: 4)
                            )
                        
                        Text("Event Feed")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.textPrimary)
                        
                        Text("See what others shared about \(event.title)")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Placeholder posts
                    VStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Circle()
                                        .fill(Color.brandPrimary.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text("U\(index + 1)")
                                                .font(.headline.weight(.bold))
                                                .foregroundColor(Color.brandPrimary)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("User \(index + 1)")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.textPrimary)
                                        
                                        Text("2 hours ago")
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)
                                    }
                                    
                                    Spacer()
                                }
                                
                                Text("Had an amazing time at this event! The atmosphere was incredible and I met so many interesting people.")
                                    .font(.body)
                                    .foregroundColor(.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                // Placeholder image
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.bgSecondary)
                                    .frame(height: 200)
                                    .overlay(
                                        VStack {
                                            Image(systemName: "photo")
                                                .font(.system(size: 32))
                                                .foregroundColor(.textMuted)
                                            Text("Event Photo")
                                                .font(.caption)
                                                .foregroundColor(.textMuted)
                                        }
                                    )
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.bgCard)
                                    .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .background(Color.bgSurface)
            .navigationTitle("Event Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
            }
        }
    }
}

// MARK: - User Profile View - Professional Design with Backend Integration
struct UserProfileView: View {
    let username: String
    @EnvironmentObject var accountManager: UserAccountManager
    @Environment(\.dismiss) var dismiss
    
    // Real data from backend
    @State private var userProfile: UserProfile?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showError = false
    
    // Additional data from separate API calls
    @State private var reputationData: ReputationData?
    @State private var friendsData: FriendsData?
    @State private var recentEventsData: [StudyEvent]?
    
    // Action states
    @State private var showChatView = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showImagePicker = false
    @State private var showSocialFeedSheet = false
    @State private var showReportSheet = false
    @State private var showFullScreenImage = false
    
    // Backend URL
    private let baseURL = APIConfig.primaryBaseURL
    
    var body: some View {
        NavigationStack {
            ZStack {
        // Professional Background
        Color.bgSurface.ignoresSafeArea()
        
        LinearGradient(
            colors: [
                Color.brandPrimary.opacity(0.03),
                Color.brandSecondary.opacity(0.02),
                Color.bgSurface
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
                
                // Content
                if isLoading {
                    loadingView
                } else if let profile = userProfile {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Professional Profile Header
                            profileHeaderCard(profile: profile)
                                .padding(.horizontal)
                            
                            // Key Stats Card
                            statsCard(profile: profile)
                                .padding(.horizontal)
                            
                            // Bio Card
                            bioCard(profile: profile)
                                .padding(.horizontal)
                            
            // Interests Card
            interestsCard(profile: profile)
                .padding(.horizontal)
            
            // Skills Card
            skillsCard(profile: profile)
                .padding(.horizontal)
            
            // Recent Activity Card
            recentActivityCard(profile: profile)
                .padding(.horizontal)
                            
            // Friends Card (instead of mutual connections)
            friendsCard(profile: profile)
                .padding(.horizontal)
                            
                            // Action Buttons Card
                            actionButtonsCard(profile: profile)
                                .padding(.horizontal)
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.vertical, 10)
                    }
                } else {
                    errorView
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
            }
            .onAppear {
                fetchUserProfile()
            }
                    .alert("Error", isPresented: $showError) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text(errorMessage ?? "Failed to load profile")
                    }
                    .alert("Action", isPresented: $showAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text(alertMessage)
                    }
                    .sheet(isPresented: $showChatView) {
                        NavigationStack {
                            ChatView(
                                sender: accountManager.currentUser ?? "Guest",
                                receiver: username
                            )
                            .environmentObject(accountManager)
                            .environmentObject(ChatManager())
                        }
                    }
                    .sheet(isPresented: $showReportSheet) {
                        ReportContentView(
                            contentType: .user,
                            contentId: username
                        )
                    }
                    .sheet(isPresented: $showFullScreenImage) {
                        FullScreenImageView(username: username)
                    }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.brandPrimary)
            
            Text("Loading profile...")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgSurface)
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.brandWarning)
            
            Text("Failed to Load Profile")
                .font(.title2.weight(.bold))
                .foregroundColor(.textPrimary)
            
            Text(errorMessage ?? "Unable to load user profile")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                fetchUserProfile()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brandPrimary)
            )
            .foregroundColor(.textLight)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgSurface)
    }
    
    // MARK: - Backend Integration
    private func fetchUserProfile() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/get_user_profile/\(username)/") else {
            errorMessage = "Invalid URL"
            isLoading = false
            showError = true
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("Network Error: \(error.localizedDescription)")
                    self.alertMessage = "Failed to load profile: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    showError = true
                    return
                }
                
                do {
                    // First, let's see what the actual response looks like
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Raw API response: \(jsonString)")
                    }
                    
                    let profile = try JSONDecoder().decode(UserProfile.self, from: data)
                    self.userProfile = profile
                    
                    // Fetch additional data in parallel
                    self.fetchReputationData()
                    self.fetchFriendsData()
                    self.fetchRecentEvents()
                } catch {
                    print("JSON Decoding Error: \(error)")
                    self.alertMessage = "Failed to parse profile data: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }.resume()
    }
    
    
    // MARK: - Fetch Reputation Data
    private func fetchReputationData() {
        guard let url = URL(string: "\(baseURL)/get_user_reputation/\(username)/") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    do {
                        let reputation = try JSONDecoder().decode(ReputationData.self, from: data)
                        self.reputationData = reputation
                    } catch {
                        print("Reputation parsing error: \(error)")
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Fetch Friends Data
    private func fetchFriendsData() {
        guard let url = URL(string: "\(baseURL)/get_friends/\(username)/") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    do {
                        let friends = try JSONDecoder().decode(FriendsData.self, from: data)
                        self.friendsData = friends
                    } catch {
                        print("Friends parsing error: \(error)")
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Fetch Recent Events
    private func fetchRecentEvents() {
        guard let url = URL(string: "\(baseURL)/get_study_events/\(username)/") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    do {
                        // The API returns {"events": [...]}
                        let response = try JSONDecoder().decode(EventsResponse.self, from: data)
                        
                        // Filter events where the user actually participated (hosted, attended, or was invited)
                        let userEvents = response.events.filter { event in
                            // Check if user is the host
                            if event.host == self.username {
                                return true
                            }
                            // Check if user is in attendees list
                            if event.attendees.contains(self.username) {
                                return true
                            }
                            // Check if user was invited
                            if event.invitedFriends.contains(self.username) {
                                return true
                            }
                            return false
                        }
                        
                        // Take only the first 3 events for recent activity
                        self.recentEventsData = Array(userEvents.prefix(3))
                    } catch {
                        print("Recent events parsing error: \(error)")
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Helper Functions
    private func formatEventDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
    
    private func formatEventDate(_ date: Date) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
    
    // MARK: - Action Functions
    private func sendMessage(to username: String) {
        showChatView = true
    }
    
    private func sendFriendRequest(to username: String) {
        guard let url = URL(string: "\(baseURL)/send_friend_request/") else {
            alertMessage = "Invalid URL"
            showAlert = true
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // ✅ Add JWT authentication header
        accountManager.addAuthHeader(to: &request)
        
        // ✅ Only send to_user - backend gets from_user from JWT
        let body = ["to_user": username]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            alertMessage = "Error encoding request"
            showAlert = true
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = "Error: \(error.localizedDescription)"
                } else if let data = data {
                    do {
                        let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                        alertMessage = response?["message"] as? String ?? "Friend request sent!"
                    } catch {
                        alertMessage = "Friend request sent!"
                    }
                } else {
                    alertMessage = "Friend request sent!"
                }
                showAlert = true
            }
        }.resume()
    }
    
    private func blockUser(_ username: String) {
        // Implement block functionality
        guard let currentUser = accountManager.currentUser else { return }
        
        let url = URL(string: "\(baseURL)/block_user/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "blocker": currentUser,
            "blocked": username
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        alertMessage = "Failed to block user: \(error.localizedDescription)"
                    } else {
                        alertMessage = "User blocked successfully"
                    }
                    showAlert = true
                }
            }.resume()
        } catch {
            alertMessage = "Failed to block user"
            showAlert = true
        }
    }
    
    // MARK: - Profile Header Card
    private func profileHeaderCard(profile: UserProfile) -> some View {
        VStack(spacing: 20) {
            // Avatar and Name
            VStack(spacing: 16) {
                Button(action: {
                    // Show full-screen image view
                    showFullScreenImage = true
                }) {
                    UserProfileImageView(
                        username: profile.username, 
                        size: 120, 
                        showBorder: true, 
                        borderColor: .brandPrimary,
                        enableFullScreen: true
                    )
                    .shadow(color: Color.brandPrimary.opacity(0.15), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(spacing: 8) {
                    Text(profile.displayName)
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(
                                Circle()
                                    .fill(Color.brandPrimary)
                            )
                        
                        Text((profile.isVerified ?? false) ? "Verified Member" : "Member")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.textSecondary)
                    }
                    
                    // University and Degree Info
                    if let university = profile.university, !university.isEmpty {
                        VStack(spacing: 4) {
                            Text(university)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.textPrimary)
                            
                            if let degree = profile.degree, !degree.isEmpty {
                                Text(degree)
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.textSecondary)
                            }
                            
                            if let year = profile.year, !year.isEmpty {
                                Text(year)
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Stats Card
    private func statsCard(profile: UserProfile) -> some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.textLight)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.brandPrimary)
                            .shadow(color: Color.brandPrimary.opacity(0.25), radius: 4, x: 0, y: 2)
                    )
                
                Text("Profile Statistics")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                statItem("Events", "\(reputationData?.eventsAttended ?? 0)", "calendar")
                statItem("Reputation", String(format: "%.1f", reputationData?.averageRating ?? 0.0), "star.fill")
                statItem("Friends", "\(friendsData?.friends.count ?? 0)", "person.2.fill")
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Bio Card
    private func bioCard(profile: UserProfile) -> some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 20))
                    .foregroundColor(.textLight)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.brandSecondary)
                            .shadow(color: Color.brandSecondary.opacity(0.25), radius: 4, x: 0, y: 2)
                    )
                
                Text("About")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            Text((profile.bio?.isEmpty ?? true) ? "No bio available" : profile.bio!)
                .font(.body)
                .foregroundColor(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Skills Card
    private func skillsCard(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.brandAccent)
                
                Text("Skills")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            if let skills = profile.skills, !skills.isEmpty {
                VStack(spacing: 12) {
                    ForEach(Array(skills.keys.sorted()), id: \.self) { skill in
                        HStack {
                            Text(skill)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            Text(skills[skill] ?? "BEGINNER")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.bgSecondary)
                                )
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.bgSecondary.opacity(0.5))
                        )
                    }
                }
            } else {
                Text("No skills specified")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.cardStroke, lineWidth: 1)
                )
        )
        .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Interests Card
    private func interestsCard(profile: UserProfile) -> some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.brandSecondary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.brandSecondary.opacity(0.1))
                            .shadow(color: Color.brandSecondary.opacity(0.15), radius: 4, x: 0, y: 2)
                    )
                
                Text("Interests")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            if (profile.interests?.isEmpty ?? true) {
                Text("No interests specified")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(profile.interests!, id: \.self) { interest in
                        Text(interest)
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.brandPrimary.opacity(0.1))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
                            )
                            .foregroundColor(Color.brandPrimary)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Recent Activity Card
    private func recentActivityCard(profile: UserProfile) -> some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.textLight)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.brandSuccess)
                            .shadow(color: Color.brandSuccess.opacity(0.25), radius: 4, x: 0, y: 2)
                    )
                
                Text("Recent Activity")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            if (recentEventsData?.isEmpty ?? true) {
                Text("No recent activity")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(recentEventsData!, id: \.id) { event in
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16))
                                .foregroundColor(.brandPrimary)
                                .frame(width: 24, height: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.textPrimary)
                                    .lineLimit(1)
                                
                                Text(formatEventDate(event.time))
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Friends Card
    private func friendsCard(profile: UserProfile) -> some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.brandPrimary)
                            .shadow(color: Color.brandPrimary.opacity(0.25), radius: 4, x: 0, y: 2)
                    )
                
                Text("Friends")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("\(friendsData?.friends.count ?? 0)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.bgSecondary)
                )
            }
            
            if (friendsData?.friends.isEmpty ?? true) {
                Text("No friends yet")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(friendsData!.friends, id: \.self) { friendUsername in
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(Color.brandPrimary.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(String(friendUsername.prefix(1)).uppercased())
                                            .font(.headline.weight(.bold))
                                            .foregroundColor(Color.brandPrimary)
                                    )
                                
                                Text(friendUsername)
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.textPrimary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Action Buttons Card
    private func actionButtonsCard(profile: UserProfile) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.textLight)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.brandSecondary)
                            .shadow(color: Color.brandSecondary.opacity(0.25), radius: 4, x: 0, y: 2)
                    )
                
                Text("Actions")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Primary Action - Send Message
                Button(action: {
                    sendMessage(to: profile.username)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                        
                        Text("Send Message")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.brandPrimary)
                            .shadow(color: Color.brandPrimary.opacity(0.25), radius: 8, x: 0, y: 4)
                    )
                }
                
                // Secondary Actions Row
                HStack(spacing: 12) {
                    Button(action: {
                        sendFriendRequest(to: profile.username)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 16))
                                .foregroundColor(.brandSecondary)
                            
                            Text("Add Friend")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.brandSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.brandSecondary.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.brandSecondary.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    Button(action: {
                        showReportSheet = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 16))
                                .foregroundColor(.brandWarning)
                            
                            Text("Report")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.brandWarning)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.brandWarning.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.brandWarning.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    Button(action: {
                        blockUser(profile.username)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.textSecondary)
                            
                            Text("Block")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.textSecondary)
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.bgSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.cardStroke, lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Helper Functions
    private func statItem(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.textLight)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.brandPrimary)
                        .shadow(color: Color.brandPrimary.opacity(0.25), radius: 4, x: 0, y: 2)
                )
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.textPrimary)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        if let date = formatter.date(from: dateString) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }
        
        return "Recently"
    }
    
}

// MARK: - UserProfile Model (matches backend API)
struct UserProfile: Codable {
    let username: String
    let fullName: String?
    let university: String?
    let degree: String?
    let year: String?
    let bio: String?
    let isCertified: Bool?
    let interests: [String]?
    let skills: [String: String]?
    let autoInviteEnabled: Bool?
    let preferredRadius: Double?
    
    // Computed properties for UI compatibility
    var displayName: String {
        return fullName?.isEmpty == false ? fullName! : username
    }
    
    var isVerified: Bool {
        return isCertified ?? false
    }
    
    var eventsAttended: Int {
        return 0 // Will be fetched separately
    }
    
    var reputation: Double {
        return 0.0 // Will be fetched separately
    }
    
    var friendsCount: Int {
        return 0 // Will be fetched separately
    }
    
    var recentEvents: [RecentEvent]? {
        return nil // Not provided by current API
    }
    
    var mutualFriends: [String]? {
        return nil // Not provided by current API
    }
    
    var memberSince: String? {
        return nil // Not provided by current API
    }
    
    // Custom initializer for mock data
    init(username: String, fullName: String?, university: String?, degree: String?, year: String?, bio: String?, isCertified: Bool?, interests: [String]?, skills: [String: String]?, autoInviteEnabled: Bool?, preferredRadius: Double?) {
        self.username = username
        self.fullName = fullName
        self.university = university
        self.degree = degree
        self.year = year
        self.bio = bio
        self.isCertified = isCertified
        self.interests = interests
        self.skills = skills
        self.autoInviteEnabled = autoInviteEnabled
        self.preferredRadius = preferredRadius
    }
    
    // Decode from backend API response
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        username = try container.decode(String.self, forKey: .username)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        university = try container.decodeIfPresent(String.self, forKey: .university)
        degree = try container.decodeIfPresent(String.self, forKey: .degree)
        year = try container.decodeIfPresent(String.self, forKey: .year)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        isCertified = try container.decodeIfPresent(Bool.self, forKey: .isCertified)
        interests = try container.decodeIfPresent([String].self, forKey: .interests)
        skills = try container.decodeIfPresent([String: String].self, forKey: .skills)
        autoInviteEnabled = try container.decodeIfPresent(Bool.self, forKey: .autoInviteEnabled)
        preferredRadius = try container.decodeIfPresent(Double.self, forKey: .preferredRadius)
    }
    
    private enum CodingKeys: String, CodingKey {
        case username, fullName = "full_name", university, degree, year, bio, isCertified = "is_certified", interests, skills, autoInviteEnabled = "auto_invite_enabled", preferredRadius = "preferred_radius"
    }
}

struct RecentEvent: Codable, Identifiable {
    let id: String
    let title: String
    let date: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try different possible field names
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? 
                container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown Event"
        date = try container.decodeIfPresent(String.self, forKey: .date) ?? 
               container.decodeIfPresent(String.self, forKey: .createdAt) ?? 
               container.decodeIfPresent(String.self, forKey: .timestamp) ?? Date().iso8601String
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, title, name, date, createdAt, timestamp
    }
}

extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}

// MARK: - Additional Data Models
struct ReputationData: Codable {
    let username: String
    let totalRatings: Int
    let averageRating: Double
    let eventsHosted: Int
    let eventsAttended: Int
    let trustLevel: TrustLevel
    
    private enum CodingKeys: String, CodingKey {
        case username, totalRatings = "total_ratings", averageRating = "average_rating", eventsHosted = "events_hosted", eventsAttended = "events_attended", trustLevel = "trust_level"
    }
}

struct TrustLevel: Codable {
    let level: Int
    let title: String
}

struct FriendsData: Codable {
    let friends: [String]  // Backend returns array of usernames, not Friend objects
}

struct Friend: Codable, Identifiable {
    let id = UUID()
    let username: String
    let firstName: String
    let lastName: String
    let university: String
    let isCertified: Bool
    
    private enum CodingKeys: String, CodingKey {
        case username, firstName = "first_name", lastName = "last_name", university, isCertified = "is_certified"
    }
}

struct EventsResponse: Codable {
    let events: [StudyEvent]
}

// MARK: - Full Screen Image View
struct FullScreenImageView: View {
    let username: String
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var imageManager = ImageManager.shared
    @State private var currentImageIndex = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if imageManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else if imageManager.userImages.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))
                        Text("No images available")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    TabView(selection: $currentImageIndex) {
                        ForEach(Array(imageManager.userImages.enumerated()), id: \.offset) { index, image in
                            imageManager.cachedAsyncImage(
                                url: imageManager.getFullImageURL(image),
                                contentMode: .fit
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .ignoresSafeArea()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                if !imageManager.userImages.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Text("\(currentImageIndex + 1) of \(imageManager.userImages.count)")
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .onAppear {
            loadUserImages()
        }
    }
    
    private func loadUserImages() {
        Task {
            await imageManager.loadUserImages(username: username, forceRefresh: true)
        }
    }
}
