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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
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
        EventType.OTHER to true
    )) }
    
    // Map state
    var pointAnnotationManager by remember { mutableStateOf<PointAnnotationManager?>(null) }
    var mapView by remember { mutableStateOf<MapView?>(null) }
    
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
    LaunchedEffect(key1 = showOnlyMatched, key2 = showEventTypes, key3 = events) {
        Log.d("BasicFullMapView", "Applying filters for user $username - showOnlyMatched=$showOnlyMatched, eventTypes=${showEventTypes.entries.filter { it.value }.map { it.key }}")
        filteredEvents = applyFilters(events, showOnlyMatched, showEventTypes, username)
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
                                EventType.STUDY -> Color(0xFF4CAF50)
                                EventType.PARTY -> Color(0xFFE91E63)
                                EventType.BUSINESS -> Color(0xFF3F51B5)
                                EventType.OTHER -> Color(0xFFFF9800)
                            }.copy(alpha = 0.2f),
                            selectedLabelColor = when(eventType) {
                                EventType.STUDY -> Color(0xFF4CAF50)
                                EventType.PARTY -> Color(0xFFE91E63)
                                EventType.BUSINESS -> Color(0xFF3F51B5)
                                EventType.OTHER -> Color(0xFFFF9800)
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
                            
                            // Vienna coordinates (center of the map)
                            val viennaCoordinates = Point.fromLngLat(16.3738, 48.2082)
                            
                            // Configure camera position
                            val cameraPosition = CameraOptions.Builder()
                                .center(viennaCoordinates)
                                .zoom(12.0) // Adjusted for better overview of events
                                .pitch(0.0) // Flat view for better marker visibility
                                .bearing(0.0) // No rotation
                                .build()
                            
                            // Set camera position before loading style
                            mapViewInstance.mapboxMap.setCamera(cameraPosition)
                            
                            // Create annotation manager for markers
                            val annotationsPlugin = mapViewInstance.annotations
                            pointAnnotationManager = annotationsPlugin.createPointAnnotationManager()
                            
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
}

// Function to apply filters to events
private fun applyFilters(
    events: List<StudyEventMap>,
    showOnlyMatched: Boolean,
    showEventTypes: Map<EventType, Boolean>,
    username: String
): List<StudyEventMap> {
    return events.filter { event ->
        // Event visibility check - critical security filter
        // 1. Keep events where current user is the host
        // 2. Keep public events that are not auto-matched
        // 3. Keep events where current user is specifically auto-matched
        
        // Check if the event is auto-matched for ANY user
        val isAutoMatchedEvent = event.isAutoMatched || 
            (event.id?.let { PotentialMatchRegistry.isEventPotentialMatch(it) } ?: false)
            
        val isVisibleToUser = when {
            // Current user is the host - always show
            event.host == username -> {
                Log.d("BasicFullMapView", "👤 Showing event '${event.title}' to host: $username")
                true
            }
            
            // Auto-matched events - only show if current user is matched
            isAutoMatchedEvent -> {
                // Check if user is in invitedFriends (which contains matched users)
                val userIsMatched = username in event.invitedFriends
                
                if (userIsMatched) {
                    Log.d("BasicFullMapView", "✨ Showing auto-matched event '${event.title}' to matched user: $username")
                } else {
                    Log.d("BasicFullMapView", "⛔ Hiding auto-matched event '${event.title}' from user: $username (not matched)")
                }
                
                userIsMatched
            }
            
            // Regular public events (not auto-matched) - show to everyone
            event.isPublic -> {
                Log.d("BasicFullMapView", "🌐 Showing public event '${event.title}' to user: $username")
                true
            }
            
            // Default case - don't show private events to non-hosts, non-matched users
            else -> {
                Log.d("BasicFullMapView", "🔒 Hiding private event '${event.title}' from user: $username")
                false
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
            val isMatched = isAutoMatchedEvent && username in event.invitedFriends
            
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
            Log.d("BasicFullMapView", "✅ Showing event '${event.title}' (type: ${event.eventType}, matched: ${isAutoMatchedEvent})")
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
                EventType.STUDY -> Color(0xFF4CAF50)    // Green
                EventType.PARTY -> Color(0xFFE91E63)    // Pink
                EventType.BUSINESS -> Color(0xFF3F51B5) // Indigo
                EventType.OTHER -> Color(0xFFFF9800)    // Orange
                null -> Color.Gray
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