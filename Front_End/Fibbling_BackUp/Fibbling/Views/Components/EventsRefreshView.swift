import SwiftUI

/// A view that displays the last refresh time and a refresh button
struct EventsRefreshView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @State private var isRefreshing = false
    @State private var refreshTimerTick = 0
    @State private var lastRefreshTime = Date()
    
    // Add debouncing to prevent rapid refresh calls
    @State private var refreshDebounceTimer: Timer?
    
    var body: some View {
        HStack {
            Image(systemName: isRefreshing ? "arrow.clockwise.circle.fill" : "arrow.clockwise.circle")
                .font(.title2)
                .foregroundColor(isRefreshing ? Color.brandPrimary : Color.textSecondary)
                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isRefreshing ? "Refreshing..." : "Refresh Events")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isRefreshing ? Color.brandPrimary : Color.textPrimary)
                
                Text("Last updated: \(timeAgoString(from: lastRefreshTime))")
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
            
            if isRefreshing {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Debounce refresh calls to prevent rapid tapping
            refreshDebounceTimer?.invalidate()
            refreshDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                withAnimation {
                    isRefreshing = true
                }
                refreshEvents()
            }
        }
        .onChange(of: calendarManager.isLoading) { oldValue, newValue in
            // When calendar manager finishes loading, we should finish our refresh
            if oldValue == true && newValue == false {
                withAnimation {
                    isRefreshing = false
                }
                lastRefreshTime = Date()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.bgCard)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.divider.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.cardShadow.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("EventRSVPUpdated"))) { _ in
            // Debounce RSVP-triggered refreshes
            refreshDebounceTimer?.invalidate()
            refreshDebounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                refreshEvents(forceUpdate: true)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("EventUpdatedFromWebSocket"))) { _ in
            
            // Update the last refresh time to now, but don't reload events (they're already updated)
            self.refreshTimerTick += 1
            lastRefreshTime = Date()
        }
        .onAppear {
            // WebSocket handles real-time updates - only refresh if manually requested
            // Remove automatic refresh on appear to reduce API calls
        }
        // This id modifier will force the view to update when the timer ticks
        .id("refreshView-\(refreshTimerTick)")
    }
    
    private func refreshEvents(forceUpdate: Bool = false) {
        // Prevent multiple simultaneous refresh calls
        if calendarManager.isLoading && !forceUpdate {
            return
        }
        
        calendarManager.fetchEvents()
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

/// Preview provider for EventsRefreshView
struct EventsRefreshView_Previews: PreviewProvider {
    static var previews: some View {
        EventsRefreshView()
            .environmentObject(CalendarManager(accountManager: UserAccountManager()))
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.bgSurface)
    }
} 