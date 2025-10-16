import Foundation
import SwiftUI
import MapKit
import Combine
import CoreLocation
import PhotosUI

// Import the UserProfileManager from ViewModels
// (Note: Swift automatically finds files in the project, no path needed)

// MARK: - Color Extensions with Refined Professional Palette
//  AppColors.swift
//  YourProjectName
//
//  Created by Your Name on 2025-03-XX.

extension Color {
    // Gradient colors - enhanced for visual appeal (keeping unique gradients)
    static let gradientStart = Color(red: 79/255, green: 70/255, blue: 229/255)      // Indigo start
    static let gradientMiddle = Color(red: 88/255, green: 80/255, blue: 236/255)     // Transition color
    static let gradientEnd = Color(red: 99/255, green: 102/255, blue: 241/255)       // Lighter indigo end
    
    // Additional UI elements for polish (keeping unique additions)
    static let coloredShadow = Color(red: 79/255, green: 70/255, blue: 229/255).opacity(0.15) // Indigo shadow
    static let cardHighlight = Color.white                                          // Card highlight
    static let iconBg = Color(red: 240/255, green: 245/255, blue: 255/255)          // Icon background  
    static let activeElement = Color(red: 59/255, green: 130/255, blue: 246/255)    // Active element color
}

// MARK: - Main ContentView with Profile Integration
struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var showSettingsView = false
    @State private var showFriendsView = false
    @State private var showCalendarView = false
    @State private var showNotesView = false
    @State private var showFlashcardsView = false
    @State private var showProfileView = false
    @State private var showMapView = false
    @State private var selectedEvent: StudyEvent? = nil
    @State private var showEventDetailSheet = false
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var chatManager: ChatManager
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // State for next RSVP'd event
    @State private var nextRSVPEvent: StudyEvent? = nil
    @State private var isLoadingEvents = false
    @State private var isEventDetailLoading = false
    
    // Animation state
    @State private var isAnimating = false
    
    // Tutorial overlay state
    @AppStorage("hasSeenMapTutorial") private var hasSeenMapTutorial = false
    @State private var showMapTutorial = false
    @StateObject private var tutorialManager = TutorialManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Refined background with subtle pattern
                backgroundGradient
                
                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // App Title Header with refined styling
                        appWelcomeHeader
                            .padding(.top, 10)
                            .transition(.move(edge: .top))
                        
                        // Weather & Map Card with enhanced styling
                        weatherMapCard
                            .padding(.horizontal)
                            .transition(.scale)
                        
                        // Features section with improved typography and spacing
                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader("Social Features")
                            
                            toolsGridView
                                .padding(.horizontal)
                        }
                        .padding(.top, 6)
                        
                        // Additional features section
                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader("Quick Access")
                                .padding(.top, 8)
                            
                            quickAccessRow
                                .padding(.horizontal)
                        }
                        
                        // App version & info
                        Text("PinIt | v2.1.0")
                            .font(.caption)
                            .foregroundColor(.textMuted)
                            .padding(.top, 12)
                            .padding(.bottom, 24)
                    }
                    .padding(.vertical, 10)
                    .onAppear {
                        withAnimation {
                            isAnimating = true
                        }
                        // Ensure events are loaded once before finding next event
                        if calendarManager.events.isEmpty && !calendarManager.isLoading && !calendarManager.username.isEmpty {
                            calendarManager.fetchEvents(force: false)
                        }
                        // Find next RSVP'd event from CalendarManager
                        findNextRSVPEvent()
                        
                        // ✅ Refresh unread message counts
                        if let currentUser = accountManager.currentUser {
                            chatManager.refreshUnreadCounts(currentUser: currentUser)
                        }
                    }
                    .onReceive(calendarManager.$events) { _ in
                        // Update when calendar events change
                        findNextRSVPEvent()
                    }
                }
                .safeAreaInset(edge: .top) {
                    customTopBar
                }
                
                // Simple welcome tutorial - shows once on first login
                if showMapTutorial {
                    InteractiveTutorial(isShowing: $showMapTutorial)
                        .transition(.opacity)
                        .zIndex(1000)
                }
            }
        }
        .onAppear {
            // Show tutorial if user hasn't seen it yet (first login after onboarding)
            if !hasSeenMapTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation {
                        showMapTutorial = true
                        tutorialManager.isActive = true
                    }
                }
            }
        }
        .sheet(isPresented: $showEventDetailSheet, onDismiss: {
            selectedEvent = nil
            isEventDetailLoading = false
        }) {
            if let event = selectedEvent {
                EventDetailView(event: event, studyEvents: $calendarManager.events, onRSVP: { eventId in
                    // Handle RSVP updates
                    if let eventIndex = calendarManager.events.firstIndex(where: { $0.id == eventId }) {
                        // Update the event in the calendar manager
                        calendarManager.events[eventIndex].attendees.append(accountManager.currentUser ?? "")
                    }
                })
                .environmentObject(accountManager)
                .environmentObject(calendarManager)
            } else {
                // Fallback view if event is nil
                VStack {
                    Text("Event not found")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Button("Close") {
                        showEventDetailSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }

    }
    
    // Listen for global request to show map at specific coordinate
    private func openMapAndCenterOn(eventIDString: String, coordinate: CLLocationCoordinate2D) {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            NotificationCenter.default.post(
                name: Notification.Name("FocusEventOnMap"),
                object: nil,
                userInfo: [
                    "eventID": eventIDString,
                    "lat": lat,
                    "lon": lon
                ]
            )
        }
    }

    // MARK: - Refined sophisticated background
    var backgroundGradient: some View {
        ZStack {
            // Light gradient background with subtle color shift
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.bgSurface,
                    Color.bgSecondary
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Enhanced subtle pattern overlay
            GeometryReader { geometry in
                ZStack {
                    // Geometric patterns
                    ForEach(0..<8) { i in
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.brandPrimary.opacity(0.015))
                            .frame(
                                width: CGFloat.random(in: 80...200),
                                height: CGFloat.random(in: 80...200)
                            )
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height)
                            )
                            .rotationEffect(.degrees(Double.random(in: 0...360)))
                    }
                    
                    // Larger colored accent circles
                    Circle()
                        .fill(Color.brandPrimary.opacity(0.03))
                        .frame(width: 350, height: 350)
                        .blur(radius: 90)
                        .offset(x: isAnimating ? geometry.size.width * 0.5 : 250,
                                y: isAnimating ? geometry.size.height * 0.1 : 15)
                        .animation(.easeInOut(duration: 30).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Circle()
                        .fill(Color.brandSecondary.opacity(0.03))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .offset(x: isAnimating ? geometry.size.width * 0.7 : -40,
                                y: isAnimating ? geometry.size.height * 0.5 : 120)
                        .animation(.easeInOut(duration: 25).repeatForever(autoreverses: true), value: isAnimating)
                    
                    // Additional subtle accent
                    Circle()
                        .fill(Color.brandAccent.opacity(0.02))
                        .frame(width: 250, height: 250)
                        .blur(radius: 60)
                        .offset(x: isAnimating ? -100 : geometry.size.width * 0.3,
                                y: isAnimating ? geometry.size.height * 0.7 : 150)
                        .animation(.easeInOut(duration: 20).repeatForever(autoreverses: true), value: isAnimating)
                }
            }
        }
    }
    
    // MARK: - Section Header Helper - refined typography
    func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Custom Top Bar with refined styling
    var customTopBar: some View {
        HStack {
            // Profile Button with enhanced shadow and interaction
            Button(action: {
                withAnimation(.spring()) {
                    showProfileView = true
                }
            }) {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.brandPrimary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.bgCard)
                            .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 3)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            .sheet(isPresented: $showProfileView) {
                // Use ProfileView as a fallback if MatchingPreferencesView can't be loaded
                // NOTE: For API calls to get_user_profile, you should update this to always use MatchingPreferencesView
                #if canImport(MatchingPreferencesView)
                MatchingPreferencesView()
                    .environmentObject(accountManager)
                #else
                ProfileView()
                    .environmentObject(accountManager)
                #endif
            }
            
            Spacer()
            
            // App Logo & Title with enhanced typography
            HStack(spacing: 8) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                
                Text("PinIt")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(.textPrimary)
                    .tracking(0.2) // Slightly increased letter spacing
            }
            
            Spacer()
            
            
            // Settings Button with enhanced animation
            Button(action: {
                withAnimation(.spring()) {
                    showSettingsView = true
                }
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.brandPrimary)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: isAnimating)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.bgCard)
                            .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 3)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            .sheet(isPresented: $showSettingsView) {
                SettingsView()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            ZStack {
                // Enhanced layered background for depth
                Rectangle()
                    .fill(Color.bgCard)
                    .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
                
                // Refined subtle gradient overlay for sophistication
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cardHighlight,
                                Color.bgAccent.opacity(0.4)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
    }
    
    // MARK: - Welcome Header with refined layout and shadows
    var appWelcomeHeader: some View {
        VStack(spacing: 18) {
            // Welcome Message with improved typography
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hello, \(accountManager.currentUser?.components(separatedBy: " ").first ?? "Student")!")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundColor(.textPrimary)
                    
                    Text(getTimeBasedGreeting())
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                
                // Date Display - refined card with better shadow
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formattedDate())
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundColor(.brandSecondary)
                        
                        Text(formattedWeekday())
                            .font(.caption)
                            .foregroundColor(.brandSecondary)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.bgCard)
                        .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
                )
            }
            .padding(.horizontal)
            
            // Event Card - Now showing next RSVP'd event or fallback
            Button(action: {
                // Prevent multiple taps while sheet is already showing
                guard !showEventDetailSheet && !isEventDetailLoading else { return }
                
                if let event = nextRSVPEvent {
                    isEventDetailLoading = true
                    selectedEvent = event
                    
                    // Removed unconditional fetch; rely on WebSocket and existing state
                    
                    // Show the detail view after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showEventDetailSheet = true
                    }
                } else {
                    showCalendarView = true
                }
            }) {
                HStack(spacing: 16) {
                    // Icon with refined gradient and shadow
                    Image(systemName: nextRSVPEvent != nil ? "calendar.badge.clock" : "calendar")
                        .font(.system(size: 20))
                        .foregroundColor(.textLight)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [.brandSuccess, .brandSuccess.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.brandSuccess.opacity(0.25), radius: 8, x: 0, y: 4)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if calendarManager.isLoading {
                            Text("Loading your events...")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            
                            Text("Please wait")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                        } else if let nextEvent = nextRSVPEvent {
                            Text("Your Next Event")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            
                            Text(nextEvent.title)
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                            
                            Text(formatEventTime(start: nextEvent.time, end: nextEvent.endTime))
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                                .lineLimit(1)
                        } else {
                            Text("No Upcoming Events")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            
                            Text("View Calendar")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                            
                            Text("Check your schedule")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.bgCard)
                        .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal)
            .sheet(isPresented: $showCalendarView) {
                CustomCalendarView()
            }
        }
    }
    
    // Helper to format event time
    private func formatEventTime(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    // Helper functions for dynamic greeting content
    func getTimeBasedGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Ready for your morning classes"
        } else if hour < 18 {
            return "Your afternoon schedule is on track"
        } else {
            return "Time for evening study sessions"
        }
    }
    
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: Date())
    }
    
    func formattedWeekday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }
    
    // MARK: - Weather & Calendar Card with enhanced shadow
    var weatherMapCard: some View {
        WeatherAndCalendarView(selectedDate: $selectedDate, showCalendar: .constant(false))
            .frame(maxWidth: .infinity)
            .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: MapCardFramePreferenceKey.self,
                        value: geo.frame(in: .global)
                    )
                }
            )
    }
    
    // MARK: - Tools Grid View with refined cards and enhanced shadows
    var toolsGridView: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 20
        ) {
            toolButton(
                "friends_social".localized,
                systemImage: "person.2.fill",
                background: Color.brandPrimary,
                description: "Connect with friends",
                badgeCount: chatManager.totalUnreadCount
            ) {
                withAnimation(.spring()) {
                    showFriendsView = true
                }
            }
            .sheet(isPresented: $showFriendsView) {
                FriendsListView()
                    .environmentObject(accountManager)
                    .environmentObject(chatManager)
            }
            
            toolButton(
                "Schedule",
                systemImage: "calendar.badge.clock",
                background: Color.brandSuccess,
                description: "Manage your timetable"
            ) {
                withAnimation(.spring()) {
                    showCalendarView = true
                }
            }
            .sheet(isPresented: $showCalendarView) {
                CustomCalendarView()
            }
            
            toolButton(
                "Events",
                systemImage: "ticket.fill",
                background: Color.brandAccent,
                description: "Join university activities",
                badgeCount: calendarManager.pendingNotificationsCount
            ) {
                withAnimation(.spring()) {
                    showNotesView = true
                }
            }
            .sheet(isPresented: $showNotesView) {
                InvitationsView()
            }
            
        toolButton(
            "community_hub".localized,
            systemImage: "person.3.fill",
            background: Color.brandPrimary,
            description: "See what's trending"
        ) {
                withAnimation(.spring()) {
                    showFlashcardsView = true
                }
            }
            .sheet(isPresented: $showFlashcardsView) {
                CommunityHubView()
            }
        }
    }
    
    // Quick access row with refined spacing
    var quickAccessRow: some View {
        HStack(spacing: 16) {
            quickAccessButton("Events", systemImage: "books.vertical.fill") {
                showNotesView = true
            }
            
            quickAccessButton("Friends", systemImage: "bubble.left.and.bubble.right.fill", badgeCount: chatManager.totalUnreadCount) {
                showFriendsView = true
            }
            
            quickAccessButton("Profile", systemImage: "chart.bar.fill") {
                showProfileView = true
            }
            
            quickAccessButton("Website", systemImage: "globe") {
                if let url = URL(string: "https://www.pinitsocial.com") {
                    UIApplication.shared.open(url)
                }
            }
        }
        .sheet(isPresented: $showMapView) {
            StudyMapView()
                .environmentObject(accountManager)
                .environmentObject(calendarManager)
        }
        .sheet(isPresented: $showProfileView) {
            ProfileView()
                .environmentObject(accountManager)
                .environmentObject(calendarManager)
        }
    }
    
    // Quick access button with enhanced styling and shadow
    func quickAccessButton(_ title: String, systemImage: String, badgeCount: Int = 0, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 14) {
                // Icon with refined gradient and shadow
                ZStack(alignment: .topTrailing) {
                    Image(systemName: systemImage)
                        .font(.system(size: 20))
                        .foregroundColor(.textLight)
                        .frame(width: 48, height: 48)
                        .background(
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.gradientStart, .gradientMiddle, .gradientEnd],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.coloredShadow, radius: 8, x: 0, y: 4)
                            }
                        )
                    
                    // Badge overlay
                    if badgeCount > 0 {
                        Text(badgeCount > 9 ? "9+" : "\(badgeCount)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .padding(2)
                            .background(
                                Circle()
                                    .fill(Color.red)
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            )
                            .offset(x: 6, y: -6)
                    }
                }
                
                Text(title)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.bgCard)
                    .shadow(color: Color.cardShadow, radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Tool Button with enhanced gradient and shadow
    func toolButton(_ title: String, systemImage: String, background: Color, description: String, badgeCount: Int = 0, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 22) {
                // Icon with enhanced gradient, inner shadow, and badge
                ZStack(alignment: .topTrailing) {
                    Image(systemName: systemImage)
                        .font(.system(size: 26))
                        .foregroundColor(.textLight)
                        .frame(width: 64, height: 64)
                        .background(
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [background, background.opacity(0.85)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: background.opacity(0.25), radius: 8, x: 0, y: 4)
                                
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
                                    .frame(width: 62, height: 62)
                            }
                        )
                    
                    // Badge overlay
                    if badgeCount > 0 {
                        Text(badgeCount > 9 ? "9+" : "\(badgeCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .padding(2)
                            .background(
                                Circle()
                                    .fill(Color.red)
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            )
                            .offset(x: 8, y: -8)
                    }
                }
                
                // Title and description with refined typography
                VStack(spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 166)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.bgCard)
                    .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // Find the next RSVP'd event from CalendarManager
    private func findNextRSVPEvent() {
        guard let username = accountManager.currentUser else { 
            self.nextRSVPEvent = nil
            return 
        }
        
        // Get events from CalendarManager
        let events = calendarManager.events
        
        // Filter for events where user is attending (RSVP'd) or hosting
        let userRSVPEvents = events.filter { event in
            let isAttending = event.attendees.contains(where: { $0.lowercased() == username.lowercased() })
            let isHosting = event.host.lowercased() == username.lowercased()
            
            if isAttending {
            }
            if isHosting {
            }
            return isAttending || isHosting
        }
        
        
        if userRSVPEvents.isEmpty {
            self.nextRSVPEvent = nil
            return
        }
        
        // Sort by start time (earliest first)
        let sortedEvents = userRSVPEvents.sorted { $0.time < $1.time }
        
        // Find the next event (first event that hasn't ended yet)
        let now = Date()
        
        let upcomingEvents = sortedEvents.filter { event in
            // Consider events that haven't ended yet
            let hasNotEnded = event.endTime > now
            if hasNotEnded {
            } else {
            }
            return hasNotEnded
        }
        
        
        for (index, event) in upcomingEvents.enumerated() {
            let timeUntilStart = event.time.timeIntervalSince(now)
            let hoursUntilStart = timeUntilStart / 3600
        }
        
        // Set the next event (first in the sorted list)
        self.nextRSVPEvent = upcomingEvents.first
        
        if let nextEvent = self.nextRSVPEvent {
            let timeUntilStart = nextEvent.time.timeIntervalSince(now)
            let hoursUntilStart = timeUntilStart / 3600
        } else {
        }
    }
}

// Enhanced button style with improved animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

struct CommunityHubView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var chatManager: ChatManager
    
    var body: some View {
        ZStack {
            // Social Activity Feed & Trending Events
            SocialActivityFeedView()
                .environmentObject(accountManager)
                .environmentObject(chatManager)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.bgCard)
                        .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
                )
        }
    }
}

// MARK: - Profile View with refined styling
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var accountManager: UserAccountManager
    @StateObject private var profileManager: UserProfileManager
    @StateObject private var reputationManager = UserReputationManager()
    
    init() {
        // We'll initialize profileManager in onAppear with the account manager
        _profileManager = StateObject(wrappedValue: UserProfileManager())
    }
    
    // State for editable fields
    @State private var editMode: Bool = false
    @State private var name: String = ""
    @State private var university: String = ""
    @State private var degree: String = ""
    @State private var year: String = ""
    @State private var bio: String = ""
    
    // State for additional fields
    @State private var skills: [String] = ["Swift", "Python", "UI Design"]
    @State private var skillLevels: [String: String] = [:]
    @State private var newSkill: String = ""
    @State private var addingSkill: Bool = false
    @State private var editingSkillLevel: String? = nil
    
    // State for interests
    @State private var newInterest: String = ""
    @State private var addingInterest: Bool = false
    
    // For API feedback
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    // Profile picture state
    @State private var profileImage: Image?
    @State private var selectedImage: PhotosPickerItem?
    @State private var showImagePicker = false
    @State private var profileImageData: Data?
    @State private var isUploadingImage = false
    @State private var uploadError: String?
    @State private var showUploadAlert = false
    @State private var showImageGallery = false
    @State private var showFullScreenImage = false
    @State private var isImageLoading = false
    @ObservedObject private var imageManager = ImageManager.shared
    
    // Local storage for profile image
    @AppStorage("profileImageData") private var storedProfileImageData: Data = Data()
    
    // Refresh profile images from backend
    private func refreshProfileImages() {
        guard let username = accountManager.currentUser else { 
            return 
        }
        
        Task {
            await imageManager.loadUserImages(username: username, forceRefresh: true)
        }
    }
    
    
    
    // Upload profile picture to backend using new ImageManager
    private func uploadProfilePicture() async -> Bool {
        guard let imageData = profileImageData,
              let username = accountManager.currentUser else { 
            await MainActor.run {
                uploadError = "No image data or username available"
                showUploadAlert = true
            }
            return false 
        }
        
        await MainActor.run {
            isUploadingImage = true
            uploadError = nil
        }
        
        // Compress image if needed
        let compressedData = compressImage(UIImage(data: imageData) ?? UIImage(), maxSize: 1920)
        
        // For profile images, always set as primary (backend will handle unsetting others)
        let request = ImageUploadRequest(
            username: username,
            imageData: compressedData,
            imageType: .profile,
            isPrimary: true, // Always set profile images as primary
            caption: "",
            filename: "profile_\(Date().timeIntervalSince1970).jpg"
        )
        
        let success = await imageManager.uploadImage(request)
        
        await MainActor.run {
            isUploadingImage = false
            if !success {
                uploadError = imageManager.errorMessage ?? "Upload failed"
                showUploadAlert = true
            }
        }
        
        return success
    }
    
    private func loadImage(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else {
            await MainActor.run {
                uploadError = "Failed to load image data"
                showUploadAlert = true
            }
            return
        }
        
        await MainActor.run {
            self.profileImage = Image(uiImage: uiImage)
            self.profileImageData = data
            self.storedProfileImageData = data // Store locally as backup
            self.uploadError = nil // Clear any previous errors
        }
    }
    
    private func compressImage(_ image: UIImage, maxSize: CGFloat) -> Data {
        let size = image.size
        let aspectRatio = size.width / size.height
        
        var newSize = size
        if max(size.width, size.height) > maxSize {
            if aspectRatio > 1 {
                newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
            } else {
                newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
            }
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let compressedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return compressedImage.jpegData(compressionQuality: 0.8) ?? Data()
    }
    
    // Stats counters - now using real data
    @State private var eventsHosted: Int = 0
    @State private var eventsAttended: Int = 0
    @State private var friendsCount: Int = 0
    
    // Use backend-provided completion percentage if available
    private var effectiveProfileCompletionPercentage: Double {
        if profileManager.completionPercentage > 0.01 {
            return profileManager.completionPercentage / 100.0
        } else {
            // Fallback to simple calculation based on actual data
            let basicInfoComplete = !name.isEmpty && !university.isEmpty && !degree.isEmpty && !year.isEmpty
            let bioComplete = bio.count > 20
            let skillsComplete = skills.count >= 3
            let interestsComplete = profileManager.interests.count >= 3
            
            let completed = (basicInfoComplete ? 1 : 0) + (bioComplete ? 1 : 0) + (skillsComplete ? 1 : 0) + (interestsComplete ? 1 : 0)
            return Double(completed) / 4.0
        }
    }
    
    // Use backend-provided missing items if available
    private var effectiveMissingItems: [String] {
        if !profileManager.missingItems.isEmpty {
            return profileManager.missingItems
        } else {
            // Fallback to simple missing items based on actual data
            var missing: [String] = []
            if name.isEmpty { missing.append("Full Name") }
            if university.isEmpty { missing.append("University") }
            if degree.isEmpty { missing.append("Degree Program") }
            if year.isEmpty { missing.append("Academic Year") }
            if bio.count <= 20 { missing.append("Bio (at least 21 characters)") }
            if skills.count < 3 { missing.append("\(3 - skills.count) more skill(s)") }
            if profileManager.interests.count < 3 { missing.append("\(3 - profileManager.interests.count) more interest(s)") }
            return missing
        }
    }
    
    // Use backend-provided benefits message if available
    private var effectiveBenefitsMessage: String {
        if !profileManager.benefitsMessage.isEmpty {
            return profileManager.benefitsMessage
        } else {
            return "Complete your profile to unlock better auto-matching and build trust with other students!"
        }
    }
    
    // Get detailed completion data for each category - based on actual data
    private var completionDetails: [(String, Bool, String, Color)] {
        let basicInfoComplete = !name.isEmpty && !university.isEmpty && !degree.isEmpty && !year.isEmpty
        let bioComplete = bio.count > 20
        let skillsComplete = skills.count >= 3
        let interestsComplete = profileManager.interests.count >= 3
        
        return [
            ("Basic Info", basicInfoComplete, 
             basicInfoComplete ? "Complete" : "\((!name.isEmpty ? 1 : 0) + (!university.isEmpty ? 1 : 0) + (!degree.isEmpty ? 1 : 0) + (!year.isEmpty ? 1 : 0))/4", .brandPrimary),
            ("Bio", bioComplete, bioComplete ? "Complete" : "\(bio.count)/21 chars", .brandSecondary),
            ("Skills", skillsComplete, "\(skills.count)/3", .brandWarning),
            ("Interests", interestsComplete, "\(profileManager.interests.count)/3", .brandAccent)
        ]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean background with subtle pattern
                Color.bgSurface.ignoresSafeArea()
                
                // Subtle background patterns with improved aesthetics
                GeometryReader { geometry in
                    ZStack {
                        // Subtle geometric shapes
                        ForEach(0..<8) { i in
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.brandPrimary.opacity(0.015))
                                .frame(
                                    width: CGFloat.random(in: 80...160),
                                    height: CGFloat.random(in: 80...160)
                                )
                                .position(
                                    x: CGFloat.random(in: 0...geometry.size.width),
                                    y: CGFloat.random(in: 0...geometry.size.height)
                                )
                                .rotationEffect(.degrees(Double.random(in: 0...360)))
                        }
                        
                        // Larger color accents
                        Circle()
                            .fill(Color.brandPrimary.opacity(0.03))
                            .frame(width: 300, height: 300)
                            .blur(radius: 80)
                            .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)
                        
                        Circle()
                            .fill(Color.brandSecondary.opacity(0.02))
                            .frame(width: 250, height: 250)
                            .blur(radius: 60)
                            .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.7)
                    }
                }
                .ignoresSafeArea()
                
                if profileManager.isLoading {
                    VStack {
                        ProgressView("Loading profile...")
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.bgCard)
                                    .shadow(color: Color.cardShadow, radius: 10, x: 0, y: 5)
                            )
                    }
                    .zIndex(1)
                } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Profile header with refined shadow and spacing
                        profileHeader
                        
                        // NEW: Profile completion progress section
                        profileCompletionSection
                        
                        // User information section with refined spacing
                        infoSection
                        
                        // Skills section with refined layout
                        skillsSection
                            
                        // Interests section (added from API)
                        interestsSection
                            
                        // Auto-Matching preferences (added from API)
                        autoMatchingSection
                        
                        // User Reputation section
                        reputationSection
                            
                        // Refresh and Save API buttons
                        apiActionButtons
                    }
                    .padding()
                    .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                // Initialize profile manager with account manager for JWT authentication
                profileManager.setAccountManager(accountManager)
                
                // Load profile data
                if let username = accountManager.currentUser {
                    // Ensure we have JWT tokens before making API calls
                    if accountManager.accessToken != nil {
                        profileManager.fetchUserProfile(username: username) { success in
                            if success {
                                // Profile loaded successfully
                            }
                        }
                    } else {
                        // No JWT token available - user needs to log in again
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Your Profile")
                        .font(.headline)
                        .foregroundColor(.black)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editMode ? "Save" : "Edit") {
                        withAnimation {
                            if editMode {
                                saveProfileData()
                            }
                            editMode.toggle()
                        }
                    }
                    .foregroundColor(.brandPrimary)
                    .fontWeight(.medium)
                }
            }
            .photosPicker(isPresented: $showImagePicker, selection: $selectedImage, matching: .images)
            .onChange(of: selectedImage) { _, newValue in
                Task {
                    if let newValue = newValue {
                        // First load the image and wait for it to complete
                        await loadImage(from: newValue)
                        
                        // Small delay to ensure image data is set
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                        
                        // Check if we have image data before uploading
                        guard profileImageData != nil else {
                            await MainActor.run {
                                uploadError = "Image data not available for upload"
                                showUploadAlert = true
                            }
                            return
                        }
                        
                        // Upload to backend
                        let uploadSuccess = await uploadProfilePicture()
                        if uploadSuccess {
                            // Small delay to ensure backend has processed the image
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                            
                            // Reload images from backend and update UI (force refresh)
                            if let username = accountManager.currentUser {
                                await imageManager.loadUserImages(username: username, forceRefresh: true)
                                
                                // Post notification to refresh all profile image views
                                await MainActor.run {
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("ProfileImageUpdated"),
                                        object: nil,
                                        userInfo: ["username": username]
                                    )
                                }
                                
                                // Update the profile image with the newly uploaded image
                                if let primaryImage = imageManager.getPrimaryImage() {
                                    await MainActor.run {
                                        let fullURL = imageManager.getFullImageURL(primaryImage)
                                        if let url = URL(string: fullURL) {
                                            URLSession.shared.dataTask(with: url) { data, response, error in
                                                if let data = data, let uiImage = UIImage(data: data) {
                                                    DispatchQueue.main.async {
                                                        self.profileImage = Image(uiImage: uiImage)
                                                        self.profileImageData = data
                                                    }
                                                }
                                            }.resume()
                                        }
                                    }
                                }
                            }
                        } else {
                        }
                    }
                }
            }
            .onAppear {
                // Initialize fields with user data
                if let user = accountManager.currentUser {
                    name = user
                    // Pre-load skill levels from profileManager (if any already exist)
                    skillLevels = profileManager.skills
                    loadProfileData() // Load profile when view appears
                    // Fetch backend profile completion details
                    profileManager.fetchProfileCompletion(username: user) { _ in }
                    // Load real user stats
                    loadUserStats()
                    
                    // Load images using ImageManager (force refresh on app start)
                    Task {
                        await imageManager.loadUserImages(username: user, forceRefresh: true)
                    }
                }
            }
            .onReceive(imageManager.$userImages) { _ in
                // AsyncImage will automatically update when the ImageManager changes
                // No need for complex manual image loading
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ProfileImageUpdated"))) { _ in
                refreshProfileImages()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Profile Update"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .alert("Image Upload", isPresented: $showUploadAlert) {
                Button("OK") { }
            } message: {
                Text(uploadError ?? "Upload failed")
            }
            .fullScreenCover(isPresented: $showImageGallery) {
                if let username = accountManager.currentUser {
                    NavigationView {
                        ImageGalleryView(username: username)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        showImageGallery = false
                                    }
                                }
                            }
                    }
                }
            }
            .fullScreenCover(isPresented: $showFullScreenImage) {
                if let primaryImage = imageManager.getPrimaryImage() {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        
                        VStack {
                            // Header with close button
                            HStack {
                                Spacer()
                                Button("Done") {
                                    showFullScreenImage = false
                                }
                                .foregroundColor(.white)
                                .padding()
                            }
                            
                            Spacer()
                            
                            // Full screen image
                            imageManager.cachedAsyncImage(url: imageManager.getFullImageURL(primaryImage), contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            Spacer()
                        }
                    }
                } else if let profileImage = profileImage {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        
                        VStack {
                            // Header with close button
                            HStack {
                                Spacer()
                                Button("Done") {
                                    showFullScreenImage = false
                                }
                                .foregroundColor(.white)
                                .padding()
                            }
                            
                            Spacer()
                            
                            // Full screen image
                            profileImage
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipped()
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Profile Completion Section
    private var profileCompletionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with refined gradient
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [.gradientStart, .gradientMiddle, .gradientEnd],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.coloredShadow, radius: 4, x: 0, y: 2)
                    )
                
                Text("Profile Completion")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("\(Int(effectiveProfileCompletionPercentage * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(profileCompletionColor)
            }
            
            Divider()
                .background(Color.divider)
                .padding(.bottom, 6)
            
            // Main progress bar
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.bgSecondary)
                            .frame(height: 12)
                        
                        // Progress fill with animated gradient
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [profileCompletionColor.opacity(0.8), profileCompletionColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(effectiveProfileCompletionPercentage), height: 12)
                    }
                }
                .frame(height: 12)
                .padding(.vertical, 4)
            }
            
            // Detailed breakdown of completion
            VStack(spacing: 10) {
                ForEach(completionDetails, id: \.0) { detail in
                    HStack {
                        Text(detail.0)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .frame(width: 80, alignment: .leading)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background track
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.bgSecondary)
                                    .frame(height: 6)
                                
                                // Progress fill - simple complete/incomplete
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(detail.1 ? detail.3 : Color.gray.opacity(0.3))
                                    .frame(width: geometry.size.width * CGFloat(detail.1 ? 1.0 : 0.0), height: 6)
                            }
                        }
                        .frame(height: 6)
                        
                        Text(detail.2)
                            .font(.caption)
                            .foregroundColor(detail.1 ? .brandSuccess : .textSecondary)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
            }
            
            // Benefits message
            if effectiveProfileCompletionPercentage < 1.0 {
                Button(action: {
                    editMode = true
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.brandWarning)
                                .font(.caption)
                            
                            Text("Why complete your profile?")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.brandWarning.opacity(0.6))
                        }
                        
                        Text(effectiveBenefitsMessage)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.brandWarning.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Missing items breakdown
            if !effectiveMissingItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checklist")
                            .foregroundColor(.brandPrimary)
                            .font(.caption)
                        
                        Text("Still missing:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(effectiveMissingItems, id: \.self) { item in
                            Button(action: {
                                editMode = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(.brandPrimary.opacity(0.6))
                                        .font(.system(size: 4))
                                    
                                    Text(item)
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.brandPrimary.opacity(0.6))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.brandPrimary.opacity(0.05))
                )
            }
            
            // Completion celebration
            if effectiveProfileCompletionPercentage >= 1.0 {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.brandSuccess)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Profile Complete! 🎉")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.brandSuccess)
                            
                            Text("You're all set for optimal auto-matching")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.brandSuccess.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.brandSuccess.opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    // Benefits of complete profile
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "target")
                                .font(.caption2)
                                .foregroundColor(.brandSuccess)
                            
                            Text("Perfect matching")
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.caption2)
                                .foregroundColor(.brandSuccess)
                            
                            Text("Fast invites")
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundColor(.brandSuccess)
                            
                            Text("Top priority")
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.top, 6)
            }
            
            if effectiveProfileCompletionPercentage < 1.0 {
                VStack(spacing: 8) {
                    Button(action: {
                        editMode = true
                    }) {
                        HStack {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Complete Your Profile")
                                    .font(.subheadline.weight(.semibold))
                                
                                Text("\(effectiveMissingItems.count) item(s) remaining")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .opacity(0.6)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(profileCompletionColor.opacity(0.1))
                        )
                        .foregroundColor(profileCompletionColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 6)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    // Completion percentage color based on completion level
    private var profileCompletionColor: Color {
        let percentage = effectiveProfileCompletionPercentage
        if percentage < 0.3 {
            return .red
        } else if percentage < 0.6 {
            return .brandWarning
        } else if percentage < 0.9 {
            return .brandSecondary
        } else {
            return .brandSuccess
        }
    }
    
    // MARK: - API Action Buttons
    private var apiActionButtons: some View {
        HStack(spacing: 20) {
            Button(action: loadProfileData) {
                Label("Refresh Profile", systemImage: "arrow.clockwise")
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.brandSecondary.opacity(0.1))
                    )
                    .foregroundColor(Color.brandSecondary)
            }
            
            Button(action: saveProfileData) {
                Label("Save Profile", systemImage: "square.and.arrow.down")
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.brandPrimary.opacity(0.1))
                    )
                    .foregroundColor(Color.brandPrimary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Interests Section (new)
    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Your Interests", systemImage: "heart.fill")
            
            Divider()
                .background(Color.divider)
                .padding(.bottom, 6)
            
            // Display interests from API
            VStack(alignment: .leading, spacing: 12) {
                if profileManager.interests.isEmpty {
                    Text("No interests set")
                        .foregroundColor(.textSecondary)
                        .italic()
                        .padding(10)
                } else {
                    // Display each interest in a flow layout
                    ForEach(profileManager.interests, id: \.self) { interest in
                        SkillTag(skill: interest, canRemove: editMode) {
                            withAnimation {
                                profileManager.interests.removeAll { $0 == interest }
                            }
                        }
                        .padding(.bottom, 4)
                    }
                }
                
                if editMode {
                    if addingInterest {
                        HStack(spacing: 10) {
                            TextField("New interest", text: $newInterest)
                                .foregroundColor(.textPrimary)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.bgSecondary)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.divider, lineWidth: 1)
                                        )
                                )
                                .frame(width: 120)
                            
                            Button("Add") {
                                if !newInterest.isEmpty {
                                    withAnimation {
                                        profileManager.interests.append(newInterest)
                                        newInterest = ""
                                        addingInterest = false
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            colors: [.gradientStart, .gradientEnd],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.coloredShadow, radius: 4, x: 0, y: 2)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .font(.subheadline.weight(.medium))
                            
                            Button("Cancel") {
                                withAnimation {
                                    newInterest = ""
                                    addingInterest = false
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.cardStroke, lineWidth: 1)
                                    .background(Color.bgSecondary.cornerRadius(10))
                            )
                            .foregroundColor(.textPrimary)
                            .font(.subheadline.weight(.medium))
                        }
                        .padding(.vertical, 6)
                    } else {
                        Button(action: {
                            withAnimation {
                                addingInterest = true
                            }
                        }) {
                            Label("Add Interest", systemImage: "plus")
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.brandPrimary.opacity(0.1))
                                )
                                .foregroundColor(Color.brandPrimary)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Auto-Matching Preferences (new)
    private var autoMatchingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Auto-Matching", systemImage: "person.2.fill")
            
            Divider()
                .background(Color.divider)
                .padding(.bottom, 6)
            
            VStack(spacing: 20) {
                Toggle("Enable Auto-Matching", isOn: $profileManager.autoInviteEnabled)
                    .padding(.horizontal)
                    .toggleStyle(EnhancedToggleStyle())
                
                if profileManager.autoInviteEnabled {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Match Distance: \(Int(profileManager.preferredRadius)) km")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        
                        Slider(value: $profileManager.preferredRadius, in: 1...50, step: 1)
                            .accentColor(.brandSecondary)
                            .padding(.horizontal)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - API Methods
    private func loadProfileData() {
        guard let username = accountManager.currentUser, !username.isEmpty else {
            self.alertMessage = "Not logged in"
            self.showAlert = true
            return
        }
        
        
        // Use the profileManager to fetch the profile
        profileManager.fetchUserProfile(username: username) { success in
            if success {
                
                // Update local state variables with profile data
                self.name = self.profileManager.fullName.isEmpty ? username : self.profileManager.fullName
                self.university = self.profileManager.university
                self.degree = self.profileManager.degree
                self.year = self.profileManager.year
                self.bio = self.profileManager.bio
                
                // Update skills array and skill levels from profileManager
                self.skills = Array(self.profileManager.skills.keys)
                self.skillLevels = self.profileManager.skills
                
                // Log the loaded profile data
            } else {
                self.alertMessage = self.profileManager.errorMessage ?? "Failed to load profile"
                self.showAlert = true
            }
        }
    }
    
    private func saveProfileData() {
        guard let username = accountManager.currentUser, !username.isEmpty else {
            alertMessage = "Not logged in"
            showAlert = true
            return
        }
        
        // Check if we have JWT tokens for authentication
        guard accountManager.accessToken != nil else {
            alertMessage = "Authentication expired. Please log out and log back in."
            showAlert = true
            return
        }
        
        // Update skill levels for any skills that don't have levels yet
        for skill in skills {
            if skillLevels[skill] == nil {
                skillLevels[skill] = "INTERMEDIATE" // Default level
            }
        }
        
        // Use the profileManager to update the profile
        profileManager.updateUserProfile(
            username: username,
            fullName: name,
            university: university,
            degree: degree,
            year: year,
            bio: bio,
            interests: profileManager.interests,
            skills: skillLevels,
            autoInviteEnabled: profileManager.autoInviteEnabled,
            preferredRadius: profileManager.preferredRadius
        ) { success in
            if success {
                self.alertMessage = "Profile saved successfully"
                self.showAlert = true
            } else {
                self.alertMessage = self.profileManager.errorMessage ?? "Failed to save profile"
                self.showAlert = true
            }
        }
    }
    
    // MARK: - Profile Header with Professional Image Upload
    private var profileHeader: some View {
        VStack(spacing: 20) {
            // Profile Image Section
            ZStack {
                // Profile circle with refined layering
                Circle()
                    .fill(Color.bgAccent)
                    .frame(width: 134, height: 134)
                    .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
                
                Circle()
                    .fill(Color.bgCard)
                    .frame(width: 126, height: 126)
                
                // Profile image with loading state
                ZStack {
                    if let primaryImage = imageManager.getPrimaryImage() {
                        imageManager.cachedAsyncImage(url: imageManager.getFullImageURL(primaryImage), contentMode: .fill)
                            .frame(width: 112, height: 112)
                            .clipShape(Circle())
                            .onTapGesture {
                                showFullScreenImage = true
                            }
                    } else if let profileImage = profileImage {
                        profileImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 112, height: 112)
                            .clipShape(Circle())
                            .onTapGesture {
                                showFullScreenImage = true
                            }
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 112, height: 112)
                            .foregroundColor(Color.brandPrimary)
                    }
                    
                    // Loading overlay for upload
                    if isUploadingImage {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 112, height: 112)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                            )
                    }
                    
                    // Loading overlay for image loading
                    if isImageLoading {
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 112, height: 112)
                            .overlay(
                                VStack(spacing: 8) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.0)
                                    Text("Loading...")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                            )
                    }
                }
                
                // Camera button - always visible when in edit mode
                if editMode {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.gradientStart, .gradientMiddle, .gradientEnd],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 38, height: 38)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            )
                            .shadow(color: Color.cardShadow, radius: 6, x: 0, y: 3)
                    }
                    .offset(x: 42, y: 42)
                    .disabled(isUploadingImage)
                }
                
                // Refresh button - always visible
                Button(action: {
                    refreshProfileImages()
                }) {
                    Circle()
                        .fill(Color.bgCard)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.brandPrimary)
                                .font(.system(size: 14, weight: .medium))
                        )
                        .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
                }
                .offset(x: -42, y: 42)
                .disabled(isImageLoading || isUploadingImage)
            }
            .padding(.top, 16)
            
            
            // Professional Image Upload Section
            if editMode {
                VStack(spacing: 12) {
                    // Upload Actions
                    VStack(spacing: 12) {
                        // First row - Upload and Manage
                        HStack(spacing: 12) {
                            // Upload New Photo Button
                            Button(action: {
                                showImagePicker = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Upload Photo")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [.gradientStart, .gradientMiddle, .gradientEnd],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: Color.cardShadow, radius: 3, x: 0, y: 1)
                                )
                            }
                            .disabled(isUploadingImage)
                            
                            // Manage Gallery Button
                            Button(action: {
                                showImageGallery = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "photo.stack")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Manage Photos")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.brandPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.bgSecondary)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.brandPrimary, lineWidth: 1)
                                        )
                                )
                            }
                            .disabled(isUploadingImage)
                        }
                        
                        // Second row - Refresh
                        Button(action: {
                            refreshProfileImages()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Refresh Images")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue)
                                    .shadow(color: Color.cardShadow, radius: 3, x: 0, y: 1)
                            )
                        }
                        .disabled(isUploadingImage)
                    }
                    
                    // Upload Status
                    if isUploadingImage {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .brandPrimary))
                                .scaleEffect(0.8)
                            Text("Uploading image...")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    } else if let error = uploadError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    } else if imageManager.userImages.isEmpty {
                        Text("No photos uploaded yet")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    } else {
                        Text("\(imageManager.userImages.count) photo\(imageManager.userImages.count == 1 ? "" : "s") uploaded")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.bgCard)
                        .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal, 16)
            }
            
            // User name field with refined styling
            if editMode {
                TextField("Your Name", text: $name)
                    .font(.title2.bold())
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.bgSecondary)
                            .shadow(color: Color.cardShadow, radius: 3, x: 0, y: 1)
                    )
                    .padding(.horizontal, 50)
                    .padding(.top, 8)
            } else {
                Text(name.isEmpty ? "Your Name" : name)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(.textPrimary)
                    .padding(.top, 8)
            }
            
            // Username with refined icon styling
            HStack(spacing: 5) {
                Image(systemName: "at")
                    .font(.caption2)
                    .foregroundColor(.brandPrimary)
                
                Text(name.lowercased().replacingOccurrences(of: " ", with: ""))
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            .padding(.bottom, 8)
            
            // Profile stats with refined dividers
            HStack(spacing: 25) {
                statView(count: eventsHosted, title: "Events Hosted")
                
                Rectangle()
                    .fill(Color.divider)
                    .frame(width: 1, height: 30)
                
                statView(count: eventsAttended, title: "Events Attended")
                
                Rectangle()
                    .fill(Color.divider)
                    .frame(width: 1, height: 30)
                
                statView(count: friendsCount, title: "Friends")
            }
            .padding(.vertical, 12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    // Statistics counter with refined typography
    private func statView(count: Int, title: String) -> some View {
        VStack(spacing: 5) {
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }
    
    // MARK: - Info Section with refined styling
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with refined gradient
            SectionHeader(title: "Academic Information", systemImage: "book.fill")
            
            Divider()
                .background(Color.divider)
                .padding(.bottom, 6)
            
            
            // Info rows with refined spacing
            InfoRow(title: "University", value: $university, editMode: editMode, suggestions: profileManager.getSuggestedUniversities())
            InfoRow(title: "Degree", value: $degree, editMode: editMode, suggestions: profileManager.getSuggestedDegrees())
            InfoRow(title: "Year", value: $year, editMode: editMode, suggestions: profileManager.getSuggestedYears())
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Bio")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                
                if editMode {
                    TextEditor(text: $bio)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(.textPrimary)
                        .frame(minHeight: 100)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.bgSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.divider, lineWidth: 1)
                                )
                        )
                } else {
                    Text(bio)
                        .foregroundColor(.textPrimary)
                        .lineSpacing(5)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.bgSecondary)
                        )
                }
            }
            .padding(.top, 6)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Skills Section with refined layout
    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Skills & Expertise", systemImage: "star.fill")
            
            Divider()
                .background(Color.divider)
                .padding(.bottom, 6)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(skills.indices, id: \.self) { index in
                    SkillTagWithLevel(
                        skill: skills[index],
                        level: skillLevels[skills[index]] ?? "INTERMEDIATE",
                        canEdit: editMode,
                        isEditing: editingSkillLevel == skills[index],
                        onRemove: {
                        if editMode {
                            withAnimation {
                                    let skill = skills[index]
                                skills.remove(at: index)
                                    skillLevels.removeValue(forKey: skill)
                                }
                            }
                        },
                        onEdit: {
                            if editMode {
                                editingSkillLevel = editingSkillLevel == skills[index] ? nil : skills[index]
                            }
                        },
                        onLevelSelected: { level in
                            skillLevels[skills[index]] = level
                            editingSkillLevel = nil
                        }
                    )
                    .padding(.bottom, 4)
                }
                
                if editMode {
                    if addingSkill {
                        HStack(spacing: 10) {
                            TextField("New skill", text: $newSkill)
                                .foregroundColor(.textPrimary)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.bgSecondary)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.divider, lineWidth: 1)
                                        )
                                )
                                .frame(width: 120)
                            
                            Button("Add") {
                                if !newSkill.isEmpty {
                                    withAnimation {
                                        skills.append(newSkill)
                                        skillLevels[newSkill] = "INTERMEDIATE"
                                        newSkill = ""
                                        addingSkill = false
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            colors: [.gradientStart, .gradientEnd],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.coloredShadow, radius: 4, x: 0, y: 2)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .font(.subheadline.weight(.medium))
                            
                            Button("Cancel") {
                                withAnimation {
                                    newSkill = ""
                                    addingSkill = false
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.cardStroke, lineWidth: 1)
                                    .background(Color.bgSecondary.cornerRadius(10))
                            )
                            .foregroundColor(.textPrimary)
                            .font(.subheadline.weight(.medium))
                        }
                        .padding(.vertical, 6)
                    } else {
                        Button(action: {
                            withAnimation {
                                addingSkill = true
                            }
                        }) {
                            Label("Add Skill", systemImage: "plus")
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.brandPrimary.opacity(0.1))
                                )
                                .foregroundColor(Color.brandPrimary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    
    // MARK: - User Reputation section
    private var reputationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "User Reputation", systemImage: "star.fill")
            
            Divider()
                .background(Color.divider)
                .padding(.bottom, 6)
            
            // User reputation view embedded directly
            if let username = accountManager.currentUser {
                // Load reputation display as embedded view
                VStack(alignment: .leading, spacing: 15) {
                    if reputationManager.isLoading {
                        HStack {
                            Spacer()
                            ProgressView("Loading reputation data...")
                            Spacer()
                        }
                    } else {
                        // Rating stars
                        HStack {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= Int(reputationManager.userStats.averageRating.rounded()) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                            Text(String(format: "%.1f", reputationManager.userStats.averageRating))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(.leading, 5)
                        }
                        
                        // Trust level
                        HStack(spacing: 10) {
                            Image(systemName: trustLevelIcon)
                                .foregroundColor(trustLevelColor)
                            Text(reputationManager.userStats.trustLevel.title)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                        }
                        
                        // Recent ratings preview if available
                        if !reputationManager.userRatings.isEmpty {
                            Divider()
                                .padding(.vertical, 5)
                            
                            Text("Recent Reviews")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                                .padding(.bottom, 5)
                            
                            ForEach(reputationManager.userRatings.prefix(1)) { rating in
                                recentRatingRow(rating: rating)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 5)
                        
                        // View details button
                        Button(action: {
                            // Show full ratings list
                            showRatingsList = true
                        }) {
                            Text("View All Reviews")
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 15)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.brandPrimary))
                        }
                    }
                }
                .padding(.vertical, 5)
                .onAppear {
                    // Load reputation data - always use real data
                    reputationManager.fetchUserReputation(username: username) { _ in
                        reputationManager.fetchUserRatings(username: username) { _ in }
                    }
                }
            } else {
                Text("Sign in to view your reputation")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
        .sheet(isPresented: $showRatingsList) {
            if let username = accountManager.currentUser {
                ratingsListView(username: username)
            }
        }
    }
    
    // MARK: - Helper views for reputation
    
    @State private var showRatingsList = false
    
    private func recentRatingRow(rating: UserRating) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(rating.fromUser)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Format date to show only month and day
                Text(parseDate(from: rating.createdAt), style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= rating.rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
            
            if let reference = rating.reference, !reference.isEmpty {
                Text(reference)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 5)
    }
    
    private func parseDate(from dateString: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString) ?? Date()
    }
    
    private func ratingsListView(username: String) -> some View {
        NavigationView {
            List {
                if reputationManager.userRatings.isEmpty {
                    Text("No reviews yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(reputationManager.userRatings) { rating in
                        recentRatingRow(rating: rating)
                            .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("All Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        showRatingsList = false
                    }
                }
            }
        }
    }
    
    // Helper computed properties
    private var trustLevelIcon: String {
        switch reputationManager.userStats.trustLevel.level {
        case 1: return "person"
        case 2: return "person.fill"
        case 3: return "person.fill.checkmark"
        case 4: return "person.fill.badge.plus"
        case 5: return "crown.fill"
        default: return "person"
        }
    }
    
    private var trustLevelColor: Color {
        switch reputationManager.userStats.trustLevel.level {
        case 1: return .secondary
        case 2: return .blue
        case 3: return .green
        case 4: return .purple
        case 5: return .orange
        default: return .secondary
        }
    }
    
    
    // MARK: - Load User Stats
    private func loadUserStats() {
        guard let username = accountManager.currentUser else { return }
        
        // Load friends count from backend API
        loadFriendsCount(username: username)
        
        // Load events hosted and attended from backend API
        loadReputationData(username: username)
    }
    
    private func loadFriendsCount(username: String) {
        guard let url = URL(string: "\(APIConfig.primaryBaseURL)/get_friends/\(username)/") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    do {
                        let friendsData = try JSONDecoder().decode(FriendsData.self, from: data)
                        self.friendsCount = friendsData.friends.count
                    } catch {
                        // Fallback to account manager friends count
                        self.friendsCount = self.accountManager.friends.count
                    }
                } else {
                    // Fallback to account manager friends count
                    self.friendsCount = self.accountManager.friends.count
                }
            }
        }.resume()
    }
    
    private func loadReputationData(username: String) {
        // Use the correct API endpoint for user reputation data
        guard let url = URL(string: "\(APIConfig.primaryBaseURL)/get_user_reputation/\(username)/") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    do {
                        let reputationResponse = try JSONDecoder().decode(UserReputationResponse.self, from: data)
                        
                        // Use the correct counts from the reputation API
                        self.eventsHosted = reputationResponse.events_hosted
                        self.eventsAttended = reputationResponse.events_attended
                    } catch {
                    }
                } else {
                }
            }
        }.resume()
    }
    
    // MARK: - Profile Picture Functions
}

// MARK: - Support Views for Profile with refined styling
struct SectionHeader: View {
    let title: String
    let systemImage: String
    
    var body: some View {
        HStack {
            // Icon with enhanced gradient
            Image(systemName: systemImage)
                .foregroundColor(.white)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [.gradientStart, .gradientMiddle, .gradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.coloredShadow, radius: 4, x: 0, y: 2)
                )
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            Spacer()
        }
    }
}

struct InfoRow: View {
    let title: String
    @Binding var value: String
    let editMode: Bool
    let suggestions: [String]
    
    @State private var showSuggestions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .frame(width: 100, alignment: .leading)
                
                if editMode {
                    HStack {
                        TextField(title, text: $value)
                            .foregroundColor(.textPrimary)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.bgSecondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.divider, lineWidth: 1)
                                    )
                            )
                        
                        if !suggestions.isEmpty && value.isEmpty {
                            Button(action: {
                                showSuggestions.toggle()
                            }) {
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.brandPrimary)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.brandPrimary.opacity(0.1))
                                    )
                            }
                        }
                    }
                } else {
                    Text(value.isEmpty ? "Not specified" : value)
                        .font(.subheadline)
                        .foregroundColor(value.isEmpty ? .textMuted : .textPrimary)
                }
                Spacer()
            }
            
            // Suggestions dropdown
            if editMode && showSuggestions && !suggestions.isEmpty && value.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(suggestions.prefix(5), id: \.self) { suggestion in
                        Button(action: {
                            value = suggestion
                            showSuggestions = false
                        }) {
                            Text(suggestion)
                                .font(.caption)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.bgSecondary)
                                )
                        }
                    }
                }
                .padding(.leading, 100)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 6)
    }
}

struct SkillTag: View {
    let skill: String
    let canRemove: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(skill)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
                .padding(.leading, 12)
                .padding(.trailing, canRemove ? 6 : 12)
                .padding(.vertical, 8)
            
            if canRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.brandAccent.opacity(0.85))
                        .font(.caption)
                }
                .padding(.trailing, 8)
            }
        }
        .background(
            Capsule()
                .fill(Color.bgSecondary)
                .overlay(
                    Capsule()
                        .stroke(Color.cardStroke, lineWidth: 1)
                )
        )
    }
}

// MARK: - Skill Tag with Level
struct SkillTagWithLevel: View {
    let skill: String
    let level: String
    let canEdit: Bool
    let isEditing: Bool
    let onRemove: () -> Void
    let onEdit: () -> Void
    let onLevelSelected: (String) -> Void
    
    private let levels = ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(skill)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                    .padding(.leading, 12)
                    .padding(.trailing, canEdit ? 6 : 12)
                    .padding(.vertical, 8)
                
                if canEdit {
                    HStack(spacing: 8) {
                        Button(action: onEdit) {
                            Image(systemName: isEditing ? "chevron.up" : "chevron.down")
                                .foregroundColor(.brandSecondary)
                                .font(.caption)
                        }
                        .padding(.trailing, 2)
                        
                        Button(action: onRemove) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.brandAccent.opacity(0.85))
                                .font(.caption)
                        }
                        .padding(.trailing, 8)
                    }
                }
            }
            .background(
                Capsule()
                    .fill(Color.bgSecondary)
                    .overlay(
                        Capsule()
                            .stroke(Color.cardStroke, lineWidth: 1)
                    )
            )
            
            if isEditing {
                // Level selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Skill Level:")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .padding(.leading, 4)
                    
                    HStack(spacing: 10) {
                        ForEach(levels, id: \.self) { levelOption in
                            Button(action: {
                                onLevelSelected(levelOption)
                            }) {
                                Text(formattedLevel(levelOption))
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(level == levelOption ? Color.brandPrimary : Color.bgSurface)
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.brandPrimary.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(level == levelOption ? .white : .textPrimary)
                            }
                        }
                    }
                    .padding(.leading, 4)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.bgSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.divider, lineWidth: 1)
                        )
                )
                .padding(.leading, 8)
                .padding(.bottom, 4)
            } else {
                // Just show the level beneath the skill
                Text(formattedLevel(level))
                    .font(.caption)
                    .foregroundColor(levelColor(level))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(levelColor(level).opacity(0.1))
                    )
                    .padding(.leading, 12)
            }
        }
    }
    
    private func formattedLevel(_ level: String) -> String {
        return level.prefix(1).uppercased() + level.dropFirst().lowercased()
    }
    
    private func levelColor(_ level: String) -> Color {
        switch level {
        case "BEGINNER":
            return .brandSecondary
        case "INTERMEDIATE":
            return .brandPrimary
        case "ADVANCED":
            return .brandWarning
        case "EXPERT":
            return .brandAccent
        default:
            return .brandPrimary
        }
    }
}

// Enhanced toggle style with refined animation
struct EnhancedToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(.subheadline)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            ZStack {
                // Track with gradient when active
                if configuration.isOn {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(
                            colors: [.gradientStart, .gradientEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: 50, height: 30)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.bgSecondary)
                        .frame(width: 50, height: 30)
                }
                
                // Enhanced shadow on active state
                if configuration.isOn {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.clear)
                        .frame(width: 50, height: 30)
                        .shadow(color: Color.coloredShadow, radius: 4, x: 0, y: 0)
                }
                
                // Knob with enhanced shadow
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.cardShadow, radius: 3, x: 0, y: 1)
                    .frame(width: 24, height: 24)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isOn)
            }
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}

// MARK: - Social Activity Feed & Trending Events
struct SocialActivityFeedView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var chatManager: ChatManager
    @StateObject private var locationManager = LocationManager()
    @State private var trendingEvents: [StudyEvent] = []
    @State private var recentActivity: [SocialActivity] = []
    @State private var isLoading = false
    @State private var selectedEvent: StudyEvent? = nil
    @State private var showEventDetail = false
    
    // Quick Actions Navigation States
    @State private var showEventCreation = false
    @State private var showFriendsView = false
    @State private var showMapView = false
    @State private var showProfileView = false
    
    private let baseURL = APIConfig.primaryBaseURL
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerView
                
                // Trending Events Section
                trendingEventsSection
                
                // Recent Activity Section
                recentActivitySection
                
                // Quick Actions
                quickActionsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(Color.bgSurface.ignoresSafeArea())
        .onAppear {
            initializeView()
        }
        .sheet(isPresented: $showEventDetail) {
            if let event = selectedEvent {
                NavigationStack {
                    EventDetailView(event: event, studyEvents: .constant([]), onRSVP: { _ in })
                }
            }
        }
        .sheet(isPresented: $showEventCreation) {
            NavigationStack {
                EventCreationView(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)) { _ in
                    // Event created - could refresh data here
                }
                .environmentObject(accountManager)
                .environmentObject(CalendarManager(accountManager: accountManager))
            }
        }
        .sheet(isPresented: $showFriendsView) {
            NavigationStack {
                FriendsListView()
                    .environmentObject(accountManager)
                    .environmentObject(chatManager)
            }
        }
        .sheet(isPresented: $showMapView) {
            NavigationStack {
                StudyMapView()
                    .environmentObject(accountManager)
                    .environmentObject(CalendarManager(accountManager: accountManager))
            }
        }
        .sheet(isPresented: $showProfileView) {
            NavigationStack {
                ProfileView()
                    .environmentObject(accountManager)
                    .environmentObject(CalendarManager(accountManager: accountManager))
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("community_hub".localized)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.textPrimary)
                    
                    Text("\(trendingEvents.count) trending events • \(recentActivity.count) recent activities")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Live counter with FOMO
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.brandSuccess)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isLoading)
                        
                        Text("LIVE")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.brandSuccess)
                    }
                    
                    Text("\(getActiveUsersCount()) online")
                        .font(.caption2)
                        .foregroundColor(.textMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.brandSuccess.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private func getActiveUsersCount() -> Int {
        // Calculate based on actual data
        return trendingEvents.count + recentActivity.count
    }
    
    // MARK: - Trending Events Section
    private var trendingEventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.brandWarning)
                        .font(.title3)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isLoading)
                    
                    Text("Trending Events")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.textPrimary)
                }
                
                Spacer()
                
                Text("\(trendingEvents.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.brandWarning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brandWarning.opacity(0.1))
                    .cornerRadius(8)
            }
            
            if isLoading {
                trendingEventsLoadingView
            } else if trendingEvents.isEmpty {
                trendingEventsEmptyView
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(trendingEvents.prefix(5)) { event in
                            TrendingEventCard(event: event) {
                                selectedEvent = event
                                showEventDetail = true
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(20)
        .background(Color.bgCard)
        .cornerRadius(16)
        .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.brandPrimary)
                    .font(.title3)
                
                Text("Recent Activity")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button(action: {
                    loadSocialData()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            
            if isLoading {
                activityLoadingView
            } else if recentActivity.isEmpty {
                activityEmptyView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(recentActivity.prefix(8)) { activity in
                        ActivityCard(activity: activity)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.bgCard)
        .cornerRadius(16)
        .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.brandAccent)
                    .font(.title3)
                
                Text("Quick Actions")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionCard(
                    icon: "plus.circle.fill",
                    title: "Create Event",
                    subtitle: "Start something new",
                    color: .brandPrimary
                ) {
                    showEventCreation = true
                }
                
                QuickActionCard(
                    icon: "person.2.fill",
                    title: "Find Friends",
                    subtitle: "Connect with others",
                    color: .brandSecondary,
                    badgeCount: chatManager.totalUnreadCount
                ) {
                    showFriendsView = true
                }
                
                QuickActionCard(
                    icon: "location.fill",
                    title: "Nearby Events",
                    subtitle: "Discover local",
                    color: .brandSuccess
                ) {
                    showMapView = true
                }
                
                QuickActionCard(
                    icon: "star.fill",
                    title: "Rate Events",
                    subtitle: "Share feedback",
                    color: .brandWarning
                ) {
                    showProfileView = true
                }
            }
        }
        .padding(20)
        .background(Color.bgCard)
        .cornerRadius(16)
        .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Loading Views
    private var trendingEventsLoadingView: some View {
        HStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.bgSecondary)
                    .frame(width: 200, height: 120)
                    .shimmer()
            }
        }
    }
    
    private var activityLoadingView: some View {
        VStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.bgSecondary)
                        .frame(width: 40, height: 40)
                        .shimmer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.bgSecondary)
                            .frame(height: 16)
                            .shimmer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.bgSecondary)
                            .frame(width: 120, height: 12)
                            .shimmer()
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Empty Views
    private var trendingEventsEmptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "flame")
                .font(.system(size: 40))
                .foregroundColor(.textMuted)
            
            Text("No trending events yet")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.textSecondary)
            
            Text("Be the first to create an event!")
                .font(.caption)
                .foregroundColor(.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var activityEmptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 40))
                .foregroundColor(.textMuted)
            
            Text("No recent activity")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.textSecondary)
            
            Text("Join events to see activity here")
                .font(.caption)
                .foregroundColor(.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Data Loading
    private func loadSocialData() {
        isLoading = true
        
        // Load trending events
        loadTrendingEvents()
        
        // Load recent activity
        loadRecentActivity()
        
        // No artificial delay - loading state handled by actual data completion
        isLoading = false
    }
    
    private func loadTrendingEvents() {
        // Load real trending events from backend
        guard let username = accountManager.currentUser else { return }
        
        let url = URL(string: "\(baseURL)/get_trending_events/")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    do {
                        let response = try JSONDecoder().decode(EventsResponse.self, from: data)
                        // Filter and sort events
                        var filteredEvents = response.events
                            .filter { event in
                                // Only show events happening soon (next 24 hours) for urgency
                                let timeUntilEvent = event.time.timeIntervalSinceNow
                                return timeUntilEvent > 0 && timeUntilEvent < 86400 // 24 hours
                            }
                        
                        // If location is available, prioritize nearby events
                        if locationManager.isLocationAvailable() {
                            filteredEvents = locationManager.getNearbyEvents(filteredEvents, radiusKm: 25.0)
                        }
                        
                        // Sort by attendee count (social proof) then by time (urgency)
                        self.trendingEvents = filteredEvents
                            .sorted { event1, event2 in
                                if event1.attendees.count != event2.attendees.count {
                                    return event1.attendees.count > event2.attendees.count
                                }
                                return event1.time < event2.time
                            }
                            .prefix(5)
                            .map { $0 }
                    } catch {
                        self.trendingEvents = []
                    }
                } else {
                    self.trendingEvents = []
                }
            }
        }.resume()
    }
    
    
    private func loadRecentActivity() {
        // Load real recent activity from backend
        guard let username = accountManager.currentUser else { return }
        
        let url = URL(string: "\(baseURL)/get_recent_activity/\(username)/")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    do {
                        let response = try JSONDecoder().decode(RecentActivityResponse.self, from: data)
                        self.recentActivity = response.activities
                            .sorted { $0.timestamp > $1.timestamp } // Most recent first
                            .prefix(8)
                            .map { $0 }
                    } catch {
                        self.recentActivity = []
                    }
                } else {
                    self.recentActivity = []
                }
            }
        }.resume()
    }
    
    // MARK: - Lifecycle
    private func initializeView() {
        // Do not auto-start location updates here; ask explicitly after onboarding
        loadTrendingEvents()
        loadRecentActivity()
    }
}

// MARK: - Supporting Views and Models

struct TrendingEventCard: View {
    let event: StudyEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Urgency Badge
                HStack {
                    if isUrgent {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text(urgencyText)
                                .font(.caption.weight(.bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.brandWarning)
                        .cornerRadius(8)
                    } else {
                        Text(event.eventType.rawValue.capitalized)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(eventTypeColor)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // Social Proof with FOMO
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                        Text("\(event.attendees.count) going")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(.brandSuccess)
                }
                
                // Event Title with FOMO indicators
                Text(event.title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                
                // Time with urgency styling
                HStack(spacing: 4) {
                    Image(systemName: isUrgent ? "clock.fill" : "clock")
                        .font(.caption)
                        .foregroundColor(isUrgent ? .brandWarning : .textSecondary)
                    Text(formatEventTime(event.time))
                        .font(.caption.weight(isUrgent ? .semibold : .regular))
                        .foregroundColor(isUrgent ? .brandWarning : .textSecondary)
                }
                
                Spacer()
                
                // Host Info with verification
                HStack(spacing: 6) {
                    Image(systemName: event.hostIsCertified ? "checkmark.seal.fill" : "person.fill")
                        .font(.caption)
                        .foregroundColor(event.hostIsCertified ? .brandSuccess : .textSecondary)
                    
                    Text(event.host)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(16)
            .frame(width: 200, height: 140)
            .background(Color.bgCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isUrgent ? Color.brandWarning.opacity(0.5) : Color.cardStroke, lineWidth: isUrgent ? 2 : 1)
            )
            .shadow(color: isUrgent ? Color.brandWarning.opacity(0.3) : Color.cardShadow, radius: isUrgent ? 8 : 4, x: 0, y: isUrgent ? 4 : 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var isUrgent: Bool {
        let timeUntilEvent = event.time.timeIntervalSinceNow
        return timeUntilEvent > 0 && timeUntilEvent < 3600 // Less than 1 hour
    }
    
    private var urgencyText: String {
        let timeUntilEvent = event.time.timeIntervalSinceNow
        if timeUntilEvent < 1800 { // Less than 30 minutes
            return "NOW!"
        } else {
            return "SOON"
        }
    }
    
    private var eventTypeColor: Color {
        switch event.eventType {
        case .study: return .brandPrimary
        case .party: return .brandWarning
        case .business: return .brandSecondary
        case .cultural: return .brandWarning
        case .academic: return .brandSuccess
        case .networking: return .brandPrimary
        case .social: return .brandSuccess
        case .language_exchange: return .brandSecondary
        case .other: return .textSecondary
        }
    }
    
    private func formatEventTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ActivityCard: View {
    let activity: SocialActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Image(systemName: activity.avatar)
                .font(.title2)
                .foregroundColor(.brandPrimary)
                .frame(width: 40, height: 40)
                .background(Color.brandPrimary.opacity(0.1))
                .cornerRadius(20)
            
            // Activity Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.description)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.textPrimary)
                
                Text(timeAgoString(from: activity.timestamp))
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Activity Icon
            Image(systemName: activity.type.icon)
                .font(.caption)
                .foregroundColor(activity.type.color)
                .frame(width: 24, height: 24)
                .background(activity.type.color.opacity(0.1))
                .cornerRadius(12)
        }
        .padding(12)
        .background(Color.bgSecondary)
        .cornerRadius(12)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let badgeCount: Int
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String, color: Color, badgeCount: Int = 0, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.badgeCount = badgeCount
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                        .frame(width: 40, height: 40)
                        .background(color.opacity(0.1))
                        .cornerRadius(20)
                    
                    // Badge overlay
                    if badgeCount > 0 {
                        Text(badgeCount > 9 ? "9+" : "\(badgeCount)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 14, minHeight: 14)
                            .padding(2)
                            .background(
                                Circle()
                                    .fill(Color.red)
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            )
                            .offset(x: 4, y: -4)
                    }
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.bgCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.cardStroke, lineWidth: 1)
            )
            .shadow(color: Color.cardShadow, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Data Models

struct RecentActivityResponse: Codable {
    let activities: [SocialActivity]
}

struct UserReputationResponse: Codable {
    let username: String
    let total_ratings: Int
    let average_rating: Double
    let events_hosted: Int
    let events_attended: Int
    let trust_level: TrustLevelInfo
}

struct TrustLevelInfo: Codable {
    let level: Int
    let title: String
}

struct SocialActivity: Identifiable, Codable {
    let id: UUID
    let type: ActivityType
    let username: String
    let eventTitle: String?
    let timestamp: Date
    let avatar: String
    
    var description: String {
        switch type {
        case .eventJoined:
            return "\(username) joined \(eventTitle ?? "an event")"
        case .eventCreated:
            return "\(username) created \(eventTitle ?? "an event")"
        case .friendAdded:
            return "\(username) made a new friend"
        case .eventCompleted:
            return "\(username) completed \(eventTitle ?? "an event")"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, username, eventTitle = "event_title", timestamp, avatar
    }
}

enum ActivityType: String, Codable, CaseIterable {
    case eventJoined = "event_joined"
    case eventCreated = "event_created"
    case friendAdded = "friend_added"
    case eventCompleted = "event_completed"
    
    var icon: String {
        switch self {
        case .eventJoined: return "person.badge.plus"
        case .eventCreated: return "plus.circle"
        case .friendAdded: return "person.2"
        case .eventCompleted: return "checkmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .eventJoined: return .brandSuccess
        case .eventCreated: return .brandPrimary
        case .friendAdded: return .brandSecondary
        case .eventCompleted: return .brandWarning
        }
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: phase)
                    .animation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                        value: phase
                    )
            )
            .onAppear {
                phase = 200
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
