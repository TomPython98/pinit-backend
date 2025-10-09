import SwiftUI
import MapKit
import PhotosUI

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
                    TextField("Enter event title", text: $eventTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(Color.textPrimary)
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
                        TextField("Add tag", text: $newTag)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(Color.textPrimary)
                        
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
                // Current Location
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "location").foregroundColor(.brandPrimary)
                        Text("Location").font(.headline).foregroundColor(Color.textPrimary)
                    }
                    
                    Text("Latitude: \(String(format: "%.6f", selectedCoordinate.latitude))")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                    
                    Text("Longitude: \(String(format: "%.6f", selectedCoordinate.longitude))")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                    
                    Text("📍 Location editing will be available in a future update")
                        .font(.caption)
                        .foregroundColor(Color.textMuted)
                        .italic()
                        .padding(.top, 8)
                }
                
                // Invited Friends
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.2").foregroundColor(.brandPrimary)
                        Text("Invited Friends").font(.headline).foregroundColor(Color.textPrimary)
                    }
                    
                    TextField("Enter usernames separated by commas", text: $invitedFriends, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(Color.textPrimary)
                        .lineLimit(3...6)
                }
            }
            .padding()
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
        
        guard let url = URL(string: APIConfig.fullURL(for: "updateEvent")) else {
            alertMessage = "Invalid API URL"
            showAlert = true
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
                isLoading = false
                
                if let error = error {
                    alertMessage = "Network error: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    alertMessage = "Invalid response"
                    showAlert = true
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    // Update local event by creating a new one with updated values
                    if let index = studyEvents.firstIndex(where: { $0.id == event.id }) {
                        let oldEvent = studyEvents[index]
                        let updatedEvent = StudyEvent(
                            id: oldEvent.id,
                            title: eventTitle,
                            coordinate: selectedCoordinate,
                            time: eventDate,
                            endTime: eventEndDate,
                            description: eventDescription,
                            invitedFriends: invitedFriends.isEmpty ? [] : invitedFriends.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
                            attendees: oldEvent.attendees,
                            isPublic: isPublic,
                            host: oldEvent.host,
                            hostIsCertified: oldEvent.hostIsCertified,
                            eventType: selectedEventType,
                            isAutoMatched: enableAutoMatching,
                            interestTags: tags,
                            matchedUsers: oldEvent.matchedUsers
                        )
                        
                        studyEvents[index] = updatedEvent
                    }
                    
                    alertMessage = "Event updated successfully!"
                    showAlert = true
                } else {
                    if let data = data, let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMessage = errorData["error"] as? String {
                        alertMessage = errorMessage
                    } else {
                        alertMessage = "Failed to update event (Status: \(httpResponse.statusCode))"
                    }
                    showAlert = true
                }
            }
        }.resume()
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
