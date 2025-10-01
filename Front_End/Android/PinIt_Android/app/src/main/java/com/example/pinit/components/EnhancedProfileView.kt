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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.pinit.models.UserAccountManager
import com.example.pinit.ui.theme.CustomIcons
import com.example.pinit.ui.theme.PrimaryColor
import com.example.pinit.ui.theme.SecondaryColor
import com.example.pinit.viewmodels.ProfileViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EnhancedProfileView(
    accountManager: UserAccountManager,
    onDismiss: () -> Unit,
    onLogout: () -> Unit,
    forceRefresh: Boolean = false,
    viewModel: ProfileViewModel = androidx.lifecycle.viewmodel.compose.viewModel(
        factory = ProfileViewModelFactory(accountManager)
    )
) {
    val isLoading by viewModel.isLoading
    val isSaving by viewModel.isSaving
    val errorMessage by viewModel.errorMessage
    val saveErrorMessage by viewModel.saveErrorMessage
    val profile by viewModel.profile
    val profileCompletion by viewModel.profileCompletion
    
    // Force refresh user data if requested
    LaunchedEffect(forceRefresh, accountManager.currentUser) {
        viewModel.refreshUserData()
        viewModel.fetchProfileCompletion()
    }
    
    // State for new interest input
    var newInterest by remember { mutableStateOf("") }
    
    // State for new skill input
    var newSkill by remember { mutableStateOf("") }
    var newSkillLevel by remember { mutableStateOf(viewModel.skillLevels.first()) }
    
    // Check for unsaved changes
    val hasUnsavedChanges = viewModel.hasUnsavedChanges()
    
    // Dialog control
    var showUnsavedChangesDialog by remember { mutableStateOf(false) }
    
    // Confirmation dialog for unsaved changes
    if (showUnsavedChangesDialog) {
        AlertDialog(
            onDismissRequest = { showUnsavedChangesDialog = false },
            title = { Text("Unsaved Changes") },
            text = { Text("You have unsaved changes. Do you want to save them before leaving?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.saveProfile()
                        showUnsavedChangesDialog = false
                        onDismiss()
                    }
                ) {
                    Text("Save")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        viewModel.discardChanges()
                        showUnsavedChangesDialog = false
                        onDismiss()
                    }
                ) {
                    Text("Discard")
                }
            }
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
                .clip(RoundedCornerShape(16.dp)),
            elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(24.dp)
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Title with close button
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Your Profile",
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        color = PrimaryColor
                    )
                    
                    // Show save indicator if there are unsaved changes
                    if (hasUnsavedChanges) {
                        Text(
                            text = "Unsaved changes",
                            color = MaterialTheme.colorScheme.error,
                            fontSize = 12.sp,
                            modifier = Modifier.padding(horizontal = 8.dp)
                        )
                    }
                    
                    IconButton(
                        onClick = { 
                            if (hasUnsavedChanges) {
                                showUnsavedChangesDialog = true
                            } else {
                                onDismiss()
                            }
                        }
                    ) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "Close"
                        )
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Loading indicator
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(50.dp),
                        color = PrimaryColor
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text("Loading profile information...")
                } else if (profile != null) {
                    // Profile picture
                    Box(
                        modifier = Modifier
                            .size(100.dp)
                            .clip(CircleShape)
                            .background(PrimaryColor.copy(alpha = 0.1f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Person,
                            contentDescription = "Profile Picture",
                            modifier = Modifier.size(50.dp),
                            tint = PrimaryColor
                        )
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Username
                    Text(
                        text = profile?.username ?: accountManager.currentUser ?: "Guest",
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Bold
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    // Certification badge if certified
                    if (profile?.isCertified == true || accountManager.isCertified) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Badge(
                                containerColor = SecondaryColor
                            ) {
                                Text(
                                    text = "Certified",
                                    modifier = Modifier.padding(horizontal = 8.dp),
                                    color = Color.White
                                )
                            }
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // Error messages
                    if (errorMessage != null) {
                        Text(
                            text = errorMessage ?: "",
                            color = MaterialTheme.colorScheme.error,
                            textAlign = TextAlign.Center
                        )
                    }
                    
                    if (saveErrorMessage != null) {
                        Text(
                            text = saveErrorMessage ?: "",
                            color = MaterialTheme.colorScheme.error,
                            textAlign = TextAlign.Center
                        )
                    }
                    
                    // Profile completion section
                    profileCompletion?.let { completion ->
                        ProfileCompletionSection(completion = completion)
                        Spacer(modifier = Modifier.height(24.dp))
                    }
                    
                    // Basic Information Section
                    BasicInfoSection(viewModel = viewModel)
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // SECTION: Interests
                    SectionHeader(
                        title = "Interests",
                        iconVector = CustomIcons.Interests
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    // Interests tags
                    LazyRow(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(viewModel.editableInterests) { interest ->
                            InterestChip(
                                interest = interest,
                                onRemove = { viewModel.removeInterest(interest) }
                            )
                        }
                    }
                    
                    // Add interest input
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        OutlinedTextField(
                            value = newInterest,
                            onValueChange = { newInterest = it },
                            label = { Text("Add interest") },
                            modifier = Modifier.weight(1f),
                            singleLine = true
                        )
                        
                        IconButton(
                            onClick = {
                                if (newInterest.isNotBlank()) {
                                    viewModel.addInterest(newInterest)
                                    newInterest = ""
                                }
                            }
                        ) {
                            Icon(
                                imageVector = Icons.Default.Add,
                                contentDescription = "Add interest"
                            )
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // SECTION: Skills
                    SectionHeader(
                        title = "Skills",
                        iconVector = CustomIcons.Psychology
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    // Skills list
                    Column(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        viewModel.editableSkills.forEach { (skill, level) ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = skill,
                                    modifier = Modifier.weight(1f)
                                )
                                
                                // Skill level chip
                                SkillLevelChip(level = level)
                                
                                IconButton(
                                    onClick = { viewModel.removeSkill(skill) }
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Delete,
                                        contentDescription = "Remove skill",
                                        tint = MaterialTheme.colorScheme.error
                                    )
                                }
                            }
                        }
                    }
                    
                    // Add skill input
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        OutlinedTextField(
                            value = newSkill,
                            onValueChange = { newSkill = it },
                            label = { Text("Add skill") },
                            modifier = Modifier.weight(1f),
                            singleLine = true
                        )
                        
                        // Skill level dropdown
                        Box {
                            var expanded by remember { mutableStateOf(false) }
                            
                            Button(
                                onClick = { expanded = true },
                                modifier = Modifier.padding(horizontal = 8.dp)
                            ) {
                                Text(newSkillLevel)
                            }
                            
                            DropdownMenu(
                                expanded = expanded,
                                onDismissRequest = { expanded = false }
                            ) {
                                viewModel.skillLevels.forEach { level ->
                                    DropdownMenuItem(
                                        text = { Text(level) },
                                        onClick = {
                                            newSkillLevel = level
                                            expanded = false
                                        }
                                    )
                                }
                            }
                        }
                        
                        IconButton(
                            onClick = {
                                if (newSkill.isNotBlank()) {
                                    viewModel.addOrUpdateSkill(newSkill, newSkillLevel)
                                    newSkill = ""
                                }
                            }
                        ) {
                            Icon(
                                imageVector = Icons.Default.Add,
                                contentDescription = "Add skill"
                            )
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // SECTION: Preferences
                    SectionHeader(
                        title = "Preferences",
                        iconVector = Icons.Default.Settings
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    // Auto-invite switch
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Receive automatic event invitations",
                            modifier = Modifier.weight(1f)
                        )
                        
                        Switch(
                            checked = viewModel.autoInviteEnabled.value,
                            onCheckedChange = { viewModel.setAutoInviteEnabled(it) }
                        )
                    }
                    
                    // Preferred radius slider
                    Text(
                        text = "Preferred search radius: ${viewModel.preferredRadius.value.toInt()} km",
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 16.dp)
                    )
                    
                    Slider(
                        value = viewModel.preferredRadius.value,
                        onValueChange = { viewModel.setPreferredRadius(it) },
                        valueRange = 1f..50f,
                        steps = 49,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp)
                    )
                    
                    Spacer(modifier = Modifier.height(32.dp))
                    
                    // Action buttons
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        // Save button
                        Button(
                            onClick = { viewModel.saveProfile() },
                            enabled = hasUnsavedChanges && !isSaving,
                            modifier = Modifier.weight(1f),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = PrimaryColor
                            )
                        ) {
                            if (isSaving) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(24.dp),
                                    color = Color.White,
                                    strokeWidth = 2.dp
                                )
                            } else {
                                Icon(
                                    imageVector = Icons.Default.Save,
                                    contentDescription = "Save"
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Save Changes")
                            }
                        }
                        
                        Spacer(modifier = Modifier.width(16.dp))
                        
                        // Discard button
                        OutlinedButton(
                            onClick = { viewModel.discardChanges() },
                            enabled = hasUnsavedChanges && !isSaving,
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Undo,
                                contentDescription = "Discard"
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Discard")
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(24.dp))

                    // Logout button
                    Button(
                        onClick = onLogout,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.error
                        ),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(
                            imageVector = Icons.Default.Logout,
                            contentDescription = "Logout"
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Logout")
                    }
                }
            }
        }
    }
}

@Composable
fun ProfileCompletionSection(completion: com.example.pinit.models.ProfileCompletion) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = PrimaryColor.copy(alpha = 0.1f)
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Profile Completion",
                    fontWeight = FontWeight.Bold,
                    fontSize = 18.sp,
                    color = PrimaryColor
                )
                
                Text(
                    text = "${completion.completionPercentage.toInt()}%",
                    fontWeight = FontWeight.Bold,
                    fontSize = 18.sp,
                    color = PrimaryColor
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Progress bar
            LinearProgressIndicator(
                progress = { (completion.completionPercentage / 100.0).toFloat() },
                modifier = Modifier.fillMaxWidth(),
                color = PrimaryColor
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = completion.completionLevel,
                fontSize = 14.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            if (completion.benefitsMessage.isNotEmpty()) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = completion.benefitsMessage,
                    fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            if (completion.missingItems.isNotEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Missing: ${completion.missingItems.joinToString(", ")}",
                    fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.error
                )
            }
        }
    }
}

@Composable
fun BasicInfoSection(viewModel: ProfileViewModel) {
    SectionHeader(
        title = "Basic Information",
        iconVector = Icons.Default.Person
    )
    
    Spacer(modifier = Modifier.height(8.dp))
    
    // Full Name
    OutlinedTextField(
        value = viewModel.fullName.value,
        onValueChange = { viewModel.fullName.value = it },
        label = { Text("Full Name") },
        modifier = Modifier.fillMaxWidth(),
        singleLine = true
    )
    
    Spacer(modifier = Modifier.height(8.dp))
    
    // University dropdown
    var universityExpanded by remember { mutableStateOf(false) }
    OutlinedTextField(
        value = viewModel.university.value,
        onValueChange = { viewModel.university.value = it },
        label = { Text("University") },
        modifier = Modifier
            .fillMaxWidth()
            .clickable { universityExpanded = true },
        readOnly = true,
        trailingIcon = {
            Icon(Icons.Default.ArrowDropDown, contentDescription = "Dropdown")
        }
    )
    
    DropdownMenu(
        expanded = universityExpanded,
        onDismissRequest = { universityExpanded = false }
    ) {
        viewModel.suggestedUniversities.forEach { university ->
            DropdownMenuItem(
                text = { Text(university) },
                onClick = {
                    viewModel.university.value = university
                    universityExpanded = false
                }
            )
        }
    }
    
    Spacer(modifier = Modifier.height(8.dp))
    
    // Degree dropdown
    var degreeExpanded by remember { mutableStateOf(false) }
    OutlinedTextField(
        value = viewModel.degree.value,
        onValueChange = { viewModel.degree.value = it },
        label = { Text("Degree") },
        modifier = Modifier
            .fillMaxWidth()
            .clickable { degreeExpanded = true },
        readOnly = true,
        trailingIcon = {
            Icon(Icons.Default.ArrowDropDown, contentDescription = "Dropdown")
        }
    )
    
    DropdownMenu(
        expanded = degreeExpanded,
        onDismissRequest = { degreeExpanded = false }
    ) {
        viewModel.suggestedDegrees.forEach { degree ->
            DropdownMenuItem(
                text = { Text(degree) },
                onClick = {
                    viewModel.degree.value = degree
                    degreeExpanded = false
                }
            )
        }
    }
    
    Spacer(modifier = Modifier.height(8.dp))
    
    // Year dropdown
    var yearExpanded by remember { mutableStateOf(false) }
    OutlinedTextField(
        value = viewModel.year.value,
        onValueChange = { viewModel.year.value = it },
        label = { Text("Academic Year") },
        modifier = Modifier
            .fillMaxWidth()
            .clickable { yearExpanded = true },
        readOnly = true,
        trailingIcon = {
            Icon(Icons.Default.ArrowDropDown, contentDescription = "Dropdown")
        }
    )
    
    DropdownMenu(
        expanded = yearExpanded,
        onDismissRequest = { yearExpanded = false }
    ) {
        viewModel.suggestedYears.forEach { year ->
            DropdownMenuItem(
                text = { Text(year) },
                onClick = {
                    viewModel.year.value = year
                    yearExpanded = false
                }
            )
        }
    }
    
    Spacer(modifier = Modifier.height(8.dp))
    
    // Bio
    OutlinedTextField(
        value = viewModel.bio.value,
        onValueChange = { viewModel.bio.value = it },
        label = { Text("Bio") },
        modifier = Modifier
            .fillMaxWidth()
            .height(100.dp),
        maxLines = 4
    )
}
