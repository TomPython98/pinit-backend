package com.example.pinit.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.*
import com.example.pinit.models.WeatherViewModel
import com.example.pinit.ui.theme.*
import androidx.compose.foundation.border

@Composable
fun MapAndCalendarView(
    selectedDate: MutableState<LocalDate>,
    showCalendar: MutableState<Boolean>,
    onCalendarClick: () -> Unit = { showCalendar.value = true },
    onMapClick: () -> Unit = {}
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .shadow(
                elevation = 12.dp,
                spotColor = CardShadow,
                shape = RoundedCornerShape(24.dp)
            ),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = BgCard)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
        ) {
            // Map Preview Section
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(160.dp)
                    .clip(RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp))
                    .clickable(onClick = onMapClick)
            ) {
                // Use the MiniMapView component here
                com.example.pinit.components.MiniMapView(
                    onMapClick = onMapClick
                )
                
                // Weather info overlay with refined design (as a small overlay badge)
                WeatherOverlay()
            }
            
            // View Map Button Section
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(onClick = onMapClick)
                    .padding(vertical = 16.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Map,
                    contentDescription = "Map",
                    tint = BrandPrimary,
                    modifier = Modifier.size(20.dp)
                )
                
                Spacer(modifier = Modifier.width(8.dp))
                
                Text(
                    text = "View Full Map",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimary
                )
                
                Spacer(modifier = Modifier.width(8.dp))
                
                Icon(
                    imageVector = Icons.Default.ArrowForward,
                    contentDescription = "Go to map",
                    tint = BrandPrimary,
                    modifier = Modifier.size(16.dp)
                )
            }
        }
    }
}

@Composable
fun WeatherOverlay() {
    Box(
        modifier = Modifier
            .padding(12.dp)
    ) {
        Row(
            modifier = Modifier
                .clip(RoundedCornerShape(14.dp))
                .background(Color.Black.copy(alpha = 0.5f))
                .padding(10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Weather icon with gradient background
            Box(
                modifier = Modifier
                    .size(42.dp)
                    .background(
                        brush = Brush.linearGradient(
                            colors = listOf(
                                BrandSecondary,
                                BrandSecondary.copy(alpha = 0.85f)
                            )
                        ),
                        shape = CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.WbSunny,
                    contentDescription = "Weather",
                    tint = Color.White,
                    modifier = Modifier.size(20.dp)
                )
            }
            
            Column(
                verticalArrangement = Arrangement.spacedBy(3.dp)
            ) {
                Text(
                    text = "24°C",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                
                Text(
                    text = "Vienna",
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Medium,
                    color = Color.White
                )
            }
        }
    }
}

@Composable
fun DayCircle(
    day: String,
    date: String,
    isToday: Boolean,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .padding(horizontal = 4.dp)
            .clickable(onClick = onClick)
    ) {
        Text(
            text = day,
            style = MaterialTheme.typography.bodySmall,
            color = TextSecondary,
            modifier = Modifier.padding(bottom = 4.dp)
        )
        
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(36.dp)
                .background(
                    color = when {
                        isSelected -> BrandPrimary
                        isToday -> BrandPrimary.copy(alpha = 0.2f)
                        else -> Color.Transparent
                    },
                    shape = CircleShape
                )
                .border(
                    width = if (isToday && !isSelected) 1.5.dp else 0.dp,
                    color = if (isToday && !isSelected) BrandPrimary else Color.Transparent,
                    shape = CircleShape
                )
        ) {
            Text(
                text = date,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = when {
                    isSelected -> Color.White
                    else -> TextPrimary
                }
            )
        }
    }
} 