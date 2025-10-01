package com.example.pinit.views

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
import com.example.pinit.models.UserAccountManager
import com.example.pinit.ui.theme.*
import com.example.pinit.utils.MapboxHelper
import com.mapbox.geojson.Point
import com.mapbox.maps.*
import android.util.Log

/**
 * A simple view that displays a Mapbox map centered on Vienna.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MapboxView(
    accountManager: UserAccountManager,
    onDismiss: () -> Unit
) {
    // Coordinates for Vienna, Austria
    val viennaCoordinates = Point.fromLngLat(16.3738, 48.2082)
    
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
            Log.e("MapboxView", "Error in Mapbox init", e)
            mapInitError = "Mapbox Error: ${e.message}"
        }
    }
    
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
            // Header with title and close button
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
                AndroidView(
                    factory = { ctx ->
                        try {
                            Log.d("MapboxView", "Creating full MapView")
                            
                            // Create the map view with the access token
                            val mapView = MapView(ctx).apply {
                                // Get the token from our helper
                                val token = MapboxHelper.getAccessToken()
                                Log.d("MapboxView", "Using token: ${token.take(8)}...")
                            }
                            
                            // Access the Mapbox map instance
                            val mapboxMap = mapView.getMapboxMap()
                            
                            // Configure the camera
                            val cameraOptions = CameraOptions.Builder()
                                .center(viennaCoordinates)
                                .zoom(12.0)
                                .build()
                            
                            // Set the camera position
                            mapboxMap.setCamera(cameraOptions)
                            
                            // Load the map style
                            mapboxMap.loadStyleUri(Style.MAPBOX_STREETS) {
                                isMapReady = true
                                Log.d("MapboxView", "Full map style loaded successfully")
                            }
                            
                            // Return the map view
                            mapView
                        } catch (e: Exception) {
                            Log.e("MapboxView", "Error creating full MapView: ${e.message}", e)
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
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Information text
            Text(
                text = "This is a simple Mapbox map centered on Vienna, Austria.",
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