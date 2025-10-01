package com.example.pinit.network

import com.example.pinit.models.EventType
import com.example.pinit.models.StudyEventMap
import com.google.gson.annotations.SerializedName
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.UUID

/**
 * Request model for creating a new event
 */
data class EventCreateRequest(
    @SerializedName("title") val title: String,
    @SerializedName("description") val description: String?,
    @SerializedName("time") val time: String,
    @SerializedName("end_time") val endTime: String,
    @SerializedName("latitude") val latitude: Double,
    @SerializedName("longitude") val longitude: Double,
    @SerializedName("host") val host: String,
    @SerializedName("is_public") val isPublic: Boolean = true,
    @SerializedName("event_type") val eventType: String,
    @SerializedName("invited_friends") val invitedFriends: List<String> = emptyList(),
    @SerializedName("max_participants") val maxParticipants: Int = 10,
    @SerializedName("interest_tags") val interestTags: List<String> = emptyList(),
    @SerializedName("auto_matching_enabled") val autoMatchingEnabled: Boolean = false,
    @SerializedName("matched_users") val matchedUsers: List<String> = emptyList(),
    @SerializedName("event_images") val eventImages: List<String> = emptyList()
) {
    companion object {
        /**
         * Convert a StudyEventMap to an EventCreateRequest
         */
        fun fromStudyEventMap(event: StudyEventMap, username: String): EventCreateRequest {
            // Python's datetime.fromisoformat() expects ISO-8601 format with 'T' zone designator
            // Format: "YYYY-MM-DD'T'HH:MM:SS"
            val dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss")
            
            return EventCreateRequest(
                title = event.title,
                description = event.description ?: "",  // Ensure description is never null
                time = event.time.format(dateFormatter),
                endTime = event.endTime?.format(dateFormatter) ?: event.time.plusHours(1).format(dateFormatter),
                latitude = event.coordinate?.second ?: 0.0,
                longitude = event.coordinate?.first ?: 0.0,
                // IMPORTANT: Always use the authenticated username parameter, not event.host
                // This prevents null host errors and ensures the correct user is set
                host = username,
                isPublic = event.isPublic,
                eventType = event.eventType?.name?.lowercase() ?: "other",
                invitedFriends = event.invitedFriends ?: emptyList(),
                interestTags = event.interestTags,
                maxParticipants = event.maxParticipants,
                autoMatchingEnabled = event.autoMatchingEnabled,
                matchedUsers = event.matchedUsers,
                eventImages = event.eventImages
            )
        }
    }
} 