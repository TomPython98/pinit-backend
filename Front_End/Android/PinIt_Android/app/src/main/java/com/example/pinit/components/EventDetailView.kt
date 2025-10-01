package com.example.pinit.components

import android.content.Intent
import android.provider.CalendarContract
import android.util.Log
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.pinit.models.EventType
import com.example.pinit.models.StudyEventMap
import com.example.pinit.models.UserAccountManager
import com.example.pinit.ui.theme.*
import com.example.pinit.ui.theme.CustomIcons
import com.example.pinit.viewmodels.EventDetailViewModel
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.UUID
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardType
import kotlinx.coroutines.delay
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.ui.text.style.TextOverflow

/**
 * Event Detail View that shows full information about an event
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventDetailView(
    eventId: String,
    initialEvent: StudyEventMap? = null,
    accountManager: UserAccountManager,
    onClose: () -> Unit,
    onRsvpComplete: () -> Unit = {}
) {
    val context = LocalContext.current
    
    // Enhanced debug logging with device identifiers to trace this specific instance
    val instanceId = remember { UUID.randomUUID().toString().take(8) }
    Log.d("EventDetailView", "========== INSTANCE $instanceId ==========")
    Log.d("EventDetailView", "Opening EventDetailView with eventId: $eventId")
    if (initialEvent != null) {
        Log.d("EventDetailView", "Initial event provided: ${initialEvent.title}, ID: ${initialEvent.id}")
    }
    
    // Create ViewModel with the correct event ID - use key to ensure unique instance
    val viewModel: EventDetailViewModel = viewModel(
        key = "event_detail_$eventId",
        factory = EventDetailViewModelFactory(accountManager, eventId)
    )
    
    // Log the ViewModel instance and hash to help track if it's being reused
    Log.d("EventDetailView", "ViewModel instance ${viewModel.hashCode()} for eventId: $eventId")
    
    // Initialize with initialEvent if provided
    LaunchedEffect(initialEvent, eventId) {
        Log.d("EventDetailView", "LaunchedEffect triggered with eventId: $eventId")
        
        if (initialEvent != null) {
            Log.d("EventDetailView", "Setting initial event: ${initialEvent.title}, ID: ${initialEvent.id}")
            viewModel.event.value = initialEvent
        }
        
        // Always force reload the event to ensure we get fresh data
        Log.d("EventDetailView", "Explicitly loading event with ID: $eventId")
        viewModel.loadEvent()
    }
    
    // Get current state from ViewModel
    val event = viewModel.event.value
    val isLoading = viewModel.isLoading.value
    val errorMessage = viewModel.errorMessage.value
    val isAttending = viewModel.rsvpStatus.value
    
    // Log when the event data changes
    LaunchedEffect(event) {
        if (event != null) {
            Log.d("EventDetailView", "Event data updated - Title: ${event.title}, ID: ${event.id}")
            Log.d("EventDetailView", "Event attendance status: isUserAttending=${event.isUserAttending}, RSVP status=${viewModel.rsvpStatus.value}")
        } else {
            Log.d("EventDetailView", "Event data is null")
        }
    }
    
    // Variable to control social feed display
    var showSocialFeed by remember { mutableStateOf(false) }
    var showSocialFeedFullScreen by remember { mutableStateOf(false) }
    
    val scrollState = rememberScrollState()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("") }, // Empty title since we'll have a custom header
                navigationIcon = {
                    IconButton(onClick = onClose) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back",
                            tint = Color.White
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent,
                    navigationIconContentColor = Color.White
                )
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = paddingValues.calculateTopPadding())
                .background(Color(0xFFF5F5F7)) // Light background color matching iOS system background
        ) {
            // Loading state
            if (isLoading) {
                Column(
                    modifier = Modifier
                        .fillMaxSize(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    CircularProgressIndicator(color = PrimaryColor)
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "Loading event details...",
                        style = MaterialTheme.typography.bodyLarge
                    )
                }
            }
            
            // Error state
            else if (errorMessage != null) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Error,
                        contentDescription = "Error",
                        tint = MaterialTheme.colorScheme.error,
                        modifier = Modifier.size(64.dp)
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "Error loading event",
                        style = MaterialTheme.typography.headlineSmall,
                        color = MaterialTheme.colorScheme.error
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = errorMessage,
                        style = MaterialTheme.typography.bodyMedium,
                        textAlign = TextAlign.Center
                    )
                    Spacer(modifier = Modifier.height(24.dp))
                    Button(
                        onClick = { viewModel.loadEvent() },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = PrimaryColor
                        )
                    ) {
                        Icon(
                            imageVector = Icons.Default.Refresh,
                            contentDescription = "Retry",
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Retry")
                    }
                }
            }
            
            // Event content
            else if (event != null) {
                // Use a column with verticalScroll for proper scrolling
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(scrollState)
                ) {
                    // Header Section - similar to Swift version
                    HeaderSection(event)
                    
                    // Main content section with cards
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp)
                    ) {
                        Spacer(modifier = Modifier.height(20.dp))
                        
                        // Event Info Card - time and host sections
                        EventInfoCard(event)
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        // Attendees Card
                        AttendeesCard(event)
                        
                        Spacer(modifier = Modifier.height(20.dp))
                        
                        // Action Buttons - Just one Join/Leave button and Group Chat
                        ActionButtons(
                            isAttending = isAttending,
                            isLoading = viewModel.rsvpInProgress.value,
                            onJoinLeave = {
                                // Log the RSVP action for debugging
                                Log.d("EventDetailView", "RSVP button clicked: currentStatus=${viewModel.rsvpStatus.value}")
                                
                                // Call the ViewModel's toggleRSVP method
                                viewModel.toggleRSVP {
                                    // This is called when RSVP is complete
                                    Log.d("EventDetailView", "RSVP completed, calling onRsvpComplete")
                                    onRsvpComplete()
                                }
                            },
                            onOpenChat = {
                                // Open group chat for this event
                                Log.d("EventDetailView", "Group chat button clicked")
                                // TODO: Implement group chat navigation
                            },
                            onAddToCalendar = {
                                // Add to calendar
                                addToCalendar(context, event)
                            }
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        // Social Feed Button
                        SocialFeedButton(
                            onClick = { 
                                showSocialFeedFullScreen = true
                            }
                        )
                        
                        // Extra padding at the bottom
                        Spacer(modifier = Modifier.height(40.dp))
                    }
                }
            }
            
            // Show full screen social feed if requested
            if (showSocialFeedFullScreen && event != null) {
                FullScreenSocialFeedView(
                    event = event,
                    viewModel = viewModel,
                    onClose = { showSocialFeedFullScreen = false }
                )
            }
        }
    }
}

// New header section similar to Swift version
@Composable
fun HeaderSection(event: StudyEventMap) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(180.dp)
            .background(
                brush = Brush.linearGradient(
                    colors = listOf(
                        Color(0xFF003366), // Social dark color
                        Color(0xFF005CB2)  // Slightly lighter blue
                    )
                ),
                shape = RoundedCornerShape(bottomStart = 20.dp, bottomEnd = 20.dp)
            )
    ) {
        // Event type badge
        Box(
            modifier = Modifier
                .padding(16.dp)
                .align(Alignment.TopEnd)
                .clip(RoundedCornerShape(16.dp))
                .background(Color.White.copy(alpha = 0.2f))
                .padding(horizontal = 12.dp, vertical = 6.dp)
        ) {
            Text(
                text = event.eventType?.displayName ?: "Other",
                color = Color.White,
                fontWeight = FontWeight.SemiBold,
                fontSize = 14.sp
            )
        }
        
        // Event title
        Column(
            modifier = Modifier
                .align(Alignment.BottomStart)
                .padding(16.dp)
        ) {
            Text(
                text = event.title,
                color = Color.White,
                fontWeight = FontWeight.Bold,
                fontSize = 28.sp,
                style = MaterialTheme.typography.headlineMedium
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Hosted by ${event.host}",
                    color = Color.White.copy(alpha = 0.9f),
                    style = MaterialTheme.typography.bodyMedium
                )
                
                if (event.hostIsCertified) {
                    Spacer(modifier = Modifier.width(4.dp))
                    Icon(
                        Icons.Default.Verified,
                        contentDescription = "Certified Host",
                        tint = Color.Green,
                        modifier = Modifier.size(16.dp)
                    )
                }
            }
        }
    }
}

// Social Feed Button
@Composable
fun SocialFeedButton(onClick: () -> Unit) {
    Button(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        colors = ButtonDefaults.buttonColors(
            containerColor = Color(0xFF5C6BC0) // Indigo-like color for social
        ),
        shape = RoundedCornerShape(12.dp),
        contentPadding = PaddingValues(vertical = 12.dp)
    ) {
        Icon(
            imageVector = Icons.Default.Forum,
            contentDescription = null,
            modifier = Modifier.size(20.dp)
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = "Event Social Feed",
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
fun EventInfoCard(event: StudyEventMap) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 0.dp),
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Time section with centered icons
            Column(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = "Time",
                    color = Color.Gray,
                    fontWeight = FontWeight.Bold,
                    fontSize = 12.sp
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(vertical = 4.dp)
                ) {
                    Icon(
                        Icons.Default.Schedule,
                        contentDescription = "Start Time",
                        tint = Color(0xFF003366), // Social dark color
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = formatDateTime(event.time),
                        color = Color(0xFF003366),
                        fontWeight = FontWeight.Medium,
                        fontSize = 16.sp
                    )
                    
                    Spacer(modifier = Modifier.width(16.dp))
                    Icon(
                        Icons.Default.ArrowForward,
                        contentDescription = "To",
                        tint = Color.Gray.copy(alpha = 0.6f),
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(16.dp))
                    
                    Icon(
                        Icons.Default.Event,
                        contentDescription = "End Time",
                        tint = Color(0xFF003366),
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = formatDateTime(event.endTime),
                        color = Color(0xFF003366),
                        fontWeight = FontWeight.Medium,
                        fontSize = 16.sp
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            HorizontalDivider()
            Spacer(modifier = Modifier.height(16.dp))
            
            // Host section with improved alignment
            Column(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = "Hosted By",
                    color = Color.Gray,
                    fontWeight = FontWeight.Bold,
                    fontSize = 12.sp
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(vertical = 4.dp)
                ) {
                    Text(
                        text = event.host,
                        fontWeight = FontWeight.SemiBold,
                        fontSize =.16.sp
                    )
                    
                    if (event.hostIsCertified) {
                        Spacer(modifier = Modifier.width(8.dp))
                        Icon(
                            Icons.Default.Verified,
                            contentDescription = "Certified Host",
                            tint = Color.Green,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }
            }
            
            // Description section
            event.description?.let { desc ->
                if (desc.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(16.dp))
                    HorizontalDivider()
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Text(
                        text = desc,
                        fontSize = 16.sp,
                        lineHeight = 24.sp
                    )
                }
            }
        }
    }
}

@Composable
fun AttendeesCard(event: StudyEventMap) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 0.dp),
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.Group,
                    contentDescription = "Attendees",
                    tint = Color(0xFF003366), // Social dark color
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Attendees",
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF003366) // Social dark color
                )
                Spacer(modifier = Modifier.weight(1f))
                
                // Attendee count badge
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(14.dp))
                        .background(Color(0xFFE3F2FD)) // Light blue background
                        .padding(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = "${event.attendees}",
                        color = Color(0xFF003366), // Social dark color
                        fontWeight = FontWeight.Bold
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            if (event.attendees <= 0) {
                Text(
                    text = "Be the first to join this event!",
                    fontStyle = FontStyle.Italic,
                    color = Color.Gray,
                    modifier = Modifier.padding(vertical = 8.dp)
                )
            } else {
                // Show attendees or a message about them
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.padding(vertical = 8.dp)
                ) {
                    // Create a dummy list of attendees based on the count
                    val dummyAttendees = List(event.attendees) { index -> "User ${index + 1}" }
                    
                    // Use items() with the dummy list to properly handle Composable functions
                    items(dummyAttendees) { attendeeName ->
                        AttendeeChip(name = attendeeName)
                    }
                }
            }
        }
    }
}

@Composable
fun AttendeeChip(name: String) {
    Surface(
        modifier = Modifier.padding(vertical = 4.dp),
        shape = RoundedCornerShape(10.dp),
        color = Color.White,
        shadowElevation = 2.dp
    ) {
        Text(
            text = name,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
            color = Color(0xFF003366) // Social dark color
        )
    }
}

@Composable
fun ActionButtons(
    isAttending: Boolean,
    onJoinLeave: () -> Unit,
    onOpenChat: () -> Unit,
    onAddToCalendar: () -> Unit,
    modifier: Modifier = Modifier,
    isLoading: Boolean = false
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Just one Join/Leave button with loading state
        Button(
            onClick = onJoinLeave,
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(
                containerColor = if (isAttending) 
                    Color(0xFFE57373) // Light red for leave
                else 
                    Color(0xFF66BB6A) // Light green for join
            ),
            enabled = !isLoading,
            shape = RoundedCornerShape(12.dp),
            contentPadding = PaddingValues(vertical = 12.dp)
        ) {
            if (isLoading) {
                // Show loading indicator
                CircularProgressIndicator(
                    modifier = Modifier.size(24.dp),
                    color = Color.White,
                    strokeWidth = 2.dp
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Processing...")
            } else {
                // Show normal button content
                Icon(
                    if (isAttending) Icons.Default.Close else Icons.Default.Check,
                    contentDescription = if (isAttending) "Leave Event" else "Join Event",
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    if (isAttending) "Leave Event" else "Join Event",
                    fontWeight = FontWeight.Bold
                )
            }
        }
        
        // Group chat button
        Button(
            onClick = onOpenChat,
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(
                containerColor = Color(0xFF42A5F5) // Light blue for chat
            ),
            shape = RoundedCornerShape(12.dp),
            contentPadding = PaddingValues(vertical = 12.dp)
        ) {
            Icon(
                Icons.Default.Chat, 
                contentDescription = "Group Chat",
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                "Group Chat",
                fontWeight = FontWeight.Bold
            )
        }
    }
}

// Helper function to add event to calendar
private fun addToCalendar(context: android.content.Context, event: StudyEventMap) {
    val startTime = event.time
    val endTime = event.endTime ?: startTime.plusHours(1) // Default to 1 hour if no end time
    
    val startMillis = startTime.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
    val endMillis = endTime.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
    
    val intent = Intent(Intent.ACTION_INSERT)
        .setData(CalendarContract.Events.CONTENT_URI)
        .putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, startMillis)
        .putExtra(CalendarContract.EXTRA_EVENT_END_TIME, endMillis)
        .putExtra(CalendarContract.Events.TITLE, event.title)
        .putExtra(CalendarContract.Events.DESCRIPTION, event.description ?: "")
        .putExtra(CalendarContract.Events.EVENT_LOCATION, "")
        .putExtra(CalendarContract.Events.AVAILABILITY, CalendarContract.Events.AVAILABILITY_BUSY)
    
    context.startActivity(intent)
}

// Helper function to format date and time
private fun formatDateTime(dateTime: LocalDateTime?): String {
    return dateTime?.format(
        DateTimeFormatter.ofLocalizedDateTime(FormatStyle.SHORT)
    ) ?: "TBD"
}

// Helper extension to capitalize strings
private fun String.capitalize(): String {
    return this.replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }
}

// Factory for EventDetailViewModel
class EventDetailViewModelFactory(
    private val accountManager: UserAccountManager,
    private val eventId: String
) : androidx.lifecycle.ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : androidx.lifecycle.ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(EventDetailViewModel::class.java)) {
            return EventDetailViewModel(accountManager, eventId) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}

/**
 * Placeholder for Social Feed Section
 */
@Composable
fun SocialFeedSection(
    event: StudyEventMap,
    viewModel: EventDetailViewModel,
    showFeed: Boolean,
    onToggleFeed: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Header with toggle
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(onClick = onToggleFeed),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.Chat,
                    contentDescription = "Social Feed",
                    tint = PrimaryColor
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Event Discussion",
                    fontWeight = FontWeight.Bold,
                    color = PrimaryColor
                )
                Spacer(modifier = Modifier.weight(1f))
                Icon(
                    if (showFeed) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                    contentDescription = if (showFeed) "Collapse" else "Expand",
                    tint = PrimaryColor
                )
            }
            
            // Content (visible only when expanded)
            AnimatedVisibility(
                visible = showFeed,
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 16.dp)
                ) {
                    // Loading state
                    if (viewModel.isFeedLoading.value) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(100.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator(color = PrimaryColor)
                        }
                    } 
                    // Error state
                    else if (viewModel.feedErrorMessage.value != null) {
                        Text(
                            text = "Error loading social feed: ${viewModel.feedErrorMessage.value}",
                            color = Color.Red,
                            modifier = Modifier.padding(vertical = 16.dp)
                        )
                    } 
                    // Empty state
                    else if (viewModel.interactions.value?.posts?.isEmpty() == true) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(100.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "No posts yet. Be the first to post!",
                                color = Color.Gray,
                                fontStyle = FontStyle.Italic
                            )
                        }
                    } 
                    // Content state
                    else {
                        viewModel.interactions.value?.posts?.let { posts ->
                            // Post creation
                            TextField(
                                value = viewModel.newPostText.value,
                                onValueChange = { viewModel.newPostText.value = it },
                                modifier = Modifier.fillMaxWidth(),
                                placeholder = { Text("Share your thoughts about this event...") },
                                colors = TextFieldDefaults.colors(
                                    focusedContainerColor = Color.White,
                                    unfocusedContainerColor = Color.White,
                                    focusedIndicatorColor = PrimaryColor
                                )
                            )
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            // Post button
                            Button(
                                onClick = { viewModel.addPost() },
                                modifier = Modifier.align(Alignment.End),
                                enabled = viewModel.newPostText.value.isNotEmpty() && !viewModel.isPostingComment.value
                            ) {
                                if (viewModel.isPostingComment.value) {
                                    CircularProgressIndicator(
                                        modifier = Modifier.size(20.dp),
                                        color = Color.White,
                                        strokeWidth = 2.dp
                                    )
                                } else {
                                    Text("Post")
                                }
                            }
                            
                            Spacer(modifier = Modifier.height(16.dp))
                            Divider()
                            Spacer(modifier = Modifier.height(16.dp))
                            
                            // Posts display
                            posts.forEach { post ->
                                SocialPostItem(
                                    post = post,
                                    onLike = { viewModel.likePost(post.id) },
                                    onReply = { /* Handle reply */ }
                                )
                                Divider(modifier = Modifier.padding(vertical = 8.dp))
                            }
                        }
                    }
                }
            }
        }
    }
}

/**
 * Placeholder for AutoMatching Card
 */
@Composable
fun AutoMatchingCard(
    event: StudyEventMap,
    viewModel: EventDetailViewModel,
    accountManager: UserAccountManager,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.People,
                    contentDescription = "Auto-Matching",
                    tint = PrimaryColor
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Smart Matching",
                    fontWeight = FontWeight.Bold,
                    color = PrimaryColor
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Text(
                text = "Find other users who would be interested in this event.",
                color = TextSecondary,
                style = MaterialTheme.typography.bodyMedium
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Button(
                onClick = { },
                modifier = Modifier.align(Alignment.End)
            ) {
                Text("Find Matches")
            }
        }
    }
}

@Composable
fun SocialPostItem(
    post: com.example.pinit.models.EventInteractions.Post,
    onLike: () -> Unit,
    onReply: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
    ) {
        // Header with user info and timestamp
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // User avatar
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Default.Person,
                    contentDescription = "User",
                    tint = MaterialTheme.colorScheme.primary
                )
            }
            
            Spacer(modifier = Modifier.width(12.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = post.username,
                    fontWeight = FontWeight.Bold,
                    style = MaterialTheme.typography.bodyLarge
                )
                
                Text(
                    text = formatTimestamp(post.createdAt),
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Gray
                )
            }
        }
        
        // Post content
        Text(
            text = post.text,
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.padding(vertical = 12.dp, horizontal = 4.dp)
        )
        
        // Display images if available
        post.imageUrls?.let { urls ->
            if (urls.isNotEmpty()) {
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.padding(vertical = 8.dp)
                ) {
                    items(urls) { url ->
                        Box(
                            modifier = Modifier
                                .size(120.dp, 90.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)),
                            contentAlignment = Alignment.Center
                        ) {
                            // If we had actual images, we'd load them here
                            // For now, just show a placeholder
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Icon(
                                    Icons.Default.Image,
                                    contentDescription = "Image",
                                    tint = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.size(36.dp)
                                )
                                Text(
                                    text = "Image ${urls.indexOf(url) + 1}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.primary
                                )
                            }
                        }
                    }
                }
            }
        }
        
        // Action buttons
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Like button
            Row(
                modifier = Modifier
                    .clip(RoundedCornerShape(16.dp))
                    .clickable(onClick = onLike)
                    .padding(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    if (post.isLikedByCurrentUser) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                    contentDescription = "Like",
                    tint = if (post.isLikedByCurrentUser) Color.Red else Color.Gray,
                    modifier = Modifier.size(18.dp)
                )
                
                Spacer(modifier = Modifier.width(4.dp))
                
                Text(
                    text = post.likes.toString(),
                    style = MaterialTheme.typography.bodyMedium,
                    color = if (post.isLikedByCurrentUser) Color.Red else Color.Gray
                )
            }
            
            // Reply button
            Row(
                modifier = Modifier
                    .clip(RoundedCornerShape(16.dp))
                    .clickable(onClick = onReply)
                    .padding(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.ChatBubbleOutline,
                    contentDescription = "Reply",
                    tint = Color.Gray,
                    modifier = Modifier.size(18.dp)
                )
                
                Spacer(modifier = Modifier.width(4.dp))
                
                Text(
                    text = post.replies.size.toString(),
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color.Gray
                )
            }
        }
        
        // Show replies if any
        if (post.replies.isNotEmpty()) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(start = 20.dp, top = 8.dp)
            ) {
                post.replies.forEach { reply ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(MaterialTheme.colorScheme.surface)
                            .padding(8.dp),
                        verticalAlignment = Alignment.Top
                    ) {
                        // User avatar (smaller)
                        Box(
                            modifier = Modifier
                                .size(24.dp)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                Icons.Default.Person,
                                contentDescription = "User",
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                        
                        Spacer(modifier = Modifier.width(8.dp))
                        
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = reply.username,
                                fontWeight = FontWeight.Bold,
                                style = MaterialTheme.typography.bodyMedium
                            )
                            
                            Text(
                                text = reply.text,
                                style = MaterialTheme.typography.bodySmall
                            )
                            
                            Row(
                                modifier = Modifier.padding(top = 4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = formatTimestamp(reply.createdAt),
                                    style = MaterialTheme.typography.labelSmall,
                                    color = Color.Gray
                                )
                                
                                Spacer(modifier = Modifier.width(16.dp))
                                
                                // Like counter for the reply
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(
                                        if (reply.isLikedByCurrentUser) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                                        contentDescription = "Like",
                                        tint = if (reply.isLikedByCurrentUser) Color.Red else Color.Gray,
                                        modifier = Modifier.size(12.dp)
                                    )
                                    
                                    Spacer(modifier = Modifier.width(2.dp))
                                    
                                    Text(
                                        text = reply.likes.toString(),
                                        style = MaterialTheme.typography.labelSmall,
                                        color = if (reply.isLikedByCurrentUser) Color.Red else Color.Gray
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

// Helper function to format timestamps
private fun formatTimestamp(timestamp: String): String {
    // Try to parse the timestamp
    try {
        val dateTime = java.time.ZonedDateTime.parse(timestamp)
        val now = java.time.ZonedDateTime.now()
        val duration = java.time.Duration.between(dateTime, now)
        
        return when {
            duration.toMinutes() < 1 -> "Just now"
            duration.toMinutes() < 60 -> "${duration.toMinutes()}m"
            duration.toHours() < 24 -> "${duration.toHours()}h"
            duration.toDays() < 30 -> "${duration.toDays()}d"
            else -> {
                val formatter = java.time.format.DateTimeFormatter.ofPattern("MMM d")
                dateTime.format(formatter)
            }
        }
    } catch (e: Exception) {
        // If parsing fails, return a fallback
        return "Recently"
    }
}

// Full screen social feed view
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FullScreenSocialFeedView(
    event: StudyEventMap,
    viewModel: EventDetailViewModel,
    onClose: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxSize(),
        color = Color(0xFFF5F5F7) // Light background color matching iOS
    ) {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text(event.title, maxLines = 1, overflow = TextOverflow.Ellipsis) },
                    navigationIcon = {
                        IconButton(onClick = onClose) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                contentDescription = "Back"
                            )
                        }
                    },
                    actions = {
                        IconButton(onClick = { viewModel.loadSocialFeed() }) {
                            Icon(
                                imageVector = Icons.Default.Refresh,
                                contentDescription = "Refresh"
                            )
                        }
                    }
                )
            }
        ) { paddingValues ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
            ) {
                // Use the existing SocialFeedContent component
                SocialFeedContent(
                    viewModel = viewModel,
                    eventId = event.id ?: ""
                )
            }
        }
    }
}

@Composable
private fun SocialFeedContent(
    viewModel: EventDetailViewModel,
    eventId: String
) {
    // Get state from ViewModel
    val interactions = viewModel.interactions.value
    val isFeedLoading = viewModel.isFeedLoading.value
    val feedErrorMessage = viewModel.feedErrorMessage.value
    
    // Load social feed when opening
    LaunchedEffect(eventId) {
        viewModel.loadSocialFeed()
    }
    
    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        // Create post section at top
        CreatePostSection(viewModel)
        
        // Divider
        HorizontalDivider(
            modifier = Modifier.padding(vertical = 8.dp),
            thickness = 1.dp,
            color = Color.LightGray.copy(alpha = 0.5f)
        )
        
        // Content based on state
        when {
            isFeedLoading -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = PrimaryColor)
                }
            }
            feedErrorMessage != null -> {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Icon(
                        Icons.Default.Error,
                        contentDescription = "Error",
                        modifier = Modifier.size(48.dp),
                        tint = Color.Red
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "Failed to load feed",
                        style = MaterialTheme.typography.titleMedium,
                        color = Color.Red
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = feedErrorMessage,
                        textAlign = TextAlign.Center
                    )
                }
            }
            interactions?.posts?.isEmpty() == true -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            Icons.Default.Forum,
                            contentDescription = "No Posts",
                            modifier = Modifier.size(48.dp),
                            tint = Color.Gray.copy(alpha = 0.5f)
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "No posts yet",
                            style = MaterialTheme.typography.titleMedium,
                            color = Color.Gray
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "Be the first to start the conversation!",
                            textAlign = TextAlign.Center,
                            color = Color.Gray
                        )
                    }
                }
            }
            else -> {
                // Posts list - fixed implementation
                PostsList(
                    posts = interactions?.posts ?: emptyList(),
                    onLikePost = { viewModel.likePost(it.id) }
                )
            }
        }
    }
}

@Composable
private fun PostsList(
    posts: List<com.example.pinit.models.EventInteractions.Post>,
    onLikePost: (com.example.pinit.models.EventInteractions.Post) -> Unit
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(vertical = 8.dp)
    ) {
        items(posts) { post ->
            Column {
                SocialPostItem(
                    post = post,
                    onLike = { onLikePost(post) },
                    onReply = { /* Handle reply */ }
                )
                
                if (post != posts.lastOrNull()) {
                    HorizontalDivider(
                        modifier = Modifier.padding(vertical = 8.dp),
                        thickness = 1.dp,
                        color = Color.LightGray.copy(alpha = 0.5f)
                    )
                }
            }
        }
    }
}

@Composable
private fun CreatePostSection(viewModel: EventDetailViewModel) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp)
    ) {
        TextField(
            value = viewModel.newPostText.value,
            onValueChange = { viewModel.newPostText.value = it },
            placeholder = { Text("What's on your mind?") },
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 100.dp),
            colors = TextFieldDefaults.colors(
                focusedContainerColor = Color.White,
                unfocusedContainerColor = Color.White,
                disabledContainerColor = Color.White,
                focusedIndicatorColor = PrimaryColor,
                unfocusedIndicatorColor = Color.LightGray
            )
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        // Post button
        Button(
            onClick = { viewModel.addPost() },
            modifier = Modifier.align(Alignment.End),
            enabled = viewModel.newPostText.value.isNotBlank() && !viewModel.isPostingComment.value,
            colors = ButtonDefaults.buttonColors(
                containerColor = PrimaryColor
            )
        ) {
            if (viewModel.isPostingComment.value) {
                CircularProgressIndicator(
                    modifier = Modifier.size(16.dp),
                    color = Color.White,
                    strokeWidth = 2.dp
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Posting...")
            } else {
                Icon(Icons.Default.Send, contentDescription = "Post")
                Spacer(modifier = Modifier.width(8.dp))
                Text("Post")
            }
        }
    }
} 