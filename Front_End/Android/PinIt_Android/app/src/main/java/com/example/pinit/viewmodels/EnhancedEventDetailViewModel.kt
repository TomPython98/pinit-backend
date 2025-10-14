package com.example.pinit.viewmodels

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.pinit.models.*
import com.example.pinit.repository.ReputationRepository
import com.example.pinit.repository.SocialRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * ViewModel for enhanced event detail with social features
 */
class EnhancedEventDetailViewModel : ViewModel() {
    private val TAG = "EnhancedEventDetailVM"
    
    private val socialRepository = SocialRepository()
    private val reputationRepository = ReputationRepository()
    
    // Event feed state
    private val _eventFeed = MutableStateFlow<Result<EventFeed>>(Result.Idle)
    val eventFeed: StateFlow<Result<EventFeed>> = _eventFeed.asStateFlow()
    
    // Host reputation state
    private val _hostReputation = MutableStateFlow<Result<UserReputationResponse>>(Result.Idle)
    val hostReputation: StateFlow<Result<UserReputationResponse>> = _hostReputation.asStateFlow()
    
    // Comment submission state
    private val _commentSubmission = MutableStateFlow<Result<EventComment?>>(Result.Idle)
    val commentSubmission: StateFlow<Result<EventComment?>> = _commentSubmission.asStateFlow()
    
    // Like toggle state
    private val _likeToggle = MutableStateFlow<Result<LikeResponse>>(Result.Idle)
    val likeToggle: StateFlow<Result<LikeResponse>> = _likeToggle.asStateFlow()
    
    // Share event state
    private val _shareEvent = MutableStateFlow<Result<ShareResponse>>(Result.Idle)
    val shareEvent: StateFlow<Result<ShareResponse>> = _shareEvent.asStateFlow()
    
    // Rating submission state
    private val _ratingSubmission = MutableStateFlow<Result<SubmitRatingResponse>>(Result.Idle)
    val ratingSubmission: StateFlow<Result<SubmitRatingResponse>> = _ratingSubmission.asStateFlow()
    
    /**
     * Load event feed with comments, likes, and shares
     */
    fun loadEventFeed(eventId: String, currentUser: String) {
        viewModelScope.launch {
            socialRepository.getEventFeed(eventId, currentUser).collect { result ->
                _eventFeed.value = result
            }
        }
    }
    
    /**
     * Load host reputation
     */
    fun loadHostReputation(hostUsername: String) {
        viewModelScope.launch {
            reputationRepository.getUserReputation(hostUsername).collect { result ->
                _hostReputation.value = result
            }
        }
    }
    
    /**
     * Add a comment to the event
     */
    fun addComment(
        eventId: String,
        username: String,
        text: String,
        parentId: Int? = null
    ) {
        viewModelScope.launch {
            socialRepository.addComment(
                eventId = eventId,
                username = username,
                text = text,
                parentId = parentId
            ).collect { result ->
                _commentSubmission.value = result
                
                // If successful, reload the feed
                if (result is Result.Success) {
                    loadEventFeed(eventId, username)
                }
            }
        }
    }
    
    /**
     * Toggle like on event or comment
     */
    fun toggleLike(
        eventId: String,
        username: String,
        postId: Int? = null
    ) {
        viewModelScope.launch {
            socialRepository.toggleLike(
                eventId = eventId,
                username = username,
                postId = postId
            ).collect { result ->
                _likeToggle.value = result
                
                // If successful, reload the feed
                if (result is Result.Success) {
                    loadEventFeed(eventId, username)
                }
            }
        }
    }
    
    /**
     * Share event to a platform
     */
    fun shareEvent(
        eventId: String,
        username: String,
        platform: String
    ) {
        viewModelScope.launch {
            socialRepository.shareEvent(
                eventId = eventId,
                username = username,
                platform = platform
            ).collect { result ->
                _shareEvent.value = result
                
                // If successful, reload the feed
                if (result is Result.Success) {
                    loadEventFeed(eventId, username)
                }
            }
        }
    }
    
    /**
     * Submit a rating for another user
     */
    fun submitRating(
        fromUsername: String,
        toUsername: String,
        rating: Int,
        comment: String,
        eventId: String? = null
    ) {
        viewModelScope.launch {
            reputationRepository.submitRating(
                fromUsername = fromUsername,
                toUsername = toUsername,
                rating = rating,
                reference = comment,
                eventId = eventId
            ).collect { result ->
                _ratingSubmission.value = result
            }
        }
    }
    
    /**
     * Reset comment submission state
     */
    fun resetCommentSubmission() {
        _commentSubmission.value = Result.Idle
    }
    
    /**
     * Reset like toggle state
     */
    fun resetLikeToggle() {
        _likeToggle.value = Result.Idle
    }
    
    /**
     * Reset share event state
     */
    fun resetShareEvent() {
        _shareEvent.value = Result.Idle
    }
    
    /**
     * Reset rating submission state
     */
    fun resetRatingSubmission() {
        _ratingSubmission.value = Result.Idle
    }
    
    /**
     * Get sorted comments (newest first)
     */
    fun getSortedComments(feed: EventFeed): List<EventComment> {
        return feed.displayPosts.sortedByDescending { it.created_at }
    }
    
    /**
     * Get engagement stats
     */
    fun getEngagementStats(feed: EventFeed): EngagementStats {
        return EngagementStats(
            totalComments = feed.displayPosts.size,
            totalLikes = feed.likes?.total ?: 0,
            totalShares = feed.shares?.total ?: 0
        )
    }
    
    data class EngagementStats(
        val totalComments: Int,
        val totalLikes: Int,
        val totalShares: Int
    )
}

