package com.example.pinit.components

import android.util.Log
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.pinit.R
import com.example.pinit.components.map.ClusterAnnotationView
import com.example.pinit.components.map.EventAnnotationView
import com.example.pinit.components.map.MapClusteringUtils
import com.example.pinit.models.CoordinateConverter
import com.example.pinit.models.EventType
import com.example.pinit.models.StudyEventMap
import com.example.pinit.models.UserAccountManager
import com.mapbox.geojson.Point
import com.mapbox.maps.CameraOptions
import com.mapbox.maps.MapView
import com.mapbox.maps.Style
import com.mapbox.maps.plugin.annotation.annotations
import com.mapbox.maps.plugin.annotation.generated.PointAnnotationManager
import com.mapbox.maps.plugin.annotation.generated.PointAnnotationOptions
import com.mapbox.maps.plugin.annotation.generated.createPointAnnotationManager
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import androidx.lifecycle.viewModelScope
import com.example.pinit.repository.EventRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.ui.text.input.TextFieldValue

/**
 * ViewModel for FullScreenMapView
 */
class MapViewModel(private val accountManager: UserAccountManager) : ViewModel() {
    // Repository for data fetching
    private val repository = EventRepository()
    
    // Events from the API
    val events = mutableStateListOf<StudyEventMap>()
    
    // State variables
    val isLoading = mutableStateOf(true)
    val errorMessage = mutableStateOf<String?>(null)
    
    // Filter states
    var showEventTypes = mutableStateMapOf(
        EventType.STUDY to true,
        EventType.PARTY to true,
        EventType.BUSINESS to true,
        EventType.OTHER to true
    )
    
    var showPrivateEvents = mutableStateOf(true)
    var showInvitations = mutableStateOf(true)
    var showPotentialMatches = mutableStateOf(true)
    
    // New state for showing only potential matches
    var showOnlyPotentialMatches = mutableStateOf(false)
    
    // Initial loading of data
    init {
        Log.d("MapViewModel", "Initializing with current user: ${accountManager.currentUser}")
        
        // First, check if we need to pre-load invitations to find potential matches
        // This ensures potential matches from invitations are registered before map loads
        preloadPotentialMatches()
    }
    
    // Preload potential matches from the invitations view to ensure they're registered
    private fun preloadPotentialMatches() {
        val username = accountManager.currentUser ?: return
        
        Log.d("MapViewModel", "🔄 Pre-loading invitations to find potential matches for: $username")
        
        // Directly make request to invitations endpoint to find auto-matched events
        viewModelScope.launch {
            try {
                repository.getInvitations(username).collect { result ->
                    result.fold(
                        onSuccess = { responseBody ->
                            if (responseBody.has("invitations")) {
                                val invitationsArray = responseBody.getJSONArray("invitations")
                                Log.d("MapViewModel", "✅ Found ${invitationsArray.length()} invitations to check")
                                
                                // Clear existing matches
                                com.example.pinit.utils.PotentialMatchRegistry.clear()
                                
                                // Process all invitations
                                var potentialMatchCount = 0
                                val autoMatchedEvents = mutableListOf<StudyEventMap>()
                                
                                for (i in 0 until invitationsArray.length()) {
                                    val invitation = invitationsArray.getJSONObject(i)
                                    val eventId = invitation.getString("id")
                                    val title = invitation.getString("title")
                                    val isAutoMatched = invitation.optBoolean("isAutoMatched", false)
                                    
                                    // DEBUG: Print all invitation data
                                    Log.d("MapViewModel", "👁️ INVITATION: $title, autoMatched=$isAutoMatched")
                                    
                                    if (isAutoMatched) {
                                        // Register this as a potential match
                                        com.example.pinit.utils.PotentialMatchRegistry.registerPotentialMatch(eventId)
                                        potentialMatchCount++
                                        Log.d("MapViewModel", "✨ Registered potential match: $eventId - $title")
                                        
                                        // NEW CODE: Create a map marker for this auto-matched invitation
                                        try {
                                            val latitude = invitation.getDouble("latitude")
                                            val longitude = invitation.getDouble("longitude")
                                            val description = invitation.optString("description", "")
                                            val time = invitation.getString("time")
                                            val endTime = invitation.getString("end_time")
                                            val host = invitation.getString("host")
                                            val hostIsCertified = invitation.optBoolean("hostIsCertified", false)
                                            val eventType = invitation.optString("event_type", "study")
                                            
                                            // Debug: Make sure we have valid coordinates
                                            Log.d("MapViewModel", "📍 COORDINATES for $title: lat=$latitude, lon=$longitude")
                                            
                                            val formatter = java.time.format.DateTimeFormatter.ISO_DATE_TIME
                                            val startTime = java.time.LocalDateTime.parse(time, formatter)
                                            val endDateTime = java.time.LocalDateTime.parse(endTime, formatter)
                                            
                                            // Create map marker from invitation data
                                            val eventMarker = StudyEventMap(
                                                id = eventId,
                                                title = title,
                                                coordinate = Pair(longitude, latitude),
                                                time = startTime,
                                                endTime = endDateTime,
                                                description = description,
                                                invitedFriends = listOf(username),
                                                attendees = 0,
                                                isPublic = false,
                                                host = host,
                                                hostIsCertified = hostIsCertified,
                                                eventType = when(eventType.lowercase()) {
                                                    "study" -> EventType.STUDY
                                                    "party" -> EventType.PARTY
                                                    "business" -> EventType.BUSINESS
                                                    else -> EventType.OTHER
                                                },
                                                isUserAttending = false,
                                                isAutoMatched = true  // This is a critical flag!
                                            )
                                            
                                            autoMatchedEvents.add(eventMarker)
                                            Log.d("MapViewModel", "🗺️ Created map marker for auto-matched event: $title")
                                            Log.d("MapViewModel", "   - ID: $eventId")
                                            Log.d("MapViewModel", "   - Coordinates: ($longitude, $latitude)")
                                            Log.d("MapViewModel", "   - Type: ${eventType}")
                                        } catch (e: Exception) {
                                            Log.e("MapViewModel", "❌ Error creating map marker from invitation: ${e.message}", e)
                                        }
                                    }
                                }
                                
                                Log.d("MapViewModel", "🔍 Found and registered $potentialMatchCount potential matches from invitations")
                                
                                // NEW CODE: If we have auto-matched events, add them to the events list
                                if (autoMatchedEvents.isNotEmpty()) {
                                    Log.d("MapViewModel", "🗺️ Adding ${autoMatchedEvents.size} auto-matched events directly to map")
                                    events.addAll(autoMatchedEvents)
                                    
                                    // Force update the map to immediately show these markers
                                    // This is critical since the loadEvents function might run later
                                    refreshAutoMatchedMarkers(autoMatchedEvents)
                                }
                            }
                        },
                        onFailure = { error ->
                            Log.e("MapViewModel", "❌ Error loading invitations: ${error.message}")
                            // Continue loading the events for the map even if there's an error
                            loadEvents()
                        }
                    )
                    
                    // Continue to load map events after processing invitations
                    loadEvents()
                }
            } catch (e: Exception) {
                Log.e("MapViewModel", "❌ Error loading invitations: ${e.message}", e)
                // Continue loading the events for the map even if there's an error
                loadEvents()
            }
        }
    }
    
    // NEW FUNCTION: Specifically refresh the auto-matched markers
    private fun refreshAutoMatchedMarkers(autoMatchedEvents: List<StudyEventMap>) {
        // This function helps ensure auto-matched events appear even if they're
        // not included in the normal events list
        viewModelScope.launch {
            try {
                Log.d("MapViewModel", "🔄 Refreshing auto-matched markers: ${autoMatchedEvents.size}")
                
                // Make sure all auto-matched events are properly filtered and shown
                val filteredAutoMatched = autoMatchedEvents.filter { event ->
                    // Apply any needed filters here
                    true // We want to show all auto-matched events
                }
                
                // Force these to be displayed
                Log.d("MapViewModel", "🔍 After filtering: ${filteredAutoMatched.size} auto-matched events will appear")
                
                // NOTE: We don't need to do anything else here - the events have already been added to the
                // events list, and the MapView will automatically update when it observes changes
            } catch (e: Exception) {
                Log.e("MapViewModel", "❌ Error refreshing auto-matched markers: ${e.message}", e)
            }
        }
    }
    
    // Load events from the API using the logged-in user
    fun loadEvents() {
        isLoading.value = true
        errorMessage.value = null
        
        val username = accountManager.currentUser ?: "guest"
        Log.d("MapViewModel", "🔄 Loading events for user: $username")
        
        // Store current attendance status before reload
        val currentAttendanceStatus = events.associate { 
            it.id to (it.isUserAttending to it.attendees) 
        }
        
        // NEW: Save existing auto-matched events from invitations
        val existingAutoMatchedEvents = events.filter { 
            it.isAutoMatched && 
            com.example.pinit.utils.PotentialMatchRegistry.isEventPotentialMatch(it.id)
        }
        if (existingAutoMatchedEvents.isNotEmpty()) {
            Log.d("MapViewModel", "📌 Preserving ${existingAutoMatchedEvents.size} auto-matched events from invitations")
            for (event in existingAutoMatchedEvents) {
                Log.d("MapViewModel", "  - ${event.title} (${event.id})")
                Log.d("MapViewModel", "    Coordinates: ${event.coordinate}")
            }
        }
        
        viewModelScope.launch {
            repository.getEventsForUser(username).collect { result ->
                isLoading.value = false
                
                result.fold(
                    onSuccess = { eventsList ->
                        // Log initial count
                        Log.d("MapViewModel", "📊 Received ${eventsList.size} events from repository")
                        
                        // 🔎 DETAILED AUTO-MATCHED DEBUG
                        Log.d("MapViewModel", "🔎 AUTO-MATCHED ANALYSIS - All events:")
                        eventsList.forEachIndexed { index, event ->
                            val userIsHost = event.host == username
                            val userIsAttending = event.isUserAttending
                            val isPotentialMatch = event.isAutoMatched && !userIsAttending && !userIsHost
                            
                            Log.d("MapViewModel", "Event[$index]: id=${event.id}, title=${event.title}")
                            Log.d("MapViewModel", "  - isAutoMatched: ${event.isAutoMatched}")
                            Log.d("MapViewModel", "  - userIsHost: $userIsHost")
                            Log.d("MapViewModel", "  - userIsAttending: $userIsAttending")
                            Log.d("MapViewModel", "  - isPotentialMatch: $isPotentialMatch")
                            Log.d("MapViewModel", "  - invitedFriends: ${event.invitedFriends}")
                            if (event.coordinate != null) {
                                Log.d("MapViewModel", "  - coordinates: ${event.coordinate}")
                            } else {
                                Log.d("MapViewModel", "  - coordinates: NULL ⚠️")
                            }
                        }
                        
                        // Check registry state
                        val registeredIds = com.example.pinit.utils.PotentialMatchRegistry.getAllIds()
                        Log.d("MapViewModel", "🔍 PotentialMatchRegistry has ${registeredIds.size} entries: $registeredIds")
                        
                        // Check for any mismatches
                        eventsList.forEach { event ->
                            val inRegistry = com.example.pinit.utils.PotentialMatchRegistry.isEventPotentialMatch(event.id)
                            val isMarkedAutoMatched = event.isAutoMatched
                            
                            if (inRegistry != isMarkedAutoMatched) {
                                Log.d("MapViewModel", "⚠️ MISMATCH: Event ${event.id} - ${event.title}")
                                Log.d("MapViewModel", "  - In registry: $inRegistry")
                                Log.d("MapViewModel", "  - isAutoMatched flag: $isMarkedAutoMatched")
                            }
                        }
                        
                        // Check for attendance status changes
                        if (currentAttendanceStatus.isNotEmpty()) {
                            for (event in eventsList) {
                                val previous = currentAttendanceStatus[event.id]
                                if (previous != null) {
                                    val (wasAttending, prevAttendees) = previous
                                    // If attendance status has changed, log it
                                    if (wasAttending != event.isUserAttending || prevAttendees != event.attendees) {
                                        Log.d("MapViewModel", "⚠️ Attendance status changed for event '${event.title}':")
                                        Log.d("MapViewModel", "  - isUserAttending: $wasAttending → ${event.isUserAttending}")
                                        Log.d("MapViewModel", "  - Attendees: $prevAttendees → ${event.attendees}")
                                    }
                                }
                            }
                        }
                        
                        // Check if the response includes any event we just RSVP'd to
                        // If it doesn't match our local state, we might have a sync issue
                        for (eventId in currentAttendanceStatus.keys) {
                            val matchingEvent = eventsList.find { it.id == eventId }
                            if (matchingEvent == null) {
                                Log.d("MapViewModel", "⚠️ Event $eventId in local state no longer exists in response")
                            }
                        }
                        
                        // MODIFIED: Clear existing events EXCEPT for auto-matched invitation events
                        val nonAutoMatchedEvents = events.filterNot { 
                            it.isAutoMatched && 
                            com.example.pinit.utils.PotentialMatchRegistry.isEventPotentialMatch(it.id)
                        }
                        events.clear()
                        
                        // First add events from the API
                        events.addAll(eventsList)
                        
                        // NEW: Now add back the auto-matched events from invitations that we saved earlier
                        // Skip any that would be duplicates (same ID)
                        val existingIds = events.mapNotNull { it.id }.toSet()
                        val newAutoMatchedEvents = existingAutoMatchedEvents.filter { 
                            if (it.id in existingIds) {
                                Log.d("MapViewModel", "⚠️ Skipping duplicate auto-matched event: ${it.title}")
                                false
                            } else {
                                true
                            }
                        }
                        
                        if (newAutoMatchedEvents.isNotEmpty()) {
                            Log.d("MapViewModel", "🗺️ Adding back ${newAutoMatchedEvents.size} auto-matched events from invitations")
                            // Debug: log each event being added back
                            newAutoMatchedEvents.forEach { event ->
                                Log.d("MapViewModel", "  - Adding: ${event.title} (${event.id})")
                                Log.d("MapViewModel", "    Coordinates: ${event.coordinate}")
                            }
                            events.addAll(newAutoMatchedEvents)
                        }
                        
                        // Debug each event's attendance data
                        var attendingCount = 0
                        var invitedCount = 0
                        var hostingCount = 0
                        var autoMatchedCount = 0
                        
                        events.forEachIndexed { index, event ->
                            if (event.isUserAttending) attendingCount++
                            if (event.invitedFriends.contains(username)) invitedCount++
                            if (event.host == username) hostingCount++
                            if (event.isAutoMatched) autoMatchedCount++
                            
                            Log.d("MapViewModel", "Event[$index] - Title: ${event.title}, " +
                                  "Type: ${event.eventType}, " +
                                  "UserAttending: ${event.isUserAttending}, " +
                                  "AutoMatched: ${event.isAutoMatched}, " +
                                  "Host: ${event.host}" + 
                                  (if (event.invitedFriends.contains(username)) " [INVITED]" else ""))
                        }
                        
                        Log.d("MapViewModel", "✅ Successfully loaded ${events.size} events:")
                        Log.d("MapViewModel", "  - Attending: $attendingCount")
                        Log.d("MapViewModel", "  - Hosting: $hostingCount")
                        Log.d("MapViewModel", "  - Invited: $invitedCount")
                        Log.d("MapViewModel", "  - Auto-matched: $autoMatchedCount")
                        
                        // Additional debug: show filtered vs unfiltered counts
                        val filteredEvents = getFilteredEvents()
                        Log.d("MapViewModel", "🔍 After filtering: ${filteredEvents.size}/${events.size} events will be shown on map")
                    },
                    onFailure = { error ->
                        errorMessage.value = "Failed to load events: ${error.message}"
                        Log.e("MapViewModel", "❌ Error loading events for user $username: ${error.message}", error)
                        
                        // Load sample events as fallback for development/testing
                        loadSampleEvents()
                    }
                )
            }
        }
    }
    
    // Search for events
    fun searchEvents(query: String) {
        isLoading.value = true
        errorMessage.value = null
        
        viewModelScope.launch {
            repository.searchEvents(query).collect { result ->
                isLoading.value = false
                
                result.fold(
                    onSuccess = { eventsList ->
                        events.clear()
                        events.addAll(eventsList)
                        Log.d("MapViewModel", "Search found ${events.size} events")
                    },
                    onFailure = { error ->
                        errorMessage.value = "Search failed: ${error.message}"
                        Log.e("MapViewModel", "Error searching events", error)
                    }
                )
            }
        }
    }
    
    // Get filtered events based on selected filters
    fun getFilteredEvents(): List<StudyEventMap> {
        val currentUser = accountManager.currentUser ?: "guest"
        
        // Handle "Show Only Potential Matches" mode
        if (showOnlyPotentialMatches.value) {
            Log.d("MapViewModel", "🔍 FILTER MODE: Showing only potential matches")
            
            val matches = events.filter { event ->
                // Get basic event details
                val userIsHost = event.host == currentUser
                val userIsAttending = event.isUserAttending
                
                // Check if in registry or directly marked as auto-matched
                val isInRegistry = com.example.pinit.utils.PotentialMatchRegistry.isEventPotentialMatch(event.id)
                val isMarkedAutoMatched = event.isAutoMatched
                
                // Determine if this is a potential match
                val isPotentialMatch = (isMarkedAutoMatched || isInRegistry) && !userIsAttending && !userIsHost
                
                // Debug each event
                if (isPotentialMatch) {
                    Log.d("MapViewModel", "✅ POTENTIAL MATCH: '${event.title}'")
                    Log.d("MapViewModel", "   - host=${event.host}, currentUser=$currentUser")
                    Log.d("MapViewModel", "   - attending=${event.isUserAttending}")
                    Log.d("MapViewModel", "   - isAutoMatched=${event.isAutoMatched}")
                    Log.d("MapViewModel", "   - isInRegistry=$isInRegistry")
                    if (event.coordinate != null) {
                        Log.d("MapViewModel", "   - coordinates=${event.coordinate}")
                    } else {
                        Log.d("MapViewModel", "   - coordinates=NULL ⚠️")
                    }
                } else if (isMarkedAutoMatched || isInRegistry) {
                    Log.d("MapViewModel", "❌ IN REGISTRY BUT NOT A MATCH: '${event.title}'")
                    Log.d("MapViewModel", "   - host=${event.host}, currentUser=$currentUser")
                    Log.d("MapViewModel", "   - attending=${event.isUserAttending}")
                }
                
                // Only keep potential matches
                isPotentialMatch
            }
            Log.d("MapViewModel", "📊 Found ${matches.size} potential matches out of ${events.size} total events")
            return matches
        }
        
        // Regular filtering for normal mode
        return events.filter { event ->
            // Get basic event details
            val userIsHost = event.host == currentUser
            val isPublic = event.isPublic
            val userIsAttending = event.isUserAttending
            val userIsInvited = event.invitedFriends.contains(currentUser)
            
            // Check if in registry or directly marked as auto-matched
            val isInRegistry = com.example.pinit.utils.PotentialMatchRegistry.isEventPotentialMatch(event.id)
            val isAutoMatch = event.isAutoMatched || isInRegistry
            
            // Apply event type filter (study, party, business, other)
            val typeFilter = event.eventType?.let { showEventTypes[it] } ?: true
            
            // Modified visibility filter to include invitations and potential matches
            // Show events if:
            // 1. User is the host (always show your own events)
            // 2. User is attending (has accepted an invitation)
            // 3. Public events (only if the user isn't specifically invited but not attending)
            // 4. Direct invitations that haven't been accepted yet (if showInvitations is enabled)
            // 5. Auto-matched potential events (if showPotentialMatches is enabled)
            val isPendingInvitation = userIsInvited && !userIsAttending && !userIsHost
            val isPotentialMatch = isAutoMatch && !userIsAttending && !userIsHost
            
            val showBasedOnStatus = userIsHost || 
                                   userIsAttending || 
                                   (isPublic && (!userIsInvited || userIsAttending)) || 
                                   (showInvitations.value && isPendingInvitation) || 
                                   (showPotentialMatches.value && isPotentialMatch)
            
            // Apply private event filter for non-invitation events
            val visibilityFilter = isPublic || 
                                  (showPrivateEvents.value && (userIsHost || userIsAttending)) ||
                                  (showInvitations.value && isPendingInvitation) ||
                                  (showPotentialMatches.value && isPotentialMatch)
            
            // Debug logging for invitation events
            if (isPendingInvitation) {
                Log.d("MapViewModel", "Pending invitation: '${event.title}' (private=${!isPublic}, showing=${showInvitations.value})")
            }
            
            if (isPotentialMatch) {
                Log.d("MapViewModel", "Potential match: '${event.title}' (isAutoMatched=${event.isAutoMatched}, isInRegistry=$isInRegistry, showing=${showPotentialMatches.value})")
                // Debug coordinate information for potential matches
                if (event.coordinate != null) {
                    Log.d("MapViewModel", "  - coordinates=${event.coordinate}")
                } else {
                    Log.d("MapViewModel", "  - coordinates=NULL ⚠️")
                }
            }
            
            // Apply all filters
            typeFilter && visibilityFilter && showBasedOnStatus
        }
    }
    
    // Load sample events for development/testing
    private fun loadSampleEvents() {
        events.clear()
        
        val currentUser = accountManager.currentUser ?: "guest"
        
        events.addAll(listOf(
            StudyEventMap(
                id = "1",
                title = "Mathematics Study Group",
                coordinate = Pair(-58.3816, -34.6037), // Buenos Aires
                time = LocalDateTime.now().plusHours(1),
                endTime = LocalDateTime.now().plusHours(3),
                description = "Join our study group to prepare for the math exam",
                invitedFriends = emptyList(),
                attendees = 5,
                isPublic = true,
                host = "John Doe",
                hostIsCertified = true,
                eventType = EventType.STUDY,
                isUserAttending = false
            ),
            StudyEventMap(
                id = "2",
                title = "Physics Study Session",
                coordinate = Pair(-58.3796, -34.6017), // Near Buenos Aires
                time = LocalDateTime.now().plusHours(2),
                endTime = LocalDateTime.now().plusHours(4),
                description = "Physics study session focusing on mechanics",
                invitedFriends = listOf(currentUser),
                attendees = 3,
                isPublic = false,
                host = "Jane Smith",
                hostIsCertified = false,
                eventType = EventType.STUDY,
                isUserAttending = false  // User has not accepted yet
            ),
            StudyEventMap(
                id = "3",
                title = "Startup Networking",
                coordinate = Pair(-58.3836, -34.6057), // Also near Buenos Aires
                time = LocalDateTime.now().plusHours(5),
                endTime = LocalDateTime.now().plusHours(7),
                description = "Connect with other entrepreneurs",
                invitedFriends = emptyList(),
                attendees = 12,
                isPublic = true,
                host = "Startup Hub",
                hostIsCertified = true,
                eventType = EventType.BUSINESS,
                isUserAttending = true  // User is attending this event
            ),
            StudyEventMap(
                id = "4",
                title = "Weekend Party",
                coordinate = Pair(-58.3786, -34.6077), // Also near Buenos Aires
                time = LocalDateTime.now().plusDays(1),
                endTime = LocalDateTime.now().plusDays(1).plusHours(4),
                description = "Come join our weekend party!",
                invitedFriends = emptyList(),
                attendees = 25,
                isPublic = true,
                host = "Party Planners",
                hostIsCertified = false,
                eventType = EventType.PARTY,
                isUserAttending = true  // User is attending this event
            ),
            StudyEventMap(
                id = "5",
                title = "Language Exchange",
                coordinate = Pair(-58.3846, -34.6047), // Also near Buenos Aires
                time = LocalDateTime.now().plusDays(2),
                endTime = LocalDateTime.now().plusDays(2).plusHours(2),
                description = "Practice your language skills",
                invitedFriends = listOf(currentUser),
                attendees = 8,
                isPublic = true,
                host = "Language Club",
                hostIsCertified = false,
                eventType = EventType.OTHER,
                isUserAttending = false  // User has not accepted yet
            ),
            // Add sample auto-matched potential event
            StudyEventMap(
                id = "6",
                title = "AI Research Group",
                coordinate = Pair(-58.3766, -34.6027), // Near Buenos Aires
                time = LocalDateTime.now().plusHours(6),
                endTime = LocalDateTime.now().plusHours(9),
                description = "Discuss recent advances in AI research",
                invitedFriends = emptyList(),
                attendees = 6,
                isPublic = false,
                host = "AI Lab",
                hostIsCertified = true,
                eventType = EventType.STUDY,
                isUserAttending = false,
                isAutoMatched = true  // This is an auto-matched event
            ),
            // Another auto-matched event
            StudyEventMap(
                id = "7",
                title = "UX Design Workshop",
                coordinate = Pair(-58.3826, -34.6087), // Also near Buenos Aires
                time = LocalDateTime.now().plusDays(1).plusHours(2),
                endTime = LocalDateTime.now().plusDays(1).plusHours(5),
                description = "Learn about the latest UX design trends",
                invitedFriends = emptyList(),
                attendees = 10,
                isPublic = false,
                host = "DesignHub",
                hostIsCertified = false,
                eventType = EventType.OTHER,
                isUserAttending = false,
                isAutoMatched = true  // This is an auto-matched event
            )
        ))
        Log.d("MapViewModel", "Loaded ${events.size} sample events")
    }

    // Callback that will be passed to EventDetailView
    // This ensures we refresh the map data when an RSVP operation completes
    val onRsvpComplete: () -> Unit = {
        Log.d("MapViewModel", "🔄 RSVP completed, refreshing map events")
        // Reload events immediately to ensure we have the latest data
        loadEvents()
        // No snackbar is shown as requested by the user
    }

    // Create a test potential match event for debugging
    fun createTestPotentialMatch() {
        val username = accountManager.currentUser ?: "guest"
        Log.d("MapViewModel", "🔄 Creating test potential match for user: $username")
        
        isLoading.value = true
        
        viewModelScope.launch {
            repository.createTestAutoMatchedEvent(username).collect { result ->
                isLoading.value = false
                
                result.fold(
                    onSuccess = { event ->
                        // Add the new event to the list
                        events.add(event)
                        Log.d("MapViewModel", "✅ Added test potential match: ${event.title}")
                        
                        // Automatically enable showing potential matches
                        showPotentialMatches.value = true
                    },
                    onFailure = { error ->
                        errorMessage.value = "Failed to create test match: ${error.message}"
                        Log.e("MapViewModel", "❌ Error creating test potential match", error)
                    }
                )
            }
        }
    }
}

/**
 * Factory for creating MapViewModel with the UserAccountManager
 */
class MapViewModelFactory(private val accountManager: UserAccountManager) : androidx.lifecycle.ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(MapViewModel::class.java)) {
            return MapViewModel(accountManager) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FullScreenMapView(
    onClose: () -> Unit,
    accountManager: UserAccountManager,
    viewModel: MapViewModel = androidx.lifecycle.viewmodel.compose.viewModel(
        factory = MapViewModelFactory(accountManager)
    )
) {
    val context = LocalContext.current
    val events = viewModel.getFilteredEvents()
    
    // State management
    var mapView by remember { mutableStateOf<MapView?>(null) }
    var mapReady by remember { mutableStateOf(false) }
    var isMapError by remember { mutableStateOf(false) }
    var currentZoom by remember { mutableStateOf(14.0) }
    
    // Loading and error states from ViewModel
    val isLoading = viewModel.isLoading.value
    val errorMessage = viewModel.errorMessage.value
    
    // Search state
    var isSearching by remember { mutableStateOf(false) }
    var searchQuery by remember { mutableStateOf("") }
    var searchResults by remember { mutableStateOf(listOf<String>()) }
    
    // Current user display
    val currentUsername = accountManager.currentUser ?: "Guest"
    
    // Filter state
    var showFilterDialog by remember { mutableStateOf(false) }
    
    // Profile state
    var showProfileView by remember { mutableStateOf(false) }
    
    // PointAnnotationManager for adding markers
    var pointAnnotationManager by remember { mutableStateOf<PointAnnotationManager?>(null) }
    
    // Used to track clusters for updates
    var currentClusters by remember { mutableStateOf(listOf<com.example.pinit.components.map.Cluster>()) }
    
    val coroutineScope = rememberCoroutineScope()
    
    // Buenos Aires coordinates as default
    val buenosAiresPoint = Point.fromLngLat(-58.3816, -34.6037)
    
    // Animate search bar expansion
    val searchBarWidth by animateDpAsState(
        targetValue = if (isSearching) 280.dp else 48.dp, 
        label = "searchBarWidth"
    )
    
    // New state variables
    var showEventDetails by remember { mutableStateOf(false) }
    var selectedEventId by remember { mutableStateOf<String?>(null) }
    var showEventCreation by remember { mutableStateOf(false) }
    var selectedCoordinate by remember { mutableStateOf<Pair<Double, Double>?>(null) }
    
    // Effect to update annotations when events or filters change
    LaunchedEffect(events, mapReady, currentZoom) {
        if (mapReady && mapView != null && pointAnnotationManager != null) {
            updateMapAnnotations(mapView!!, pointAnnotationManager!!, events, currentZoom, 
                onClusterClick = { cluster ->
                    // Handle cluster click
                    Log.d("FullScreenMapView", "Cluster clicked: ${cluster.events.size} events")
                    
                    // If zoomed in far enough and small cluster, show details
                    if (currentZoom > 14.0 && cluster.events.size <= 3) {
                        // Show the first event in the cluster
                        if (cluster.events.isNotEmpty()) {
                            selectedEventId = cluster.events[0].id
                            showEventDetails = true
                        }
                    } else {
                        // Zoom in to cluster
                        mapView?.mapboxMap?.let { mapboxMap ->
                            mapboxMap.setCamera(
                                CameraOptions.Builder()
                                    .center(cluster.coordinate)
                                    .zoom(currentZoom + 1.5)
                                    .build()
                            )
                        }
                    }
                },
                onSingleEventClick = { event ->
                    // Handle single event click
                    Log.d("FullScreenMapView", "Event clicked: ${event.title}")
                    selectedEventId = event.id
                    showEventDetails = true
                }
            )
        }
    }
    
    // Snackbar host state for notifications
    val snackbarHostState = remember { SnackbarHostState() }
    
    Scaffold(
        // Bottom app bar with menu actions
        bottomBar = {
            BottomAppBar(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Home
                    IconButton(onClick = { /* home action */ }) {
                        Icon(
                            imageVector = Icons.Default.Home,
                            contentDescription = "Home"
                        )
                    }
                    
                    // Map
                    IconButton(onClick = { /* map action */ }) {
                        Icon(
                            imageVector = Icons.Default.Map,
                            contentDescription = "Map",
                            tint = MaterialTheme.colorScheme.primary // Highlighted as current screen
                        )
                    }
                    
                    // Refresh events
                    IconButton(onClick = { viewModel.loadEvents() }) {
                        Icon(
                            imageVector = Icons.Default.Refresh,
                            contentDescription = "Refresh Events"
                        )
                    }
                    
                    // Filter
                    IconButton(onClick = { showFilterDialog = true }) {
                        Icon(
                            imageVector = Icons.Default.FilterList,
                            contentDescription = "Filter Events"
                        )
                    }
                    
                    // Profile
                    IconButton(onClick = { showProfileView = true }) {
                        Icon(
                            imageVector = Icons.Default.Person,
                            contentDescription = "Profile"
                        )
                    }
                }
            }
        },
        
        // Snackbar host for notifications
        snackbarHost = {
            SnackbarHost(hostState = snackbarHostState)
        },
        
        // Rest of the content
        content = { innerPadding -> 
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .background(MaterialTheme.colorScheme.background)
            ) {
                // Map view
                if (!isMapError) {
                    AndroidView(
                        factory = { ctx ->
                            MapView(ctx).apply {
                                mapView = this
                                
                                mapboxMap.apply {
                                    // Set initial camera position
                                    setCamera(CameraOptions.Builder()
                                        .center(buenosAiresPoint)
                                        .zoom(14.0)
                                        .pitch(45.0)
                                        .bearing(15.0)
                                        .build()
                                    )
                                    
                                    // Listen for camera changes to update zoom level
                                    addOnCameraChangeListener {
                                        currentZoom = cameraState.zoom
                                    }
                                    
                                    // Load map style
                                    loadStyleUri(Style.MAPBOX_STREETS) { style ->
                                        mapReady = true
                                        
                                        // Create annotation manager
                                        val annotationApi = annotations
                                        pointAnnotationManager = annotationApi.createPointAnnotationManager()
                                    }
                                }
                            }
                        },
                        modifier = Modifier.fillMaxSize()
                    )
                }
                
                // Loading indicator
                if (isLoading) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(Color.Black.copy(alpha = 0.5f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            CircularProgressIndicator(color = Color.White)
                            Text(
                                text = "Loading events for $currentUsername...",
                                color = Color.White,
                                style = MaterialTheme.typography.bodyLarge
                            )
                        }
                    }
                }
                
                // Error message
                if (errorMessage != null) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                            .align(Alignment.TopCenter)
                            .background(MaterialTheme.colorScheme.errorContainer, RoundedCornerShape(8.dp))
                            .padding(16.dp)
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Text(
                                text = errorMessage,
                                color = MaterialTheme.colorScheme.onErrorContainer,
                                style = MaterialTheme.typography.bodyMedium
                            )
                            Button(
                                onClick = { viewModel.loadEvents() },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = MaterialTheme.colorScheme.error,
                                    contentColor = MaterialTheme.colorScheme.onError
                                )
                            ) {
                                Icon(Icons.Default.Refresh, contentDescription = "Retry")
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Retry")
                            }
                        }
                    }
                }
                
                // Top app bar with controls
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    // Top bar with back button, search, and filter
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(56.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        IconButton(
                            onClick = onClose,
                            modifier = Modifier
                                .size(48.dp)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.8f))
                        ) {
                            Icon(
                                Icons.AutoMirrored.Filled.ArrowBack,
                                contentDescription = "Back",
                                tint = MaterialTheme.colorScheme.onSurface
                            )
                        }
                        
                        Spacer(modifier = Modifier.width(8.dp))
                        
                        // Search bar
                        Box(
                            modifier = Modifier
                                .width(searchBarWidth)
                                .height(48.dp)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.8f))
                                .clickable { isSearching = true }
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxSize()
                                    .padding(horizontal = 16.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    Icons.Default.Search,
                                    contentDescription = "Search",
                                    tint = MaterialTheme.colorScheme.onSurface
                                )
                                
                                if (isSearching) {
                                    Spacer(modifier = Modifier.width(8.dp))
                                    
                                    TextField(
                                        value = searchQuery,
                                        onValueChange = { newValue ->
                                            searchQuery = newValue
                                            if (newValue.isNotEmpty()) {
                                                viewModel.searchEvents(newValue)
                                            } else {
                                                viewModel.loadEvents()
                                            }
                                        },
                                        placeholder = { 
                                            Text(
                                                text = "Search events...",
                                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                                            )
                                        },
                                        colors = TextFieldDefaults.colors(
                                            focusedContainerColor = Color.Transparent,
                                            unfocusedContainerColor = Color.Transparent,
                                            disabledContainerColor = Color.Transparent,
                                            focusedIndicatorColor = Color.Transparent,
                                            unfocusedIndicatorColor = Color.Transparent
                                        ),
                                        modifier = Modifier
                                            .weight(1f)
                                            .padding(vertical = 8.dp),
                                        singleLine = true
                                    )
                                    
                                    if (searchQuery.isNotEmpty()) {
                                        IconButton(onClick = {
                                            searchQuery = ""
                                            viewModel.loadEvents()
                                        }) {
                                            Icon(
                                                Icons.Default.Clear,
                                                contentDescription = "Clear search",
                                                tint = MaterialTheme.colorScheme.onSurface
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Username display
                    if (accountManager.isLoggedIn) {
                        Box(
                            modifier = Modifier
                                .align(Alignment.End)
                                .padding(top = 8.dp)
                                .clip(RoundedCornerShape(16.dp))
                                .background(MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.8f))
                                .clickable { showProfileView = true }
                                .padding(horizontal = 12.dp, vertical = 4.dp)
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    Icons.Default.Person, 
                                    contentDescription = "User",
                                    tint = MaterialTheme.colorScheme.onPrimaryContainer,
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = "${currentUsername}${if (accountManager.isCertified) " ✓" else ""}",
                                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                                    style = MaterialTheme.typography.labelMedium,
                                    fontWeight = FontWeight.Medium
                                )
                            }
                        }
                    }
                }
                
                // Location label
                if (mapReady) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.TopCenter)
                            .padding(top = 80.dp)
                            .clip(RoundedCornerShape(16.dp))
                            .background(Color.White.copy(alpha = 0.8f))
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                    ) {
                        Text(
                            text = "Buenos Aires, Argentina",
                            color = Color.Black,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
                
                // Add Event FAB
                FloatingActionButton(
                    onClick = {
                        // Use current center of map as the coordinate for the new event
                        mapView?.mapboxMap?.let { mapboxMap ->
                            val center = mapboxMap.cameraState.center
                            selectedCoordinate = Pair(center.longitude(), center.latitude())
                            showEventCreation = true
                        }
                    },
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .padding(16.dp),
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                ) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = "Create Event"
                    )
                }
                
                // Potential matches toggle button
                Box(
                    modifier = Modifier
                        .align(Alignment.BottomStart)
                        .padding(16.dp)
                ) {
                    FloatingActionButton(
                        onClick = {
                            // Toggle between showing all events and only potential matches
                            viewModel.showOnlyPotentialMatches.value = !viewModel.showOnlyPotentialMatches.value
                            
                            // Show a toast to indicate the mode change
                            val message = if (viewModel.showOnlyPotentialMatches.value) 
                                "Showing only potential matches" 
                            else 
                                "Showing all events"
                            
                            coroutineScope.launch {
                                snackbarHostState.showSnackbar(
                                    message = message,
                                    duration = SnackbarDuration.Short
                                )
                            }
                        },
                        containerColor = if (viewModel.showOnlyPotentialMatches.value)
                            MaterialTheme.colorScheme.primary
                        else
                            MaterialTheme.colorScheme.secondaryContainer
                    ) {
                        Icon(
                            imageVector = Icons.Default.Favorite,
                            contentDescription = "Toggle Potential Matches",
                            tint = if (viewModel.showOnlyPotentialMatches.value)
                                Color.White
                            else
                                MaterialTheme.colorScheme.onSecondaryContainer
                        )
                    }
                    
                    // Count of potential matches as badge
                    val potentialMatches = events.count { event ->
                        val userIsHost = event.host == accountManager.currentUser ?: ""
                        val userIsAttending = event.isUserAttending
                        val isInRegistry = com.example.pinit.utils.PotentialMatchRegistry.isEventPotentialMatch(event.id)
                        (event.isAutoMatched || isInRegistry) && !userIsAttending && !userIsHost
                    }
                    
                    if (potentialMatches > 0) {
                        Badge(
                            modifier = Modifier
                                .align(Alignment.TopEnd)
                                .offset(x = 8.dp, y = (-8).dp)
                                .size(24.dp),
                            containerColor = MaterialTheme.colorScheme.primary
                        ) {
                            Text(
                                text = potentialMatches.toString(),
                                color = Color.White,
                                style = MaterialTheme.typography.labelSmall
                            )
                        }
                    }
                }
            }
            
            // Filter dialog
            if (showFilterDialog) {
                AlertDialog(
                    onDismissRequest = { showFilterDialog = false },
                    title = { Text("Filter Events") },
                    text = {
                        Column {
                            Text("Event Types", fontWeight = FontWeight.Bold)
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            // Study events toggle
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text("Study Events")
                                Spacer(modifier = Modifier.weight(1f))
                                Switch(
                                    checked = viewModel.showEventTypes[EventType.STUDY] ?: true,
                                    onCheckedChange = { 
                                        viewModel.showEventTypes[EventType.STUDY] = it
                                    }
                                )
                            }
                            
                            // Party events toggle
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text("Party Events")
                                Spacer(modifier = Modifier.weight(1f))
                                Switch(
                                    checked = viewModel.showEventTypes[EventType.PARTY] ?: true,
                                    onCheckedChange = { 
                                        viewModel.showEventTypes[EventType.PARTY] = it
                                    }
                                )
                            }
                            
                            // Business events toggle
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text("Business Events")
                                Spacer(modifier = Modifier.weight(1f))
                                Switch(
                                    checked = viewModel.showEventTypes[EventType.BUSINESS] ?: true,
                                    onCheckedChange = { 
                                        viewModel.showEventTypes[EventType.BUSINESS] = it
                                    }
                                )
                            }
                            
                            // Other events toggle
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text("Other Events")
                                Spacer(modifier = Modifier.weight(1f))
                                Switch(
                                    checked = viewModel.showEventTypes[EventType.OTHER] ?: true,
                                    onCheckedChange = { 
                                        viewModel.showEventTypes[EventType.OTHER] = it
                                    }
                                )
                            }
                            
                            HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))
                            
                            // Private events toggle
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text("Show Private Events")
                                Spacer(modifier = Modifier.weight(1f))
                                Switch(
                                    checked = viewModel.showPrivateEvents.value,
                                    onCheckedChange = { 
                                        viewModel.showPrivateEvents.value = it
                                    }
                                )
                            }
                            
                            HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))
                            
                            Text(
                                text = "Invitation Settings",
                                style = MaterialTheme.typography.titleMedium,
                                modifier = Modifier.padding(vertical = 8.dp)
                            )
                            
                            // Pending invitations toggle
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text("Show Pending Invitations")
                                Spacer(modifier = Modifier.weight(1f))
                                Switch(
                                    checked = viewModel.showInvitations.value,
                                    onCheckedChange = { 
                                        viewModel.showInvitations.value = it
                                    }
                                )
                            }
                            
                            // Potential matches toggle
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text("Show Potential Matches")
                                Spacer(modifier = Modifier.weight(1f))
                                Switch(
                                    checked = viewModel.showPotentialMatches.value,
                                    onCheckedChange = { 
                                        viewModel.showPotentialMatches.value = it
                                    }
                                )
                            }
                            
                            HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))
                            
                            // "Show only potential matches" toggle
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .background(
                                        color = if (viewModel.showOnlyPotentialMatches.value) 
                                            MaterialTheme.colorScheme.primaryContainer
                                        else 
                                            Color.Transparent,
                                        shape = RoundedCornerShape(8.dp)
                                    )
                                    .padding(8.dp)
                            ) {
                                Column {
                                    Text(
                                        "Show Only Potential Matches", 
                                        fontWeight = FontWeight.Bold
                                    )
                                    Text(
                                        "Filter map to display only events that match your interests",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = Color.Gray
                                    )
                                }
                                Spacer(modifier = Modifier.weight(1f))
                                Switch(
                                    checked = viewModel.showOnlyPotentialMatches.value,
                                    onCheckedChange = { showOnly ->
                                        viewModel.showOnlyPotentialMatches.value = showOnly
                                        // When "Show only" is enabled, automatically enable potential matches
                                        if (showOnly) {
                                            viewModel.showPotentialMatches.value = true
                                        }
                                    }
                                )
                            }
                            
                            // For testing - create a sample auto-matched event
                            Spacer(modifier = Modifier.height(16.dp))
                            HorizontalDivider()
                            Spacer(modifier = Modifier.height(16.dp))
                            
                            // Debug section heading
                            Text(
                                text = "Debug Tools",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            // Create test match button
                            Button(
                                onClick = { 
                                    viewModel.createTestPotentialMatch() 
                                    showFilterDialog = false
                                },
                                modifier = Modifier.fillMaxWidth(),
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = MaterialTheme.colorScheme.tertiaryContainer,
                                    contentColor = MaterialTheme.colorScheme.onTertiaryContainer
                                )
                            ) {
                                Icon(
                                    imageVector = Icons.Default.BugReport,
                                    contentDescription = "Debug",
                                    modifier = Modifier.size(18.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Create Test Potential Match")
                            }
                        }
                    },
                    confirmButton = {
                        TextButton(onClick = { showFilterDialog = false }) {
                            Text("Done")
                        }
                    }
                )
            }
            
            // Profile View Dialog
            if (showProfileView) {
                ProfileView(
                    accountManager = accountManager,
                    onDismiss = { showProfileView = false },
                    onLogout = {
                        showProfileView = false
                        // Handle logout - navigate to login screen
                        onClose()
                    }
                )
            }
            
            // Event Detail Dialog
            if (showEventDetails && selectedEventId != null) {
                val event = events.find { it.id == selectedEventId }
                if (event != null) {
                    // Enhanced logging for event selection
                    Log.d("FullScreenMapView", "⭐️ DISPLAYING EventDetailView for event:")
                    Log.d("FullScreenMapView", "  ID: ${event.id}")
                    Log.d("FullScreenMapView", "  Title: ${event.title}")
                    Log.d("FullScreenMapView", "  Host: ${event.host}")
                    Log.d("FullScreenMapView", "  Type: ${event.eventType}")
                    Log.d("FullScreenMapView", "  Coordinates: ${event.coordinate?.first}, ${event.coordinate?.second}")
                    
                    // Pass the exact event ID to ensure correct event is loaded
                    event.id?.let { eventId ->
                        EventDetailView(
                            eventId = eventId,
                            initialEvent = event,
                            accountManager = accountManager,
                            onClose = { 
                                showEventDetails = false
                                selectedEventId = null
                                Log.d("FullScreenMapView", "Closed EventDetailView for event: ${event.id}")
                            },
                            onRsvpComplete = viewModel.onRsvpComplete
                        )
                    } ?: Log.e("FullScreenMapView", "Cannot show event details: Event ID is null")
                } else {
                    Log.e("FullScreenMapView", "❌ ERROR: Could not find event with ID: $selectedEventId in ${events.size} events")
                    // Log all available events for debugging
                    Log.d("FullScreenMapView", "Available events: ${events.map { "${it.id}:${it.title}" }}")
                }
            }
            
            // Event Creation Dialog
            if (showEventCreation && selectedCoordinate != null) {
                EventCreationView(
                    initialCoordinate = selectedCoordinate!!,
                    accountManager = accountManager,
                    onClose = { 
                        showEventCreation = false
                        selectedCoordinate = null
                    },
                    onSave = { newEvent ->
                        // Add the new event to the local list
                        viewModel.events.add(newEvent)
                        
                        // Refresh the full events list to ensure we have the latest data from server
                        viewModel.loadEvents()
                        
                        showEventCreation = false
                        selectedCoordinate = null
                        
                        // Show a success message
                        coroutineScope.launch {
                            snackbarHostState.showSnackbar(
                                "Event created successfully: ${newEvent.title}",
                                duration = SnackbarDuration.Short
                            )
                        }
                    }
                )
            }
        }
    )
}

/**
 * Update map annotations with clustered events
 */
private fun updateMapAnnotations(
    mapView: MapView,
    pointAnnotationManager: PointAnnotationManager,
    events: List<StudyEventMap>,
    zoomLevel: Double,
    onClusterClick: (com.example.pinit.components.map.Cluster) -> Unit,
    onSingleEventClick: (StudyEventMap) -> Unit
) {
    Log.d("FullScreenMapView", "Updating map annotations with ${events.size} events at zoom $zoomLevel")
    
    // Debug events with explicit coordinate checking
    Log.d("FullScreenMapView", "====== DEBUG EVENT DATA ======")
    events.forEachIndexed { index, event ->
        val coordString = if (event.coordinate != null) {
            "longitude=${event.coordinate.first}, latitude=${event.coordinate.second}"
        } else {
            "NULL"
        }
        Log.d("FullScreenMapView", "Event[$index]: id=${event.id}, title=${event.title}, coordinates=$coordString, type=${event.eventType}")
    }
    
    // Check for events with invalid coordinates
    val validEvents = events.filter { event -> 
        val isValid = event.coordinate != null && 
                      event.coordinate.first.isFinite() && 
                      event.coordinate.second.isFinite() &&
                      event.coordinate.first != 0.0 &&
                      event.coordinate.second != 0.0
        
        if (!isValid && event.coordinate != null) {
            Log.w("FullScreenMapView", "Event ${event.id} has invalid coordinates: ${event.coordinate}")
        }
        
        isValid
    }
    
    if (validEvents.size < events.size) {
        Log.w("FullScreenMapView", "Warning: ${events.size - validEvents.size} events have invalid coordinates and will be ignored")
    }
    
    // Debug valid events with coordinates
    Log.d("FullScreenMapView", "====== VALID EVENTS ======")
    validEvents.forEachIndexed { index, event ->
        Log.d("FullScreenMapView", "ValidEvent[$index]: id=${event.id}, title=${event.title}, " +
              "longitude=${event.coordinate?.first}, latitude=${event.coordinate?.second}, type=${event.eventType}")
    }
    
    // Clear existing annotations
    val previousCount = pointAnnotationManager.annotations.size
    pointAnnotationManager.deleteAll()
    Log.d("FullScreenMapView", "Cleared $previousCount previous annotations")
    
    // Clean up any existing click listeners to prevent duplicates
    pointAnnotationManager.removeClickListener { false }
    
    // Create a new annotation data map - using String keys to match the annotation IDs
    val annotationData = mutableMapOf<String, Any>()
    
    // Cluster the events based on current zoom level
    val mapViewport = mapView.getMapboxMap().getSize()
    val mapWidth = mapViewport.width.toInt()
    val mapHeight = mapViewport.height.toInt()
    Log.d("FullScreenMapView", "Map viewport: $mapWidth x $mapHeight pixels")

    // Use improved clustering with viewport dimensions
    val clusters = MapClusteringUtils.clusterEvents(validEvents, zoomLevel, mapWidth, mapHeight)
    Log.d("FullScreenMapView", "Created ${clusters.size} clusters from ${validEvents.size} events")
    
    // Debug cluster information
    clusters.forEachIndexed { index, cluster ->
        Log.d("FullScreenMapView", "Cluster[$index] with ${cluster.events.size} events at " +
              "(${cluster.coordinate.longitude()}, ${cluster.coordinate.latitude()})")
        
        // Log event IDs in this cluster
        val eventIds = cluster.events.map { it.id }
        Log.d("FullScreenMapView", "  Events in cluster: $eventIds")
    }
    
    var successfulAnnotations = 0
    var failedAnnotations = 0
    
    // Add clusters to the map
    clusters.forEach { cluster ->
        try {
            // For single event markers
            if (cluster.events.size == 1) {
                val event = cluster.events.first()
                
                // Create point annotation options directly with MapAnnotationUtils
                val pointAnnotationOptions = com.example.pinit.components.map.MapAnnotationUtils.createEventAnnotation(mapView.context, event)
                
                if (pointAnnotationOptions != null) {
                    // Add annotation to manager
                    val annotation = pointAnnotationManager.create(pointAnnotationOptions)
                    
                    // Store event with annotation ID
                    annotationData[annotation.id] = event
                    
                    successfulAnnotations++
                    Log.d("FullScreenMapView", "Added single event annotation for '${event.title}' at (${cluster.coordinate.longitude()}, ${cluster.coordinate.latitude()})")
                } else {
                    failedAnnotations++
                    Log.w("FullScreenMapView", "Failed to create annotation options for event ${event.id}")
                }
            } 
            // For clusters with multiple events
            else {
                // Create point annotation options directly with MapAnnotationUtils
                val pointAnnotationOptions = com.example.pinit.components.map.MapAnnotationUtils.createClusterAnnotation(mapView.context, cluster)
                
                if (pointAnnotationOptions != null) {
                    // Add annotation to manager
                    val annotation = pointAnnotationManager.create(pointAnnotationOptions)
                    
                    // Store cluster with annotation ID
                    annotationData[annotation.id] = cluster
                    
                    successfulAnnotations++
                    Log.d("FullScreenMapView", "Added cluster annotation with ${cluster.events.size} events at (${cluster.coordinate.longitude()}, ${cluster.coordinate.latitude()})")
                } else {
                    failedAnnotations++
                    Log.w("FullScreenMapView", "Failed to create annotation options for cluster with ${cluster.events.size} events")
                }
            }
        } catch (e: Exception) {
            failedAnnotations++
            Log.e("FullScreenMapView", "Error creating annotation: ${e.message}", e)
            e.printStackTrace()
        }
    }
    
    // Set up a single click listener for all annotations
    pointAnnotationManager.addClickListener { clickedAnnotation ->
        Log.d("FullScreenMapView", "Annotation clicked with ID: ${clickedAnnotation.id}")
        
        val data = annotationData[clickedAnnotation.id]
        if (data != null) {
            when (data) {
                is StudyEventMap -> {
                    Log.d("FullScreenMapView", "Handling click on event: ${data.title}")
                    onSingleEventClick(data)
                    true
                }
                is com.example.pinit.components.map.Cluster -> {
                    Log.d("FullScreenMapView", "Handling click on cluster with ${data.events.size} events")
                    onClusterClick(data)
                    true
                }
                else -> {
                    Log.w("FullScreenMapView", "Unknown annotation data type: ${data::class.java.simpleName}")
                    false
                }
            }
        } else {
            Log.w("FullScreenMapView", "No data found for annotation ID: ${clickedAnnotation.id}")
            false
        }
    }
    
    Log.d("FullScreenMapView", "====== FINAL ANNOTATIONS ON MAP ======")
    Log.d("FullScreenMapView", "Added $successfulAnnotations annotations ($failedAnnotations failed)")
    pointAnnotationManager.annotations.forEachIndexed { index, annotation ->
        val point = annotation.point
        val textField = annotation.textField ?: "No ID"
        Log.d("FullScreenMapView", "Annotation[$index]: ID=${annotation.id}, TextField=$textField, Position=(${point.longitude()}, ${point.latitude()})")
    }
    
    // Warning if no annotations were created
    if (successfulAnnotations == 0 && validEvents.isNotEmpty()) {
        Log.w("FullScreenMapView", "WARNING: No annotations were created despite having ${validEvents.size} valid events")
        Log.w("FullScreenMapView", "Please check the event coordinates and annotation creation logic")
    }
}

/**
 * Extension function to create a bitmap from a View
 */
fun android.view.View.createViewBitmap(): android.graphics.Bitmap {
    // Force layout calculation
    measure(
        android.view.View.MeasureSpec.makeMeasureSpec(0, android.view.View.MeasureSpec.UNSPECIFIED),
        android.view.View.MeasureSpec.makeMeasureSpec(0, android.view.View.MeasureSpec.UNSPECIFIED)
    )
    
    // Layout with calculated dimensions
    layout(0, 0, measuredWidth, measuredHeight)
    
    // Create bitmap of same size
    val bitmap = android.graphics.Bitmap.createBitmap(
        measuredWidth, measuredHeight, android.graphics.Bitmap.Config.ARGB_8888
    )
    
    // Draw view into bitmap
    val canvas = android.graphics.Canvas(bitmap)
    background?.draw(canvas) ?: canvas.drawColor(android.graphics.Color.TRANSPARENT)
    draw(canvas)
    
    return bitmap
}

@Composable
private fun EventDetailDialog(
    eventId: String,
    initialEvent: StudyEventMap,
    accountManager: UserAccountManager,
    viewModel: MapViewModel,
    onDismiss: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.5f))
            .clickable(onClick = onDismiss)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .fillMaxHeight(0.95f)
                .align(Alignment.BottomCenter)
                .background(
                    color = MaterialTheme.colorScheme.background,
                    shape = RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp)
                )
                .clickable(enabled = false) { /* Consume clicks inside dialog */ }
        ) {
            EventDetailView(
                eventId = eventId,
                initialEvent = initialEvent,
                accountManager = accountManager,
                onClose = onDismiss,
                onRsvpComplete = viewModel.onRsvpComplete
            )
        }
    }
}
