package com.example.pinit.models

import com.google.gson.annotations.SerializedName

/**
 * Models for social interactions with events
 */
data class EventInteractions(
    val eventId: String,
    var posts: MutableList<Post> = mutableListOf(),
    var likes: Stats = Stats(0, mapOf()),
    var shares: Stats = Stats(0, mapOf())
) {
    /**
     * Represents a comment or reply in the event feed
     */
    data class Post(
        val id: Int,
        val text: String,
        val username: String,
        val userId: String,
        @SerializedName("created_at") val createdAt: String,
        @SerializedName("imageURLs") val imageUrls: List<String>? = null,
        var likes: Int = 0,
        var isLikedByCurrentUser: Boolean = false,
        var replies: MutableList<Post> = mutableListOf()
    ) {
        override fun equals(other: Any?): Boolean {
            if (this === other) return true
            if (javaClass != other?.javaClass) return false
            other as Post
            return id == other.id
        }

        override fun hashCode(): Int {
            return id
        }
    }

    /**
     * Stores statistics information like likes and shares
     */
    data class Stats(
        var total: Int,
        var breakdown: Map<String, Int>
    )
} 