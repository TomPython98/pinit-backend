import SwiftUI
import MapKit
import Foundation

struct StudyEventCard: View {
    let event: StudyEvent
    let showAttendees: Bool
    var onTap: (() -> Void)? = nil
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 12) {
                // Event type & host info
                HStack(alignment: .center) {
                    // Event type pill
                    Text(event.eventType.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(eventTypeColor.opacity(0.15))
                        .foregroundColor(eventTypeColor)
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    // Host info with verified badge if applicable
                    HStack(spacing: 4) {
                        Text("Host: \(event.host)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if event.hostIsCertified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Event title
                Text(event.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Date & time
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Text("\(dateFormatter.string(from: event.time))")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                // Description if available
                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Show attendees if requested
                if showAttendees && !event.attendees.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Attendees: \(event.attendees.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Show first few attendees
                        if event.attendees.count > 0 {
                            Text(event.attendees.prefix(3).joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.top, 4)
                }
                
                // Tags if available
                if let tags = event.interestTags, !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tags.prefix(4), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Color based on event type
    private var eventTypeColor: Color {
        switch event.eventType {
        case .study:
            return .blue
        case .party:
            return .purple
        case .business:
            return .green
        case .cultural:
            return .orange
        case .academic:
            return .green
        case .networking:
            return .pink
        case .social:
            return .red
        case .language_exchange:
            return .teal
        case .other:
            return .orange
        }
    }
}

// Preview requires StudyEvent model - comment this out if model isn't available
#Preview {
    VStack {
        if let sampleEvent = createSampleEvent() {
            StudyEventCard(event: sampleEvent, showAttendees: true)
                .padding()
        } else {
            Text("Preview unavailable - StudyEvent model required")
                .padding()
        }
    }
    .background(Color.gray.opacity(0.1))
}

// Helper function to create a sample event for preview
func createSampleEvent() -> StudyEvent? {
    // Only attempt to create a sample event if the StudyEvent model exists
    guard NSClassFromString("StudyEvent") != nil else {
        return nil
    }
    
    return StudyEvent(
        id: UUID(),
        title: "Machine Learning Study Group",
        coordinate: CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816),
        time: Date(),
        endTime: Date().addingTimeInterval(3600 * 2),
        description: "Weekly study group for machine learning.",
        invitedFriends: ["john_doe", "jane_smith"],
        attendees: ["alex_jones", "sarah_williams", "mike_brown"],
        isPublic: true,
        host: "david_miller",
        hostIsCertified: true,
        eventType: .study,
        interestTags: ["Machine Learning", "AI", "Data Science"]
    )
} 