package com.example.pinit.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.example.pinit.ui.theme.*

@Composable
fun MapSection() {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .height(200.dp)
            .padding(16.dp),
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        DirectAccessMapView()
    }
}

@Composable
fun SectionHeader(title: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )
        
        Text(
            text = "See All",
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium,
            color = BrandPrimary
        )
    }
}

@Composable
fun ToolsGrid(
    onFriendsClick: () -> Unit,
    onCalendarClick: () -> Unit,
    onInvitationsClick: () -> Unit,
    onFlashcardsClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Top row with Friends and Calendar
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Friends Button
            ToolCard(
                title = "Study Chat",
                description = "Connect with classmates",
                icon = Icons.Default.People,
                backgroundColor = BrandPrimary,
                modifier = Modifier
                    .weight(1f)
                    .height(166.dp),
                onClick = onFriendsClick
            )
            
            // Calendar Button
            ToolCard(
                title = "Schedule",
                description = "Manage your timetable",
                icon = Icons.Default.CalendarMonth,
                backgroundColor = BrandSuccess,
                modifier = Modifier
                    .weight(1f)
                    .height(166.dp),
                onClick = onCalendarClick
            )
        }
        
        // Bottom row with Invitations and Flashcards
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Invitations Button
            ToolCard(
                title = "Events",
                description = "Join university activities",
                icon = Icons.Default.EventNote,
                backgroundColor = BrandAccent,
                modifier = Modifier
                    .weight(1f)
                    .height(166.dp),
                onClick = onInvitationsClick
            )
            
            // Flashcards Button
            ToolCard(
                title = "Flashcards",
                description = "Study efficiently",
                icon = Icons.Default.Layers,
                backgroundColor = BrandWarning,
                modifier = Modifier
                    .weight(1f)
                    .height(166.dp),
                onClick = onFlashcardsClick
            )
        }
    }
}

@Composable
fun ToolCard(
    title: String,
    description: String,
    icon: ImageVector,
    backgroundColor: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Card(
        modifier = modifier
            .shadow(
                elevation = 12.dp,
                spotColor = CardShadow,
                shape = RoundedCornerShape(22.dp)
            )
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(22.dp),
        colors = CardDefaults.cardColors(containerColor = BgCard)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp)
        ) {
            // Icon with enhanced gradient and shadow (matching iOS)
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .size(64.dp)
                    .background(
                        brush = androidx.compose.ui.graphics.Brush.radialGradient(
                            colors = listOf(
                                backgroundColor,
                                backgroundColor.copy(alpha = 0.85f)
                            ),
                            radius = 32f
                        ),
                        shape = CircleShape
                    )
                    .shadow(
                        elevation = 8.dp,
                        spotColor = backgroundColor.copy(alpha = 0.25f),
                        shape = CircleShape
                    )
            ) {
                // Inner highlight (matching iOS)
                Box(
                    modifier = Modifier
                        .size(62.dp)
                        .background(
                            brush = androidx.compose.ui.graphics.Brush.radialGradient(
                                colors = listOf(
                                    Color.White.copy(alpha = 0.6f),
                                    Color.Transparent
                                ),
                                radius = 31f
                            ),
                            shape = CircleShape
                        )
                )
                
                Icon(
                    imageVector = icon,
                    contentDescription = title,
                    tint = Color.White,
                    modifier = Modifier.size(26.dp)
                )
            }
            
            // Title and description with refined typography (matching iOS)
            Column(
                modifier = Modifier.padding(horizontal = 8.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary,
                    textAlign = TextAlign.Center
                )
                
                Spacer(modifier = Modifier.height(6.dp))
                
                Text(
                    text = description,
                    style = MaterialTheme.typography.bodySmall,
                    color = TextSecondary,
                    textAlign = TextAlign.Center,
                    maxLines = 1,
                    overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis
                )
            }
        }
    }
}

@Composable
fun QuickAccessRow(onMapClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        QuickAccessButton(
            title = "Library",
            icon = Icons.Default.MenuBook,
            iconTint = BrandPrimary,
            onClick = { /* TODO: Open library */ }
        )
        
        QuickAccessButton(
            title = "Forum",
            icon = Icons.Default.Forum,
            iconTint = BrandSecondary,
            onClick = { /* TODO: Open forum */ }
        )
        
        QuickAccessButton(
            title = "Grades",
            icon = Icons.Default.Analytics,
            iconTint = BrandWarning,
            onClick = { /* TODO: Open grades */ }
        )
        
        QuickAccessButton(
            title = "Map",
            icon = Icons.Default.Map,
            iconTint = BrandAccent,
            onClick = onMapClick
        )
    }
}

@Composable
fun QuickAccessButton(
    title: String,
    icon: ImageVector,
    iconTint: Color = BrandPrimary,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .clickable(onClick = onClick)
            .padding(horizontal = 8.dp, vertical = 12.dp)
    ) {
        // Icon with enhanced gradient and shadow (matching iOS)
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(48.dp)
                .background(
                    brush = androidx.compose.ui.graphics.Brush.radialGradient(
                        colors = listOf(
                            GradientStart,
                            GradientMiddle,
                            GradientEnd
                        ),
                        radius = 24f
                    ),
                    shape = CircleShape
                )
                .shadow(
                    elevation = 8.dp,
                    spotColor = ColoredShadow,
                    shape = CircleShape
                )
        ) {
            Icon(
                imageVector = icon,
                contentDescription = title,
                tint = Color.White,
                modifier = Modifier.size(20.dp)
            )
        }
        
        Spacer(modifier = Modifier.height(14.dp))
        
        Text(
            text = title,
            style = MaterialTheme.typography.bodySmall,
            fontWeight = FontWeight.Medium,
            color = TextPrimary
        )
    }
}
