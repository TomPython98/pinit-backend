package com.example.pinit.models

import com.mapbox.geojson.Point

/**
 * Utility class for converting between coordinate formats
 */
object CoordinateConverter {
    /**
     * Convert a Pair<Double, Double> to a Point object
     * @param coordinate Pair where first is longitude, second is latitude
     * @return Point object with the coordinates
     */
    fun fromPair(coordinate: Pair<Double, Double>): Point {
        return Point.fromLngLat(coordinate.first, coordinate.second)
    }
    
    /**
     * Convert a Point object to a Pair<Double, Double>
     * @param point Point object
     * @return Pair where first is longitude, second is latitude
     */
    fun toPair(point: Point): Pair<Double, Double> {
        return Pair(point.longitude(), point.latitude())
    }
} 