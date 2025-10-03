import SwiftUI
import MapKit
import PhotosUI

// MARK: - EventCreationView
struct EventCreationView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var calendarManager: CalendarManager
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Event State
    @State private var eventTitle = ""
    @State private var eventDescription = ""
    @State private var eventDate = Date()
    @State private var eventEndDate = Date().addingTimeInterval(3600) // 1 hour later by default
    @State private var selectedEventType: EventType = .study  // Default type
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    
    let initialCoordinate: CLLocationCoordinate2D
    @State private var selectedCoordinate: CLLocationCoordinate2D
    @State private var invitedFriends = ""
    @State private var isPublic = true  // Default: Public
    @State private var eventSearchQuery = ""
    @State private var eventSearchResults: [MKMapItem] = []
    @State private var maxParticipants = 10
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var enableAutoMatching = false // Add auto-matching toggle
    @State private var currentTab = 0 // For paged navigation
    @State private var isLoading = false
    
    var onSave: (StudyEvent) -> Void
    
    // MARK: - Init
    init(coordinate: CLLocationCoordinate2D, onSave: @escaping (StudyEvent) -> Void) {
        self.initialCoordinate = coordinate
        self._selectedCoordinate = State(initialValue: coordinate)
        self.onSave = onSave
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.bgSurface
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                TabView(selection: $currentTab) {
                    // Basic Info
                    basicInfoView
                        .tag(0)
                    
                    // Location & Time
                    locationTimeView
                        .tag(1)
                    
                    // Social & Tags
                    socialTagsView
                        .tag(2)
                    
                    // Review & Create
                    reviewView
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Navigation buttons
                navigationControls
            }
            
            // Loading overlay
            if isLoading {
                loadingOverlay
            }
        }
        .sheet(isPresented: $showImagePicker) {
            //ImagePicker(selectedImages: $selectedImages)
        }
    }
    
    // MARK: - Header View
    var headerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .font(.headline)
            .foregroundColor(Color.textPrimary)
            
            Spacer()
            
            Text("Create Event")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Color.textPrimary)
            
            Spacer()
            
            // Make the header Save button inactive
            Text("Save")
                .font(.headline)
                .foregroundColor(Color.textMuted) // Indicate inactive state
        }
        .padding()
        .background(Color.bgCard)
        .cornerRadius(15)
        .shadow(color: Color.cardShadow, radius: 5, x: 0, y: 2)
        .padding()
    }
    
    // MARK: - Basic Info View
    var basicInfoView: some View {
                ScrollView {
            VStack(spacing: 16) {
                // Title Card
                cardView {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "pencil")
                                .foregroundColor(.brandPrimary)
                            Text("Event Title")
                                .font(.headline)
                                .foregroundColor(Color.textPrimary)
                        }
                        
                        TextField("Enter title", text: $eventTitle)
                            .padding()
                            .background(Color.bgSecondary)
                            .foregroundColor(Color.textPrimary)
                            .cornerRadius(8)
                    }
                }
                
                // Event Type
                cardView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(.brandPrimary)
                            Text("Event Type")
                                .font(.headline)
                                .foregroundColor(Color.textPrimary)
                        }
                        
                        Picker("Event Type", selection: $selectedEventType) {
                            ForEach(EventType.allCases) { type in
                                HStack {
                                    Circle()
                                        .fill(eventTypeColor(type))
                                        .frame(width: 12, height: 12)
                                    
                                    Text(type.displayName)
                                        .foregroundColor(Color.textPrimary)
                                }
                                .tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                // Description Card
                cardView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "text.alignleft")
                                .foregroundColor(.brandPrimary)
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(Color.textPrimary)
                        }
                                
                                TextEditor(text: $eventDescription)
                            .frame(minHeight: 100)
                            .padding(4)
                            .background(Color.bgSecondary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.divider, lineWidth: 1)
                            )
                            .overlay(
                                Group {
                                    if eventDescription.isEmpty {
                                        Text("Describe your event...")
                                            .foregroundColor(Color.textMuted)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 10)
                                    }
                                },
                                alignment: .topLeading
                            )
                            .colorScheme(.light)
                    }
                }
                
                // Image upload card
                cardView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "photo")
                                .foregroundColor(.brandPrimary)
                            Text("Event Photos")
                                .font(.headline)
                        }
                        
                                Button(action: { showImagePicker = true }) {
                                    HStack {
                                Image(systemName: "plus")
                                Text("Add Photos")
                                    }
                                    .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.brandPrimary)
                            .cornerRadius(8)
                                }
                                
                                if !selectedImages.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 10) {
                                            ForEach(selectedImages, id: \.self) { image in
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 80, height: 80)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                        }
                                    }
                                }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Location & Time View
    var locationTimeView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Date Card
                cardView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.brandPrimary)
                            Text("Event Date & Time")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Start")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                                
                                DatePicker("", selection: $eventDate)
                                        .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("End")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                                
                                DatePicker("", selection: $eventEndDate)
                                        .datePickerStyle(.compact)
                                    .labelsHidden()
                                        .onChange(of: eventDate) { oldValue, newStart in
                                            if eventEndDate < newStart {
                                                eventEndDate = newStart.addingTimeInterval(3600)
                                            }
                                    }
                            }
                        }
                        .padding(.leading, 8)
                    }
                }
                
                // Location Search
                cardView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.brandPrimary)
                            Text("Event Location")
                                .font(.headline)
                        }
                        
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.textMuted)
                            TextField("Search for a location...", text: $eventSearchQuery)
                                .padding(8)
                                .background(Color.bgSecondary)
                                .cornerRadius(8)
                                .onChange(of: eventSearchQuery) { oldValue, newValue in
                                    searchEventLocations()
                                }
                        }
                        
                        if !eventSearchResults.isEmpty {
                            ScrollView {
                                VStack(spacing: 8) {
                                    ForEach(eventSearchResults, id: \.self) { place in
                                        Button {
                                            eventSearchQuery = place.placemark.name ?? "Unknown Place"
                                            selectedCoordinate = place.placemark.coordinate
                                        } label: {
                                HStack {
                                                VStack(alignment: .leading) {
                                                    Text(place.placemark.name ?? "Unknown")
                                                        .font(.subheadline.bold())
                                                        .foregroundColor(.textPrimary)
                                                    Text(place.placemark.title ?? "")
                                                        .font(.caption)
                                                        .foregroundColor(.textSecondary)
                                                }
                                                Spacer()
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundColor(.brandPrimary)
                                            }
                                            .padding(10)
                                            .background(Color.bgSecondary)
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                        
                        // Selected location display
                        HStack {
                            Image(systemName: "mappin")
                                .foregroundColor(.brandWarning)
                            Text(eventSearchQuery.isEmpty ? "Default Location" : eventSearchQuery)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.vertical, 8)
                        
                        Text("Coordinates: \(String(format: "%.4f", selectedCoordinate.latitude)), \(String(format: "%.4f", selectedCoordinate.longitude))")
                            .font(.caption)
                            .foregroundColor(.textMuted)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Social & Tags View
    var socialTagsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Privacy Card
                cardView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.brandPrimary)
                            Text("Event Privacy")
                                .font(.headline)
                        }
                        
                        Toggle(isOn: $isPublic) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(isPublic ? "Public Event" : "Private Event")
                                    .font(.subheadline)
                                
                                Text(isPublic ? 
                                     "Anyone can see and join this event" : 
                                        "Only invited users can see this event")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .brandPrimary))
                        
                        if !isPublic {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Invited Friends")
                                    .font(.subheadline)
                                
                                TextField("Usernames (comma-separated)", text: $invitedFriends)
                                    .padding()
                                    .background(Color.bgSecondary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Auto-matching Card
                cardView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.brandPrimary)
                            Text("Auto-Matching")
                                .font(.headline)
                        }
                        
                        Toggle(isOn: $enableAutoMatching) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Enable Auto-Matching")
                                    .font(.subheadline)
                                
                                Text("Automatically invite users with similar interests")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .brandPrimary))
                        
                        if enableAutoMatching {
                            VStack(alignment: .leading, spacing: 16) {
                                Divider()
                                
                                // Participants limit
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Max Participants")
                                        .font(.subheadline)
                                    
                                    HStack {
                                        Text("\(maxParticipants)")
                                            .fontWeight(.semibold)
                                            .frame(width: 40, alignment: .center)
                                        
                                        Slider(value: .init(
                                            get: { Double(maxParticipants) },
                                            set: { maxParticipants = Int($0) }
                                        ), in: 2...50, step: 1)
                                        .accentColor(.brandPrimary)
                                    }
                                }
                                
                                Divider()
                                
                                // Interest Tags Section
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Interest Tags")
                                        .font(.subheadline)
                                    
                                    // Tag input
                                    HStack {
                                        TextField("Add tag...", text: $newTag)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.bgSecondary)
                                            .cornerRadius(8)
                                        
                                        Button(action: {
                                            if !newTag.isEmpty && !tags.contains(newTag) {
                                                withAnimation {
                                                    tags.append(newTag)
                                                    newTag = ""
                                                }
                                            }
                                        }) {
                                            Text("Add")
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(newTag.isEmpty ? Color.gray : Color.brandPrimary)
                                                )
                                        }
                                        .disabled(newTag.isEmpty)
                                    }
                                    
                                    // Tag display
                                    if !tags.isEmpty {
                                        FlowLayout(spacing: 8) {
                                            ForEach(tags, id: \.self) { tag in
                                                TagView(tag: tag) {
                                                    withAnimation {
                                                        tags.removeAll { $0 == tag }
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    } else {
                                        Text("Add tags to improve matching")
                                            .font(.caption)
                                            .foregroundColor(.textMuted)
                                            .padding(.vertical, 8)
                                    }
                                    
                                    // Suggestions
                                    if tags.count < 5 {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Suggested Tags:")
                                                .font(.caption)
                                                .foregroundColor(.textSecondary)
                                            
                                            let suggestions = ["Programming", "Swift", "iOS", "Machine Learning", "Data Science", "Study", "Group Project", "Networking"]
                                                .filter { !tags.contains($0) }
                                            
                                            FlowLayout(spacing: 8) {
                                                ForEach(suggestions.prefix(6), id: \.self) { suggestion in
                                                    Button(action: {
                                                        withAnimation {
                                                            tags.append(suggestion)
                                                        }
                                                    }) {
                                                        Text(suggestion)
                                                            .font(.caption)
                                                            .foregroundColor(.brandPrimary)
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
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Review View
    var reviewView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Event Summary Card
                cardView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.brandPrimary)
                            Text("Event Summary")
                                .font(.headline)
                                .foregroundColor(Color.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            // Title and Type
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Title")
                                    .font(.caption)
                                    .foregroundColor(Color.textSecondary)
                                
                                HStack {
                                    Text(eventTitle.isEmpty ? "Untitled Event" : eventTitle)
                                        .font(.subheadline.bold())
                                        .foregroundColor(Color.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text(selectedEventType.displayName)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(eventTypeColor(selectedEventType))
                                        .cornerRadius(8)
                                }
                            }
                            
                            Divider()
                            
                            // Date and Time
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Schedule")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.textSecondary)
                                            .frame(width: 20)
                                        Text(formatDate(eventDate))
                                            .font(.subheadline)
                                    }
                                    
                                    HStack {
                                        Image(systemName: "clock")
                                            .foregroundColor(.textSecondary)
                                            .frame(width: 20)
                                        Text("\(formatTime(eventDate)) - \(formatTime(eventEndDate))")
                                            .font(.subheadline)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // Location
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Location")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                
                                Text(eventSearchQuery.isEmpty ? "Default Location" : eventSearchQuery)
                                    .font(.subheadline)
                            }
                            
                            Divider()
                            
                            // Privacy and Auto-matching
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Settings")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                
                                HStack {
                                    Image(systemName: isPublic ? "globe" : "lock")
                                        .foregroundColor(.textSecondary)
                                        .frame(width: 20)
                                    Text(isPublic ? "Public event" : "Private event")
                                        .font(.subheadline)
                                }
                                
                                HStack {
                                    Image(systemName: "person.2")
                                        .foregroundColor(.textSecondary)
                                        .frame(width: 20)
                                    Text(enableAutoMatching ? "Auto-matching enabled" : "Auto-matching disabled")
                                        .font(.subheadline)
                                }
                                
                                if enableAutoMatching {
                                    HStack {
                                        Image(systemName: "number")
                                            .foregroundColor(.textSecondary)
                                            .frame(width: 20)
                                        Text("Maximum \(maxParticipants) participants")
                                            .font(.subheadline)
                                    }
                                }
                            }
                            
                            // Show tags if auto-matching is enabled
                            if enableAutoMatching && !tags.isEmpty {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Interest Tags")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                    
                                    FlowLayout(spacing: 6) {
                                        ForEach(tags, id: \.self) { tag in
                                            Text(tag)
                                                .font(.caption)
                                                .foregroundColor(.brandPrimary)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.brandPrimary.opacity(0.1))
                                                )
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                            }
                            
                            if !eventDescription.isEmpty {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Description")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                    
                                    Text(eventDescription)
                                        .font(.subheadline)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                
                // Validation alerts
                if eventTitle.isEmpty {
                    validationAlert(message: "Event title is required")
                }
                
                if enableAutoMatching && tags.isEmpty {
                    validationAlert(message: "Interest tags are required for auto-matching")
                }
                
                if eventDate >= eventEndDate {
                    validationAlert(message: "End time must be after start time")
                }
                
                // Create button
                Button(action: createEvent) {
                    Text("Create Event")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.brandPrimary, Color.brandSecondary]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.coloredShadow, radius: 5, x: 0, y: 2)
                }
                .disabled(
                    eventTitle.isEmpty || 
                    eventDate >= eventEndDate ||
                    (enableAutoMatching && tags.isEmpty)
                )
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .padding()
        }
    }
    
    // MARK: - Navigation Controls
    var navigationControls: some View {
        HStack {
            if currentTab > 0 {
                Button(action: {
                    withAnimation {
                        currentTab -= 1
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.bgSecondary)
                    .cornerRadius(8)
                }
            }
            
            Spacer()
            
            if currentTab < 3 {
                Button(action: {
                    withAnimation {
                        currentTab += 1
                    }
                }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.brandPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(
                    (currentTab == 0 && eventTitle.isEmpty) ||
                    (currentTab == 1 && eventDate >= eventEndDate) ||
                    (currentTab == 2 && enableAutoMatching && tags.isEmpty)
                )
            }
        }
        .padding()
        .background(Color.bgCard)
        .shadow(color: Color.cardShadow, radius: 3, y: -2)
    }
    
    // MARK: - Loading Overlay
    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Creating your event...")
                    .font(.headline)
                .foregroundColor(.white)
            }
            .padding(30)
            .background(Color.bgCard.opacity(0.9))
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
    
    // MARK: - Helper Views
    func cardView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(Color.bgCard)
            .cornerRadius(16)
            .shadow(color: Color.cardShadow, radius: 5, x: 0, y: 2)
    }
    
    func validationAlert(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.brandWarning)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.brandWarning)
            
            Spacer()
        }
        .padding(12)
        .background(Color.brandWarning.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Functions
    private func eventTypeColor(_ type: EventType) -> Color {
        switch type {
        case .study:
            return Color.brandPrimary
        case .party:
            return Color.brandAccent
        case .business:
            return Color.brandSecondary
        case .cultural:
            return Color.orange
        case .academic:
            return Color.green
        case .networking:
            return Color.pink
        case .social:
            return Color.red
        case .language_exchange:
            return Color.teal
        case .other:
            return Color.textSecondary
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Event Creation
    private func createEvent() {
        // Set loading state
        isLoading = true

        // Create the basic event
                let username = accountManager.currentUser ?? "Guest"
        
        // Save tags for debugging and local preservation
        let selectedTags = tags.isEmpty ? ["general", eventTitle.lowercased()] : tags
        print("🏷️ Selected tags for event: \(selectedTags)")
        
        // Store tags with title as temporary key - we'll update with event ID later
        let tempKey = "event_tags_title_\(eventTitle.lowercased())"
        UserDefaults.standard.set(selectedTags, forKey: tempKey)
        print("💾 Saved tags with title key: \(tempKey) = \(selectedTags)")
        
                let newEvent = StudyEvent(
                    title: eventTitle.isEmpty ? "New Event" : eventTitle,
                    coordinate: selectedCoordinate,
                    time: eventDate,
                    endTime: eventEndDate,
            description: eventDescription,
            invitedFriends: invitedFriends.isEmpty ? [] : invitedFriends.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            attendees: [username], // Add the current user as an attendee
                    isPublic: isPublic,
                    host: username,
            hostIsCertified: false, // Set hostIsCertified
            eventType: selectedEventType,
            isAutoMatched: enableAutoMatching,
            interestTags: selectedTags
        )

        // Send to backend with tags for auto-matching
        sendEventToBackend(newEvent)
    }
    
    private func sendEventToBackend(_ event: StudyEvent) {
        guard let url = URL(string: APIConfig.fullURL(for: "createEvent")) else {
            isLoading = false
            dismiss()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let formattedStartDate = isoFormatter.string(from: event.time)
        let formattedEndDate = isoFormatter.string(from: event.endTime)
        
        // Prepare the request body
        var jsonBody: [String: Any] = [
            "host": event.host,
            "title": event.title,
            "latitude": event.coordinate.latitude,
            "longitude": event.coordinate.longitude,
            "description": event.description ?? "",
            "time": formattedStartDate,
            "end_time": formattedEndDate,
            "is_public": event.isPublic,
            "invited_friends": event.invitedFriends,
            "attendees": event.attendees, // Add the attendees list
            "event_type": event.eventType.rawValue,
            "max_participants": maxParticipants
        ]
        
        // Add auto-matching data if enabled
        if enableAutoMatching {
            // Explicitly mark auto-matching as enabled - use true instead of Bool because some backends might expect different formats
            jsonBody["auto_matching_enabled"] = true
            
            // Make sure to send the tags - this is critical for matching
            // Normalize tags: trim whitespace, lowercase, and ensure they're not empty
            let normalizedTags = tags.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
                                   .filter { !$0.isEmpty }
            
            // If no tags provided, use default ones based on event type and title
            let tagsToSend: [String]
            if normalizedTags.isEmpty {
                // Generate meaningful default tags
                var defaultTags = [eventTitle.lowercased(), "event"]
                
                // Add tags based on event type
                switch selectedEventType {
                case .study:
                    defaultTags.append(contentsOf: ["study", "education", "learning"])
                case .party:
                    defaultTags.append(contentsOf: ["party", "social", "fun"])
                case .business:
                    defaultTags.append(contentsOf: ["business", "meeting", "networking"])
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
                    defaultTags.append(contentsOf: ["meetup", "gathering"])
                }
                
                // Remove duplicates and empty strings
                tagsToSend = Array(Set(defaultTags.filter { !$0.isEmpty }))
            } else {
                tagsToSend = normalizedTags
            }
            
            // IMPORTANT: Make sure this matches exactly what the backend expects
            jsonBody["interest_tags"] = tagsToSend
            
            // Store in UserDefaults for persistence
            let eventTagsKey = "event_tags_\(event.id.uuidString)"
            UserDefaults.standard.set(tagsToSend, forKey: eventTagsKey)
            print("💾 Backup: Saved event tags to UserDefaults with key: \(eventTagsKey)")
            
            // Emphasize max participants for matching
            jsonBody["max_participants"] = maxParticipants
            
            // Try to specify a lower match threshold for better results
            jsonBody["match_threshold"] = 1  // Require only 1 matching interest for better results
            
            print("📊 DEBUG: Auto-matching enabled with settings:")
            print("   🔹 Tags: \(tagsToSend)")
            print("   🔹 Max participants: \(maxParticipants)")
            print("   🔹 Host user: \(event.host)")
            print("   🔹 Public event: \(event.isPublic)")
            
            // Print critical info about the exact keys being used
            print("📝 IMPORTANT: Sending auto-matching payload with exact keys:")
            print("   🔑 \"auto_matching_enabled\": \(jsonBody["auto_matching_enabled"] ?? "nil")")
            print("   🔑 \"interest_tags\": \(jsonBody["interest_tags"] ?? "nil")")
            print("   🔑 \"max_participants\": \(jsonBody["max_participants"] ?? "nil")")
            print("   🔑 \"match_threshold\": \(jsonBody["match_threshold"] ?? "nil")")
        } else {
            // Even for non-auto-matched events, still send tags if available for display
            if !tags.isEmpty {
                jsonBody["interest_tags"] = tags
                print("📝 Including tags for non-auto-matched event: \(tags)")
            }
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
            print("🔄 Sending event data: \(jsonBody)")
            
            // Print request curl command for debugging
            #if DEBUG
            // Access curlString directly since it's not an optional
            let curlString = request.curlString
            print("🔄 CURL equivalent: \(curlString)")
            
            // Also print basic request details
            print("🔄 [DEBUG] Request URL: \(request.url?.absoluteString ?? "unknown")")
            print("🔄 [DEBUG] Request Method: \(request.httpMethod ?? "unknown")")
            print("🔄 [DEBUG] Request Headers: \(request.allHTTPHeaderFields ?? [:])")
            #endif
        } catch {
            print("❌ JSON encoding error: \(error.localizedDescription)")
            isLoading = false
            dismiss()
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    self.dismiss()
                    return
                }
                
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                print("📡 HTTP Status: \(statusCode)")
                
                // Log response data
                if let data = data, let responseStr = String(data: data, encoding: .utf8) {
                    print("📦 Response: \(responseStr)")
                    
                    // Parse auto-matching results if available
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // Only add event to calendar after backend confirms creation
                        if statusCode >= 200 && statusCode < 300 {
                            if let eventId = json["event_id"] as? String {
                                let backendEvent = StudyEvent(
                                    id: UUID(uuidString: eventId) ?? UUID(),
                                    title: event.title,
                                    coordinate: event.coordinate,
                                    time: event.time,
                                    endTime: event.endTime,
                                    description: event.description,
                                    invitedFriends: event.invitedFriends,
                                    attendees: event.attendees,
                                    isPublic: event.isPublic,
                                    host: event.host,
                                    hostIsCertified: event.hostIsCertified,
                                    eventType: event.eventType,
                                    isAutoMatched: event.isAutoMatched,
                                    interestTags: event.interestTags
                                )
                                self.calendarManager.addEvent(backendEvent)
                            }
                        }
                        
                        // Process enhanced auto-matching results
                        if let autoMatchResults = json["auto_matching_results"] as? [String: Any] {
                            print("⭐ ENHANCED AUTO-MATCHING RESULTS RECEIVED:")
                            
                            // Print complete raw results for debugging
                            for (key, value) in autoMatchResults {
                                print("   🔸 \(key): \(value)")
                            }
                            
                            let invitesSent = autoMatchResults["invites_sent"] as? Int ?? 0
                            let successfulMatches = autoMatchResults["successful_matches"] as? Int ?? 0
                            
                            print("✅ Enhanced auto-matched results: \(successfulMatches) successful matches, \(invitesSent) invites sent")
                            
                            if invitesSent == 0 {
                                print("⚠️ No users matched! Details:")
                                print("   📋 Tags used: \(jsonBody["interest_tags"] ?? [])")
                                
                                // Check if there were any potential matches at all
                                if let potentialCount = autoMatchResults["potential_match_count"] as? Int {
                                    print("   👥 Potential users found: \(potentialCount)")
                                    if potentialCount == 0 {
                                        print("   ❌ No users with matching interests in system!")
                                        print("   💡 Try adding more common tags or checking that other users have interests set")
                                    } else {
                                        print("   ⚠️ Users found but no matches made - check enhanced matching algorithm")
                                        print("   💡 The enhanced matching threshold might be too high (now 30+ points)")
                                    }
                                }
                                
                                // Show match threshold if available
                                if let threshold = autoMatchResults["match_threshold"] as? Int {
                                    print("   🎯 Enhanced matching threshold: \(threshold) - must have at least this many points")
                                }
                            }
                            
                            // Detailed matched user information with enhanced scoring
                            if let matchedUsers = autoMatchResults["matched_users"] as? [[String: Any]] {
                                print("🔍 Enhanced matched users details (\(matchedUsers.count) users):")
                                for user in matchedUsers {
                                    if let username = user["username"] as? String,
                                       let matchingInterests = user["matching_interests"] as? [String],
                                       let score = user["score"] as? Double {
                                        print("👤 Enhanced matched with \(username):")
                                        print("   ✓ Enhanced match score: \(score)")
                                        print("   ✓ Common interests: \(matchingInterests.joined(separator: ", "))")
                                        
                                        // Show score breakdown if available
                                        if let scoreBreakdown = user["score_breakdown"] as? [String: Any] {
                                            print("   📊 Score breakdown:")
                                            for (factor, factorScore) in scoreBreakdown {
                                                if let score = factorScore as? Double, score > 0 {
                                                    print("     • \(factor): \(score)")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Show enhanced matching explanation
                            print("🎯 Enhanced matching now considers:")
                            print("   • Interest matching (25 points per match)")
                            print("   • Academic similarity (university, degree, year)")
                            print("   • Skill relevance to event content")
                            print("   • Bio similarity with event description")
                            print("   • Social connections and mutual friends")
                            print("   • Location proximity with enhanced distance scaling")
                            print("   • User reputation and trust level")
                            print("   • Event type preferences based on history")
                            print("   • Time compatibility patterns")
                            print("   • Recent activity level")
                            
                        } else {
                            print("❓ No enhanced auto-matching results in response")
                            if enableAutoMatching {
                                print("⚠️ Enhanced auto-matching was enabled but no results returned!")
                                print("⚠️ Check if backend has enhanced auto-matching feature enabled")
                                print("📝 Raw response content:")
                                for (key, value) in json {
                                    print("   🔹 \(key): \(value)")
                                }
                            }
                        }
                    }
                }
                
                self.dismiss()
            }
        }.resume()
    }
    
    // MARK: - Search Event Locations
    func searchEventLocations() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = eventSearchQuery
        request.region = MKCoordinateRegion(
            center: selectedCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            if let response = response {
                self.eventSearchResults = response.mapItems
            }
        }
    }
}

// MARK: - Tag View
struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(tag)
                .font(.system(.footnote, design: .rounded))
                .fontWeight(.medium)
                .padding(.leading, 10)
                .padding(.trailing, 4)
                .padding(.vertical, 6)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.brandPrimary.opacity(0.8))
            }
            .padding(.trailing, 8)
        }
        .background(
            Capsule()
                .fill(Color.brandPrimary.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(Color.brandPrimary.opacity(0.25), lineWidth: 1)
        )
        .foregroundColor(.brandPrimary)
    }
}

// MARK: - Flow Layout
// FlowLayout is already defined elsewhere in the project
// Using the existing implementation instead of redefining it here
/* 
struct FlowLayout: View {
    let spacing: CGFloat
    let content: () -> [TagView]
    
    init(spacing: CGFloat, @ViewBuilder content: @escaping () -> [TagView]) {
        self.spacing = spacing
        self.content = content
    }
    
    init(spacing: CGFloat, @ViewBuilder content: @escaping () -> [Text]) {
        self.spacing = spacing
        self.content = {
            content().map { text in
                TagView(tag: "", onRemove: {})
                    .overlay(text)
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(0..<content().count, id: \.self) { i in
                content()[i]
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                    .alignmentGuide(.leading) { dimension in
                        if (abs(width - dimension.width) > geometry.size.width) {
                            width = 0
                            height -= dimension.height + spacing
                        }
                        let result = width
                        if i == content().count - 1 {
                            width = 0
                        } else {
                            width -= dimension.width + spacing
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if i == content().count - 1 {
                            height = 0
                        }
                        return result
                    }
            }
        }
        .background(viewHeightReader($height))
    }
    
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}
*/

// MARK: - Enhanced Auto-Matching Results View
struct EnhancedAutoMatchingResultsView: View {
    @ObservedObject var autoMatchingManager: AutoMatchingManager
    let eventId: UUID
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedMatch: AutoMatchingManager.PotentialMatch?
    @State private var showingMatchDetail = false
    
    var body: some View {
        NavigationView {
            VStack {
                if autoMatchingManager.isLoading {
                    VStack {
                        ProgressView("Finding perfect matches...")
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Analyzing interests, skills, location, and more...")
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else if autoMatchingManager.potentialMatches.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Matches Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Try adjusting your event tags or check back later when more users join.")
                            .font(.body)
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        Section(header: Text("Potential Matches (\(autoMatchingManager.potentialMatches.count))")) {
                            ForEach(autoMatchingManager.potentialMatches) { match in
                                MatchRowView(match: match, autoMatchingManager: autoMatchingManager)
                                    .onTapGesture {
                                        selectedMatch = match
                                        showingMatchDetail = true
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Auto-Matching Results")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Refresh") {
                    autoMatchingManager.fetchPotentialMatches(forEventId: eventId) { _ in }
                }
            )
            .sheet(isPresented: $showingMatchDetail) {
                if let match = selectedMatch {
                    MatchDetailView(match: match, autoMatchingManager: autoMatchingManager)
                }
            }
        }
        .onAppear {
            autoMatchingManager.fetchPotentialMatches(forEventId: eventId) { _ in }
        }
    }
}

// MARK: - Match Row View
struct MatchRowView: View {
    let match: AutoMatchingManager.PotentialMatch
    let autoMatchingManager: AutoMatchingManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(match.username)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let detail = autoMatchingManager.matchDetails[match.username] {
                        Text(detail.matchQuality)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(match.matchScore))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("points")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
            }
            
            if !match.matchingInterests.isEmpty {
                Text("🎯 \(match.matchingInterests.joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundColor(Color.textPrimary)
            }
            
            if let detail = autoMatchingManager.matchDetails[match.username],
               !detail.topFactors.isEmpty {
                Text("⭐ \(detail.topFactors.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
            
            if let ratio = match.interestRatio, ratio > 0 {
                HStack {
                    Text("Interest Match:")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                    
                    Text("\(Int(ratio * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Match Detail View
struct MatchDetailView: View {
    let match: AutoMatchingManager.PotentialMatch
    let autoMatchingManager: AutoMatchingManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(match.username)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if let detail = autoMatchingManager.matchDetails[match.username] {
                            Text(detail.matchQuality)
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        
                        Text("Total Score: \(Int(match.matchScore))")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Matching Interests
                    if !match.matchingInterests.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("🎯 Common Interests")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(match.matchingInterests, id: \.self) { interest in
                                    Text(interest)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    
                    // Score Breakdown
                    if let breakdown = match.scoreBreakdown {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("📊 Score Breakdown")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 8) {
                                ScoreRow(title: "Interest Match", score: breakdown.interestMatch, color: .blue)
                                ScoreRow(title: "Academic Similarity", score: breakdown.academicSimilarity, color: .purple)
                                ScoreRow(title: "Skill Relevance", score: breakdown.skillRelevance, color: .orange)
                                ScoreRow(title: "Social Connection", score: breakdown.social, color: .green)
                                ScoreRow(title: "Location", score: breakdown.location, color: .red)
                                ScoreRow(title: "Reputation", score: breakdown.reputationBoost, color: .yellow)
                                ScoreRow(title: "Bio Similarity", score: breakdown.bioSimilarity, color: .pink)
                                ScoreRow(title: "Content Similarity", score: breakdown.contentSimilarity, color: .indigo)
                                ScoreRow(title: "Event Type Preference", score: breakdown.eventTypePreference, color: .teal)
                                ScoreRow(title: "Time Compatibility", score: breakdown.timeCompatibility, color: .brown)
                                ScoreRow(title: "Activity Level", score: breakdown.activityLevel, color: .mint)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    
                    // Interest Ratio
                    if let ratio = match.interestRatio, ratio > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("📈 Interest Match Ratio")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            HStack {
                                Text("\(Int(ratio * 100))%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                
                                Spacer()
                                
                                ProgressView(value: ratio)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                    .frame(width: 100)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                }
                .padding()
            }
            .navigationTitle("Match Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Score Row View
struct ScoreRow: View {
    let title: String
    let score: Double?
    let color: Color
    
    var body: some View {
        if let score = score, score > 0 {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                Text("\(Int(score))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                ProgressView(value: min(score / 25.0, 1.0))  // Normalize to max weight
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .frame(width: 60)
            }
        }
    }
}
