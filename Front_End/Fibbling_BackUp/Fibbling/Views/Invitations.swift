import SwiftUI

// MARK: - Event Join Request Model
struct EventJoinRequest: Identifiable, Codable {
    let id: String
    let event: EventRequestInfo
    let status: String
    let message: String?
    let createdAt: String
    let processedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case event
        case status
        case message
        case createdAt = "created_at"
        case processedAt = "processed_at"
    }
}

struct EventRequestInfo: Codable {
    let id: String
    let title: String
    let host: String
    let time: String
    let eventType: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case host
        case time
        case eventType = "event_type"
    }
}

// MARK: - Invitation Model

/// Represents an invitation for a StudyEvent.
/// An invitation is pending if the current user is in the event's invitedFriends array,
/// but is not yet in the event's attendees and is not the host.
struct Invitation: Identifiable {
    let id: UUID
    let event: StudyEvent
    let currentUser: String
    let isAutoMatched: Bool
    
    var isPending: Bool {
        return event.invitedFriends.contains(currentUser) &&
               !event.attendees.contains(currentUser) &&
               event.host != currentUser
    }
}

// MARK: - InvitationsResponse

/// A wrapper to decode the backend response for invitations.
struct InvitationsResponse: Codable {
    let invitations: [StudyEvent]
}

// MARK: - Join Requests Response
struct JoinRequestsResponse: Codable {
    let success: Bool
    let requests: [EventJoinRequest]
    let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case success
        case requests
        case totalCount = "total_count"
    }
}

// MARK: - InvitationsView

struct InvitationsView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var calendarManager: CalendarManager
    @State private var invitations: [Invitation] = []
    @State private var joinRequests: [EventJoinRequest] = []
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedTab = 0 // 0 = Direct Invites, 1 = Potential Matches, 2 = Requests
    
    private var directInvitations: [Invitation] {
        return invitations.filter { !$0.isAutoMatched }
    }
    
    private var potentialMatches: [Invitation] {
        return invitations.filter { $0.isAutoMatched }
    }
    
    private var navigationTitle: String {
        switch selectedTab {
        case 0: return "Direct Invitations"
        case 1: return "Potential Matches"
        case 2: return "My Requests"
        default: return "Events"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Beautiful gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color.bgSurface, Color.bgCard.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Modern tab selector
                    modernTabSelector
                    
                    // Content area
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if selectedTab == 0 {
                                // Direct Invitations Tab
                                if directInvitations.isEmpty {
                                    emptyStateView(
                                        icon: "envelope.open",
                                        title: "No Direct Invitations",
                                        subtitle: "You don't have any pending invitations right now"
                                    )
                                } else {
                                    ForEach(directInvitations) { invitation in
                                        ModernInvitationCard(
                                            invitation: invitation,
                                            onAccept: { accept(invitation) },
                                            onDecline: { decline(invitation) }
                                        )
                                    }
                                }
                            } else if selectedTab == 1 {
                                // Potential Matches Tab
                                if potentialMatches.isEmpty {
                                    emptyStateView(
                                        icon: "sparkles",
                                        title: "No Potential Matches",
                                        subtitle: "We're working on finding events that match your interests"
                                    )
                                } else {
                                    ForEach(potentialMatches) { invitation in
                                        ModernPotentialMatchCard(
                                            invitation: invitation,
                                            onAccept: { accept(invitation) },
                                            onDecline: { decline(invitation) }
                                        )
                                    }
                                }
                            } else {
                                // My Requests Tab
                                if joinRequests.isEmpty {
                                    emptyStateView(
                                        icon: "paperplane",
                                        title: "No Join Requests",
                                        subtitle: "Your join requests will appear here"
                                    )
                                } else {
                                    ForEach(joinRequests) { request in
                                        ModernJoinRequestCard(request: request)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgCard, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: fetchInvitations) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color.textPrimary)
                    }
                    .disabled(isLoading)
                }
            }
            .overlay {
                if isLoading {
                    loadingOverlay
                }
            }
            .onAppear {
                fetchInvitations()
                fetchJoinRequests()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Invitation Update"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // MARK: - API Integration
    
    /// Fetches pending invitations for the current user from the backend.
    private func fetchInvitations() {
        guard let username = accountManager.currentUser,
              let url = URL(string: "https://pinit-backend-production.up.railway.app/api/get_invitations/\(username)/")
        else {
            return
        }
        
        isLoading = true
        
        var request = URLRequest(url: url)
        accountManager.addAuthHeader(to: &request)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { DispatchQueue.main.async { isLoading = false } }
            
            if let error = error {
                return
            }
            
            // Log HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
            }
            
            guard let data = data else {
                return
            }
            
            // Debug: Print raw JSON response
            
            do {
                let response = try JSONDecoder().decode(InvitationsResponse.self, from: data)
                
                // Debug: Print decoded invitations
                
                // Map each returned event to an Invitation object.
                let invitationObjects = response.invitations.map { event in
                    // Check if this is an auto-matched invitation (potential match)
                    let isAutoMatched = event.isAutoMatched ?? false
                    
                    return Invitation(
                        id: event.id, 
                        event: event,
                        currentUser: accountManager.currentUser ?? "",
                        isAutoMatched: isAutoMatched
                    )
                }
                
                DispatchQueue.main.async {
                    self.invitations = invitationObjects
                }
            } catch {
            }
        }.resume()
    }
    
    /// Accepts an invitation by calling the RSVP endpoint.
    private func accept(_ invitation: Invitation) {
        guard let username = accountManager.currentUser,
              let url = URL(string: "\(APIConfig.primaryBaseURL)/rsvp_study_event/")
        else { return }
        
        isLoading = true
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        accountManager.addAuthHeader(to: &request)
        
        let body: [String: Any] = [
            "event_id": invitation.event.id.uuidString
        ]
        
        // Debug: Print request body
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Capture HTTP status for debugging
            if let httpResponse = response as? HTTPURLResponse {
            }
            
            // Print raw response for debugging
            if let data = data, let responseStr = String(data: data, encoding: .utf8) {
            }
            
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    alertMessage = "Failed to accept invitation: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                // Create a copy of the event to avoid struct mutation issues
                let event = invitation.event
                
                // Create a new attendees array with the current user added
                var newAttendees = event.attendees
                if !newAttendees.contains(username) {
                    newAttendees.append(username)
                }
                
                // Create a new event with the updated attendees
                let updatedEvent = StudyEvent(
                    id: event.id,
                    title: event.title,
                    coordinate: event.coordinate,
                    time: event.time,
                    endTime: event.endTime,
                    description: event.description,
                    invitedFriends: event.invitedFriends,
                    attendees: newAttendees,
                    isPublic: event.isPublic,
                    host: event.host,
                    hostIsCertified: event.hostIsCertified,
                    eventType: event.eventType
                )
                
                
                // Add the event to CalendarManager and force a refresh
                self.calendarManager.addEvent(updatedEvent)
                
                // Refresh invitations & calendar data
                fetchInvitations()
                
                // self.calendarManager.fetchEvents() // REMOVED - WebSocket will handle updates
                
                // Show success message
                alertMessage = "You've accepted the invitation to \(updatedEvent.title)"
                showAlert = true
            }
        }.resume()
    }
    
    /// Declines an invitation by calling the appropriate backend endpoint.
    private func decline(_ invitation: Invitation) {
        guard let username = accountManager.currentUser,
              let url = URL(string: "\(APIConfig.primaryBaseURL)/decline_invitation/")
        else { return }
        
        isLoading = true
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        accountManager.addAuthHeader(to: &request)
        
        let body: [String: Any] = [
            "event_id": invitation.event.id.uuidString
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    alertMessage = "Failed to decline invitation: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                // Remove the event from calendar manager if it exists there
                self.calendarManager.removeEvent(withID: invitation.event.id)
                
                // Refresh invitations
                fetchInvitations()
                
                // Show success message
                alertMessage = "You've declined the invitation to \(invitation.event.title)"
                showAlert = true
            }
        }.resume()
    }
    
    // MARK: - Fetch Join Requests
    private func fetchJoinRequests() {
        guard let username = accountManager.currentUser else { return }
        
        isLoading = true
        
        guard let url = URL(string: "\(APIConfig.primaryBaseURL)/get_user_join_requests/\(username)/") else {
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        accountManager.addAuthHeader(to: &request)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("❌ Join requests fetch error: \(error)")
                    return
                }
                
                if let data = data {
                    do {
                        let response = try JSONDecoder().decode(JoinRequestsResponse.self, from: data)
                        self.joinRequests = response.requests
                        print("✅ Join requests loaded: \(response.requests.count) requests")
                    } catch {
                        print("❌ Join requests JSON decode error: \(error)")
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print("Raw response: \(jsonString)")
                        }
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Modern UI Components
    
    private var modernTabSelector: some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tabTitle(for: index))
                            .font(.system(size: 16, weight: selectedTab == index ? .semibold : .medium))
                            .foregroundColor(selectedTab == index ? Color.textPrimary : Color.textSecondary)
                        
                        Rectangle()
                            .fill(selectedTab == index ? Color.brandPrimary : Color.clear)
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.bgCard)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Direct Invites"
        case 1: return "Potential Matches"
        case 2: return "My Requests"
        default: return ""
        }
    }
    
    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60, weight: .light))
                .foregroundColor(Color.textMuted)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(Color.textPrimary)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(Color.bgCard)
        .cornerRadius(16)
        .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.brandPrimary))
                    .scaleEffect(1.2)
                
                Text("Loading Invitations...")
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
            }
            .padding(24)
            .background(Color.bgCard)
            .cornerRadius(16)
            .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Modern Invitation Cards

struct ModernInvitationCard: View {
    let invitation: Invitation
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with event type icon
            HStack(spacing: 12) {
                // Event type icon
                Image(systemName: eventTypeIcon)
                    .font(.title2)
                    .foregroundColor(eventTypeColor)
                    .frame(width: 32, height: 32)
                    .background(eventTypeColor.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(invitation.event.title)
                        .font(.headline.bold())
                        .foregroundColor(Color.textPrimary)
                        .lineLimit(2)
                    
                    Text("Hosted by \(invitation.event.host)")
                        .font(.subheadline)
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                // Time badge
                VStack(spacing: 2) {
                    Text(formatDate(invitation.event.time))
                        .font(.caption.bold())
                        .foregroundColor(Color.textPrimary)
                    Text(formatTime(invitation.event.time))
                        .font(.caption2)
                        .foregroundColor(Color.textSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.bgSecondary)
                .cornerRadius(8)
            }
            
            // Description
            if let description = invitation.event.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.brandPrimary.opacity(0.05))
                    .cornerRadius(8)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onAccept) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Accept")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.brandPrimary)
                    .cornerRadius(10)
                }
                
                Button(action: onDecline) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Decline")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.bgSecondary)
                    .cornerRadius(10)
                }
            }
        }
        .padding(20)
        .background(Color.bgCard)
        .cornerRadius(16)
        .shadow(color: Color.cardShadow, radius: 6, x: 0, y: 3)
    }
    
    private var eventTypeIcon: String {
        switch invitation.event.eventType {
        case .study: return "book.fill"
        case .social: return "person.3.fill"
        case .business: return "briefcase.fill"
        case .cultural: return "theatermasks.fill"
        case .party: return "party.popper.fill"
        case .language_exchange: return "globe"
        case .academic: return "graduationcap.fill"
        case .networking: return "network"
        case .other: return "star.fill"
        }
    }
    
    private var eventTypeColor: Color {
        switch invitation.event.eventType {
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct ModernPotentialMatchCard: View {
    let invitation: Invitation
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with auto-match badge
            HStack(spacing: 12) {
                // Sparkles icon for auto-match
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.yellow)
                    .frame(width: 32, height: 32)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(invitation.event.title)
                        .font(.headline.bold())
                        .foregroundColor(Color.textPrimary)
                        .lineLimit(2)
                    
                    Text("Hosted by \(invitation.event.host)")
                        .font(.subheadline)
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                // Auto-match badge
                Text("Auto-Matched")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
            }
            
            // Description
            if let description = invitation.event.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.brandPrimary.opacity(0.05))
                    .cornerRadius(8)
            }
            
            // Event details
            HStack(spacing: 16) {
                // Date & Time
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(Color.textSecondary)
                    Text(formatDate(invitation.event.time))
                        .font(.subheadline)
                        .foregroundColor(Color.textPrimary)
                }
                
                // Event type
                HStack(spacing: 6) {
                    Image(systemName: "tag")
                        .foregroundColor(Color.textSecondary)
                    Text(invitation.event.eventType.displayName)
                        .font(.subheadline)
                        .foregroundColor(Color.textPrimary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.bgSecondary)
            .cornerRadius(8)
            
            // Match explanation
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                Text("This event matches your interests!")
                    .font(.subheadline)
                    .foregroundColor(Color.textSecondary)
                    .italic()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.pink.opacity(0.05))
            .cornerRadius(8)
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onAccept) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                        Text("Join Event")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                
                Button(action: onDecline) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Not Interested")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.bgSecondary)
                    .cornerRadius(10)
                }
            }
        }
        .padding(20)
        .background(Color.bgCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.brandPrimary.opacity(0.3), Color.brandPrimary.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.cardShadow, radius: 6, x: 0, y: 3)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Modern Join Request Card
struct ModernJoinRequestCard: View {
    let request: EventJoinRequest
    
    private var statusColor: Color {
        switch request.status {
        case "pending": return .orange
        case "approved": return .green
        case "rejected": return .red
        default: return .gray
        }
    }
    
    private var statusIcon: String {
        switch request.status {
        case "pending": return "clock"
        case "approved": return "checkmark.circle.fill"
        case "rejected": return "xmark.circle.fill"
        default: return "questionmark.circle"
        }
    }
    
    private var statusText: String {
        switch request.status {
        case "pending": return "Pending"
        case "approved": return "Approved"
        case "rejected": return "Rejected"
        default: return "Unknown"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with event info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.event.title)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Host: \(request.event.host)")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 6) {
                    Image(systemName: statusIcon)
                        .font(.caption)
                        .foregroundColor(statusColor)
                    
                    Text(statusText)
                        .font(.caption.weight(.medium))
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(statusColor.opacity(0.1))
                )
            }
            
            // Event details
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.textMuted)
                    
                    Text(formatEventTime(request.event.time))
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "tag")
                        .font(.caption)
                        .foregroundColor(.textMuted)
                    
                    Text(request.event.eventType.capitalized)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
            }
            
            // Message if available
            if let message = request.message, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.bgSecondary.opacity(0.5))
                    )
            }
            
            // Request date
            Text("Requested: \(formatRequestDate(request.createdAt))")
                .font(.caption)
                .foregroundColor(.textMuted)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
        )
    }
    
    private func formatEventTime(_ timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        if let date = formatter.date(from: timeString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, h:mm a"
            return displayFormatter.string(from: date)
        }
        
        return timeString
    }
    
    private func formatRequestDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, h:mm a"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

// MARK: - Preview

struct InvitationsView_Previews: PreviewProvider {
    static var previews: some View {
        InvitationsView()
            .environmentObject(UserAccountManager())
            .environmentObject(CalendarManager(accountManager: UserAccountManager()))
    }
}
