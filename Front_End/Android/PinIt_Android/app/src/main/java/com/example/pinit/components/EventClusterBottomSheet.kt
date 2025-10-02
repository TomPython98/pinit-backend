package com.example.pinit.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.pinit.models.StudyEventMap
import com.example.pinit.models.EventType
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventClusterBottomSheet(
    events: List<StudyEventMap>,
    onEventClick: (StudyEventMap) -> Unit,
    onDismiss: () -> Unit
) {
    val bottomSheetState = rememberBottomSheetScaffoldState()
    
    BottomSheetScaffold(
        scaffoldState = bottomSheetState,
        sheetContent = {
            EventClusterContent(
                events = events,
                onEventClick = onEventClick,
                onDismiss = onDismiss
            )
        },
        sheetPeekHeight = 0.dp
    ) {
        // Empty content - this is just for the bottom sheet
    }
}

@Composable
fun EventClusterContent(
    events: List<StudyEventMap>,
    onEventClick: (StudyEventMap) -> Unit,
    onDismiss: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.White)
            .padding(16.dp)
    ) {
        // Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "${events.size} Events at This Location",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                color = Color.Black
            )
            
            TextButton(onClick = onDismiss) {
                Text("Close", color = Color(0xFF007AFF))
            }
        }
        
        Spacer(modifier = Modifier.height(8.dp))
        
        // Location info
        Text(
            text = "📍 ${events.firstOrNull()?.coordinate?.let { "(${it.first}, ${it.second})" } ?: "Unknown Location"}",
            fontSize = 14.sp,
            color = Color(0xFF8E8E93),
            modifier = Modifier.padding(bottom = 16.dp)
        )
        
        // Events list
        LazyColumn(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(events) { event ->
                EventClusterItem(
                    event = event,
                    onClick = { onEventClick(event) }
                )
            }
        }
    }
}

@Composable
fun EventClusterItem(
    event: StudyEventMap,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Event type and title row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Event type indicator
                    Box(
                        modifier = Modifier
                            .size(12.dp)
                            .background(
                                getEventTypeColor(event.eventType),
                                RoundedCornerShape(6.dp)
                            )
                    )
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    Text(
                        text = event.title,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.Black,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f)
                    )
                }
                
                // Event type badge
                Box(
                    modifier = Modifier
                        .background(
                            getEventTypeColor(event.eventType).copy(alpha = 0.2f),
                            RoundedCornerShape(12.dp)
                        )
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = event.eventType?.displayName ?: "Other",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium,
                        color = getEventTypeColor(event.eventType)
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Description
            Text(
                text = event.description ?: "No description available",
                fontSize = 14.sp,
                color = Color(0xFF8E8E93),
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Time and attendees
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Time
                Text(
                    text = formatEventTime(event),
                    fontSize = 12.sp,
                    color = Color(0xFF8E8E93)
                )
                
                // Attendees count
                Text(
                    text = "${event.attendees}/${event.maxParticipants} attendees",
                    fontSize = 12.sp,
                    color = Color(0xFF8E8E93)
                )
            }
            
            // Host info
            if (event.host.isNotEmpty()) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Hosted by ${event.host}",
                    fontSize = 12.sp,
                    color = Color(0xFF8E8E93),
                    fontStyle = androidx.compose.ui.text.font.FontStyle.Italic
                )
            }
        }
    }
}

private fun getEventTypeColor(eventType: EventType?): Color {
    return when (eventType) {
        EventType.STUDY -> Color(0xFF007AFF)      // iOS Blue
        EventType.PARTY -> Color(0xFFAF52DE)      // iOS Purple
        EventType.BUSINESS -> Color(0xFF5856D6)  // iOS Indigo
        EventType.CULTURAL -> Color(0xFFFF9500)  // iOS Orange
        EventType.ACADEMIC -> Color(0xFF34C759)  // iOS Green
        EventType.NETWORKING -> Color(0xFFFF2D92) // iOS Pink
        EventType.SOCIAL -> Color(0xFFFF3B30)    // iOS Red
        EventType.LANGUAGE_EXCHANGE -> Color(0xFF5AC8FA) // iOS Teal
        EventType.OTHER -> Color(0xFF8E8E93)     // iOS Gray
        null -> Color(0xFF8E8E93)
    }
}

private fun formatEventTime(event: StudyEventMap): String {
    return try {
        val formatter = DateTimeFormatter.ofPattern("MMM dd, HH:mm")
        event.time.format(formatter)
    } catch (e: Exception) {
        "TBD"
    }
}
