package com.example.pinit.repository

import android.util.Log
import com.example.pinit.models.EventInteractions
import com.example.pinit.network.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map

/**
 * Repository for event interactions like comments, likes, and social feed
 */
class EventInteractionsRepository {
    private val interactionsService = ApiClient.eventInteractionsService
    private val TAG = "EventInteractionsRepo"
    
    /**
     * Get event social feed
     */
    fun getEventFeed(eventId: String, currentUser: String?): Flow<Result<EventInteractions>> = flow {
        try {
            Log.d(TAG, "Fetching event feed for event: $eventId, user: $currentUser")
            val response = interactionsService.getEventFeed(eventId, currentUser)
            
            if (response.isSuccessful) {
                val feed = response.body()
                if (feed != null) {
                    Log.d(TAG, "Successfully fetched feed with ${feed.posts.size} posts")
                    
                    // Add eventId to the model if it doesn't already exist
                    val feedWithEventId = if (feed is EventInteractions) {
                        if (feed.eventId == eventId) feed else {
                            // Create a new instance with the correct eventId
                            EventInteractions(
                                eventId = eventId,
                                posts = feed.posts,
                                likes = feed.likes,
                                shares = feed.shares
                            )
                        }
                    } else {
                        // Create a new instance with all data from API response
                        EventInteractions(
                            eventId = eventId,
                            posts = feed.posts,
                            likes = feed.likes,
                            shares = feed.shares
                        )
                    }
                    
                    emit(Result.success(feedWithEventId))
                } else {
                    Log.e(TAG, "Successful response but body is null")
                    emit(Result.failure(Exception("API Error: Response body is null")))
                }
            } else {
                Log.e(TAG, "API Error: ${response.code()} - ${response.errorBody()?.string()}")
                emit(Result.failure(Exception("API Error: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception while fetching event feed: ${e.message}", e)
            emit(Result.failure(e))
        }
    }
    
    /**
     * Add a comment or reply to an event
     */
    fun addComment(
        username: String,
        userId: String,
        eventId: String,
        text: String,
        imageUrls: List<String>? = null,
        parentId: Int? = null
    ): Flow<Result<CommentResponse>> = flow {
        try {
            Log.d(TAG, "Adding comment to event: $eventId by user: $username")
            
            val commentRequest = CommentRequest(
                username = username,
                event_id = eventId,
                text = text,
                image_urls = imageUrls,
                parent_id = parentId
            )
            
            val response = interactionsService.addComment(commentRequest)
            
            if (response.isSuccessful) {
                val result = response.body()
                if (result != null) {
                    Log.d(TAG, "Successfully added comment with ID: ${result.post_id}")
                    emit(Result.success(result))
                } else {
                    Log.e(TAG, "Successful response but body is null")
                    emit(Result.failure(Exception("API Error: Response body is null")))
                }
            } else {
                Log.e(TAG, "API Error: ${response.code()} - ${response.errorBody()?.string()}")
                emit(Result.failure(Exception("API Error: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception while adding comment: ${e.message}", e)
            emit(Result.failure(e))
        }
    }
    
    /**
     * Like or unlike a post
     */
    fun likePost(
        username: String,
        userId: String,
        eventId: String,
        postId: Int
    ): Flow<Result<LikeResponse>> = flow {
        try {
            Log.d(TAG, "Toggling like for post: $postId in event: $eventId by user: $username")
            
            val likeRequest = LikeRequest(
                username = username,
                event_id = eventId,
                post_id = postId
            )
            
            val response = interactionsService.likePost(likeRequest)
            
            if (response.isSuccessful) {
                val result = response.body()
                if (result != null) {
                    Log.d(TAG, "Like operation successful. New state: liked=${result.liked}, total_likes=${result.total_likes}")
                    emit(Result.success(result))
                } else {
                    Log.e(TAG, "Successful response but body is null")
                    emit(Result.failure(Exception("API Error: Response body is null")))
                }
            } else {
                Log.e(TAG, "API Error: ${response.code()} - ${response.errorBody()?.string()}")
                emit(Result.failure(Exception("API Error: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception during like operation: ${e.message}", e)
            emit(Result.failure(e))
        }
    }
} 