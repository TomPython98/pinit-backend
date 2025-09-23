import Foundation
import SwiftUI
import MapKit
import Combine

// Import the UserProfileManager from ViewModels
// (Note: Swift automatically finds files in the project, no path needed)

// MARK: - Color Extensions with Refined Professional Palette
//  AppColors.swift
//  YourProjectName
//
//  Created by Your Name on 2025-03-XX.

extension Color {
    // Primary interface colors - refined tones
    static let bgSurface = Color(red: 248/255, green: 250/255, blue: 255/255)        // Light bg surface (slightly bluer tint)
    static let bgCard = Color(red: 255/255, green: 255/255, blue: 255/255)           // White card background
    static let bgAccent = Color(red: 240/255, green: 242/255, blue: 255/255)         // Accented bg (light purple hue)
    static let bgSecondary = Color(red: 242/255, green: 245/255, blue: 250/255)      // Secondary bg (slightly bluer)
    
    // Vibrant brand colors - slightly more saturated
    static let brandPrimary = Color(red: 79/255, green: 70/255, blue: 229/255)       // Indigo primary
    static let brandSecondary = Color(red: 59/255, green: 130/255, blue: 246/255)    // Royal blue (more professional)
    static let brandAccent = Color(red: 236/255, green: 72/255, blue: 153/255)       // Pink
    static let brandWarning = Color(red: 245/255, green: 158/255, blue: 11/255)      // Amber
    static let brandSuccess = Color(red: 16/255, green: 185/255, blue: 129/255)      // Emerald
    
    // Gradient colors - enhanced
    static let gradientStart = Color(red: 79/255, green: 70/255, blue: 229/255)      // Indigo start
    static let gradientMiddle = Color(red: 88/255, green: 80/255, blue: 236/255)     // Transition color
    static let gradientEnd = Color(red: 99/255, green: 102/255, blue: 241/255)       // Lighter indigo end
    
    // Text colors - enhanced contrast
    static let textPrimary = Color(red: 15/255, green: 23/255, blue: 42/255)         // Near black (darker)
    static let textSecondary = Color(red: 71/255, green: 85/255, blue: 105/255)      // Slate 600
    static let textLight = Color(red: 255/255, green: 255/255, blue: 255/255)        // White text
    static let textMuted = Color(red: 148/255, green: 163/255, blue: 184/255)        // Slate 400
    
    static let socialDark = Color(red: 20/255, green: 42/255, blue: 80/255)
    static let socialMedium = Color(red: 40/255, green: 80/255, blue: 135/255)
    static let socialPrimary = Color(red: 70/255, green: 130/255, blue: 210/255)
    static let socialAccent = Color(red: 130/255, green: 195/255, blue: 235/255)
    static let socialLight = Color(red: 190/255, green: 225/255, blue: 245/255)
    
    // UI Elements - refined
    static let divider = Color(red: 226/255, green: 232/255, blue: 240/255)          // Slate 200
    static let cardShadow = Color(red: 15/255, green: 23/255, blue: 42/255).opacity(0.08) // Slate 900 8%
    static let cardStroke = Color(red: 226/255, green: 232/255, blue: 240/255)       // Slate 200
    static let coloredShadow = Color(red: 79/255, green: 70/255, blue: 229/255).opacity(0.15) // Indigo shadow
    
    // Additional UI elements
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
    @State private var showDebugView = false
    @State private var selectedEvent: StudyEvent? = nil
    @State private var showEventDetailSheet = false
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var calendarManager: CalendarManager
    
    // State for next RSVP'd event
    @State private var nextRSVPEvent: StudyEvent? = nil
    @State private var isLoadingEvents = false
    
    // Animation state
    @State private var isAnimating = false

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
                            sectionHeader("Academic Tools")
                            
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
                        // Find next RSVP'd event from CalendarManager
                        findNextRSVPEvent()
                    }
                    .onReceive(calendarManager.$events) { _ in
                        // Update when calendar events change
                        findNextRSVPEvent()
                    }
                }
                .safeAreaInset(edge: .top) {
                    customTopBar
                }
            }
        }
        .sheet(isPresented: $showEventDetailSheet, onDismiss: {
            selectedEvent = nil
        }) {
            if let event = selectedEvent {
                EventDetailView(event: event, studyEvents: .constant([event]), onRSVP: { _ in
                    // Event update logic would go here
                })
                .environmentObject(accountManager)
            }
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
            
            Text("See All")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.brandPrimary)
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
                    .environmentObject(UserProfileManager())
                #endif
            }
            
            Spacer()
            
            // App Logo & Title with enhanced typography
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundColor(.brandPrimary)
                
                Text("PinIt")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(.textPrimary)
                    .tracking(0.2) // Slightly increased letter spacing
            }
            
            Spacer()
            
            // Debug button for testing push notifications
            Button(action: {
                // Navigate to debug view
                showDebugView = true
            }) {
                Image(systemName: "ladybug.fill")
                    .font(.title2)
                    .foregroundColor(.brandSecondary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.bgCard)
                            .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 3)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            .sheet(isPresented: $showDebugView) {
                NavigationView {
                    DebugView()
                }
            }
            
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
                if let event = nextRSVPEvent {
                    selectedEvent = event
                    showEventDetailSheet = true
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
    }
    
    // MARK: - Tools Grid View with refined cards and enhanced shadows
    var toolsGridView: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 20
        ) {
            toolButton(
                "Study Chat",
                systemImage: "message.fill",
                background: Color.brandPrimary,
                description: "Connect with classmates"
            ) {
                withAnimation(.spring()) {
                    showFriendsView = true
                }
            }
            .sheet(isPresented: $showFriendsView) {
                FriendsListView()
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
                description: "Join university activities"
            ) {
                withAnimation(.spring()) {
                    showNotesView = true
                }
            }
            .sheet(isPresented: $showNotesView) {
                InvitationsView()
            }
            
            toolButton(
                "Flashcards",
                systemImage: "rectangle.stack.fill",
                background: Color.brandWarning,
                description: "Study efficiently"
            ) {
                withAnimation(.spring()) {
                    showFlashcardsView = true
                }
            }
            .sheet(isPresented: $showFlashcardsView) {
                FlashcardsView()
            }
        }
    }
    
    // Quick access row with refined spacing
    var quickAccessRow: some View {
        HStack(spacing: 16) {
            quickAccessButton("Library", systemImage: "books.vertical.fill")
            quickAccessButton("Forum", systemImage: "bubble.left.and.bubble.right.fill")
            quickAccessButton("Grades", systemImage: "chart.bar.fill")
            quickAccessButton("Map", systemImage: "mappin.circle.fill")
        }
    }
    
    // Quick access button with enhanced styling and shadow
    func quickAccessButton(_ title: String, systemImage: String) -> some View {
        VStack(spacing: 14) {
            // Icon with refined gradient and shadow
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
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Tool Button with enhanced gradient and shadow
    func toolButton(_ title: String, systemImage: String, background: Color, description: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 22) {
                // Icon with enhanced gradient and inner shadow
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
            print("⚠️ No current user found")
            self.nextRSVPEvent = nil
            return 
        }
        
        // Get events from CalendarManager
        let events = calendarManager.events
        print("📅 Finding next RSVP'd event among \(events.count) events for user: \(username)")
        
        // Filter for events where user is attending (RSVP'd) or hosting
        let userRSVPEvents = events.filter { event in
            let isAttending = event.attendees.contains(where: { $0.lowercased() == username.lowercased() })
            let isHosting = event.host.lowercased() == username.lowercased()
            
            if isAttending {
                print("👤 User is attending event: \(event.title) at \(event.time)")
            }
            if isHosting {
                print("🏠 User is hosting event: \(event.title) at \(event.time)")
            }
            return isAttending || isHosting
        }
        
        print("👤 Found \(userRSVPEvents.count) events user is attending")
        
        if userRSVPEvents.isEmpty {
            print("⚠️ User is not attending any events")
            self.nextRSVPEvent = nil
            return
        }
        
        // Sort by start time (earliest first)
        let sortedEvents = userRSVPEvents.sorted { $0.time < $1.time }
        
        // Find the next event (first event that hasn't ended yet)
        let now = Date()
        print("⏰ Current time: \(now)")
        
        let upcomingEvents = sortedEvents.filter { event in
            // Consider events that haven't ended yet
            let hasNotEnded = event.endTime > now
            if hasNotEnded {
                print("📆 Event is upcoming: \(event.title), Ends: \(event.endTime)")
            } else {
                print("⏰ Event has ended: \(event.title), Ended: \(event.endTime)")
            }
            return hasNotEnded
        }
        
        print("📆 Found \(upcomingEvents.count) upcoming events")
        
        for (index, event) in upcomingEvents.enumerated() {
            let timeUntilStart = event.time.timeIntervalSince(now)
            let hoursUntilStart = timeUntilStart / 3600
            print("   Event \(index+1): \(event.title)")
            print("      Starts: \(event.time)")
            print("      Ends: \(event.endTime)")
            print("      Hours until start: \(String(format: "%.1f", hoursUntilStart))")
        }
        
        // Set the next event (first in the sorted list)
        self.nextRSVPEvent = upcomingEvents.first
        
        if let nextEvent = self.nextRSVPEvent {
            let timeUntilStart = nextEvent.time.timeIntervalSince(now)
            let hoursUntilStart = timeUntilStart / 3600
            print("✅ Next RSVP'd event: \(nextEvent.title)")
            print("   Starts in: \(String(format: "%.1f", hoursUntilStart)) hours")
        } else {
            print("❌ No upcoming RSVP'd events found")
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

struct FlashcardsView: View {
    var body: some View {
        ZStack {
            // Clean background
            Color.bgSurface.ignoresSafeArea()
            
            Text("Flashcards View Placeholder")
                .font(.title)
                .foregroundColor(Color.textPrimary)
                .padding()
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
    @StateObject private var profileManager = UserProfileManager()
    @StateObject private var reputationManager = UserReputationManager()
    
    // State for editable fields
    @State private var editMode: Bool = false
    @State private var showEditProfileSheet: Bool = false
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
    
    // Stats counters
    @State private var postsCount: Int = 24
    @State private var followersCount: Int = 156
    @State private var followingCount: Int = 128
    
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
                        
                        // Privacy settings with improved toggles
                        privacySection
                        
                        // User Reputation section
                        reputationSection
                        
                        // Connected accounts with refined visuals
                        connectedAccountsSection
                            
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
            .toolbar {
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
            .onAppear {
                // Initialize fields with user data
                if let user = accountManager.currentUser {
                    name = user
                    // Pre-load skill levels from profileManager (if any already exist)
                    skillLevels = profileManager.skills
                    loadProfileData() // Load profile when view appears
                    // Fetch backend profile completion details
                    profileManager.fetchProfileCompletion(username: user) { _ in }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Profile Update"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showEditProfileSheet, onDismiss: {
                // Refresh profile data when returning from edit
                if let user = accountManager.currentUser {
                    loadProfileData()
                    profileManager.fetchProfileCompletion(username: user) { _ in }
                }
            }) {
                EditProfileView()
                    .environmentObject(accountManager)
                    .environmentObject(profileManager)
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
                    showEditProfileSheet = true
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
                                showEditProfileSheet = true
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
                        showEditProfileSheet = true
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
            print("❌ Cannot load profile: No username available")
            return
        }
        
        print("🔍 Loading profile for user: \(username) using UserProfileManager")
        
        // Use the profileManager to fetch the profile
        profileManager.fetchUserProfile(username: username) { success in
            if success {
                print("✅ Profile loaded successfully")
                
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
                print("📊 Loaded basic info: \(self.name), \(self.university), \(self.degree), \(self.year)")
                print("📊 Loaded bio: \(self.bio)")
                print("📊 Loaded interests: \(self.profileManager.interests)")
                print("📊 Loaded skills with levels: \(self.profileManager.skills)")
                print("📊 Auto-invite enabled: \(self.profileManager.autoInviteEnabled)")
                print("📊 Preferred radius: \(self.profileManager.preferredRadius)")
            } else {
                self.alertMessage = self.profileManager.errorMessage ?? "Failed to load profile"
                self.showAlert = true
                print("❌ Failed to load profile: \(self.profileManager.errorMessage ?? "Unknown error")")
            }
        }
    }
    
    private func saveProfileData() {
        guard let username = accountManager.currentUser, !username.isEmpty else {
            alertMessage = "Not logged in"
            showAlert = true
            print("❌ Cannot save profile: No username available")
            return
        }
        
        print("💾 Saving preferences for user: \(username) using UserProfileManager")
        
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
                print("✅ Profile saved successfully")
            } else {
                self.alertMessage = self.profileManager.errorMessage ?? "Failed to save profile"
                self.showAlert = true
                print("❌ Failed to save profile: \(self.profileManager.errorMessage ?? "Unknown error")")
            }
        }
    }
    
    // MARK: - Profile Header with refined styling
    private var profileHeader: some View {
        VStack {
            ZStack {
                // Profile circle with refined layering
                Circle()
                    .fill(Color.bgAccent)
                    .frame(width: 134, height: 134)
                    .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
                
                Circle()
                    .fill(Color.bgCard)
                    .frame(width: 126, height: 126)
                
                // Profile image with more refined colors
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 112, height: 112)
                    .foregroundColor(Color.brandPrimary)
                
                // Edit camera button with refined gradient
                if editMode {
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
                                .offset(y: 0.5) // Subtle icon positioning
                        )
                        .offset(x: 42, y: 42)
                        .shadow(color: Color.cardShadow, radius: 6, x: 0, y: 3)
                }
            }
            .padding(.top, 16)
            
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
                statView(count: postsCount, title: "Posts")
                
                Rectangle()
                    .fill(Color.divider)
                    .frame(width: 1, height: 30)
                
                statView(count: followersCount, title: "Followers")
                
                Rectangle()
                    .fill(Color.divider)
                    .frame(width: 1, height: 30)
                
                statView(count: followingCount, title: "Following")
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
    
    // MARK: - Privacy Section with enhanced toggle style
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Privacy Settings", systemImage: "lock.fill")
            
            Divider()
                .background(Color.divider)
                .padding(.bottom, 6)
            
            Toggle("Profile Visible to Everyone", isOn: .constant(true))
                .padding(.horizontal)
                .toggleStyle(EnhancedToggleStyle())
            
            Toggle("Show University & Degree", isOn: .constant(true))
                .padding(.horizontal)
                .toggleStyle(EnhancedToggleStyle())
            
            Toggle("Allow Friend Requests", isOn: .constant(true))
                .padding(.horizontal)
                .toggleStyle(EnhancedToggleStyle())
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
                                .padding(.leading, 5)
                        }
                        
                        // Trust level
                        HStack(spacing: 10) {
                            Image(systemName: trustLevelIcon)
                                .foregroundColor(trustLevelColor)
                            Text(reputationManager.userStats.trustLevel.title)
                                .fontWeight(.medium)
                                .foregroundColor(trustLevelColor)
                        }
                        
                        Divider()
                        
                        // Activity stats
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(reputationManager.userStats.eventsHosted)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Hosted")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(reputationManager.userStats.eventsAttended)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Attended")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(reputationManager.userStats.totalRatings)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Reviews")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Recent ratings preview if available
                        if !reputationManager.userRatings.isEmpty {
                            Divider()
                                .padding(.vertical, 5)
                            
                            Text("Recent Reviews")
                                .font(.subheadline)
                                .fontWeight(.medium)
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
                Text(rating.createdAt, style: .date)
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
    
    // MARK: - Connected Accounts with refined styling
    private var connectedAccountsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Connected Accounts", systemImage: "link")
            
            Divider()
                .background(Color.divider)
                .padding(.bottom, 6)
            
            // Connected account row with refined styling
            HStack {
                Image(systemName: "graduationcap.fill")
                    .foregroundColor(.white)
                    .padding(10)
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
                
                Text("University Login")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.textPrimary)
                Spacer()
                
                Text("Connected")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.brandSuccess.opacity(0.1))
                    )
                    .foregroundColor(.brandSuccess)
            }
            .padding(.horizontal)
            
            Divider()
                .background(Color.divider)
                .padding(.horizontal)
            
            // Second connected account with refined styling
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [.brandWarning, .brandWarning.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.brandWarning.opacity(0.25), radius: 4, x: 0, y: 2)
                    )
                
                Text("Study Management System")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.textPrimary)
                Spacer()
                
                Button("Connect") {
                    // Connect action
                }
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .stroke(Color.brandPrimary, lineWidth: 1.5)
                )
                .foregroundColor(.brandPrimary)
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
