package com.example.pinit.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.pinit.models.UserAccountManager
import com.example.pinit.models.UserProfile
import com.example.pinit.models.ProfileCompletion
import com.example.pinit.viewmodels.ProfileViewModel
import com.example.pinit.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EnhancedProfileView(
    accountManager: UserAccountManager,
    onDismiss: () -> Unit,
    onLogout: () -> Unit
) {
    val profileViewModel = remember { ProfileViewModel(accountManager) }
    val profile = profileViewModel.profile.value
    val profileCompletion = profileViewModel.profileCompletion.value
    val isLoading = profileViewModel.isLoading.value
    val isSaving = profileViewModel.isSaving.value
    
    // State for editable fields
    var editMode by remember { mutableStateOf(false) }
    var fullName by remember { mutableStateOf(profile?.fullName ?: "") }
    var university by remember { mutableStateOf(profile?.university ?: "") }
    var degree by remember { mutableStateOf(profile?.degree ?: "") }
    var year by remember { mutableStateOf(profile?.year ?: "") }
    var bio by remember { mutableStateOf(profile?.bio ?: "") }
    var interests by remember { mutableStateOf(profile?.interests ?: emptyList()) }
    var skills by remember { mutableStateOf(profile?.skills ?: emptyMap()) }
    
    // Load profile data when view appears
    LaunchedEffect(Unit) {
        profileViewModel.refreshUserData()
        profileViewModel.fetchProfileCompletion()
    }
    
    // Update local state when profile changes
    LaunchedEffect(profile) {
        profile?.let {
            fullName = it.fullName
            university = it.university
            degree = it.degree
            year = it.year
            bio = it.bio
            interests = it.interests
            skills = it.skills
        }
    }
    
    // iOS-style background with gradient
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(BgSurface, BgSecondary),
                    startY = 0f,
                    endY = Float.POSITIVE_INFINITY
                )
            )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
        ) {
            // iOS-style header with gradient background
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        Brush.horizontalGradient(
                            colors = listOf(GradientStart, GradientMiddle, GradientEnd)
                        ),
                        shape = RoundedCornerShape(16.dp)
                    )
                    .padding(16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Profile",
                    color = TextLight,
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold
                )
                
                Row {
                    if (editMode) {
                        IconButton(
                            onClick = {
                                editMode = false
                                // Reset to original values
                                profile?.let {
                                    fullName = it.fullName
                                    university = it.university
                                    degree = it.degree
                                    year = it.year
                                    bio = it.bio
                                }
                            }
                        ) {
                            Icon(
                                Icons.AutoMirrored.Filled.Undo,
                                contentDescription = "Cancel",
                                tint = TextLight
                            )
                        }
                    }
                    
                    IconButton(
                        onClick = onLogout
                    ) {
                        Icon(
                            Icons.AutoMirrored.Filled.Logout,
                            contentDescription = "Logout",
                            tint = TextLight
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            if (isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Card(
                        modifier = Modifier.padding(16.dp),
                        colors = CardDefaults.cardColors(containerColor = BgCard),
                        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
                    ) {
                        Column(
                            modifier = Modifier.padding(24.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            CircularProgressIndicator(color = BrandPrimary)
                            Spacer(modifier = Modifier.height(16.dp))
                            Text(
                                "Loading profile...",
                                color = TextPrimary,
                                fontSize = 16.sp
                            )
                        }
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    verticalArrangement = Arrangement.spacedBy(20.dp)
                ) {
                    // Profile Header Section
                    item {
                        ProfileHeaderSection(
                            profile = profile,
                            editMode = editMode,
                            onEditModeToggle = { editMode = !editMode }
                        )
                    }
                    
                    // Profile Completion Section
                    item {
                        profileCompletion?.let { completion ->
                            ProfileCompletionSection(
                                completion = completion,
                                onEditProfile = { editMode = true }
                            )
                        }
                    }
                    
                    // User Information Section
                    item {
                        UserInfoSection(
                            fullName = fullName,
                            university = university,
                            degree = degree,
                            year = year,
                            bio = bio,
                            editMode = editMode,
                            onFullNameChange = { fullName = it },
                            onUniversityChange = { university = it },
                            onDegreeChange = { degree = it },
                            onYearChange = { year = it },
                            onBioChange = { bio = it }
                        )
                    }
                    
                    // Skills Section
                    item {
                        SkillsSection(
                            skills = skills,
                            editMode = editMode,
                            onSkillsChange = { skills = it }
                        )
                    }
                    
                    // Interests Section
                    item {
                        InterestsSection(
                            interests = interests,
                            editMode = editMode,
                            onInterestsChange = { interests = it }
                        )
                    }
                    
                    // Auto-Matching Preferences
                    item {
                        AutoMatchingSection(
                            profile = profile,
                            editMode = editMode
                        )
                    }
                    
                    // Privacy Section
                    item {
                        PrivacySection()
                    }
                    
                    // User Reputation Section
                    item {
                        ReputationSection()
                    }
                    
                    // Connected Accounts Section
                    item {
                        ConnectedAccountsSection()
                    }
                    
                    // API Action Buttons
                    item {
                        ApiActionButtons(
                            onRefreshProfile = {
                                profileViewModel.refreshUserData()
                                profileViewModel.fetchProfileCompletion()
                            },
                            onSaveProfile = {
                                // Update the ViewModel's editable state
                                profileViewModel.fullName.value = fullName
                                profileViewModel.university.value = university
                                profileViewModel.degree.value = degree
                                profileViewModel.year.value = year
                                profileViewModel.bio.value = bio
                                
                                // Update interests
                                profileViewModel.editableInterests.clear()
                                profileViewModel.editableInterests.addAll(interests)
                                
                                // Update skills using public methods
                                skills.forEach { entry ->
                                    profileViewModel.addOrUpdateSkill(entry.key, entry.value)
                                }
                                
                                // Save profile
                                profileViewModel.saveProfile()
                            }
                        )
                    }
                    
                    // Save Button
                    if (editMode) {
                        item {
                            SaveButton(
                                isLoading = isSaving,
                                onClick = {
                                    // Update the ViewModel's editable state
                                    profileViewModel.fullName.value = fullName
                                    profileViewModel.university.value = university
                                    profileViewModel.degree.value = degree
                                    profileViewModel.year.value = year
                                    profileViewModel.bio.value = bio
                                    
                                    // Update interests
                                    profileViewModel.editableInterests.clear()
                                    profileViewModel.editableInterests.addAll(interests)
                                    
                                    // Update skills using public methods
                                    skills.forEach { entry ->
                                        profileViewModel.addOrUpdateSkill(entry.key, entry.value)
                                    }
                                    
                                    // Save profile
                                    profileViewModel.saveProfile()
                                    editMode = false
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ProfileHeaderSection(
    profile: UserProfile?,
    editMode: Boolean,
    onEditModeToggle: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = 12.dp,
                shape = RoundedCornerShape(16.dp),
                spotColor = CardShadow
            ),
        colors = CardDefaults.cardColors(containerColor = BgCard),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // iOS-style circular profile image with layered design
            Box(
                contentAlignment = Alignment.Center
            ) {
                // Outer accent circle
                Box(
                    modifier = Modifier
                        .size(134.dp)
                        .background(
                            Brush.radialGradient(
                                colors = listOf(BgAccent, BgCard),
                                radius = 67f
                            ),
                            shape = CircleShape
                        )
                        .shadow(
                            elevation = 12.dp,
                            shape = CircleShape,
                            spotColor = CardShadow
                        )
                )
                
                // Inner white circle
                Box(
                    modifier = Modifier
                        .size(126.dp)
                        .background(BgCard, CircleShape)
                )
                
                // Profile icon
                Icon(
                    Icons.Filled.Person,
                    contentDescription = "Profile",
                    modifier = Modifier.size(112.dp),
                    tint = BrandPrimary
                )
                
                // Edit camera button (iOS-style)
                if (editMode) {
                    Box(
                        modifier = Modifier
                            .size(38.dp)
                            .background(
                                Brush.radialGradient(
                                    colors = listOf(GradientStart, GradientMiddle, GradientEnd),
                                    radius = 19f
                                ),
                                shape = CircleShape
                            )
                            .shadow(
                                elevation = 6.dp,
                                shape = CircleShape,
                                spotColor = CardShadow
                            )
                            .offset(x = 42.dp, y = 42.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Filled.CameraAlt,
                            contentDescription = "Edit Photo",
                            modifier = Modifier.size(16.dp),
                            tint = TextLight
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Username
            Text(
                text = profile?.username ?: "Loading...",
                color = TextPrimary,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Edit button
            Button(
                onClick = onEditModeToggle,
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (editMode) BrandWarning else BrandPrimary
                ),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.padding(top = 8.dp)
            ) {
                Text(
                    text = if (editMode) "Cancel" else "Edit Profile",
                    color = TextLight,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}

@Composable
fun ProfileCompletionSection(
    completion: ProfileCompletion,
    onEditProfile: () -> Unit
) {
    val animatedProgress by animateFloatAsState(
        targetValue = (completion.completionPercentage / 100.0).toFloat(),
        animationSpec = tween(1000),
        label = "progress"
    )
    
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = 8.dp,
                shape = RoundedCornerShape(16.dp),
                spotColor = CardShadow
            ),
        colors = CardDefaults.cardColors(containerColor = BgCard),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            // Section header with icon
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .background(
                            Brush.radialGradient(
                                colors = listOf(GradientStart, GradientMiddle, GradientEnd),
                                radius = 20f
                            ),
                            shape = RoundedCornerShape(10.dp)
                        )
                        .shadow(
                            elevation = 4.dp,
                            shape = RoundedCornerShape(10.dp),
                            spotColor = ColoredShadow
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Filled.BarChart,
                        contentDescription = "Completion",
                        modifier = Modifier.size(20.dp),
                        tint = TextLight
                    )
                }
                
                Spacer(modifier = Modifier.width(12.dp))
                
                Text(
                    text = "Profile Completion",
                    color = TextPrimary,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.SemiBold
                )
                
                Spacer(modifier = Modifier.weight(1f))
                
                Text(
                    text = "${completion.completionPercentage.toInt()}%",
                    color = when {
                        completion.completionPercentage >= 80 -> BrandSuccess
                        completion.completionPercentage >= 60 -> BrandWarning
                        else -> BrandAccent
                    },
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Divider
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(Divider)
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Main progress bar
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(12.dp)
                    .background(BgSecondary, RoundedCornerShape(6.dp))
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxHeight()
                        .fillMaxWidth(animatedProgress)
                        .background(
                            Brush.horizontalGradient(
                                colors = listOf(
                                    when {
                                        completion.completionPercentage >= 80 -> BrandSuccess.copy(alpha = 0.8f)
                                        completion.completionPercentage >= 60 -> BrandWarning.copy(alpha = 0.8f)
                                        else -> BrandAccent.copy(alpha = 0.8f)
                                    },
                                    when {
                                        completion.completionPercentage >= 80 -> BrandSuccess
                                        completion.completionPercentage >= 60 -> BrandWarning
                                        else -> BrandAccent
                                    }
                                )
                            ),
                            shape = RoundedCornerShape(6.dp)
                        )
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Completion level
            Text(
                text = completion.completionLevel,
                color = TextSecondary,
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium
            )
            
            // Benefits message
            if (completion.completionPercentage < 100) {
                Spacer(modifier = Modifier.height(16.dp))
                
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = BrandWarning.copy(alpha = 0.1f)),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(12.dp)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Filled.Lightbulb,
                                contentDescription = "Benefits",
                                modifier = Modifier.size(16.dp),
                                tint = BrandWarning
                            )
                            
                            Spacer(modifier = Modifier.width(8.dp))
                            
                            Text(
                                text = "Why complete your profile?",
                                color = TextPrimary,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Medium
                            )
                            
                            Spacer(modifier = Modifier.weight(1f))
                            
                            Icon(
                                Icons.Filled.ChevronRight,
                                contentDescription = "More",
                                modifier = Modifier.size(12.dp),
                                tint = BrandWarning.copy(alpha = 0.6f)
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        Text(
                            text = completion.benefitsMessage,
                            color = TextSecondary,
                            fontSize = 12.sp,
                            lineHeight = 16.sp
                        )
                    }
                }
            }
            
            // Missing items
            if (completion.missingItems.isNotEmpty()) {
                Spacer(modifier = Modifier.height(16.dp))
                
                Column {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Filled.Checklist,
                            contentDescription = "Missing",
                            modifier = Modifier.size(16.dp),
                            tint = BrandPrimary
                        )
                        
                        Spacer(modifier = Modifier.width(8.dp))
                        
                        Text(
                            text = "Still missing:",
                            color = TextPrimary,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    completion.missingItems.forEach { item ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { onEditProfile() }
                                .padding(vertical = 4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(4.dp)
                                    .background(BrandPrimary.copy(alpha = 0.6f), CircleShape)
                            )
                            
                            Spacer(modifier = Modifier.width(8.dp))
                            
                            Text(
                                text = item,
                                color = TextSecondary,
                                fontSize = 12.sp
                            )
                            
                            Spacer(modifier = Modifier.weight(1f))
                            
                            Icon(
                                Icons.Filled.ChevronRight,
                                contentDescription = "Edit",
                                modifier = Modifier.size(12.dp),
                                tint = BrandPrimary.copy(alpha = 0.6f)
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun UserInfoSection(
    fullName: String,
    university: String,
    degree: String,
    year: String,
    bio: String,
    editMode: Boolean,
    onFullNameChange: (String) -> Unit,
    onUniversityChange: (String) -> Unit,
    onDegreeChange: (String) -> Unit,
    onYearChange: (String) -> Unit,
    onBioChange: (String) -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = 8.dp,
                shape = RoundedCornerShape(16.dp),
                spotColor = CardShadow
            ),
        colors = CardDefaults.cardColors(containerColor = BgCard),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            Text(
                text = "Personal Information",
                color = TextPrimary,
                fontSize = 18.sp,
                fontWeight = FontWeight.SemiBold
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Form fields
            ProfileFormField(
                label = "Full Name",
                value = fullName,
                onValueChange = onFullNameChange,
                editMode = editMode,
                icon = Icons.Filled.Person
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            ProfileFormField(
                label = "University",
                value = university,
                onValueChange = onUniversityChange,
                editMode = editMode,
                icon = Icons.Filled.School
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            ProfileFormField(
                label = "Degree",
                value = degree,
                onValueChange = onDegreeChange,
                editMode = editMode,
                icon = Icons.Filled.MenuBook
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            ProfileFormField(
                label = "Year",
                value = year,
                onValueChange = onYearChange,
                editMode = editMode,
                icon = Icons.Filled.CalendarToday,
                keyboardType = KeyboardType.Number
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Bio field (multiline)
            Column {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Filled.Description,
                        contentDescription = "Bio",
                        modifier = Modifier.size(20.dp),
                        tint = BrandPrimary
                    )
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    Text(
                        text = "Bio",
                        color = TextPrimary,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Medium
                    )
                }
                
                Spacer(modifier = Modifier.height(8.dp))
                
                if (editMode) {
                    OutlinedTextField(
                        value = bio,
                        onValueChange = onBioChange,
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("Tell us about yourself...", color = TextMuted) },
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = BrandPrimary,
                            unfocusedBorderColor = Divider,
                            focusedTextColor = TextPrimary,
                            unfocusedTextColor = TextPrimary
                        ),
                        shape = RoundedCornerShape(12.dp),
                        maxLines = 4,
                        minLines = 2
                    )
                } else {
                    Text(
                        text = bio.ifEmpty { "No bio provided" },
                        color = if (bio.isEmpty()) TextMuted else TextSecondary,
                        fontSize = 14.sp,
                        lineHeight = 20.sp,
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(
                                BgSecondary,
                                RoundedCornerShape(8.dp)
                            )
                            .padding(12.dp)
                    )
                }
            }
        }
    }
}

@Composable
fun ProfileFormField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    editMode: Boolean,
    icon: ImageVector,
    keyboardType: KeyboardType = KeyboardType.Text
) {
    Row(
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            icon,
            contentDescription = label,
            modifier = Modifier.size(20.dp),
            tint = BrandPrimary
        )
        
        Spacer(modifier = Modifier.width(8.dp))
        
        Text(
            text = label,
            color = TextPrimary,
            fontSize = 16.sp,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.width(100.dp)
        )
        
        Spacer(modifier = Modifier.width(12.dp))
        
        if (editMode) {
            OutlinedTextField(
                value = value,
                onValueChange = onValueChange,
                modifier = Modifier.weight(1f),
                placeholder = { Text("Enter $label", color = TextMuted) },
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = BrandPrimary,
                    unfocusedBorderColor = Divider,
                    focusedTextColor = TextPrimary,
                    unfocusedTextColor = TextPrimary
                ),
                shape = RoundedCornerShape(8.dp),
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = keyboardType)
            )
        } else {
            Text(
                text = value.ifEmpty { "Not provided" },
                color = if (value.isEmpty()) TextMuted else TextSecondary,
                fontSize = 14.sp,
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
fun SkillsSection(
    skills: Map<String, String>,
    editMode: Boolean,
    onSkillsChange: (Map<String, String>) -> Unit
) {
    var editingSkill by remember { mutableStateOf<String?>(null) }
    
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = 8.dp,
                shape = RoundedCornerShape(16.dp),
                spotColor = CardShadow
            ),
        colors = CardDefaults.cardColors(containerColor = BgCard),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            SectionHeader(
                title = "Skills & Expertise",
                icon = Icons.Filled.Star
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Divider
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(Divider)
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            if (skills.isEmpty()) {
                Text(
                    text = "No skills added yet",
                    color = TextMuted,
                    fontSize = 14.sp,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Center
                )
            } else {
                skills.forEach { (skill, level) ->
                    SkillTagWithLevel(
                        skill = skill,
                        level = level,
                        canEdit = editMode,
                        isEditing = editingSkill == skill,
                        onRemove = {
                            val newSkills = skills.toMutableMap()
                            newSkills.remove(skill)
                            onSkillsChange(newSkills)
                        },
                        onEdit = {
                            editingSkill = if (editingSkill == skill) null else skill
                        },
                        onLevelSelected = { newLevel ->
                            val newSkills = skills.toMutableMap()
                            newSkills[skill] = newLevel
                            onSkillsChange(newSkills)
                            editingSkill = null
                        }
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }
            
            if (editMode) {
                Spacer(modifier = Modifier.height(16.dp))
                
                Button(
                    onClick = { /* TODO: Add skill functionality */ },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = BrandPrimary.copy(alpha = 0.1f)
                    ),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Filled.Add,
                            contentDescription = "Add",
                            modifier = Modifier.size(16.dp),
                            tint = BrandPrimary
                        )
                        
                        Spacer(modifier = Modifier.width(8.dp))
                        
                        Text(
                            text = "Add Skill",
                            color = BrandPrimary,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun InterestsSection(
    interests: List<String>,
    editMode: Boolean,
    onInterestsChange: (List<String>) -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = 8.dp,
                shape = RoundedCornerShape(16.dp),
                spotColor = CardShadow
            ),
        colors = CardDefaults.cardColors(containerColor = BgCard),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            SectionHeader(
                title = "Your Interests",
                icon = Icons.Filled.Favorite
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Divider
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(Divider)
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            if (interests.isEmpty()) {
                Text(
                    text = "No interests set",
                    color = TextMuted,
                    fontSize = 14.sp,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Center
                )
            } else {
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(interests) { interest ->
                        SkillTag(
                            skill = interest,
                            canRemove = editMode,
                            onRemove = {
                                val newInterests = interests.toMutableList()
                                newInterests.remove(interest)
                                onInterestsChange(newInterests)
                            }
                        )
                    }
                }
            }
            
            if (editMode) {
                Spacer(modifier = Modifier.height(16.dp))
                
                Button(
                    onClick = { /* TODO: Add interest functionality */ },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = BrandPrimary.copy(alpha = 0.1f)
                    ),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Filled.Add,
                            contentDescription = "Add",
                            modifier = Modifier.size(16.dp),
                            tint = BrandPrimary
                        )
                        
                        Spacer(modifier = Modifier.width(8.dp))
                        
                        Text(
                            text = "Add Interest",
                            color = BrandPrimary,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun AutoMatchingSection(
    profile: UserProfile?,
    editMode: Boolean
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = 8.dp,
                shape = RoundedCornerShape(16.dp),
                spotColor = CardShadow
            ),
        colors = CardDefaults.cardColors(containerColor = BgCard),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            SectionHeader(
                title = "Auto-Matching",
                icon = Icons.Filled.Group
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Divider
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(Divider)
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Enable Auto-Matching",
                    color = TextPrimary,
                    fontSize = 14.sp
                )
                
                EnhancedToggle(
                    checked = profile?.autoInviteEnabled ?: true,
                    onCheckedChange = { /* TODO: Update preference */ }
                )
            }
            
            if (profile?.autoInviteEnabled == true) {
                Spacer(modifier = Modifier.height(16.dp))
                
                Column {
                    Text(
                        text = "Match Distance: ${profile.preferredRadius.toInt()} km",
                        color = TextSecondary,
                        fontSize = 14.sp
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    Slider(
                        value = profile.preferredRadius,
                        onValueChange = { /* TODO: Update radius */ },
                        valueRange = 1f..50f,
                        colors = SliderDefaults.colors(
                            thumbColor = BrandSecondary,
                            activeTrackColor = BrandSecondary,
                            inactiveTrackColor = Divider
                        )
                    )
                }
            }
        }
    }
}

@Composable
fun SaveButton(
    isLoading: Boolean,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = BrandPrimary
        ),
        shape = RoundedCornerShape(16.dp),
        enabled = !isLoading
    ) {
        if (isLoading) {
            CircularProgressIndicator(
                modifier = Modifier.size(20.dp),
                color = TextLight,
                strokeWidth = 2.dp
            )
        } else {
            Text(
                text = "Save Changes",
                color = TextLight,
                fontSize = 16.sp,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

// MARK: - iOS-Style Section Header Component
@Composable
fun SectionHeader(
    title: String,
    icon: ImageVector
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth()
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .background(
                    Brush.radialGradient(
                        colors = listOf(GradientStart, GradientMiddle, GradientEnd),
                        radius = 20f
                    ),
                    shape = RoundedCornerShape(10.dp)
                )
                .shadow(
                    elevation = 4.dp,
                    shape = RoundedCornerShape(10.dp),
                    spotColor = ColoredShadow
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                icon,
                contentDescription = title,
                modifier = Modifier.size(20.dp),
                tint = TextLight
            )
        }
        
        Spacer(modifier = Modifier.width(12.dp))
        
        Text(
            text = title,
            color = TextPrimary,
            fontSize = 18.sp,
            fontWeight = FontWeight.SemiBold
        )
    }
}

// MARK: - iOS-Style Skill Tag Component
@Composable
fun SkillTag(
    skill: String,
    canRemove: Boolean = false,
    onRemove: () -> Unit = {}
) {
    Row(
        modifier = Modifier
            .background(
                BgSecondary,
                RoundedCornerShape(20.dp)
            )
            .border(
                1.dp,
                CardStroke,
                RoundedCornerShape(20.dp)
            )
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = skill,
            color = TextPrimary,
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium
        )
        
        if (canRemove) {
            Spacer(modifier = Modifier.width(8.dp))
            
            IconButton(
                onClick = onRemove,
                modifier = Modifier.size(16.dp)
            ) {
                Icon(
                    Icons.Filled.Close,
                    contentDescription = "Remove",
                    modifier = Modifier.size(12.dp),
                    tint = BrandAccent.copy(alpha = 0.85f)
                )
            }
        }
    }
}

// MARK: - iOS-Style Skill Tag with Level Component
@Composable
fun SkillTagWithLevel(
    skill: String,
    level: String,
    canEdit: Boolean = false,
    isEditing: Boolean = false,
    onRemove: () -> Unit = {},
    onEdit: () -> Unit = {},
    onLevelSelected: (String) -> Unit = {}
) {
    val levels = listOf("BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT")
    
    Column(
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .background(
                    BgSecondary,
                    RoundedCornerShape(20.dp)
                )
                .border(
                    1.dp,
                    CardStroke,
                    RoundedCornerShape(20.dp)
                )
                .padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = skill,
                color = TextPrimary,
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.weight(1f)
            )
            
            if (canEdit) {
                IconButton(
                    onClick = onEdit,
                    modifier = Modifier.size(20.dp)
                ) {
                    Icon(
                        if (isEditing) Icons.Filled.KeyboardArrowUp else Icons.Filled.KeyboardArrowDown,
                        contentDescription = if (isEditing) "Hide" else "Show",
                        modifier = Modifier.size(16.dp),
                        tint = BrandSecondary
                    )
                }
                
                IconButton(
                    onClick = onRemove,
                    modifier = Modifier.size(20.dp)
                ) {
                    Icon(
                        Icons.Filled.Close,
                        contentDescription = "Remove",
                        modifier = Modifier.size(16.dp),
                        tint = BrandAccent.copy(alpha = 0.85f)
                    )
                }
            }
        }
        
        if (isEditing) {
            Spacer(modifier = Modifier.height(8.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                levels.forEach { levelOption ->
                    Button(
                        onClick = { onLevelSelected(levelOption) },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = if (levelOption == level) BrandPrimary else BgSecondary
                        ),
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier.weight(1f)
                    ) {
                        Text(
                            text = levelOption,
                            color = if (levelOption == level) TextLight else TextPrimary,
                            fontSize = 12.sp
                        )
                    }
                }
            }
        }
    }
}

// MARK: - iOS-Style Enhanced Toggle
@Composable
fun EnhancedToggle(
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Spacer(modifier = Modifier.weight(1f))
        
        Box(
            modifier = Modifier
                .size(width = 50.dp, height = 30.dp)
                .then(
                    if (checked) {
                        Modifier.background(
                            Brush.horizontalGradient(
                                colors = listOf(GradientStart, GradientEnd)
                            ),
                            shape = RoundedCornerShape(16.dp)
                        )
                    } else {
                        Modifier.background(
                            BgSecondary,
                            shape = RoundedCornerShape(16.dp)
                        )
                    }
                )
                .clickable { onCheckedChange(!checked) }
                .then(
                    if (checked) {
                        Modifier.shadow(
                            elevation = 4.dp,
                            shape = RoundedCornerShape(16.dp),
                            spotColor = ColoredShadow
                        )
                    } else {
                        Modifier
                    }
                ),
            contentAlignment = Alignment.Center
        ) {
            Box(
                modifier = Modifier
                    .size(24.dp)
                    .background(
                        TextLight,
                        CircleShape
                    )
                    .shadow(
                        elevation = 3.dp,
                        shape = CircleShape,
                        spotColor = CardShadow
                    )
                    .offset(x = if (checked) 10.dp else (-10).dp)
            )
        }
    }
}

// MARK: - Privacy Section
@Composable
fun PrivacySection() {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = 8.dp,
                shape = RoundedCornerShape(16.dp),
                spotColor = CardShadow
            ),
        colors = CardDefaults.cardColors(containerColor = BgCard),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            SectionHeader(
                title = "Privacy Settings",
                icon = Icons.Filled.Security
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Divider
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(Divider)
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Show online status",
                    color = TextPrimary,
                    fontSize = 14.sp
                )
                
                EnhancedToggle(
                    checked = true,
                    onCheckedChange = { /* TODO: Update privacy setting */ }
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Allow direct messages",
                    color = TextPrimary,
                    fontSize = 14.sp
                )
                
                EnhancedToggle(
                    checked = true,
                    onCheckedChange = { /* TODO: Update privacy setting */ }
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Show activity status",
                    color = TextPrimary,
                    fontSize = 14.sp
                )
                
                EnhancedToggle(
                    checked = false,
                    onCheckedChange = { /* TODO: Update privacy setting */ }
                )
            }
        }
    }
}

// MARK: - Reputation Section
@Composable
fun ReputationSection() {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = 8.dp,
                shape = RoundedCornerShape(16.dp),
                spotColor = CardShadow
            ),
        colors = CardDefaults.cardColors(containerColor = BgCard),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            SectionHeader(
                title = "User Reputation",
                icon = Icons.Filled.StarBorder
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Divider
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(Divider)
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Overall Rating",
                    color = TextPrimary,
                    fontSize = 14.sp
                )
                
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "4.8",
                        color = BrandSuccess,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Spacer(modifier = Modifier.width(4.dp))
                    
                    Icon(
                        Icons.Filled.Star,
                        contentDescription = "Rating",
                        modifier = Modifier.size(16.dp),
                        tint = BrandSuccess
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Events Hosted",
                    color = TextSecondary,
                    fontSize = 14.sp
                )
                
                Text(
                    text = "12",
                    color = TextPrimary,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Events Attended",
                    color = TextSecondary,
                    fontSize = 14.sp
                )
                
                Text(
                    text = "28",
                    color = TextPrimary,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}

// MARK: - Connected Accounts Section
@Composable
fun ConnectedAccountsSection() {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = 8.dp,
                shape = RoundedCornerShape(16.dp),
                spotColor = CardShadow
            ),
        colors = CardDefaults.cardColors(containerColor = BgCard),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            SectionHeader(
                title = "Connected Accounts",
                icon = Icons.Filled.Link
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Divider
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(Divider)
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Filled.Email,
                        contentDescription = "Email",
                        modifier = Modifier.size(20.dp),
                        tint = BrandPrimary
                    )
                    
                    Spacer(modifier = Modifier.width(12.dp))
                    
                    Text(
                        text = "Email",
                        color = TextPrimary,
                        fontSize = 14.sp
                    )
                }
                
                Text(
                    text = "Connected",
                    color = BrandSuccess,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Filled.Phone,
                        contentDescription = "Phone",
                        modifier = Modifier.size(20.dp),
                        tint = BrandPrimary
                    )
                    
                    Spacer(modifier = Modifier.width(12.dp))
                    
                    Text(
                        text = "Phone",
                        color = TextPrimary,
                        fontSize = 14.sp
                    )
                }
                
                Text(
                    text = "Not Connected",
                    color = TextMuted,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}

// MARK: - API Action Buttons
@Composable
fun ApiActionButtons(
    onRefreshProfile: () -> Unit,
    onSaveProfile: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = 8.dp,
                shape = RoundedCornerShape(16.dp),
                spotColor = CardShadow
            ),
        colors = CardDefaults.cardColors(containerColor = BgCard),
        shape = RoundedCornerShape(16.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            horizontalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            Button(
                onClick = onRefreshProfile,
                colors = ButtonDefaults.buttonColors(
                    containerColor = BrandSecondary.copy(alpha = 0.1f)
                ),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.weight(1f)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Filled.Refresh,
                        contentDescription = "Refresh",
                        modifier = Modifier.size(16.dp),
                        tint = BrandSecondary
                    )
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    Text(
                        text = "Refresh Profile",
                        color = BrandSecondary,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium
                    )
                }
            }
            
            Button(
                onClick = onSaveProfile,
                colors = ButtonDefaults.buttonColors(
                    containerColor = BrandPrimary.copy(alpha = 0.1f)
                ),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.weight(1f)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Filled.Save,
                        contentDescription = "Save",
                        modifier = Modifier.size(16.dp),
                        tint = BrandPrimary
                    )
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    Text(
                        text = "Save Profile",
                        color = BrandPrimary,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        }
    }
}