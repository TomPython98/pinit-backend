import SwiftUI
import MapKit

// MARK: - Custom Calendar View
struct CustomCalendarView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @State private var displayedMonth: Date = Date()
    @State private var selectedDayEvents: [StudyEvent] = []
    @State private var showDayEventsSheet: Bool = false
    @State private var selectedDate: Date = Date()
    @State private var calendarViewMode: CalendarViewMode = .month
    @State private var showEventCreation = false
    
    // Add view mode filtering (same as map)
    @State private var eventViewMode: EventViewMode = .all  // Default to "All Events" to show all available events
    @State private var showViewModeSelector: Bool = false
    
    private let todayDate = Date()
    private let calendar = Calendar.current
    
    enum CalendarViewMode {
        case month, week
    }
    
    // Add EventViewMode enum (same as map)
    enum EventViewMode: CaseIterable {
        case all, autoMatched, rsvpedOnly
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Refresh indicator at the top of the content
                        EventsRefreshView()
                            .padding(.top, 8)
                        
                        if calendarViewMode == .month {
                            monthView
                        } else {
                            weekView
                        }
                        todayEventsSection
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.bgSurface)
            .sheet(isPresented: $showDayEventsSheet) {
                DayEventsView(events: selectedDayEvents, date: selectedDate)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showEventCreation) {
                EventCreationView(
                    coordinate: CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816), // Default to Buenos Aires
                    onSave: { newEvent in
                        // Add the event to calendar manager
                        calendarManager.addEvent(newEvent)
                        showEventCreation = false
                    }
                )
            }
            // Add confirmation dialog for view mode selection (same as map)
            .confirmationDialog(
                "Select View Mode",
                isPresented: $showViewModeSelector,
                titleVisibility: .visible
            ) {
                Button("All Events") {
                    eventViewMode = .all
                }
                
                Button(autoMatchCount > 0 ? "Auto-Matched (\(autoMatchCount))" : "Auto-Matched") {
                    eventViewMode = .autoMatched
                }
                
                Button(rsvpCount > 0 ? "My Events (\(rsvpCount))" : "My Events") {
                    eventViewMode = .rsvpedOnly
                }
                
                Button("Cancel", role: .cancel) { }
            }
        }
        .onAppear {
            // // Fetch events (including RSVP data) when this view appears. - REMOVED
            // calendarManager.fetchEvents() // REMOVED
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("EventRSVPStatusChanged"))) { notification in
            if let eventID = notification.userInfo?["eventID"] as? UUID {

                // Force UI update by refreshing selectedDayEvents if the updated event is part of the current selection
                if let index = selectedDayEvents.firstIndex(where: { $0.id == eventID }) {
                    selectedDayEvents = calendarManager.events.filter { calendar.isDate($0.time, inSameDayAs: selectedDate) }
                }

                // // Regardless of specific event being in view, refresh all events - REMOVED
                // DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                //     calendarManager.fetchEvents() // REMOVED
                // }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("EventRSVPUpdated"))) { notification in
            if let eventID = notification.userInfo?["eventID"] as? UUID {
            }
            // // Regardless of specific event, refresh all events - REMOVED
            // DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            //     calendarManager.fetchEvents() // REMOVED
            // }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("EventUpdatedFromWebSocket"))) { notification in
            if let eventID = notification.userInfo?["eventID"] as? UUID {
                
                // Force UI update by refreshing selectedDayEvents if the updated event is part of the current selection
                if let index = selectedDayEvents.firstIndex(where: { $0.id == eventID }) {
                    
                    // If the event is in the currently displayed day events, refresh the view
                    // by getting the updated events for the selected date
                    selectedDayEvents = calendarManager.events.filter { calendar.isDate($0.time, inSameDayAs: selectedDate) }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Month/Year and Navigation
            HStack {
                Button(action: {
                    withAnimation {
                        displayedMonth = previousMonth()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                Text(monthYearString(from: displayedMonth))
                    .font(.title2.bold())
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        displayedMonth = nextMonth()
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            // Today Button
            HStack {
                Spacer()
                Button("Today") {
                    withAnimation {
                        displayedMonth = Date()
                        selectedDate = Date()
                    }
                }
                .foregroundColor(.accentColor)
                .font(.subheadline.bold())
                Spacer()
            }
            .padding(.horizontal)
            
            // View Mode Selector and Calendar Mode Toggle
            HStack {
                // View Mode Selector Button (same styling as map)
                Button(action: {
                    withAnimation(.spring()) {
                        showViewModeSelector = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: viewModeIcon)
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(viewModeLabel)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .foregroundColor(.white)
                    .background(
                        Capsule()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [viewModeColor, viewModeColor.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                    )
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                }
                
                Spacer()
                
                // Calendar Mode Toggle
                Picker("Calendar View", selection: $calendarViewMode) {
                    Text("Month").tag(CalendarViewMode.month)
                    Text("Week").tag(CalendarViewMode.week)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
            .padding(.horizontal)
            
            // Weekday Header
            weekdayHeader
        }
        .padding(.top)
        .background(Color.bgCard)
    }
    
    // MARK: - Helper computed properties for view mode button styling (same as map)
    private var viewModeIcon: String {
        switch eventViewMode {
        case .all: return "list.bullet"
        case .autoMatched: return "sparkles"
        case .rsvpedOnly: return "checkmark.circle"
        }
    }
    
    private var viewModeLabel: String {
        switch eventViewMode {
        case .all: return "All Events"
        case .autoMatched: return "Auto-Matched"
        case .rsvpedOnly: return "My Events"
        }
    }
    
    private var viewModeColor: Color {
        switch eventViewMode {
        case .all: return Color(red: 0.4, green: 0.4, blue: 0.4)
        case .autoMatched: return Color(red: 0.2, green: 0.5, blue: 0.9)
        case .rsvpedOnly: return Color(red: 0.2, green: 0.7, blue: 0.3)
        }
    }
    
    // MARK: - Computed properties for counts
    private var autoMatchCount: Int {
        let username = calendarManager.username
        return calendarManager.events.filter { event in
            guard let isAutoMatched = event.isAutoMatched, isAutoMatched else { return false }
            return !event.attendees.contains(username)
        }.count
    }
    
    private var rsvpCount: Int {
        let username = calendarManager.username
        return calendarManager.events.filter { event in
            return event.attendees.contains(username) || event.host == username
        }.count
    }
    
    // MARK: - Weekday Header
    private var weekdayHeader: some View {
        HStack {
            ForEach(Calendar.current.veryShortWeekdaySymbols, id: \.self) { day in
                Text(day)
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color.textSecondary)
                    .padding(.vertical, 8)
            }
        }
        .background(Color.bgCard)
    }
    
    // MARK: - Month View
    private var monthView: some View {
        let days = generateDays(for: displayedMonth)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(days, id: \.self) { date in
                DayCell(
                    date: date,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    isToday: calendar.isDate(date, inSameDayAs: todayDate),
                    isSameMonth: isSameMonth(date: date, as: displayedMonth),
                    events: eventsFor(date: date) ?? [],
                    eventSpans: getEventSpans(for: date)
                )
                .onTapGesture {
                    selectedDate = date
                    let dayEvents = eventsFor(date: date) ?? []
                    let spans = getEventSpans(for: date)
                    if !dayEvents.isEmpty || !spans.isEmpty {
                        // Create a set of event IDs to avoid duplicates
                        var uniqueEventIds = Set<UUID>()
                        var uniqueEvents: [StudyEvent] = []
                        
                        // Add regular day events first
                        for event in dayEvents {
                            uniqueEventIds.insert(event.id)
                            uniqueEvents.append(event)
                        }
                        
                        // Add span events only if they're not already included
                        for span in spans {
                            if !uniqueEventIds.contains(span.event.id) {
                                uniqueEventIds.insert(span.event.id)
                                uniqueEvents.append(span.event)
                            }
                        }
                        
                        selectedDayEvents = uniqueEvents
                        showDayEventsSheet = true
                    }
                }
            }
        }
        .padding(.top)
    }
    
    // MARK: - Week View
    private var weekView: some View {
        let weekDays = generateWeekDays(for: selectedDate)
        return VStack(spacing: 8) {
            ForEach(weekDays, id: \.self) { date in
                WeekDayRow(
                    date: date,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    isToday: calendar.isDate(date, inSameDayAs: todayDate),
                    events: eventsFor(date: date) ?? []
                )
                .onTapGesture {
                    selectedDate = date
                    let dayEvents = eventsFor(date: date) ?? []
                    let spans = getEventSpans(for: date)
                    if !dayEvents.isEmpty || !spans.isEmpty {
                        // Create a set of event IDs to avoid duplicates
                        var uniqueEventIds = Set<UUID>()
                        var uniqueEvents: [StudyEvent] = []
                        
                        // Add regular day events first
                        for event in dayEvents {
                            uniqueEventIds.insert(event.id)
                            uniqueEvents.append(event)
                        }
                        
                        // Add span events only if they're not already included
                        for span in spans {
                            if !uniqueEventIds.contains(span.event.id) {
                                uniqueEventIds.insert(span.event.id)
                                uniqueEvents.append(span.event)
                            }
                        }
                        
                        selectedDayEvents = uniqueEvents
                        showDayEventsSheet = true
                    }
                }
            }
        }
    }
    
    // MARK: - Today's Events Section
    private var todayEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(sectionTitle)
                    .font(.title3.bold())
                    .foregroundColor(Color.textPrimary)
                Spacer()
                Button(action: { showEventCreation = true }) {
                    Label("Add Event", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.bottom, 8)
            
            if !displayedEvents.isEmpty {
                SimpleEventsList(events: displayedEvents)
                    .transition(.scale.combined(with: .opacity))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.7))
                    Text(emptyStateMessage)
                        .font(.subheadline)
                        .foregroundColor(Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.bgCard)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Computed Properties for Events Section
    private var sectionTitle: String {
        switch eventViewMode {
        case .all:
            let totalCount = calendarManager.events.count
            return "All Events (\(totalCount))"
        case .autoMatched:
            let autoCount = calendarManager.events.filter { event in
                guard let isAutoMatched = event.isAutoMatched, isAutoMatched else { return false }
                return !event.attendees.contains(calendarManager.username)
            }.count
            return "Auto-Matched (\(autoCount))"
        case .rsvpedOnly:
            let rsvpCount = calendarManager.events.filter { event in
                event.attendees.contains(calendarManager.username) || event.host == calendarManager.username
            }.count
            return "My Events (\(rsvpCount))"
        }
    }
    
    private var displayedEvents: [StudyEvent] {
        switch eventViewMode {
        case .all:
            return calendarManager.events
        case .autoMatched:
            return calendarManager.events.filter { event in
                guard let isAutoMatched = event.isAutoMatched, isAutoMatched else { return false }
                return !event.attendees.contains(calendarManager.username)
            }
        case .rsvpedOnly:
            return calendarManager.events.filter { event in
                event.attendees.contains(calendarManager.username) || event.host == calendarManager.username
            }
        }
    }
    
    private var emptyStateMessage: String {
        switch eventViewMode {
        case .all:
            return "No events available"
        case .autoMatched:
            return "No auto-matched events"
        case .rsvpedOnly:
            return "No events today"
        }
    }
    
    // MARK: - Helper Functions
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func generateDays(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let dateComponents = DateComponents(year: year, month: month)
        let firstDayOfMonth = calendar.date(from: dateComponents)!
        let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!
        let numDays = range.count
        let firstDayWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let offsetDays = firstDayWeekday - 1
        let totalDays = numDays + offsetDays
        
        return (0..<42).map { day -> Date in
            if day < offsetDays {
                let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstDayOfMonth)!
                let previousMonthLength = calendar.range(of: .day, in: .month, for: previousMonth)!.count
                return calendar.date(byAdding: .day, value: previousMonthLength - offsetDays + day, to: previousMonth)!
            } else if day >= totalDays {
                let daysIntoNextMonth = day - totalDays
                return calendar.date(byAdding: .day, value: daysIntoNextMonth, to: calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth)!)!
            } else {
                return calendar.date(byAdding: .day, value: day - offsetDays, to: firstDayOfMonth)!
            }
        }
    }
    
    private func generateWeekDays(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let dayOfWeek = calendar.component(.weekday, from: today)
        let weekdays = calendar.range(of: .weekday, in: .weekOfYear, for: today)!
        return (weekdays.lowerBound ..< weekdays.upperBound)
            .compactMap { calendar.date(byAdding: .day, value: $0 - dayOfWeek, to: today) }
    }
    
    private func isSameMonth(date: Date, as otherDate: Date) -> Bool {
        Calendar.current.component(.month, from: date) == Calendar.current.component(.month, from: otherDate)
    }
    
    private func eventsFor(date: Date) -> [StudyEvent]? {
        let username = calendarManager.username
        
        // First filter events by view mode (same logic as map)
        let eventsFilteredByType = calendarManager.events.filter { event in
            switch eventViewMode {
            case .all:
                // Show all events
                return true
                
            case .autoMatched:
                // Show only auto-matched events that user hasn't RSVPed to
                guard let isAutoMatched = event.isAutoMatched, isAutoMatched else { return false }
                return !event.attendees.contains(username) // User hasn't RSVPed
                
            case .rsvpedOnly:
                // Show events the user has RSVPed to OR is hosting
                return event.attendees.contains(username) || event.host == username
                
            @unknown default:
                // Default to showing all events if an unknown case is added in the future
                return true
            }
        }
        
        // Then filter by date
        return eventsFilteredByType.filter { calendar.isDate($0.time, inSameDayAs: date) }
    }
    
    private func previousMonth() -> Date {
        Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
    }
    
    private func nextMonth() -> Date {
        Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
    }
    
    private func getEventSpans(for date: Date) -> [EventSpan] {
        let username = calendarManager.username
        
        // First filter events by view mode (same logic as map)
        let eventsFilteredByType = calendarManager.events.filter { event in
            switch eventViewMode {
            case .all:
                // Show all events
                return true
                
            case .autoMatched:
                // Show only auto-matched events that user hasn't RSVPed to
                guard let isAutoMatched = event.isAutoMatched, isAutoMatched else { return false }
                return !event.attendees.contains(username) // User hasn't RSVPed
                
            case .rsvpedOnly:
                // Show events the user has RSVPed to OR is hosting
                return event.attendees.contains(username) || event.host == username
                
            @unknown default:
                // Default to showing all events if an unknown case is added in the future
                return true
            }
        }
        
        // Then filter for multi-day events
        return eventsFilteredByType.compactMap { event in
            let startDate = Calendar.current.startOfDay(for: event.time)
            let endDate = Calendar.current.startOfDay(for: event.endTime)
            guard startDate != endDate else { return nil }
            let isStart = Calendar.current.isDate(date, inSameDayAs: startDate)
            let isEnd = Calendar.current.isDate(date, inSameDayAs: endDate)
            let isMiddle = date > startDate && date < endDate
            if isStart || isEnd || isMiddle {
                return EventSpan(id: UUID(), event: event, isStart: isStart, isEnd: isEnd, isMiddle: isMiddle)
            }
            return nil
        }
    }
}

// MARK: - Supporting Views

struct DayEventsView: View {
    let events: [StudyEvent]
    let date: Date
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Events on \(date, formatter: dateFormatter)")
                    .font(.title2.bold())
                    .padding()
                List(events) { event in
                    NavigationLink(destination: EventDetailView(event: event, studyEvents: .constant([]), onRSVP: { _ in })) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title).font(.headline)
                            Text("Starts: \(event.time, formatter: dateFormatter)").font(.caption)
                            Text("Ends: \(event.endTime, formatter: dateFormatter)").font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Day Events")
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

struct CustomCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CustomCalendarView()
            .environmentObject(CalendarManager(accountManager: UserAccountManager()))
    }
}

// MARK: - Supporting Cells and Indicators

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isSameMonth: Bool
    let events: [StudyEvent]
    let eventSpans: [EventSpan]
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(isToday ? .bold : .medium)
                .foregroundColor(cellTextColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isToday ? Color.accentColor.opacity(0.2) : Color.clear)
                        .overlay(
                            Circle().strokeBorder(isToday ? Color.accentColor : Color.clear, lineWidth: 1.5)
                        )
                )
            VStack(spacing: 2) {
                ForEach(eventSpans.prefix(2)) { span in
                    MultiDayEventIndicator(span: span)
                }
                if !events.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(events.prefix(3)) { event in
                            SingleDayEventIndicator(event: event)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 65)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(cellBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )
        )
        .padding(.vertical, 2)
    }
    
    private var cellBackground: Color {
        isSelected ? Color.accentColor.opacity(0.1) : Color.bgCard
    }
    
    private var cellTextColor: Color {
        if !isSameMonth { return Color.textMuted }
        else if isToday { return Color.brandPrimary }
        else { return Color.textPrimary }
    }
}

struct WeekDayRow: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let events: [StudyEvent]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(date, style: .date)
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(Color.textPrimary)
                if !events.isEmpty {
                    Text("\(events.count) events")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
            }
            Spacer()
            ForEach(events.prefix(2)) { _ in
                Circle().fill(Color.accentColor).frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.bgCard)
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        )
    }
}

struct EventRow: View {
    let event: StudyEvent
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 4)
                .cornerRadius(2)
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.textPrimary)
                Text(event.time, style: .time)
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                        .foregroundColor(Color.textSecondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.bgCard)
        .cornerRadius(8)
    }
}

// MARK: - Simple Events List Component
struct SimpleEventsList: View {
    let events: [StudyEvent]
    
    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(events) { event in
                SimpleEventRow(event: event)
            }
        }
    }
}

// MARK: - Simple Event Row Component
struct SimpleEventRow: View {
    let event: StudyEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Simple event type indicator
            Circle()
                .fill(Color.accentColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.textPrimary)
                    .foregroundColor(Color.textPrimary)
                
                HStack(spacing: 8) {
                    Text(event.time.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                    
                    Text(event.eventType.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Simple RSVP indicator
            if event.attendees.contains(where: { $0 == "lola_ramirez_947" }) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 16))
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.textSecondary)
                    .font(.system(size: 14))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.bgCard)
        .cornerRadius(8)
    }
}



// Interest tag component for the UI
struct InterestTag: View {
    let interest: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(interest)
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

// TagSuggestions component for displaying tag options
struct TagSuggestions: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 8)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(suggestions.prefix(8), id: \.self) { suggestion in
                Button(action: {
                    onSelect(suggestion)
                }) {
                    Text(suggestion)
                        .font(.footnote)
                        .foregroundColor(.brandPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.brandPrimary.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.brandPrimary.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if suggestions.count > 8 {
                Menu {
                    ForEach(suggestions.dropFirst(8), id: \.self) { suggestion in
                        Button(suggestion) {
                            onSelect(suggestion)
                        }
                    }
                } label: {
                    HStack {
                        Text("More...")
                        Image(systemName: "ellipsis")
                    }
                    .font(.footnote)
                    .foregroundColor(Color.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.1))
                    )
                }
            }
        }
    }
}

/// Represents a multi-day event span.
struct EventSpan: Identifiable {
    let id: UUID
    let event: StudyEvent
    let isStart: Bool
    let isEnd: Bool
    let isMiddle: Bool
}

/// Indicator for multi-day events.
struct MultiDayEventIndicator: View {
    let span: EventSpan
    
    var body: some View {
        HStack(spacing: 0) {
            if span.isStart {
                Rectangle()
                    .fill(eventColor(for: span.event))
                    .cornerRadius(4, corners: [.topLeft, .bottomLeft])
            }
            Rectangle().fill(eventColor(for: span.event))
            if span.isEnd {
                Rectangle()
                    .fill(eventColor(for: span.event))
                    .cornerRadius(4, corners: [.topRight, .bottomRight])
            }
        }
        .frame(height: 6)
        .opacity(0.9)
    }
}

/// Indicator for single-day events.
struct SingleDayEventIndicator: View {
    let event: StudyEvent
    
    var body: some View {
        Circle()
            .fill(eventColor(for: event))
            .frame(width: 6, height: 6)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: eventColor(for: event).opacity(0.3), radius: 1, x: 0, y: 1)
    }
}

/// Returns a color based on the event type.
func eventColor(for event: StudyEvent) -> Color {
    switch event.eventType {
    case .study:
        return Color.blue.opacity(0.9)
    case .party:
        return Color.purple.opacity(0.9)
    case .business:
        return Color.orange.opacity(0.9)
    case .cultural:
        return Color.orange.opacity(0.9)
    case .academic:
        return Color.green.opacity(0.9)
    case .networking:
        return Color.pink.opacity(0.9)
    case .social:
        return Color.red.opacity(0.9)
    case .language_exchange:
        return Color.teal.opacity(0.9)
    case .other:
        return Color.gray.opacity(0.9)
    }
}

// MARK: - RoundedCorner Modifier

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
