import SwiftUI
import MapKit  // For CLLocationCoordinate2D

// Import custom models and managers
import Foundation

// UserReputationManager is in the same module, so we don't need a separate import
// But we do need to ensure it's accessible at compile time

// Define preview-only types to make the preview work
fileprivate enum PreviewEventType {
    case study, party, business, other
}

fileprivate struct PreviewEvent {
    let id = UUID()
    let title: String
    let coordinate: CLLocationCoordinate2D
    let time: Date
    let endTime: Date
    let description: String?
    let isPublic: Bool
    let host: String
    let eventType: PreviewEventType
}

struct RateUserView: View {
    // Use a protocol or typealias to handle the different event types
    // This represents the minimal interface we need from an event
    let eventId: UUID
    let eventTitle: String
    let username: String
    let targetUser: String
    let onComplete: (Bool) -> Void
    
    @EnvironmentObject var accountManager: UserAccountManager
    @State private var rating: Int = 5
    @State private var reference: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    @Environment(\.dismiss) private var dismiss
    
    // Constructor for production code
    init(event: /* StudyEvent */ Any, username: String, targetUser: String, onComplete: @escaping (Bool) -> Void) {
        // In production, use this initializer with the real StudyEvent type
        // self.eventId = event.id
        // self.eventTitle = event.title
        
        // For preview only
        if let previewEvent = event as? PreviewEvent {
            self.eventId = previewEvent.id
            self.eventTitle = previewEvent.title
        } else {
            // Just to make the compiler happy in preview
            self.eventId = UUID()
            self.eventTitle = "Unknown Event"
        }
        
        self.username = username
        self.targetUser = targetUser
        self.onComplete = onComplete
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .center, spacing: 15) {
                        Text("How was your experience with")
                            .font(.headline)
                        
                        Text(targetUser)
                            .font(.title2)
                            .fontWeight(.bold)
                            
                        Text("for event \"\(eventTitle)\"?")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                
                Section {
                    HStack {
                        Text("Rating")
                        Spacer()
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= rating ? "star.fill" : "star")
                                .foregroundColor(Color.brandPrimary)
                                .font(.title3)
                                .onTapGesture {
                                    rating = index
                                }
                                .accessibilityLabel("Rate \(index) star\(index == 1 ? "" : "s")")
                                .accessibilityAddTraits(index <= rating ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                Section(header: Text("Add a reference (optional)")) {
                    TextField("What did you like or dislike?", text: $reference, axis: .vertical)
                        .lineLimit(4...6)
                        .padding(.vertical, 5)
                        .accessibilityLabel("Reference text field")
                        .accessibilityHint("Optional feedback about your experience")
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(Color.textMuted)
                            .font(.footnote)
                    }
                }
                
                Section {
                    Button(action: submitRating) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Text("Submit Rating")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSubmitting)
                    .accessibilityLabel("Submit rating")
                    .accessibilityHint("Submit your \(rating) star rating for \(targetUser)")
                }
            }
            .navigationTitle("Rate Host")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
            }
            #else
            // Alternative for macOS
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
            }
            #endif
        }
    }
    
    private func submitRating() {
        isSubmitting = true
        errorMessage = nil
        
        let finalReference = reference.isEmpty ? nil : reference
        
        // Use APIConfig for consistent URL management
        let baseURLs = APIConfig.baseURLs
        
        // Create the rating data with field names matching the Django backend
        let ratingData: [String: Any] = [
            "from_username": username,
            "to_username": targetUser,
            "event_id": eventId.uuidString,
            "rating": rating,
            "reference": finalReference as Any
        ]
        
        // Try each URL sequentially
        tryNextURL(index: 0, baseURLs: baseURLs, ratingData: ratingData)
    }
    
    private func tryNextURL(index: Int, baseURLs: [String], ratingData: [String: Any]) {
        guard index < baseURLs.count else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to connect to any server"
                self.isSubmitting = false
            }
            return
        }
        
        let baseURL = baseURLs[index]
        guard let url = URL(string: "\(baseURL)/submit_user_rating/") else {
            // Try next URL if this one is invalid
            tryNextURL(index: index + 1, baseURLs: baseURLs, ratingData: ratingData)
            return
        }
        
        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // ✅ Add JWT authentication header
        accountManager.addAuthHeader(to: &request)
        
        // Serialize to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: ratingData)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Error preparing request: \(error.localizedDescription)"
                self.isSubmitting = false
            }
            return
        }
        
        // Make the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                // Try the next URL
                self.tryNextURL(index: index + 1, baseURLs: baseURLs, ratingData: ratingData)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                
                // If we got a successful response, return success
                if (200...299).contains(httpResponse.statusCode) {
                    DispatchQueue.main.async {
                        self.isSubmitting = false
                        self.onComplete(true)
                        self.dismiss()
                    }
                    return
                }
                
                // If we got a response but with an error status code
                if let data = data, let errorString = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.errorMessage = "Server error: \(errorString)"
                        self.isSubmitting = false
                    }
                    return
                }
            }
            
            // Try the next URL if this one failed
            self.tryNextURL(index: index + 1, baseURLs: baseURLs, ratingData: ratingData)
        }.resume()
    }
}

// Preview that works without requiring external types
#Preview {
    RateUserView(
        event: PreviewEvent(
            title: "Sample Study Event",
            coordinate: CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816),
            time: Date(),
            endTime: Date().addingTimeInterval(3600),
            description: "A sample event for preview",
            isPublic: true,
            host: "SampleHost",
            eventType: .study
        ),
        username: "CurrentUser",
        targetUser: "SampleHost",
        onComplete: { _ in }
    )
} 