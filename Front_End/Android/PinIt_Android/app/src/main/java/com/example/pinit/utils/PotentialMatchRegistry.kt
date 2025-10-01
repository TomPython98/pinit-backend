package com.example.pinit.utils

import android.util.Log

/**
 * Registry to track potential matches across different parts of the app
 * This is used to ensure potential matches from the Invitations view are properly 
 * reflected in the Map view
 */
object PotentialMatchRegistry {
    private val TAG = "PotentialMatchRegistry"
    
    // Store potential matches IDs so they can be accessed by the map view
    private val potentialMatchIds = mutableSetOf<String>()
    
    // Track last refresh time
    var lastRefreshTime = 0L
    
    // Track current user to ensure we reset matches when user changes
    private var currentUser: String? = null
    
    /**
     * Register a potential match by its ID
     */
    fun registerPotentialMatch(eventId: String) {
        val normalizedId = eventId.trim().lowercase()
        potentialMatchIds.add(normalizedId)
        Log.d(TAG, "Registered potential match: $normalizedId")
    }
    
    /**
     * Check if an event is registered as a potential match
     */
    fun isEventPotentialMatch(eventId: String?): Boolean {
        if (eventId == null) return false
        val normalizedId = eventId.trim().lowercase()
        return potentialMatchIds.contains(normalizedId)
    }
    
    /**
     * Clear all registered potential matches
     */
    fun clear() {
        potentialMatchIds.clear()
        Log.d(TAG, "Cleared all potential match registrations")
    }
    
    /**
     * Reset registry for a new user or on app startup
     * This ensures that matches from previous users aren't shown
     */
    fun resetForUser(username: String?) {
        if (username != currentUser) {
            Log.d(TAG, "User changed from $currentUser to $username - clearing potential matches")
            clear()
            currentUser = username
        }
    }
    
    /**
     * Get count of registered potential matches
     */
    fun count(): Int {
        return potentialMatchIds.size
    }
    
    /**
     * Get all registered potential match IDs
     */
    fun getAllIds(): Set<String> {
        return potentialMatchIds.toSet()
    }
} 