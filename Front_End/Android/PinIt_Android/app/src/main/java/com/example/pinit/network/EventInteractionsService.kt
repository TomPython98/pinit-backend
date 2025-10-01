package com.example.pinit.network

import com.example.pinit.models.EventInteractions
import retrofit2.Response
import retrofit2.http.*

/**
 * API service for event interactions like comments, likes, and posts
 */
interface EventInteractionsService {
    
    /**
     * Get the social feed for an event
     */
    @GET("events/feed/{eventId}/")
    suspend fun getEventFeed(
        @Path("eventId") eventId: String,
        @Query("current_user") currentUser: String? = null
    ): Response<EventInteractions>
    
    /**
     * Add a comment or reply to an event
     */
    @POST("events/comment/")
    suspend fun addComment(
        @Body commentData: CommentRequest
    ): Response<CommentResponse>
    
    /**
     * Like or unlike a post
     */
    @POST("events/like/")
    suspend fun likePost(
        @Body likeData: LikeRequest
    ): Response<LikeResponse>
}

/**
 * Request body for adding a comment
 */
data class CommentRequest(
    val username: String,
    val user_id: String? = null,
    val event_id: String,
    val text: String,
    val image_urls: List<String>? = null,
    val parent_id: Int? = null
)

/**
 * Response for comment creation
 */
data class CommentResponse(
    val success: Boolean,
    val post_id: Int,
    val user_id: String? = null,
    val message: String
)

/**
 * Request body for liking a post
 */
data class LikeRequest(
    val username: String,
    val user_id: String? = null,
    val event_id: String,
    val post_id: Int
)

/**
 * Response for like action
 */
data class LikeResponse(
    val success: Boolean,
    val liked: Boolean,
    val total_likes: Int
) 