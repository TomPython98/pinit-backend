package com.example.pinit.components

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Brightness7
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.Interests
import androidx.compose.material.icons.rounded.LocalLibrary
import androidx.compose.material.icons.rounded.School
import androidx.compose.ui.graphics.vector.ImageVector

/**
 * Custom extension for Icons to add additional icons or provide fallbacks
 * where needed icons might not be available in the current API level
 */
object CustomIcons {
    
    /**
     * Interest icon - using Book as a fallback if Interests isn't available
     */
    val Interests: ImageVector
        get() = try {
            Icons.Default.Interests
        } catch (e: Exception) {
            Icons.Default.Book
        }
    
    /**
     * Psychology icon - using Psychology if available, School as fallback
     */
    val Psychology: ImageVector 
        get() = try {
            Icons.Default.Psychology
        } catch (e: Exception) {
            Icons.Default.School
        }
} 