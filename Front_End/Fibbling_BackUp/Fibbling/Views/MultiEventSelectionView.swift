import SwiftUI
import CoreLocation

struct MultiEventSelectionView: View {
    @State private var events: [StudyEvent]
    let onEventSelected: (StudyEvent) -> Void
    @Environment(\.dismiss) private var dismiss
    
    init(events: [StudyEvent], onEventSelected: @escaping (StudyEvent) -> Void) {
        self._events = State(initialValue: events)
        self.onEventSelected = onEventSelected
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Multiple Events")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("\(events.count) events at this location")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                .onAppear {
                }
                
                // Events List
                if events.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("No events found")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Text("The events may have been removed or there was an error loading them.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(events, id: \.id) { event in
                                EventSelectionCard(
                                    event: event,
                                    onTap: {
                                        onEventSelected(event)
                                        dismiss()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .background(Color.white)
                }
                
                Spacer()
            }
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Select Event")
                        .foregroundColor(.black)
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
            }
        }
    }
}

struct EventSelectionCard: View {
    let event: StudyEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Event Type Icon
                Image(eventTypeImageName(event.eventType))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(eventTypeColor(event.eventType).opacity(0.1))
                    )
                
                // Event Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                    
                    Text(event.description ?? "No description available")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        // Host info
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.gray)
                                .font(.caption)
                            Text(event.host)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Event time
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.gray)
                                .font(.caption)
                            Text(formatEventTime(event.time))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatEventTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    private func eventTypeColor(_ eventType: EventType) -> Color {
        switch eventType {
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
    
    private func eventTypeImageName(_ eventType: EventType) -> String {
        switch eventType {
        case .study:
            return "Study"
        case .party:
            return "Party"
        case .business:
            return "Business"
        case .cultural:
            return "Cultural"
        case .academic:
            return "Academic"
        case .networking:
            return "Networking"
        case .social:
            return "Social"
        case .language_exchange:
            return "LanguageExchange"
        case .other:
            return "Other"
        }
    }
}

#Preview {
    MultiEventSelectionView(
        events: [
            StudyEvent(
                title: "Study Session",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                time: Date(),
                endTime: Date().addingTimeInterval(3600),
                description: "Group study for finals",
                isPublic: true,
                host: "john",
                hostIsCertified: false,
                eventType: .study
            ),
            StudyEvent(
                title: "Coffee Meetup",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                time: Date().addingTimeInterval(1800),
                endTime: Date().addingTimeInterval(5400),
                description: "Casual coffee chat",
                isPublic: true,
                host: "jane",
                hostIsCertified: true,
                eventType: .social
            )
        ],
        onEventSelected: { _ in }
    )
}
