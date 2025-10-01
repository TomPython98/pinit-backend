package com.example.pinit.viewmodels

import android.util.Log
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.pinit.models.UserAccountManager
import com.example.pinit.models.UserProfile
import com.example.pinit.models.ProfileCompletion
import com.example.pinit.repository.ProfileRepository
import kotlinx.coroutines.launch

/**
 * ViewModel for profile management
 */
class ProfileViewModel(
    private val accountManager: UserAccountManager
) : ViewModel() {
    
    private val TAG = "ProfileViewModel"
    private val repository = ProfileRepository()
    
    // State variables
    val isLoading = mutableStateOf(false)
    val isSaving = mutableStateOf(false)
    val errorMessage = mutableStateOf<String?>(null)
    val saveErrorMessage = mutableStateOf<String?>(null)
    val profile = mutableStateOf<UserProfile?>(null)
    val profileCompletion = mutableStateOf<ProfileCompletion?>(null)
    
    // Current username for comparison
    private var currentUsername: String? = null
    
    // Editable state for interests
    val editableInterests = mutableStateListOf<String>()
    
    // Editable state for skills
    private val _editableSkills = mutableStateOf<MutableMap<String, String>>(mutableMapOf())
    val editableSkills: Map<String, String> get() = _editableSkills.value
    
    // Editable preferences
    val autoInviteEnabled = mutableStateOf(true)
    val preferredRadius = mutableStateOf(10.0f)
    
    // Enhanced profile fields
    val fullName = mutableStateOf("")
    val university = mutableStateOf("")
    val degree = mutableStateOf("")
    val year = mutableStateOf("")
    val bio = mutableStateOf("")
    
    // Skill level options
    val skillLevels = listOf("BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT")
    
    // Suggested values for dropdowns
    val suggestedUniversities = listOf(
        "University of Buenos Aires",
        "National University of La Plata",
        "University of San Andrés",
        "Torcuato Di Tella University",
        "University of Belgrano",
        "University of Palermo",
        "University of Salvador",
        "National University of Córdoba",
        "National University of Rosario",
        "University of San Martín"
    )
    
    val suggestedDegrees = listOf(
        "Computer Science",
        "Software Engineering",
        "Information Systems",
        "Mathematics",
        "Physics",
        "Chemistry",
        "Biology",
        "Medicine",
        "Law",
        "Business Administration",
        "Economics",
        "Psychology",
        "Philosophy",
        "History",
        "Literature",
        "Art",
        "Music",
        "Architecture",
        "Engineering",
        "Education"
    )
    
    val suggestedYears = listOf(
        "1st Year",
        "2nd Year", 
        "3rd Year",
        "4th Year",
        "5th Year",
        "Master's 1st Year",
        "Master's 2nd Year",
        "PhD Student",
        "Graduate"
    )
    
    init {
        Log.d(TAG, "Initializing ProfileViewModel with current user: ${accountManager.currentUser}")
        refreshUserData()
    }
    
    /**
     * Refresh user data when user changes
     * This should be called whenever the current user might have changed
     */
    fun refreshUserData() {
        val username = accountManager.currentUser
        
        Log.d(TAG, "Refreshing user data for: $username (current: $currentUsername)")
        
        // Only reload if username has changed
        if (username != null && username != currentUsername) {
            currentUsername = username
            
            // Clear any existing data
            profile.value = null
            editableInterests.clear()
            _editableSkills.value.clear()
            
            // Load fresh profile
            loadProfile()
        }
    }
    
    /**
     * Load profile data from the backend
     */
    private fun loadProfile() {
        val username = accountManager.currentUser ?: return
        
        isLoading.value = true
        errorMessage.value = null
        
        Log.d(TAG, "Loading profile from backend for: $username")
        
        viewModelScope.launch {
            try {
                repository.getUserProfile(username).collect { result ->
                    result.fold(
                        onSuccess = { userProfile ->
                            Log.d(TAG, "✅ Successfully loaded profile from backend for: $username")
                            Log.d(TAG, "  Interests: ${userProfile.interests}")
                            Log.d(TAG, "  Skills: ${userProfile.skills}")
                            
                            profile.value = userProfile
                            
                            // Initialize editable collections
                            editableInterests.clear()
                            editableInterests.addAll(userProfile.interests)
                            
                            _editableSkills.value = userProfile.skills.toMutableMap()
                            
                            autoInviteEnabled.value = userProfile.autoInviteEnabled
                            preferredRadius.value = userProfile.preferredRadius
                            
                            // Initialize enhanced profile fields
                            fullName.value = userProfile.fullName
                            university.value = userProfile.university
                            degree.value = userProfile.degree
                            year.value = userProfile.year
                            bio.value = userProfile.bio
                            
                            isLoading.value = false
                        },
                        onFailure = { error ->
                            Log.e(TAG, "❌ Error loading profile from backend", error)
                            
                            // Fallback to local profile data
                            val fallbackProfile = UserProfile(
                                username = username,
                                isCertified = accountManager.isCertified,
                                interests = emptyList(),
                                skills = emptyMap(),
                                autoInviteEnabled = true,
                                preferredRadius = 10.0f
                            )
                            
                            profile.value = fallbackProfile
                            
                            // Initialize editable collections with fallback data
                            editableInterests.clear()
                            _editableSkills.value.clear()
                            
                            autoInviteEnabled.value = true
                            preferredRadius.value = 10.0f
                            
                            isLoading.value = false
                            errorMessage.value = "Failed to load profile from server: ${error.message}"
                        }
                    )
                }
            } catch (e: Exception) {
                isLoading.value = false
                errorMessage.value = "Failed to load profile: ${e.message}"
                Log.e(TAG, "Exception loading profile", e)
            }
        }
    }
    
    /**
     * Add a new interest to the editable list
     */
    fun addInterest(interest: String) {
        if (interest.isNotBlank() && !editableInterests.contains(interest)) {
            editableInterests.add(interest)
        }
    }
    
    /**
     * Remove an interest from the editable list
     */
    fun removeInterest(interest: String) {
        editableInterests.remove(interest)
    }
    
    /**
     * Add or update a skill in the editable map
     */
    fun addOrUpdateSkill(skill: String, level: String) {
        if (skill.isNotBlank() && level.isNotBlank()) {
            _editableSkills.value[skill] = level
        }
    }
    
    /**
     * Remove a skill from the editable map
     */
    fun removeSkill(skill: String) {
        _editableSkills.value.remove(skill)
    }
    
    /**
     * Update auto invite preference
     */
    fun setAutoInviteEnabled(enabled: Boolean) {
        autoInviteEnabled.value = enabled
    }
    
    /**
     * Update preferred radius
     */
    fun setPreferredRadius(radius: Float) {
        preferredRadius.value = radius
    }
    
    /**
     * Fetch profile completion details
     */
    fun fetchProfileCompletion() {
        val username = accountManager.currentUser ?: return
        
        Log.d(TAG, "Fetching profile completion for: $username")
        
        viewModelScope.launch {
            try {
                repository.getProfileCompletion(username).collect { result ->
                    result.fold(
                        onSuccess = { completion ->
                            Log.d(TAG, "✅ Successfully loaded profile completion")
                            profileCompletion.value = completion
                        },
                        onFailure = { error ->
                            Log.e(TAG, "❌ Error loading profile completion", error)
                        }
                    )
                }
            } catch (e: Exception) {
                Log.e(TAG, "Exception loading profile completion", e)
            }
        }
    }
    
    /**
     * Save profile changes to the backend
     */
    fun saveProfile() {
        val username = accountManager.currentUser ?: return
        
        isSaving.value = true
        saveErrorMessage.value = null
        
        Log.d(TAG, "Saving profile to backend for: $username")
        Log.d(TAG, "  Interests: ${editableInterests.toList()}")
        Log.d(TAG, "  Skills: ${editableSkills}")
        Log.d(TAG, "  Auto-invite: ${autoInviteEnabled.value}")
        Log.d(TAG, "  Preferred radius: ${preferredRadius.value}")
        
        viewModelScope.launch {
            try {
                repository.updateUserInterests(
                    username = username,
                    interests = editableInterests.toList(),
                    skills = editableSkills,
                    autoInviteEnabled = autoInviteEnabled.value,
                    preferredRadius = preferredRadius.value,
                    fullName = fullName.value,
                    university = university.value,
                    degree = degree.value,
                    year = year.value,
                    bio = bio.value
                ).collect { result ->
                    result.fold(
                        onSuccess = {
                            // Update local profile with saved values
                            profile.value = UserProfile(
                                username = username,
                                isCertified = accountManager.isCertified,
                                interests = editableInterests.toList(),
                                skills = editableSkills,
                                autoInviteEnabled = autoInviteEnabled.value,
                                preferredRadius = preferredRadius.value,
                                fullName = fullName.value,
                                university = university.value,
                                degree = degree.value,
                                year = year.value,
                                bio = bio.value
                            )
                            
                            isSaving.value = false
                            Log.d(TAG, "✅ Successfully saved profile to backend")
                        },
                        onFailure = { error ->
                            isSaving.value = false
                            saveErrorMessage.value = "Failed to save profile: ${error.message}"
                            Log.e(TAG, "❌ Error saving profile to backend", error)
                        }
                    )
                }
            } catch (e: Exception) {
                isSaving.value = false
                saveErrorMessage.value = "Failed to save profile: ${e.message}"
                Log.e(TAG, "Exception saving profile", e)
            }
        }
    }
    
    /**
     * Discard changes and reset to the saved profile
     */
    fun discardChanges() {
        profile.value?.let { savedProfile ->
            editableInterests.clear()
            editableInterests.addAll(savedProfile.interests)
            
            _editableSkills.value = savedProfile.skills.toMutableMap()
            
            autoInviteEnabled.value = savedProfile.autoInviteEnabled
            preferredRadius.value = savedProfile.preferredRadius
            
            // Reset enhanced profile fields
            fullName.value = savedProfile.fullName
            university.value = savedProfile.university
            degree.value = savedProfile.degree
            year.value = savedProfile.year
            bio.value = savedProfile.bio
        }
    }
    
    /**
     * Check if there are unsaved changes
     */
    fun hasUnsavedChanges(): Boolean {
        val savedProfile = profile.value ?: return false
        
        val interestsChanged = editableInterests.toSet() != savedProfile.interests.toSet()
        val skillsChanged = editableSkills != savedProfile.skills
        val autoInviteChanged = autoInviteEnabled.value != savedProfile.autoInviteEnabled
        val radiusChanged = preferredRadius.value != savedProfile.preferredRadius
        
        // Check enhanced profile fields
        val fullNameChanged = fullName.value != savedProfile.fullName
        val universityChanged = university.value != savedProfile.university
        val degreeChanged = degree.value != savedProfile.degree
        val yearChanged = year.value != savedProfile.year
        val bioChanged = bio.value != savedProfile.bio
        
        return interestsChanged || skillsChanged || autoInviteChanged || radiusChanged ||
               fullNameChanged || universityChanged || degreeChanged || yearChanged || bioChanged
    }
    
    /**
     * Logout the current user
     */
    fun logout() {
        accountManager.logout()
    }
} 