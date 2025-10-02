package com.example.pinit.components

import android.graphics.BitmapFactory
import android.util.Log
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import com.example.pinit.ui.theme.*
import com.example.pinit.models.EventType
import com.example.pinit.models.StudyEventMap
import com.example.pinit.repository.EventRepository
import com.example.pinit.utils.PotentialMatchRegistry
import com.mapbox.geojson.Point
import com.mapbox.maps.CameraOptions
import com.mapbox.maps.MapView
import com.mapbox.maps.Style
import com.mapbox.maps.plugin.annotation.annotations
import com.mapbox.maps.plugin.annotation.generated.PointAnnotationManager
import com.mapbox.maps.plugin.annotation.generated.PointAnnotationOptions
import com.mapbox.maps.plugin.annotation.generated.createPointAnnotationManager
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

enum class EventViewMode {
    ALL, AUTO_MATCHED, MY_EVENTS
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BasicFullMapView(
    onDismiss: () -> Unit,
    username: String = "user1" // Default user for testing
) {
    // Track map loading state
    var isMapReady by remember { mutableStateOf(false) }
    var mapError by remember { mutableStateOf<String?>(null) }
    val context = LocalContext.current
    
    // iOS-style view mode selector
    var eventViewMode by remember { mutableStateOf(EventViewMode.ALL) }
    var showViewModeSelector by remember { mutableStateOf(false) }
    val coroutineScope = rememberCoroutineScope()
    val repository = remember { EventRepository() }
    
    // State for events and filters
    var events by remember { mutableStateOf<List<StudyEventMap>>(emptyList()) }
    var filteredEvents by remember { mutableStateOf<List<StudyEventMap>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    
    // Filter states
    var showOnlyMatched by remember { mutableStateOf(true) }
    var showEventTypes by remember { mutableStateOf(mapOf(
        EventType.STUDY to true,
        EventType.PARTY to true, 
        EventType.BUSINESS to true,
        EventType.CULTURAL to true,
        EventType.ACADEMIC to true,
        EventType.NETWORKING to true,
        EventType.SOCIAL to true,
        EventType.LANGUAGE_EXCHANGE to true,
        EventType.OTHER to true
    )) }
    
    // Map state
    var pointAnnotationManager by remember { mutableStateOf<PointAnnotationManager?>(null) }
    var mapView by remember { mutableStateOf<MapView?>(null) }
    
    // Cluster bottom sheet state
    var showClusterBottomSheet by remember { mutableStateOf(false) }
    var clusterEvents by remember { mutableStateOf<List<StudyEventMap>>(emptyList()) }
    
    // Fetch events when the component is first displayed
    LaunchedEffect(key1 = username) {
        isLoading = true
        try {
            repository.getEventsForUser(username).collectLatest { result ->
                result.fold(
                    onSuccess = { eventsList ->
                        Log.d("BasicFullMapView", "Fetched ${eventsList.size} events for user $username")
                        events = eventsList
                        applyFilters(events, showOnlyMatched, showEventTypes, username).let {
                            filteredEvents = it
                            Log.d("BasicFullMapView", "Applied filters: ${it.size} events visible")
                        }
                        isLoading = false
                    },
                    onFailure = { error ->
                        Log.e("BasicFullMapView", "Error fetching events: ${error.message}", error)
                        mapError = "Failed to load events: ${error.localizedMessage}"
                        isLoading = false
                    }
                )
            }
        } catch (e: Exception) {
            Log.e("BasicFullMapView", "Exception in event fetching: ${e.message}", e)
            mapError = "Error: ${e.localizedMessage}"
            isLoading = false
        }
    }
    
    // Update filtered events when filter changes
    LaunchedEffect(showOnlyMatched, showEventTypes, events, eventViewMode) {
        Log.d("BasicFullMapView", "Applying filters for user $username - showOnlyMatched=$showOnlyMatched, eventTypes=${showEventTypes.entries.filter { it.value }.map { it.key }}, viewMode=$eventViewMode")
        filteredEvents = applyFiltersWithViewMode(events, showOnlyMatched, showEventTypes, username, eventViewMode)
        Log.d("BasicFullMapView", "After filtering: ${filteredEvents.size} of ${events.size} events visible")
        
        // Update map annotations if map is ready
        if (isMapReady && mapView != null && pointAnnotationManager != null) {
            updateMapAnnotations(mapView!!, pointAnnotationManager!!, filteredEvents)
        }
    }
    
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = BgSurface
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Events Map",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
                
                IconButton(onClick = onDismiss) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Close",
                        tint = TextPrimary
                    )
                }
            }
            
            // Filter toggle
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(Color(0xFFEEEEEE))
                    .clickable { showOnlyMatched = !showOnlyMatched }
                    .padding(12.dp),
                horizontalArrangement = Arrangement.Start,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.FilterList,
                    contentDescription = "Filter",
                    tint = if (showOnlyMatched) BrandPrimary else TextSecondary
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = if (showOnlyMatched) "Showing matched events only" else "Showing all events",
                    color = if (showOnlyMatched) BrandPrimary else TextSecondary
                )
            }
            
            // Event type filters
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                EventType.values().forEach { eventType ->
                    val isSelected = showEventTypes[eventType] == true
                    FilterChip(
                        selected = isSelected,
                        onClick = {
                            showEventTypes = showEventTypes.toMutableMap().apply {
                                put(eventType, !isSelected)
                            }
                        },
                        label = { Text(eventType.displayName) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = when(eventType) {
                                EventType.STUDY -> Color(0xFF007AFF)      // iOS Blue
                                EventType.PARTY -> Color(0xFFAF52DE)      // iOS Purple
                                EventType.BUSINESS -> Color(0xFF5856D6)  // iOS Indigo
                                EventType.CULTURAL -> Color(0xFFFF9500)  // iOS Orange
                                EventType.ACADEMIC -> Color(0xFF34C759)  // iOS Green
                                EventType.NETWORKING -> Color(0xFFFF2D92) // iOS Pink
                                EventType.SOCIAL -> Color(0xFFFF3B30)    // iOS Red
                                EventType.LANGUAGE_EXCHANGE -> Color(0xFF5AC8FA) // iOS Teal
                                EventType.OTHER -> Color(0xFF8E8E93)     // iOS Gray
                                else -> Color(0xFF8E8E93) // Default iOS Gray
                            }.copy(alpha = 0.2f),
                            selectedLabelColor = when(eventType) {
                                EventType.STUDY -> Color(0xFF007AFF)      // iOS Blue
                                EventType.PARTY -> Color(0xFFAF52DE)      // iOS Purple
                                EventType.BUSINESS -> Color(0xFF5856D6)  // iOS Indigo
                                EventType.CULTURAL -> Color(0xFFFF9500)  // iOS Orange
                                EventType.ACADEMIC -> Color(0xFF34C759)  // iOS Green
                                EventType.NETWORKING -> Color(0xFFFF2D92) // iOS Pink
                                EventType.SOCIAL -> Color(0xFFFF3B30)    // iOS Red
                                EventType.LANGUAGE_EXCHANGE -> Color(0xFF5AC8FA) // iOS Teal
                                EventType.OTHER -> Color(0xFF8E8E93)     // iOS Gray
                                else -> Color(0xFF8E8E93) // Default iOS Gray
                            }
                        )
                    )
                }
            }
            
            // Map view
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(400.dp)
                    .padding(horizontal = 16.dp)
            ) {
                // Mapbox map using the simplest method possible
                AndroidView(
                    factory = { ctx ->
                        try {
                            Log.d("BasicFullMapView", "Creating MapView")
                            
                            // Create the MapView using the simplest constructor
                            val mapViewInstance = MapView(ctx)
                            mapView = mapViewInstance
                            
                            // Buenos Aires coordinates (center of the map)
                            val buenosAiresCoordinates = Point.fromLngLat(-58.3816, -34.6037)
                            
                            // Configure camera position
                            val cameraPosition = CameraOptions.Builder()
                                .center(buenosAiresCoordinates)
                                .zoom(12.0) // Adjusted for better overview of events
                                .pitch(0.0) // Flat view for better marker visibility
                                .bearing(0.0) // No rotation
                                .build()
                            
                            // Set camera position before loading style
                            mapViewInstance.mapboxMap.setCamera(cameraPosition)
                            
                            // Create annotation manager for markers
                            val annotationsPlugin = mapViewInstance.annotations
                            pointAnnotationManager = annotationsPlugin.createPointAnnotationManager()
                            
                            // Add click listener for annotations
                            pointAnnotationManager?.addClickListener { annotation ->
                                val eventTitle = annotation.textField
                                Log.d("BasicFullMapView", "Clicked on annotation: $eventTitle")
                                
                                // Find the event(s) at this location
                                val clickedEvents = filteredEvents.filter { event ->
                                    event.coordinate?.let { coord ->
                                        val annotationPoint = annotation.point
                                        val eventPoint = Point.fromLngLat(coord.first, coord.second)
                                        // Check if points are very close (within 0.0001 degrees ≈ 11m)
                                        kotlin.math.abs(annotationPoint.longitude() - eventPoint.longitude()) < 0.0001 &&
                                        kotlin.math.abs(annotationPoint.latitude() - eventPoint.latitude()) < 0.0001
                                    } ?: false
                                }
                                
                                if (clickedEvents.size > 1) {
                                    // Multiple events at same location - show cluster bottom sheet
                                    clusterEvents = clickedEvents
                                    showClusterBottomSheet = true
                                    Log.d("BasicFullMapView", "Showing cluster bottom sheet with ${clickedEvents.size} events")
                                } else if (clickedEvents.size == 1) {
                                    // Single event - handle normally (you can add event detail navigation here)
                                    Log.d("BasicFullMapView", "Single event clicked: ${clickedEvents.first().title}")
                                }
                                
                                true // Consume the click event
                            }
                            
                            // Load a basic map style
                            mapViewInstance.getMapboxMap().loadStyleUri(Style.MAPBOX_STREETS) {
                                // Ensure camera is still correctly positioned after style loads
                                mapViewInstance.mapboxMap.setCamera(cameraPosition)
                                isMapReady = true
                                Log.d("BasicFullMapView", "Map style loaded successfully")
                                
                                // Add event markers once the map and events are ready
                                if (filteredEvents.isNotEmpty() && pointAnnotationManager != null) {
                                    updateMapAnnotations(mapViewInstance, pointAnnotationManager!!, filteredEvents)
                                }
                            }
                            
                            // Return the map view
                            mapViewInstance
                        } catch (e: Exception) {
                            Log.e("BasicFullMapView", "Error creating MapView: ${e.message}", e)
                            mapError = e.message
                            // Return empty view on error
                            android.view.View(ctx)
                        }
                    },
                    update = { viewInstance ->
                        // Cast the view to MapView only if it's the right type
                        if (viewInstance is MapView && isMapReady && !isLoading && 
                            filteredEvents.isNotEmpty() && pointAnnotationManager != null) {
                            // Update map annotations when filtered events change
                            updateMapAnnotations(viewInstance, pointAnnotationManager!!, filteredEvents)
                        }
                    },
                    modifier = Modifier.fillMaxSize()
                )
                
                // iOS-style View Mode Selector (bottom left)
                Box(
                    modifier = Modifier
                        .align(Alignment.BottomStart)
                        .padding(start = 16.dp, bottom = 16.dp)
                ) {
                    ViewModeSelector(
                        currentMode = eventViewMode,
                        onModeClick = { showViewModeSelector = true }
                    )
                }
                
                // Loading or error overlay
                if (!isMapReady || isLoading) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(Color.LightGray.copy(alpha = 0.7f)),
                        contentAlignment = Alignment.Center
                    ) {
                        if (mapError != null) {
                            // Error message
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                modifier = Modifier.padding(16.dp)
                            ) {
                                Text(
                                    text = "Could not load map",
                                    fontWeight = FontWeight.Bold,
                                    color = Color.Red
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    text = mapError ?: "Unknown error",
                                    color = Color.DarkGray,
                                    textAlign = TextAlign.Center
                                )
                            }
                        } else {
                            // Loading indicator
                            CircularProgressIndicator(color = BrandPrimary)
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Stats about displayed events
            if (!isLoading) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.padding(horizontal = 32.dp)
                ) {
                    Text(
                        text = "Showing ${filteredEvents.size} of ${events.size} total events",
                        style = MaterialTheme.typography.bodyMedium,
                        color = TextSecondary,
                        textAlign = TextAlign.Center
                    )
                    
                    // Display info about potential matches
                    val matchedCount = events.count { it.isAutoMatched || (it.id?.let { id -> PotentialMatchRegistry.isEventPotentialMatch(id) } ?: false) }
                    if (matchedCount > 0) {
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Found $matchedCount events matched to your interests",
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color(0xFF9C27B0), // Purple
                            textAlign = TextAlign.Center,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Close button
            Button(
                onClick = onDismiss,
                colors = ButtonDefaults.buttonColors(
                    containerColor = PrimaryColor
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
            ) {
                Text("Close Map")
            }
        }
    }
    
    // View Mode Selector Dialog
    if (showViewModeSelector) {
        ViewModeSelectorDialog(
            currentMode = eventViewMode,
            onModeSelected = { mode ->
                eventViewMode = mode
                showViewModeSelector = false
            },
            onDismiss = { showViewModeSelector = false }
        )
    }
    
    // Cluster Bottom Sheet
    if (showClusterBottomSheet) {
        EventClusterBottomSheet(
            events = clusterEvents,
            onEventClick = { event ->
                // Handle individual event click (you can add navigation here)
                Log.d("BasicFullMapView", "Event clicked from cluster: ${event.title}")
                showClusterBottomSheet = false
            },
            onDismiss = { showClusterBottomSheet = false }
        )
    }
}

@Composable
fun ViewModeSelector(
    currentMode: EventViewMode,
    onModeClick: () -> Unit
) {
    val (icon, label, color) = when (currentMode) {
        EventViewMode.ALL -> Triple("🌍", "All Events", Color(0xFF007AFF))
        EventViewMode.AUTO_MATCHED -> Triple("🎯", "Auto Matched", Color(0xFF34C759))
        EventViewMode.MY_EVENTS -> Triple("👤", "My Events", Color(0xFFAF52DE))
    }
    
    Button(
        onClick = onModeClick,
        colors = ButtonDefaults.buttonColors(
            containerColor = color.copy(alpha = 0.9f)
        ),
        shape = RoundedCornerShape(25.dp),
        modifier = Modifier.shadow(4.dp, RoundedCornerShape(25.dp))
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = icon,
                fontSize = 18.sp
            )
            Text(
                text = label,
                color = Color.White,
                fontWeight = FontWeight.SemiBold,
                fontSize = 14.sp
            )
        }
    }
}

@Composable
fun ViewModeSelectorDialog(
    currentMode: EventViewMode,
    onModeSelected: (EventViewMode) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = "View Mode",
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Column {
                EventViewMode.values().forEach { mode ->
                    val (icon, label) = when (mode) {
                        EventViewMode.ALL -> "🌍" to "All Events"
                        EventViewMode.AUTO_MATCHED -> "🎯" to "Auto Matched"
                        EventViewMode.MY_EVENTS -> "👤" to "My Events"
                    }
                    
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onModeSelected(mode) }
                            .padding(vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = icon,
                            fontSize = 20.sp,
                            modifier = Modifier.padding(end = 12.dp)
                        )
                        Text(
                            text = label,
                            fontSize = 16.sp,
                            fontWeight = if (mode == currentMode) FontWeight.Bold else FontWeight.Normal,
                            color = if (mode == currentMode) BrandPrimary else TextPrimary
                        )
                        if (mode == currentMode) {
                            Spacer(modifier = Modifier.weight(1f))
                            Text(
                                text = "✓",
                                color = BrandPrimary,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Done")
            }
        }
    )
}

// Function to apply filters to events with view mode
private fun applyFiltersWithViewMode(
    events: List<StudyEventMap>,
    showOnlyMatched: Boolean,
    showEventTypes: Map<EventType, Boolean>,
    username: String,
    viewMode: EventViewMode
): List<StudyEventMap> {
    Log.d("BasicFullMapView", "Applying filters with view mode: $viewMode")
    
    // First filter by view mode
    val viewModeFilteredEvents = when (viewMode) {
        EventViewMode.ALL -> events
        EventViewMode.AUTO_MATCHED -> {
            // Show only auto-matched events that user hasn't RSVPed to
            events.filter { event ->
                event.isAutoMatched == true && !event.isUserAttending
            }
        }
        EventViewMode.MY_EVENTS -> {
            // Show events the user has RSVPed to OR is hosting
            events.filter { event ->
                event.isUserAttending || event.host == username
            }
        }
    }
    
    Log.d("BasicFullMapView", "After view mode filtering: ${viewModeFilteredEvents.size} of ${events.size} events")
    
    // Then apply the existing filters
    return applyFilters(viewModeFilteredEvents, showOnlyMatched, showEventTypes, username)
}

// Function to apply filters to events
private fun applyFilters(
    events: List<StudyEventMap>,
    showOnlyMatched: Boolean,
    showEventTypes: Map<EventType, Boolean>,
    username: String
): List<StudyEventMap> {
    return events.filter { event ->
        // Event visibility check - matching iOS CalendarManager logic
        // Events are visible if:
        // 1. User is the host, OR
        // 2. User is attending (has explicitly accepted an invitation), OR
        // 3. User is auto-matched to the event, OR
        // 4. User is invited to the event (even if not yet accepted)
        // 5. Event has not expired (endTime > current time) - matching iOS behavior
        
        val userIsHost = event.host == username
        val userIsAttending = event.isUserAttending
        val userIsInvited = username in event.invitedFriends
        val isAutoMatched = event.isAutoMatched == true
        
        // Check if event has expired (matching iOS CalendarManager logic)
        val isExpired = event.isExpired()
        
        // Match iOS CalendarManager filtering logic:
        // Include events where user is host, attending, auto-matched, OR invited
        // AND event has not expired
        val isVisibleToUser = !isExpired && (userIsHost || userIsAttending || isAutoMatched || userIsInvited)
        
        if (isVisibleToUser) {
            Log.d("BasicFullMapView", "✅ Showing event '${event.title}' to user: $username " +
                 "(host=$userIsHost, attending=$userIsAttending, invited=$userIsInvited, autoMatched=$isAutoMatched, expired=$isExpired)")
        } else {
            if (isExpired) {
                Log.d("BasicFullMapView", "⏰ Hiding expired event '${event.title}' from user: $username " +
                     "(endTime=${event.endTime})")
            } else {
                Log.d("BasicFullMapView", "⛔ Hiding event '${event.title}' from user: $username " +
                     "(host=$userIsHost, attending=$userIsAttending, invited=$userIsInvited, autoMatched=$isAutoMatched)")
            }
        }
        
        // If event isn't visible to this user, filter it out immediately
        if (!isVisibleToUser) {
            Log.d("BasicFullMapView", "⛔ Filtering out event '${event.title}' - not visible to user $username")
            return@filter false
        }
        
        // Additional filters (matched status and event type)
        // Only apply these filters after basic visibility check
        
        // Filter by match status if showOnlyMatched is enabled
        val matchStatus = if (showOnlyMatched) {
            // Only show events that are auto-matched for this user
            val isMatched = isAutoMatched && username in event.invitedFriends
            
            if (!isMatched) {
                Log.d("BasicFullMapView", "🔍 Filtering out event '${event.title}' - 'matched only' filter is on")
            }
            
            isMatched
        } else {
            true // Show all visible events if not filtering by match status
        }
        
        // Filter by event type
        val typeStatus = event.eventType?.let { showEventTypes[it] } ?: true
        if (!typeStatus) {
            Log.d("BasicFullMapView", "🏷️ Filtering out event '${event.title}' - event type filter is off for ${event.eventType}")
        }
        
        // Event must pass all filters
        val passesAllFilters = matchStatus && typeStatus
        if (passesAllFilters) {
            Log.d("BasicFullMapView", "✅ Showing event '${event.title}' (type: ${event.eventType}, matched: ${isAutoMatched})")
        }
        
        passesAllFilters
    }
}

// Function to update map annotations
private fun updateMapAnnotations(
    mapView: MapView,
    pointAnnotationManager: PointAnnotationManager,
    events: List<StudyEventMap>
) {
    try {
        // Clear existing annotations
        pointAnnotationManager.deleteAll()
        
        if (events.isEmpty()) {
            Log.d("BasicFullMapView", "No events to display on map")
            return
        }
        
        Log.d("BasicFullMapView", "Updating map with ${events.size} events")
        
        // Create a point annotation for each event
        val pointAnnotationOptions = events.mapNotNull { event ->
            // Skip events without coordinates
            val coordinates = event.coordinate ?: return@mapNotNull null
            
            // Create a point for the event location
            val point = Point.fromLngLat(coordinates.first, coordinates.second)
            
            // Determine marker color based on event type
            val color = when (event.eventType) {
                EventType.STUDY -> Color(0xFF007AFF)      // iOS Blue
                EventType.PARTY -> Color(0xFFAF52DE)      // iOS Purple
                EventType.BUSINESS -> Color(0xFF5856D6)  // iOS Indigo
                EventType.CULTURAL -> Color(0xFFFF9500)  // iOS Orange
                EventType.ACADEMIC -> Color(0xFF34C759)  // iOS Green
                EventType.NETWORKING -> Color(0xFFFF2D92) // iOS Pink
                EventType.SOCIAL -> Color(0xFFFF3B30)    // iOS Red
                EventType.LANGUAGE_EXCHANGE -> Color(0xFF5AC8FA) // iOS Teal
                EventType.OTHER -> Color(0xFF8E8E93)     // iOS Gray
                else -> Color(0xFF8E8E93)               // Default iOS Gray
            }
            
            // Check if event is a potential match
            val isPotentialMatch = event.isAutoMatched || 
                (event.id?.let { PotentialMatchRegistry.isEventPotentialMatch(it) } ?: false)
            
            // Create annotation options
            PointAnnotationOptions()
                .withPoint(point)
                .withIconImage(createMarkerBitmap(mapView.context, color, isPotentialMatch))
                .withTextField(event.title)
        }
        
        // Add all annotations to the map
        if (pointAnnotationOptions.isNotEmpty()) {
            pointAnnotationManager.create(pointAnnotationOptions)
        }
        
        // Adjust camera to show all markers if needed
        if (events.isNotEmpty()) {
            // Calculate bounds of all events
            val points = events.mapNotNull { event ->
                event.coordinate?.let { coord ->
                    Point.fromLngLat(coord.first, coord.second)
                }
            }
            
            // If we have points, try to fit them all in view
            if (points.isNotEmpty()) {
                // For simplicity, just center on the first event with a reasonable zoom
                val firstPoint = points.first()
                val camera = CameraOptions.Builder()
                    .center(firstPoint)
                    .zoom(12.0)
                    .build()
                mapView.mapboxMap.setCamera(camera)
            }
        }
    } catch (e: Exception) {
        Log.e("BasicFullMapView", "Error updating map annotations: ${e.message}", e)
    }
}

// Function to create a marker bitmap
private fun createMarkerBitmap(
    context: android.content.Context,
    color: Color,
    isPotentialMatch: Boolean
): android.graphics.Bitmap {
    // Create a bitmap for the marker
    val bitmap = android.graphics.Bitmap.createBitmap(48, 48, android.graphics.Bitmap.Config.ARGB_8888)
    val canvas = android.graphics.Canvas(bitmap)
    
    // Draw main circle
    val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
    paint.color = android.graphics.Color.argb(
        color.alpha.toInt(), 
        color.red.toInt(), 
        color.green.toInt(), 
        color.blue.toInt()
    )
    paint.style = android.graphics.Paint.Style.FILL
    canvas.drawCircle(24f, 24f, 20f, paint)
    
    // Draw white border
    val borderPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
    borderPaint.color = android.graphics.Color.WHITE
    borderPaint.style = android.graphics.Paint.Style.STROKE
    borderPaint.strokeWidth = 3f
    canvas.drawCircle(24f, 24f, 20f, borderPaint)
    
    // Add special border for potential matches
    if (isPotentialMatch) {
        val matchPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        matchPaint.color = android.graphics.Color.parseColor("#9C27B0") // Purple
        matchPaint.style = android.graphics.Paint.Style.STROKE
        matchPaint.strokeWidth = 4f
        matchPaint.pathEffect = android.graphics.DashPathEffect(floatArrayOf(3f, 3f), 0f)
        canvas.drawCircle(24f, 24f, 23f, matchPaint)
    }
    
    return bitmap
} 