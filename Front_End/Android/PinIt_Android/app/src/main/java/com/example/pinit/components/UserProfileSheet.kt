package com.example.pinit.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.pinit.models.UserAccountManager
import com.example.pinit.ui.theme.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.ui.graphics.vector.ImageVector
import com.example.pinit.components.SectionHeader

/**
 * User Profile Sheet for viewing other users' profiles
 * This matches the iOS implementation for viewing user profiles
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UserProfileSheet(
    username: String,
    accountManager: UserAccountManager,
    onDismiss: () -> Unit,
    onSendMessage: (String) -> Unit = {},
    onAddFriend: (String) -> Unit = {},
    onBlockUser: (String) -> Unit = {}
) {
    // Mock user profile data - in real implementation, this would come from API
    val userProfile = remember(username) {
        UserProfileData(
            username = username,
            fullName = "John Doe",
            university = "University of Buenos Aires",
            degree = "Computer Science",
            year = "Senior",
            bio = "Passionate about technology and learning. Always up for a good study session!",
            isCertified = true,
            interests = listOf("Programming", "Machine Learning", "Mobile Development", "Data Science"),
            skills = mapOf(
                "Kotlin" to "ADVANCED",
                "Python" to "EXPERT",
                "Swift" to "INTERMEDIATE",
                "JavaScript" to "ADVANCED"
            ),
            reputation = 4.7,
            eventsHosted = 15,
            eventsAttended = 32,
            friendsCount = 67,
            mutualFriends = listOf("alice123", "bob456", "charlie789")
        )
    }
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.5f)),
        contentAlignment = Alignment.Center
    ) {
        Card(
            modifier = Modifier
                .fillMaxWidth(0.95f)
                .fillMaxHeight(0.9f)
                .padding(16.dp)
                .clip(RoundedCornerShape(20.dp)),
            elevation = CardDefaults.cardElevation(defaultElevation = 12.dp)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Enhanced header with gradient background
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(120.dp)
                        .background(
                            brush = Brush.linearGradient(
                                colors = listOf(
                                    Color(0xFF1E3A8A),
                                    Color(0xFF3B82F6),
                                    Color(0xFF60A5FA)
                                )
                            ),
                            shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp)
                        )
                ) {
                    // Close button
                    IconButton(
                        onClick = onDismiss,
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .padding(16.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "Close",
                            tint = Color.White,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                    
                    // User name in header
                    Text(
                        text = userProfile.fullName,
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        modifier = Modifier
                            .align(Alignment.BottomStart)
                            .padding(20.dp)
                    )
                }
                
                // Profile content
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    // Profile picture with enhanced styling
                    Box(
                        modifier = Modifier
                            .size(120.dp)
                            .clip(CircleShape)
                            .background(
                                brush = Brush.radialGradient(
                                    colors = listOf(
                                        Color(0xFF1E3A8A).copy(alpha = 0.1f),
                                        Color(0xFF3B82F6).copy(alpha = 0.05f)
                                    )
                                )
                            )
                            .border(
                                width = 3.dp,
                                color = Color(0xFF1E3A8A).copy(alpha = 0.3f),
                                shape = CircleShape
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Person,
                            contentDescription = "Profile Picture",
                            modifier = Modifier.size(60.dp),
                            tint = Color(0xFF1E3A8A)
                        )
                    }

                    Spacer(modifier = Modifier.height(20.dp))

                    // Username with enhanced styling
                    Text(
                        text = "@${userProfile.username}",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Medium,
                        color = Color(0xFF6B7280)
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    // Full name
                    Text(
                        text = userProfile.fullName,
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF1E3A8A)
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    // Certification badge if certified
                    if (userProfile.isCertified) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.Verified,
                                contentDescription = "Certified",
                                tint = Color(0xFF10B981),
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Verified User",
                                color = Color(0xFF10B981),
                                fontSize = 16.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // Bio section
                    if (userProfile.bio.isNotEmpty()) {
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            shape = RoundedCornerShape(16.dp),
                            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = Color(0xFFF8FAFC)
                            )
                        ) {
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp)
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        Icons.Default.Info,
                                        contentDescription = "Bio",
                                        tint = Color(0xFF1E3A8A),
                                        modifier = Modifier.size(20.dp)
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = "About",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 16.sp,
                                        color = Color(0xFF1E3A8A)
                                    )
                                }
                                
                                Spacer(modifier = Modifier.height(8.dp))
                                
                                Text(
                                    text = userProfile.bio,
                                    fontSize = 14.sp,
                                    color = Color(0xFF374151),
                                    lineHeight = 20.sp
                                )
                            }
                        }
                    }
                    
                    // University info
                    if (userProfile.university.isNotEmpty()) {
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            shape = RoundedCornerShape(16.dp),
                            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = Color(0xFFF8FAFC)
                            )
                        ) {
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp)
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        Icons.Default.School,
                                        contentDescription = "Education",
                                        tint = Color(0xFF1E3A8A),
                                        modifier = Modifier.size(20.dp)
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = "Education",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 16.sp,
                                        color = Color(0xFF1E3A8A)
                                    )
                                }
                                
                                Spacer(modifier = Modifier.height(8.dp))
                                
                                Text(
                                    text = userProfile.university,
                                    fontSize = 16.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = Color(0xFF1E3A8A)
                                )
                                
                                if (userProfile.degree.isNotEmpty()) {
                                    Text(
                                        text = "${userProfile.degree} • ${userProfile.year}",
                                        fontSize = 14.sp,
                                        color = Color(0xFF6B7280)
                                    )
                                }
                            }
                        }
                    }
                    
                    // Interests section
                    if (userProfile.interests.isNotEmpty()) {
                        SectionHeader(
                            title = "Interests",
                            icon = Icons.Default.Favorite
                        )
                        
                        LazyRow(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            items(userProfile.interests) { interest ->
                                SimpleInterestChip(interest = interest)
                            }
                        }
                    }
                    
                    // Skills section
                    if (userProfile.skills.isNotEmpty()) {
                        SectionHeader(
                            title = "Skills",
                            icon = Icons.Default.Psychology
                        )
                        
                        Column(
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            userProfile.skills.forEach { (skill, level) ->
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(vertical = 4.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = skill,
                                        modifier = Modifier.weight(1f),
                                        fontSize = 14.sp
                                    )
                                    
                                    SimpleSkillLevelChip(level = level)
                                }
                            }
                        }
                    }
                    
                    // Reputation section
                    SectionHeader(
                        title = "Reputation",
                        icon = Icons.Default.EmojiEvents
                    )
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        SimpleUserStatItem(
                            label = "Events",
                            value = "${userProfile.eventsHosted}",
                            icon = Icons.Default.Event
                        )
                        SimpleUserStatItem(
                            label = "Friends",
                            value = "${userProfile.friendsCount}",
                            icon = Icons.Default.People
                        )
                        SimpleUserStatItem(
                            label = "Rating",
                            value = String.format("%.1f", userProfile.reputation),
                            icon = Icons.Default.Star
                        )
                    }
                    
                    // Mutual friends section
                    if (userProfile.mutualFriends.isNotEmpty()) {
                        SectionHeader(
                            title = "Mutual Friends",
                            icon = Icons.Default.People
                        )
                        
                        LazyRow(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            items(userProfile.mutualFriends) { friend ->
                                MutualFriendChip(friendName = friend)
                            }
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // Action buttons
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        // Send message button
                        Button(
                            onClick = { onSendMessage(username) },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = Color(0xFF3B82F6)
                            ),
                            shape = RoundedCornerShape(16.dp),
                            elevation = ButtonDefaults.buttonElevation(
                                defaultElevation = 4.dp,
                                pressedElevation = 8.dp
                            ),
                            contentPadding = PaddingValues(vertical = 16.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Message,
                                contentDescription = "Send Message",
                                modifier = Modifier.size(24.dp)
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                "Send Message",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        
                        // Add friend button
                        OutlinedButton(
                            onClick = { onAddFriend(username) },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(16.dp),
                            contentPadding = PaddingValues(vertical = 16.dp),
                            colors = ButtonDefaults.outlinedButtonColors(
                                contentColor = Color(0xFF10B981)
                            ),
                            border = BorderStroke(2.dp, Color(0xFF10B981))
                        ) {
                            Icon(
                                imageVector = Icons.Default.PersonAdd,
                                contentDescription = "Add Friend",
                                modifier = Modifier.size(24.dp)
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                "Add Friend",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        
                        // Block user button
                        OutlinedButton(
                            onClick = { onBlockUser(username) },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(16.dp),
                            contentPadding = PaddingValues(vertical = 16.dp),
                            colors = ButtonDefaults.outlinedButtonColors(
                                contentColor = Color(0xFFEF4444)
                            ),
                            border = BorderStroke(2.dp, Color(0xFFEF4444))
                        ) {
                            Icon(
                                imageVector = Icons.Default.Block,
                                contentDescription = "Block User",
                                modifier = Modifier.size(24.dp)
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                "Block User",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }
        }
    }
}

// Data class for user profile
data class UserProfileData(
    val username: String,
    val fullName: String,
    val university: String,
    val degree: String,
    val year: String,
    val bio: String,
    val isCertified: Boolean,
    val interests: List<String>,
    val skills: Map<String, String>,
    val reputation: Double,
    val eventsHosted: Int,
    val eventsAttended: Int,
    val friendsCount: Int,
    val mutualFriends: List<String>
)

@Composable
fun MutualFriendChip(friendName: String) {
    Surface(
        modifier = Modifier.padding(4.dp),
        shape = RoundedCornerShape(20.dp),
        color = Color(0xFF1E3A8A).copy(alpha = 0.1f),
        shadowElevation = 2.dp
    ) {
        Row(
            modifier = Modifier.padding(vertical = 8.dp, horizontal = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Friend avatar
            Box(
                modifier = Modifier
                    .size(20.dp)
                    .clip(CircleShape)
                    .background(Color(0xFF1E3A8A).copy(alpha = 0.2f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = "Friend",
                    tint = Color(0xFF1E3A8A),
                    modifier = Modifier.size(12.dp)
                )
            }
            
            Spacer(modifier = Modifier.width(6.dp))
            
            Text(
                text = friendName,
                color = Color(0xFF1E3A8A),
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

@Composable
fun SimpleInterestChip(interest: String) {
    Surface(
        modifier = Modifier.padding(4.dp),
        shape = RoundedCornerShape(20.dp),
        color = Color(0xFF1E3A8A).copy(alpha = 0.1f),
        shadowElevation = 2.dp
    ) {
        Text(
            text = interest,
            color = Color(0xFF1E3A8A),
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.padding(vertical = 8.dp, horizontal = 12.dp)
        )
    }
}

@Composable
fun SimpleSkillLevelChip(level: String) {
    val color = when (level) {
        "BEGINNER" -> Color(0xFF90CAF9)      // Light Blue
        "INTERMEDIATE" -> Color(0xFF4CAF50)  // Green
        "ADVANCED" -> Color(0xFFFFA726)      // Orange
        "EXPERT" -> Color(0xFFF44336)        // Red
        else -> Color.Gray
    }
    
    Surface(
        shape = RoundedCornerShape(16.dp),
        color = color.copy(alpha = 0.2f)
    ) {
        Text(
            text = level,
            color = color,
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}

@Composable
private fun SimpleUserStatItem(
    label: String,
    value: String,
    icon: ImageVector
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(24.dp)
        )
        Text(
            text = value,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onSurface
        )
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}
