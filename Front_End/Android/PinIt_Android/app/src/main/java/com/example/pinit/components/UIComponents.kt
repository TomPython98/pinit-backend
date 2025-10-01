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
    Text(
        text = title,
        style = MaterialTheme.typography.headlineSmall,
        fontWeight = FontWeight.Bold,
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
    )
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
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Icon with enhanced gradient and shadow
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .size(64.dp)
                    .background(
                        color = backgroundColor,
                        shape = CircleShape
                    )
                    .shadow(
                        elevation = 4.dp,
                        spotColor = backgroundColor.copy(alpha = 0.25f),
                        shape = CircleShape
                    )
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = title,
                    tint = Color.White,
                    modifier = Modifier.size(28.dp)
                )
            }
            
            // Title and description
            Column(modifier = Modifier.padding(top = 8.dp)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
                
                Spacer(modifier = Modifier.height(4.dp))
                
                Text(
                    text = description,
                    style = MaterialTheme.typography.bodySmall,
                    color = TextSecondary
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
        // Icon with refined gradient and shadow
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(48.dp)
                .shadow(
                    elevation = 6.dp,
                    spotColor = CardShadow,
                    shape = CircleShape
                )
                .background(
                    color = BgCard,
                    shape = CircleShape
                )
        ) {
            Icon(
                imageVector = icon,
                contentDescription = title,
                tint = iconTint,
                modifier = Modifier.size(24.dp)
            )
        }
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = title,
            style = MaterialTheme.typography.bodySmall,
            fontWeight = FontWeight.Medium,
            color = TextPrimary
        )
    }
}
