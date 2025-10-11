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
    @State private var locationSuggestions: [String] = []
    @State private var locationSuggestionsCoords: [String: CLLocationCoordinate2D] = [:] // Map suggestion to coordinate
    @State private var showLocationSuggestions = false
    @State private var isGeocoding = false
    @State private var showSuccessAnimation = false
    @State private var isSearchingSuggestions = false
    @State private var isLocationSelected = false
    @State private var suppressLocationOnChange = false // prevent TextField onChange from clearing selection when set programmatically
    
    var onSave: (StudyEvent) -> Void
    
    // MARK: - Init
    init(coordinate: CLLocationCoordinate2D, onSave: @escaping (StudyEvent) -> Void) {
        self.initialCoordinate = coordinate
        self._selectedCoordinate = State(initialValue: coordinate)
        self.onSave = onSave
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
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textPrimary)
            }
        }
        .sheet(isPresented: $showImagePicker) {
                EventImagePicker(selectedImages: $selectedImages)
            }
            .sheet(isPresented: $showFriendPicker) {
                FriendPickerView(selectedFriends: $selectedFriends)
                    .environmentObject(accountManager)
            }
            .animation(.easeInOut(duration: 0.3), value: showLocationSuggestions)
            .animation(.easeInOut(duration: 0.3), value: isGeocoding)
            .animation(.easeInOut(duration: 0.3), value: isSearchingSuggestions)
            .animation(.easeInOut(duration: 0.3), value: showSuccessAnimation)
            .animation(.easeInOut(duration: 0.3), value: isLoading)
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
            cardHeader("Essential Info", icon: "info.circle.fill", color: .blue)
            
            VStack(spacing: 16) {
                // Event Title
                    VStack(alignment: .leading, spacing: 8) {
                            Text("Event Title")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.textPrimary)
                    
                    ZStack(alignment: .leading) {
                        if eventTitle.isEmpty {
                            Text("What's your event about?")
                                .foregroundColor(Color.gray.opacity(0.5))
                                .padding()
                        }
                        TextField("", text: $eventTitle)
                            .foregroundColor(Color.black)
                            .padding()
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
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
                                .foregroundColor(Color.gray.opacity(0.5))
                                .padding()
                        }
                        TextField("", text: $eventDescription, axis: .vertical)
                            .foregroundColor(Color.black)
                            .padding()
                            .lineLimit(3...6)
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Date & Time Card
    private var dateTimeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader("When", icon: "calendar.badge.clock", color: .green)
            
            VStack(spacing: 16) {
                // Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.textPrimary)
                    
                    DatePicker("", selection: $eventDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                
                // Time Range
                HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                        Text("Start Time")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.textPrimary)
                        
                        DatePicker("", selection: $eventDate, displayedComponents: [.hourAndMinute])
                                        .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                        Text("End Time")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.textPrimary)
                        
                        DatePicker("", selection: $eventEndDate, displayedComponents: [.hourAndMinute])
                                        .datePickerStyle(.compact)
                                    .labelsHidden()
                    }
                }
                
                // Duration display
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.textSecondary)
                    Text("Duration: \(formatDuration(from: eventDate, to: eventEndDate))")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
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
            cardHeader("Where", icon: "location.fill", color: .orange)
            
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
                                .foregroundColor(.green)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    
                    VStack(spacing: 0) {
                        HStack {
                            ZStack(alignment: .leading) {
                                if locationName.isEmpty {
                                    Text("Enter location (e.g., Brandenburger Tor, Berlin)")
                                        .foregroundColor(Color.gray.opacity(0.5))
                                        .padding()
                                }
                                TextField("", text: $locationName)
                                    .foregroundColor(Color.black)
                                    .padding()
                                    .onChange(of: locationName) { oldValue, newValue in
                                    // If the change was triggered programmatically, do not reset selection
                                    if suppressLocationOnChange {
                                        suppressLocationOnChange = false
                                    } else if !oldValue.isEmpty && oldValue != newValue {
                                        isLocationSelected = false
                                    }
                                    
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
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            
                            // Dynamic indicator: checkmark, loading, or search button
                            if isLocationSelected && !isGeocoding {
                                // Green checkmark when location is selected
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 18, weight: .semibold))
                                    .transition(.scale.combined(with: .opacity))
                            } else if isGeocoding || isSearchingSuggestions {
                                // Loading indicator
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.orange)
                                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            } else {
                                // Search button when no location selected
                                Button(action: {
                                    if !locationName.isEmpty {
                                        geocodeLocation(locationName)
                                    }
                                }) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .disabled(locationName.isEmpty)
                            }
                        }
                        
                        // Enhanced Location Suggestions with Map Preview
                        if showLocationSuggestions && !locationSuggestions.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(Array(locationSuggestions.prefix(3).enumerated()), id: \.element) { index, suggestion in
                                    LocationSuggestionRow(
                                        suggestion: suggestion,
                                        coordinate: locationSuggestionsCoords[suggestion],
                                        isSelected: false
                                    )
                                    .contentShape(Rectangle()) // Make entire area tappable
                                    .onTapGesture {
                                        // Force immediate state update
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            suppressLocationOnChange = true
                                            locationName = suggestion
                                            showLocationSuggestions = false
                                            locationSuggestions = []
                                            
                                            // Use stored coordinates if available (faster and more accurate)
                                            if let coord = locationSuggestionsCoords[suggestion] {
                                                selectedCoordinate = coord
                                                isLocationSelected = true
                                                print("✅ Location selected immediately: \(suggestion)")
                                            } else {
                                                // Still set as selected while geocoding
                                                isLocationSelected = true
                                                geocodeLocation(suggestion)
                                                print("⏳ Geocoding: \(suggestion)")
                                            }
                                        }
                                    }
                                    
                                    if index < min(2, locationSuggestions.count - 1) {
                                        Divider()
                                            .padding(.horizontal, 16)
                                    }
                                }
                            }
                            .background(Color.bgCard)
                            .cornerRadius(12)
                            .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
                            .padding(.top, 4)
                        }
                        
                        // Mini Map Preview - Show selected location
                        if isLocationSelected {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "map")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text("Location Preview")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(.textSecondary)
                                    Spacer()
                                }
                                
                                MiniMapPreview(coordinate: selectedCoordinate)
                                    .frame(height: 200)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                                
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption2)
                                    Text("\(String(format: "%.4f", selectedCoordinate.latitude)), \(String(format: "%.4f", selectedCoordinate.longitude))")
                                        .font(.caption2)
                                        .foregroundColor(.textSecondary)
                                    Spacer()
                                }
                            }
                            .padding(12)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(12)
                            .padding(.top, 8)
                        }
                    }
                    
                    
                    // Show current coordinates and location info for reference
                    if !locationName.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                        HStack {
                                Image(systemName: "mappin.circle")
                                    .foregroundColor(.orange)
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
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    
                                    Text("Location selected successfully")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    
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
                            .foregroundColor(.green)
                        
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
            cardHeader("Settings", icon: "gearshape.fill", color: .purple)
            
            VStack(spacing: 16) {
                // Privacy Setting
                HStack {
                            VStack(alignment: .leading, spacing: 4) {
                        Text("Event Visibility")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.textPrimary)
                                
                        Text(isPublic ? "Anyone can see and join" : "Only invited people can see")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isPublic)
                        .toggleStyle(SwitchToggleStyle(tint: .brandPrimary))
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
                        
                        Stepper("", value: $maxParticipants, in: 2...50)
                            .labelsHidden()
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Optional Features Card
    private var optionalFeaturesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader("Optional Features", icon: "star.fill", color: .yellow)
            
            VStack(spacing: 16) {
                // Auto-matching Toggle
                                    HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Smart Matching")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.textPrimary)
                        
                        Text("Automatically invite people with similar interests")
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
                                        .foregroundColor(Color.gray.opacity(0.5))
                                        .padding()
                                }
                                TextField("", text: $newTag)
                                    .foregroundColor(Color.black)
                                    .padding()
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
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
        isSearchingSuggestions = true
        
        // Search both Apple Maps (MKLocalSearch) and Mapbox in parallel
        // Apple Maps has excellent POI data for restaurants, bars, cafes, etc.
        let group = DispatchGroup()
        var appleResults: [(String, CLLocationCoordinate2D)] = []
        var mapboxResults: [(String, CLLocationCoordinate2D)] = []
        
        // APPLE MAPS SEARCH (MKLocalSearch) - Best for POIs like restaurants, bars, cafes
        group.enter()
        searchAppleMaps(query: query) { results in
            appleResults = results
            group.leave()
        }
        
        // MAPBOX SEARCH - Good for addresses and international locations
        group.enter()
        searchMapbox(query: query) { results in
            mapboxResults = results
            group.leave()
        }
        
        // Combine results when both searches complete
        group.notify(queue: .main) {
            self.isSearchingSuggestions = false
            
            // Prioritize Apple Maps results (better for POIs), then add unique Mapbox results
            var combinedResults = appleResults
            
            // Add Mapbox results that aren't already in Apple results
            for (mbResult, mbCoord) in mapboxResults {
                let mbName = mbResult.components(separatedBy: " - ").first ?? mbResult
                let isDuplicate = appleResults.contains { (appleResult, _) in
                    let appleName = appleResult.components(separatedBy: " - ").first ?? appleResult
                    // Check if names are similar
                    return appleName.lowercased().contains(mbName.lowercased()) || 
                           mbName.lowercased().contains(appleName.lowercased())
                }
                if !isDuplicate {
                    combinedResults.append((mbResult, mbCoord))
                }
            }
            
            // Store results and their coordinates
            self.locationSuggestions = combinedResults.prefix(10).map { $0.0 }
            self.locationSuggestionsCoords = Dictionary(uniqueKeysWithValues: combinedResults.prefix(10).map { ($0.0, $0.1) })
            self.showLocationSuggestions = !self.locationSuggestions.isEmpty
            
            print("🔍 Search '\(query)' found \(appleResults.count) Apple + \(mapboxResults.count) Mapbox = \(combinedResults.count) total results")
        }
    }
    
    private func searchMapbox(query: String, completion: @escaping ([(String, CLLocationCoordinate2D)]) -> Void) {
        let accessToken = "pk.eyJ1IjoidG9tYmVzaSIsImEiOiJjbTdwNDdvbXAwY3I3MmtzYmZ3dzVtaGJrIn0.yiXVdzVGYjTucLPZPa0hjw"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        
        // Add proximity parameter and bbox for better local results
        let proximityParam = "\(selectedCoordinate.longitude),\(selectedCoordinate.latitude)"
        
        // Create a bounding box around the location (approximately 50km radius)
        let bboxDelta = 0.5 // Roughly 50km at most latitudes
        let minLon = selectedCoordinate.longitude - bboxDelta
        let minLat = selectedCoordinate.latitude - bboxDelta
        let maxLon = selectedCoordinate.longitude + bboxDelta
        let maxLat = selectedCoordinate.latitude + bboxDelta
        let bboxParam = "\(minLon),\(minLat),\(maxLon),\(maxLat)"
        
        // Enhanced parameters for better POI search
        let urlString = "https://api.mapbox.com/geocoding/v5/mapbox.places/\(encodedQuery).json?access_token=\(accessToken)&limit=5&types=poi,address&proximity=\(proximityParam)&bbox=\(bboxParam)&fuzzyMatch=true&language=en"
        
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Mapbox search error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let data = data else {
                completion([])
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let json = json,
                   let features = json["features"] as? [[String: Any]] {
                    
                    let results = features.compactMap { feature -> (String, CLLocationCoordinate2D)? in
                        guard let placeName = feature["place_name"] as? String,
                              let geometry = feature["geometry"] as? [String: Any],
                              let coordinates = geometry["coordinates"] as? [Double],
                              coordinates.count >= 2 else {
                            return nil
                        }
                        
                        let coord = CLLocationCoordinate2D(latitude: coordinates[1], longitude: coordinates[0])
                        
                        let displayName: String
                        if let text = feature["text"] as? String {
                            let placeType = feature["place_type"] as? [String] ?? []
                            if placeType.contains("poi") {
                                displayName = "\(text) - \(placeName)"
                            } else {
                                displayName = placeName
                            }
                        } else {
                            displayName = placeName
                        }
                        
                        return (displayName, coord)
                    }.filter { !$0.0.isEmpty }
                    
                    completion(results)
                } else {
                    completion([])
                }
            } catch {
                print("Mapbox JSON parsing error: \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }
    
    private func searchAppleMaps(query: String, completion: @escaping ([(String, CLLocationCoordinate2D)]) -> Void) {
        guard !query.isEmpty else {
            completion([])
            return
        }
        
        // Create search request with natural language query
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        
        // Set region to search around the current/selected location (50km radius)
        let regionRadius: CLLocationDistance = 50000 // 50km
        let region = MKCoordinateRegion(
            center: selectedCoordinate,
            latitudinalMeters: regionRadius,
            longitudinalMeters: regionRadius
        )
        searchRequest.region = region
        
        // Only show results within this region
        searchRequest.resultTypes = [.pointOfInterest, .address]
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            if let error = error {
                print("Apple Maps search error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let response = response else {
                completion([])
                return
            }
            
            let results = response.mapItems.prefix(8).compactMap { item -> (String, CLLocationCoordinate2D)? in
                guard let name = item.name else { return nil }
                
                let coordinate = item.placemark.coordinate
                
                // Build display string
                var displayParts: [String] = [name]
                
                // Add address context
                var addressParts: [String] = []
                if let thoroughfare = item.placemark.thoroughfare {
                    addressParts.append(thoroughfare)
                }
                if let locality = item.placemark.locality {
                    addressParts.append(locality)
                }
                
                if !addressParts.isEmpty {
                    displayParts.append(addressParts.joined(separator: ", "))
                }
                
                let displayName = displayParts.joined(separator: " - ")
                
                return (displayName, coordinate)
            }
            
            print("🍎 Apple Maps found \(results.count) results for '\(query)'")
            completion(Array(results))
        }
    }
    
    private func geocodeLocation(_ address: String) {
        // Set loading state
        isGeocoding = true
        
        // Use Mapbox Geocoding REST API directly for much better worldwide results
        let accessToken = "pk.eyJ1IjoidG9tYmVzaSIsImEiOiJjbTdwNDdvbXAwY3I3MmtzYmZ3dzVtaGJrIn0.yiXVdzVGYjTucLPZPa0hjw"
        let encodedQuery = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        
        // Add proximity bias for better local results
        let proximityParam = "\(selectedCoordinate.longitude),\(selectedCoordinate.latitude)"
        let urlString = "https://api.mapbox.com/geocoding/v5/mapbox.places/\(encodedQuery).json?access_token=\(accessToken)&limit=1&types=poi,address,place,locality,neighborhood&proximity=\(proximityParam)"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.isGeocoding = false
                self.fallbackGeocode(address)
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isGeocoding = false
                
                if let error = error {
                    self.fallbackGeocode(address)
                    return
                }
                
                guard let data = data else {
                    self.fallbackGeocode(address)
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let features = json["features"] as? [[String: Any]],
                       let firstFeature = features.first,
                       let geometry = firstFeature["geometry"] as? [String: Any],
                       let coordinates = geometry["coordinates"] as? [Double],
                       coordinates.count >= 2 {
                        
                        let longitude = coordinates[0]
                        let latitude = coordinates[1]
                        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        
                        self.selectedCoordinate = coordinate
                        self.isLocationSelected = true
                        
                        // Hide suggestions when location is selected
                        self.showLocationSuggestions = false
                        self.locationSuggestions = []
                        
                        // Update location name with the found result for better accuracy
                        if let placeName = firstFeature["place_name"] as? String {
                            self.locationName = placeName
                        }
                        
                        // Show success animation
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.showSuccessAnimation = true
                        }
                        
                        // Hide success animation after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                self.showSuccessAnimation = false
                            }
                        }
                    } else {
                        self.fallbackGeocode(address)
                    }
                } catch {
                    self.fallbackGeocode(address)
                }
            }
        }.resume()
    }
    
    private func fallbackGeocode(_ address: String) {
        let geocoder = CLGeocoder()
        // Create a custom location manager to avoid device location bias
        geocoder.geocodeAddressString(address, in: nil) { placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    self.selectedCoordinate = placemark.location?.coordinate ?? self.selectedCoordinate
                } else {
                    // Keep current coordinate as last resort
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
        case .study: return .blue
        case .party: return .purple
        case .business: return .orange
        case .cultural: return .yellow
        case .academic: return .green
        case .networking: return .pink
        case .social: return .red
        case .language_exchange: return .teal
        case .other: return .gray
        }
    }
    
    // MARK: - Event Creation
    private func createEvent() {
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
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isSelected ? Color.blue.opacity(0.05) : Color.clear)
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
            return .orange
        }
        if name.contains("bar") || name.contains("pub") || name.contains("club") {
            return .purple
        }
        if name.contains("hotel") || name.contains("hostel") {
            return .green
        }
        if name.contains("museum") || name.contains("gallery") {
            return .blue
        }
        if name.contains("park") || name.contains("plaza") {
            return .green
        }
        if name.contains("university") || name.contains("school") {
            return .indigo
        }
        
        return .blue
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
            // Interactive map with pan enabled
            MapboxMapView(coordinate: coordinate)
            
            // Info bar
            HStack {
                Image(systemName: "hand.point.up.left")
                    .font(.caption2)
                    .foregroundColor(.blue)
                Text("Tap & drag to explore")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.05))
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
        
        // Enable pan gestures, disable zoom/rotate for better UX
        mapView.gestures.options.panEnabled = true
        mapView.gestures.options.pinchZoomEnabled = true // Allow zoom for verification
        mapView.gestures.options.rotateEnabled = false
        mapView.gestures.options.pitchEnabled = false
        mapView.gestures.options.doubleTapToZoomInEnabled = true
        mapView.gestures.options.doubleTouchToZoomOutEnabled = true
        
        // Set camera to the location with zoom level 15
        let cameraOptions = CameraOptions(
            center: coordinate,
            zoom: 15.0,
            bearing: 0,
            pitch: 0
        )
        mapView.mapboxMap.setCamera(to: cameraOptions)
        
        // Add annotation immediately (no need to wait for style)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.addAnnotation(to: mapView, context: context)
        }
        
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
            
            // Update annotation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.addAnnotation(to: mapView, context: context)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(coordinate: coordinate)
    }
    
    private func addAnnotation(to mapView: MapView, context: Context) {
        // Store or reuse the annotation manager
        if context.coordinator.annotationManager == nil {
            context.coordinator.annotationManager = mapView.annotations.makePointAnnotationManager()
        }
        
        guard let annotationManager = context.coordinator.annotationManager else { return }
        
        // Create a point annotation with custom pin like the main map
        var pointAnnotation = PointAnnotation(coordinate: coordinate)
        
        // Use the destination pin image (same as main map)
        if let pinImage = UIImage(named: "dest-pin")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
            pointAnnotation.image = .init(image: pinImage, name: "event-pin")
            pointAnnotation.iconAnchor = .bottom
            pointAnnotation.iconSize = 0.8
        } else {
            // Fallback to system icon
            if let markerImage = UIImage(systemName: "mappin.circle.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
                pointAnnotation.image = .init(image: markerImage, name: "blue-marker")
                pointAnnotation.iconSize = 1.2
            }
        }
        
        // Add the annotation
        annotationManager.annotations = [pointAnnotation]
    }
    
    // Coordinator to manage state
    class Coordinator {
        var annotationManager: PointAnnotationManager?
        var lastCoordinate: CLLocationCoordinate2D
        
        init(coordinate: CLLocationCoordinate2D) {
            self.lastCoordinate = coordinate
        }
    }
}
