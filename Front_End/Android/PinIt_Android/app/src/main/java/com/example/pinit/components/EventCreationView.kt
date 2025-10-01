package com.example.pinit.components

import android.util.Log
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.pinit.models.EventType
import com.example.pinit.models.StudyEventMap
import com.example.pinit.models.UserAccountManager
import com.example.pinit.repository.EventRepository
import com.example.pinit.ui.theme.PrimaryColor
import com.example.pinit.ui.theme.SecondaryColor
import com.example.pinit.services.LocationSearchService
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import kotlinx.coroutines.MainScope

/**
 * View for creating a new event
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventCreationView(
    initialCoordinate: Pair<Double, Double>,
    accountManager: UserAccountManager,
    onClose: () -> Unit,
    onSave: (StudyEventMap) -> Unit
) {
    val scrollState = rememberScrollState()
    
    // Event state
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var startDate by remember { mutableStateOf(LocalDateTime.now()) }
    var endDate by remember { mutableStateOf(LocalDateTime.now().plusHours(1)) }
    var selectedEventType by remember { mutableStateOf(EventType.STUDY) }
    var isPublic by remember { mutableStateOf(true) }
    var invitedFriends by remember { mutableStateOf("") }
    var locationName by remember { mutableStateOf("Selected Location") }
    var coordinate by remember { mutableStateOf(initialCoordinate) }
    var maxParticipants by remember { mutableStateOf(10) }
    var isSaving by remember { mutableStateOf(false) }
    var interestTags by remember { mutableStateOf("") }
    var autoMatchingEnabled by remember { mutableStateOf(false) }
    var matchedUsers by remember { mutableStateOf(listOf<String>()) }
    var eventImages by remember { mutableStateOf(listOf<String>()) }
    
    // Date-time pickers
    var showStartDatePicker by remember { mutableStateOf(false) }
    var showStartTimePicker by remember { mutableStateOf(false) }
    var showEndDatePicker by remember { mutableStateOf(false) }
    var showEndTimePicker by remember { mutableStateOf(false) }
    
    // Show error alert
    var showErrorDialog by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf("") }
    
    // Log when coordinates change
    LaunchedEffect(coordinate) {
        Log.d("EventCreationView", "Coordinates updated: ${coordinate.first}, ${coordinate.second}")
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Create Event") },
                navigationIcon = {
                    IconButton(onClick = onClose) {
                        Icon(
                            Icons.Default.Close,
                            contentDescription = "Close"
                        )
                    }
                },
                actions = {
                    TextButton(
                        onClick = {
                            // Inline validation
                            val isValid = title.isNotBlank() && endDate.isAfter(startDate) 
                            
                            if (isValid) {
                                saveEvent(
                                    title = title,
                                    description = description,
                                    startDate = startDate,
                                    endDate = endDate,
                                    eventType = selectedEventType,
                                    isPublic = isPublic,
                                    invitedFriends = invitedFriends,
                                    coordinate = coordinate,
                                    accountManager = accountManager,
                                    onSuccess = onSave,
                                    onError = { error ->
                                        errorMessage = error
                                        showErrorDialog = true
                                    },
                                    interestTags = interestTags,
                                    autoMatchingEnabled = autoMatchingEnabled,
                                    maxParticipants = maxParticipants
                                )
                            } else {
                                errorMessage = "Please fill in all required fields"
                                showErrorDialog = true
                            }
                        },
                        enabled = !isSaving
                    ) {
                        if (isSaving) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(24.dp),
                                color = Color.White,
                                strokeWidth = 2.dp
                            )
                        } else {
                            Text("Save", color = Color.White)
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = PrimaryColor,
                    titleContentColor = Color.White,
                    navigationIconContentColor = Color.White,
                    actionIconContentColor = Color.White
                )
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            PrimaryColor.copy(alpha = 0.1f),
                            SecondaryColor.copy(alpha = 0.05f)
                        )
                    )
                )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(scrollState)
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Event Details Card
                EventDetailsCard(
                    title = title,
                    onTitleChange = { title = it },
                    description = description,
                    onDescriptionChange = { description = it },
                    selectedEventType = selectedEventType,
                    onEventTypeChange = { selectedEventType = it },
                    maxParticipants = maxParticipants,
                    onMaxParticipantsChange = { maxParticipants = it }
                )
                
                // Time Selection Card
                TimeSelectionCard(
                    startDate = startDate,
                    endDate = endDate,
                    onStartDateChange = { startDate = it },
                    onEndDateChange = { endDate = it },
                    onShowStartDatePicker = { showStartDatePicker = true },
                    onShowStartTimePicker = { showStartTimePicker = true },
                    onShowEndDatePicker = { showEndDatePicker = true },
                    onShowEndTimePicker = { showEndTimePicker = true }
                )
                
                // Location Card
                LocationCard(
                    locationName = locationName,
                    coordinate = coordinate,
                    onLocationNameChange = { locationName = it },
                    onCoordinateChange = { coordinate = it }
                )
                
                // Social Settings Card
                SocialSettingsCard(
                    isPublic = isPublic,
                    onPublicChange = { isPublic = it },
                    invitedFriends = invitedFriends,
                    onInvitedFriendsChange = { invitedFriends = it },
                    interestTags = interestTags,
                    onInterestTagsChange = { interestTags = it },
                    autoMatchingEnabled = autoMatchingEnabled,
                    onAutoMatchingEnabledChange = { autoMatchingEnabled = it }
                )
                
                Spacer(modifier = Modifier.height(16.dp))
            }
            
            if (showErrorDialog) {
                AlertDialog(
                    onDismissRequest = { showErrorDialog = false },
                    title = { Text("Error") },
                    text = { Text(errorMessage) },
                    confirmButton = {
                        Button(
                            onClick = { showErrorDialog = false }
                        ) {
                            Text("OK")
                        }
                    }
                )
            }
            
            // Date and time pickers
            if (showStartDatePicker) {
                DatePickerDialog(
                    date = startDate.toLocalDate(),
                    onDateSelected = { 
                        startDate = LocalDateTime.of(it, startDate.toLocalTime())
                        if (endDate.isBefore(startDate)) {
                            endDate = startDate.plusHours(1)
                        }
                        showStartDatePicker = false
                    },
                    onDismiss = { showStartDatePicker = false }
                )
            }
            
            if (showStartTimePicker) {
                TimePickerDialog(
                    time = startDate.toLocalTime(),
                    onTimeSelected = { 
                        startDate = LocalDateTime.of(startDate.toLocalDate(), it)
                        if (endDate.isBefore(startDate)) {
                            endDate = startDate.plusHours(1)
                        }
                        showStartTimePicker = false
                    },
                    onDismiss = { showStartTimePicker = false }
                )
            }
            
            if (showEndDatePicker) {
                DatePickerDialog(
                    date = endDate.toLocalDate(),
                    onDateSelected = { 
                        endDate = LocalDateTime.of(it, endDate.toLocalTime())
                        showEndDatePicker = false
                    },
                    onDismiss = { showEndDatePicker = false },
                    minDate = startDate.toLocalDate()
                )
            }
            
            if (showEndTimePicker) {
                TimePickerDialog(
                    time = endDate.toLocalTime(),
                    onTimeSelected = { 
                        endDate = LocalDateTime.of(endDate.toLocalDate(), it)
                        showEndTimePicker = false
                    },
                    onDismiss = { showEndTimePicker = false }
                )
            }
        }
    }
}

@Composable
fun EventDetailsCard(
    title: String,
    onTitleChange: (String) -> Unit,
    description: String,
    onDescriptionChange: (String) -> Unit,
    selectedEventType: EventType,
    onEventTypeChange: (EventType) -> Unit,
    maxParticipants: Int,
    onMaxParticipantsChange: (Int) -> Unit
) {
    SettingsCard(
        title = "Event Details",
        icon = Icons.Default.EventNote
    ) {
        Column(
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Title input
            OutlinedTextField(
                value = title,
                onValueChange = onTitleChange,
                label = { Text("Event Title") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                leadingIcon = {
                    Icon(Icons.Default.Title, contentDescription = "Title")
                }
            )
            
            // Description input
            OutlinedTextField(
                value = description,
                onValueChange = onDescriptionChange,
                label = { Text("Description") },
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = 120.dp),
                leadingIcon = {
                    Icon(Icons.Default.Description, contentDescription = "Description")
                },
                maxLines = 5
            )
            
            // Event Type selection
            Column {
                Text(
                    text = "Event Type",
                    style = MaterialTheme.typography.labelMedium
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    EventType.values().forEach { eventType ->
                        LegacyEventTypeChip(
                            type = eventType,
                            selected = selectedEventType == eventType,
                            onClick = { onEventTypeChange(eventType) }
                        )
                    }
                }
            }
            
            // Max participants
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Max Participants:",
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.weight(1f)
                )
                
                IconButton(
                    onClick = { onMaxParticipantsChange(maxOf(2, maxParticipants - 1)) }
                ) {
                    Icon(Icons.Default.Remove, contentDescription = "Decrease")
                }
                
                Text(
                    text = "$maxParticipants",
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.width(40.dp),
                    textAlign = TextAlign.Center
                )
                
                IconButton(
                    onClick = { onMaxParticipantsChange(maxParticipants + 1) }
                ) {
                    Icon(Icons.Default.Add, contentDescription = "Increase")
                }
            }
        }
    }
}

@Composable
fun TimeSelectionCard(
    startDate: LocalDateTime,
    endDate: LocalDateTime,
    onStartDateChange: (LocalDateTime) -> Unit,
    onEndDateChange: (LocalDateTime) -> Unit,
    onShowStartDatePicker: () -> Unit,
    onShowStartTimePicker: () -> Unit,
    onShowEndDatePicker: () -> Unit,
    onShowEndTimePicker: () -> Unit
) {
    SettingsCard(
        title = "Date & Time",
        icon = Icons.Default.Schedule
    ) {
        Column(
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Start time
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Starts",
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.width(60.dp)
                )
                
                Spacer(modifier = Modifier.width(8.dp))
                
                // Date selector
                OutlinedButton(
                    onClick = onShowStartDatePicker,
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = startDate.format(DateTimeFormatter.ofPattern("MMM dd, yyyy")),
                        fontSize = 14.sp
                    )
                }
                
                Spacer(modifier = Modifier.width(8.dp))
                
                // Time selector
                OutlinedButton(
                    onClick = onShowStartTimePicker,
                    modifier = Modifier.width(100.dp)
                ) {
                    Text(
                        text = startDate.format(DateTimeFormatter.ofPattern("HH:mm")),
                        fontSize = 14.sp
                    )
                }
            }
            
            // End time
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Ends",
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.width(60.dp)
                )
                
                Spacer(modifier = Modifier.width(8.dp))
                
                // Date selector
                OutlinedButton(
                    onClick = onShowEndDatePicker,
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = endDate.format(DateTimeFormatter.ofPattern("MMM dd, yyyy")),
                        fontSize = 14.sp
                    )
                }
                
                Spacer(modifier = Modifier.width(8.dp))
                
                // Time selector
                OutlinedButton(
                    onClick = onShowEndTimePicker,
                    modifier = Modifier.width(100.dp)
                ) {
                    Text(
                        text = endDate.format(DateTimeFormatter.ofPattern("HH:mm")),
                        fontSize = 14.sp
                    )
                }
            }
            
            // Duration info
            Text(
                text = "Duration: ${calculateDuration(startDate, endDate)}",
                style = MaterialTheme.typography.bodySmall,
                color = Color.Gray,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.End
            )
        }
    }
}

@Composable
fun LocationCard(
    locationName: String,
    coordinate: Pair<Double, Double>,
    onLocationNameChange: (String) -> Unit,
    onCoordinateChange: (Pair<Double, Double>) -> Unit
) {
    val context = androidx.compose.ui.platform.LocalContext.current
    
    // Location search functionality
    val locationSearchService = remember { com.example.pinit.services.LocationSearchService(context) }
    val coroutineScope = rememberCoroutineScope()
    
    // State for location suggestions
    var searchQuery by remember { mutableStateOf("") } // Start with empty search
    var selectedLocation by remember { mutableStateOf(locationName) } // Track selected location separately
    var locationSuggestions by remember { mutableStateOf<List<com.example.pinit.services.LocationSuggestion>>(emptyList()) }
    var isSearching by remember { mutableStateOf(false) }
    var showSuggestions by remember { mutableStateOf(false) }
    
    // Update suggestions when search query changes
    LaunchedEffect(searchQuery) {
        if (searchQuery.isNotBlank()) {
            isSearching = true
            try {
                val suggestions = locationSearchService.searchLocations(searchQuery)
                locationSuggestions = suggestions
                showSuggestions = suggestions.isNotEmpty()
            } catch (e: Exception) {
                Log.e("LocationCard", "Error searching locations: ${e.message}", e)
            } finally {
                isSearching = false
            }
        } else {
            locationSuggestions = emptyList()
            showSuggestions = false
        }
    }
    
    SettingsCard(
        title = "Location",
        icon = Icons.Default.LocationOn
    ) {
        Column(
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Current selected location display (if any)
            if (selectedLocation.isNotBlank() && selectedLocation != "Selected Location") {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 8.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                    )
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = selectedLocation,
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.SemiBold
                            )
                            Text(
                                text = "Coordinates: ${String.format("%.4f", coordinate.second)}, ${String.format("%.4f", coordinate.first)}",
                                style = MaterialTheme.typography.bodySmall,
                                color = Color.Gray
                            )
                        }
                        IconButton(
                            onClick = {
                                selectedLocation = ""
                                onLocationNameChange("")
                                searchQuery = ""
                            }
                        ) {
                            Icon(
                                Icons.Default.Close, 
                                contentDescription = "Clear location",
                                tint = MaterialTheme.colorScheme.error
                            )
                        }
                    }
                }
            }
            
            // Location search field with suggestions
            Box(modifier = Modifier.fillMaxWidth()) {
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { 
                        searchQuery = it
                    },
                    placeholder = { Text("Enter a location...") },
                    label = { Text("Search for a place") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    leadingIcon = {
                        Icon(Icons.Default.Search, contentDescription = "Search")
                    },
                    trailingIcon = {
                        if (isSearching) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(24.dp),
                                strokeWidth = 2.dp
                            )
                        } else if (searchQuery.isNotBlank()) {
                            IconButton(onClick = { searchQuery = "" }) {
                                Icon(Icons.Default.Clear, contentDescription = "Clear search")
                            }
                        }
                    }
                )
                
                // Show suggestions dropdown when there are suggestions
                if (showSuggestions) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 60.dp) // Position below the text field
                    ) {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.surface
                            )
                        ) {
                            Column(modifier = Modifier.fillMaxWidth()) {
                                locationSuggestions.forEach { suggestion ->
                                    SuggestionItem(
                                        suggestion = suggestion,
                                        onClick = {
                                            // When a suggestion is selected
                                            coroutineScope.launch {
                                                try {
                                                    // Get detailed location information
                                                    val locationDetail = locationSearchService.getLocationDetails(suggestion)
                                                    
                                                    // Update location name and coordinate
                                                    selectedLocation = locationDetail.name
                                                    onLocationNameChange(locationDetail.name)
                                                    searchQuery = "" // Clear search after selection
                                                    
                                                    if (locationDetail.coordinates.first != 0.0 || 
                                                        locationDetail.coordinates.second != 0.0) {
                                                        // Update coordinate in parent component
                                                        onCoordinateChange(locationDetail.coordinates)
                                                        Log.d("LocationCard", "Selected coordinates: " +
                                                              "${locationDetail.coordinates.first}, ${locationDetail.coordinates.second}")
                                                    }
                                                    
                                                    // Hide suggestions
                                                    showSuggestions = false
                                                } catch (e: Exception) {
                                                    Log.e("LocationCard", "Error getting location details: ${e.message}", e)
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            }
            
            // Map preview placeholder
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(150.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(Color.LightGray.copy(alpha = 0.5f)),
                contentAlignment = Alignment.Center
            ) {
                if (selectedLocation.isBlank() || selectedLocation == "Selected Location") {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Default.Map,
                            contentDescription = "Map Preview",
                            modifier = Modifier.size(48.dp),
                            tint = Color.Gray
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            "Search for a location to see it on the map",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.Gray,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(horizontal = 16.dp)
                        )
                    }
                } else {
                    // In a production app, you would show a real map preview here
                    Icon(
                        Icons.Default.LocationOn,
                        contentDescription = "Location marker",
                        modifier = Modifier.size(48.dp),
                        tint = PrimaryColor
                    )
                }
            }
        }
    }
}

/**
 * Individual location suggestion item
 */
@Composable
fun SuggestionItem(
    suggestion: com.example.pinit.services.LocationSuggestion,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            Icons.Default.LocationOn,
            contentDescription = "Location",
            tint = PrimaryColor,
            modifier = Modifier.padding(end = 12.dp)
        )
        
        Column {
            Text(
                text = suggestion.name,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold
            )
            
            if (suggestion.address.isNotBlank()) {
                Text(
                    text = suggestion.address,
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Gray
                )
            }
        }
    }
}

@Composable
fun SocialSettingsCard(
    isPublic: Boolean,
    onPublicChange: (Boolean) -> Unit,
    invitedFriends: String,
    onInvitedFriendsChange: (String) -> Unit,
    interestTags: String,
    onInterestTagsChange: (String) -> Unit,
    autoMatchingEnabled: Boolean,
    onAutoMatchingEnabledChange: (Boolean) -> Unit
) {
    SettingsCard(
        title = "Social Settings",
        icon = Icons.Default.Share
    ) {
        Column(
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Public/Private toggle
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Public Event",
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.weight(1f)
                )
                
                Switch(
                    checked = isPublic,
                    onCheckedChange = onPublicChange,
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = PrimaryColor,
                        checkedTrackColor = PrimaryColor.copy(alpha = 0.5f)
                    )
                )
            }
            
            if (!isPublic) {
                Text(
                    text = "Only invited friends can see this event",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Gray
                )
            }
            
            // Interest tags field
            OutlinedTextField(
                value = interestTags,
                onValueChange = onInterestTagsChange,
                label = { Text("Interest Tags (comma-separated)") },
                modifier = Modifier.fillMaxWidth(),
                leadingIcon = {
                    Icon(CustomIcons.Interests, contentDescription = "Interests")
                },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Text,
                    imeAction = ImeAction.Next
                )
            )
            
            // Auto-matching toggle
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = "Auto-Match Participants",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Text(
                        text = "Find and invite participants based on interests and skills",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.Gray
                    )
                }
                
                Switch(
                    checked = autoMatchingEnabled,
                    onCheckedChange = onAutoMatchingEnabledChange,
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = PrimaryColor,
                        checkedTrackColor = PrimaryColor.copy(alpha = 0.5f)
                    )
                )
            }
            
            // Invited friends
            OutlinedTextField(
                value = invitedFriends,
                onValueChange = onInvitedFriendsChange,
                label = { Text("Invite Friends (comma-separated)") },
                modifier = Modifier.fillMaxWidth(),
                leadingIcon = {
                    Icon(Icons.Default.People, contentDescription = "Friends")
                },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Text,
                    imeAction = ImeAction.Done
                )
            )
        }
    }
}

@Composable
fun SettingsCard(
    title: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    content: @Composable () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Card header
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    icon,
                    contentDescription = null,
                    tint = PrimaryColor
                )
                
                Spacer(modifier = Modifier.width(8.dp))
                
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = PrimaryColor
                )
            }
            
            Divider()
            
            // Card content
            content()
        }
    }
}

@Composable
fun LegacyEventTypeChip(
    type: EventType,
    selected: Boolean,
    onClick: () -> Unit
) {
    val backgroundColor = when (type) {
        EventType.STUDY -> if (selected) Color(0xFF007AFF) else Color(0xFF007AFF).copy(alpha = 0.2f)
        EventType.PARTY -> if (selected) Color(0xFFAF52DE) else Color(0xFFAF52DE).copy(alpha = 0.2f)
        EventType.BUSINESS -> if (selected) Color(0xFF5856D6) else Color(0xFF5856D6).copy(alpha = 0.2f)
        EventType.CULTURAL -> if (selected) Color(0xFFFF9500) else Color(0xFFFF9500).copy(alpha = 0.2f)
        EventType.ACADEMIC -> if (selected) Color(0xFF34C759) else Color(0xFF34C759).copy(alpha = 0.2f)
        EventType.NETWORKING -> if (selected) Color(0xFFFF2D92) else Color(0xFFFF2D92).copy(alpha = 0.2f)
        EventType.SOCIAL -> if (selected) Color(0xFFFF3B30) else Color(0xFFFF3B30).copy(alpha = 0.2f)
        EventType.LANGUAGE_EXCHANGE -> if (selected) Color(0xFF5AC8FA) else Color(0xFF5AC8FA).copy(alpha = 0.2f)
        EventType.OTHER -> if (selected) Color(0xFF8E8E93) else Color(0xFF8E8E93).copy(alpha = 0.2f)
    }
    
    val textColor = if (selected) Color.White else Color.Black
    
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(16.dp))
            .background(backgroundColor)
            .clickable { onClick() }
            .padding(horizontal = 12.dp, vertical = 8.dp)
    ) {
        Text(
            text = type.name.capitalize(),
            color = textColor,
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DatePickerDialog(
    date: java.time.LocalDate,
    onDateSelected: (java.time.LocalDate) -> Unit,
    onDismiss: () -> Unit,
    minDate: java.time.LocalDate? = null
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Select Date") },
        text = {
            // In a real app, you would use a DatePicker from Material3
            // For now, we'll use a simple year/month/day selection
            Column {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Year
                    OutlinedTextField(
                        value = date.year.toString(),
                        onValueChange = { /* No direct edit */ },
                        modifier = Modifier.weight(1f),
                        label = { Text("Year") },
                        readOnly = true,
                        trailingIcon = {
                            Row {
                                IconButton(onClick = {
                                    val newDate = date.minusYears(1)
                                    if (minDate == null || !newDate.isBefore(minDate)) {
                                        onDateSelected(newDate)
                                    }
                                }) {
                                    Icon(Icons.Default.Remove, "Previous Year")
                                }
                                IconButton(onClick = {
                                    onDateSelected(date.plusYears(1))
                                }) {
                                    Icon(Icons.Default.Add, "Next Year")
                                }
                            }
                        }
                    )
                }
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Month
                    OutlinedTextField(
                        value = date.month.toString(),
                        onValueChange = { /* No direct edit */ },
                        modifier = Modifier.weight(1f),
                        label = { Text("Month") },
                        readOnly = true,
                        trailingIcon = {
                            Row {
                                IconButton(onClick = {
                                    val newDate = date.minusMonths(1)
                                    if (minDate == null || !newDate.isBefore(minDate)) {
                                        onDateSelected(newDate)
                                    }
                                }) {
                                    Icon(Icons.Default.Remove, "Previous Month")
                                }
                                IconButton(onClick = {
                                    onDateSelected(date.plusMonths(1))
                                }) {
                                    Icon(Icons.Default.Add, "Next Month")
                                }
                            }
                        }
                    )
                    
                    // Day
                    OutlinedTextField(
                        value = date.dayOfMonth.toString(),
                        onValueChange = { /* No direct edit */ },
                        modifier = Modifier.weight(1f),
                        label = { Text("Day") },
                        readOnly = true,
                        trailingIcon = {
                            Row {
                                IconButton(onClick = {
                                    val newDate = date.minusDays(1)
                                    if (minDate == null || !newDate.isBefore(minDate)) {
                                        onDateSelected(newDate)
                                    }
                                }) {
                                    Icon(Icons.Default.Remove, "Previous Day")
                                }
                                IconButton(onClick = {
                                    onDateSelected(date.plusDays(1))
                                }) {
                                    Icon(Icons.Default.Add, "Next Day")
                                }
                            }
                        }
                    )
                }
            }
        },
        confirmButton = {
            Button(onClick = {
                onDateSelected(date)
                onDismiss()
            }) {
                Text("OK")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TimePickerDialog(
    time: LocalTime,
    onTimeSelected: (LocalTime) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Select Time") },
        text = {
            // Simple hour/minute selection
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Hour
                OutlinedTextField(
                    value = String.format("%02d", time.hour),
                    onValueChange = { /* No direct edit */ },
                    modifier = Modifier.weight(1f),
                    label = { Text("Hour") },
                    readOnly = true,
                    trailingIcon = {
                        Column {
                            IconButton(onClick = {
                                val newHour = (time.hour + 23) % 24
                                onTimeSelected(LocalTime.of(newHour, time.minute))
                            }) {
                                Icon(Icons.Default.KeyboardArrowUp, "Up Hour")
                            }
                            IconButton(onClick = {
                                val newHour = (time.hour + 1) % 24
                                onTimeSelected(LocalTime.of(newHour, time.minute))
                            }) {
                                Icon(Icons.Default.KeyboardArrowDown, "Down Hour")
                            }
                        }
                    }
                )
                
                Text(
                    text = ":",
                    modifier = Modifier.padding(top = 20.dp),
                    fontSize = 24.sp
                )
                
                // Minute
                OutlinedTextField(
                    value = String.format("%02d", time.minute),
                    onValueChange = { /* No direct edit */ },
                    modifier = Modifier.weight(1f),
                    label = { Text("Minute") },
                    readOnly = true,
                    trailingIcon = {
                        Column {
                            IconButton(onClick = {
                                val newMinute = (time.minute + 55) % 60
                                onTimeSelected(LocalTime.of(time.hour, newMinute))
                            }) {
                                Icon(Icons.Default.KeyboardArrowUp, "Up Minute")
                            }
                            IconButton(onClick = {
                                val newMinute = (time.minute + 5) % 60
                                onTimeSelected(LocalTime.of(time.hour, newMinute))
                            }) {
                                Icon(Icons.Default.KeyboardArrowDown, "Down Minute")
                            }
                        }
                    }
                )
            }
        },
        confirmButton = {
            Button(onClick = {
                onTimeSelected(time)
                onDismiss()
            }) {
                Text("OK")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

// Helper functions
private fun String.capitalize(): String {
    return this.replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }
}

private fun calculateDuration(start: LocalDateTime, end: LocalDateTime): String {
    val hours = java.time.Duration.between(start, end).toHours()
    val minutes = java.time.Duration.between(start, end).toMinutes() % 60
    
    return when {
        hours > 0 && minutes > 0 -> "${hours}h ${minutes}m"
        hours > 0 -> "${hours}h"
        else -> "${minutes}m"
    }
}

private fun saveEvent(
    title: String,
    description: String,
    startDate: LocalDateTime,
    endDate: LocalDateTime,
    eventType: EventType,
    isPublic: Boolean,
    invitedFriends: String,
    coordinate: Pair<Double, Double>,
    accountManager: UserAccountManager,
    onSuccess: (StudyEventMap) -> Unit,
    onError: (String) -> Unit,
    interestTags: String = "",
    autoMatchingEnabled: Boolean = false,
    maxParticipants: Int = 10
) {
    try {
        // Get the username from the account manager
        val username = accountManager.currentUser
        
        // Check if the user is logged in
        if (username.isNullOrEmpty()) {
            Log.e("EventCreation", "Cannot create event: No user is logged in")
            onError("You must be logged in to create an event")
            return
        }
        
        Log.d("EventCreation", "Creating event with host username: $username")
        
        // Parse invited friends list, removing empty entries and whitespace
        val friendsList = invitedFriends.split(",")
            .map { it.trim() }
            .filter { it.isNotEmpty() && it != username } // Filter out empty strings and self
        
        // Parse interest tags list
        val tagsList = interestTags.split(",")
            .map { it.trim() }
            .filter { it.isNotEmpty() }
        
        Log.d("EventCreation", "Creating event with invited friends: $friendsList")
        Log.d("EventCreation", "Interest tags: $tagsList")
        Log.d("EventCreation", "Auto-matching enabled: $autoMatchingEnabled")
        
        // Create a temporary event object
        val event = StudyEventMap(
            id = java.util.UUID.randomUUID().toString(),
            title = title,
            description = description,
            time = startDate,
            endTime = endDate,
            coordinate = coordinate,
            eventType = eventType,
            isPublic = isPublic,
            attendees = 1, // Start with one attendee (the creator)
            host = username, // Set host to the logged-in user
            hostIsCertified = accountManager.isCertified, // Use the user's actual certification status
            invitedFriends = friendsList,
            interestTags = tagsList,
            maxParticipants = maxParticipants,
            autoMatchingEnabled = autoMatchingEnabled
        )
        
        Log.d("EventCreation", "Event object created with host: ${event.host}")
        
        // Create the event using the repository
        val eventRepository = com.example.pinit.repository.EventRepository()
        
        // Use kotlinx.coroutines.MainScope() to launch a coroutine
        kotlinx.coroutines.MainScope().launch {
            eventRepository.createEvent(event).collect { result ->
                result.fold(
                    onSuccess = { createdEvent ->
                        Log.d("EventCreation", "Successfully created event with ID: ${createdEvent.id}, host: ${createdEvent.host}")
                        
                        // The backend already handles auto-matching automatically
                        // when autoMatchingEnabled=true during event creation
                        
                        // If we successfully created the event, notify invited friends
                        if (friendsList.isNotEmpty()) {
                            Log.d("EventCreation", "Event created, inviting friends: $friendsList")
                        }
                        
                        // Return the successfully created event
                        onSuccess(createdEvent)
                    },
                    onFailure = { error ->
                        Log.e("EventCreation", "Failed to create event", error)
                        onError("Failed to save event: ${error.message}")
                    }
                )
            }
        }
    } catch (e: Exception) {
        Log.e("EventCreation", "Error saving event", e)
        onError("Failed to save event: ${e.message}")
    }
} 