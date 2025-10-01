package com.example.pinit.repository

import android.util.Log
import com.example.pinit.models.UserProfile
import com.example.pinit.models.ProfileCompletion
import com.example.pinit.network.ApiClient
import com.example.pinit.network.UpdateUserInterestsRequest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn

/**
 * Repository for user profile data
 */
class ProfileRepository {
    private val TAG = "ProfileRepository"
    private val apiService = ApiClient.apiService
    
    /**
     * Get user profile from the backend
     * 
     * @param username The username to fetch profile for
     * @return Flow with Result containing UserProfile
     */
    fun getUserProfile(username: String): Flow<Result<UserProfile>> = flow {
        try {
            Log.d(TAG, "Fetching profile for user: $username")
            
            val response = apiService.getUserProfile(username)
            
            if (response.isSuccessful) {
                val profileResponse = response.body()
                
                if (profileResponse != null) {
                    val userProfile = UserProfile(
                        username = profileResponse.username,
                        isCertified = profileResponse.isCertified,
                        interests = profileResponse.interests,
                        skills = profileResponse.skills,
                        autoInviteEnabled = profileResponse.autoInviteEnabled,
                        preferredRadius = profileResponse.preferredRadius,
                        // Enhanced profile fields
                        fullName = profileResponse.fullName,
                        university = profileResponse.university,
                        degree = profileResponse.degree,
                        year = profileResponse.year,
                        bio = profileResponse.bio
                    )
                    
                    Log.d(TAG, "✅ Successfully fetched profile for user: $username (certified: ${userProfile.isCertified})")
                    Log.d(TAG, "  Interests: ${userProfile.interests}")
                    Log.d(TAG, "  Skills: ${userProfile.skills}")
                    
                    emit(Result.success(userProfile))
                } else {
                    Log.e(TAG, "❌ Profile response body was null")
                    emit(Result.failure(Exception("Profile response body was null")))
                }
            } else {
                val errorBody = response.errorBody()?.string()
                Log.e(TAG, "❌ API Error: ${response.code()} - $errorBody")
                emit(Result.failure(Exception("API Error: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception fetching profile", e)
            emit(Result.failure(e))
        }
    }.flowOn(Dispatchers.IO)
    
    /**
     * Get profile completion details
     * 
     * @param username The username to get completion details for
     * @return Flow with Result containing ProfileCompletion
     */
    fun getProfileCompletion(username: String): Flow<Result<ProfileCompletion>> = flow {
        try {
            Log.d(TAG, "Fetching profile completion for user: $username")
            
            val response = apiService.getProfileCompletion(username)
            
            if (response.isSuccessful) {
                val completionResponse = response.body()
                
                if (completionResponse != null) {
                    val profileCompletion = ProfileCompletion(
                        completionPercentage = completionResponse.completionPercentage,
                        missingItems = completionResponse.missingItems,
                        benefitsMessage = completionResponse.benefitsMessage,
                        completionLevel = completionResponse.completionLevel,
                        categoryBreakdown = completionResponse.categoryBreakdown
                    )
                    
                    Log.d(TAG, "✅ Successfully fetched profile completion for user: $username")
                    Log.d(TAG, "  Completion: ${profileCompletion.completionPercentage}%")
                    Log.d(TAG, "  Missing items: ${profileCompletion.missingItems}")
                    
                    emit(Result.success(profileCompletion))
                } else {
                    Log.e(TAG, "❌ Profile completion response body was null")
                    emit(Result.failure(Exception("Profile completion response body was null")))
                }
            } else {
                val errorBody = response.errorBody()?.string()
                Log.e(TAG, "❌ API Error: ${response.code()} - $errorBody")
                emit(Result.failure(Exception("API Error: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception fetching profile completion", e)
            emit(Result.failure(e))
        }
    }.flowOn(Dispatchers.IO)

    /**
     * Update user interests and preferences
     * 
     * @param username The username to update profile for
     * @param interests List of user interests
     * @param skills Map of skills to proficiency levels
     * @param autoInviteEnabled Whether user wants automatic invites 
     * @param preferredRadius Preferred radius for event matching
     * @param fullName User's full name
     * @param university User's university
     * @param degree User's degree
     * @param year User's academic year
     * @param bio User's bio
     * @return Flow with Result indicating success or failure
     */
    fun updateUserInterests(
        username: String,
        interests: List<String>,
        skills: Map<String, String>,
        autoInviteEnabled: Boolean,
        preferredRadius: Float,
        fullName: String = "",
        university: String = "",
        degree: String = "",
        year: String = "",
        bio: String = ""
    ): Flow<Result<Boolean>> = flow {
        try {
            Log.d(TAG, "Updating profile for user: $username")
            Log.d(TAG, "  Interests: $interests")
            Log.d(TAG, "  Skills: $skills")
            Log.d(TAG, "  Auto-invite: $autoInviteEnabled")
            Log.d(TAG, "  Preferred radius: $preferredRadius")
            
            val request = UpdateUserInterestsRequest(
                username = username,
                interests = interests,
                skills = skills,
                autoInvitePreference = autoInviteEnabled,
                preferredRadius = preferredRadius,
                fullName = fullName,
                university = university,
                degree = degree,
                year = year,
                bio = bio
            )
            
            val response = apiService.updateUserInterests(request)
            
            if (response.isSuccessful) {
                Log.d(TAG, "✅ Successfully updated profile for user: $username")
                emit(Result.success(true))
            } else {
                val errorBody = response.errorBody()?.string()
                Log.e(TAG, "❌ API Error updating profile: ${response.code()} - $errorBody")
                emit(Result.failure(Exception("API Error: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception updating profile", e)
            emit(Result.failure(e))
        }
    }.flowOn(Dispatchers.IO)
} 