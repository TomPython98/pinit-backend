package com.example.pinit.repository

import com.example.pinit.network.ApiService
import com.example.pinit.models.UserReputationResponse
import com.example.pinit.models.UserRatingsResponse
import com.example.pinit.models.FriendsResponse
import com.example.pinit.models.EventFeedResponse
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import android.util.Log

/**
 * Repository for enhanced user profile features including reputation, ratings, and social interactions
 */
class EnhancedProfileRepository(
    private val apiService: ApiService
) {
    companion object {
        private const val TAG = "EnhancedProfileRepository"
    }

    /**
     * Get user reputation statistics
     */
    fun getUserReputation(username: String): Flow<Result<UserReputationResponse>> = flow {
        try {
            Log.d(TAG, "Fetching reputation for user: $username")
            
            val response = apiService.getUserReputation(username)
            
            if (response.isSuccessful) {
                val reputation = response.body()
                if (reputation != null) {
                    Log.d(TAG, "✅ Successfully fetched reputation for $username: ${reputation.average_rating} stars")
                    emit(Result.success(reputation))
                } else {
                    Log.e(TAG, "❌ Reputation response body was null")
                    emit(Result.failure(Exception("Reputation response body was null")))
                }
            } else {
                val errorBody = response.errorBody()?.string()
                Log.e(TAG, "❌ API Error: ${response.code()} - $errorBody")
                emit(Result.failure(Exception("API Error: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception fetching reputation: ${e.message}")
            emit(Result.failure(e))
        }
    }

    /**
     * Get user ratings (both given and received)
     */
    fun getUserRatings(username: String): Flow<Result<UserRatingsResponse>> = flow {
        try {
            Log.d(TAG, "Fetching ratings for user: $username")
            
            val response = apiService.getUserRatings(username)
            
            if (response.isSuccessful) {
                val ratings = response.body()
                if (ratings != null) {
                    Log.d(TAG, "✅ Successfully fetched ratings for $username: ${ratings.total_received} received, ${ratings.total_given} given")
                    emit(Result.success(ratings))
                } else {
                    Log.e(TAG, "❌ Ratings response body was null")
                    emit(Result.failure(Exception("Ratings response body was null")))
                }
            } else {
                val errorBody = response.errorBody()?.string()
                Log.e(TAG, "❌ API Error: ${response.code()} - $errorBody")
                emit(Result.failure(Exception("API Error: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception fetching ratings: ${e.message}")
            emit(Result.failure(e))
        }
    }

    /**
     * Get user's friends list
     */
    fun getFriends(username: String): Flow<Result<List<String>>> = flow {
        try {
            Log.d(TAG, "Fetching friends for user: $username")
            
            val response = apiService.getFriends(username)
            
            if (response.isSuccessful) {
                val friendsResponse = response.body()
                if (friendsResponse != null) {
                    Log.d(TAG, "✅ Successfully fetched friends for $username: ${friendsResponse.friends.size} friends")
                    emit(Result.success(friendsResponse.friends))
                } else {
                    Log.e(TAG, "❌ Friends response body was null")
                    emit(Result.failure(Exception("Friends response body was null")))
                }
            } else {
                val errorBody = response.errorBody()?.string()
                Log.e(TAG, "❌ API Error: ${response.code()} - $errorBody")
                emit(Result.failure(Exception("API Error: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception fetching friends: ${e.message}")
            emit(Result.failure(e))
        }
    }

    /**
     * Get event social feed/interactions
     */
    fun getEventFeed(eventId: String, currentUser: String): Flow<Result<EventFeedResponse>> = flow {
        try {
            Log.d(TAG, "Fetching event feed for event: $eventId")
            
            val response = apiService.getEventFeed(eventId, currentUser)
            
            if (response.isSuccessful) {
                val feed = response.body()
                if (feed != null) {
                    Log.d(TAG, "✅ Successfully fetched event feed: ${feed.posts.size} posts, ${feed.likes.size} likes")
                    emit(Result.success(feed))
                } else {
                    Log.e(TAG, "❌ Event feed response body was null")
                    emit(Result.failure(Exception("Event feed response body was null")))
                }
            } else {
                val errorBody = response.errorBody()?.string()
                Log.e(TAG, "❌ API Error: ${response.code()} - $errorBody")
                emit(Result.failure(Exception("API Error: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception fetching event feed: ${e.message}")
            emit(Result.failure(e))
        }
    }

    /**
     * Submit a user rating
     */
    suspend fun submitUserRating(
        fromUser: String,
        toUser: String,
        rating: Int,
        reference: String,
        eventId: String?
    ): Result<Map<String, Any>> {
        return try {
            Log.d(TAG, "Submitting rating: $fromUser -> $toUser ($rating stars)")
            
            val requestBody = mapOf(
                "from_user" to fromUser,
                "to_user" to toUser,
                "rating" to rating,
                "reference" to reference,
                "event_id" to (eventId ?: "")
            )
            
            val response = apiService.submitUserRating(requestBody)
            
            if (response.isSuccessful) {
                val result = response.body()
                Log.d(TAG, "✅ Successfully submitted rating")
                Result.success(result ?: emptyMap())
            } else {
                val errorBody = response.errorBody()?.string()
                Log.e(TAG, "❌ API Error: ${response.code()} - $errorBody")
                Result.failure(Exception("API Error: ${response.code()}"))
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception submitting rating: ${e.message}")
            Result.failure(e)
        }
    }

    /**
     * Send friend request
     */
    suspend fun sendFriendRequest(fromUser: String, toUser: String): Result<Map<String, Any>> {
        return try {
            Log.d(TAG, "Sending friend request: $fromUser -> $toUser")
            
            val requestBody = mapOf(
                "from_user" to fromUser,
                "to_user" to toUser
            )
            
            val response = apiService.sendFriendRequest(requestBody)
            
            if (response.isSuccessful) {
                val result = response.body()
                Log.d(TAG, "✅ Successfully sent friend request")
                Result.success(result ?: emptyMap())
            } else {
                val errorBody = response.errorBody()?.string()
                Log.e(TAG, "❌ API Error: ${response.code()} - $errorBody")
                Result.failure(Exception("API Error: ${response.code()}"))
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception sending friend request: ${e.message}")
            Result.failure(e)
        }
    }

    /**
     * Accept friend request
     */
    suspend fun acceptFriendRequest(fromUser: String, toUser: String): Result<Map<String, Any>> {
        return try {
            Log.d(TAG, "Accepting friend request: $fromUser -> $toUser")
            
            val requestBody = mapOf(
                "from_user" to fromUser,
                "to_user" to toUser
            )
            
            val response = apiService.acceptFriendRequest(requestBody)
            
            if (response.isSuccessful) {
                val result = response.body()
                Log.d(TAG, "✅ Successfully accepted friend request")
                Result.success(result ?: emptyMap())
            } else {
                val errorBody = response.errorBody()?.string()
                Log.e(TAG, "❌ API Error: ${response.code()} - $errorBody")
                Result.failure(Exception("API Error: ${response.code()}"))
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception accepting friend request: ${e.message}")
            Result.failure(e)
        }
    }
}

