package com.example.pinit.models

import com.example.pinit.models.EventType
import com.google.gson.annotations.SerializedName
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.UUID

/**
 * Data classes for API responses
 */

/**
 * Response class for study events
 */
data class ApiEventsResponse(
    @SerializedName("events") val events: List<EventResponse>
)

/**
 * Response class for a single event
 */
data class EventResponse(
    @SerializedName("id") val id: String,
    @SerializedName("title") val title: String,
    @SerializedName("description") val description: String?,
    @SerializedName("latitude") val latitude: Double,
    @SerializedName("longitude") val longitude: Double,
    @SerializedName("time") val time: String,
    @SerializedName("end_time") val endTime: String,
    @SerializedName("host") val host: String,
    @SerializedName("hostIsCertified") val hostIsCertified: Boolean,
    @SerializedName("isPublic") val isPublic: Boolean,
    @SerializedName("event_type") val eventType: String,
    @SerializedName("invitedFriends") val invitedFriends: List<String>? = null,
    @SerializedName("attendees") val attendees: List<String>? = null,
    @SerializedName("isAutoMatched") val isAutoMatched: Boolean = false
) {
    /**
     * Convert API response to domain model
     * 
     * @param isUserAttending Optional flag to indicate if the current user is attending this event,
     *                        typically based on attendees list verification from the repository
     */
    fun toStudyEventMap(isUserAttending: Boolean = false): StudyEventMap {
        // If attendees list exists, we could determine attendance status directly here
        // However, we respect the passed parameter for consistency with repository logic
        return StudyEventMap(
            id = id,
            title = title,
            coordinate = Pair(longitude, latitude),
            time = parseDateTime(time),
            endTime = parseDateTime(endTime),
            description = description,
            invitedFriends = invitedFriends ?: emptyList(),
            attendees = attendees?.size ?: 0,
            isPublic = isPublic,
            host = host,
            hostIsCertified = hostIsCertified,
            eventType = when(eventType.lowercase()) {
                "study" -> EventType.STUDY
                "party" -> EventType.PARTY
                "business" -> EventType.BUSINESS
                else -> EventType.OTHER
            },
            isUserAttending = isUserAttending,
            isAutoMatched = isAutoMatched
        )
    }
    
    /**
     * Parse ISO DateTime string to LocalDateTime
     */
    private fun parseDateTime(dateTimeString: String): LocalDateTime {
        return try {
            LocalDateTime.parse(dateTimeString, DateTimeFormatter.ISO_DATE_TIME)
        } catch (e: Exception) {
            LocalDateTime.now() // Fallback in case of parsing error
        }
    }
}

/**
 * Response for authentication
 */
data class AuthResponse(
    @SerializedName("success") val success: Boolean,
    @SerializedName("message") val message: String
)

/**
 * User profile response
 */
data class UserProfileResponse(
    @SerializedName("username") val username: String,
    @SerializedName("is_certified") val isCertified: Boolean,
    @SerializedName("interests") val interests: List<String> = emptyList(),
    @SerializedName("skills") val skills: Map<String, String> = emptyMap(),
    @SerializedName("auto_invite_enabled") val autoInviteEnabled: Boolean = true,
    @SerializedName("preferred_radius") val preferredRadius: Float = 10.0f,
    // Enhanced profile fields to match iOS
    @SerializedName("full_name") val fullName: String = "",
    @SerializedName("university") val university: String = "",
    @SerializedName("degree") val degree: String = "",
    @SerializedName("year") val year: String = "",
    @SerializedName("bio") val bio: String = ""
)

/**
 * Profile completion response
 */
data class ProfileCompletionResponse(
    @SerializedName("completion_percentage") val completionPercentage: Double = 0.0,
    @SerializedName("missing_items") val missingItems: List<String> = emptyList(),
    @SerializedName("benefits_message") val benefitsMessage: String = "",
    @SerializedName("completion_level") val completionLevel: String = "",
    @SerializedName("category_breakdown") val categoryBreakdown: Map<String, Map<String, Any>> = emptyMap()
) 