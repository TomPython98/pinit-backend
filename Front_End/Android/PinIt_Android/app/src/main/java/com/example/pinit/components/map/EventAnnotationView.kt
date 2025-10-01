package com.example.pinit.components.map

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.drawable.Drawable
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import android.util.Log
import com.example.pinit.R
import com.example.pinit.models.EventType
import com.example.pinit.models.StudyEventMap

/**
 * Custom view for displaying a single event marker on the map
 */
class EventAnnotationView(context: Context) : FrameLayout(context) {
    
    private val TAG = "EventAnnotationView"
    
    private val circlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
    }
    
    private val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 4f
        color = Color.WHITE
    }
    
    private val iconView = ImageView(context).apply {
        layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply {
            gravity = Gravity.CENTER
            width = 24
            height = 24
        }
    }
    
    private val certifiedBadge = ImageView(context).apply {
        layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply {
            gravity = Gravity.TOP or Gravity.END
            width = 16
            height = 16
        }
        visibility = View.GONE
    }
    
    private val privateBadge = ImageView(context).apply {
        layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply {
            gravity = Gravity.BOTTOM or Gravity.END
            width = 16
            height = 16
        }
        visibility = View.GONE
    }
    
    init {
        Log.d(TAG, "Initializing EventAnnotationView")
        setWillNotDraw(false) // Enable onDraw
        
        // Set explicit size - make it larger to ensure visibility
        val size = 96
        layoutParams = LayoutParams(size, size)
        
        // Add views
        addView(iconView)
        addView(certifiedBadge)
        addView(privateBadge)
        
        // Set badge images
        try {
            // Try to set badge images
            certifiedBadge.setImageResource(R.drawable.ic_verified)
            privateBadge.setImageResource(R.drawable.ic_lock)
            Log.d(TAG, "Badge images set successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error setting badge images: ${e.message}", e)
            // Attempt to use system icons as fallback
            try {
                certifiedBadge.setImageResource(android.R.drawable.ic_secure)
                privateBadge.setImageResource(android.R.drawable.ic_lock_lock)
            } catch (e2: Exception) {
                Log.e(TAG, "Failed to set fallback badge images: ${e2.message}", e2)
            }
        }
        
        // Set background color to debug
        setBackgroundColor(Color.parseColor("#22FF0000"))
    }
    
    /**
     * Configure the marker based on the event
     */
    fun configure(event: StudyEventMap) {
        Log.d(TAG, "Configuring for event: ${event.id} - ${event.title}, type: ${event.eventType}")
        
        // Set marker color based on event type
        circlePaint.color = getColorForEventType(event.eventType)
        
        // Set icon based on event type
        setIconForEventType(event.eventType)
        
        // Configure badges
        certifiedBadge.visibility = if (event.hostIsCertified) View.VISIBLE else View.GONE
        privateBadge.visibility = if (!event.isPublic) View.VISIBLE else View.GONE
        
        // Force layout calculation
        measure(
            MeasureSpec.makeMeasureSpec(96, MeasureSpec.EXACTLY),
            MeasureSpec.makeMeasureSpec(96, MeasureSpec.EXACTLY)
        )
        layout(0, 0, 96, 96)
        
        invalidate()
    }
    
    /**
     * Draw the marker circle
     */
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        
        Log.d(TAG, "onDraw called, canvas dimensions: ${canvas.width}x${canvas.height}")
        
        val centerX = width / 2f
        val centerY = height / 2f
        val radius = (width / 2f) - 8f // Smaller radius to leave room for badges
        
        // Draw main circle
        canvas.drawCircle(centerX, centerY, radius, circlePaint)
        
        // Draw border
        canvas.drawCircle(centerX, centerY, radius, borderPaint)
    }
    
    /**
     * Get color for event type
     */
    private fun getColorForEventType(eventType: EventType?): Int {
        return when (eventType) {
            EventType.STUDY -> Color.parseColor("#2196F3") // Blue
            EventType.PARTY -> Color.parseColor("#9C27B0") // Purple
            EventType.BUSINESS -> Color.parseColor("#FF9800") // Orange
            EventType.OTHER -> Color.parseColor("#607D8B") // Gray
            null -> Color.parseColor("#607D8B") // Default gray
        }
    }
    
    /**
     * Set icon based on event type
     */
    private fun setIconForEventType(eventType: EventType?) {
        val iconResId = when (eventType) {
            EventType.STUDY -> R.drawable.ic_study
            EventType.PARTY -> R.drawable.ic_party
            EventType.BUSINESS -> R.drawable.ic_business
            EventType.OTHER -> R.drawable.ic_other
            null -> R.drawable.ic_other
        }
        
        try {
            iconView.setImageResource(iconResId)
            iconView.setColorFilter(Color.WHITE)
            Log.d(TAG, "Set icon for type: $eventType")
        } catch (e: Exception) {
            // Fallback to a default icon if the resource doesn't exist
            Log.e(TAG, "Error setting icon for type $eventType: ${e.message}", e)
            try {
                iconView.setImageResource(android.R.drawable.ic_menu_info_details)
                iconView.setColorFilter(Color.WHITE)
            } catch (e2: Exception) {
                Log.e(TAG, "Failed to set fallback icon: ${e2.message}", e2)
            }
        }
    }
    
    /**
     * Helper method to create a bitmap snapshot of this view
     */
    fun createViewBitmap(): android.graphics.Bitmap {
        Log.d(TAG, "Creating bitmap from view")
        
        // Force layout and measure if needed
        if (width == 0 || height == 0) {
            measure(
                MeasureSpec.makeMeasureSpec(96, MeasureSpec.EXACTLY),
                MeasureSpec.makeMeasureSpec(96, MeasureSpec.EXACTLY)
            )
            layout(0, 0, 96, 96)
        }
        
        // Make the background transparent instead of debug color
        setBackgroundColor(Color.TRANSPARENT)
        
        // Create bitmap with ARGB_8888 config to ensure alpha channel
        val bitmap = android.graphics.Bitmap.createBitmap(
            96, 96, android.graphics.Bitmap.Config.ARGB_8888
        )
        
        // Clear the bitmap to transparent
        bitmap.eraseColor(Color.TRANSPARENT)
        
        // Draw view into canvas
        val canvas = android.graphics.Canvas(bitmap)
        draw(canvas)
        
        Log.d(TAG, "Bitmap created: ${bitmap.width}x${bitmap.height}")
        return bitmap
    }
} 