package com.example.pinit.components

import android.util.Log
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
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
import com.mapbox.geojson.Point
import com.mapbox.maps.*
import com.mapbox.maps.plugin.animation.CameraAnimationsPlugin
import com.mapbox.maps.plugin.animation.camera

/**
 * A map view that explicitly sets the Mapbox access token programmatically
 * for direct token access as recommended in error messages.
 */
@Composable
fun DirectAccessMapView() {
    // Track map loading state
    var isMapReady by remember { mutableStateOf(false) }
    var mapError by remember { mutableStateOf<String?>(null) }
    val context = LocalContext.current
    
    // Buenos Aires coordinates
    val buenosAiresCoordinates = Point.fromLngLat(-58.3816, -34.6037)
    
    // The direct token
    val directToken = "pk.eyJ1IjoidG9tYmVzaSIsImEiOiJjbTdwNDdvbXAwY3I3MmtzYmZ3dzVtaGJrIn0.yiXVdzVGYjTucLPZPa0hjw"
    
    // Map container
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(200.dp)
            .clip(RoundedCornerShape(16.dp)),
        contentAlignment = Alignment.Center
    ) {
        // This is the actual map view with directly set token
        AndroidView(
            factory = { ctx ->
                try {
                    Log.d("DirectAccessMapView", "Creating MapView with direct token access")
                    
                    // Explicitly set the token as recommended in the error message
                    com.mapbox.common.MapboxOptions.accessToken = directToken
                    
                    // Create the MapView after token is set
                    val mapView = MapView(ctx)
                    
                    // Configure camera position
                    val cameraPosition = CameraOptions.Builder()
                        .center(buenosAiresCoordinates)
                        .zoom(13.5) // Slightly higher zoom level for better city view
                        .pitch(45.0) // Add some tilt for a more engaging view
                        .bearing(10.0) // Slight rotation for better orientation
                        .build()
                    
                    // Set camera position before loading style
                    mapView.mapboxMap.setCamera(cameraPosition)
                    
                    // Load map style
                    mapView.mapboxMap.loadStyleUri(Style.MAPBOX_STREETS) {
                        Log.d("DirectAccessMapView", "Map style loaded successfully")
                        
                        // Ensure camera is correctly positioned after style loads
                        mapView.mapboxMap.setCamera(cameraPosition)
                        
                        isMapReady = true
                    }
                    
                    // Return the map view
                    mapView
                } catch (e: Exception) {
                    Log.e("DirectAccessMapView", "Error creating map: ${e.message}", e)
                    mapError = e.message
                    // Return empty view on error
                    android.view.View(ctx)
                }
            },
            modifier = Modifier.fillMaxSize()
        )
        
        // Show loading or error state
        if (!isMapReady) {
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
                            text = "Map Error",
                            fontWeight = FontWeight.Bold,
                            color = Color.Red
                        )
                        Text(
                            text = mapError ?: "Unknown error",
                            color = Color.DarkGray,
                            textAlign = TextAlign.Center
                        )
                    }
                } else {
                    // Loading indicator
                    CircularProgressIndicator(color = Color(0xFF1976D2))
                }
            }
        }
        
        // Location label at bottom
        if (isMapReady) {
            Column(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .background(
                        Color.Black.copy(alpha = 0.5f),
                        shape = RoundedCornerShape(bottomStart = 16.dp, bottomEnd = 16.dp)
                    )
                    .padding(vertical = 8.dp, horizontal = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "Buenos Aires, Argentina",
                    color = Color.White,
                    style = MaterialTheme.typography.bodyLarge
                )
            }
        }
    }
} 