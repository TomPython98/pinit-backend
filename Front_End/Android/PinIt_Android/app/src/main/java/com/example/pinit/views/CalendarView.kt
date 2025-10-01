package com.example.pinit.views

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import com.example.pinit.models.CalendarManager
import com.example.pinit.models.StudyEvent
import com.example.pinit.models.UserAccountManager
import com.example.pinit.ui.theme.*
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.time.temporal.TemporalAdjusters
import java.time.temporal.WeekFields
import java.util.*
import androidx.compose.foundation.border

enum class CalendarViewMode {
    MONTH, WEEK
}

data class EventSpan(
    val id: UUID,
    val event: StudyEvent,
    val isStart: Boolean,
    val isEnd: Boolean,
    val isMiddle: Boolean
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CalendarView(
    accountManager: UserAccountManager,
    calendarManager: CalendarManager,
    onDismiss: () -> Unit
) {
    var displayedMonth by remember { mutableStateOf(YearMonth.now()) }
    var selectedDate by remember { mutableStateOf(LocalDate.now()) }
    var calendarViewMode by remember { mutableStateOf(CalendarViewMode.MONTH) }
    var showDayEventsSheet by remember { mutableStateOf(false) }
    var showEventCreation by remember { mutableStateOf(false) }
    var selectedDayEvents by remember { mutableStateOf<List<StudyEvent>>(emptyList()) }
    
    val todayDate = LocalDate.now()
    
    // Fetch events when the view appears
    LaunchedEffect(Unit) {
        calendarManager.fetchEvents()
    }
    
    // Use a box with a background to create a modal-like experience
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        Scaffold(
            topBar = {
                Column {
                    // Top app bar with back button
                    TopAppBar(
                        title = { Text("Calendar") },
                        navigationIcon = {
                            IconButton(onClick = onDismiss) {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                    contentDescription = "Back to main screen"
                                )
                            }
                        },
                        colors = TopAppBarDefaults.topAppBarColors(
                            containerColor = PrimaryColor,
                            titleContentColor = Color.White,
                            navigationIconContentColor = Color.White
                        ),
                        actions = {
                            // Add "Create" button
                            TextButton(
                                onClick = { showEventCreation = true },
                                colors = ButtonDefaults.textButtonColors(
                                    contentColor = Color.White
                                )
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Add,
                                    contentDescription = "Create Event"
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Create")
                            }
                        }
                    )
                    
                    // Calendar header with month/year display and view mode selector
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 8.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = displayedMonth.format(DateTimeFormatter.ofPattern("MMMM yyyy")),
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold
                        )
                        
                        Row {
                            IconButton(onClick = { calendarViewMode = CalendarViewMode.MONTH }) {
                                Icon(
                                    imageVector = Icons.Default.DateRange,
                                    contentDescription = "Month View",
                                    tint = if (calendarViewMode == CalendarViewMode.MONTH) 
                                              MaterialTheme.colorScheme.primary else TextSecondary
                                )
                            }
                            IconButton(onClick = { calendarViewMode = CalendarViewMode.WEEK }) {
                                Icon(
                                    imageVector = Icons.Default.ViewWeek,
                                    contentDescription = "Week View",
                                    tint = if (calendarViewMode == CalendarViewMode.WEEK) 
                                              MaterialTheme.colorScheme.primary else TextSecondary
                                )
                            }
                        }
                    }
                    
                    // Navigation row (prev, today, next)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 8.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        IconButton(onClick = { 
                            displayedMonth = displayedMonth.minusMonths(1)
                        }) {
                            Icon(
                                imageVector = Icons.Default.ChevronLeft,
                                contentDescription = "Previous"
                            )
                        }
                        
                        TextButton(onClick = { 
                            displayedMonth = YearMonth.now()
                            selectedDate = LocalDate.now()
                        }) {
                            Text("Today")
                        }
                        
                        IconButton(onClick = { 
                            displayedMonth = displayedMonth.plusMonths(1)
                        }) {
                            Icon(
                                imageVector = Icons.Default.ChevronRight,
                                contentDescription = "Next"
                            )
                        }
                    }
                    
                    // Weekday header row
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 4.dp)
                    ) {
                        val daysOfWeek = DayOfWeek.values()
                        for (dayOfWeek in daysOfWeek) {
                            Text(
                                text = dayOfWeek.getDisplayName(TextStyle.SHORT, Locale.getDefault()),
                                modifier = Modifier.weight(1f),
                                textAlign = TextAlign.Center,
                                color = TextSecondary,
                                fontWeight = FontWeight.SemiBold,
                                style = MaterialTheme.typography.bodySmall
                            )
                        }
                    }
                    
                    HorizontalDivider()
                }
            }
        ) { innerPadding ->
            Column(
                modifier = Modifier
                    .padding(innerPadding)
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
            ) {
                // Calendar Grid (Month View)
                if (calendarViewMode == CalendarViewMode.MONTH) {
                    val days = generateDaysForMonth(displayedMonth)
                    
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(7),
                        contentPadding = PaddingValues(8.dp),
                        modifier = Modifier
                            .height(300.dp)
                            .fillMaxWidth()
                    ) {
                        items(days) { date ->
                            val isCurrentMonth = date.month == displayedMonth.month
                            val isToday = date.equals(todayDate)
                            val isSelected = date.equals(selectedDate)
                            val dayEvents = eventsForDate(date, calendarManager.events)
                            val eventSpans = getEventSpans(date, calendarManager.events)
                            
                            DayCell(
                                date = date,
                                isSelected = isSelected,
                                isToday = isToday, 
                                isSameMonth = isCurrentMonth,
                                events = dayEvents,
                                eventSpans = eventSpans,
                                onClick = {
                                    selectedDate = date
                                    if (dayEvents.isNotEmpty() || eventSpans.isNotEmpty()) {
                                        val allEvents = dayEvents + eventSpans.map { it.event }
                                        selectedDayEvents = allEvents.distinctBy { it.id }
                                        showDayEventsSheet = true
                                    }
                                }
                            )
                        }
                    }
                } 
                // Week View
                else {
                    val weekDays = generateWeekDays(selectedDate)
                    
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(8.dp)
                    ) {
                        weekDays.forEach { date ->
                            val isToday = date.equals(todayDate)
                            val isSelected = date.equals(selectedDate)
                            val dayEvents = eventsForDate(date, calendarManager.events)
                            
                            WeekDayRow(
                                date = date,
                                isSelected = isSelected,
                                isToday = isToday,
                                events = dayEvents,
                                onClick = {
                                    selectedDate = date
                                    if (dayEvents.isNotEmpty()) {
                                        selectedDayEvents = dayEvents
                                        showDayEventsSheet = true
                                    }
                                }
                            )
                            
                            Spacer(modifier = Modifier.height(8.dp))
                        }
                    }
                }
                
                // Today's Events Section
                Surface(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    shape = RoundedCornerShape(16.dp),
                    tonalElevation = 1.dp,
                    shadowElevation = 2.dp
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Today's Events",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        val todayEvents = eventsForDate(todayDate, calendarManager.events)
                        
                        if (todayEvents.isEmpty()) {
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 24.dp),
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Event,
                                    contentDescription = "No Events",
                                    modifier = Modifier.size(48.dp),
                                    tint = TextMuted
                                )
                                
                                Spacer(modifier = Modifier.height(8.dp))
                                
                                Text(
                                    text = "No events today",
                                    color = TextMuted,
                                    style = MaterialTheme.typography.bodyMedium
                                )
                            }
                        } else {
                            Column {
                                todayEvents.forEach { event ->
                                    EventRow(
                                        event = event,
                                        onClick = {
                                            selectedDayEvents = listOf(event)
                                            showDayEventsSheet = true
                                        }
                                    )
                                    
                                    Spacer(modifier = Modifier.height(8.dp))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Day Events Sheet
    if (showDayEventsSheet) {
        DayEventsSheet(
            events = selectedDayEvents,
            date = selectedDate,
            onDismiss = { showDayEventsSheet = false }
        )
    }
    
    // Event Creation Sheet
    if (showEventCreation) {
        EventCreationSheet(
            onDismiss = { showEventCreation = false },
            onCreateEvent = { event ->
                calendarManager.addEvent(event)
            },
            username = accountManager.currentUser ?: ""
        )
    }
}

@Composable
fun DayCell(
    date: LocalDate,
    isSelected: Boolean,
    isToday: Boolean,
    isSameMonth: Boolean,
    events: List<StudyEvent>,
    eventSpans: List<EventSpan>,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .aspectRatio(1f)
            .padding(2.dp)
            .clip(RoundedCornerShape(10.dp))
            .background(
                color = if (isSelected) 
                    MaterialTheme.colorScheme.primary.copy(alpha = 0.1f) 
                else 
                    Color.White
            )
            .border(
                width = if (isSelected) 1.5.dp else 0.dp,
                color = if (isSelected) MaterialTheme.colorScheme.primary else Color.Transparent,
                shape = RoundedCornerShape(10.dp)
            )
            .clickable(onClick = onClick),
        contentAlignment = Alignment.TopCenter
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(4.dp)
        ) {
            // Day number with today indicator
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .size(28.dp)
                    .background(
                        color = if (isToday) MaterialTheme.colorScheme.primary.copy(alpha = 0.2f) else Color.Transparent,
                        shape = CircleShape
                    )
                    .border(
                        width = if (isToday) 1.5.dp else 0.dp,
                        color = if (isToday) MaterialTheme.colorScheme.primary else Color.Transparent,
                        shape = CircleShape
                    )
            ) {
                Text(
                    text = date.dayOfMonth.toString(),
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = if (isToday) FontWeight.Bold else FontWeight.Medium,
                    color = when {
                        !isSameMonth -> Color.Gray.copy(alpha = 0.5f)
                        isToday -> MaterialTheme.colorScheme.primary
                        else -> MaterialTheme.colorScheme.onSurface
                    }
                )
            }
            
            Spacer(modifier = Modifier.height(2.dp))
            
            // Multi-day event spans
            eventSpans.take(2).forEach { span ->
                MultiDayEventIndicator(span = span)
            }
            
            // Single day event indicators
            if (events.isNotEmpty()) {
                Row(
                    horizontalArrangement = Arrangement.Center,
                    modifier = Modifier.padding(top = 2.dp)
                ) {
                    events.take(3).forEach { event ->
                        SingleDayEventIndicator(event = event)
                        Spacer(modifier = Modifier.width(3.dp))
                    }
                }
            }
        }
    }
}

@Composable
fun MultiDayEventIndicator(span: EventSpan) {
    Row(modifier = Modifier.fillMaxWidth()) {
        // Render differently based on position in multi-day span
        Box(
            modifier = Modifier
                .height(6.dp)
                .fillMaxWidth()
                .clip(
                    RoundedCornerShape(
                        topStart = if (span.isStart) 4.dp else 0.dp,
                        bottomStart = if (span.isStart) 4.dp else 0.dp,
                        topEnd = if (span.isEnd) 4.dp else 0.dp,
                        bottomEnd = if (span.isEnd) 4.dp else 0.dp
                    )
                )
                .background(eventColor(span.event))
        )
    }
}

@Composable
fun SingleDayEventIndicator(event: StudyEvent) {
    Box(
        modifier = Modifier
            .size(6.dp)
            .clip(CircleShape)
            .background(eventColor(event))
            .border(
                width = 1.dp,
                color = Color.White.copy(alpha = 0.5f),
                shape = CircleShape
            )
    )
}

@Composable
fun WeekDayRow(
    date: LocalDate,
    isSelected: Boolean,
    isToday: Boolean,
    events: List<StudyEvent>,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(8.dp),
        tonalElevation = if (isSelected) 3.dp else 1.dp,
        shadowElevation = if (isSelected) 2.dp else 0.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column {
                Text(
                    text = date.format(DateTimeFormatter.ofPattern("EEE, MMM d")),
                    fontWeight = if (isToday) FontWeight.Bold else FontWeight.Normal,
                    color = if (isToday) MaterialTheme.colorScheme.primary else TextPrimary
                )
                
                if (events.isNotEmpty()) {
                    Text(
                        text = "${events.size} events",
                        style = MaterialTheme.typography.bodySmall,
                        color = TextSecondary
                    )
                }
            }
            
            Row {
                events.take(3).forEach { _ ->
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .clip(CircleShape)
                            .background(MaterialTheme.colorScheme.primary)
                            .padding(end = 2.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                }
            }
        }
    }
}

@Composable
fun EventRow(
    event: StudyEvent,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(8.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Color indicator based on event type
            Box(
                modifier = Modifier
                    .width(4.dp)
                    .height(40.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(eventColor(event))
            )
            
            Spacer(modifier = Modifier.width(12.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = event.title,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Medium
                )
                
                Text(
                    text = formatTime(event.time),
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Gray
                )
            }
            
            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = "View Event",
                tint = Color.Gray
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DayEventsSheet(
    events: List<StudyEvent>,
    date: LocalDate,
    onDismiss: () -> Unit
) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = BgSurface
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                text = "Events on ${date.format(DateTimeFormatter.ofPattern("MMMM d, yyyy"))}",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            LazyColumn(
                modifier = Modifier.heightIn(max = 400.dp)
            ) {
                items(events) { event ->
                    Surface(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp),
                        shape = RoundedCornerShape(8.dp),
                        tonalElevation = 1.dp
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp)
                        ) {
                            Text(
                                text = event.title,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.SemiBold
                            )
                            
                            Spacer(modifier = Modifier.height(4.dp))
                            
                            Text(
                                text = "Starts: ${formatDateTime(event.time)}",
                                style = MaterialTheme.typography.bodyMedium
                            )
                            
                            if (event.endTime != null) {
                                Text(
                                    text = "Ends: ${formatDateTime(event.endTime)}",
                                    style = MaterialTheme.typography.bodyMedium
                                )
                            }
                            
                            if (event.description != null) {
                                Spacer(modifier = Modifier.height(8.dp))
                                Text(
                                    text = event.description,
                                    style = MaterialTheme.typography.bodyMedium
                                )
                            }
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            Text(
                                text = "Host: ${event.host}",
                                style = MaterialTheme.typography.bodySmall,
                                color = TextSecondary
                            )
                            
                            Text(
                                text = "Attendees: ${event.attendees.joinToString(", ")}",
                                style = MaterialTheme.typography.bodySmall,
                                color = TextSecondary
                            )
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Button(
                onClick = onDismiss,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Close")
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventCreationSheet(
    onDismiss: () -> Unit,
    onCreateEvent: (StudyEvent) -> Unit,
    username: String
) {
    var eventTitle by remember { mutableStateOf("") }
    var eventDescription by remember { mutableStateOf("") }
    var eventDate by remember { mutableStateOf(LocalDate.now()) }
    var eventTime by remember { mutableStateOf(LocalDateTime.now()) }
    var eventEndTime by remember { mutableStateOf(LocalDateTime.now().plusHours(1)) }
    var isPublicEvent by remember { mutableStateOf(true) }
    
    // Date/time pickers state
    var showDatePicker by remember { mutableStateOf(false) }
    var showStartTimePicker by remember { mutableStateOf(false) }
    var showEndTimePicker by remember { mutableStateOf(false) }
    
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = BgSurface
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                text = "Create New Event",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            OutlinedTextField(
                value = eventTitle,
                onValueChange = { eventTitle = it },
                label = { Text("Event Title") },
                modifier = Modifier.fillMaxWidth()
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            OutlinedTextField(
                value = eventDescription,
                onValueChange = { eventDescription = it },
                label = { Text("Description") },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(100.dp)
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Date Picker Button
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { showDatePicker = true },
                shape = RoundedCornerShape(4.dp),
                border = ButtonDefaults.outlinedButtonBorder
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.DateRange,
                        contentDescription = "Date"
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Date: ${eventDate.format(DateTimeFormatter.ofPattern("MMM d, yyyy"))}"
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Start Time Picker Button
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { showStartTimePicker = true },
                shape = RoundedCornerShape(4.dp),
                border = ButtonDefaults.outlinedButtonBorder
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Schedule,
                        contentDescription = "Start Time"
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Start Time: ${eventTime.format(DateTimeFormatter.ofPattern("h:mm a"))}"
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // End Time Picker Button
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { showEndTimePicker = true },
                shape = RoundedCornerShape(4.dp),
                border = ButtonDefaults.outlinedButtonBorder
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Schedule,
                        contentDescription = "End Time"
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "End Time: ${eventEndTime.format(DateTimeFormatter.ofPattern("h:mm a"))}"
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Public Event Toggle
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Public Event",
                    modifier = Modifier.weight(1f)
                )
                Switch(
                    checked = isPublicEvent,
                    onCheckedChange = { isPublicEvent = it }
                )
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                OutlinedButton(
                    onClick = onDismiss,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Cancel")
                }
                
                Spacer(modifier = Modifier.width(16.dp))
                
                Button(
                    onClick = {
                        // Combine date and time components
                        val startDateTime = LocalDateTime.of(
                            eventDate.year,
                            eventDate.month,
                            eventDate.dayOfMonth,
                            eventTime.hour,
                            eventTime.minute
                        )
                        
                        val endDateTime = LocalDateTime.of(
                            eventDate.year,
                            eventDate.month,
                            eventDate.dayOfMonth,
                            eventEndTime.hour,
                            eventEndTime.minute
                        )
                        
                        // Create the event
                        val newEvent = StudyEvent(
                            id = UUID.randomUUID(),
                            title = eventTitle,
                            time = startDateTime,
                            endTime = endDateTime,
                            description = eventDescription.takeIf { it.isNotEmpty() },
                            invitedFriends = emptyList(),
                            attendees = listOf(username),
                            isPublic = isPublicEvent,
                            host = username,
                            hostIsCertified = false,
                            eventType = "study"
                        )
                        
                        // Pass to caller
                        onCreateEvent(newEvent)
                        onDismiss()
                    },
                    enabled = eventTitle.isNotEmpty(),
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Create")
                }
            }
        }
        
        // This is a simplified version without actual date/time picker dialogs
        // In a real implementation, you'd show DatePickerDialog and TimePickerDialog
    }
}

// Helper Functions
fun generateDaysForMonth(yearMonth: YearMonth): List<LocalDate> {
    val firstOfMonth = yearMonth.atDay(1)
    val lastOfMonth = yearMonth.atEndOfMonth()
    
    // Find the first day of the displayed grid (last Monday of previous month or earlier)
    val firstDisplayedDay = firstOfMonth.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
    
    // Find the last day of the displayed grid (might be in the next month)
    val lastDisplayedDay = lastOfMonth.with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY))
    
    val days = mutableListOf<LocalDate>()
    var currentDay = firstDisplayedDay
    
    // Generate all days in the displayed grid
    while (!currentDay.isAfter(lastDisplayedDay)) {
        days.add(currentDay)
        currentDay = currentDay.plusDays(1)
    }
    
    return days
}

fun generateWeekDays(date: LocalDate): List<LocalDate> {
    val weekFields = WeekFields.of(Locale.getDefault())
    val weekOfYear = date.get(weekFields.weekOfWeekBasedYear())
    val firstDayOfWeek = date.with(weekFields.dayOfWeek(), 1)
    
    return (0..6).map { firstDayOfWeek.plusDays(it.toLong()) }
}

fun eventsForDate(date: LocalDate, events: List<StudyEvent>): List<StudyEvent> {
    return events.filter { event ->
        val eventDate = event.time.toLocalDate()
        val isExpired = event.endTime?.isBefore(LocalDateTime.now()) ?: false
        eventDate == date && !isExpired
    }
}

fun getEventSpans(date: LocalDate, events: List<StudyEvent>): List<EventSpan> {
    return events.mapNotNull { event ->
        val startDate = event.time.toLocalDate()
        val endDate = event.endTime?.toLocalDate() ?: return@mapNotNull null
        
        // Skip expired events (matching iOS CalendarManager logic)
        val isExpired = event.endTime?.isBefore(LocalDateTime.now()) ?: false
        if (isExpired) return@mapNotNull null
        
        // Skip events that don't span multiple days
        if (startDate == endDate) return@mapNotNull null
        
        val isStart = date == startDate
        val isEnd = date == endDate
        val isMiddle = date.isAfter(startDate) && date.isBefore(endDate)
        
        if (isStart || isEnd || isMiddle) {
            EventSpan(
                id = UUID.randomUUID(),
                event = event,
                isStart = isStart,
                isEnd = isEnd,
                isMiddle = isMiddle
            )
        } else null
    }
}

fun formatDateTime(dateTime: LocalDateTime?): String {
    return dateTime?.format(DateTimeFormatter.ofPattern("MMM d, yyyy h:mm a")) ?: ""
}

fun formatTimeRange(startTime: LocalDateTime, endTime: LocalDateTime?): String {
    val startStr = startTime.format(DateTimeFormatter.ofPattern("h:mm a"))
    return if (endTime != null) {
        val endStr = endTime.format(DateTimeFormatter.ofPattern("h:mm a"))
        "$startStr - $endStr"
    } else {
        startStr
    }
}

fun formatTime(time: java.time.LocalDateTime): String {
    val formatter = java.time.format.DateTimeFormatter.ofPattern("HH:mm")
    return time.format(formatter)
}

fun eventColor(event: StudyEvent): Color {
    // Convert string to EventType when possible
    val eventTypeString = event.eventType?.lowercase() ?: "other"
    
    return when (eventTypeString) {
        "study" -> Color(0xFF1E88E5) // Blue
        "party" -> Color(0xFF8E24AA) // Purple
        "business" -> Color(0xFFF57C00) // Orange
        "other", null -> Color(0xFF757575) // Gray
        else -> Color(0xFF757575) // Default gray for any other type
    }
} 