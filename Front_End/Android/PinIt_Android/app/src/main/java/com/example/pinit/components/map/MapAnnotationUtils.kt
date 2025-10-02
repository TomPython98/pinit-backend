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
        EventType.STUDY -> Color(0xFF007AFF)      // iOS Blue
        EventType.PARTY -> Color(0xFFAF52DE)      // iOS Purple
        EventType.BUSINESS -> Color(0xFF5856D6)  // iOS Indigo
        EventType.CULTURAL -> Color(0xFFFF9500)  // iOS Orange
        EventType.ACADEMIC -> Color(0xFF34C759)  // iOS Green
        EventType.NETWORKING -> Color(0xFFFF2D92) // iOS Pink
        EventType.SOCIAL -> Color(0xFFFF3B30)    // iOS Red
        EventType.LANGUAGE_EXCHANGE -> Color(0xFF5AC8FA) // iOS Teal
        EventType.OTHER -> Color(0xFF8E8E93)     // iOS Gray
        null -> Color.Gray
    }
}
    
    /**
     * Create a bitmap icon for an event - iOS style
     * 
     * @param context Android context
     * @param event The event to create an icon for
     * @return Bitmap representing the event
     */
    fun createEventIcon(context: Context, event: StudyEventMap): Bitmap {
        // Get PNG drawable resource based on event type
        val resourceId = when (event.eventType) {
            EventType.STUDY -> R.drawable.ic_study
            EventType.PARTY -> R.drawable.ic_party
            EventType.BUSINESS -> R.drawable.ic_business
            EventType.CULTURAL -> R.drawable.ic_cultural
            EventType.ACADEMIC -> R.drawable.ic_academic
            EventType.NETWORKING -> R.drawable.ic_networking
            EventType.SOCIAL -> R.drawable.ic_social
            EventType.LANGUAGE_EXCHANGE -> R.drawable.ic_language_exchange
            EventType.OTHER -> R.drawable.ic_other
            null -> R.drawable.ic_other
        }
        
        // Get background color based on event type with iOS colors
        val bgColor = when (event.eventType) {
            EventType.STUDY -> android.graphics.Color.parseColor("#007AFF")      // iOS Blue
            EventType.PARTY -> android.graphics.Color.parseColor("#AF52DE")      // iOS Purple
            EventType.BUSINESS -> android.graphics.Color.parseColor("#5856D6")  // iOS Indigo
            EventType.CULTURAL -> android.graphics.Color.parseColor("#FF9500")  // iOS Orange
            EventType.ACADEMIC -> android.graphics.Color.parseColor("#34C759")  // iOS Green
            EventType.NETWORKING -> android.graphics.Color.parseColor("#FF2D92") // iOS Pink
            EventType.SOCIAL -> android.graphics.Color.parseColor("#FF3B30")    // iOS Red
            EventType.LANGUAGE_EXCHANGE -> android.graphics.Color.parseColor("#5AC8FA") // iOS Teal
            EventType.OTHER -> android.graphics.Color.parseColor("#8E8E93")     // iOS Gray
            null -> android.graphics.Color.GRAY
        }
        
        // Create bigger markers for better visibility
        val markerWidth = 120
        val markerHeight = 84
        val bitmap = Bitmap.createBitmap(markerWidth, markerHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        val centerX = markerWidth / 2f
        val centerY = markerHeight / 2f
        val radius = 34f // Bigger radius
        
        // Draw subtle shadow (iOS style)
        val shadowPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        shadowPaint.color = android.graphics.Color.parseColor("#20000000") // Very subtle shadow
        shadowPaint.style = android.graphics.Paint.Style.FILL
        canvas.drawCircle(centerX + 1f, centerY + 1f, radius, shadowPaint)
        
        // Draw main circle with iOS colors
        val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        paint.color = bgColor
        paint.style = android.graphics.Paint.Style.FILL
        canvas.drawCircle(centerX, centerY, radius, paint)
        
        // Draw clean white border (iOS style)
        val borderPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        borderPaint.color = android.graphics.Color.WHITE
        borderPaint.style = android.graphics.Paint.Style.STROKE
        borderPaint.strokeWidth = 3f
        canvas.drawCircle(centerX, centerY, radius - 1f, borderPaint)
        
        // Get the PNG drawable and center it properly
        val drawable = ContextCompat.getDrawable(context, resourceId)
        if (drawable != null) {
            // Center the icon perfectly in the circle
            val iconSize = 32 // Bigger icon size
            val left = (markerWidth - iconSize) / 2
            val top = (markerHeight - iconSize) / 2
            val right = left + iconSize
            val bottom = top + iconSize
            
            drawable.setBounds(left, top, right, bottom)
            drawable.draw(canvas)
        }
        
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
        // Get background color based on event type with darker iOS colors for clusters
        val bgColor = when (eventType) {
            EventType.STUDY -> android.graphics.Color.parseColor("#0056CC")      // Darker iOS Blue
            EventType.PARTY -> android.graphics.Color.parseColor("#8E44AD")      // Darker iOS Purple
            EventType.BUSINESS -> android.graphics.Color.parseColor("#4A4AB8")  // Darker iOS Indigo
            EventType.CULTURAL -> android.graphics.Color.parseColor("#E67E00")  // Darker iOS Orange
            EventType.ACADEMIC -> android.graphics.Color.parseColor("#2E8B47")  // Darker iOS Green
            EventType.NETWORKING -> android.graphics.Color.parseColor("#E91E63") // Darker iOS Pink
            EventType.SOCIAL -> android.graphics.Color.parseColor("#E53E3E")    // Darker iOS Red
            EventType.LANGUAGE_EXCHANGE -> android.graphics.Color.parseColor("#4A9FD1") // Darker iOS Teal
            EventType.OTHER -> android.graphics.Color.parseColor("#6B7280")     // Darker iOS Gray
        }
        
        // Create iOS-style cluster: exact iOS size (40x40 base, grows with count)
        val clusterSize = when {
            size >= 15 -> 65 // Large clusters
            size >= 8 -> 55  // Medium clusters  
            size >= 3 -> 45  // Small clusters
            else -> 40       // Base size (matches iOS)
        }
        val bitmap = Bitmap.createBitmap(clusterSize, clusterSize, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        val centerX = clusterSize / 2f
        val centerY = clusterSize / 2f
        val radius = clusterSize / 2f - 2f
        
        // Draw subtle shadow (iOS style)
        val shadowPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        shadowPaint.color = android.graphics.Color.parseColor("#30000000") // Subtle shadow
        shadowPaint.style = android.graphics.Paint.Style.FILL
        canvas.drawCircle(centerX + 1f, centerY + 1f, radius, shadowPaint)
        
        // Draw main circle with darker color
        val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        paint.color = bgColor
        paint.style = android.graphics.Paint.Style.FILL
        canvas.drawCircle(centerX, centerY, radius, paint)
        
        // Draw clean white border (iOS style)
        val borderPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        borderPaint.color = android.graphics.Color.WHITE
        borderPaint.style = android.graphics.Paint.Style.STROKE
        borderPaint.strokeWidth = 2f
        canvas.drawCircle(centerX, centerY, radius - 1f, borderPaint)
        
        // Draw count text in center
        val textPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        textPaint.color = android.graphics.Color.WHITE
        textPaint.textSize = when {
            size >= 15 -> 20f
            size >= 8 -> 18f
            size >= 3 -> 16f
            else -> 14f
        }
        textPaint.textAlign = android.graphics.Paint.Align.CENTER
        textPaint.isFakeBoldText = true
        
        val countText = size.toString()
        canvas.drawText(countText, centerX, centerY + 6f, textPaint)
        
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