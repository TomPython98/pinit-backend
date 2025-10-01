package com.example.pinit.utils

import android.content.Context
import android.util.Log
import com.mapbox.common.MapboxOptions

/**
 * Helper class for Mapbox-related functionality
 */
object MapboxHelper {
    private const val TAG = "MapboxHelper"
    
    // Mapbox public access token (this should match what's in AndroidManifest.xml)
    private const val MAPBOX_ACCESS_TOKEN = "pk.eyJ1IjoidG9tYmVzaSIsImEiOiJjbTdwNDdvbXAwY3I3MmtzYmZ3dzVtaGJrIn0.yiXVdzVGYjTucLPZPa0hjw"
    
    // Flag to track initialization status
    private var isInitialized = false
    
    /**
     * Initialize Mapbox with the application token
     * 
     * @return True if initialization was successful
     */
    fun initialize(context: Context): Boolean {
        return try {
            if (!isInitialized) {
                Log.d(TAG, "Initializing Mapbox framework")
                
                // EXPLICITLY SET THE TOKEN USING CORRECT CLASS FOR MAPBOX v11
                MapboxOptions.accessToken = MAPBOX_ACCESS_TOKEN
                
                isInitialized = true
                Log.d(TAG, "Mapbox initialized successfully with token: ${MAPBOX_ACCESS_TOKEN.take(15)}...")
            } else {
                Log.d(TAG, "Mapbox already initialized")
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing Mapbox: ${e.message}", e)
            false
        }
    }
    
    /**
     * Get Mapbox token
     */
    fun getAccessToken(): String {
        return MAPBOX_ACCESS_TOKEN
    }
    
    /**
     * Check if Mapbox is properly initialized
     */
    fun isMapboxInitialized(): Boolean {
        return isInitialized
    }
} 