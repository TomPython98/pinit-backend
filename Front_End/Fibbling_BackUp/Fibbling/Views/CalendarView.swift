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
                EventCreationSheet()
                    .presentationDetents([.height(420)])
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
            // print("📅 [CalendarView] View appeared - fetching latest events")
            // calendarManager.fetchEvents() // REMOVED
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("EventRSVPStatusChanged"))) { notification in
            print("📅 [CalendarView] Received RSVP status change notification from WebSocket")
            if let eventID = notification.userInfo?["eventID"] as? UUID {
                print("📅 [CalendarView] RSVP status change for event ID: \(eventID)")

                // Force UI update by refreshing selectedDayEvents if the updated event is part of the current selection
                if let index = selectedDayEvents.firstIndex(where: { $0.id == eventID }) {
                    print("📅 [CalendarView] Updated event is in currently displayed day events")
                    selectedDayEvents = calendarManager.events.filter { calendar.isDate($0.time, inSameDayAs: selectedDate) }
                }

                // // Regardless of specific event being in view, refresh all events - REMOVED
                // DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                //     calendarManager.fetchEvents() // REMOVED
                // }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("EventRSVPUpdated"))) { notification in
            print("📅 [CalendarView] Received RSVP update notification")
            if let eventID = notification.userInfo?["eventID"] as? UUID {
                print("📅 [CalendarView] RSVP update for event ID: \(eventID)")
            }
            // // Regardless of specific event, refresh all events - REMOVED
            // DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            //     calendarManager.fetchEvents() // REMOVED
            // }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("EventUpdatedFromWebSocket"))) { notification in
            print("📅 [CalendarView] Received WebSocket event update notification")
            if let eventID = notification.userInfo?["eventID"] as? UUID {
                print("📅 [CalendarView] WebSocket update for event ID: \(eventID)")
                
                // Force UI update by refreshing selectedDayEvents if the updated event is part of the current selection
                if let index = selectedDayEvents.firstIndex(where: { $0.id == eventID }) {
                    print("📅 [CalendarView] Updated event is in currently displayed day events")
                    
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


struct EventCreationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var calendarManager: CalendarManager
    
    // Event data
    @State private var eventTitle = ""
    @State private var eventDate = Date()
    @State private var eventEndDate = Date().addingTimeInterval(3600)
    @State private var eventDescription = ""
    @State private var isPublicEvent = true
    @State private var eventType: EventType = .study
    @State private var eventLocation = ""
    @State private var coordinates = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    // Auto-matching states
    @State private var autoMatchingEnabled = false
    @State private var maxParticipants = 10
    @State private var selectedInterests: [String] = []
    @State private var newInterest = ""
    @State private var addingInterest = false
    
    // Common interest tags
    let commonInterests = [
        "Programming", "Swift", "iOS Development", "Python", "AI", 
        "Machine Learning", "Web Development", "Mathematics", "Statistics",
        "Physics", "Chemistry", "Biology", "Economics", "Finance", 
        "Literature", "Philosophy", "History", "Art"
    ]
    
    // UI states
    @State private var currentTab = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    
    var body: some View {
        ZStack {
            // Background
            Color.bgSurface
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                TabView(selection: $currentTab) {
                    // Basic Info
                    basicInfoView
                        .tag(0)
                    
                    // Date & Time
                    dateTimeView
                        .tag(1)
                    
                    // Auto-matching
                    autoMatchingView
                        .tag(2)
                    
                    // Review & Create
                    reviewView
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Navigation buttons
                navigationControls
            }
            
            // Loading overlay
            if isLoading {
                loadingOverlay
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(errorMessage == nil ? "Success" : "Error"),
                message: Text(errorMessage ?? "Event created successfully"),
                dismissButton: .default(Text("OK")) {
                    if errorMessage == nil {
                    dismiss()
                }
                }
            )
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        ZStack {
            // Background with gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 8) {
                // Navigation title
                Text(["Event Details", "Date & Time", "Matching", "Review"][currentTab])
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                
                // Progress indicator
                HStack(spacing: 4) {
                    ForEach(0..<4) { index in
                        Capsule()
                            .fill(currentTab >= index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: index == currentTab ? 24 : 12, height: 4)
                            .animation(.spring(), value: currentTab)
                    }
                }
                .padding(.bottom, 8)
            }
            
            // Close button
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .frame(height: 100)
    }
    
    // MARK: - Basic Info View
    private var basicInfoView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Title Card
                cardView {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                            Text("Event Title")
                                .font(.headline)
                        }
                        
                        TextField("Enter title", text: $eventTitle)
                            .padding()
                            .background(Color.bgSecondary)
                            .cornerRadius(8)
                    }
                }
                
                // Event Type
                cardView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(.blue)
                            Text("Event Type")
                                .font(.headline)
                        }
                        
                        Picker("Event Type", selection: $eventType) {
                            ForEach(EventType.allCases) { type in
                                HStack {
                                    Circle()
                                        .fill(eventTypeColor(type))
                                        .frame(width: 12, height: 12)
                                    
                                    Text(type.displayName)
                                        .foregroundColor(Color.textPrimary)
                                }
                                .tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                // Description Card
                cardView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "text.alignleft")
                                .foregroundColor(.blue)
                            Text("Description")
                                .font(.headline)
                        }
                        
                        TextEditor(text: $eventDescription)
                            .frame(minHeight: 100)
                            .padding(4)
                            .background(Color.bgSecondary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                
                // Location Card (placeholder for future location functionality)
                cardView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.blue)
                            Text("Location")
                                .font(.headline)
                        }
                        
                        TextField("Enter location", text: $eventLocation)
                            .padding()
                            .background(Color.bgSecondary)
                            .cornerRadius(8)
                        
                        Text("Location feature will be available soon")
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Date & Time View
    private var dateTimeView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Date Card
                cardView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text("Event Date & Time")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Start")
                                    .font(.subheadline)
                                    .foregroundColor(Color.textSecondary)
                                
                                DatePicker("", selection: $eventDate)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("End")
                                    .font(.subheadline)
                                    .foregroundColor(Color.textSecondary)
                                
                                DatePicker("", selection: $eventEndDate)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                        }
                        .padding(.leading, 8)
                    }
                }
                
                // Duration
                cardView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                            Text("Duration")
                                .font(.headline)
                        }
                        
                        HStack {
                            Text(formatDuration(from: eventDate, to: eventEndDate))
                                .padding()
                                .background(Color.bgSecondary)
                                .cornerRadius(8)
                            
                            Spacer()
                        }
                    }
                }
                
                // Privacy Card
                cardView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.blue)
                            Text("Event Privacy")
                                .font(.headline)
                        }
                        
                        Toggle(isOn: $isPublicEvent) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(isPublicEvent ? "Public Event" : "Private Event")
                                    .font(.subheadline)
                                
                                Text(isPublicEvent ? 
                                     "Anyone can see and join this event" : 
                                        "Only invited users can see this event")
                                    .font(.caption)
                                    .foregroundColor(Color.textSecondary)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Auto Matching View
    private var autoMatchingView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Auto-matching Card
                cardView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                            Text("Auto-Matching")
                                .font(.headline)
                        }
                        
                        Toggle(isOn: $autoMatchingEnabled) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Enable Auto-Matching")
                                    .font(.subheadline)
                                
                                Text("Automatically invite users with similar interests")
                                    .font(.caption)
                                    .foregroundColor(Color.textSecondary)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        
                        if autoMatchingEnabled {
                            VStack(alignment: .leading, spacing: 16) {
                                Divider()
                                
                                // Participants limit
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Max Participants")
                                        .font(.subheadline)
                                    
                                    HStack {
                                        Text("\(maxParticipants)")
                                            .fontWeight(.semibold)
                                            .frame(width: 40, alignment: .center)
                                        
                                        Slider(value: .init(
                                            get: { Double(maxParticipants) },
                                            set: { maxParticipants = Int($0) }
                                        ), in: 1...50, step: 1)
                                    }
                                }
                                
                                Divider()
                                
                                // Interest Tags Section
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Interest Tags")
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        if !addingInterest {
                                            Button(action: {
                                                withAnimation {
                                                    addingInterest = true
                                                }
                                            }) {
                                                Label("Add", systemImage: "plus")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                    
                                    // Tags layout
                                    if !selectedInterests.isEmpty {
                                        FlowLayout(spacing: 8) {
                                            ForEach(selectedInterests, id: \.self) { interest in
                                                InterestTag(interest: interest, onRemove: {
                                                    withAnimation {
                                                        selectedInterests.removeAll { $0 == interest }
                                                    }
                                                })
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    } else if !addingInterest {
                                        Text("Add tags to improve matching")
                                            .font(.caption)
                                            .foregroundColor(Color.textSecondary)
                                            .padding(.vertical, 8)
                                    }
                                    
                                    // Add tag interface
                                    if addingInterest {
                                        VStack(spacing: 12) {
                                            // Input field with add button
                                            HStack {
                                                TextField("New tag", text: $newInterest)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                    .background(Color.bgSecondary)
                                                    .cornerRadius(8)
                                                
                                                Button(action: {
                                                    if !newInterest.isEmpty && !selectedInterests.contains(newInterest) {
                                                        withAnimation {
                                                            selectedInterests.append(newInterest)
                                                            newInterest = ""
                                                        }
                                                    }
                                                }) {
                                                    Text("Add")
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 8)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 8)
                                                                .fill(newInterest.isEmpty ? Color.gray : Color.blue)
                                                        )
                                                }
                                                .disabled(newInterest.isEmpty)
                                            }
                                            
                                            // Suggestion label
                                            HStack {
                                                Text("Suggestions:")
                                                    .font(.caption)
                                                    .foregroundColor(Color.textSecondary)
                                                
                                                Spacer()
                                                
                                                Button("Done") {
                                                    withAnimation {
                                                        addingInterest = false
                                                    }
                                                }
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                            }
                                            
                                            // Tag suggestions
                                            let availableTags = commonInterests.filter { !selectedInterests.contains($0) }
                                            if !availableTags.isEmpty {
                                                TagSuggestions(
                                                    suggestions: availableTags,
                                                    onSelect: { interest in
                                                        withAnimation {
                                                            selectedInterests.append(interest)
                                                        }
                                                    }
                                                )
                                            } else {
                                                Text("No more suggestions available")
                                                    .font(.caption)
                                                    .foregroundColor(Color.textSecondary)
                                                    .padding(.vertical, 8)
                                            }
                                        }
                                        .padding(12)
                                        .background(Color.bgSecondary.opacity(0.5))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Information Card
                if autoMatchingEnabled {
                    cardView {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text("How It Works")
                                    .font(.headline)
                            }
                            
                            Text("Auto-matching uses your selected tags to find users with similar interests. The system will automatically invite compatible users to your event.")
                                .font(.caption)
                                .foregroundColor(Color.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if selectedInterests.isEmpty {
                                Text("⚠️ Add at least one interest tag to enable auto-matching")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Review View
    private var reviewView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Event Summary Card
                cardView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.blue)
                            Text("Event Summary")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            // Title and Type
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Title")
                                    .font(.caption)
                                    .foregroundColor(Color.textSecondary)
                                
                                HStack {
                                    Text(eventTitle.isEmpty ? "Untitled Event" : eventTitle)
                                        .font(.subheadline.bold())
                                    
                                    Spacer()
                                    
                                    Text(eventType.displayName)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(eventTypeColor(eventType))
                                        .cornerRadius(8)
                                }
                            }
                            
                            Divider()
                            
                            // Date and Time
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Schedule")
                                    .font(.caption)
                                    .foregroundColor(Color.textSecondary)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(Color.textSecondary)
                                            .frame(width: 20)
                                        Text(formatDate(eventDate))
                                            .font(.subheadline)
                                    }
                                    
                                    HStack {
                                        Image(systemName: "clock")
                                            .foregroundColor(Color.textSecondary)
                                            .frame(width: 20)
                                        Text("\(formatTime(eventDate)) - \(formatTime(eventEndDate))")
                                            .font(.subheadline)
                                    }
                                    
                                    HStack {
                                        Image(systemName: "hourglass")
                                            .foregroundColor(Color.textSecondary)
                                            .frame(width: 20)
                                        Text(formatDuration(from: eventDate, to: eventEndDate))
                                            .font(.subheadline)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // Privacy and Auto-matching
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Settings")
                                    .font(.caption)
                                    .foregroundColor(Color.textSecondary)
                                
                                HStack {
                                    Image(systemName: isPublicEvent ? "globe" : "lock")
                                        .foregroundColor(Color.textSecondary)
                                        .frame(width: 20)
                                    Text(isPublicEvent ? "Public event" : "Private event")
                                        .font(.subheadline)
                                }
                                
                                HStack {
                                    Image(systemName: "person.2")
                                        .foregroundColor(Color.textSecondary)
                                        .frame(width: 20)
                                    Text(autoMatchingEnabled ? "Auto-matching enabled" : "Auto-matching disabled")
                                        .font(.subheadline)
                                }
                                
                                if autoMatchingEnabled {
                                    HStack {
                                        Image(systemName: "number")
                                            .foregroundColor(Color.textSecondary)
                                            .frame(width: 20)
                                        Text("Maximum \(maxParticipants) participants")
                                            .font(.subheadline)
                                    }
                                }
                            }
                            
                            // Show tags if auto-matching is enabled
                            if autoMatchingEnabled && !selectedInterests.isEmpty {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Interest Tags")
                                        .font(.caption)
                                        .foregroundColor(Color.textSecondary)
                                    
                                    FlowLayout(spacing: 6) {
                                        ForEach(selectedInterests, id: \.self) { tag in
                                            Text(tag)
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.blue.opacity(0.1))
                                                )
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                            }
                            
                            if !eventDescription.isEmpty {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Description")
                                        .font(.caption)
                                        .foregroundColor(Color.textSecondary)
                                    
                                    Text(eventDescription)
                                        .font(.subheadline)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                
                // Validation alerts
                if eventTitle.isEmpty {
                    validationAlert(message: "Event title is required")
                }
                
                if autoMatchingEnabled && selectedInterests.isEmpty {
                    validationAlert(message: "Interest tags are required for auto-matching")
                }
                
                if eventDate >= eventEndDate {
                    validationAlert(message: "End time must be after start time")
                }
                
                // Create button
                Button(action: createEvent) {
                    Text("Create Event")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .disabled(
                    eventTitle.isEmpty || 
                    eventDate >= eventEndDate ||
                    (autoMatchingEnabled && selectedInterests.isEmpty)
                )
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .padding()
        }
    }
    
    // MARK: - Navigation Controls
    private var navigationControls: some View {
        HStack {
            if currentTab > 0 {
                Button(action: {
                    withAnimation {
                        currentTab -= 1
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.bgSecondary)
                    .cornerRadius(8)
                }
            }
            
            Spacer()
            
            if currentTab < 3 {
                Button(action: {
                    withAnimation {
                        currentTab += 1
                    }
                }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(
                    (currentTab == 0 && eventTitle.isEmpty) ||
                    (currentTab == 1 && eventDate >= eventEndDate) ||
                    (currentTab == 2 && autoMatchingEnabled && selectedInterests.isEmpty)
                )
            }
        }
        .padding()
        .background(Color.bgCard)
        .shadow(color: Color.black.opacity(0.05), radius: 3, y: -2)
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Creating your event...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color.bgCard.opacity(0.9))
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
    
    // MARK: - Helper Views
    private func cardView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(Color.bgCard)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func validationAlert(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.orange)
            
            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Functions
    private func eventTypeColor(_ type: EventType) -> Color {
        switch type {
        case .study:
            return Color.blue
        case .party:
            return Color.purple
        case .business:
            return Color.orange
        case .cultural:
            return Color.orange
        case .academic:
            return Color.green
        case .networking:
            return Color.pink
        case .social:
            return Color.red
        case .language_exchange:
            return Color.teal
        case .other:
            return Color.gray
        }
    }
    
    private func formatDuration(from startDate: Date, to endDate: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: startDate, to: endDate)
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        
        if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")\(minutes > 0 ? ", \(minutes) min" : "")"
        } else {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Event Creation
    private func createEvent() {
        // Set loading state
        isLoading = true
        // Do NOT add to local calendar here!
        // Only send to backend
        let newEvent = StudyEvent(
            id: UUID(),
            title: eventTitle,
            coordinate: coordinates,
            time: eventDate,
            endTime: eventEndDate,
            description: eventDescription,
            invitedFriends: [],
            attendees: [],
            isPublic: isPublicEvent,
            host: calendarManager.username,
            hostIsCertified: true,
            eventType: eventType,
            isAutoMatched: autoMatchingEnabled
        )
        sendEventToBackend(newEvent)
    }

    private func sendEventToBackend(_ event: StudyEvent) {
        guard let url = URL(string: APIConfig.fullURL(for: "createEvent")) else {
            isLoading = false
            errorMessage = "Invalid URL"
            showAlert = true
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let formattedStartDate = isoFormatter.string(from: event.time)
        let formattedEndDate = isoFormatter.string(from: event.endTime)
        
        // Prepare the request body
        var jsonBody: [String: Any] = [
            "host": calendarManager.username,
            "title": event.title,
            "latitude": event.coordinate.latitude,
            "longitude": event.coordinate.longitude,
            "description": event.description ?? "",
            "time": formattedStartDate,
            "end_time": formattedEndDate,
            "is_public": event.isPublic,
            "invited_friends": event.invitedFriends,
            "event_type": event.eventType.rawValue,
            "max_participants": maxParticipants
        ]
        
        // Add auto-matching data if enabled
        if autoMatchingEnabled {
            jsonBody["auto_matching_enabled"] = true
            jsonBody["interest_tags"] = selectedInterests
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
            print("📤 Sending event data: \(jsonBody)")
        } catch {
            isLoading = false
            errorMessage = "JSON encoding error: \(error.localizedDescription)"
            showAlert = true
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status: \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 201 {
                        self.errorMessage = "Server error: HTTP \(httpResponse.statusCode)"
                        self.showAlert = true
                        return
                    }
                }
                if let data = data, let responseStr = String(data: data, encoding: .utf8) {
                    print("📦 Response: \(responseStr)")
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // Parse event data from backend response
                        if let eventId = json["event_id"] as? String {
                            // Construct StudyEvent from backend data (use all fields if available)
                            let backendEvent = StudyEvent(
                                id: UUID(uuidString: eventId) ?? UUID(),
                                title: event.title,
                                coordinate: event.coordinate,
                                time: event.time,
                                endTime: event.endTime,
                                description: event.description,
                                invitedFriends: event.invitedFriends,
                                attendees: event.attendees,
                                isPublic: event.isPublic,
                                host: event.host,
                                hostIsCertified: event.hostIsCertified,
                                eventType: event.eventType,
                                isAutoMatched: event.isAutoMatched
                            )
                            self.calendarManager.addEvent(backendEvent)
                        }
                        // Check if auto-matching results are available
                        if let autoMatchResults = json["auto_matching_results"] as? [String: Any] {
                            let enabled = autoMatchResults["enabled"] as? Bool ?? false
                            let invitesSent = autoMatchResults["invites_sent"] as? Int ?? 0
                            
                            if enabled && invitesSent > 0 {
                                self.errorMessage = nil
                                self.showAlert = true
                                print("✅ Auto-matched and invited \(invitesSent) users")
                            } else {
                                self.errorMessage = nil
                                self.showAlert = true
                            }
                        } else {
                            self.errorMessage = nil
                            self.showAlert = true
                        }
                    }
                }
                // Let WebSocket handle the update
                print("📢 [EventCreationSheet] Created event, WebSocket will handle refresh")
            }
        }.resume()
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
