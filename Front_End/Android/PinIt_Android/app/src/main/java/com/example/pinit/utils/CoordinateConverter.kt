package com.example.pinit.utils

import android.util.Log
import com.mapbox.geojson.Point

/**
 * Utility class for converting between coordinate formats with enhanced validation
 */
object CoordinateConverter {
    private const val TAG = "CoordinateConverter"
    
    /**
     * Convert a Pair<Double, Double> to a Point object with validation
     * In our data model, Pair is (longitude, latitude), matching what Mapbox expects
     * 
     * @param coordinate Pair where first is longitude, second is latitude
     * @return Point object with the coordinates, or null if invalid
     */
    fun fromPair(coordinate: Pair<Double, Double>?): Point? {
        if (coordinate == null) {
            Log.w(TAG, "Cannot convert null coordinate to Point")
            return null
        }
        
        val longitude = coordinate.first
        val latitude = coordinate.second
        
        // Validate coordinates are within reasonable ranges
        if (!isValidLongitude(longitude) || !isValidLatitude(latitude)) {
            Log.w(TAG, "Invalid coordinate values: longitude=$longitude, latitude=$latitude")
            return null
        }
        
        Log.d(TAG, "Converting coordinate: longitude=$longitude, latitude=$latitude to Point")
        return Point.fromLngLat(longitude, latitude)
    }
    
    /**
     * Convert a Point object to a Pair<Double, Double> with validation
     * 
     * @param point Point object
     * @return Pair where first is longitude, second is latitude, or null if point is invalid
     */
    fun toPair(point: Point?): Pair<Double, Double>? {
        if (point == null) {
            Log.w(TAG, "Cannot convert null Point to coordinate Pair")
            return null
        }
        
        val longitude = point.longitude()
        val latitude = point.latitude()
        
        // Validate coordinates are within reasonable ranges
        if (!isValidLongitude(longitude) || !isValidLatitude(latitude)) {
            Log.w(TAG, "Invalid Point values: longitude=$longitude, latitude=$latitude")
            return null
        }
        
        Log.d(TAG, "Converting Point: longitude=$longitude, latitude=$latitude to Pair")
        return Pair(longitude, latitude)
    }
    
    /**
     * Check if a latitude value is valid (-90 to 90 degrees)
     */
    fun isValidLatitude(latitude: Double): Boolean {
        return latitude.isFinite() && latitude >= -90.0 && latitude <= 90.0
    }
    
    /**
     * Check if a longitude value is valid (-180 to 180 degrees)
     */
    fun isValidLongitude(longitude: Double): Boolean {
        return longitude.isFinite() && longitude >= -180.0 && longitude <= 180.0
    }
} 