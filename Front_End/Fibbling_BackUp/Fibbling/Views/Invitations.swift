import SwiftUI

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

// MARK: - InvitationsView

struct InvitationsView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @EnvironmentObject var calendarManager: CalendarManager
    @State private var invitations: [Invitation] = []
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedTab = 0 // 0 = Direct Invites, 1 = Potential Matches
    
    private var directInvitations: [Invitation] {
        return invitations.filter { !$0.isAutoMatched }
    }
    
    private var potentialMatches: [Invitation] {
        return invitations.filter { $0.isAutoMatched }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Tab selector
                Picker("Invitation Type", selection: $selectedTab) {
                    Text("Direct Invites").tag(0)
                    Text("Potential Matches").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                List {
                    if selectedTab == 0 {
                        // Direct Invitations Tab
                        if directInvitations.isEmpty {
                            Text("No direct invitations")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(directInvitations) { invitation in
                                InvitationRow(invitation: invitation,
                                            onAccept: { accept(invitation) },
                                            onDecline: { decline(invitation) })
                            }
                        }
                    } else {
                        // Potential Matches Tab
                        if potentialMatches.isEmpty {
                            Text("No potential matches")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(potentialMatches) { invitation in
                                PotentialMatchRow(invitation: invitation,
                                                onAccept: { accept(invitation) },
                                                onDecline: { decline(invitation) })
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(selectedTab == 0 ? "Direct Invitations" : "Potential Matches")
            .overlay {
                if isLoading {
                    ProgressView("Loading Invitations...")
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .onAppear(perform: fetchInvitations)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Invitation Update"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // MARK: - API Integration
    
    /// Fetches pending invitations for the current user from the backend.
    private func fetchInvitations() {
        guard let username = accountManager.currentUser,
              let url = URL(string: "http://127.0.0.1:8000/api/get_invitations/\(username)/")
        else {
            print("❌ [InvitationsView] Invalid username or URL")
            return
        }
        
        print("🔍 [InvitationsView] Fetching invitations for user: \(username)")
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { DispatchQueue.main.async { isLoading = false } }
            
            if let error = error {
                print("❌ [InvitationsView] Error fetching invitations: \(error.localizedDescription)")
                return
            }
            
            // Log HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [InvitationsView] HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ [InvitationsView] No data received")
                return
            }
            
            // Debug: Print raw JSON response
            print("📦 [InvitationsView] Raw response: \(String(data: data, encoding: .utf8) ?? "invalid data")")
            
            do {
                let response = try JSONDecoder().decode(InvitationsResponse.self, from: data)
                
                // Debug: Print decoded invitations
                print("✅ [InvitationsView] Decoded \(response.invitations.count) invitation(s)")
                
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
                    print("📊 [InvitationsView] \(self.invitations.count) pending invitation(s) found")
                    print("   👤 Direct invitations: \(self.directInvitations.count)")
                    print("   🔄 Potential matches: \(self.potentialMatches.count)")
                }
            } catch {
                print("❌ [InvitationsView] Decoding error: \(error)")
            }
        }.resume()
    }
    
    /// Accepts an invitation by calling the RSVP endpoint.
    private func accept(_ invitation: Invitation) {
        guard let username = accountManager.currentUser,
              let url = URL(string: "http://127.0.0.1:8000/api/rsvp_study_event/")
        else { return }
        
        print("🔍 [InvitationsView] Accepting invitation for event: \(invitation.event.title) (ID: \(invitation.event.id))")
        isLoading = true
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body: [String: Any] = [
            "username": username,
            "event_id": invitation.event.id.uuidString
        ]
        
        // Debug: Print request body
        print("📤 [InvitationsView] RSVP request body: \(body)")
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Capture HTTP status for debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [InvitationsView] RSVP HTTP Status: \(httpResponse.statusCode)")
            }
            
            // Print raw response for debugging
            if let data = data, let responseStr = String(data: data, encoding: .utf8) {
                print("📦 [InvitationsView] RSVP response data: \(responseStr)")
            }
            
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("❌ [InvitationsView] RSVP error: \(error.localizedDescription)")
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
                
                print("✅ [InvitationsView] Created updated event with user in attendees")
                print("   👥 Updated attendees: \(updatedEvent.attendees)")
                
                // Add the event to CalendarManager and force a refresh
                self.calendarManager.addEvent(updatedEvent)
                print("📆 [InvitationsView] Added event to CalendarManager")
                
                // Refresh invitations & calendar data
                fetchInvitations()
                print("🔄 [InvitationsView] Fetching fresh invitations")
                
                // self.calendarManager.fetchEvents() // REMOVED - WebSocket will handle updates
                print("🔄 [InvitationsView] Relying on WebSocket for calendar updates")
                
                // Show success message
                alertMessage = "You've accepted the invitation to \(updatedEvent.title)"
                showAlert = true
            }
        }.resume()
    }
    
    /// Declines an invitation by calling the appropriate backend endpoint.
    private func decline(_ invitation: Invitation) {
        guard let username = accountManager.currentUser,
              let url = URL(string: "http://127.0.0.1:8000/api/decline_invitation/")
        else { return }
        
        print("🔍 [InvitationsView] Declining invitation for event: \(invitation.event.title) (ID: \(invitation.event.id))")
        isLoading = true
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body: [String: Any] = [
            "username": username,
            "event_id": invitation.event.id.uuidString
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("❌ [InvitationsView] Decline error: \(error.localizedDescription)")
                    alertMessage = "Failed to decline invitation: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                // Remove the event from calendar manager if it exists there
                self.calendarManager.removeEvent(withID: invitation.event.id)
                print("🗑 [InvitationsView] Removed event from CalendarManager")
                
                // Refresh invitations
                fetchInvitations()
                
                // Show success message
                alertMessage = "You've declined the invitation to \(invitation.event.title)"
                showAlert = true
            }
        }.resume()
    }
}

// MARK: - InvitationRow

struct InvitationRow: View {
    let invitation: Invitation
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(invitation.event.title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Hosted by \(invitation.event.host)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(invitation.event.time, style: .date)
                .font(.caption)
                .foregroundColor(.gray)
            
            if let message = invitation.event.description, !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(4)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(5)
            }
            
            HStack {
                Button("Accept", action: onAccept)
                    .buttonStyle(.borderedProminent)
                Button("Decline", action: onDecline)
                    .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - PotentialMatchRow

struct PotentialMatchRow: View {
    let invitation: Invitation
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(invitation.event.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Auto-match badge
                Text("Auto-Matched")
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
            }
            
            Text("Hosted by \(invitation.event.host)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(invitation.event.time, style: .date)
                .font(.caption)
                .foregroundColor(.gray)
            
            if let message = invitation.event.description, !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(4)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(5)
            }
            
            // Show the event type
            Text("Event type: \(invitation.event.eventType.displayName)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Divider
            Divider()
                .padding(.vertical, 4)
            
            Text("This event matches your interests")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
            
            HStack {
                Button("Accept", action: onAccept)
                    .buttonStyle(.borderedProminent)
                Button("Decline", action: onDecline)
                    .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 10)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
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
