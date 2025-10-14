package com.example.pinit.viewmodels

import android.content.Context
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.pinit.models.*
import com.example.pinit.repository.ImageRepository
import com.example.pinit.repository.ReputationRepository
import com.example.pinit.repository.EnhancedProfileRepository
import com.example.pinit.network.ApiClient
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * ViewModel for enhanced profile management
 */
class EnhancedProfileViewModel : ViewModel() {
    private val imageRepository = ImageRepository()
    private val reputationRepository = ReputationRepository()
    private val profileRepository = EnhancedProfileRepository(ApiClient.apiService)
    
    // User images state
    private val _userImages = MutableStateFlow<Result<List<UserImage>>>(Result.Idle)
    val userImages: StateFlow<Result<List<UserImage>>> = _userImages.asStateFlow()
    
    // Image upload state
    private val _imageUpload = MutableStateFlow<Result<UploadImageResponse>>(Result.Idle)
    val imageUpload: StateFlow<Result<UploadImageResponse>> = _imageUpload.asStateFlow()
    
    // Image deletion state
    private val _imageDeletion = MutableStateFlow<Result<Boolean>>(Result.Idle)
    val imageDeletion: StateFlow<Result<Boolean>> = _imageDeletion.asStateFlow()
    
    // Set primary image state
    private val _setPrimary = MutableStateFlow<Result<Boolean>>(Result.Idle)
    val setPrimary: StateFlow<Result<Boolean>> = _setPrimary.asStateFlow()
    
    // User reputation state
    private val _userReputation = MutableStateFlow<Result<UserReputationResponse>>(Result.Idle)
    val userReputation: StateFlow<Result<UserReputationResponse>> = _userReputation.asStateFlow()
    
    // User ratings state
    private val _userRatings = MutableStateFlow<Result<UserRatingsResponse>>(Result.Idle)
    val userRatings: StateFlow<Result<UserRatingsResponse>> = _userRatings.asStateFlow()
    
    // Profile completion state
    private val _profileCompletion = MutableStateFlow<Result<ProfileCompletion>>(Result.Idle)
    val profileCompletion: StateFlow<Result<ProfileCompletion>> = _profileCompletion.asStateFlow()
    
    /**
     * Load user images
     */
    fun loadUserImages(username: String) {
        viewModelScope.launch {
            imageRepository.getUserImages(username).collect { result ->
                _userImages.value = result
            }
        }
    }
    
    /**
     * Upload an image
     */
    fun uploadImage(
        context: Context,
        imageUri: Uri,
        imageType: ImageType,
        caption: String? = null
    ) {
        viewModelScope.launch {
            imageRepository.uploadImage(context, imageUri, imageType, caption).collect { result ->
                _imageUpload.value = result
            }
        }
    }
    
    /**
     * Delete an image
     */
    fun deleteImage(imageId: String) {
        viewModelScope.launch {
            imageRepository.deleteImage(imageId).collect { result ->
                _imageDeletion.value = result
            }
        }
    }
    
    /**
     * Set image as primary
     */
    fun setPrimaryImage(imageId: String) {
        viewModelScope.launch {
            imageRepository.setPrimaryImage(imageId).collect { result ->
                _setPrimary.value = result
            }
        }
    }
    
    /**
     * Load user reputation
     */
    fun loadUserReputation(username: String) {
        viewModelScope.launch {
            reputationRepository.getUserReputation(username).collect { result ->
                _userReputation.value = result
            }
        }
    }
    
    /**
     * Load user ratings
     */
    fun loadUserRatings(username: String) {
        viewModelScope.launch {
            reputationRepository.getUserRatings(username).collect { result ->
                _userRatings.value = result
            }
        }
    }
    
    /**
     * Load profile completion
     */
    fun loadProfileCompletion(username: String) {
        viewModelScope.launch {
            profileRepository.getProfileCompletion(username).collect { result ->
                _profileCompletion.value = result
            }
        }
    }
    
    /**
     * Reset image upload state
     */
    fun resetImageUpload() {
        _imageUpload.value = Result.Idle
    }
    
    /**
     * Reset image deletion state
     */
    fun resetImageDeletion() {
        _imageDeletion.value = Result.Idle
    }
    
    /**
     * Reset set primary state
     */
    fun resetSetPrimary() {
        _setPrimary.value = Result.Idle
    }
    
    /**
     * Get profile image URL
     */
    fun getProfileImageUrl(images: List<UserImage>): String? {
        return imageRepository.getProfileImageUrl(images)
    }
    
    /**
     * Get gallery images
     */
    fun getGalleryImages(images: List<UserImage>): List<UserImage> {
        return imageRepository.getGalleryImages(images)
    }
    
    /**
     * Calculate trust level progress
     */
    fun calculateTrustLevelProgress(reputation: UserReputation): Int {
        return reputationRepository.calculateTrustLevelProgress(reputation)
    }
}

