package com.example.pinit.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.pinit.models.UserAccountManager
import com.example.pinit.models.UserProfile
import com.example.pinit.repository.ProfileRepository
import com.example.pinit.repository.EnhancedProfileRepository
import com.example.pinit.network.ApiClient
import kotlinx.coroutines.launch
import android.util.Log

/**
 * Enhanced Profile View that matches iOS functionality with Material Design
 * Includes all features from iOS ProfileView: completion progress, skills, interests, 
 * auto-matching, privacy settings, reputation, and API actions
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileView(
    accountManager: UserAccountManager,
    onDismiss: () -> Unit,
    onLogout: () -> Unit,
    forceRefresh: Boolean = false
) {
    var isLoading by remember { mutableStateOf(true) }
    var isSaving by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var profile by remember { mutableStateOf<UserProfile?>(null) }
    var hasUnsavedChanges by remember { mutableStateOf(false) }
    var editMode by remember { mutableStateOf(false) }
    var showEditSheet by remember { mutableStateOf(false) }
    
    // Profile data state
    var fullName by remember { mutableStateOf("") }
    var university by remember { mutableStateOf("") }
    var degree by remember { mutableStateOf("") }
    var year by remember { mutableStateOf("") }
    var bio by remember { mutableStateOf("") }
    var interests by remember { mutableStateOf<List<String>>(emptyList()) }
    var skills by remember { mutableStateOf<Map<String, String>>(emptyMap()) }
    var autoInviteEnabled by remember { mutableStateOf(false) }
    var preferredRadius by remember { mutableStateOf(5) }
    
    // Stats
    var eventsHosted by remember { mutableStateOf(0) }
    var eventsAttended by remember { mutableStateOf(0) }
    var friendsCount by remember { mutableStateOf(0) }
    var averageRating by remember { mutableStateOf(0.0) }
    
    val profileRepository = remember { ProfileRepository() }
    val enhancedProfileRepository = remember { EnhancedProfileRepository(ApiClient.apiService) }
    val scope = rememberCoroutineScope()
    
    // Calculate profile completion percentage
    val profileCompletionPercentage by remember(profile) {
        derivedStateOf {
            if (profile == null) return@derivedStateOf 0.0
            
            var completedFields = 0
            var totalFields = 8
            
            if (!profile!!.fullName.isNullOrEmpty()) completedFields++
            if (!profile!!.university.isNullOrEmpty()) completedFields++
            if (!profile!!.degree.isNullOrEmpty()) completedFields++
            if (!profile!!.year.isNullOrEmpty()) completedFields++
            if (!profile!!.bio.isNullOrEmpty()) completedFields++
            if (profile!!.interests.isNotEmpty()) completedFields++
            if (profile!!.skills.isNotEmpty()) completedFields++
            if (profile!!.isCertified) completedFields++
            
            (completedFields.toDouble() / totalFields * 100).toInt().toDouble()
        }
    }
    
    // Load profile data
    LaunchedEffect(forceRefresh) {
        isLoading = true
        errorMessage = null
        
        try {
            val currentUser = accountManager.currentUser ?: "Guest"
            
            // Fetch user profile
            profileRepository.getUserProfile(currentUser).collect { result ->
                result.onSuccess { userProfile ->
                    profile = userProfile
                    fullName = userProfile.fullName ?: ""
                    university = userProfile.university ?: ""
                    degree = userProfile.degree ?: ""
                    year = userProfile.year ?: ""
                    bio = userProfile.bio ?: ""
                    interests = userProfile.interests ?: emptyList()
                    skills = userProfile.skills ?: emptyMap()
                    autoInviteEnabled = userProfile.autoInviteEnabled ?: false
                    preferredRadius = (userProfile.preferredRadius ?: 5).toInt()
                    Log.d("ProfileView", "✅ Successfully loaded profile for $currentUser")
                }.onFailure { error ->
                    errorMessage = "Failed to load profile: ${error.message}"
                    Log.e("ProfileView", "❌ Failed to load profile: ${error.message}")
                }
            }
            
            // Fetch reputation data
            try {
                enhancedProfileRepository.getUserReputation(currentUser).collect { result ->
                    result.onSuccess { reputation ->
                        eventsHosted = reputation.events_hosted
                        eventsAttended = reputation.events_attended
                        averageRating = reputation.average_rating
                        Log.d("ProfileView", "✅ Successfully loaded reputation")
                    }.onFailure { error ->
                        Log.w("ProfileView", "⚠️ Failed to load reputation: ${error.message}")
                    }
                }
            } catch (e: Exception) {
                Log.w("ProfileView", "⚠️ Exception loading reputation: ${e.message}")
            }
            
            // Fetch friends count
            try {
                enhancedProfileRepository.getFriends(currentUser).collect { result ->
                    result.onSuccess { friendsList ->
                        friendsCount = friendsList.size
                        Log.d("ProfileView", "✅ Successfully loaded friends")
                    }.onFailure { error ->
                        Log.w("ProfileView", "⚠️ Failed to load friends: ${error.message}")
                    }
                }
            } catch (e: Exception) {
                Log.w("ProfileView", "⚠️ Exception loading friends: ${e.message}")
            }
            
        } catch (e: Exception) {
            errorMessage = "Failed to load user data: ${e.message}"
            Log.e("ProfileView", "❌ Exception loading user data: ${e.message}")
        } finally {
            isLoading = false
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Text(
                        text = "Your Profile",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    ) 
                },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (editMode) {
                        TextButton(onClick = { editMode = false }) {
                            Text("Cancel")
                        }
                        TextButton(
                            onClick = { 
                                // TODO: Save changes
                                editMode = false 
                            }
                        ) {
                            Text("Save")
                        }
                    } else {
                        IconButton(onClick = { editMode = true }) {
                            Icon(Icons.Default.Edit, contentDescription = "Edit Profile")
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.onSurface,
                    navigationIconContentColor = MaterialTheme.colorScheme.onSurface,
                    actionIconContentColor = MaterialTheme.colorScheme.onSurface
                )
            )
        }
    ) { paddingValues ->
        if (isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    CircularProgressIndicator(
                        color = MaterialTheme.colorScheme.primary,
                        strokeWidth = 3.dp,
                        modifier = Modifier.size(48.dp)
                    )
                    Text(
                        text = "Loading profile...",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        } else if (errorMessage != null) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Error,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.error,
                        modifier = Modifier.size(48.dp)
                    )
                    Text(
                        text = errorMessage!!,
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.error,
                        textAlign = TextAlign.Center
                    )
                    Button(onClick = { /* Retry loading */ }) {
                        Text("Retry")
                    }
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                item {
                    ProfileHeaderCard(
                        profile = profile,
                        accountManager = accountManager,
                        editMode = editMode,
                        onEditClick = { showEditSheet = true }
                    )
                }
                
                item {
                    ProfileCompletionCard(
                        completionPercentage = profileCompletionPercentage,
                        missingItems = getMissingProfileItems(profile)
                    )
                }
                
                item {
                    UserInfoCard(
                        profile = profile,
                        editMode = editMode,
                        onFieldChange = { field, value ->
                            hasUnsavedChanges = true
                            when (field) {
                                "fullName" -> fullName = value
                                "university" -> university = value
                                "degree" -> degree = value
                                "year" -> year = value
                                "bio" -> bio = value
                            }
                        }
                    )
                }
                
                item {
                    SkillsCard(
                        skills = skills,
                        editMode = editMode,
                        onSkillsChange = { newSkills ->
                            skills = newSkills
                            hasUnsavedChanges = true
                        }
                    )
                }
                
                item {
                    InterestsCard(
                        interests = interests,
                        editMode = editMode,
                        onInterestsChange = { newInterests ->
                            interests = newInterests
                            hasUnsavedChanges = true
                        }
                    )
                }
                
                item {
                    AutoMatchingCard(
                        autoInviteEnabled = autoInviteEnabled,
                        preferredRadius = preferredRadius,
                        editMode = editMode,
                        onAutoInviteChange = { enabled ->
                            autoInviteEnabled = enabled
                            hasUnsavedChanges = true
                        },
                        onRadiusChange = { radius ->
                            preferredRadius = radius
                            hasUnsavedChanges = true
                        }
                    )
                }
                
                item {
                    PrivacyCard(
                        editMode = editMode
                    )
                }
                
                item {
                    ReputationCard(
                        eventsHosted = eventsHosted,
                        eventsAttended = eventsAttended,
                        friendsCount = friendsCount,
                        averageRating = averageRating
                    )
                }
                
                item {
                    ApiActionCard(
                        onRefresh = { /* TODO: Refresh profile */ },
                        onSave = { /* TODO: Save profile */ },
                        isLoading = isSaving,
                        hasUnsavedChanges = hasUnsavedChanges
                    )
                }
            }
        }
    }
    
    // Edit Profile Sheet
    if (showEditSheet) {
        EditProfileSheet(
            profile = profile,
            onDismiss = { showEditSheet = false },
            onSave = { updatedProfile ->
                profile = updatedProfile
                showEditSheet = false
            }
        )
    }
}

// Helper function to get missing profile items
private fun getMissingProfileItems(profile: UserProfile?): List<String> {
    if (profile == null) return listOf("Profile not loaded")
    
    val missing = mutableListOf<String>()
    if (profile.fullName.isNullOrEmpty()) missing.add("Full Name")
    if (profile.university.isNullOrEmpty()) missing.add("University")
    if (profile.degree.isNullOrEmpty()) missing.add("Degree")
    if (profile.year.isNullOrEmpty()) missing.add("Year")
    if (profile.bio.isNullOrEmpty()) missing.add("Bio")
    if (profile.interests.isNullOrEmpty()) missing.add("Interests")
    if (profile.skills.isNullOrEmpty()) missing.add("Skills")
    if (!profile.isCertified) missing.add("Verification")
    
    return missing
}

// Profile Header Card
@Composable
private fun ProfileHeaderCard(
    profile: UserProfile?,
    accountManager: UserAccountManager,
    editMode: Boolean,
    onEditClick: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Profile Avatar
            Surface(
                modifier = Modifier.size(120.dp),
                shape = CircleShape,
                color = MaterialTheme.colorScheme.primaryContainer,
                shadowElevation = 8.dp
            ) {
                Box(contentAlignment = Alignment.Center) {
                    if (profile?.fullName?.isNotEmpty() == true) {
                        Text(
                            text = profile.fullName!!.take(1).uppercase(),
                            style = MaterialTheme.typography.headlineLarge,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    } else {
                        Icon(
                            imageVector = Icons.Default.Person,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onPrimaryContainer,
                            modifier = Modifier.size(48.dp)
                        )
                    }
                }
            }
            
            // User Info
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = profile?.fullName ?: accountManager.currentUser ?: "Guest",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                
                if (!profile?.university.isNullOrEmpty()) {
                    Text(
                        text = profile!!.university!!,
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                
                // Certification Badge
                if (profile?.isCertified == true) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Verified,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(20.dp)
                        )
                        Text(
                            text = "Verified User",
                            style = MaterialTheme.typography.labelLarge,
                            color = MaterialTheme.colorScheme.primary,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }
            
            // Edit Button
            if (!editMode) {
                OutlinedButton(
                    onClick = onEditClick,
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = MaterialTheme.colorScheme.primary
                    )
                ) {
                    Icon(
                        imageVector = Icons.Default.Edit,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Edit Profile")
                }
            }
        }
    }
}

// Profile Completion Card
@Composable
private fun ProfileCompletionCard(
    completionPercentage: Double,
    missingItems: List<String>
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Surface(
                    modifier = Modifier.size(40.dp),
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.primaryContainer
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onPrimaryContainer,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
                
                Column {
                    Text(
                        text = "Profile Completion",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = "${completionPercentage.toInt()}% Complete",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            
            // Progress Bar
            LinearProgressIndicator(
                progress = (completionPercentage / 100).toFloat(),
                modifier = Modifier.fillMaxWidth(),
                color = MaterialTheme.colorScheme.primary,
                trackColor = MaterialTheme.colorScheme.surfaceVariant
            )
            
            // Missing Items
            if (missingItems.isNotEmpty()) {
                Text(
                    text = "Missing: ${missingItems.joinToString(", ")}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

// User Info Card
@Composable
private fun UserInfoCard(
    profile: UserProfile?,
    editMode: Boolean,
    onFieldChange: (String, String) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Surface(
                    modifier = Modifier.size(40.dp),
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.secondaryContainer
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Default.Person,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSecondaryContainer,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
                
                Text(
                    text = "Personal Information",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
            
            // Info Fields
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                InfoField(
                    label = "Full Name",
                    value = profile?.fullName ?: "",
                    editMode = editMode,
                    onValueChange = { onFieldChange("fullName", it) }
                )
                
                InfoField(
                    label = "University",
                    value = profile?.university ?: "",
                    editMode = editMode,
                    onValueChange = { onFieldChange("university", it) }
                )
                
                InfoField(
                    label = "Degree",
                    value = profile?.degree ?: "",
                    editMode = editMode,
                    onValueChange = { onFieldChange("degree", it) }
                )
                
                InfoField(
                    label = "Year",
                    value = profile?.year ?: "",
                    editMode = editMode,
                    onValueChange = { onFieldChange("year", it) }
                )
                
                InfoField(
                    label = "Bio",
                    value = profile?.bio ?: "",
                    editMode = editMode,
                    onValueChange = { onFieldChange("bio", it) },
                    multiline = true
                )
            }
        }
    }
}

// Info Field Component
@Composable
private fun InfoField(
    label: String,
    value: String,
    editMode: Boolean,
    onValueChange: (String) -> Unit,
    multiline: Boolean = false
) {
    if (editMode) {
        if (multiline) {
            OutlinedTextField(
                value = value,
                onValueChange = onValueChange,
                label = { Text(label) },
                modifier = Modifier.fillMaxWidth(),
                minLines = 3,
                maxLines = 5
            )
        } else {
            OutlinedTextField(
                value = value,
                onValueChange = onValueChange,
                label = { Text(label) },
                modifier = Modifier.fillMaxWidth()
            )
        }
    } else {
        Column {
            Text(
                text = label,
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = value.ifEmpty { "Not provided" },
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

// Skills Card
@Composable
private fun SkillsCard(
    skills: Map<String, String>,
    editMode: Boolean,
    onSkillsChange: (Map<String, String>) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Surface(
                    modifier = Modifier.size(40.dp),
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.tertiaryContainer
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Default.Star,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onTertiaryContainer,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
                
                Text(
                    text = "Skills",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
            
            if (skills.isNotEmpty()) {
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(skills.entries.toList()) { (skill, level) ->
                        SkillChip(skill = skill, level = level)
                    }
                }
            } else {
                Text(
                    text = "No skills added yet",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

// Skill Chip Component
@Composable
private fun SkillChip(skill: String, level: String) {
    Surface(
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.primaryContainer,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = skill,
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
            Text(
                text = level,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
            )
        }
    }
}

// Interests Card
@Composable
private fun InterestsCard(
    interests: List<String>,
    editMode: Boolean,
    onInterestsChange: (List<String>) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Surface(
                    modifier = Modifier.size(40.dp),
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.secondaryContainer
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Default.Favorite,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSecondaryContainer,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
                
                Text(
                    text = "Interests",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
            
            if (interests.isNotEmpty()) {
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(interests) { interest ->
                        InterestChip(interest = interest)
                    }
                }
            } else {
                Text(
                    text = "No interests added yet",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

// Interest Chip Component
@Composable
private fun InterestChip(interest: String) {
    Surface(
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.secondaryContainer
    ) {
        Text(
            text = interest,
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.Medium,
            color = MaterialTheme.colorScheme.onSecondaryContainer,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)
        )
    }
}

// Auto-Matching Card
@Composable
private fun AutoMatchingCard(
    autoInviteEnabled: Boolean,
    preferredRadius: Int,
    editMode: Boolean,
    onAutoInviteChange: (Boolean) -> Unit,
    onRadiusChange: (Int) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Surface(
                    modifier = Modifier.size(40.dp),
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.primaryContainer
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Default.AutoAwesome,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onPrimaryContainer,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
                
                Text(
                    text = "Auto-Matching",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
            
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Enable Auto-Invites",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Switch(
                        checked = autoInviteEnabled,
                        onCheckedChange = onAutoInviteChange,
                        enabled = editMode
                    )
                }
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Preferred Radius: ${preferredRadius}km",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    if (editMode) {
                        Slider(
                            value = preferredRadius.toFloat(),
                            onValueChange = { onRadiusChange(it.toInt()) },
                            valueRange = 1f..50f,
                            steps = 48
                        )
                    }
                }
            }
        }
    }
}

// Privacy Card
@Composable
private fun PrivacyCard(editMode: Boolean) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Surface(
                    modifier = Modifier.size(40.dp),
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.errorContainer
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Default.Security,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onErrorContainer,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
                
                Text(
                    text = "Privacy Settings",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
            
            Text(
                text = "Privacy settings functionality coming soon...",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

// Reputation Card
@Composable
private fun ReputationCard(
    eventsHosted: Int,
    eventsAttended: Int,
    friendsCount: Int,
    averageRating: Double
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Surface(
                    modifier = Modifier.size(40.dp),
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.primaryContainer
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Default.EmojiEvents,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onPrimaryContainer,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
                
                Text(
                    text = "Reputation",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                ReputationStat(
                    label = "Events Hosted",
                    value = eventsHosted.toString(),
                    icon = Icons.Default.Event
                )
                ReputationStat(
                    label = "Events Attended",
                    value = eventsAttended.toString(),
                    icon = Icons.Default.CheckCircle
                )
                ReputationStat(
                    label = "Friends",
                    value = friendsCount.toString(),
                    icon = Icons.Default.People
                )
                ReputationStat(
                    label = "Rating",
                    value = String.format("%.1f", averageRating),
                    icon = Icons.Default.Star
                )
            }
        }
    }
}

// Reputation Stat Component
@Composable
private fun ReputationStat(
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

// API Action Card
@Composable
private fun ApiActionCard(
    onRefresh: () -> Unit,
    onSave: () -> Unit,
    isLoading: Boolean,
    hasUnsavedChanges: Boolean
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Surface(
                    modifier = Modifier.size(40.dp),
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.secondaryContainer
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Default.Settings,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSecondaryContainer,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
                
                Text(
                    text = "Actions",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedButton(
                    onClick = onRefresh,
                    modifier = Modifier.weight(1f),
                    enabled = !isLoading
                ) {
                    Icon(
                        imageVector = Icons.Default.Refresh,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Refresh")
                }
                
                Button(
                    onClick = onSave,
                    modifier = Modifier.weight(1f),
                    enabled = hasUnsavedChanges && !isLoading
                ) {
                    Icon(
                        imageVector = Icons.Default.Save,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Save")
                }
            }
        }
    }
}

// Edit Profile Sheet
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun EditProfileSheet(
    profile: UserProfile?,
    onDismiss: () -> Unit,
    onSave: (UserProfile) -> Unit
) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = MaterialTheme.colorScheme.surface,
        contentColor = MaterialTheme.colorScheme.onSurface
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Edit Profile",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
            
            Text(
                text = "Edit profile functionality coming soon...",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Button(
                onClick = onDismiss,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Close")
            }
        }
    }
}