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
    @State private var locationSuggestions: [GooglePlacesService.LocationSuggestion] = []
    @State private var showLocationSuggestions = false
    @State private var isGeocoding = false
    @State private var isLocationSelected = true // Start as true since we have existing location
    @State private var searchTask: Task<Void, Never>? // For debouncing location search
    @State private var suppressLocationOnChange = false // prevent TextField onChange from clearing selection when set programmatically
    @State private var selectedLocation: GooglePlacesService.LocationSuggestion?
    @State private var isSearchingSuggestions = false
    
    // Google Places Service
    private let googlePlacesService = GooglePlacesService.shared
    
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
                    .background(Color.bgCard)
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

                    HStack {
                        Text("\(maxParticipants) people")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.brandPrimary)

                        Spacer()

                        PinItStepper(value: $maxParticipants, range: 2...50, isDarkMode: false)
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
                                        // Safety check for valid values
                                        guard !oldValue.isEmpty, !newValue.isEmpty else { return }
                                        
                                        // If the change was triggered programmatically, do not reset selection
                                        if suppressLocationOnChange {
                                            suppressLocationOnChange = false
                                            return
                                        }
                                        
                                        // User is typing - reset selection and show suggestions
                                        if oldValue != newValue {
                                            isLocationSelected = false
                                            selectedLocation = nil
                                            
                                            // Cancel previous search task
                                            searchTask?.cancel()
                                            
                                            // Only show suggestions if query is long enough
                                            if newValue.count >= 2 {
                                                // Debounce the search
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
                                    .frame(maxHeight: 400)
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
                                            }
                                        }
                                    )
                                    .padding(.top, 12)
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
                    .background(Color.bgCard)
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
                        name: Notification.Name("FocusEventOnMap"),
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
        // Safety checks
        guard !query.isEmpty,
              query.count >= 2,
              query.count <= 100 else {
            locationSuggestions = []
            showLocationSuggestions = false
            return
        }
        
        isSearchingSuggestions = true
        
        // Use Google Places API for location search
        Task {
            do {
                let results = try await googlePlacesService.searchLocations(query: query, near: selectedCoordinate)
                
                // Check if task was cancelled before updating UI
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    
                    self.isSearchingSuggestions = false
                    self.locationSuggestions = results
                    self.showLocationSuggestions = !results.isEmpty
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
