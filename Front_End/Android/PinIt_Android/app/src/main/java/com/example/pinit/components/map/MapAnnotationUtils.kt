package com.example.pinit.components.map

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.Log
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.core.content.ContextCompat
import com.example.pinit.R
import com.example.pinit.models.EventType
import com.example.pinit.models.StudyEventMap
import com.example.pinit.network.ApiClient
import com.example.pinit.utils.CoordinateConverter
import com.mapbox.geojson.Point
import com.mapbox.maps.MapView
import com.mapbox.maps.ScreenCoordinate
import com.mapbox.maps.plugin.annotation.annotations
import com.mapbox.maps.plugin.annotation.generated.PointAnnotation
import com.mapbox.maps.plugin.annotation.generated.PointAnnotationManager
import com.mapbox.maps.plugin.annotation.generated.PointAnnotationOptions
import com.mapbox.maps.plugin.annotation.generated.createPointAnnotationManager
import java.util.UUID

/**
 * Utility class for handling map annotations
 */
object MapAnnotationUtils {
    private const val TAG = "MapAnnotationUtils"
    
    /**
     * Get the event type color
     * 
     * @param eventType The type of event
     * @return Color for the event type
     */
    fun getEventTypeColor(eventType: EventType?): Color {
        return when (eventType) {
            EventType.STUDY -> Color(0xFF4CAF50)    // Green
            EventType.PARTY -> Color(0xFFF44336)    // Red  
            EventType.BUSINESS -> Color(0xFF2196F3) // Blue
            EventType.OTHER -> Color(0xFFFF9800)    // Orange
            null -> Color.Gray
        }
    }
    
    /**
     * Create a bitmap icon for an event
     * 
     * @param context Android context
     * @param event The event to create an icon for
     * @return Bitmap representing the event
     */
    fun createEventIcon(context: Context, event: StudyEventMap): Bitmap {
        // Get vector drawable resource based on event type
        val resourceId = when (event.eventType) {
            EventType.STUDY -> R.drawable.ic_study
            EventType.PARTY -> R.drawable.ic_party
            EventType.BUSINESS -> R.drawable.ic_business
            EventType.OTHER -> R.drawable.ic_other
            null -> R.drawable.ic_other
        }
        
        // Get background color based on event type with improved color scheme
        val bgColor = when (event.eventType) {
            EventType.STUDY -> android.graphics.Color.parseColor("#4CAF50")    // Green
            EventType.PARTY -> android.graphics.Color.parseColor("#E91E63")    // Pink
            EventType.BUSINESS -> android.graphics.Color.parseColor("#3F51B5") // Indigo
            EventType.OTHER -> android.graphics.Color.parseColor("#FF9800")    // Orange
            null -> android.graphics.Color.GRAY
        }
        
        // Get the drawable and set appropriate background color
        val drawable = ContextCompat.getDrawable(context, resourceId)?.mutate()
            ?: createDefaultBitmap(context)
        
        // Create bitmap from drawable with enhanced styling
        val bitmap = Bitmap.createBitmap(96, 96, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        // Draw shadow first (slight offset)
        val shadowPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        shadowPaint.color = android.graphics.Color.parseColor("#33000000") // Translucent black
        shadowPaint.style = android.graphics.Paint.Style.FILL
        canvas.drawCircle(48f + 2f, 48f + 2f, 44f, shadowPaint)
        
        // Draw main circle
        val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        paint.color = bgColor
        paint.style = android.graphics.Paint.Style.FILL
        canvas.drawCircle(48f, 48f, 44f, paint)
        
        // Draw white border with drop shadow effect
        val borderPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        borderPaint.color = android.graphics.Color.WHITE
        borderPaint.style = android.graphics.Paint.Style.STROKE
        borderPaint.strokeWidth = 3f
        canvas.drawCircle(48f, 48f, 43f, borderPaint)
        
        // Determine the event's status for the current user
        val currentUser = ApiClient.getCurrentUsername()
        val userIsHost = event.host == currentUser
        val userIsAttending = event.isUserAttending
        val userIsInvited = currentUser != null && event.invitedFriends.contains(currentUser)
        val isPendingInvitation = userIsInvited && !userIsAttending && !userIsHost
        
        // Check both the direct isAutoMatched flag AND the registry
        val isInRegistry = event.id?.let { com.example.pinit.utils.PotentialMatchRegistry.isEventPotentialMatch(it) } ?: false
        val isPotentialMatch = (event.isAutoMatched || isInRegistry) && !userIsAttending && !userIsHost
        
        // Log debug info about potential matches for every event rendered
        if (isInRegistry || event.isAutoMatched) {
            Log.d("MapAnnotationUtils", "🔍 Event ${event.id} - ${event.title} status:")
            Log.d("MapAnnotationUtils", "  - isAutoMatched: ${event.isAutoMatched}")
            Log.d("MapAnnotationUtils", "  - isInRegistry: $isInRegistry")
            Log.d("MapAnnotationUtils", "  - userIsHost: $userIsHost")
            Log.d("MapAnnotationUtils", "  - userIsAttending: $userIsAttending")
            Log.d("MapAnnotationUtils", "  - isPotentialMatch: $isPotentialMatch")
        }
        
        // Add special border for pending invitations (dashed blue)
        if (isPendingInvitation) {
            val invitationPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
            invitationPaint.color = android.graphics.Color.parseColor("#2196F3") // Blue
            invitationPaint.style = android.graphics.Paint.Style.STROKE
            invitationPaint.strokeWidth = 4f
            invitationPaint.pathEffect = android.graphics.DashPathEffect(floatArrayOf(8f, 4f), 0f)
            canvas.drawCircle(48f, 48f, 46f, invitationPaint)
        }
        
        // Add special border for potential matches (dotted purple)
        if (isPotentialMatch) {
            val matchPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
            matchPaint.color = android.graphics.Color.parseColor("#9C27B0") // Purple
            matchPaint.style = android.graphics.Paint.Style.STROKE
            matchPaint.strokeWidth = 4f
            matchPaint.pathEffect = android.graphics.DashPathEffect(floatArrayOf(3f, 3f), 0f)
            canvas.drawCircle(48f, 48f, 46f, matchPaint)
        }
        
        // Certified event gets a star outline (keep this after the invitation/match borders)
        if (event.hostIsCertified) {
            val certifiedPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
            certifiedPaint.color = android.graphics.Color.YELLOW
            certifiedPaint.style = android.graphics.Paint.Style.STROKE
            certifiedPaint.strokeWidth = 3f
            canvas.drawCircle(48f, 48f, 46f, certifiedPaint)
        }
        
        // Draw the icon in the center of the bitmap with proper scaling
        drawable.setBounds(24, 20, 72, 68)
        drawable.draw(canvas)
        
        return bitmap
    }
    
    /**
     * Create annotation for a single event
     * 
     * @param context Android context
     * @param event Event to create annotation for
     * @return PointAnnotationOptions for the event, or null if invalid coordinates
     */
    fun createEventAnnotation(
        context: Context,
        event: StudyEventMap
    ): PointAnnotationOptions? {
        // Handle null or invalid coordinates
        if (event.coordinate == null) {
            Log.w(TAG, "Cannot create annotation for event with null coordinates: ${event.id} - ${event.title}")
            return null
        }
        
        // Convert to Point with validation
        val point = CoordinateConverter.fromPair(event.coordinate)
        if (point == null) {
            Log.w(TAG, "Invalid coordinates for event ${event.id} - ${event.title}: ${event.coordinate}")
            return null
        }
        
        // Log coordinates for debugging
        Log.d(TAG, "Creating annotation for event ${event.id} at (${point.longitude()}, ${point.latitude()})")
        
        // Create bitmap for the event
        val bitmap = createEventIcon(context, event)
        
        // Create the annotation with the bitmap and a unique identifier - without text field
        return PointAnnotationOptions()
            .withPoint(point)
            .withIconImage(bitmap)
            .withIconSize(1.5) // Make icon slightly larger for better visibility
    }
    
    /**
     * Create annotation for a cluster of events
     * 
     * @param context Android context
     * @param cluster Cluster of events
     * @return PointAnnotationOptions for the cluster, or null if invalid coordinates
     */
    fun createClusterAnnotation(
        context: Context,
        cluster: Cluster
    ): PointAnnotationOptions? {
        // Validate cluster coordinate
        val point = cluster.coordinate
        if (point == null || 
            !CoordinateConverter.isValidLongitude(point.longitude()) || 
            !CoordinateConverter.isValidLatitude(point.latitude())) {
            
            Log.w(TAG, "Invalid coordinates for cluster with ${cluster.events.size} events: ${point?.longitude()}, ${point?.latitude()}")
            return null
        }
        
        // Log coordinates for debugging
        Log.d(TAG, "Creating annotation for cluster with ${cluster.events.size} events at (${point.longitude()}, ${point.latitude()})")
        
        // Use the first event's type for the icon, or a default
        val eventType = determineMainEventType(cluster.events)
        
        // Create bitmap for the cluster
        val bitmap = createClusterIcon(context, cluster.events.size, eventType)
        
        // Create the annotation with the bitmap and a unique identifier
        return PointAnnotationOptions()
            .withPoint(point)
            .withIconImage(bitmap)
            .withIconSize(1.8) // Make clusters larger than single events
    }
    
    /**
     * Determine the main event type for a cluster based on most common type
     */
    private fun determineMainEventType(events: List<StudyEventMap>): EventType {
        if (events.isEmpty()) return EventType.OTHER
        
        // Count occurrences of each event type
        val typeCounts = events
            .mapNotNull { it.eventType }
            .groupingBy { it }
            .eachCount()
        
        // Return the most frequent type, or the first event's type if there's a tie
        return typeCounts.maxByOrNull { it.value }?.key 
            ?: events.firstOrNull()?.eventType 
            ?: EventType.OTHER
    }
    
    /**
     * Create a bitmap icon for a cluster
     * 
     * @param context Android context
     * @param size Number of events in the cluster
     * @param eventType The predominant event type in the cluster
     * @return Bitmap representing the cluster
     */
    private fun createClusterIcon(context: Context, size: Int, eventType: EventType): Bitmap {
        // For clusters, we use a distinct visual appearance
        val resourceId = when (eventType) {
            EventType.STUDY -> R.drawable.ic_study
            EventType.PARTY -> R.drawable.ic_party  
            EventType.BUSINESS -> R.drawable.ic_business
            EventType.OTHER -> R.drawable.ic_mixed_types
        }
        
        // Get background color based on event type with improved contrast for clusters
        val bgColor = when (eventType) {
            EventType.STUDY -> android.graphics.Color.parseColor("#388E3C")    // Darker Green
            EventType.PARTY -> android.graphics.Color.parseColor("#C2185B")    // Darker Pink
            EventType.BUSINESS -> android.graphics.Color.parseColor("#303F9F") // Darker Indigo
            EventType.OTHER -> android.graphics.Color.parseColor("#EF6C00")    // Darker Orange
        }
        
        // Get the drawable
        val drawable = ContextCompat.getDrawable(context, resourceId)?.mutate()
            ?: createDefaultBitmap(context)
        
        // Create a larger bitmap for clustering
        val bitmapSize = 120 // Increased size for better visibility
        val bitmap = Bitmap.createBitmap(
            bitmapSize,
            bitmapSize,
            Bitmap.Config.ARGB_8888
        )
        
        val canvas = Canvas(bitmap)
        
        // Draw drop shadow
        val shadowPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        shadowPaint.color = android.graphics.Color.parseColor("#40000000") // Translucent black
        shadowPaint.style = android.graphics.Paint.Style.FILL
        val shadowCenterX = bitmapSize / 2f + 3f
        val shadowCenterY = bitmapSize / 2f + 3f
        val shadowRadius = bitmapSize / 2f - 10f
        canvas.drawCircle(shadowCenterX, shadowCenterY, shadowRadius, shadowPaint)
        
        // Draw circular background
        val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        paint.color = bgColor
        paint.style = android.graphics.Paint.Style.FILL
        
        // Draw a circle in the center of the bitmap
        val centerX = bitmapSize / 2f
        val centerY = bitmapSize / 2f
        val radius = bitmapSize / 2f - 8f  // Slightly smaller than half the width for padding
        canvas.drawCircle(centerX, centerY, radius, paint)
        
        // Add gradient overlay for 3D effect
        val gradientPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        val gradient = android.graphics.RadialGradient(
            centerX, centerY, radius,
            android.graphics.Color.parseColor("#FFFFFF"),
            android.graphics.Color.parseColor("#00FFFFFF"),
            android.graphics.Shader.TileMode.CLAMP
        )
        gradientPaint.shader = gradient
        gradientPaint.alpha = 80 // Translucent white center
        canvas.drawCircle(centerX, centerY, radius, gradientPaint)
        
        // Draw white border
        val borderPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        borderPaint.color = android.graphics.Color.WHITE
        borderPaint.style = android.graphics.Paint.Style.STROKE
        borderPaint.strokeWidth = 5f
        canvas.drawCircle(centerX, centerY, radius, borderPaint)
        
        // Add a second, inner white circle for visual interest
        val innerCirclePaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        innerCirclePaint.color = android.graphics.Color.parseColor("#22FFFFFF") // Translucent white
        innerCirclePaint.style = android.graphics.Paint.Style.STROKE
        innerCirclePaint.strokeWidth = 3f
        canvas.drawCircle(centerX, centerY, radius - 10f, innerCirclePaint)
        
        // Calculate padding for the drawable to make it smaller to fit the count text
        val drawablePadding = bitmapSize / 4
        drawable.setBounds(
            drawablePadding, 
            drawablePadding - 12, // Move up a bit to make room for the count
            bitmapSize - drawablePadding, 
            bitmapSize - drawablePadding - 12
        )
        
        // Draw the icon
        drawable.draw(canvas)
        
        // Draw the count with a nicer visual style
        val textPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        textPaint.color = android.graphics.Color.WHITE
        textPaint.textSize = 40f
        textPaint.textAlign = android.graphics.Paint.Align.CENTER
        textPaint.isFakeBoldText = true
        
        // Add strong shadow/glow effect to make text visible on any background
        textPaint.setShadowLayer(6f, 0f, 0f, android.graphics.Color.parseColor("#80000000"))
        
        // Display count as a badge in the bottom part
        val countText = size.toString()
        val xPos = centerX
        val yPos = centerY + radius - 10f
        
        // Use small white highlight circle instead of black badge
        val highlightPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        highlightPaint.color = android.graphics.Color.WHITE
        highlightPaint.alpha = 120 // Semi-transparent
        highlightPaint.style = android.graphics.Paint.Style.FILL
        
        val textWidth = textPaint.measureText(countText)
        val highlightRadius = textWidth / 2 + 6
        canvas.drawCircle(xPos, yPos, highlightRadius, highlightPaint)
        
        // Draw count text
        canvas.drawText(countText, xPos, yPos + 15f, textPaint)
        
        return bitmap
    }
    
    /**
     * Create a bitmap from a drawable with a colored circular background
     * 
     * @param drawable The drawable to convert
     * @param bgColor Optional background color, defaults to white
     * @return Bitmap created from the drawable with background
     */
    private fun createBitmapFromDrawable(drawable: Drawable, bgColor: Int = android.graphics.Color.WHITE): Bitmap {
        if (drawable is BitmapDrawable) {
            return drawable.bitmap
        }
        
        // Create a larger bitmap for better visibility
        val size = 96 // Larger size for better visibility on map
        val bitmap = Bitmap.createBitmap(
            size,
            size,
            Bitmap.Config.ARGB_8888
        )
        
        val canvas = Canvas(bitmap)
        
        // Draw circular background
        val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        paint.color = bgColor
        paint.style = android.graphics.Paint.Style.FILL
        
        // Draw a circle in the center of the bitmap
        val centerX = size / 2f
        val centerY = size / 2f
        val radius = size / 2f - 4f  // Slightly smaller than half the width for padding
        canvas.drawCircle(centerX, centerY, radius, paint)
        
        // Draw white border
        val borderPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        borderPaint.color = android.graphics.Color.WHITE
        borderPaint.style = android.graphics.Paint.Style.STROKE
        borderPaint.strokeWidth = 4f
        canvas.drawCircle(centerX, centerY, radius, borderPaint)
        
        // Calculate padding for the drawable to make it smaller than the circle
        val drawablePadding = size / 4
        drawable.setBounds(
            drawablePadding, 
            drawablePadding, 
            size - drawablePadding, 
            size - drawablePadding
        )
        
        // Draw the icon
        drawable.draw(canvas)
        
        return bitmap
    }
    
    /**
     * Create a default bitmap for fallback
     * 
     * @param context Android context
     * @return Default drawable
     */
    private fun createDefaultBitmap(context: Context): Drawable {
        return ContextCompat.getDrawable(context, R.drawable.ic_other)
            ?: throw IllegalStateException("Default drawable not found")
    }
} 