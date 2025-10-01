package com.example.pinit.components.map

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.util.Log
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import androidx.core.content.ContextCompat
import com.example.pinit.R
import com.example.pinit.models.EventType
import com.example.pinit.models.StudyEventMap

/**
 * Custom view for displaying a cluster of events on the map
 */
class ClusterAnnotationView(context: Context) : FrameLayout(context) {

    private val TAG = "ClusterAnnotationView"

    // UI components
    private val mainCircle: View
    private val countLabel: TextView
    private val mixedTypesIcon: ImageView
    private val privateBadge: ImageView
    
    // State tracking
    private val eventCounts = mutableMapOf<EventType, Int>()
    private var hasPrivateEvents = false
    private var hasCertifiedEvents = false
    
    init {
        Log.d(TAG, "Initializing ClusterAnnotationView")
        
        // Create main circle background
        mainCircle = View(context).apply {
            val circleBackground = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#2196F3")) // Default blue
            }
            background = circleBackground
            
            layoutParams = LayoutParams(80, 80).apply {
                gravity = Gravity.CENTER
            }
        }
        
        // Create count label
        countLabel = TextView(context).apply {
            layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply {
                gravity = Gravity.CENTER
            }
            setTextColor(Color.WHITE)
            textSize = 16f
            text = "0"
        }
        
        // Create mixed types icon
        mixedTypesIcon = ImageView(context).apply {
            layoutParams = LayoutParams(24, 24).apply {
                gravity = Gravity.BOTTOM or Gravity.END
                setMargins(0, 0, 4, 4)
            }
            try {
                setImageResource(R.drawable.ic_mixed_types)
                Log.d(TAG, "Set mixed types icon successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Error setting mixed types icon: ${e.message}", e)
                try {
                    setImageResource(android.R.drawable.ic_dialog_dialer)
                } catch (e2: Exception) {
                    Log.e(TAG, "Failed to set fallback icon: ${e2.message}", e2)
                }
            }
            visibility = View.GONE
        }
        
        // Create private events badge
        privateBadge = ImageView(context).apply {
            layoutParams = LayoutParams(20, 20).apply {
                gravity = Gravity.TOP or Gravity.END
                setMargins(0, 4, 4, 0)
            }
            try {
                setImageResource(R.drawable.ic_lock)
                Log.d(TAG, "Set private badge icon successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Error setting private badge icon: ${e.message}", e)
                try {
                    setImageResource(android.R.drawable.ic_lock_lock)
                } catch (e2: Exception) {
                    Log.e(TAG, "Failed to set fallback icon: ${e2.message}", e2)
                }
            }
            visibility = View.GONE
        }
        
        // Add views to frame
        addView(mainCircle)
        addView(countLabel)
        addView(mixedTypesIcon)
        addView(privateBadge)
        
        // Set explicit size for the whole view
        val size = 120 // Large enough to contain the circle plus icons
        layoutParams = LayoutParams(size, size)
        
        // Set background color for debugging
        setBackgroundColor(Color.parseColor("#22FF0000"))
    }
    
    /**
     * Configure the cluster view based on the events it contains
     */
    fun configure(events: List<StudyEventMap>) {
        Log.d(TAG, "Configuring cluster view for ${events.size} events")
        
        // Reset counts
        eventCounts.clear()
        hasPrivateEvents = false
        hasCertifiedEvents = false
        
        // Count event types and check for special attributes
        for (event in events) {
            val eventType = event.eventType ?: EventType.OTHER
            eventCounts[eventType] = (eventCounts[eventType] ?: 0) + 1
            
            if (!event.isPublic) {
                hasPrivateEvents = true
            }
            
            if (event.hostIsCertified) {
                hasCertifiedEvents = true
            }
        }
        
        // Log event types distribution
        eventCounts.forEach { (type, count) ->
            Log.d(TAG, "Event type: $type, Count: $count")
        }
        
        // Set count text
        countLabel.text = events.size.toString()
        
        // Show mixed types icon if there's more than one type
        mixedTypesIcon.visibility = if (eventCounts.size > 1) View.VISIBLE else View.GONE
        
        // Show private badge if there are private events
        privateBadge.visibility = if (hasPrivateEvents) View.VISIBLE else View.GONE
        
        // Determine dominant event type for coloring
        val dominantType = eventCounts.entries.maxByOrNull { it.value }?.key ?: EventType.OTHER
        Log.d(TAG, "Dominant event type: $dominantType")
        
        // Get styling based on cluster size and dominant type
        val (size, color) = getAppearanceForCluster(events.size, dominantType)
        Log.d(TAG, "Cluster appearance: size=$size, color=${String.format("#%06X", 0xFFFFFF and color)}")
        
        // Update view size
        val layoutParams = mainCircle.layoutParams
        layoutParams.width = size
        layoutParams.height = size
        mainCircle.layoutParams = layoutParams
        
        // Update circle appearance
        val circleBackground = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(color)
        }
        mainCircle.background = circleBackground
        
        // Update label size based on cluster size
        countLabel.textSize = size * 0.4f / resources.displayMetrics.density
        
        // Force layout calculation
        measure(
            MeasureSpec.makeMeasureSpec(120, MeasureSpec.EXACTLY),
            MeasureSpec.makeMeasureSpec(120, MeasureSpec.EXACTLY)
        )
        layout(0, 0, 120, 120)
        
        invalidate()
    }
    
    /**
     * Determine the size and color of the cluster based on number of events and type
     */
    private fun getAppearanceForCluster(count: Int, dominantType: EventType): Pair<Int, Int> {
        // Calculate size based on count
        val size = when {
            count >= 100 -> 100
            count >= 50 -> 90
            count >= 20 -> 80
            count >= 10 -> 70
            count >= 5 -> 60
            else -> 50
        }
        
        // Determine color based on dominant event type
        val color = when (dominantType) {
            EventType.STUDY -> Color.parseColor("#2196F3") // Blue
            EventType.PARTY -> Color.parseColor("#9C27B0") // Purple
            EventType.BUSINESS -> Color.parseColor("#FF9800") // Orange
            EventType.OTHER -> Color.parseColor("#607D8B") // Gray
        }
        
        return Pair(size, color)
    }
    
    /**
     * Helper method to create a bitmap snapshot of this view
     */
    fun createViewBitmap(): android.graphics.Bitmap {
        Log.d(TAG, "Creating bitmap from cluster view")
        
        // Force layout and measure if needed
        if (width == 0 || height == 0) {
            measure(
                MeasureSpec.makeMeasureSpec(120, MeasureSpec.EXACTLY),
                MeasureSpec.makeMeasureSpec(120, MeasureSpec.EXACTLY)
            )
            layout(0, 0, 120, 120)
        }
        
        // Make the background transparent instead of debug color
        setBackgroundColor(Color.TRANSPARENT)
        
        // Create bitmap with ARGB_8888 config to ensure alpha channel
        val bitmap = android.graphics.Bitmap.createBitmap(
            120, 120, android.graphics.Bitmap.Config.ARGB_8888
        )
        
        // Clear the bitmap to transparent
        bitmap.eraseColor(Color.TRANSPARENT)
        
        // Draw view into canvas
        val canvas = android.graphics.Canvas(bitmap)
        draw(canvas)
        
        Log.d(TAG, "Cluster bitmap created: ${bitmap.width}x${bitmap.height}")
        return bitmap
    }
} 