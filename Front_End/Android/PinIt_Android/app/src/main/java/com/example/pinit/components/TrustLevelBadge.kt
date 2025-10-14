package com.example.pinit.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.pinit.models.TrustLevel

/**
 * Trust level badge component
 * Displays user's trust level with icon and color
 */
@Composable
fun TrustLevelBadge(
    trustLevel: TrustLevel,
    modifier: Modifier = Modifier,
    showTitle: Boolean = true,
    size: TrustLevelBadgeSize = TrustLevelBadgeSize.MEDIUM
) {
    val color = getTrustLevelColor(trustLevel.level)
    val icon = getTrustLevelIcon(trustLevel.level)
    
    when (size) {
        TrustLevelBadgeSize.SMALL -> SmallBadge(trustLevel, color, icon, modifier)
        TrustLevelBadgeSize.MEDIUM -> MediumBadge(trustLevel, color, icon, showTitle, modifier)
        TrustLevelBadgeSize.LARGE -> LargeBadge(trustLevel, color, icon, modifier)
    }
}

@Composable
private fun SmallBadge(
    trustLevel: TrustLevel,
    color: Color,
    icon: ImageVector,
    modifier: Modifier
) {
    Box(
        modifier = modifier
            .size(24.dp)
            .background(color.copy(alpha = 0.2f), CircleShape),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = trustLevel.title,
            tint = color,
            modifier = Modifier.size(16.dp)
        )
    }
}

@Composable
private fun MediumBadge(
    trustLevel: TrustLevel,
    color: Color,
    icon: ImageVector,
    showTitle: Boolean,
    modifier: Modifier
) {
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(12.dp),
        color = color.copy(alpha = 0.1f),
        border = androidx.compose.foundation.BorderStroke(1.dp, color.copy(alpha = 0.3f))
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = trustLevel.title,
                tint = color,
                modifier = Modifier.size(16.dp)
            )
            if (showTitle) {
                Text(
                    text = trustLevel.title,
                    style = MaterialTheme.typography.labelSmall,
                    color = color,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}

@Composable
private fun LargeBadge(
    trustLevel: TrustLevel,
    color: Color,
    icon: ImageVector,
    modifier: Modifier
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = color.copy(alpha = 0.1f)
        ),
        border = androidx.compose.foundation.BorderStroke(2.dp, color.copy(alpha = 0.3f))
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .background(color.copy(alpha = 0.2f), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = trustLevel.title,
                    tint = color,
                    modifier = Modifier.size(28.dp)
                )
            }
            Text(
                text = trustLevel.title,
                style = MaterialTheme.typography.titleMedium,
                color = color,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "Level ${trustLevel.level}",
                style = MaterialTheme.typography.bodySmall,
                color = color.copy(alpha = 0.7f)
            )
        }
    }
}

enum class TrustLevelBadgeSize {
    SMALL, MEDIUM, LARGE
}

private fun getTrustLevelColor(level: Int): Color {
    return when (level) {
        1 -> Color(0xFF9E9E9E) // Gray
        2 -> Color(0xFF2196F3) // Blue
        3 -> Color(0xFF4CAF50) // Green
        4 -> Color(0xFFFF9800) // Orange
        5 -> Color(0xFFFFC107) // Gold
        else -> Color(0xFF9E9E9E)
    }
}

private fun getTrustLevelIcon(level: Int): ImageVector {
    return when (level) {
        1 -> Icons.Default.PersonOutline
        2 -> Icons.Default.Person
        3 -> Icons.Default.VerifiedUser
        4 -> Icons.Default.Stars
        5 -> Icons.Default.EmojiEvents
        else -> Icons.Default.PersonOutline
    }
}

/**
 * Compact inline trust level indicator
 */
@Composable
fun InlineTrustLevel(
    trustLevel: TrustLevel,
    modifier: Modifier = Modifier
) {
    val color = getTrustLevelColor(trustLevel.level)
    val icon = getTrustLevelIcon(trustLevel.level)
    
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = trustLevel.title,
            tint = color,
            modifier = Modifier.size(14.dp)
        )
        Text(
            text = trustLevel.title,
            style = MaterialTheme.typography.labelSmall,
            color = color,
            fontSize = 11.sp
        )
    }
}


