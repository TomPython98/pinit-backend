package com.example.pinit.repository

import android.util.Log
import com.example.pinit.models.*
import com.example.pinit.network.ApiClient
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn

/**
 * Repository for event social interactions (comments, likes, shares)
 */
class SocialRepository {
    private val TAG = "SocialRepository"
    private val apiService = ApiClient.apiService
    
    /**
     * Get event feed with all social interactions
     */
    fun getEventFeed(eventId: String, currentUser: String): Flow<Result<EventFeed>> = flow {
        emit(Result.Loading)
        try {
            Log.d(TAG, "Fetching event feed for event: $eventId")
            val response = apiService.getEventFeedDetailed(eventId, currentUser)
            
            if (response.isSuccessful && response.body() != null) {
                val feed = response.body()!!
                Log.d(TAG, "Successfully fetched event feed: ${feed.displayPosts.size} posts, ${feed.likes?.total ?: 0} likes")
                emit(Result.Success(feed))
            } else {
                val error = response.errorBody()?.string() ?: "Unknown error"
                Log.e(TAG, "Failed to fetch event feed: $error")
                emit(Result.Error(Exception(error), error))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception fetching event feed", e)
            emit(Result.Error(e, e.message))
        }
    }.flowOn(Dispatchers.IO)
    
    /**
     * Add a comment to an event
     */
    fun addComment(
        eventId: String,
        username: String,
        text: String,
        parentId: Int? = null,
        imageUrls: List<String>? = null
    ): Flow<Result<EventComment?>> = flow {
        emit(Result.Loading)
        try {
            Log.d(TAG, "Adding comment to event $eventId by $username")
            
            val request = AddCommentRequest(
                event_id = eventId,
                username = username,
                text = text,
                parent_id = parentId,
                image_urls = imageUrls
            )
            
            val response = apiService.addEventComment(request)
            
            if (response.isSuccessful && response.body() != null) {
                val result = response.body()!!
                if (result.success && result.displayPost != null) {
                    Log.d(TAG, "Successfully added comment")
                    emit(Result.Success(result.displayPost))
                } else {
                    val error = result.message ?: "Failed to add comment"
                    Log.e(TAG, "Comment addition failed: $error")
                    emit(Result.Error(Exception(error), error))
                }
            } else {
                val error = response.errorBody()?.string() ?: "Unknown error"
                Log.e(TAG, "Failed to add comment: $error")
                emit(Result.Error(Exception(error), error))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception adding comment", e)
            emit(Result.Error(e, e.message))
        }
    }.flowOn(Dispatchers.IO)
    
    /**
     * Toggle like on an event or comment
     */
    fun toggleLike(
        eventId: String,
        username: String,
        postId: Int? = null
    ): Flow<Result<LikeResponse>> = flow {
        emit(Result.Loading)
        try {
            Log.d(TAG, "Toggling like on event $eventId by $username")
            
            val request = LikeRequest(
                event_id = eventId,
                username = username,
                post_id = postId
            )
            
            val response = apiService.toggleEventLike(request)
            
            if (response.isSuccessful && response.body() != null) {
                val result = response.body()!!
                if (result.success) {
                    Log.d(TAG, "Successfully toggled like: liked=${result.liked}, total=${result.total_likes}")
                    emit(Result.Success(result))
                } else {
                    val error = result.message ?: "Failed to toggle like"
                    Log.e(TAG, "Like toggle failed: $error")
                    emit(Result.Error(Exception(error), error))
                }
            } else {
                val error = response.errorBody()?.string() ?: "Unknown error"
                Log.e(TAG, "Failed to toggle like: $error")
                emit(Result.Error(Exception(error), error))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception toggling like", e)
            emit(Result.Error(e, e.message))
        }
    }.flowOn(Dispatchers.IO)
    
    /**
     * Share an event
     */
    fun shareEvent(
        eventId: String,
        username: String,
        platform: String
    ): Flow<Result<ShareResponse>> = flow {
        emit(Result.Loading)
        try {
            Log.d(TAG, "Sharing event $eventId by $username on $platform")
            
            val request = ShareRequest(
                event_id = eventId,
                username = username,
                platform = platform
            )
            
            val response = apiService.shareEvent(request)
            
            if (response.isSuccessful && response.body() != null) {
                val result = response.body()!!
                if (result.success) {
                    Log.d(TAG, "Successfully shared event: total shares=${result.total_shares}")
                    emit(Result.Success(result))
                } else {
                    val error = result.message ?: "Failed to share event"
                    Log.e(TAG, "Event share failed: $error")
                    emit(Result.Error(Exception(error), error))
                }
            } else {
                val error = response.errorBody()?.string() ?: "Unknown error"
                Log.e(TAG, "Failed to share event: $error")
                emit(Result.Error(Exception(error), error))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception sharing event", e)
            emit(Result.Error(e, e.message))
        }
    }.flowOn(Dispatchers.IO)
    
    /**
     * Format timestamp for display
     */
    fun formatTimestamp(timestamp: String): String {
        return try {
            val instant = java.time.Instant.parse(timestamp)
            val now = java.time.Instant.now()
            val duration = java.time.Duration.between(instant, now)
            
            when {
                duration.toMinutes() < 1 -> "Just now"
                duration.toMinutes() < 60 -> "${duration.toMinutes()}m ago"
                duration.toHours() < 24 -> "${duration.toHours()}h ago"
                duration.toDays() < 7 -> "${duration.toDays()}d ago"
                duration.toDays() < 30 -> "${duration.toDays() / 7}w ago"
                else -> {
                    val formatter = java.time.format.DateTimeFormatter.ofPattern("MMM d, yyyy")
                    instant.atZone(java.time.ZoneId.systemDefault()).format(formatter)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error formatting timestamp: $timestamp", e)
            timestamp
        }
    }
}

