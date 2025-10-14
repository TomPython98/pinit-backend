package com.example.pinit.repository

import android.util.Log
import com.example.pinit.models.*
import com.example.pinit.network.ApiClient
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn

/**
 * Repository for user reputation and ratings
 */
class ReputationRepository {
    private val TAG = "ReputationRepository"
    private val apiService = ApiClient.apiService
    
    /**
     * Get user reputation statistics
     */
    fun getUserReputation(username: String): Flow<Result<UserReputationResponse>> = flow {
        emit(Result.Loading)
        try {
            Log.d(TAG, "Fetching reputation for user: $username")
            val response = apiService.getUserReputation(username)
            
            if (response.isSuccessful && response.body() != null) {
                val reputation = response.body()!!
                Log.d(TAG, "Successfully fetched reputation: $reputation")
                emit(Result.Success(reputation))
            } else {
                val error = response.errorBody()?.string() ?: "Unknown error"
                Log.e(TAG, "Failed to fetch reputation: $error")
                emit(Result.Error(Exception(error), error))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception fetching reputation", e)
            emit(Result.Error(e, e.message))
        }
    }.flowOn(Dispatchers.IO)
    
    /**
     * Get detailed user ratings (given and received)
     */
    fun getUserRatings(username: String): Flow<Result<UserRatingsResponse>> = flow {
        emit(Result.Loading)
        try {
            Log.d(TAG, "Fetching ratings for user: $username")
            val response = apiService.getUserRatingsDetailed(username)
            
            if (response.isSuccessful && response.body() != null) {
                val ratings = response.body()!!
                Log.d(TAG, "Successfully fetched ratings: ${ratings.ratings_received?.size ?: 0} received, ${ratings.ratings_given?.size ?: 0} given")
                emit(Result.Success(ratings))
            } else {
                val error = response.errorBody()?.string() ?: "Unknown error"
                Log.e(TAG, "Failed to fetch ratings: $error")
                emit(Result.Error(Exception(error), error))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception fetching ratings", e)
            emit(Result.Error(e, e.message))
        }
    }.flowOn(Dispatchers.IO)
    
    /**
     * Submit a user rating
     */
    fun submitRating(
        fromUsername: String,
        toUsername: String,
        rating: Int,
        reference: String,
        eventId: String? = null
    ): Flow<Result<SubmitRatingResponse>> = flow {
        emit(Result.Loading)
        try {
            Log.d(TAG, "Submitting rating from $fromUsername to $toUsername: $rating stars")
            
            val request = SubmitRatingRequest(
                from_username = fromUsername,
                to_username = toUsername,
                rating = rating,
                reference = reference,
                event_id = eventId
            )
            
            val response = apiService.submitRating(request)
            
            if (response.isSuccessful && response.body() != null) {
                val result = response.body()!!
                if (result.success) {
                    Log.d(TAG, "Successfully submitted rating")
                    emit(Result.Success(result))
                } else {
                    val error = result.message ?: "Failed to submit rating"
                    Log.e(TAG, "Rating submission failed: $error")
                    emit(Result.Error(Exception(error), error))
                }
            } else {
                val error = response.errorBody()?.string() ?: "Unknown error"
                Log.e(TAG, "Failed to submit rating: $error")
                emit(Result.Error(Exception(error), error))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception submitting rating", e)
            emit(Result.Error(e, e.message))
        }
    }.flowOn(Dispatchers.IO)
    
    /**
     * Calculate trust level progress percentage
     */
    fun calculateTrustLevelProgress(reputation: UserReputation): Int {
        val currentLevel = reputation.trust_level.level
        val nextLevel = currentLevel + 1
        
        // If already at max level
        if (currentLevel >= 5) return 100
        
        // Calculate progress based on ratings count
        // These are rough estimates, adjust based on your trust level requirements
        val requiredRatings = when (nextLevel) {
            2 -> 5    // Newcomer -> Participant
            3 -> 15   // Participant -> Trusted Member
            4 -> 30   // Trusted Member -> Event Expert
            5 -> 50   // Event Expert -> Community Leader
            else -> Int.MAX_VALUE
        }
        
        val progress = (reputation.total_ratings.toFloat() / requiredRatings * 100).toInt()
        return minOf(progress, 100)
    }
    
    /**
     * Get trust level color
     */
    fun getTrustLevelColor(level: Int): androidx.compose.ui.graphics.Color {
        return when (level) {
            1 -> androidx.compose.ui.graphics.Color(0xFF9E9E9E) // Gray
            2 -> androidx.compose.ui.graphics.Color(0xFF2196F3) // Blue
            3 -> androidx.compose.ui.graphics.Color(0xFF4CAF50) // Green
            4 -> androidx.compose.ui.graphics.Color(0xFFFF9800) // Orange
            5 -> androidx.compose.ui.graphics.Color(0xFFFFC107) // Gold
            else -> androidx.compose.ui.graphics.Color(0xFF9E9E9E)
        }
    }
    
    /**
     * Get trust level icon name
     */
    fun getTrustLevelIcon(level: Int): String {
        return when (level) {
            1 -> "person_outline"
            2 -> "person"
            3 -> "verified_user"
            4 -> "stars"
            5 -> "emoji_events"
            else -> "person_outline"
        }
    }
}

