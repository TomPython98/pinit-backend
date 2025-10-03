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
    @State private var showShareSheet = false

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
        
        // Check if the same event exists in studyEvents with more data
        if let updatedEventInArray = studyEvents.wrappedValue.first(where: { $0.id == event.id }),
           let tags = updatedEventInArray.interestTags,
           !tags.isEmpty {
            // Found more complete event data with tags
            self._localEvent = State(initialValue: updatedEventInArray)
        } else {
            self._localEvent = State(initialValue: event)
        }
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
        ScrollView {
            VStack(spacing: 20) {
                eventInfoCard
                attendeesCard
                actionButtons
                socialFeedButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(Color.bgSurface.ignoresSafeArea())
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
                .background(Color.socialDark)
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
            
            hasInitialized = true
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
            print("✅ Found tags in studyEvents array: \(tags)")
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
            print("📂 Retrieved tags from UserDefaults by event ID: \(savedTags)")
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
            print("📂 Retrieved tags from UserDefaults by title: \(savedTagsByTitle)")
            
            // Save with the event ID for future reference
            UserDefaults.standard.set(savedTagsByTitle, forKey: eventTagsKey)
            print("📂 Updated tags storage with event ID key: \(eventTagsKey)")
            
            DispatchQueue.main.async {
                var updatedEvent = self.localEvent
                updatedEvent.interestTags = savedTagsByTitle
                self.localEvent = updatedEvent
            }
            return
        }

        print("⚠️ No tags found in any local sources - generating from event info")
        
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
            print("🔄 Created fallback tags based on event info: \(uniqueTags)")
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
            print("⏱️ Skipping refresh as event was updated less than 2 seconds ago")
            return
        }
        
        print("🔄 Refreshing event data for \(localEvent.title)")
        
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
            print("📝 Updated event data found - Attendees: \(updatedEvent.attendees)")
            
            // Only update if there are actual changes
            if updatedEvent.attendees != localEvent.attendees {
                print("🔄 Attendee list changed, updating local state")
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
                    print("🔄 Found attendance mismatch in UserDefaults vs local event, updating")
                    
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
            print("Event added to calendar.")
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
                gradient: Gradient(colors: [Color.socialDark, Color.socialDark]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(radius: 4)
    }
}

// MARK: - Event Info Card
extension EventDetailView {
    private var eventInfoCard: some View {
        VStack(spacing: 20) {
            timeSection
            hostSection
            
            // Auto-matching section - display only for auto-matched events
            if localEvent.isAutoMatched ?? false {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(Color.brandPrimary)
                        Text("Auto-Matched Event")
                            .font(.headline)
                            .foregroundColor(Color.textPrimary)
                        
                        Spacer()
                        
                        // Add a refresh button for debugging purposes
                        Button(action: {
                            fetchEventTags()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(Color.brandPrimary)
                                .font(.caption)
                        }
                        .accessibilityLabel("Refresh tags")
                        .accessibilityHint("Refresh interest tags for this event")
                    }
                    
                    Text("This event uses interest matching to connect people with similar interests.")
                        .font(.subheadline)
                        .foregroundColor(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Display real interest tags if available
                    if let tags = localEvent.interestTags, !tags.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Interest Tags")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text("\(tags.count) tags")
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                            
                            FlowLayout(spacing: 6) {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(.caption2, design: .rounded))
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            Capsule()
                                                .fill(Color.blue.opacity(0.12))
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.blue.opacity(0.25), lineWidth: 1)
                                        )
                                        .foregroundColor(Color.brandPrimary)
                                        .onAppear {
                                            print("🏷️ Displaying tag: \(tag)")
                                        }
                                }
                            }
                        }
                        .onAppear {
                            print("🏷️ Interest tags section appeared with \(tags.count) tags")
                        }
                    } else {
                        // If no tags are available, show a static message instead of auto-refreshing
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Interest tags not available")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.gray)
                            
                            // Manual refresh button instead of automatic refreshing
                            Button(action: {
                                print("🔄 Manual refresh of tags requested")
                                fetchEventTags()
                            }) {
                                Label("Refresh Tags", systemImage: "arrow.clockwise")
                                    .font(.caption)
                                    .foregroundColor(Color.brandPrimary)
                            }
                            .padding(.vertical, 4)
                            
                            // Debug output showing the EventID for troubleshooting
                            Text("Event ID: \(localEvent.id.uuidString.prefix(8))...")
                                .font(.system(size: 8))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .onAppear {
                            print("⚠️ No tags available in auto-matching section")
                            // Don't auto-fetch tags to prevent refresh loops
                        }
                    }
                }
                .padding(15)
                .background(Color.bgCard.opacity(0.7))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
                .onAppear {
                    print("🔍 Auto-matching section appeared - isAutoMatched: \(localEvent.isAutoMatched ?? false)")
                    print("🔍 Current tags: \(localEvent.interestTags?.joined(separator: ", ") ?? "none")")
                    print("🔍 Event ID: \(localEvent.id)")
                }
            }
            
            if let description = localEvent.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(Color.textPrimary)
            }
        }
    }
    
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Time")
                .font(.caption.weight(.bold))
                .foregroundColor(.gray)
            
            HStack(spacing: 6) {
                Label(localEvent.time.formatted(date: .abbreviated, time: .shortened),
                      systemImage: "clock.fill")
                    .font(.subheadline)
                    .foregroundColor(.socialDark)
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.gray.opacity(0.6))
                
                Label(localEvent.endTime.formatted(date: .abbreviated, time: .shortened),
                      systemImage: "clock.badge.checkmark.fill")
                    .font(.subheadline)
                    .foregroundColor(.socialDark)
            }
        }
    }
    
    private var hostSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hosted By")
                .font(.caption.weight(.bold))
                .foregroundColor(Color.textSecondary)
            
            HStack {
                Text(localEvent.host)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.textPrimary)
                
                if localEvent.hostIsCertified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
    }
}

// MARK: - Attendees Card
extension EventDetailView {
    private var attendeesCard: some View {
        EventCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Attendees", systemImage: "person.2.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(Color.socialDark)
                    
                    Spacer()
                    
                    // Show host badge if user is hosting
                    if isHosting {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("Host")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.textPrimary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(6)
                    }
                    
                    Text("\(localEvent.attendees.count)")
                        .font(.subheadline)
                        .foregroundColor(Color.textSecondary)
                }
                
                if localEvent.attendees.isEmpty {
                    Text("Be the first to join!")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                        .padding(.vertical, 4)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(localEvent.attendees.enumerated()), id: \.offset) { index, attendee in
                                HStack {
                                    AttendeeChip(name: attendee)
                                    
                                    // Show host indicator
                                    if attendee == localEvent.host {
                                        Image(systemName: "crown.fill")
                                            .font(.caption2)
                                            .foregroundColor(.yellow)
                                    }
                                    
                                    // Don't show rate button for yourself
                                    if attendee != accountManager.currentUser, isEventCompleted {
                                        Button(action: {
                                            selectedUserToRate = attendee
                                            showRateUserSheet = true
                                        }) {
                                            Image(systemName: "star.fill")
                                                .font(.caption)
                                                .foregroundColor(.yellow)
                                                .padding(4)
                                                .background(Circle().fill(Color.white.opacity(0.9)))
                                                .shadow(radius: 1)
                                        }
                                        .accessibilityLabel("Rate \(attendee)")
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Host management section
                if canManageAttendance {
                    hostManagementSection
                }
            }
        }
        .id(attendanceStateChanged)
    }
    
    private var hostManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            
            Text("Host Management")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.socialDark)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(Color.brandPrimary)
                    Text("Manage Attendance")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(localEvent.attendees.count) attending")
                        .font(.caption2)
                        .foregroundColor(Color.textSecondary)
                }
                
                Text("As the host, you're automatically marked as attending. You can manage your event and invite others.")
                    .font(.caption2)
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.leading)
                
                // Quick actions for hosts
                HStack(spacing: 8) {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption2)
                            Text("Share Event")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.brandPrimary)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
            }
            .padding(.top, 4)
        }
    }
    
    // Helper to determine if an event has completed
    private var isEventCompleted: Bool {
        return localEvent.endTime < Date()
    }
}

// MARK: - Action Buttons
extension EventDetailView {
    private var actionButtons: some View {
        VStack(spacing: 12) {
            joinLeaveButton
            
            // If event is completed and user is a participant, show the rating button
            if isEventCompleted && localEvent.attendees.contains(where: { $0 == accountManager.currentUser }) {
                Button(action: {
                    // Show menu with attendees to rate
                    // This will be handled by the attendance card's sheet
                    showRateUserSheet = true
                }) {
                    Label("Rate Attendees", systemImage: "star.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow)
                        .cornerRadius(12)
                }
                .disabled(localEvent.attendees.count <= 1) // Disable if user is the only attendee
            }
            
            groupChatButton
        }
    }
    
    private var joinLeaveButton: some View {
        Button {
            print("🔵 Join/Leave button tapped - about to call handleRSVP()")
            handleRSVP()
        } label: {
            Label(
                isHosting ? "Hosting Event" : (isAttending ? "Leave Event" : "Join Event"),
                systemImage: isHosting ? "crown.fill" : (isAttending ? "xmark.circle.fill" : "checkmark.circle.fill")
            )
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(isHosting ? Color.yellow : (isAttending ? Color.socialLight : Color.socialMedium))
            .cornerRadius(12)
            .shadow(radius: 4)
        }
        .id(attendanceStateChanged)
        .disabled(isHosting) // Hosts can't leave their own events
        .accessibilityHint(isHosting ? "You are hosting this event" : (isAttending ? "Tap to leave this event" : "Tap to join this event"))
    }
    
    private var groupChatButton: some View {
        NavigationLink {
            GroupChatView(
                eventID: localEvent.id,
                currentUser: accountManager.currentUser ?? "Guest",
                eventTitle: localEvent.title
            )
        } label: {
            Label("Group Chat", systemImage: "bubble.left.and.bubble.right.fill")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.socialDark)
                .cornerRadius(12)
                .shadow(radius: 4)
        }
    }
    
    private func handleRSVP() {
        print("RSVP button clicked for event: \(localEvent.id)")
        print("Current user: \(accountManager.currentUser ?? "No user")")
        
        // Immediately update the local event's attendees list
        let currentUser = accountManager.currentUser ?? ""
        if isAttending {
            // User is attending and wants to un-RSVP
            if let index = localEvent.attendees.firstIndex(of: currentUser) {
                localEvent.attendees.remove(at: index)
                print("Removed user from attendees locally")
                
                // Store RSVP status in UserDefaults for this event
                let key = "event_rsvp_\(localEvent.id.uuidString)_\(currentUser)"
                UserDefaults.standard.set(false, forKey: key)
            }
        } else {
            // User is not attending and wants to RSVP
            if !localEvent.attendees.contains(currentUser) {
                localEvent.attendees.append(currentUser)
                print("Added user to attendees locally")
                
                // Store RSVP status in UserDefaults for this event
                let key = "event_rsvp_\(localEvent.id.uuidString)_\(currentUser)"
                UserDefaults.standard.set(true, forKey: key)
            }
        }
        
        // Toggle the state to refresh the UI
        attendanceStateChanged = UUID()
        print("Updated attendanceStateChanged to refresh UI")
        
        // Call onRSVP immediately
        onRSVP(localEvent.id)
        print("RSVP sent to backend for event: \(localEvent.id)")
        
        // Update the studyEvents array with our local event
        if let eventIndex = studyEvents.firstIndex(where: { $0.id == localEvent.id }) {
            studyEvents[eventIndex] = localEvent
            print("Updated global events array with local changes")
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
    
    // MARK: - View Body
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            createPostSection
            
            feedStats
            
            postsListView
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $isShowingImagePicker) {
            SocialImagePicker(selectedImages: $selectedImages, maxSelection: 4)
        }
        .sheet(item: $showingFullPost) { post in
            PostDetailView(post: post, onLike: { likePost(postID: post.id) }, onReply: { text in
                replyToPost(postID: post.id, text: text)
            })
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
        .background(Color(.secondarySystemBackground))
    }
    
    private var createPostSection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                // Profile Image
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
                
                // Text input and controls
                VStack(alignment: .leading, spacing: 10) {
                    TextField("What's happening at this event?", text: $newPostText, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(PlainTextFieldStyle())
                    
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
        .background(Color.bgCard)
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
                Label("\(interactions?.likes.total ?? 0) Likes", systemImage: "heart")
                    .font(.subheadline)
                Label("\(interactions?.shares.total ?? 0) Shares", systemImage: "square.and.arrow.up")
                    .font(.subheadline)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
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
                                onLike: { likePost(postID: post.id) },
                                onReply: { showReplySheet(for: post) }
                            )
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
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(height: 300)
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
        // Demo data for preview/testing
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            createDemoData()
            return
        }
        #endif
        
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
        
        URLSession.shared.dataTask(with: finalUrl) { data, response, error in
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
                    print("⛔ Received 403 Forbidden for event \(self.event.id) - user not in matched users")
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
                } catch {
                    self.errorMessage = "Failed to decode data: \(error.localizedDescription)"
                    print("Decoding error details: \(error)")
                    
                    // Print the received data for debugging
                    if let dataString = String(data: data, encoding: .utf8) {
                        print("Received data: \(dataString)")
                    }
                }
            }
        }.resume()
    }

    
    private func createDemoData() {
        // Create some demo posts for preview/testing
        let demoInteractions = EventInteractions(
            posts: [
                EventInteractions.Post(
                    id: 1,
                    text: "Having a great time at this event! The discussions are really insightful.",
                    username: "user1",
                    created_at: Date().ISO8601Format(),
                    imageURLs: nil,
                    likes: 5,
                    isLikedByCurrentUser: false,
                    replies: []
                ),
                EventInteractions.Post(
                    id: 2,
                    text: "Just joined and already learning so much!",
                    username: "user2",
                    created_at: Date().addingTimeInterval(-1800).ISO8601Format(),
                    imageURLs: ["placeholder1", "placeholder2"],
                    likes: 3,
                    isLikedByCurrentUser: true,
                    replies: [
                        EventInteractions.Post(
                            id: 3,
                            text: "Welcome! Glad you're enjoying it!",
                            username: "host",
                            created_at: Date().addingTimeInterval(-1700).ISO8601Format(),
                            imageURLs: nil,
                            likes: 1,
                            isLikedByCurrentUser: false,
                            replies: []
                        )
                    ]
                )
            ],
            likes: EventInteractions.Likes(total: 9, users: ["user1", "user2", "user3"]),
            shares: EventInteractions.Shares(total: 3, breakdown: ["twitter": 1, "messages": 2])
        )
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.interactions = demoInteractions
        }
    }
    
    private func refreshFeed() {
        fetchInteractions()
    }
    
   
    // MARK: - Update the addPost function

    private func addPost() {
        guard isPostButtonEnabled else { return }
        
        // Show loading state
        _ = "Posting..." // Loading message available for future use if needed
        errorMessage = nil
        isRefreshing = true
        
        // API endpoint
        guard let url = URL(string: "\(APIConfig.primaryBaseURL)/events/comment/") else {
            errorMessage = "Invalid API URL"
            isRefreshing = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare post data
        let imageURLs = selectedImages.isEmpty ? nil : selectedImages.map { _ in "placeholder" }
        let username = accountManager.currentUser ?? "Guest"
        
        let postData: [String: Any] = [
            "username": username,
            "event_id": event.id.uuidString,
            "text": newPostText,
            "image_urls": imageURLs as Any
        ]
        
        // Convert to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: postData)
        } catch {
            errorMessage = "Failed to encode post data: \(error.localizedDescription)"
            isRefreshing = false
            return
        }
        
        // Create a local copy of post while waiting for response
        let optimisticPost = EventInteractions.Post(
            id: Int.random(in: 9000...10000),  // Temporary ID that will be replaced
            text: newPostText,
            username: username,
            created_at: Date().ISO8601Format(),
            imageURLs: imageURLs,
            likes: 0,
            isLikedByCurrentUser: false,
            replies: []
        )
        
        // Immediately update UI with optimistic post
        if var currentInteractions = interactions {
            currentInteractions.posts.insert(optimisticPost, at: 0)
            interactions = currentInteractions
        } else {
            // Create new interactions object if none exists
            interactions = EventInteractions(
                posts: [optimisticPost],
                likes: EventInteractions.Likes(total: 0, users: []),
                shares: EventInteractions.Shares(total: 0, breakdown: [:])
            )
        }
        
        // Clear input immediately for good UX
        let savedText = newPostText
        let savedImages = selectedImages
        newPostText = ""
        selectedImages = []
        
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
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    self.errorMessage = "Server error: \(httpResponse.statusCode)"
                    
                    // Show response data for debugging
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("Server error response: \(responseString)")
                    }
                    
                    // Revert optimistic update on failure
                    if var current = self.interactions {
                        current.posts.removeAll { $0.id == optimisticPost.id }
                        self.interactions = current
                    }
                    return
                }
                
                // Post created successfully, refresh the feed
                self.refreshFeed()
            }
        }.resume()
    }
    // Updated helper function to set likes count from server response
    func updatePostLikeCount(posts: [EventInteractions.Post], postID: Int, newCount: Int, isLiked: Bool) -> [EventInteractions.Post] {
        var updatedPosts = posts
        
        for i in 0..<updatedPosts.count {
            if updatedPosts[i].id == postID {
                // Update with correct like count from server
                updatedPosts[i].likes = newCount
                updatedPosts[i].isLikedByCurrentUser = isLiked
                print("✅ Updated post \(postID) with server data: likes=\(newCount), liked=\(isLiked)")
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
                    print("✅ Updated like state in a reply of post \(updatedPosts[i].id)")
                    return updatedPosts
                }
            }
        }
        
        return updatedPosts
    }

    
    // Enhanced likePost function with debugging and proper API call
    func likePost(postID: Int) {
        print("❤️ Like/unlike requested for post ID: \(postID)")
        
        // Find the post to check its current state before update
        if let interactions = interactions {
            let foundPost = interactions.posts.first(where: { $0.id == postID }) ??
                            interactions.posts.flatMap { $0.replies }.first(where: { $0.id == postID })
            
            if let post = foundPost {
                print("🔍 Found post \(postID) with current state: liked=\(post.isLikedByCurrentUser), likes=\(post.likes)")
            } else {
                print("⚠️ Could not find post ID \(postID) before updating")
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
        
        // IMPORTANT: The backend expects 'post_id' for comment likes
        let body: [String: Any] = [
            "username": currentUser,
            "event_id": event.id.uuidString,
            "post_id": postID  // This matches the backend expectation
        ]
        
        print("📡 Sending API request to: \(url.absoluteString)")
        print("📦 Request body: \(body)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ Error serializing request: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    self.errorMessage = "Failed to like post: \(error.localizedDescription)"
                    // Revert the optimistic update if the API call fails
                    self.refreshFeed()
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    return
                }
                
                print("📊 HTTP Status: \(httpResponse.statusCode)")
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Response: \(responseString)")
                    
                    // Try to parse response for total_likes
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let _ = json["success"] as? Bool,
                           let liked = json["liked"] as? Bool,
                           let totalLikes = json["total_likes"] as? Int {
                            
                            print("✅ Like operation successful. New state: liked=\(liked), total_likes=\(totalLikes)")
                            
                            // Update the post with correct likes count from server
                            if var updatedInteractions = self.interactions {
                                updatedInteractions.posts = self.updatePostLikeCount(
                                    posts: updatedInteractions.posts,
                                    postID: postID,
                                    newCount: totalLikes,
                                    isLiked: liked
                                )
                                self.interactions = updatedInteractions
                            }
                        } else {
                            print("⚠️ Unexpected response format")
                        }
                    } catch {
                        print("⚠️ Error parsing response: \(error)")
                    }
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    print("❌ Server error: \(httpResponse.statusCode)")
                    self.errorMessage = "Server error: \(httpResponse.statusCode)"
                    self.refreshFeed()
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
                   
                   print("✅ Toggled like for post \(postID): liked=\(!wasLiked), likes=\(updatedPosts[i].likes)")
                   return updatedPosts
               }
               
               // Check replies
               if !updatedPosts[i].replies.isEmpty {
                   let originalReplies = updatedPosts[i].replies
                   updatedPosts[i].replies = updateLikeStateInPosts(posts: originalReplies, postID: postID)
                   
                   // Check if we found and updated the target post in replies
                   if updatedPosts[i].replies != originalReplies {
                       print("✅ Updated like state in a reply of post \(updatedPosts[i].id)")
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
                    
                    // Show response data for debugging
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("Server error response: \(responseString)")
                    }
                    return
                }
                
                // Reply created successfully, refresh the feed to show actual server data
                self.refreshFeed()
            }
        }.resume()
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                // Profile image
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
                
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
                        .foregroundColor(Color.textPrimary)
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
        .background(Color.bgCard)
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
                // Create a visually appealing placeholder
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .aspectRatio(contentMode: .fill)
                        .frame(height: imageURLs.count == 1 ? 200 : 120)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    // Photo icon and label
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                        
                        Text("Image \(index + 1)")
                            .foregroundColor(.white)
                            .font(.caption)
                            .padding(.top, 5)
                    }
                }
            }
        }
        .padding(.vertical, 5)
    }
    
    private func replyView(for reply: EventInteractions.Post) -> some View {
        HStack(alignment: .top, spacing: 8) {
            // Smaller profile image for replies
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reply.username)
                        .font(.subheadline.bold())
                    Spacer()
                    Text(formatDate(reply.created_at))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Text(reply.text)
                    .font(.subheadline)
            }
        }
        .padding(8)
        .background(Color.bgSecondary)
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
    
    @State private var replyText = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var accountManager: UserAccountManager
    
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
            .background(Color(.secondarySystemBackground))
            
            ScrollView {
                VStack(spacing: 0) {
                    // Original post
                    EventPostView(post: post, onLike: onLike, onReply: {})
                        .padding(.bottom, 12)
                    
                    Divider()
                    
                    // Reply composer
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(Color.brandPrimary)
                        
                        VStack(alignment: .trailing, spacing: 8) {
                            TextField("Add your reply...", text: $replyText, axis: .vertical)
                                .lineLimit(1...5)
                                .textFieldStyle(PlainTextFieldStyle())
                            
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
        }
    }
    
    private var isReplyButtonEnabled: Bool {
        !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func submitReply() {
        guard isReplyButtonEnabled else { return }
        onReply(replyText)
        replyText = ""
        dismiss()
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
                            print("Image loading error: \(error.localizedDescription)")
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
                            print("Image loading error: \(error.localizedDescription)")
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
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
                
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
                        .foregroundColor(Color.textPrimary)
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
