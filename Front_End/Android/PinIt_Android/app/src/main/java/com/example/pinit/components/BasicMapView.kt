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
import com.example.pinit.ui.theme.BrandPrimary
import com.mapbox.maps.CameraOptions
import com.mapbox.maps.MapView
import com.mapbox.maps.Style

@Composable
fun BasicMapView() {
    // Track map loading state
    var isMapReady by remember { mutableStateOf(false) }
    var mapError by remember { mutableStateOf<String?>(null) }
    val context = LocalContext.current
    
    // Map container
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(200.dp)
            .clip(RoundedCornerShape(16.dp)),
        contentAlignment = Alignment.Center
    ) {
        // Mapbox map using the simplest method possible
        AndroidView(
            factory = { ctx ->
                try {
                    Log.d("BasicMapView", "Creating MapView")
                    
                    // Create the MapView using the simplest constructor
                    val mapView = MapView(ctx)
                    
                    // Vienna coordinates
                    val viennaCoordinates = com.mapbox.geojson.Point.fromLngLat(16.3738, 48.2082)
                    
                    // Configure camera position
                    val cameraPosition = CameraOptions.Builder()
                        .center(viennaCoordinates)
                        .zoom(13.5) // Higher zoom level for better city view
                        .pitch(45.0) // Add some tilt for a more engaging view  
                        .bearing(10.0) // Slight rotation for better orientation
                        .build()
                        
                    // Set camera position
                    mapView.mapboxMap.setCamera(cameraPosition)
                    
                    // Load a basic map style
                    mapView.getMapboxMap().loadStyleUri(Style.MAPBOX_STREETS) {
                        // Ensure camera is still correctly positioned after style loads
                        mapView.mapboxMap.setCamera(cameraPosition)
                        
                        isMapReady = true
                        Log.d("BasicMapView", "Map style loaded successfully")
                    }
                    
                    // Return the map view
                    mapView
                } catch (e: Exception) {
                    Log.e("BasicMapView", "Error creating MapView: ${e.message}", e)
                    mapError = e.message
                    // Return empty view on error
                    android.view.View(ctx)
                }
            },
            modifier = Modifier.fillMaxSize()
        )
        
        // Loading or error overlay
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
                    CircularProgressIndicator(color = BrandPrimary)
                }
            }
        }
    }
} 