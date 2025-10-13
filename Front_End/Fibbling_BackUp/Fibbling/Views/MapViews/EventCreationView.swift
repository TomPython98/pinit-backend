import SwiftUI
import MapKit
import PhotosUI
import CoreLocation
import MapboxMaps
import Combine

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
        NavigationStack {
        ZStack {
                // Professional background
            Color.bgSurface
                .ignoresSafeArea()
            
                // Subtle gradient
            LinearGradient(
                    colors: [Color.gradientStart.opacity(0.03), Color.gradientEnd.opacity(0.01)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with progress
                        headerSection
                            .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
                        
                        // Main content in cards
                        VStack(spacing: 20) {
                            // Essential Info Card
                            essentialInfoCard
                                .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
                            
                            // Date & Time Card
                            dateTimeCard
                                .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
                            
                            // Location Card
                            locationCard
                                .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
                            
                            // Event Settings Card
                            settingsCard
                                .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
                            
                            // Optional Features Card
                            optionalFeaturesCard
                                .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
                        }
                        .padding(.horizontal, 20)
                        
                        // Create Button
                        createButton
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
                    }
                }
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgCard, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textPrimary)
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
            .animation(.easeInOut(duration: 0.3), value: showLocationSuggestions)
            .animation(.easeInOut(duration: 0.3), value: isGeocoding)
            .animation(.easeInOut(duration: 0.3), value: isSearchingSuggestions)
            .animation(.easeInOut(duration: 0.3), value: showSuccessAnimation)
            .animation(.easeInOut(duration: 0.3), value: isLoading)
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
                        .animation(.easeInOut(duration: 0.3), value: completionProgress)
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
                
                // Event Type
                VStack(alignment: .leading, spacing: 8) {
                            Text("Event Type")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.textPrimary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(EventType.allCases, id: \.self) { type in
                                eventTypeButton(type)
                            }
                        }
                        .padding(.horizontal, 4)
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
                    Text("Date")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.black)

                    DatePicker("", selection: $eventDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .accentColor(.brandPrimary)
                        .environment(\.colorScheme, .light)
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
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .frame(maxHeight: 450)
                            .padding(.top, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
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
                    Text("Audience")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.textPrimary)
                    Picker("Audience", selection: $audienceSelection) {
                        Text("Public").tag(Audience.publicEvent)
                        Text("Private").tag(Audience.privateEvent)
                    }
                    .pickerStyle(.segmented)
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
                
                // Private visibility callout + Invite CTA
                if audienceSelection == .privateEvent {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(Color.pinItWarning)
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Private Event")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.textPrimary)
                            Text("This event is hidden from everyone except:")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            Text("• Friends you invite directly")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            Text("• Users auto-matched by interests")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            Button(action: { showFriendPicker = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.caption)
                                    Text("Invite friends")
                                        .font(.footnote.weight(.semibold))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.brandPrimary.opacity(0.12))
                                .foregroundColor(.brandPrimary)
                                .cornerRadius(8)
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.pinItWarning.opacity(0.12))
                    .cornerRadius(10)
                }
                        
                // Friend Invitations (only show if private)
                        if !isPublic {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Invite Friends")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            Button(action: { showFriendPicker = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.caption)
                                    Text("Add Friends")
                                        .font(.caption.weight(.medium))
                                }
                                .foregroundColor(.brandPrimary)
                            }
                        }
                        
                        if !selectedFriends.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(selectedFriends, id: \.self) { friend in
                                        HStack(spacing: 4) {
                                            Text(friend)
                                                .font(.caption.weight(.medium))
                                .foregroundColor(.brandPrimary)
                                            
                                            Button(action: { removeFriend(friend) }) {
                                                Image(systemName: "xmark")
                                                    .font(.caption2)
                                                    .foregroundColor(.textSecondary)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.brandPrimary.opacity(0.1))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        } else {
                            Text("No friends invited yet")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                .padding(.vertical, 8)
                        }
                    }
                }
                
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
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .animation(.easeInOut(duration: 0.3), value: isFormValid)
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
                        .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isLoading)
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
    
    private func eventTypeButton(_ type: EventType) -> some View {
        Button(action: { selectedEventType = type }) {
            VStack(spacing: 4) {
                Image(systemName: eventTypeIcon(type))
                    .font(.system(size: 16))
                    .foregroundColor(selectedEventType == type ? .white : eventTypeColor(type))
                
                Text(type.displayName)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(selectedEventType == type ? .white : .textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 55, height: 50)
                                                .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedEventType == type ? eventTypeColor(type) : Color.bgSecondary)
                                                )
                                                .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedEventType == type ? Color.clear : Color.bgSecondary, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
        !eventTitle.isEmpty &&
        !eventDescription.isEmpty &&
        !locationName.isEmpty &&
        eventDate < eventEndDate
        // Removed the auto-matching tags requirement to make it easier
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
        
        // Cancel previous search task
        searchTask?.cancel()
        
        isSearchingSuggestions = true
        
        // Use Google Places API for location search
        searchTask = Task {
            do {
                let results = try await googlePlacesService.searchLocations(query: query, near: selectedCoordinate)
                
                // Multiple safety checks before updating UI
                guard !Task.isCancelled,
                      !results.isEmpty else { return }
                
                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    
                    self.isSearchingSuggestions = false
                    self.locationSuggestions = results
                    self.showLocationSuggestions = true
                }
            } catch {
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
        
        withAnimation(.easeInOut(duration: 0.3)) {
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
            
            // Hide success animation after delay
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    withAnimation {
                        showSuccessAnimation = false
                    }
                }
            }
        }
    }
    
    
    private func geocodeLocation(_ address: String) {
        // Safety check
        guard !address.isEmpty, address.count <= 200 else { return }
        
        // Set loading state
        isGeocoding = true
        
        // Use Google Places API for geocoding
        Task {
            do {
                let result = try await googlePlacesService.geocodeAddress(address)
                
                await MainActor.run {
                self.isGeocoding = false
                    self.selectLocation(result)
                }
            } catch {
                await MainActor.run {
                self.isGeocoding = false
                    // Keep current coordinate as fallback
                }
            }
        }
    }
    
    private func formatDuration(from startDate: Date, to endDate: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: startDate, to: endDate)
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        
        if hours > 0 {
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
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        // Success - parse response
                        if let data = data {
                            do {
                                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                
                                // Create local event for UI using the backend event ID
                                let eventId = json?["event_id"] as? String ?? UUID().uuidString
                                
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
                                
                                self.onSave(newEvent)
                                self.dismiss()
                            } catch {
                            }
                        }
                        } else {
                                }
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
                        .foregroundColor(.textSecondary)
                    
                    TextField("Search friends", text: $searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.black) // Ensure text is black for visibility
                    }
                    .padding()
                .background(Color.bgSecondary)
                    .cornerRadius(12)
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
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .listRowBackground(Color.bgCard)
                    .onTapGesture {
                        toggleFriend(friend)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.bgSurface)
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
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
        let mapView = MapView(frame: .zero)
        
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


