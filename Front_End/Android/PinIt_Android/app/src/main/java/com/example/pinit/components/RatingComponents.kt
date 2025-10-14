package com.example.pinit.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog

/**
 * Star rating display (read-only)
 */
@Composable
fun StarRating(
    rating: Double,
    modifier: Modifier = Modifier,
    maxRating: Int = 5,
    starSize: androidx.compose.ui.unit.Dp = 16.dp,
    showValue: Boolean = true
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        repeat(maxRating) { index ->
            val starRating = (index + 1).toDouble()
            Icon(
                imageVector = when {
                    rating >= starRating -> Icons.Default.Star
                    rating >= starRating - 0.5 -> Icons.Default.StarHalf
                    else -> Icons.Default.StarOutline
                },
                contentDescription = null,
                tint = Color(0xFFFFC107),
                modifier = Modifier.size(starSize)
            )
        }
        
        if (showValue) {
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = String.format("%.1f", rating),
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                fontWeight = FontWeight.Medium
            )
        }
    }
}

/**
 * Interactive star rating (for submitting ratings)
 */
@Composable
fun InteractiveStarRating(
    currentRating: Int,
    onRatingChange: (Int) -> Unit,
    modifier: Modifier = Modifier,
    maxRating: Int = 5,
    starSize: androidx.compose.ui.unit.Dp = 32.dp
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        repeat(maxRating) { index ->
            val starRating = index + 1
            Icon(
                imageVector = if (starRating <= currentRating) Icons.Default.Star else Icons.Default.StarOutline,
                contentDescription = "Rate $starRating stars",
                tint = if (starRating <= currentRating) Color(0xFFFFC107) else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f),
                modifier = Modifier
                    .size(starSize)
                    .clickable { onRatingChange(starRating) }
            )
        }
    }
}

/**
 * Rating dialog for submitting user ratings
 */
@Composable
fun RatingDialog(
    username: String,
    eventTitle: String?,
    onDismiss: () -> Unit,
    onSubmit: (rating: Int, comment: String) -> Unit,
    isLoading: Boolean = false
) {
    var rating by remember { mutableStateOf(0) }
    var comment by remember { mutableStateOf("") }
    
    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surface
            )
        ) {
            Column(
                modifier = Modifier
                    .padding(24.dp)
                    .fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Header
                Icon(
                    imageVector = Icons.Default.Star,
                    contentDescription = null,
                    tint = Color(0xFFFFC107),
                    modifier = Modifier.size(48.dp)
                )
                
                Text(
                    text = "Rate $username",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center
                )
                
                if (eventTitle != null) {
                    Text(
                        text = "for: $eventTitle",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                        textAlign = TextAlign.Center
                    )
                }
                
                Divider()
                
                // Star rating
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "How was your experience?",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                    
                    InteractiveStarRating(
                        currentRating = rating,
                        onRatingChange = { rating = it },
                        starSize = 36.dp
                    )
                    
                    if (rating > 0) {
                        Text(
                            text = when (rating) {
                                1 -> "Poor"
                                2 -> "Fair"
                                3 -> "Good"
                                4 -> "Very Good"
                                5 -> "Excellent"
                                else -> ""
                            },
                            style = MaterialTheme.typography.labelLarge,
                            color = Color(0xFFFFC107),
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
                
                // Comment field
                OutlinedTextField(
                    value = comment,
                    onValueChange = { if (it.length <= 500) comment = it },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("Add a comment (optional)") },
                    placeholder = { Text("Share your experience...") },
                    minLines = 3,
                    maxLines = 5,
                    supportingText = {
                        Text(
                            text = "${comment.length}/500",
                            modifier = Modifier.fillMaxWidth(),
                            textAlign = TextAlign.End,
                            style = MaterialTheme.typography.labelSmall
                        )
                    }
                )
                
                // Action buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    OutlinedButton(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f),
                        enabled = !isLoading
                    ) {
                        Text("Cancel")
                    }
                    
                    Button(
                        onClick = {
                            if (rating > 0) {
                                onSubmit(rating, comment.trim())
                            }
                        },
                        modifier = Modifier.weight(1f),
                        enabled = rating > 0 && !isLoading,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFFFFC107),
                            contentColor = Color.Black
                        )
                    ) {
                        if (isLoading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(20.dp),
                                strokeWidth = 2.dp,
                                color = Color.Black
                            )
                        } else {
                            Text("Submit")
                        }
                    }
                }
            }
        }
    }
}

/**
 * Compact rating display with count
 */
@Composable
fun CompactRatingDisplay(
    averageRating: Double,
    totalRatings: Int,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Icon(
            imageVector = Icons.Default.Star,
            contentDescription = null,
            tint = Color(0xFFFFC107),
            modifier = Modifier.size(16.dp)
        )
        Text(
            text = String.format("%.1f", averageRating),
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.Bold
        )
        Text(
            text = "($totalRatings)",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
        )
    }
}


