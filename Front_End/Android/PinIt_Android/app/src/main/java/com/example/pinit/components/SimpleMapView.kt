package com.example.pinit.components

import android.content.Context
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
import com.mapbox.geojson.Point
import com.mapbox.maps.*

@Composable
fun SimpleMapView() {
    // Track map loading state
    var isMapReady by remember { mutableStateOf(false) }
    var mapError by remember { mutableStateOf<String?>(null) }
    val context = LocalContext.current
    
    // Vienna coordinates 
    val viennaCoordinates = Point.fromLngLat(16.3738, 48.2082)
    
    // Map container
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(200.dp)
            .clip(RoundedCornerShape(16.dp)),
        contentAlignment = Alignment.Center
    ) {
        // This is the actual map view
        AndroidView(
            factory = { ctx ->
                try {
                    Log.d("SimpleMapView", "Creating MapView")
                    // Create a simple map view directly with token hardcoded
                    val directToken = "pk.eyJ1IjoidG9tYmVzaSIsImEiOiJjbTdwNDdvbXAwY3I3MmtzYmZ3dzVtaGJrIn0.yiXVdzVGYjTucLPZPa0hjw"
                    
                    // Create the MapView directly
                    val mapView = MapView(ctx)
                    
                    // Get the Mapbox map
                    val mapboxMap = mapView.mapboxMap
                    
                    // Set camera position
                    val cameraOptions = CameraOptions.Builder()
                        .center(viennaCoordinates)
                        .zoom(12.0)
                        .build()
                    mapboxMap.setCamera(cameraOptions)
                    
                    // Load map style
                    mapboxMap.loadStyleUri(Style.MAPBOX_STREETS) {
                        Log.d("SimpleMapView", "Map style loaded successfully")
                        isMapReady = true
                    }
                    
                    // Return the map view
                    mapView
                } catch (e: Exception) {
                    Log.e("SimpleMapView", "Error creating map: ${e.message}", e)
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
                    CircularProgressIndicator(color = BrandPrimary)
                }
            }
        }
    }
} 