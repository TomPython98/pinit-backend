package com.example.pinit.components

import android.util.Log
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
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
import com.example.pinit.ui.theme.*
import com.example.pinit.services.LocationSearchService
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import kotlinx.coroutines.MainScope

/**
 * Enhanced Event Creation View matching iOS design with tabbed interface
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EnhancedEventCreationView(
    initialCoordinate: Pair<Double, Double>,
    accountManager: UserAccountManager,
    onClose: () -> Unit,
    onSave: (StudyEventMap) -> Unit
) {
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
    var interestTags by remember { mutableStateOf(listOf<String>()) }
    var autoMatchingEnabled by remember { mutableStateOf(false) }
    var matchedUsers by remember { mutableStateOf(listOf<String>()) }
    var eventImages by remember { mutableStateOf(listOf<String>()) }
    
    // Tab state
    val pagerState = rememberPagerState(pageCount = { 4 })
    var currentTab by remember { mutableStateOf(0) }
    
    // Location search
    var locationSearchQuery by remember { mutableStateOf("") }
    var locationSearchResults by remember { mutableStateOf(listOf<String>()) }
    
    // Date-time pickers
    var showStartDatePicker by remember { mutableStateOf(false) }
    var showStartTimePicker by remember { mutableStateOf(false) }
    var showEndDatePicker by remember { mutableStateOf(false) }
    var showEndTimePicker by remember { mutableStateOf(false) }
    
    // Show error alert
    var showErrorDialog by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf("") }
    
    // Tag input
    var newTag by remember { mutableStateOf("") }
    
    // Log when coordinates change
    LaunchedEffect(coordinate) {
        Log.d("EnhancedEventCreationView", "Coordinates updated: ${coordinate.first}, ${coordinate.second}")
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Create Event",
                        color = TextLight,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onClose) {
                        Icon(
                            Icons.Filled.Close,
                            contentDescription = "Close",
                            tint = TextLight
                        )
                    }
                },
                actions = {
                    if (currentTab == 3) {
                        Button(
                            onClick = {
                                createEvent(
                                    title = title,
                                    description = description,
                                    startDate = startDate,
                                    endDate = endDate,
                                    eventType = selectedEventType,
                                    isPublic = isPublic,
                                    invitedFriends = invitedFriends,
                                    coordinate = coordinate,
                                    maxParticipants = maxParticipants,
                                    interestTags = interestTags,
                                    autoMatchingEnabled = autoMatchingEnabled,
                                    matchedUsers = matchedUsers,
                                    eventImages = eventImages,
                                    accountManager = accountManager,
                                    onSuccess = onSave,
                                    onError = { error ->
                                        errorMessage = error
                                        showErrorDialog = true
                                    }
                                )
                            },
                            enabled = !isSaving && title.isNotEmpty(),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = BrandPrimary
                            ),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            if (isSaving) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(16.dp),
                                    color = TextLight,
                                    strokeWidth = 2.dp
                                )
                            } else {
                                Text(
                                    text = "Create",
                                    color = TextLight,
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.Medium
                                )
                            }
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = BrandPrimary
                )
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(BgSurface)
        ) {
            Column(
                modifier = Modifier.fillMaxSize()
            ) {
                // Tab indicators
                TabIndicators(
                    currentTab = currentTab,
                    onTabClick = { tab ->
                        currentTab = tab
                    }
                )
                
                // Content
                HorizontalPager(
                    state = pagerState,
                    modifier = Modifier.weight(1f)
                ) { page ->
                    when (page) {
                        0 -> BasicInfoTab(
                            title = title,
                            onTitleChange = { title = it },
                            description = description,
                            onDescriptionChange = { description = it },
                            selectedEventType = selectedEventType,
                            onEventTypeChange = { selectedEventType = it },
                            maxParticipants = maxParticipants,
                            onMaxParticipantsChange = { maxParticipants = it }
                        )
                        1 -> LocationTimeTab(
                            startDate = startDate,
                            endDate = endDate,
                            onStartDateChange = { startDate = it },
                            onEndDateChange = { endDate = it },
                            locationName = locationName,
                            onLocationNameChange = { locationName = it },
                            coordinate = coordinate,
                            onCoordinateChange = { coordinate = it },
                            locationSearchQuery = locationSearchQuery,
                            onLocationSearchQueryChange = { locationSearchQuery = it },
                            locationSearchResults = locationSearchResults,
                            onLocationSearchResultsChange = { locationSearchResults = it }
                        )
                        2 -> SocialTagsTab(
                            isPublic = isPublic,
                            onIsPublicChange = { isPublic = it },
                            invitedFriends = invitedFriends,
                            onInvitedFriendsChange = { invitedFriends = it },
                            autoMatchingEnabled = autoMatchingEnabled,
                            onAutoMatchingEnabledChange = { autoMatchingEnabled = it },
                            maxParticipants = maxParticipants,
                            onMaxParticipantsChange = { maxParticipants = it },
                            interestTags = interestTags,
                            onInterestTagsChange = { interestTags = it },
                            newTag = newTag,
                            onNewTagChange = { newTag = it }
                        )
                        3 -> ReviewTab(
                            title = title,
                            description = description,
                            selectedEventType = selectedEventType,
                            startDate = startDate,
                            endDate = endDate,
                            locationName = locationName,
                            coordinate = coordinate,
                            isPublic = isPublic,
                            invitedFriends = invitedFriends,
                            maxParticipants = maxParticipants,
                            autoMatchingEnabled = autoMatchingEnabled,
                            interestTags = interestTags
                        )
                    }
                }
                
                // Navigation buttons
                NavigationButtons(
                    currentTab = currentTab,
                    onPrevious = {
                        if (currentTab > 0) {
                            currentTab--
                        }
                    },
                    onNext = {
                        if (currentTab < 3) {
                            currentTab++
                        }
                    },
                    canProceed = when (currentTab) {
                        0 -> title.isNotEmpty()
                        1 -> true
                        2 -> true
                        3 -> true
                        else -> false
                    }
                )
            }
        }
    }
    
    // Error dialog
    if (showErrorDialog) {
        AlertDialog(
            onDismissRequest = { showErrorDialog = false },
            title = { Text("Error") },
            text = { Text(errorMessage) },
            confirmButton = {
                TextButton(onClick = { showErrorDialog = false }) {
                    Text("OK")
                }
            }
        )
    }
}

@Composable
fun TabIndicators(
    currentTab: Int,
    onTabClick: (Int) -> Unit
) {
    val tabs = listOf("Basic Info", "Location & Time", "Social & Tags", "Review")
    
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(BgCard)
            .padding(16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        tabs.forEachIndexed { index, tab ->
            TabIndicator(
                text = tab,
                isSelected = currentTab == index,
                onClick = { onTabClick(index) }
            )
        }
    }
}

@Composable
fun TabIndicator(
    text: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val backgroundColor by animateFloatAsState(
        targetValue = if (isSelected) 1f else 0f,
        animationSpec = tween(300),
        label = "background"
    )
    
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(20.dp))
            .background(
                if (isSelected) BrandPrimary else BgSecondary
            )
            .clickable { onClick() }
            .padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        Text(
            text = text,
            color = if (isSelected) TextLight else TextPrimary,
            fontSize = 14.sp,
            fontWeight = if (isSelected) FontWeight.Medium else FontWeight.Normal
        )
    }
}

@Composable
fun BasicInfoTab(
    title: String,
    onTitleChange: (String) -> Unit,
    description: String,
    onDescriptionChange: (String) -> Unit,
    selectedEventType: EventType,
    onEventTypeChange: (EventType) -> Unit,
    maxParticipants: Int,
    onMaxParticipantsChange: (Int) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Event Details Card
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = BgCard),
            shape = RoundedCornerShape(16.dp),
            elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
        ) {
            Column(
                modifier = Modifier.padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Filled.EventNote,
                        contentDescription = "Event",
                        modifier = Modifier.size(20.dp),
                        tint = BrandPrimary
                    )
                    
                    Spacer(modifier = Modifier.width(12.dp))
                    
                    Text(
                        text = "Event Details",
                        color = TextPrimary,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }
                
                // Title
                OutlinedTextField(
                    value = title,
                    onValueChange = onTitleChange,
                    label = { Text("Event Title") },
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = BrandPrimary,
                        unfocusedBorderColor = Divider
                    ),
                    shape = RoundedCornerShape(12.dp)
                )
                
                // Description
                OutlinedTextField(
                    value = description,
                    onValueChange = onDescriptionChange,
                    label = { Text("Description") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 3,
                    maxLines = 5,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = BrandPrimary,
                        unfocusedBorderColor = Divider
                    ),
                    shape = RoundedCornerShape(12.dp)
                )
                
                // Event Type
                Text(
                    text = "Event Type",
                    color = TextPrimary,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
                
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(EventType.values()) { type ->
                        EnhancedEventTypeChip(
                            eventType = type,
                            isSelected = selectedEventType == type,
                            onClick = { onEventTypeChange(type) }
                        )
                    }
                }
                
                // Max Participants
                Text(
                    text = "Max Participants: $maxParticipants",
                    color = TextPrimary,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
                
                Slider(
                    value = maxParticipants.toFloat(),
                    onValueChange = { onMaxParticipantsChange(it.toInt()) },
                    valueRange = 2f..50f,
                    colors = SliderDefaults.colors(
                        thumbColor = BrandPrimary,
                        activeTrackColor = BrandPrimary,
                        inactiveTrackColor = Divider
                    )
                )
            }
        }
    }
}

@Composable
fun EnhancedEventTypeChip(
    eventType: EventType,
    isSelected: Boolean,
    onClick: () -> Unit
) {
        val backgroundColor = when (eventType) {
            EventType.STUDY -> if (isSelected) Color(0xFF007AFF) else Color(0xFF007AFF).copy(alpha = 0.2f)
            EventType.PARTY -> if (isSelected) Color(0xFFAF52DE) else Color(0xFFAF52DE).copy(alpha = 0.2f)
            EventType.BUSINESS -> if (isSelected) Color(0xFF5856D6) else Color(0xFF5856D6).copy(alpha = 0.2f)
            EventType.CULTURAL -> if (isSelected) Color(0xFFFF9500) else Color(0xFFFF9500).copy(alpha = 0.2f)
            EventType.ACADEMIC -> if (isSelected) Color(0xFF34C759) else Color(0xFF34C759).copy(alpha = 0.2f)
            EventType.NETWORKING -> if (isSelected) Color(0xFFFF2D92) else Color(0xFFFF2D92).copy(alpha = 0.2f)
            EventType.SOCIAL -> if (isSelected) Color(0xFFFF3B30) else Color(0xFFFF3B30).copy(alpha = 0.2f)
            EventType.LANGUAGE_EXCHANGE -> if (isSelected) Color(0xFF5AC8FA) else Color(0xFF5AC8FA).copy(alpha = 0.2f)
            EventType.OTHER -> if (isSelected) Color(0xFF8E8E93) else Color(0xFF8E8E93).copy(alpha = 0.2f)
        }
    
    val textColor = if (isSelected) Color.White else Color.Black
    
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(20.dp))
            .background(backgroundColor)
            .clickable { onClick() }
            .padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        Text(
            text = eventType.displayName,
            color = textColor,
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
fun LocationTimeTab(
    startDate: LocalDateTime,
    endDate: LocalDateTime,
    onStartDateChange: (LocalDateTime) -> Unit,
    onEndDateChange: (LocalDateTime) -> Unit,
    locationName: String,
    onLocationNameChange: (String) -> Unit,
    coordinate: Pair<Double, Double>,
    onCoordinateChange: (Pair<Double, Double>) -> Unit,
    locationSearchQuery: String,
    onLocationSearchQueryChange: (String) -> Unit,
    locationSearchResults: List<String>,
    onLocationSearchResultsChange: (List<String>) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Date & Time Card
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = BgCard),
            shape = RoundedCornerShape(16.dp),
            elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
        ) {
            Column(
                modifier = Modifier.padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Filled.CalendarToday,
                        contentDescription = "Calendar",
                        modifier = Modifier.size(20.dp),
                        tint = BrandPrimary
                    )
                    
                    Spacer(modifier = Modifier.width(12.dp))
                    
                    Text(
                        text = "Date & Time",
                        color = TextPrimary,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }
                
                // Start Date/Time
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = "Start",
                            color = TextSecondary,
                            fontSize = 14.sp
                        )
                        Text(
                            text = "${startDate.dayOfMonth}/${startDate.monthValue}/${startDate.year}",
                            color = TextPrimary,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = "${startDate.hour}:${startDate.minute.toString().padStart(2, '0')}",
                            color = TextSecondary,
                            fontSize = 14.sp
                        )
                    }
                    
                    Button(
                        onClick = { /* TODO: Show date/time picker */ },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = BrandPrimary.copy(alpha = 0.1f)
                        ),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text(
                            text = "Change",
                            color = BrandPrimary,
                            fontSize = 12.sp
                        )
                    }
                }
                
                // End Date/Time
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = "End",
                            color = TextSecondary,
                            fontSize = 14.sp
                        )
                        Text(
                            text = "${endDate.dayOfMonth}/${endDate.monthValue}/${endDate.year}",
                            color = TextPrimary,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = "${endDate.hour}:${endDate.minute.toString().padStart(2, '0')}",
                            color = TextSecondary,
                            fontSize = 14.sp
                        )
                    }
                    
                    Button(
                        onClick = { /* TODO: Show date/time picker */ },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = BrandPrimary.copy(alpha = 0.1f)
                        ),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text(
                            text = "Change",
                            color = BrandPrimary,
                            fontSize = 12.sp
                        )
                    }
                }
            }
        }
        
        // Location Card
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = BgCard),
            shape = RoundedCornerShape(16.dp),
            elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
        ) {
            Column(
                modifier = Modifier.padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Filled.LocationOn,
                        contentDescription = "Location",
                        modifier = Modifier.size(20.dp),
                        tint = BrandPrimary
                    )
                    
                    Spacer(modifier = Modifier.width(12.dp))
                    
                    Text(
                        text = "Event Location",
                        color = TextPrimary,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }
                
                // Location search
                OutlinedTextField(
                    value = locationSearchQuery,
                    onValueChange = onLocationSearchQueryChange,
                    label = { Text("Search for a location...") },
                    modifier = Modifier.fillMaxWidth(),
                    leadingIcon = {
                        Icon(
                            Icons.Filled.Search,
                            contentDescription = "Search",
                            tint = TextMuted
                        )
                    },
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = BrandPrimary,
                        unfocusedBorderColor = Divider
                    ),
                    shape = RoundedCornerShape(12.dp)
                )
                
                // Selected location
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Filled.Place,
                        contentDescription = "Place",
                        modifier = Modifier.size(16.dp),
                        tint = BrandWarning
                    )
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    Text(
                        text = locationName,
                        color = TextSecondary,
                        fontSize = 14.sp
                    )
                }
                
                Text(
                    text = "Coordinates: ${String.format("%.4f", coordinate.first)}, ${String.format("%.4f", coordinate.second)}",
                    color = TextMuted,
                    fontSize = 12.sp
                )
            }
        }
    }
}

@Composable
fun SocialTagsTab(
    isPublic: Boolean,
    onIsPublicChange: (Boolean) -> Unit,
    invitedFriends: String,
    onInvitedFriendsChange: (String) -> Unit,
    autoMatchingEnabled: Boolean,
    onAutoMatchingEnabledChange: (Boolean) -> Unit,
    maxParticipants: Int,
    onMaxParticipantsChange: (Int) -> Unit,
    interestTags: List<String>,
    onInterestTagsChange: (List<String>) -> Unit,
    newTag: String,
    onNewTagChange: (String) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Privacy Card
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = BgCard),
            shape = RoundedCornerShape(16.dp),
            elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
        ) {
            Column(
                modifier = Modifier.padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Filled.Security,
                        contentDescription = "Privacy",
                        modifier = Modifier.size(20.dp),
                        tint = BrandPrimary
                    )
                    
                    Spacer(modifier = Modifier.width(12.dp))
                    
                    Text(
                        text = "Event Privacy",
                        color = TextPrimary,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = if (isPublic) "Public Event" else "Private Event",
                            color = TextPrimary,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = if (isPublic) 
                                "Anyone can see and join this event" 
                            else 
                                "Only invited users can see this event",
                            color = TextSecondary,
                            fontSize = 12.sp
                        )
                    }
                    
                    Switch(
                        checked = isPublic,
                        onCheckedChange = onIsPublicChange,
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = TextLight,
                            checkedTrackColor = BrandPrimary,
                            uncheckedThumbColor = TextLight,
                            uncheckedTrackColor = Divider
                        )
                    )
                }
                
                if (!isPublic) {
                    OutlinedTextField(
                        value = invitedFriends,
                        onValueChange = onInvitedFriendsChange,
                        label = { Text("Invited Friends (comma-separated)") },
                        modifier = Modifier.fillMaxWidth(),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = BrandPrimary,
                            unfocusedBorderColor = Divider
                        ),
                        shape = RoundedCornerShape(12.dp)
                    )
                }
            }
        }
        
        // Auto-matching Card
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = BgCard),
            shape = RoundedCornerShape(16.dp),
            elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
        ) {
            Column(
                modifier = Modifier.padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Filled.Group,
                        contentDescription = "Auto-matching",
                        modifier = Modifier.size(20.dp),
                        tint = BrandPrimary
                    )
                    
                    Spacer(modifier = Modifier.width(12.dp))
                    
                    Text(
                        text = "Auto-Matching",
                        color = TextPrimary,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = "Enable Auto-Matching",
                            color = TextPrimary,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = "Automatically invite users with similar interests",
                            color = TextSecondary,
                            fontSize = 12.sp
                        )
                    }
                    
                    Switch(
                        checked = autoMatchingEnabled,
                        onCheckedChange = onAutoMatchingEnabledChange,
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = TextLight,
                            checkedTrackColor = BrandPrimary,
                            uncheckedThumbColor = TextLight,
                            uncheckedTrackColor = Divider
                        )
                    )
                }
                
                if (autoMatchingEnabled) {
                    Divider()
                    
                    Text(
                        text = "Max Participants: $maxParticipants",
                        color = TextPrimary,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium
                    )
                    
                    Slider(
                        value = maxParticipants.toFloat(),
                        onValueChange = { onMaxParticipantsChange(it.toInt()) },
                        valueRange = 2f..50f,
                        colors = SliderDefaults.colors(
                            thumbColor = BrandPrimary,
                            activeTrackColor = BrandPrimary,
                            inactiveTrackColor = Divider
                        )
                    )
                    
                    Divider()
                    
                    // Interest Tags
                    Text(
                        text = "Interest Tags",
                        color = TextPrimary,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium
                    )
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        OutlinedTextField(
                            value = newTag,
                            onValueChange = onNewTagChange,
                            label = { Text("Add tag...") },
                            modifier = Modifier.weight(1f),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = BrandPrimary,
                                unfocusedBorderColor = Divider
                            ),
                            shape = RoundedCornerShape(8.dp)
                        )
                        
                        Spacer(modifier = Modifier.width(8.dp))
                        
                        Button(
                            onClick = {
                                if (newTag.isNotEmpty() && !interestTags.contains(newTag)) {
                                    onInterestTagsChange(interestTags + newTag)
                                    onNewTagChange("")
                                }
                            },
                            enabled = newTag.isNotEmpty(),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = BrandPrimary
                            ),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text(
                                text = "Add",
                                color = TextLight,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                    
                    // Tags display
                    if (interestTags.isNotEmpty()) {
                        LazyRow(
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            items(interestTags) { tag ->
                                TagChip(
                                    tag = tag,
                                    onRemove = {
                                        onInterestTagsChange(interestTags - tag)
                                    }
                                )
                            }
                        }
                    } else {
                        Text(
                            text = "Add tags to improve matching",
                            color = TextMuted,
                            fontSize = 12.sp
                        )
                    }
                    
                    // Suggested tags
                    if (interestTags.size < 5) {
                        val suggestions = listOf("Programming", "Swift", "iOS", "Machine Learning", "Data Science", "Study", "Group Project", "Networking")
                            .filter { !interestTags.contains(it) }
                            .take(6)
                        
                        Text(
                            text = "Suggested Tags:",
                            color = TextSecondary,
                            fontSize = 12.sp
                        )
                        
                        LazyRow(
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            items(suggestions) { suggestion ->
                                Button(
                                    onClick = {
                                        onInterestTagsChange(interestTags + suggestion)
                                    },
                                    colors = ButtonDefaults.buttonColors(
                                        containerColor = BrandPrimary.copy(alpha = 0.1f)
                                    ),
                                    shape = RoundedCornerShape(16.dp)
                                ) {
                                    Text(
                                        text = suggestion,
                                        color = BrandPrimary,
                                        fontSize = 10.sp
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun TagChip(
    tag: String,
    onRemove: () -> Unit
) {
    Row(
        modifier = Modifier
            .background(
                BgSecondary,
                RoundedCornerShape(16.dp)
            )
            .border(
                1.dp,
                CardStroke,
                RoundedCornerShape(16.dp)
            )
            .padding(horizontal = 12.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = tag,
            color = TextPrimary,
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium
        )
        
        Spacer(modifier = Modifier.width(6.dp))
        
        IconButton(
            onClick = onRemove,
            modifier = Modifier.size(16.dp)
        ) {
            Icon(
                Icons.Filled.Close,
                contentDescription = "Remove",
                modifier = Modifier.size(12.dp),
                tint = BrandAccent.copy(alpha = 0.85f)
            )
        }
    }
}

@Composable
fun ReviewTab(
    title: String,
    description: String,
    selectedEventType: EventType,
    startDate: LocalDateTime,
    endDate: LocalDateTime,
    locationName: String,
    coordinate: Pair<Double, Double>,
    isPublic: Boolean,
    invitedFriends: String,
    maxParticipants: Int,
    autoMatchingEnabled: Boolean,
    interestTags: List<String>
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Event Summary Card
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = BgCard),
            shape = RoundedCornerShape(16.dp),
            elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
        ) {
            Column(
                modifier = Modifier.padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Filled.CheckCircle,
                        contentDescription = "Review",
                        modifier = Modifier.size(20.dp),
                        tint = BrandPrimary
                    )
                    
                    Spacer(modifier = Modifier.width(12.dp))
                    
                    Text(
                        text = "Event Summary",
                        color = TextPrimary,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }
                
                // Title and Type
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = title.ifEmpty { "Untitled Event" },
                        color = TextPrimary,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Box(
                        modifier = Modifier
                            .background(
                                getEventTypeColor(selectedEventType),
                                RoundedCornerShape(8.dp)
                            )
                            .padding(horizontal = 8.dp, vertical = 4.dp)
                    ) {
                        Text(
                            text = selectedEventType.displayName,
                            color = TextLight,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
                
                Divider()
                
                // Schedule
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Filled.CalendarToday,
                        contentDescription = "Calendar",
                        modifier = Modifier.size(16.dp),
                        tint = TextSecondary
                    )
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    Text(
                        text = "${startDate.dayOfMonth}/${startDate.monthValue}/${startDate.year}",
                        color = TextPrimary,
                        fontSize = 14.sp
                    )
                }
                
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Filled.Schedule,
                        contentDescription = "Time",
                        modifier = Modifier.size(16.dp),
                        tint = TextSecondary
                    )
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    Text(
                        text = "${startDate.hour}:${startDate.minute.toString().padStart(2, '0')} - ${endDate.hour}:${endDate.minute.toString().padStart(2, '0')}",
                        color = TextPrimary,
                        fontSize = 14.sp
                    )
                }
                
                Divider()
                
                // Location
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Filled.LocationOn,
                        contentDescription = "Location",
                        modifier = Modifier.size(16.dp),
                        tint = TextSecondary
                    )
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    Text(
                        text = locationName,
                        color = TextPrimary,
                        fontSize = 14.sp
                    )
                }
                
                Divider()
                
                // Privacy and Settings
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Privacy",
                        color = TextSecondary,
                        fontSize = 14.sp
                    )
                    Text(
                        text = if (isPublic) "Public" else "Private",
                        color = TextPrimary,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium
                    )
                }
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Max Participants",
                        color = TextSecondary,
                        fontSize = 14.sp
                    )
                    Text(
                        text = maxParticipants.toString(),
                        color = TextPrimary,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium
                    )
                }
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Auto-Matching",
                        color = TextSecondary,
                        fontSize = 14.sp
                    )
                    Text(
                        text = if (autoMatchingEnabled) "Enabled" else "Disabled",
                        color = TextPrimary,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium
                    )
                }
                
                if (interestTags.isNotEmpty()) {
                    Divider()
                    
                    Text(
                        text = "Interest Tags",
                        color = TextSecondary,
                        fontSize = 14.sp
                    )
                    
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(interestTags) { tag ->
                            Box(
                                modifier = Modifier
                                    .background(
                                        BrandPrimary.copy(alpha = 0.1f),
                                        RoundedCornerShape(12.dp)
                                    )
                                    .padding(horizontal = 8.dp, vertical = 4.dp)
                            ) {
                                Text(
                                    text = tag,
                                    color = BrandPrimary,
                                    fontSize = 12.sp
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun NavigationButtons(
    currentTab: Int,
    onPrevious: () -> Unit,
    onNext: () -> Unit,
    canProceed: Boolean
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(BgCard)
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        if (currentTab > 0) {
            Button(
                onClick = onPrevious,
                colors = ButtonDefaults.buttonColors(
                    containerColor = BgSecondary
                ),
                shape = RoundedCornerShape(8.dp)
            ) {
                Text(
                    text = "Previous",
                    color = TextPrimary,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        } else {
            Spacer(modifier = Modifier.width(80.dp))
        }
        
        if (currentTab < 3) {
            Button(
                onClick = onNext,
                enabled = canProceed,
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (canProceed) BrandPrimary else BgSecondary
                ),
                shape = RoundedCornerShape(8.dp)
            ) {
                Text(
                    text = "Next",
                    color = if (canProceed) TextLight else TextMuted,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}

// Event creation function
private fun createEvent(
    title: String,
    description: String,
    startDate: LocalDateTime,
    endDate: LocalDateTime,
    eventType: EventType,
    isPublic: Boolean,
    invitedFriends: String,
    coordinate: Pair<Double, Double>,
    maxParticipants: Int,
    interestTags: List<String>,
    autoMatchingEnabled: Boolean,
    matchedUsers: List<String>,
    eventImages: List<String>,
    accountManager: UserAccountManager,
    onSuccess: (StudyEventMap) -> Unit,
    onError: (String) -> Unit
) {
    val scope = MainScope()
    scope.launch {
        try {
            // Get the username from the account manager
            val username = accountManager.currentUser
            
            // Check if the user is logged in
            if (username.isNullOrEmpty()) {
                Log.e("EnhancedEventCreation", "Cannot create event: No user is logged in")
                onError("You must be logged in to create an event")
                return@launch
            }
            
            Log.d("EnhancedEventCreation", "Creating event with host username: $username")
            
            // Parse invited friends list, removing empty entries and whitespace
            val friendsList = invitedFriends.split(",")
                .map { it.trim() }
                .filter { it.isNotEmpty() && it != username } // Filter out empty strings and self
            
            Log.d("EnhancedEventCreation", "Creating event with invited friends: $friendsList")
            Log.d("EnhancedEventCreation", "Interest tags: $interestTags")
            Log.d("EnhancedEventCreation", "Auto-matching enabled: $autoMatchingEnabled")
            
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
                interestTags = interestTags,
                maxParticipants = maxParticipants,
                autoMatchingEnabled = autoMatchingEnabled,
                matchedUsers = matchedUsers,
                eventImages = eventImages
            )
            
            Log.d("EnhancedEventCreation", "Event object created with host: ${event.host}")
            
            // Create the event using the repository
            val eventRepository = EventRepository()
            eventRepository.createEvent(event).collect { result ->
                if (result.isSuccess) {
                    Log.d("EnhancedEventCreation", "Event created successfully")
                    onSuccess(event)
                } else {
                    Log.e("EnhancedEventCreation", "Failed to create event: ${result.exceptionOrNull()?.message}")
                    onError(result.exceptionOrNull()?.message ?: "Failed to create event")
                }
            }
            
        } catch (e: Exception) {
            Log.e("EnhancedEventCreation", "Error creating event", e)
            onError("Error creating event: ${e.message}")
        }
    }
}

// Helper function to get event type color
    private fun getEventTypeColor(eventType: EventType): Color {
        return when (eventType) {
            EventType.STUDY -> Color(0xFF007AFF)      // iOS Blue
            EventType.PARTY -> Color(0xFFAF52DE)      // iOS Purple
            EventType.BUSINESS -> Color(0xFF5856D6)  // iOS Indigo
            EventType.CULTURAL -> Color(0xFFFF9500)  // iOS Orange
            EventType.ACADEMIC -> Color(0xFF34C759)  // iOS Green
            EventType.NETWORKING -> Color(0xFFFF2D92) // iOS Pink
            EventType.SOCIAL -> Color(0xFFFF3B30)    // iOS Red
            EventType.LANGUAGE_EXCHANGE -> Color(0xFF5AC8FA) // iOS Teal
            EventType.OTHER -> Color(0xFF8E8E93)     // iOS Gray
        }
    }
