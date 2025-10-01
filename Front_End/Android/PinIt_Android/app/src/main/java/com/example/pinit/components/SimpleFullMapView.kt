package com.example.pinit.components

import android.content.Context
import android.util.Log
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import com.example.pinit.ui.theme.*
import com.mapbox.geojson.Point
import com.mapbox.maps.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SimpleFullMapView(onDismiss: () -> Unit) {
    // Track map loading state
    var isMapReady by remember { mutableStateOf(false) }
    var mapError by remember { mutableStateOf<String?>(null) }
    val context = LocalContext.current
    
    // Buenos Aires coordinates
    val buenosAiresCoordinates = Point.fromLngLat(-58.3816, -34.6037)
    
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = BgSurface
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Campus Map",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
                
                IconButton(onClick = onDismiss) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Close",
                        tint = TextPrimary
                    )
                }
            }
            
            // Map view
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(400.dp)
                    .padding(horizontal = 16.dp)
            ) {
                // Mapbox map
                AndroidView(
                    factory = { ctx ->
                        try {
                            Log.d("SimpleFullMapView", "Creating full map view")
                            // Create a simple map view directly
                            val directToken = "pk.eyJ1IjoidG9tYmVzaSIsImEiOiJjbTdwNDdvbXAwY3I3MmtzYmZ3dzVtaGJrIn0.yiXVdzVGYjTucLPZPa0hjw"
                            
                            // Create the MapView directly
                            val mapView = MapView(ctx)
                            
                            // Get the Mapbox map
                            val mapboxMap = mapView.mapboxMap
                            
                            // Set camera position
                            val cameraOptions = CameraOptions.Builder()
                                .center(buenosAiresCoordinates)
                                .zoom(12.0)
                                .build()
                            mapboxMap.setCamera(cameraOptions)
                            
                            // Load map style
                            mapboxMap.loadStyleUri(Style.MAPBOX_STREETS) {
                                Log.d("SimpleFullMapView", "Map style loaded successfully")
                                isMapReady = true
                            }
                            
                            // Return the map view
                            mapView
                        } catch (e: Exception) {
                            Log.e("SimpleFullMapView", "Error creating map: ${e.message}", e)
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
                                    text = "Could not load map",
                                    fontWeight = FontWeight.Bold,
                                    color = Color.Red
                                )
                                Spacer(modifier = Modifier.height(4.dp))
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
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Information text
            Text(
                text = "This is a simple Mapbox map centered on Buenos Aires, Argentina.",
                style = MaterialTheme.typography.bodyMedium,
                color = TextSecondary,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 32.dp)
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Close button
            Button(
                onClick = onDismiss,
                colors = ButtonDefaults.buttonColors(
                    containerColor = PrimaryColor
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
            ) {
                Text("Close Map")
            }
        }
    }
} 