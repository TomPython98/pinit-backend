package com.example.pinit.models

import com.mapbox.geojson.Point
import java.time.LocalDateTime
import java.util.Date
import java.util.UUID

/**
 * EventType enum representing different types of events on the map
 */
enum class EventType(val displayName: String) {
    STUDY("Study"),
    PARTY("Party"),
    BUSINESS("Business"),
    OTHER("Other"),
    CULTURAL("Cultural"),
    ACADEMIC("Academic"),
    NETWORKING("Networking"),
    SOCIAL("Social"),
    LANGUAGE_EXCHANGE("Language Exchange");
    
    companion object {
        fun fromString(value: String): EventType {
            return when (value.lowercase()) {
                "study" -> STUDY
                "party" -> PARTY
                "business" -> BUSINESS
                "other" -> OTHER
                "cultural" -> CULTURAL
                "academic" -> ACADEMIC
                "networking" -> NETWORKING
                "social" -> SOCIAL
                "language_exchange" -> LANGUAGE_EXCHANGE
                else -> OTHER
            }
        }
    }
}

/**
 * Model class representing a user profile
 */
data class UserProfile(
    val username: String,
    val isCertified: Boolean = false,
    val interests: List<String> = emptyList(),
    val skills: Map<String, String> = emptyMap(),
    val autoInviteEnabled: Boolean = true,
    val preferredRadius: Float = 10.0f,
    // Enhanced profile information to match iOS
    val fullName: String = "",
    val university: String = "",
    val degree: String = "",
    val year: String = "",
    val bio: String = ""
)

/**
 * Profile completion data class
 */
data class ProfileCompletion(
    val completionPercentage: Double = 0.0,
    val missingItems: List<String> = emptyList(),
    val benefitsMessage: String = "",
    val completionLevel: String = "",
    val categoryBreakdown: Map<String, Map<String, Any>> = emptyMap()
)

/**
 * Extension of StudyEvent for map display functionality
 * This keeps compatibility with the existing StudyEvent class but adds map-specific features
 */
class StudyEventMap(
    val id: String? = null,
    val title: String,
    val coordinate: Pair<Double, Double>? = null,
    val time: LocalDateTime,
    val endTime: LocalDateTime? = null,
    val description: String? = null,
    val invitedFriends: List<String> = emptyList(),
    val attendees: Int = 0,
    val attendeesList: List<String> = emptyList(), // Add actual attendees list
    val isPublic: Boolean = true,
    val host: String,
    val hostIsCertified: Boolean = false,
    val eventType: EventType? = EventType.STUDY,
    val isUserAttending: Boolean = false,
    val interestTags: List<String> = emptyList(),
    val maxParticipants: Int = 10,
    val autoMatchingEnabled: Boolean = false,
    val isAutoMatched: Boolean = false,
    val matchedUsers: List<String> = emptyList(),
    val eventImages: List<String> = emptyList()
) {
    /**
     * Checks if the event has expired (ended in the past)
     */
    fun isExpired(): Boolean {
        return endTime?.isBefore(LocalDateTime.now()) ?: false
    }

    /**
     * Create a copy of the StudyEventMap with modified properties
     */
    fun copy(
        id: String? = this.id,
        title: String = this.title,
        coordinate: Pair<Double, Double>? = this.coordinate,
        time: LocalDateTime = this.time,
        endTime: LocalDateTime? = this.endTime,
        description: String? = this.description,
        invitedFriends: List<String> = this.invitedFriends,
        attendees: Int = this.attendees,
        isPublic: Boolean = this.isPublic,
        host: String = this.host,
        hostIsCertified: Boolean = this.hostIsCertified,
        eventType: EventType? = this.eventType,
        isUserAttending: Boolean = this.isUserAttending,
        interestTags: List<String> = this.interestTags,
        maxParticipants: Int = this.maxParticipants,
        autoMatchingEnabled: Boolean = this.autoMatchingEnabled,
        isAutoMatched: Boolean = this.isAutoMatched,
        matchedUsers: List<String> = this.matchedUsers,
        eventImages: List<String> = this.eventImages
    ): StudyEventMap {
        return StudyEventMap(
            id = id,
            title = title,
            coordinate = coordinate,
            time = time,
            endTime = endTime,
            description = description,
            invitedFriends = invitedFriends,
            attendees = attendees,
            isPublic = isPublic,
            host = host,
            hostIsCertified = hostIsCertified,
            eventType = eventType,
            isUserAttending = isUserAttending,
            interestTags = interestTags,
            maxParticipants = maxParticipants,
            autoMatchingEnabled = autoMatchingEnabled,
            isAutoMatched = isAutoMatched,
            matchedUsers = matchedUsers,
            eventImages = eventImages
        )
    }
}

// Extension function to convert StudyEventMap to StudyEvent
fun StudyEventMap.toStudyEvent(): StudyEvent {
    return StudyEvent(
        id = try {
            UUID.fromString(this.id ?: UUID.randomUUID().toString())
        } catch (e: IllegalArgumentException) {
            UUID.randomUUID()
        },
        title = this.title,
        coordinate = this.coordinate,
        time = this.time,
        endTime = this.endTime,
        description = this.description,
        invitedFriends = this.invitedFriends,
        attendees = if (this.attendeesList.isNotEmpty()) {
            this.attendeesList
        } else if (this.matchedUsers.isNotEmpty()) {
            this.matchedUsers
        } else if (this.attendees > 0) {
            // Fallback: create realistic usernames based on count
            (1..this.attendees).map { "Attendee$it" }
        } else {
            emptyList()
        },
        isPublic = this.isPublic,
        host = this.host,
        hostIsCertified = this.hostIsCertified,
        eventType = this.eventType?.name?.lowercase() ?: "study",
        isAutoMatched = this.isAutoMatched
    )
} 