package com.example.pinit.components.map

import android.util.Log
import com.example.pinit.models.StudyEventMap
import com.example.pinit.models.CoordinateConverter
import com.mapbox.geojson.Point
import kotlin.math.abs

/**
 * Data class representing a cluster of events
 */
data class Cluster(
    val events: List<StudyEventMap>
) {
    private val TAG = "EventCluster"
    
    /**
     * Calculate the center coordinate of the cluster
     */
    val coordinate: Point
        get() {
            // If there's only one event, use its coordinate
            if (events.size == 1) {
                val singleCoord = events.first().coordinate
                if (singleCoord != null) {
                    return CoordinateConverter.fromPair(singleCoord)
                } else {
                    Log.w(TAG, "Single event has null coordinate, using default")
                    return Point.fromLngLat(16.3738, 48.2082) // Vienna as default
                }
            }
            
            // Calculate average of all valid coordinates
            val validEvents = events.filter { it.coordinate != null }
            if (validEvents.isEmpty()) {
                Log.w(TAG, "No valid coordinates in cluster, using default")
                return Point.fromLngLat(16.3738, 48.2082) // Vienna as default
            }
            
            val sumLat = validEvents.sumOf { it.coordinate!!.second }
            val sumLng = validEvents.sumOf { it.coordinate!!.first }
            
            val avgLng = sumLng / validEvents.size
            val avgLat = sumLat / validEvents.size
            
            Log.d(TAG, "Calculated cluster center: ($avgLng, $avgLat) from ${validEvents.size} events")
            return Point.fromLngLat(avgLng, avgLat)
        }
    
    /**
     * Check if two clusters are approximately equal
     */
    override fun equals(other: Any?): Boolean {
        if (other !is Cluster) return false
        
        // Compare event IDs
        val thisEventIds = events.map { it.id }.toSet()
        val otherEventIds = other.events.map { it.id }.toSet()
        
        if (thisEventIds != otherEventIds) return false
        
        // Check if coordinates are close
        return abs(coordinate.latitude() - other.coordinate.latitude()) < 0.0001 &&
               abs(coordinate.longitude() - other.coordinate.longitude()) < 0.0001
    }
    
    override fun hashCode(): Int {
        return events.map { it.id }.hashCode()
    }
}

/**
 * Utility class for clustering map events
 */
object MapClusteringUtils {
    private const val TAG = "MapClusteringUtils"
    
    /**
     * Calculate distance threshold based on zoom level and event density
     * Uses an adaptive approach to prevent overcrowding while maintaining meaningful clusters
     *
     * @param zoomLevel The current map zoom level
     * @param eventCount The number of events being clustered
     * @param mapWidth The width of the map viewport in pixels (optional)
     * @param mapHeight The height of the map viewport in pixels (optional)
     * @return The distance threshold to use for clustering
     */
    private fun calculateThreshold(
        zoomLevel: Double, 
        eventCount: Int,
        mapWidth: Int = 1080, // Default to typical screen width
        mapHeight: Int = 1920 // Default to typical screen height
    ): Double {
        // Base threshold scaled by zoom level
        val baseThreshold = when {
            zoomLevel >= 18.0 -> 0.0003  // Very close (about 33m)
            zoomLevel >= 16.0 -> 0.0008  // Close (about 88m)
            zoomLevel >= 14.0 -> 0.0020  // Medium (about 220m)
            zoomLevel >= 12.0 -> 0.0045  // Far (about 500m)
            zoomLevel >= 10.0 -> 0.0100  // Very far (about 1.1km)
            zoomLevel >= 8.0 -> 0.0180   // Extremely far (about 2km)
            else -> 0.0300               // Ultra far (about 3.3km)
        }
        
        // Density factor: more events = larger clusters (within reason)
        val densityFactor = when {
            eventCount > 100 -> 1.5      // Many events
            eventCount > 50 -> 1.3       // Lots of events
            eventCount > 20 -> 1.1       // Moderate number of events
            else -> 1.0                  // Few events
        }
        
        // Viewport factor: adjust for map viewport size
        val viewportArea = mapWidth * mapHeight
        val standardArea = 1080 * 1920 // Reference viewport size
        val viewportFactor = Math.sqrt(viewportArea.toDouble() / standardArea)
        
        // Apply all factors for the final threshold
        val finalThreshold = baseThreshold * densityFactor * viewportFactor
        
        Log.d(TAG, "Calculated threshold: $finalThreshold (zoom: $zoomLevel, events: $eventCount, density factor: $densityFactor)")
        return finalThreshold
    }
    
    /**
     * Cluster events based on proximity with improved algorithm
     * 
     * @param events List of events to cluster
     * @param zoomLevel Current map zoom level
     * @param mapWidth Map viewport width in pixels (optional)
     * @param mapHeight Map viewport height in pixels (optional)
     * @return List of clusters
     */
    fun clusterEvents(
        events: List<StudyEventMap>, 
        zoomLevel: Double,
        mapWidth: Int = 1080,
        mapHeight: Int = 1920
    ): List<Cluster> {
        Log.d(TAG, "Clustering ${events.size} events at zoom level $zoomLevel")
        
        // Early return if no events
        if (events.isEmpty()) {
            Log.d(TAG, "No events to cluster")
            return emptyList()
        }
        
        // Check for events with invalid coordinates
        val validEvents = events.filter { event -> 
            val isValid = event.coordinate != null && 
                         event.coordinate.first.isFinite() && 
                         event.coordinate.second.isFinite() &&
                         event.coordinate.first != 0.0 &&
                         event.coordinate.second != 0.0
            
            if (!isValid && event.coordinate != null) {
                Log.w(TAG, "Event ${event.id} has invalid coordinates: ${event.coordinate}")
            }
            
            isValid
        }
        
        if (validEvents.size < events.size) {
            Log.w(TAG, "Filtered out ${events.size - validEvents.size} events with invalid coordinates")
        }
        
        // If no valid events, return early
        if (validEvents.isEmpty()) {
            Log.w(TAG, "No events with valid coordinates")
            return emptyList()
        }
        
        // Calculate clustering threshold based on zoom and event density
        val threshold = calculateThreshold(zoomLevel, validEvents.size, mapWidth, mapHeight)
        
        // Group nearby events into initial clusters using improved algorithm
        val clusteredEvents = mutableSetOf<String>() // Track clustered events by ID
        val initialClusters = mutableListOf<Cluster>()
        
        // Sort events by popularity (attendees count) so more popular events become cluster centers
        val sortedEvents = validEvents.sortedByDescending { it.attendees }
        
        // Create clusters starting with the most popular events as centers
        for (centerEvent in sortedEvents) {
            // Skip if this event is already in a cluster
            if (clusteredEvents.contains(centerEvent.id)) continue
            
            // Create a new cluster with this event as the center
            val clusterEvents = mutableListOf(centerEvent)
            clusteredEvents.add(centerEvent.id ?: "")
            
            // Find nearby events to add to this cluster
            for (otherEvent in validEvents) {
                // Skip if this event is already in a cluster or it's the center event
                if (clusteredEvents.contains(otherEvent.id) || otherEvent.id == centerEvent.id) continue
                
                // Calculate distance using Haversine formula for better accuracy
                val distance = calculateHaversineDistance(
                    centerEvent.coordinate!!.second, centerEvent.coordinate.first,
                    otherEvent.coordinate!!.second, otherEvent.coordinate.first
                )
                
                if (distance <= threshold) {
                    clusterEvents.add(otherEvent)
                    clusteredEvents.add(otherEvent.id ?: "")
                }
            }
            
            // Add the new cluster to our list
            initialClusters.add(Cluster(clusterEvents))
        }
        
        // Optional: Merge small clusters that are very close to each other
        return mergeClustersIfNeeded(initialClusters, threshold)
    }
    
    /**
     * Merge clusters that are too close to each other to prevent visual clutter
     */
    private fun mergeClustersIfNeeded(clusters: List<Cluster>, baseThreshold: Double): List<Cluster> {
        if (clusters.size <= 1) return clusters
        
        val mergeThreshold = baseThreshold * 1.2 // Slightly larger threshold for merging
        val finalClusters = mutableListOf<Cluster>()
        val processedClusters = mutableSetOf<Int>()
        
        for (i in clusters.indices) {
            if (i in processedClusters) continue
            
            val cluster = clusters[i]
            val mergedEvents = cluster.events.toMutableList()
            processedClusters.add(i)
            
            // Check if this cluster should be merged with any other cluster
            for (j in clusters.indices) {
                if (j in processedClusters || i == j) continue
                
                val otherCluster = clusters[j]
                val clusterCenter = CoordinateConverter.toPair(cluster.coordinate)
                val otherCenter = CoordinateConverter.toPair(otherCluster.coordinate)
                
                if (clusterCenter != null && otherCenter != null) {
                    val distance = calculateHaversineDistance(
                        clusterCenter.second, clusterCenter.first,
                        otherCenter.second, otherCenter.first
                    )
                    
                    if (distance <= mergeThreshold) {
                        mergedEvents.addAll(otherCluster.events)
                        processedClusters.add(j)
                    }
                }
            }
            
            finalClusters.add(Cluster(mergedEvents))
        }
        
        return finalClusters
    }
    
    /**
     * Calculate Haversine distance between two points (more accurate than Euclidean for geo-coordinates)
     * 
     * @param lat1 Latitude of point 1 in degrees
     * @param lng1 Longitude of point 1 in degrees
     * @param lat2 Latitude of point 2 in degrees
     * @param lng2 Longitude of point 2 in degrees
     * @return Distance in degrees (multiply by 111.32 for km)
     */
    private fun calculateHaversineDistance(lat1: Double, lng1: Double, lat2: Double, lng2: Double): Double {
        val R = 6371.0 // Earth's radius in kilometers
        
        // Convert latitude and longitude from degrees to radians
        val latRad1 = Math.toRadians(lat1)
        val latRad2 = Math.toRadians(lat2)
        val lngRad1 = Math.toRadians(lng1)
        val lngRad2 = Math.toRadians(lng2)
        
        // Calculate differences
        val diffLat = latRad2 - latRad1
        val diffLng = lngRad2 - lngRad1
        
        // Haversine formula
        val a = Math.sin(diffLat/2) * Math.sin(diffLat/2) +
                Math.cos(latRad1) * Math.cos(latRad2) *
                Math.sin(diffLng/2) * Math.sin(diffLng/2)
        val c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
        
        // Convert back to degrees for consistency with other methods
        return c * (180 / Math.PI) / Math.PI
    }
} 