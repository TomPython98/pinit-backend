import SwiftUI
import MapKit
import PhotosUI
import CoreLocation

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
    @State private var showLocationSuggestions = false
    @State private var isGeocoding = false
    @State private var showSuccessAnimation = false
    @State private var isSearchingSuggestions = false
    @State private var isLocationSelected = false
    
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
                    
                    TextField("What's your event about?", text: $eventTitle)
                        .textFieldStyle(ModernTextFieldStyle())
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
                    
                    TextField("Tell people what to expect...", text: $eventDescription, axis: .vertical)
                        .textFieldStyle(ModernTextFieldStyle())
                        .lineLimit(3...6)
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
                            TextField("Enter location (e.g., Brandenburger Tor, Berlin)", text: $locationName)
                                .textFieldStyle(ModernTextFieldStyle())
                                .onChange(of: locationName) { _, newValue in
                                    // Reset location selected state when user types
                                    if !newValue.isEmpty {
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
                            
                            // Find Location button
                            Button(action: {
                                if !locationName.isEmpty {
                                    geocodeLocation(locationName)
                                }
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .disabled(locationName.isEmpty || isGeocoding)
                            
                            // Geocoding/Searching indicator with smooth animation
                            if isGeocoding || isSearchingSuggestions {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.orange)
                                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            }
                        }
                        
                        // Location Suggestions - Simplified
                        if showLocationSuggestions && !locationSuggestions.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(locationSuggestions.prefix(3), id: \.self) { suggestion in
                                    Button(action: {
                                        locationName = suggestion
                                        showLocationSuggestions = false
                                        locationSuggestions = []
                                        geocodeLocation(suggestion)
                                    }) {
                                HStack {
                                            Image(systemName: "location")
                                                .foregroundColor(.orange)
                                                        .font(.caption)
                                            
                                            Text(suggestion)
                                                .font(.subheadline)
                                                .foregroundColor(.textPrimary)
                                            
                                                Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color.bgCard)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if suggestion != locationSuggestions.prefix(3).last {
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
                            TextField("Add interest tag", text: $newTag)
                                .textFieldStyle(ModernTextFieldStyle())
                            
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
        
        let accessToken = "pk.eyJ1IjoidG9tYmVzaSIsImEiOiJjbTdwNDdvbXAwY3I3MmtzYmZ3dzVtaGJrIn0.yiXVdzVGYjTucLPZPa0hjw"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://api.mapbox.com/geocoding/v5/mapbox.places/\(encodedQuery).json?access_token=\(accessToken)&limit=5&types=poi,place,locality,neighborhood,address"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.isSearchingSuggestions = false
                self.locationSuggestions = []
                self.showLocationSuggestions = false
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isSearchingSuggestions = false
                
                if let error = error {
                    self.locationSuggestions = []
                    self.showLocationSuggestions = false
                    return
                }
                
                guard let data = data else {
                    self.locationSuggestions = []
                    self.showLocationSuggestions = false
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    if let json = json,
                       let features = json["features"] as? [[String: Any]] {
                        
                        self.locationSuggestions = features.compactMap { feature in
                            guard let placeName = feature["place_name"] as? String else {
                                return nil
                            }
                            return placeName
                        }.filter { !$0.isEmpty }
                        
                        self.showLocationSuggestions = !self.locationSuggestions.isEmpty
                    } else {
                        self.locationSuggestions = []
                        self.showLocationSuggestions = false
                    }
                } catch {
                    self.locationSuggestions = []
                    self.showLocationSuggestions = false
                }
            }
        }.resume()
    }
    
    private func geocodeLocation(_ address: String) {
        // Set loading state
        isGeocoding = true
        
        // Use Mapbox Geocoding REST API directly for much better worldwide results
        let accessToken = "pk.eyJ1IjoidG9tYmVzaSIsImEiOiJjbTdwNDdvbXAwY3I3MmtzYmZ3dzVtaGJrIn0.yiXVdzVGYjTucLPZPa0hjw"
        let encodedQuery = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        let urlString = "https://api.mapbox.com/geocoding/v5/mapbox.places/\(encodedQuery).json?access_token=\(accessToken)&limit=1&types=poi,place,locality,neighborhood,address"
        
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
                    print("📍 Fallback geocoded '\(address)' to: \(self.selectedCoordinate)")
                } else {
                    print("❌ Complete geocoding failure for '\(address)'")
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
                    print("❌ Event creation error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 Event creation status code: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        // Success - parse response
                        if let data = data {
                            do {
                                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                print("✅ Event created successfully: \(json ?? [:])")
                                
                                // Create local event for UI using the backend event ID
                                let eventId = json?["event_id"] as? String ?? UUID().uuidString
                                print("🔍 EventCreationView: Backend returned event_id: \(eventId)")
                                
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
                                
                                print("🔍 EventCreationView: Created StudyEvent with ID: \(newEvent.id.uuidString)")
                                self.onSave(newEvent)
                                self.dismiss()
                            } catch {
                                print("❌ JSON parsing error: \(error.localizedDescription)")
                            }
                        }
                        } else {
                        print("❌ Server error: HTTP \(httpResponse.statusCode)")
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

