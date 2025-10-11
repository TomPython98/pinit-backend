import SwiftUI
import MapKit
import PhotosUI
import CoreLocation
import MapboxMaps

// MARK: - EventEditView
struct EventEditView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var calendarManager: CalendarManager
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Properties
    let event: StudyEvent
    @Binding var studyEvents: [StudyEvent]
    
    // MARK: - Event State
    @State private var eventTitle: String
    @State private var eventDescription: String
    @State private var eventDate: Date
    @State private var eventEndDate: Date
    @State private var selectedEventType: EventType
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    
    @State private var selectedCoordinate: CLLocationCoordinate2D
    @State private var locationName = ""
    @State private var invitedFriends = ""
    @State private var isPublic: Bool
    @State private var eventSearchQuery = ""
    @State private var eventSearchResults: [MKMapItem] = []
    @State private var maxParticipants: Int
    @State private var tags: [String]
    @State private var newTag = ""
    @State private var enableAutoMatching: Bool
    @State private var currentTab = 0
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Location editing states
    @State private var locationSuggestions: [String] = []
    @State private var showLocationSuggestions = false
    @State private var isGeocoding = false
    @State private var isLocationSelected = true // Start as true since we have existing location
    @State private var searchTask: Task<Void, Never>? // For debouncing location search
    @State private var suppressLocationOnChange = false // prevent TextField onChange from clearing selection when set programmatically
    
    // MARK: - Init
    init(event: StudyEvent, studyEvents: Binding<[StudyEvent]>) {
        self.event = event
        self._studyEvents = studyEvents
        
        // Initialize state with current event values
        self._eventTitle = State(initialValue: event.title)
        self._eventDescription = State(initialValue: event.description ?? "")
        self._eventDate = State(initialValue: event.time)
        self._eventEndDate = State(initialValue: event.endTime)
        self._selectedEventType = State(initialValue: event.eventType)
        self._selectedCoordinate = State(initialValue: event.coordinate)
        self._locationName = State(initialValue: "Current Location") // Will be geocoded to get proper name
        self._isPublic = State(initialValue: event.isPublic)
        self._maxParticipants = State(initialValue: 10) // Default value since maxParticipants doesn't exist in StudyEvent
        self._tags = State(initialValue: event.interestTags ?? [])
        self._enableAutoMatching = State(initialValue: event.isAutoMatched ?? false)
        
        // Initialize invited friends string
        self._invitedFriends = State(initialValue: event.invitedFriends.joined(separator: ", "))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgSurface.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab Selector
                    tabSelector
                    
                    // Content
                    TabView(selection: $currentTab) {
                        // Basic Info Tab
                        basicInfoTab
                            .tag(0)
                        
                        // Details Tab
                        detailsTab
                            .tag(1)
                        
                        // Location Tab
                        locationTab
                            .tag(2)
                        
                        // Settings Tab
                        settingsTab
                            .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgCard, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.textPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateEvent()
                    }
                    .foregroundColor(Color.textPrimary)
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                EventImagePicker(selectedImages: $selectedImages)
            }
            .alert("Event Update", isPresented: $showAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { index in
                Button(action: { currentTab = index }) {
                    VStack(spacing: 8) {
                        Text(tabTitles[index])
                            .font(.system(size: 14, weight: currentTab == index ? .semibold : .medium))
                            .foregroundColor(currentTab == index ? Color.textPrimary : Color.textSecondary)
                        
                        Rectangle()
                            .fill(currentTab == index ? Color.brandPrimary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(Color.bgCard)
        .shadow(color: Color.cardShadow, radius: 2, x: 0, y: 1)
    }
    
    private var tabTitles: [String] {
        ["Basic", "Details", "Location", "Settings"]
    }
    
    // MARK: - Basic Info Tab
    private var basicInfoTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Event Title
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "textformat").foregroundColor(.brandPrimary)
                        Text("Event Title").font(.headline).foregroundColor(Color.textPrimary)
                    }
                    ZStack(alignment: .leading) {
                        if eventTitle.isEmpty {
                            Text("Enter event title")
                                .foregroundColor(Color.gray.opacity(0.5))
                                .padding(.horizontal, 12)
                        }
                        TextField("", text: $eventTitle)
                            .foregroundColor(Color.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Event Type
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "tag").foregroundColor(.brandPrimary)
                        Text("Event Type").font(.headline).foregroundColor(Color.textPrimary)
                    }
                    Picker("Event Type", selection: $selectedEventType) {
                        ForEach(EventType.allCases) { type in
                            HStack {
                                Circle().fill(eventTypeColor(type)).frame(width: 12, height: 12)
                                Text(type.displayName).foregroundColor(Color.textPrimary)
                            }.tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.bgSecondary)
                    .cornerRadius(8)
                }
                
                // Date and Time
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar").foregroundColor(.brandPrimary)
                        Text("Date & Time").font(.headline).foregroundColor(Color.textPrimary)
                    }
                    
                    VStack(spacing: 12) {
                        DatePicker("Start Time", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .foregroundColor(Color.textPrimary)
                        
                        DatePicker("End Time", selection: $eventEndDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .foregroundColor(Color.textPrimary)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Details Tab
    private var detailsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "text.alignleft").foregroundColor(.brandPrimary)
                        Text("Description").font(.headline).foregroundColor(Color.textPrimary)
                    }
                    TextEditor(text: $eventDescription)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100)
                        .padding(4)
                        .background(Color.bgSecondary)
                        .foregroundColor(Color.textPrimary)
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
                
                // Max Participants
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.3").foregroundColor(.brandPrimary)
                        Text("Max Participants").font(.headline).foregroundColor(Color.textPrimary)
                    }
                    Stepper(value: $maxParticipants, in: 2...50) {
                        Text("\(maxParticipants) people")
                            .foregroundColor(Color.textPrimary)
                    }
                }
                
                // Interest Tags
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "tag").foregroundColor(.brandPrimary)
                        Text("Interest Tags").font(.headline).foregroundColor(Color.textPrimary)
                    }
                    
                    // Add new tag
                    HStack {
                        ZStack(alignment: .leading) {
                            if newTag.isEmpty {
                                Text("Add tag")
                                    .foregroundColor(Color.gray.opacity(0.5))
                                    .padding(.horizontal, 12)
                                    .allowsHitTesting(false)
                            }
                            TextField("", text: $newTag)
                                .foregroundColor(Color.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        
                        Button("Add") {
                            addTag()
                        }
                        .foregroundColor(Color.brandPrimary)
                        .disabled(newTag.isEmpty)
                    }
                    
                    // Display tags
                    if !tags.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                HStack {
                                    Text(tag)
                                        .font(.caption)
                                        .foregroundColor(Color.textPrimary)
                                    
                                    Button(action: { removeTag(tag) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Color.textMuted)
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.bgSecondary)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Location Tab
    private var locationTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Location Editing Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "location.fill").foregroundColor(.orange)
                        Text("Location").font(.headline).foregroundColor(Color.textPrimary)
                    }
                    
                    VStack(spacing: 16) {
                        // Location Input with Suggestions
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
                                            .padding(.horizontal, 12)
                                            .allowsHitTesting(false)
                                    }
                                    TextField("", text: $locationName)
                                        .foregroundColor(Color.black)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                }
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                    .onChange(of: locationName) { oldValue, newValue in
                                        // Reset location selected state when user types, unless programmatic
                                        if suppressLocationOnChange {
                                            suppressLocationOnChange = false
                                        } else if !newValue.isEmpty && oldValue != newValue {
                                            isLocationSelected = false
                                        }
                                            
                                            // Cancel previous search task
                                            searchTask?.cancel()
                                            
                                            // Only show suggestions, don't auto-geocode
                                            if newValue.count > 2 {
                                                // Debounce the search to avoid throttling
                                                searchTask = Task {
                                                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                                                    
                                                    if !Task.isCancelled {
                                                        await MainActor.run {
                                                            searchLocationSuggestions(query: newValue)
                                                        }
                                                    }
                                                }
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
                                }
                                
                                // Loading indicator
                                if isGeocoding {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Finding location...")
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)
                                    }
                                    .padding(.top, 8)
                                }
                                
                                // Enhanced Location Suggestions
                                if showLocationSuggestions && !locationSuggestions.isEmpty {
                                    VStack(spacing: 0) {
                                        ForEach(Array(locationSuggestions.prefix(3).enumerated()), id: \.element) { index, suggestion in
                                            LocationSuggestionRow(
                                                suggestion: suggestion,
                                                coordinate: nil, // EventEditView doesn't store coordinates yet
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
                                                    isLocationSelected = true // Set immediately
                                                    geocodeLocation(suggestion)
                                                    print("✅ Location selected: \(suggestion)")
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
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    .padding(.top, 8)
                                }
                                
                                // Mini Map Preview for EventEditView
                                if isLocationSelected {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: "map")
                                                .foregroundColor(.blue)
                                                .font(.caption)
                                            Text("Event Location")
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
                        }
                        
                        // Current Coordinates Display
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Coordinates")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.textSecondary)
                            
                            Text("Latitude: \(String(format: "%.6f", selectedCoordinate.latitude))")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            
                            Text("Longitude: \(String(format: "%.6f", selectedCoordinate.longitude))")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, 8)
                    }
                }
                .cardStyle()
                
                // Invited Friends Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "person.2").foregroundColor(.blue)
                        Text("Invited Friends").font(.headline).foregroundColor(Color.textPrimary)
                    }
                    
                    ZStack(alignment: .topLeading) {
                        if invitedFriends.isEmpty {
                            Text("Enter usernames separated by commas")
                                .foregroundColor(Color.gray.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                        TextField("", text: $invitedFriends, axis: .vertical)
                            .foregroundColor(Color.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .lineLimit(3...6)
                    }
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .cardStyle()
            }
            .padding()
        }
        .onAppear {
            // Geocode the current location to get a proper name
            reverseGeocodeLocation()
        }
        .onDisappear {
            // Cancel any pending search tasks
            searchTask?.cancel()
        }
    }
    
    // MARK: - Settings Tab
    private var settingsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Visibility
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "eye").foregroundColor(.brandPrimary)
                        Text("Visibility").font(.headline).foregroundColor(Color.textPrimary)
                    }
                    
                    Toggle("Public Event", isOn: $isPublic)
                        .foregroundColor(Color.textPrimary)
                    
                    Text("Public events are visible to everyone. Private events are only visible to invited friends.")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
                
                // Auto Matching
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles").foregroundColor(.brandPrimary)
                        Text("Auto Matching").font(.headline).foregroundColor(Color.textPrimary)
                    }
                    
                    Toggle("Enable Auto Matching", isOn: $enableAutoMatching)
                        .foregroundColor(Color.textPrimary)
                    
                    Text("Automatically match users with similar interests to your event.")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Functions
    private func eventTypeColor(_ type: EventType) -> Color {
        switch type {
        case .study: return .blue
        case .social: return .green
        case .business: return .purple
        case .cultural: return .orange
        case .party: return .pink
        case .language_exchange: return .cyan
        case .academic: return .indigo
        case .networking: return .teal
        case .other: return .gray
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    // MARK: - Event Update
    private func updateEvent() {
        isLoading = true
        
        guard let username = accountManager.currentUser else {
            alertMessage = "User not found"
            showAlert = true
            isLoading = false
            return
        }
        
        
        // Try updating with URL fallback mechanism
        tryUpdateEvent(index: 0, username: username)
    }
    
    private func tryUpdateEvent(index: Int, username: String) {
        let baseURLs = APIConfig.baseURLs
        
        // Check if we've tried all URLs
        guard index < baseURLs.count else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.alertMessage = "Failed to connect to any server"
                self.showAlert = true
            }
            return
        }
        
        let baseURL = baseURLs[index]
        let endpointPath = APIConfig.endpoints["updateEvent"] ?? "updateEvent"
        let updateURL = "\(baseURL)\(endpointPath)"
        
        
        guard let url = URL(string: updateURL) else {
            // Skip to next URL if this one can't be constructed
            tryUpdateEvent(index: index + 1, username: username)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"  // ✅ Backend expects POST, not PUT
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // ✅ Add JWT authentication header
        accountManager.addAuthHeader(to: &request)
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let formattedStartDate = isoFormatter.string(from: eventDate)
        let formattedEndDate = isoFormatter.string(from: eventEndDate)
        
        // Prepare the request body
        let jsonBody: [String: Any] = [
            "username": username,
            "event_id": event.id.uuidString,
            "title": eventTitle,
            "description": eventDescription,
            "latitude": selectedCoordinate.latitude,
            "longitude": selectedCoordinate.longitude,
            "time": formattedStartDate,
            "end_time": formattedEndDate,
            "is_public": isPublic,
            "event_type": selectedEventType.rawValue,
            "interest_tags": tags
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        } catch {
            alertMessage = "Error preparing request: \(error.localizedDescription)"
            showAlert = true
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Try the next URL
                    self.tryUpdateEvent(index: index + 1, username: username)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    // Try the next URL
                    self.tryUpdateEvent(index: index + 1, username: username)
                    return
                }
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                }
                
                if httpResponse.statusCode == 200 {
                    // Update local event by creating a new one with updated values
                    if let index = self.studyEvents.firstIndex(where: { $0.id == self.event.id }) {
                        let oldEvent = self.studyEvents[index]
                        let updatedEvent = StudyEvent(
                            id: oldEvent.id,
                            title: self.eventTitle,
                            coordinate: self.selectedCoordinate,
                            time: self.eventDate,
                            endTime: self.eventEndDate,
                            description: self.eventDescription,
                            invitedFriends: self.invitedFriends.isEmpty ? [] : self.invitedFriends.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
                            attendees: oldEvent.attendees,
                            isPublic: self.isPublic,
                            host: oldEvent.host,
                            hostIsCertified: oldEvent.hostIsCertified,
                            eventType: self.selectedEventType,
                            isAutoMatched: self.enableAutoMatching,
                            interestTags: self.tags,
                            matchedUsers: oldEvent.matchedUsers
                        )
                        
                        self.studyEvents[index] = updatedEvent
                    }
                    
                    // Notify map to recenter to the updated location immediately
                    NotificationCenter.default.post(
                        name: Notification.Name("EventLocationUpdated"),
                        object: nil,
                        userInfo: [
                            "eventID": self.event.id.uuidString,
                            "lat": self.selectedCoordinate.latitude,
                            "lon": self.selectedCoordinate.longitude
                        ]
                    )
                    
                    self.isLoading = false
                    self.alertMessage = "Event updated successfully!"
                    self.showAlert = true
                } else {
                    // If we got a valid response (even an error), don't try other URLs
                    // This means the server responded but the request failed
                    self.isLoading = false
                    
                    if let data = data, let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMessage = errorData["error"] as? String {
                        self.alertMessage = errorMessage
                    } else {
                        self.alertMessage = "Failed to update event (Status: \(httpResponse.statusCode))"
                    }
                    self.showAlert = true
                }
            }
        }.resume()
    }
    
    // MARK: - Location Functions
    
    private func searchLocationSuggestions(query: String) {
        guard !query.isEmpty else { return }
        
        // Use Apple Maps (MKLocalSearch) which has excellent POI data
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        
        // Set region to search around the event's current location (50km radius)
        let regionRadius: CLLocationDistance = 50000 // 50km
        let region = MKCoordinateRegion(
            center: selectedCoordinate,
            latitudinalMeters: regionRadius,
            longitudinalMeters: regionRadius
        )
        searchRequest.region = region
        searchRequest.resultTypes = [.pointOfInterest, .address]
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Location search error: \(error.localizedDescription)")
                    self.locationSuggestions = []
                    self.showLocationSuggestions = false
                    return
                }
                
                guard let response = response else {
                    self.locationSuggestions = []
                    self.showLocationSuggestions = false
                    return
                }
                
                self.locationSuggestions = response.mapItems.prefix(8).compactMap { item in
                    guard let name = item.name else { return nil }
                    
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
                    
                    return displayParts.joined(separator: " - ")
                }
                
                self.showLocationSuggestions = !self.locationSuggestions.isEmpty
                print("🔍 EventEdit search '\(query)' found \(self.locationSuggestions.count) results")
            }
        }
    }
    
    private func geocodeLocation(_ address: String) {
        isGeocoding = true
        
        // Use Mapbox Geocoding for better POI and international location support
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
                    print("Mapbox geocoding error: \(error.localizedDescription)")
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
                        
                        // Mapbox returns [longitude, latitude]
                        let longitude = coordinates[0]
                        let latitude = coordinates[1]
                        
                        self.selectedCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        self.isLocationSelected = true
                        self.showLocationSuggestions = false
                        self.locationSuggestions = []
                        
                        // Optionally update the location name with the full place name
                        if let placeName = firstFeature["place_name"] as? String {
                            // Prevent TextField onChange from clearing selection for programmatic update
                            self.suppressLocationOnChange = true
                            self.locationName = placeName
                        }
                    } else {
                        print("Failed to parse Mapbox geocoding response")
                        self.fallbackGeocode(address)
                    }
                } catch {
                    print("Mapbox geocoding JSON error: \(error.localizedDescription)")
                    self.fallbackGeocode(address)
                }
            }
        }.resume()
    }
    
    // Fallback to Apple's geocoder if Mapbox fails
    private func fallbackGeocode(_ address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Fallback geocoding error: \(error.localizedDescription)")
                    return
                }
                
                if let placemark = placemarks?.first,
                   let location = placemark.location {
                    self.selectedCoordinate = location.coordinate
                    self.isLocationSelected = true
                    self.showLocationSuggestions = false
                    self.locationSuggestions = []
                }
            }
        }
    }
    
    private func reverseGeocodeLocation() {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: selectedCoordinate.latitude, longitude: selectedCoordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    // Create a readable location name
                    var locationName = ""
                    
                    if let name = placemark.name {
                        locationName = name
                    } else if let thoroughfare = placemark.thoroughfare {
                        locationName = thoroughfare
                        if let locality = placemark.locality {
                            locationName += ", \(locality)"
                        }
                    } else if let locality = placemark.locality {
                        locationName = locality
                        if let country = placemark.country {
                            locationName += ", \(country)"
                        }
                    } else {
                        locationName = "Current Location"
                    }
                    
                    // Prevent TextField onChange from clearing selection for programmatic update
                    self.suppressLocationOnChange = true
                    self.locationName = locationName
                    // Keep mini map visible when name updates programmatically
                    self.isLocationSelected = true
                }
            }
        }
    }
}

// MARK: - Preview
struct EventEditView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleEvent = StudyEvent(
            title: "Sample Study Session",
            coordinate: CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816),
            time: Date(),
            endTime: Date().addingTimeInterval(3600),
            description: "A sample study session",
            invitedFriends: ["friend1", "friend2"],
            attendees: ["host"],
            isPublic: true,
            host: "host",
            hostIsCertified: false,
            eventType: .study,
            isAutoMatched: false,
            interestTags: ["programming", "study"]
        )
        
        EventEditView(event: sampleEvent, studyEvents: .constant([sampleEvent]))
            .environmentObject(UserAccountManager())
            .environmentObject(CalendarManager(accountManager: UserAccountManager()))
    }
}
