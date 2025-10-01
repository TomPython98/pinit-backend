package com.example.pinit.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import android.util.Log
import com.example.pinit.ui.theme.BrandPrimary

/**
 * A super simplified map view component to ensure compatibility
 */
@Composable
fun SuperSimpleMapView() {
    Box(
        modifier = Modifier.fillMaxSize()
    ) {
        // Show a placeholder instead of a map
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFFE0E0E0)),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "Campus Map View",
                style = MaterialTheme.typography.titleLarge,
                color = Color.DarkGray
            )
        }
        
        // Add a location label at the bottom
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
                text = "Vienna, Austria",
                color = Color.White,
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
} 