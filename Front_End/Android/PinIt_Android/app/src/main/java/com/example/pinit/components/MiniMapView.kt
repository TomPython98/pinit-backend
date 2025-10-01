package com.example.pinit.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.ArrowForward
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
import com.example.pinit.ui.theme.*
import com.example.pinit.utils.MapboxHelper
import com.mapbox.geojson.Point
import com.mapbox.maps.*
import android.util.Log
import androidx.compose.foundation.layout.Box
import kotlinx.coroutines.delay

/**
 * A compact Mapbox map view for the main screen, showing Buenos Aires.
 */
@Composable
fun MiniMapView(
    onMapClick: () -> Unit
) {
    // Buenos Aires coordinates
    val buenosAiresCoordinates = Point.fromLngLat(-58.3816, -34.6037)
    
    // Track map loading state
    var isMapReady by remember { mutableStateOf(false) }
    var mapInitError by remember { mutableStateOf<String?>(null) }
    val context = LocalContext.current
    
    // Ensure Mapbox is initialized
    LaunchedEffect(Unit) {
        try {
            // Initialize our helper
            MapboxHelper.initialize(context)
        } catch (e: Exception) {
            Log.e("MiniMapView", "Error in Mapbox init", e)
            mapInitError = "Mapbox Error: ${e.message}"
        }
    }
    
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .clickable(onClick = onMapClick),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = BgCard),
        elevation = CardDefaults.cardElevation(defaultElevation = 3.dp)
    ) {
        Column(modifier = Modifier.padding(bottom = 16.dp)) {
            // Map view with fixed height
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(160.dp)
                    .clip(RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp))
            ) {
                AndroidView(
                    factory = { ctx ->
                        try {
                            Log.d("MiniMapView", "Creating MapView")
                            
                            // Create the map view with the access token
                            val mapView = MapView(ctx).apply {
                                // Get the token from our helper
                                val token = MapboxHelper.getAccessToken()
                                Log.d("MiniMapView", "Using token: ${token.take(8)}...")
                            }
                            
                            // Access the Mapbox map instance
                            val mapboxMap = mapView.getMapboxMap()
                            
                            // Configure the camera
                            val cameraOptions = CameraOptions.Builder()
                                .center(buenosAiresCoordinates)
                                .zoom(13.0)
                                .build()
                            
                            // Set the camera position
                            mapboxMap.setCamera(cameraOptions)
                            
                            // Load the map style
                            mapboxMap.loadStyleUri(Style.MAPBOX_STREETS) {
                                isMapReady = true
                                Log.d("MiniMapView", "Map style loaded successfully")
                            }
                            
                            // Return the map view
                            mapView
                        } catch (e: Exception) {
                            Log.e("MiniMapView", "Error creating MapView: ${e.message}", e)
                            mapInitError = "Map Creation Error: ${e.message}"
                            // Return a simple view if map creation fails
                            android.view.View(ctx)
                        }
                    },
                    modifier = Modifier.fillMaxSize()
                )
                
                // Loading indicator or error message
                if (!isMapReady) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(Color.LightGray.copy(alpha = 0.7f)),
                        contentAlignment = Alignment.Center
                    ) {
                        if (mapInitError != null) {
                            // Show error message with more details
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                modifier = Modifier.padding(16.dp)
                            ) {
                                Text(
                                    text = "Could not load map",
                                    color = Color.Red,
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                
                                Spacer(modifier = Modifier.height(4.dp))
                                
                                Text(
                                    text = mapInitError ?: "Unknown error",
                                    color = Color.DarkGray,
                                    style = MaterialTheme.typography.bodySmall,
                                    textAlign = TextAlign.Center
                                )
                            }
                        } else {
                            // Show loading indicator
                            CircularProgressIndicator(
                                color = BrandPrimary,
                                modifier = Modifier.size(40.dp)
                            )
                        }
                    }
                }
                
                // Location pill overlay (show only when map is ready)
                if (isMapReady) {
                    Card(
                        modifier = Modifier
                            .padding(12.dp)
                            .align(Alignment.TopStart),
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = Color.Black.copy(alpha = 0.6f)
                        )
                    ) {
                        Row(
                            modifier = Modifier.padding(vertical = 6.dp, horizontal = 10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.LocationOn,
                                contentDescription = "Location",
                                tint = Color.White,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "Buenos Aires, Argentina",
                                color = Color.White,
                                style = MaterialTheme.typography.labelMedium
                            )
                        }
                    }
                }
            }
            
            // Button bar at the bottom with "View Map" text and arrow
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Map,
                    contentDescription = "Map Icon",
                    tint = BrandPrimary,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "View Campus Map",
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.SemiBold,
                    color = BrandPrimary
                )
                Spacer(modifier = Modifier.width(8.dp))
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                    contentDescription = "View Map",
                    tint = BrandPrimary,
                    modifier = Modifier.size(16.dp)
                )
            }
        }
    }
} 