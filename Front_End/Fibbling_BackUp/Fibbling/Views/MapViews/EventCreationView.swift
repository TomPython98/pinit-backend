import SwiftUI
import MapKit
import PhotosUI
import CoreLocation
import MapboxMaps
import Combine

// MARK: - Performance Debugging
private struct PerformanceTracker {
    static func measure(_ operation: String, _ block: () -> Void) {
        let start = CFAbsoluteTimeGetCurrent()
        block()
        let duration = CFAbsoluteTimeGetCurrent() - start
        if duration > 0.05 {
            print("⚠️ SLOW [\(operation)]: \(String(format: "%.3f", duration))s")
        }
    }
}

// MARK: - Redesigned EventCreationView
struct EventCreationView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var calendarManager: CalendarManager
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Event State
    @State private var eventTitle = ""
    @State private var eventDescription = ""
    @State private var eventDate = Date().addingTimeInterval(3600) // 1 hour in the future
    @State private var eventEndDate = Date().addingTimeInterval(7200) // 2 hours in the future
    @State private var selectedEventType: EventType = .study
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    
    let initialCoordinate: CLLocationCoordinate2D
    @State private var selectedCoordinate: CLLocationCoordinate2D
    @State private var locationName = ""
    @State private var isPublic = true
    @State private var maxParticipants = 10
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var enableAutoMatching = false
    @State private var isLoading = false
    @State private var showFriendPicker = false
    @State private var selectedFriends: [String] = []
    @State private var locationSuggestions: [GooglePlacesService.LocationSuggestion] = []
    @State private var selectedLocation: GooglePlacesService.LocationSuggestion?
    @State private var showLocationSuggestions = false
    @State private var isGeocoding = false
    @State private var showSuccessAnimation = false
    @State private var isSearchingSuggestions = false
    @State private var isLocationSelected = false
    @State private var suppressLocationOnChange = false // prevent TextField onChange from clearing selection when set programmatically
    @State private var showVisibilityHint = false
    @State private var showAutoMatchHint = false
    @State private var showValidationAlert = false
    @State private var isFullDay = false
    @State private var validationMessage = ""
    @State private var audienceSelection: Audience = .publicEvent
    @State private var showLocationDetail = false
    @State private var searchTask: Task<Void, Never>?
    
    // Google Places Service
    private let googlePlacesService = GooglePlacesService.shared
    
    var onSave: (StudyEvent) -> Void
    
    // MARK: - Init
    init(coordinate: CLLocationCoordinate2D, onSave: @escaping (StudyEvent) -> Void) {
        self.initialCoordinate = coordinate
        self._selectedCoordinate = State(initialValue: coordinate)
        self.onSave = onSave
        self._audienceSelection = State(initialValue: .publicEvent)
    }
    
    var body: some View {
        let _ = print("🔄 [EventCreation] Body re-evaluated - selectedEventType: \(selectedEventType.rawValue)")
        let _ = print("   📊 State: isLoading=\(isLoading), showLocationSuggestions=\(showLocationSuggestions), isGeocoding=\(isGeocoding), isSearchingSuggestions=\(isSearchingSuggestions), showSuccessAnimation=\(showSuccessAnimation)")
        let _ = print("   📍 Location: isLocationSelected=\(isLocationSelected), locationName='\(locationName.prefix(20))...'")
        
        NavigationStack {
        ZStack {
                // Professional background
            Color.bgSurface
                .ignoresSafeArea()
                .allowsHitTesting(false) // Don't block touches
            
                // Subtle gradient
            LinearGradient(
                    colors: [Color.gradientStart.opacity(0.03), Color.gradientEnd.opacity(0.01)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .allowsHitTesting(false) // Don't block touches
            
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Header with progress
                        headerSection
                        
                        // Main content in cards
                        VStack(spacing: 20) {
                            // Essential Info Card
                            essentialInfoCard
                            
                            // Date & Time Card
                            dateTimeCard
                            
                            // Location Card
                            locationCard
                            
                            // Event Settings Card
                            settingsCard
                            
                            // Optional Features Card
                            optionalFeaturesCard
                        }
                        .padding(.horizontal, 20)
                        
                        // Create Button
                        createButton
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Create Event")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.black)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
                EventImagePicker(selectedImages: $selectedImages)
            }
            .sheet(isPresented: $showFriendPicker) {
                FriendPickerView(selectedFriends: $selectedFriends)
                    .environmentObject(accountManager)
            }
            .alert(isPresented: $showValidationAlert) {
                Alert(
                    title: Text("Cannot Create Event"),
                    message: Text(validationMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onTapGesture {
                hideKeyboard()
            }
        .onDisappear {
            // Cancel any ongoing search tasks
            searchTask?.cancel()
            searchTask = nil
        }
        .overlay {
            if isLoading {
                loadingOverlay
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: isLoading)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
        HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create Your Event")
                        .font(.title2.bold())
                        .foregroundColor(.textPrimary)
                    
                    Text("Fill in the details below to create your event")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            
            Spacer()
            
                // Quick stats
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(maxParticipants)")
                        .font(.title3.bold())
                        .foregroundColor(.brandPrimary)
                    Text("max people")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
            }
            
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(completionProgress >= Double(index) ? Color.brandPrimary : Color.bgSecondary)
                        .frame(width: 8, height: 8)
                }
            
            Spacer()
            
                Text("\(Int(completionProgress * 25))% Complete")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Essential Info Card
    private var essentialInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader("Essential Info", icon: "info.circle.fill", color: Color.pinItPrimary)
            
            VStack(spacing: 16) {
                // Event Title
                    VStack(alignment: .leading, spacing: 8) {
                            Text("Event Title")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.textPrimary)
                    
                    ZStack(alignment: .leading) {
                        if eventTitle.isEmpty {
                            Text("What's your event about?")
                                .foregroundColor(Color.pinItTextSecondary.opacity(0.5))
                                .padding()
                        }
                        TextField("", text: $eventTitle)
                            .foregroundColor(Color.black)
                            .padding()
                    }
                    .background(Color.bgCard)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cardStroke, lineWidth: 1)
                    )
                }
                
                // Event Type - NEW STABLE IMPLEMENTATION
                VStack(alignment: .leading, spacing: 8) {
                    Text("Event Type")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.textPrimary)
                    
                    // Use Menu for stable selection
                    Menu {
                        ForEach(EventType.allCases, id: \.self) { type in
                            Button(action: {
                                print("🎯 [EventCreation] Menu selected: \(type.rawValue)")
                                selectedEventType = type
                            }) {
                                HStack {
                                    Image(systemName: eventTypeIcon(type))
                                        .foregroundColor(eventTypeColor(type))
                                    Text(type.displayName)
                                    if selectedEventType == type {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.brandPrimary)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: eventTypeIcon(selectedEventType))
                                .foregroundColor(eventTypeColor(selectedEventType))
                            Text(selectedEventType.displayName)
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.textSecondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.bgCard)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.cardStroke, lineWidth: 1)
                        )
                    }
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.textPrimary)
                    
                    ZStack(alignment: .topLeading) {
                        if eventDescription.isEmpty {
                            Text("Tell people what to expect...")
                                .foregroundColor(Color.pinItTextSecondary.opacity(0.5))
                                .padding()
                        }
                        TextField("", text: $eventDescription, axis: .vertical)
                            .foregroundColor(Color.black)
                            .padding()
                            .lineLimit(3...6)
                    }
                    .background(Color.bgCard)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cardStroke, lineWidth: 1)
                    )
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Date & Time Card
    private var dateTimeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader("When", icon: "calendar.badge.clock", color: Color.pinItAccent)
            
            VStack(spacing: 16) {
                // Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Event Date")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.black)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.brandPrimary)
                        
                        DatePicker("Select Date", selection: $eventDate, displayedComponents: [.date])
                            .labelsHidden()
                            .accentColor(.brandPrimary)
                            .environment(\.colorScheme, .light)
                            .onChange(of: eventDate) { oldValue, newValue in
                                print("🔍 [EventCreation] Date Changed:")
                                print("   📅 Old Date: \(oldValue)")
                                print("   📅 New Date: \(newValue)")
                                print("   📅 End Date: \(eventEndDate)")
                                print("   ⏰ Valid (start < end): \(newValue < eventEndDate)")
                                
                                // If the new date is after the end date, adjust end date
                                if newValue >= eventEndDate {
                                    let newEndDate = newValue.addingTimeInterval(3600) // Add 1 hour
                                    print("   🔧 Adjusting end date to: \(newEndDate)")
                                    eventEndDate = newEndDate
                                }
                            }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Full Day Toggle
                Toggle(isOn: $isFullDay) {
                    HStack(spacing: 8) {
                        Image(systemName: "sun.horizon.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.brandAccent)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Full Day Event")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Text("Event lasts all day")
                                .font(.system(size: 12))
                                .foregroundColor(.black.opacity(0.6))
                        }
                    }
                }
                .tint(.brandPrimary)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.bgCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isFullDay ? Color.brandPrimary : Color.clear, lineWidth: 2)
                        )
                )
                .onChange(of: isFullDay) { _, newValue in
                    if newValue {
                        // Set to full day (midnight to 11:59 PM)
                        let calendar = Calendar.current
                        eventDate = calendar.startOfDay(for: eventDate)
                        if let endOfDay = calendar.date(byAdding: .day, value: 1, to: eventDate)?.addingTimeInterval(-60) {
                            eventEndDate = endOfDay
                        }
                    }
                }
                
                // Time Range (only if not full day)
                if !isFullDay {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Start Time")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            
                            DatePicker("", selection: $eventDate, displayedComponents: [.hourAndMinute])
                                .datePickerStyle(.compact)
                                .accentColor(.brandPrimary)
                                .environment(\.colorScheme, .light)
                                .labelsHidden()
                                .onChange(of: eventDate) { oldValue, newValue in
                                    print("🔍 [EventCreation] Start Time Changed:")
                                    print("   ⏰ Old Start: \(oldValue)")
                                    print("   ⏰ New Start: \(newValue)")
                                    print("   ⏰ End Time: \(eventEndDate)")
                                    print("   ⏰ Valid (start < end): \(newValue < eventEndDate)")
                                    
                                    // If the new start time is after the end time, adjust end time
                                    if newValue >= eventEndDate {
                                        let newEndDate = newValue.addingTimeInterval(1800) // Add 30 minutes
                                        print("   🔧 Adjusting end time to: \(newEndDate)")
                                        eventEndDate = newEndDate
                                    }
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("End Time")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            
                            DatePicker("", selection: $eventEndDate, displayedComponents: [.hourAndMinute])
                                .datePickerStyle(.compact)
                                .accentColor(.brandPrimary)
                                .environment(\.colorScheme, .light)
                                .labelsHidden()
                                .onChange(of: eventEndDate) { oldValue, newValue in
                                    print("🔍 [EventCreation] End Time Changed:")
                                    print("   ⏰ Start Time: \(eventDate)")
                                    print("   ⏰ Old End: \(oldValue)")
                                    print("   ⏰ New End: \(newValue)")
                                    print("   ⏰ Valid (start < end): \(eventDate < newValue)")
                                    
                                    // If the new end time is before the start time, adjust start time
                                    if newValue <= eventDate {
                                        let newStartDate = newValue.addingTimeInterval(-1800) // Subtract 30 minutes
                                        print("   🔧 Adjusting start time to: \(newStartDate)")
                                        eventDate = newStartDate
                                    }
                                }
                        }
                    }
                }
                
                // Duration display
                HStack {
                    Image(systemName: isFullDay ? "sun.max.fill" : "clock")
                        .foregroundColor(.brandAccent)
                    Text(isFullDay ? "Full Day Event" : "Duration: \(formatDuration(from: eventDate, to: eventEndDate))")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Location Card
    private var locationCard: some View {
                    VStack(alignment: .leading, spacing: 16) {
            cardHeader("Where", icon: "location.fill", color: Color.pinItWarning)
            
            VStack(spacing: 16) {
                // Simple Location Input with Suggestions
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(isLocationSelected ? "Location Selected" : "Location")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        if isLocationSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.pinItSuccess)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    
                    VStack(spacing: 0) {
                        HStack {
                            ZStack(alignment: .leading) {
                                if locationName.isEmpty {
                                    Text("Enter location (e.g., Brandenburger Tor, Berlin)")
                                        .foregroundColor(Color.pinItTextSecondary.opacity(0.5))
                                        .padding()
                                }
                                TextField("", text: $locationName)
                                    .foregroundColor(Color.black)
                                    .padding()
                                    .onChange(of: locationName) { oldValue, newValue in
                                    // Safety check for valid values
                                    guard !oldValue.isEmpty, !newValue.isEmpty else { return }
                                    
                                    // If the change was triggered programmatically, do not reset selection
                                    if suppressLocationOnChange {
                                        suppressLocationOnChange = false
                                    } else if !oldValue.isEmpty && oldValue != newValue {
                                        isLocationSelected = false
                                        selectedLocation = nil
                                    }
                                    
                                    // Cancel previous search task
                                    searchTask?.cancel()
                                    
                                    // Only show suggestions, don't auto-geocode
                                    if newValue.count > 2 {
                                        searchLocationSuggestions(query: newValue)
                                    } else {
                                        locationSuggestions = []
                                        showLocationSuggestions = false
                                    }
                                    }
                                    .onSubmit {
                                        // Geocode when user presses return
                                        if !locationName.isEmpty {
                                            geocodeLocation(locationName)
                                        }
                                    }
                            }
                            .background(Color.bgCard)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cardStroke, lineWidth: 1)
                            )

                            // Dynamic indicator: checkmark, loading, or search button
                            if isLocationSelected && !isGeocoding {
                                // Green checkmark when location is selected
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.pinItSuccess)
                                    .font(.system(size: 18, weight: .semibold))
                                    .transition(.scale.combined(with: .opacity))
                            } else if isGeocoding || isSearchingSuggestions {
                                // Loading indicator
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(Color.pinItWarning)
                                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            } else {
                                // Search button when no location selected
                                Button(action: {
                                    if !locationName.isEmpty {
                                        geocodeLocation(locationName)
                                    }
                                }) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(Color.pinItWarning)
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .disabled(locationName.isEmpty)
                            }
                        }
                        
                        // Enhanced Location Suggestions with Photos & Ratings
                        // Only show suggestions if no location is selected
                        if showLocationSuggestions && !locationSuggestions.isEmpty && !isLocationSelected {
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(locationSuggestions.prefix(5)) { suggestion in
                                        EnhancedLocationSuggestionCard(
                                        suggestion: suggestion,
                                            onTap: {
                                                // Cancel search task and clear suggestions
                                                searchTask?.cancel()
                                                selectLocation(suggestion)
                                            }
                                        )
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .frame(maxHeight: 450)
                            .padding(.top, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .animation(.easeInOut(duration: 0.2), value: showLocationSuggestions)
                        }
                        
                        // Selected Location Detail Card
                        if isLocationSelected, let selected = selectedLocation {
                            SelectedLocationDetailCard(
                                suggestion: selected,
                                onDeselect: {
                                    withAnimation {
                                        isLocationSelected = false
                                        selectedLocation = nil
                                        locationName = ""
                                    }
                                }
                            )
                            .padding(.top, 12)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }
                    
                    
                    // Show current coordinates and location info for reference
                    if !locationName.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                        HStack {
                                Image(systemName: "mappin.circle")
                                    .foregroundColor(Color.pinItWarning)
                                    .font(.caption)
                                
                                Text("Coordinates: \(String(format: "%.4f", selectedCoordinate.latitude)), \(String(format: "%.4f", selectedCoordinate.longitude))")
                                    .font(.caption)
                                .foregroundColor(.textSecondary)
                                
                                Spacer()
                            }
                            
                            // Show if location was found successfully with animation
                            if isLocationSelected {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color.pinItSuccess)
                                        .font(.caption)
                                    
                                    Text("Location selected successfully")
                                        .font(.caption)
                                        .foregroundColor(Color.pinItSuccess)
                                    
                                    Spacer()
                                }
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                
                // Location Status
                if !locationName.isEmpty {
                        HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.pinItSuccess)
                        
                        Text("Location set: \(locationName)")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Settings Card
    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader("Settings", icon: "gearshape.fill", color: Color.pinItAcademic)
            
            VStack(spacing: 16) {
                // Audience selector
                VStack(alignment: .leading, spacing: 10) {
                    Text("Event Visibility")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: 12) {
                        // Public Button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                audienceSelection = .publicEvent
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text("Public")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(audienceSelection == .publicEvent ? Color.brandPrimary : Color.bgCard)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cardStroke, lineWidth: 1)
                            )
                            .shadow(color: audienceSelection == .publicEvent ? Color.brandPrimary.opacity(0.3) : Color.clear, radius: audienceSelection == .publicEvent ? 8 : 0, x: 0, y: 2)
                            .opacity(audienceSelection == .publicEvent ? 1.0 : 0.7)
                        }
                        
                        // Private Button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                audienceSelection = .privateEvent
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text("Private")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(audienceSelection == .privateEvent ? Color.brandPrimary : Color.bgCard)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cardStroke, lineWidth: 1)
                            )
                            .shadow(color: audienceSelection == .privateEvent ? Color.brandPrimary.opacity(0.3) : Color.clear, radius: audienceSelection == .privateEvent ? 8 : 0, x: 0, y: 2)
                            .opacity(audienceSelection == .privateEvent ? 1.0 : 0.7)
                        }
                    }
                    .onChange(of: audienceSelection) { newValue in
                        switch newValue {
                        case .publicEvent:
                            isPublic = true
                        case .privateEvent:
                            isPublic = false
                            // Auto-matching is now allowed for private events too
                        }
                    }
                    Text(audienceSelection == .publicEvent ? 
                         "Everyone can discover and join this event." : 
                         "Only invited friends and auto-matched users can see this event.")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                // Friend Invitations - Always visible for both public and private
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Invite Friends")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        Button(action: { showFriendPicker = true }) {
                            HStack(spacing: 6) {
                                Text("Add Friends")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.brandPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(audienceSelection == .publicEvent ?
                             "Invite specific friends to this public event to let them know about it" :
                             "Only these invited friends and auto-matched users can see this private event")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    if !selectedFriends.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectedFriends, id: \.self) { friend in
                                    HStack(spacing: 6) {
                                        Text(friend)
                                            .font(.caption.weight(.medium))
                                            .foregroundColor(.white)
                                        
                                        Button(action: { removeFriend(friend) }) {
                                            Text("×")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.brandPrimary)
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("No friends invited yet")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                                .padding(.vertical, 12)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.bgSecondary.opacity(0.5))
                        .cornerRadius(8)
                    }
                }
                .padding(16)
                .background(Color.bgCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1.5)
                )
                
                // Max Participants
                                VStack(alignment: .leading, spacing: 8) {
                    Text("Maximum Participants")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.textPrimary)

                                    HStack {
                        Text("\(maxParticipants) people")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.brandPrimary)

                        Spacer()

                        PinItStepper(value: $maxParticipants, range: 2...50, isDarkMode: false)
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Optional Features Card
    private var optionalFeaturesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader("Optional Features", icon: "star.fill", color: Color.pinItWarning)
            
            VStack(spacing: 16) {
                // Auto-Match - available for both Public and Private
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto-Match")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.textPrimary)
                        
                        Text(audienceSelection == .publicEvent ? 
                             "Automatically invite users with similar interests to your public event." :
                             "Automatically invite users with similar interests. Only matched users can see this private event.")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $enableAutoMatching)
                        .toggleStyle(SwitchToggleStyle(tint: .brandPrimary))
                }
                
                // Interest Tags (only show if auto-matching is enabled)
                if enableAutoMatching {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Interest Tags")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.textPrimary)
                        
                        // Tags display
                                    if !tags.isEmpty {
                                        FlowLayout(spacing: 8) {
                                            ForEach(tags, id: \.self) { tag in
                                    tagView(tag)
                                }
                            }
                        }
                        
                        // Add tag input
                        HStack {
                            ZStack(alignment: .leading) {
                                if newTag.isEmpty {
                                    Text("Add interest tag")
                                        .foregroundColor(Color.pinItTextSecondary.opacity(0.5))
                                        .padding()
                                }
                                TextField("", text: $newTag)
                                    .foregroundColor(Color.black)
                                    .padding()
                            }
                            .background(Color.bgCard)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cardStroke, lineWidth: 1)
                            )

                            Button("Add") {
                                addTag()
                            }
                            .disabled(newTag.isEmpty)
                            .foregroundColor(.brandPrimary)
                            .fontWeight(.medium)
                        }
                        
                        // Quick suggestions
                        if tags.isEmpty {
                            Text("Popular tags:")
                                                .font(.caption)
                                                .foregroundColor(.textSecondary)
                                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(popularTags.prefix(6), id: \.self) { tag in
                                        Button(tag) {
                                            addTag(tag)
                                        }
                                                            .font(.caption)
                                                            .foregroundColor(.brandPrimary)
                                                            .padding(.horizontal, 12)
                                                            .padding(.vertical, 6)
                                        .background(Color.brandPrimary.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal, 4)
                                            }
                                        }
                                    }
                                }
                            }
                        }
        .cardStyle()
    }
    
    // MARK: - Create Button
    private var createButton: some View {
        Button(action: createEvent) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
                
                Text(isLoading ? "Creating Event..." : "Create Event")
                    .font(.headline.weight(.semibold))
                    .transition(.opacity)
            }
                                        .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: isLoading ? 
                        [Color.brandPrimary.opacity(0.8), Color.brandAccent.opacity(0.8)] :
                        [Color.brandPrimary, Color.brandAccent]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.brandPrimary.opacity(isLoading ? 0.2 : 0.3), radius: isLoading ? 4 : 8, x: 0, y: isLoading ? 2 : 4)
            .scaleEffect(isLoading ? 0.98 : 1.0)
        }
        .disabled(!isFormValid || isLoading)
        .opacity(isFormValid ? 1.0 : 0.6)
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .transition(.opacity)
            
            VStack(spacing: 20) {
                // Animated progress indicator
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.brandPrimary, Color.brandAccent]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                }
                
                VStack(spacing: 8) {
                    Text("Creating Event...")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                    
                    Text("Please wait while we set up your event")
                                            .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.bgCard.opacity(0.95))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .scaleEffect(isLoading ? 1.0 : 0.9)
            .opacity(isLoading ? 1.0 : 0.0)
            .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
        }
    }
    
    // MARK: - Helper Views
    private func cardHeader(_ title: String, icon: String, color: Color) -> some View {
                                HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
    }
    
    private func tagView(_ tag: String) -> some View {
        HStack(spacing: 6) {
            Text(tag)
                .font(.caption.weight(.medium))
                .foregroundColor(.brandPrimary)
            
            Button(action: { removeTag(tag) }) {
                Image(systemName: "xmark")
                    .font(.caption2)
                                        .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.brandPrimary.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties
    private var completionProgress: Double {
        var progress = 0.0
        if !eventTitle.isEmpty { progress += 0.25 }
        if !eventDescription.isEmpty { progress += 0.25 }
        if !locationName.isEmpty { progress += 0.25 }
        if eventDate < eventEndDate { progress += 0.25 }
        return progress
    }
    
    private var isFormValid: Bool {
        let titleValid = !eventTitle.isEmpty
        let descriptionValid = !eventDescription.isEmpty
        let locationValid = !locationName.isEmpty
        let dateValid = eventDate < eventEndDate
        
        // 🔍 DEBUG: Print detailed validation info
        print("🔍 [EventCreation] Form Validation Debug:")
        print("   📝 Title: '\(eventTitle)' - Valid: \(titleValid)")
        print("   📄 Description: '\(eventDescription)' - Valid: \(descriptionValid)")
        print("   📍 Location: '\(locationName)' - Valid: \(locationValid)")
        print("   📅 Start Date: \(eventDate)")
        print("   📅 End Date: \(eventEndDate)")
        print("   ⏰ Date Valid (start < end): \(dateValid)")
        print("   ✅ Overall Valid: \(titleValid && descriptionValid && locationValid && dateValid)")
        
        return titleValid && descriptionValid && locationValid && dateValid
    }
    
    private var popularTags: [String] {
        ["Study", "Programming", "Networking", "Social", "Academic", "Business", "Creative", "Fitness"]
    }
    
    // MARK: - Helper Functions
    private func addTag(_ tag: String? = nil) {
        let tagToAdd = tag ?? newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tagToAdd.isEmpty && !tags.contains(tagToAdd) else { return }
        
        tags.append(tagToAdd)
        newTag = ""
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func removeFriend(_ friend: String) {
        selectedFriends.removeAll { $0 == friend }
    }
    
    private func searchLocationSuggestions(query: String) {
        // Safety checks
        guard !query.isEmpty,
              query.count >= 2,
              query.count <= 100 else {
            locationSuggestions = []
            showLocationSuggestions = false
            return
        }
        
        print("🔍 [EventCreation] searchLocationSuggestions called: '\(query)'")
        
        // Cancel previous search task
        searchTask?.cancel()
        
        isSearchingSuggestions = true
        
        // Use Google Places API for location search
        searchTask = Task(priority: .userInitiated) {
            let taskStart = CFAbsoluteTimeGetCurrent()
            
            do {
                let results = try await googlePlacesService.searchLocations(query: query, near: selectedCoordinate)
                let duration = CFAbsoluteTimeGetCurrent() - taskStart
                print("✅ [EventCreation] Location search completed in \(String(format: "%.3f", duration))s - \(results.count) results")
                
                // Multiple safety checks before updating UI
                guard !Task.isCancelled,
                      !results.isEmpty else {
                    print("⚠️ [EventCreation] Search cancelled or empty")
                    return
                }
                
                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    
                    print("📍 [EventCreation] Updating UI with \(results.count) suggestions")
                    self.isSearchingSuggestions = false
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.locationSuggestions = results
                        self.showLocationSuggestions = true
                    }
                }
            } catch {
                let duration = CFAbsoluteTimeGetCurrent() - taskStart
                print("❌ [EventCreation] Location search failed in \(String(format: "%.3f", duration))s: \(error)")
                
                // Check if task was cancelled before updating UI
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    self.isSearchingSuggestions = false
                    self.locationSuggestions = []
                    self.showLocationSuggestions = false
                }
            }
        }
    }
    
    private func selectLocation(_ suggestion: GooglePlacesService.LocationSuggestion) {
        // Safety check
        guard !suggestion.name.isEmpty else { return }
        
        print("🎯 [EventCreation] selectLocation called: \(suggestion.name)")
        
        PerformanceTracker.measure("Select Location") {
            withAnimation(.easeInOut(duration: 0.15)) {
                // Update location details
                suppressLocationOnChange = true
                locationName = suggestion.name
                selectedCoordinate = suggestion.coordinate
                selectedLocation = suggestion
                
                // CRITICAL: Set these in the right order
                isLocationSelected = true  // First, mark as selected
                showLocationSuggestions = false  // Then hide suggestions
                locationSuggestions = []  // Clear the suggestions array
                isSearchingSuggestions = false  // Stop any search state
                
                // Show success animation
                showSuccessAnimation = true
            }
        }
        
        // Hide success animation after delay (run outside of animation block)
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSuccessAnimation = false
                }
            }
        }
    }
    
    
    private func geocodeLocation(_ address: String) {
        // Safety check
        guard !address.isEmpty, address.count <= 200 else { return }
        
        print("🌍 [EventCreation] geocodeLocation called: \(address)")
        
        // Set loading state
        isGeocoding = true
        
        // Use Google Places API for geocoding
        Task(priority: .userInitiated) {
            let taskStart = CFAbsoluteTimeGetCurrent()
            
            do {
                let result = try await googlePlacesService.geocodeAddress(address)
                let duration = CFAbsoluteTimeGetCurrent() - taskStart
                print("✅ [EventCreation] Geocoding completed in \(String(format: "%.3f", duration))s")
                
                await MainActor.run {
                    self.isGeocoding = false
                    self.selectLocation(result)
                }
            } catch {
                let duration = CFAbsoluteTimeGetCurrent() - taskStart
                print("❌ [EventCreation] Geocoding failed in \(String(format: "%.3f", duration))s: \(error)")
                
                await MainActor.run {
                    self.isGeocoding = false
                    // Keep current coordinate as fallback
                }
            }
        }
    }
    
    private func formatDuration(from startDate: Date, to endDate: Date) -> String {
        // Ensure non-negative duration and handle overnight (end before start => next day)
        var adjustedEnd = endDate
        if adjustedEnd < startDate {
            // Assume the end time is on the next day
            adjustedEnd = Calendar.current.date(byAdding: .day, value: 1, to: adjustedEnd) ?? adjustedEnd.addingTimeInterval(24 * 60 * 60)
        }
        
        let seconds = max(0, adjustedEnd.timeIntervalSince(startDate))
        let totalMinutes = Int(seconds / 60)
        let days = totalMinutes / (24 * 60)
        let hours = (totalMinutes % (24 * 60)) / 60
        let minutes = totalMinutes % 60
        
        if days > 0 {
            if hours > 0 || minutes > 0 {
                return "\(days)d \(hours)h \(minutes)m"
            } else {
                return "\(days)d"
            }
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func eventTypeIcon(_ type: EventType) -> String {
        switch type {
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
    
    private func eventTypeColor(_ type: EventType) -> Color {
        switch type {
        case .study: return Color.pinItPrimary
        case .party: return Color.pinItParty
        case .business: return Color.pinItBusiness
        case .cultural: return Color.pinItCultural
        case .academic: return Color.pinItAcademic
        case .networking: return Color.pinItNetworking
        case .social: return Color.pinItSocial
        case .language_exchange: return Color.pinItLanguage
        case .other: return Color.pinItOther
        }
    }
    
    // MARK: - Helper Functions
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Event Creation
    private func createEvent() {
        print("🚀 [EventCreation] createEvent called - type: \(selectedEventType.rawValue)")
        print("🔍 [EventCreation] Current Form State:")
        print("   📝 Title: '\(eventTitle)'")
        print("   📄 Description: '\(eventDescription)'")
        print("   📍 Location: '\(locationName)'")
        print("   📅 Start Date: \(eventDate)")
        print("   📅 End Date: \(eventEndDate)")
        print("   ⏰ Date Valid (start < end): \(eventDate < eventEndDate)")
        print("   ✅ Form Valid: \(isFormValid)")
        
        // Client-side validation: prevent private events without invitees or auto-matching
        if !isPublic && selectedFriends.isEmpty && !enableAutoMatching {
            validationMessage = "Private events need either invited friends or auto-matching enabled."
            showValidationAlert = true
            return
        }

        isLoading = true

        // Prepare the API request
        guard let url = URL(string: APIConfig.fullURL(for: "createEvent")) else {
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // ✅ Add JWT authentication header
        accountManager.addAuthHeader(to: &request)
        
        // Format dates for backend
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let formattedStartDate = isoFormatter.string(from: eventDate)
        let formattedEndDate = isoFormatter.string(from: eventEndDate)
        
        // Prepare the request body
        var jsonBody: [String: Any] = [
            "host": accountManager.currentUser ?? "Unknown",
            "title": eventTitle,
            "latitude": selectedCoordinate.latitude,
            "longitude": selectedCoordinate.longitude,
            "description": eventDescription,
            "time": formattedStartDate,
            "end_time": formattedEndDate,
            "is_public": isPublic,
            "invited_friends": selectedFriends,
            "event_type": selectedEventType.rawValue,
            "max_participants": maxParticipants
        ]
        
        // Add auto-matching data if enabled
        if enableAutoMatching {
            jsonBody["auto_matching_enabled"] = true
                jsonBody["interest_tags"] = tags
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        } catch {
            isLoading = false
            return
        }
        
        // Make the API call
        let requestStart = CFAbsoluteTimeGetCurrent()
        URLSession.shared.dataTask(with: request) { data, response, error in
            Task {
                let networkDuration = CFAbsoluteTimeGetCurrent() - requestStart
                print("🌐 [EventCreation] Network request completed in \(String(format: "%.3f", networkDuration))s")
                
                await MainActor.run { self.isLoading = false }
                
                if let error = error {
                    print("❌ [EventCreation] Network error: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else { return }
                print("📡 [EventCreation] HTTP Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    // Success - parse response OFF main thread
                    guard let data = data else { return }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let eventId = json["event_id"] as? String {
                        
                        print("✅ [EventCreation] Event created with ID: \(eventId)")
                        
                        let newEvent = StudyEvent(
                            id: UUID(uuidString: eventId) ?? UUID(),
                            title: self.eventTitle,
                            coordinate: self.selectedCoordinate,
                            time: self.eventDate,
                            endTime: self.eventEndDate,
                            description: self.eventDescription,
                            invitedFriends: self.selectedFriends,
                            attendees: [self.accountManager.currentUser ?? "Unknown"],
                            isPublic: self.isPublic,
                            host: self.accountManager.currentUser ?? "Unknown",
                            hostIsCertified: false,
                            eventType: self.selectedEventType,
                            isAutoMatched: self.enableAutoMatching,
                            interestTags: self.tags,
                            matchedUsers: []
                        )
                        
                        await MainActor.run {
                            print("💾 [EventCreation] Saving event and dismissing view")
                            self.onSave(newEvent)
                            self.dismiss()
                        }
                    } else {
                        print("⚠️ [EventCreation] Failed to parse event response")
                    }
                } else {
                    print("❌ [EventCreation] HTTP error: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
}

// MARK: - Audience Enum
fileprivate enum Audience: Hashable {
    case publicEvent
    case privateEvent
}

// MARK: - Supporting Views
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.bgSecondary)
            .cornerRadius(12)
            .foregroundColor(.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.cardStroke, lineWidth: 1)
            )
    }
}
extension View {
    func cardStyle() -> some View {
        self
            .padding(20)
            .background(Color.bgCard)
            .cornerRadius(16)
            .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
    }
}
// MARK: - Friend Picker View
struct FriendPickerView: View {
    @Binding var selectedFriends: [String]
    @EnvironmentObject var accountManager: UserAccountManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery = ""
    
    private var filteredFriends: [String] {
        if searchQuery.isEmpty {
            return accountManager.friends
                        } else {
            return accountManager.friends.filter { $0.localizedCaseInsensitiveContains(searchQuery) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
            HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    ZStack(alignment: .leading) {
                        if searchQuery.isEmpty {
                            Text("Search friends")
                                .foregroundColor(Color(.darkGray))
                        }
                        TextField("", text: $searchQuery)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.black)
                            .tint(.brandPrimary)
                    }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
                    .padding()
                
                // Friends list
                List(filteredFriends, id: \.self) { friend in
                            HStack {
                        UserProfileImageView(username: friend, size: 30, borderColor: .brandPrimary)
                        
                        Text(friend)
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                                
                                Spacer()
                                
                        if selectedFriends.contains(friend) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.brandPrimary)
                                .font(.system(size: 24))
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.textSecondary.opacity(0.3))
                                .font(.system(size: 24))
                        }
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .listRowBackground(Color.white)
                    .onTapGesture {
                        toggleFriend(friend)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.white)
                .listStyle(PlainListStyle())
            }
            .background(Color.white)
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { 
                        dismiss() 
                    }
                    .foregroundColor(.black)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { 
                        dismiss() 
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
    
    private func toggleFriend(_ friend: String) {
        if selectedFriends.contains(friend) {
            selectedFriends.removeAll { $0 == friend }
        } else {
            selectedFriends.append(friend)
        }
    }
}

// MARK: - Location Suggestion Row Component
struct LocationSuggestionRow: View {
    let suggestion: String
    let coordinate: CLLocationCoordinate2D?
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Location icon with category
            VStack {
                Image(systemName: locationIcon)
                    .foregroundColor(locationColor)
                    .font(.title3)
                
                if let coord = coordinate {
                    Text(distanceText(from: coord))
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
            }
            .frame(width: 40)
            
            // Location details
            VStack(alignment: .leading, spacing: 2) {
                Text(primaryName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                Text(addressDetails)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
                
                if let category = categoryName {
                    Text(category)
                        .font(.caption2)
                        .foregroundColor(Color.pinItPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.pinItPrimary.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.pinItPrimary)
                    .font(.title3)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isSelected ? Color.pinItPrimary.opacity(0.05) : Color.clear)
    }
    
    private var primaryName: String {
        let components = suggestion.components(separatedBy: " - ")
        return components.first ?? suggestion
    }
    
    private var addressDetails: String {
        let components = suggestion.components(separatedBy: " - ")
        if components.count > 1 {
            return components[1]
        }
        return ""
    }
    
    private var categoryName: String? {
        let name = primaryName.lowercased()
        
        // Restaurant categories
        if name.contains("restaurant") || name.contains("cafe") || name.contains("coffee") {
            return "Restaurant"
        }
        if name.contains("bar") || name.contains("pub") || name.contains("club") {
            return "Bar/Club"
        }
        if name.contains("hotel") || name.contains("hostel") {
            return "Accommodation"
        }
        if name.contains("museum") || name.contains("gallery") {
            return "Culture"
        }
        if name.contains("park") || name.contains("plaza") {
            return "Public Space"
        }
        if name.contains("university") || name.contains("school") {
            return "Education"
        }
        
        return nil
    }
    
    private var locationIcon: String {
        let name = primaryName.lowercased()
        
        if name.contains("restaurant") || name.contains("cafe") || name.contains("coffee") {
            return "fork.knife"
        }
        if name.contains("bar") || name.contains("pub") || name.contains("club") {
            return "wineglass"
        }
        if name.contains("hotel") || name.contains("hostel") {
            return "bed.double"
        }
        if name.contains("museum") || name.contains("gallery") {
            return "building.columns"
        }
        if name.contains("park") || name.contains("plaza") {
            return "tree"
        }
        if name.contains("university") || name.contains("school") {
            return "graduationcap"
        }
        
        return "location"
    }
    
    private var locationColor: Color {
        let name = primaryName.lowercased()
        
        if name.contains("restaurant") || name.contains("cafe") || name.contains("coffee") {
            return Color.pinItWarning
        }
        if name.contains("bar") || name.contains("pub") || name.contains("club") {
            return Color.pinItParty
        }
        if name.contains("hotel") || name.contains("hostel") {
            return Color.pinItSuccess
        }
        if name.contains("museum") || name.contains("gallery") {
            return Color.pinItPrimary
        }
        if name.contains("park") || name.contains("plaza") {
            return Color.pinItSuccess
        }
        if name.contains("university") || name.contains("school") {
            return Color.pinItAcademic
        }
        
        return Color.pinItPrimary
    }
    
    private func distanceText(from coordinate: CLLocationCoordinate2D) -> String {
        // This would need the user's current location to calculate distance
        // For now, just show coordinates
        return "📍"
    }
}

// MARK: - Mapbox Mini Map Preview Component
struct MiniMapPreview: View {
    let coordinate: CLLocationCoordinate2D
    
    var body: some View {
        VStack(spacing: 0) {
            // Interactive map with anchored pin
            MapboxMapView(coordinate: coordinate)
                .overlay(alignment: .topLeading) {
                    GeometryReader { geo in
                        // Project geographic coordinate into screen point to keep pin anchored to geo coordinate
                        MiniMapProjectedPin(coordinate: coordinate)
                            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                            .allowsHitTesting(false)
                    }
                }
            
            // Info bar
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.caption2)
                    .foregroundColor(Color.pinItPrimary)
                Text("Selected location preview")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.pinItPrimary.opacity(0.05))
        }
    }
}

// MARK: - Mapbox Map View Wrapper for Mini Preview
struct MapboxMapView: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> MapView {
        // REVERT: Start with zero frame, let SwiftUI handle sizing
        let mapView = MapView(frame: .zero)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Configure map style
        mapView.mapboxMap.styleURI = .streets
        
        // Disable all gestures for static preview
        mapView.gestures.options.panEnabled = false
        mapView.gestures.options.pinchZoomEnabled = false
        mapView.gestures.options.rotateEnabled = false
        mapView.gestures.options.pitchEnabled = false
        mapView.gestures.options.doubleTapToZoomInEnabled = false
        mapView.gestures.options.doubleTouchToZoomOutEnabled = false
        
        // Set camera to the location with zoom level 15
        let cameraOptions = CameraOptions(
            center: coordinate,
            zoom: 15.0,
            bearing: 0,
            pitch: 0
        )
        mapView.mapboxMap.setCamera(to: cameraOptions)
        
        // Wait for map style to load before adding annotation
        mapView.mapboxMap.onStyleLoaded.observeNext { _ in
            DispatchQueue.main.async {
                self.addAnnotation(to: mapView, context: context)
            }
        }.store(in: &context.coordinator.cancellables)
        
        // No camera change observers needed - pin stays centered in overlay
        
        return mapView
    }
    
    func updateUIView(_ mapView: MapView, context: Context) {
        // Update annotation if coordinate changed (with more precision)
        let lastCoord = context.coordinator.lastCoordinate
        let latDiff = abs(lastCoord.latitude - coordinate.latitude)
        let lonDiff = abs(lastCoord.longitude - coordinate.longitude)
        
        // Only update if coordinates actually changed (threshold: 0.0001 degrees ≈ 11 meters)
        if latDiff > 0.0001 || lonDiff > 0.0001 {
            context.coordinator.lastCoordinate = coordinate
            
            // Update camera with smooth animation
            let cameraOptions = CameraOptions(
                center: coordinate,
                zoom: 15.0,
                bearing: 0,
                pitch: 0
            )
            mapView.camera.ease(to: cameraOptions, duration: 0.5)
            
            // Update annotation when style is ready
            mapView.mapboxMap.onStyleLoaded.observeNext { _ in
                DispatchQueue.main.async {
                    self.addAnnotation(to: mapView, context: context)
                }
            }.store(in: &context.coordinator.cancellables)
            
            // No camera notifications needed - pin stays centered in overlay
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(coordinate: coordinate)
    }
    
    private func addAnnotation(to mapView: MapView, context: Context) {
        print("🔍 Adding annotation to mini map at coordinate: \(coordinate)")
        
        // Store or reuse the annotation manager
        if context.coordinator.annotationManager == nil {
            context.coordinator.annotationManager = mapView.annotations.makePointAnnotationManager()
            print("🔍 Created new annotation manager")
        }
        
        guard let annotationManager = context.coordinator.annotationManager else { 
            print("❌ Failed to get annotation manager")
            return 
        }
        
        // No longer using Mapbox annotations - using SwiftUI overlay instead
        print("✅ Using SwiftUI overlay pin (no Mapbox annotations needed)")
    }
    
    // Coordinator to manage state
    class Coordinator {
        var annotationManager: PointAnnotationManager?
        var lastCoordinate: CLLocationCoordinate2D
        var cancellables = Set<AnyCancellable>()
        
        init(coordinate: CLLocationCoordinate2D) {
            self.lastCoordinate = coordinate
        }
    }
}

// MARK: - Simple centered pin that represents the selected location
struct MiniMapProjectedPin: View {
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        // Pin is always centered in the overlay - represents the selected location
        ZStack(alignment: .center) {
            Circle()
                .fill(Color.white)
                .frame(width: 32, height: 32)
                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
            Image("dest-pin")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


