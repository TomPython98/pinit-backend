package com.example.pinit.models

import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.UUID

/**
 * Represents a study event in the system
 */
data class StudyEvent(
    val id: UUID = UUID.randomUUID(),
    val title: String,
    val coordinate: Pair<Double, Double>? = null,
    val time: LocalDateTime,
    val endTime: LocalDateTime? = null,
    val description: String? = null,
    val invitedFriends: List<String> = emptyList(),
    val attendees: List<String> = emptyList(),
    val isPublic: Boolean = false,
    val host: String,
    val hostIsCertified: Boolean = false,
    val eventType: String? = "study",
    val isAutoMatched: Boolean = false
)

/**
 * Represents an invitation for a StudyEvent.
 * An invitation is pending if:
 * 1. For direct invitations: the current user is in the event's invitedFriends array, 
 *    is not yet in the event's attendees, and is not the host.
 * 2. For auto-matched invitations: the event is auto-matched, the user is not in attendees,
 *    and is not the host.
 */
data class Invitation(
    val id: UUID,
    val event: StudyEvent,
    val currentUser: String
) {
    val isPending: Boolean
        get() = (event.isAutoMatched || event.invitedFriends.contains(currentUser)) &&
                !event.attendees.contains(currentUser) &&
                event.host != currentUser
}

/**
 * A wrapper to decode the backend response for invitations.
 */
data class InvitationsResponse(
    val invitations: List<StudyEvent>
)

/**
 * Wrapper to decode the backend response for events
 */
data class StudyEventsResponse(
    val events: List<StudyEvent>
)

/**
 * Manages calendar and study event data
 */
class CalendarManager(private val accountManager: UserAccountManager) {
    var events = mutableListOf<StudyEvent>()
    var useDemoMode = false // Set to false to use real backend connection
    var isLoading = false
    
    init {
    }
    
    fun addEvent(event: StudyEvent) {
        // Check if event already exists (by ID)
        val existingIndex = events.indexOfFirst { it.id == event.id }
        
        if (existingIndex >= 0) {
            // Update existing event
            events[existingIndex] = event
        } else {
            // Add new event
            events.add(event)
        }
        
    }
    
    fun removeEvent(eventId: UUID) {
        events.removeIf { it.id == eventId }
    }
    
    // Get demo invitations for testing
    fun getDemoInvitations(username: String): List<Invitation> {
        if (!useDemoMode) return emptyList()
        
        // Create sample study events with invitations
        val now = LocalDateTime.now()
        val demoEvents = listOf(
            StudyEvent(
                id = UUID.randomUUID(),
                title = "Study Group: Advanced Math",
                time = now.plusDays(1),
                endTime = now.plusDays(1).plusHours(2),
                description = "Join us for an advanced math study session",
                invitedFriends = listOf(username, "Sarah", "Mike"),
                attendees = listOf("Sarah"),
                isPublic = false,
                host = "Alice",
                hostIsCertified = true,
                eventType = "study"
            ),
            StudyEvent(
                id = UUID.randomUUID(),
                title = "Physics Exam Prep",
                time = now.plusDays(2),
                endTime = now.plusDays(2).plusHours(3),
                description = "Preparing for upcoming physics exam",
                invitedFriends = listOf(username, "John", "Emma"),
                attendees = listOf("John"),
                isPublic = true,
                host = "Bob",
                hostIsCertified = false,
                eventType = "study"
            ),
            StudyEvent(
                id = UUID.randomUUID(),
                title = "Campus Party",
                time = now.plusDays(3).plusHours(20),
                endTime = now.plusDays(4),
                description = "End of semester celebration!",
                invitedFriends = listOf(username, "Emma", "Sarah", "John"),
                attendees = emptyList(),
                isPublic = true,
                host = "Mike",
                hostIsCertified = true,
                eventType = "party"
            )
        )
        
        // Convert events to invitations
        return demoEvents.map { Invitation(it.id, it, username) }
            .filter { it.isPending }
    }
    
    /**
     * Get demo events for calendar testing
     */
    fun getDemoEvents(username: String): List<StudyEvent> {
        if (!useDemoMode) return emptyList()
        
        // Create sample study events
        val now = LocalDateTime.now()
        return listOf(
            StudyEvent(
                id = UUID.randomUUID(),
                title = "Study Group: Advanced Math",
                time = now,
                endTime = now.plusHours(2),
                description = "Join us for an advanced math study session",
                invitedFriends = emptyList(),
                attendees = listOf(username, "Sarah"),
                isPublic = false,
                host = username,
                hostIsCertified = true,
                eventType = "study"
            ),
            StudyEvent(
                id = UUID.randomUUID(),
                title = "Physics Exam Prep",
                time = now.plusDays(1),
                endTime = now.plusDays(1).plusHours(3),
                description = "Preparing for upcoming physics exam",
                invitedFriends = emptyList(),
                attendees = listOf(username, "John"),
                isPublic = true,
                host = "Bob",
                hostIsCertified = false,
                eventType = "study"
            ),
            StudyEvent(
                id = UUID.randomUUID(),
                title = "Campus Party",
                time = now.plusDays(2).plusHours(20),
                endTime = now.plusDays(3),
                description = "End of semester celebration!",
                invitedFriends = emptyList(),
                attendees = listOf(username, "Emma", "Sarah", "John"),
                isPublic = true,
                host = "Mike",
                hostIsCertified = true,
                eventType = "party"
            ),
            StudyEvent(
                id = UUID.randomUUID(),
                title = "Computer Science Project",
                time = now.plusDays(5),
                endTime = now.plusDays(5).plusHours(4),
                description = "Meeting to work on the group project",
                invitedFriends = emptyList(),
                attendees = listOf(username, "Alice", "David"),
                isPublic = false,
                host = username,
                hostIsCertified = false,
                eventType = "study"
            ),
            StudyEvent(
                id = UUID.randomUUID(),
                title = "Art Exhibition",
                time = now.plusDays(7).plusHours(14),
                endTime = now.plusDays(7).plusHours(17),
                description = "Visit to the campus art exhibition",
                invitedFriends = emptyList(),
                attendees = listOf(username, "Emma"),
                isPublic = true,
                host = "Department of Fine Arts",
                hostIsCertified = true,
                eventType = "other"
            )
        )
    }
    
    fun fetchEvents() {
        println("🔍 [CalendarManager] Fetching events")
        val currentUser = accountManager.currentUser
        if (currentUser == null) {
            println("❌ [CalendarManager] Invalid username")
            return
        }
        
        println("👤 [CalendarManager] Current user: '$currentUser'")
        
        isLoading = true
        
        // Always use real backend connection
        accountManager.makeApiRequest(
            endpoint = "get_study_events/$currentUser/",
            method = "GET",
            onSuccess = { response ->
                try {
                    val jsonObject = JSONObject(response)
                    val eventsArray = jsonObject.getJSONArray("events")
                    
                    // Clear existing events
                    events.clear()
                    
                    for (i in 0 until eventsArray.length()) {
                        val eventJson = eventsArray.getJSONObject(i)
                        
                        // Parse required fields
                        val id = UUID.fromString(eventJson.getString("id"))
                        val title = eventJson.getString("title")
                        val host = eventJson.getString("host")
                        
                        // Parse times
                        val timeStr = eventJson.getString("time")
                        val time = LocalDateTime.parse(timeStr, DateTimeFormatter.ISO_DATE_TIME)
                        
                        val endTimeStr = if (eventJson.has("endTime") && !eventJson.isNull("endTime")) 
                            eventJson.getString("endTime") else null
                        val endTime = endTimeStr?.let { LocalDateTime.parse(it, DateTimeFormatter.ISO_DATE_TIME) }
                        
                        // Parse optional fields
                        val description = if (eventJson.has("description") && !eventJson.isNull("description")) 
                            eventJson.getString("description") else null
                        
                        // Parse arrays
                        val invitedFriends = mutableListOf<String>()
                        val attendees = mutableListOf<String>()
                        
                        val invitedArray = eventJson.getJSONArray("invitedFriends")
                        for (j in 0 until invitedArray.length()) {
                            invitedFriends.add(invitedArray.getString(j))
                        }
                        
                        val attendeesArray = eventJson.getJSONArray("attendees")
                        for (j in 0 until attendeesArray.length()) {
                            attendees.add(attendeesArray.getString(j))
                        }
                        
                        // Parse boolean values
                        val isPublic = eventJson.optBoolean("isPublic", false)
                        val hostIsCertified = eventJson.optBoolean("hostIsCertified", false)
                        
                        // Parse event type (backend sends "event_type" with underscore)
                        val eventType = eventJson.optString("event_type", "study")
                        
                        // Parse auto-matched status
                        val isAutoMatched = eventJson.optBoolean("isAutoMatched", false)
                        
                        // Create and add the event
                        val studyEvent = StudyEvent(
                            id = id,
                            title = title,
                            time = time,
                            endTime = endTime,
                            description = description,
                            invitedFriends = invitedFriends,
                            attendees = attendees,
                            isPublic = isPublic,
                            host = host,
                            hostIsCertified = hostIsCertified,
                            eventType = eventType,
                            isAutoMatched = isAutoMatched
                        )
                        
                        // Only include events that:
                        // 1. Haven't ended (but be more lenient for hosting events)
                        // 2. Are visible to the user (hosting, attending, invited, or auto-matched)
                        val userIsHost = host == currentUser
                        val userIsAttending = attendees.contains(currentUser)
                        val userIsInvited = invitedFriends.contains(currentUser)
                        val isAutoMatchedEvent = isAutoMatched
                        
                        // For hosting events, be more lenient with expiration (allow events that ended recently)
                        val isExpired = if (userIsHost) {
                            // For hosting events, only exclude if ended more than 1 hour ago
                            endTime != null && endTime.isBefore(LocalDateTime.now().minusHours(1))
                        } else {
                            // For other events, exclude if ended
                            endTime != null && endTime.isBefore(LocalDateTime.now())
                        }
                        
                        // Include events where user is host, attending, invited, OR auto-matched
                        // AND event has not expired (with lenient logic for hosting events)
                        val include = !isExpired && (userIsHost || userIsAttending || userIsInvited || isAutoMatchedEvent)
                        
                        if (include) {
                            addEvent(studyEvent)
                        }
                    }
                    
                    isLoading = false
                    
                } catch (e: Exception) {
                    isLoading = false
                    events.clear() // Clear events on error
                }
            },
            onError = { error ->
                isLoading = false
                events.clear() // Clear events on error
            }
        )
    }
    
    /**
     * RSVP to an event
     */
    fun rsvpEvent(eventId: UUID, onComplete: (Boolean, String) -> Unit) {
        val currentUser = accountManager.currentUser
        if (currentUser == null) {
            onComplete(false, "User not logged in")
            return
        }
        
        println("🔍 [CalendarManager] RSVP for event ID: $eventId")
        isLoading = true
        
        // Check if we already have this event in our local list
        val existingEvent = events.find { it.id == eventId }
        val isAttending = existingEvent?.attendees?.contains(currentUser) ?: false
        val eventTitle = existingEvent?.title ?: "unknown event"
        
        // Log the current state for debugging
        if (existingEvent != null) {
            println("✨ [CalendarManager] Found event in local cache: ${existingEvent.title}")
            println("👥 [CalendarManager] Current attendees: ${existingEvent.attendees.size} (${existingEvent.attendees.joinToString(", ")})")
            println("🔄 [CalendarManager] Current attendance status: isAttending=$isAttending")
        } else {
            println("⚠️ [CalendarManager] Event not found in local cache, proceeding with API call")
        }
        
        // Prepare request body as Map
        val requestBody = mapOf(
            "username" to currentUser,
            "event_id" to eventId.toString()
        )
        
        accountManager.makeApiRequest(
            endpoint = "rsvp_study_event/",
            method = "POST",
            body = requestBody,
            onSuccess = { response ->
                println("📦 [CalendarManager] RSVP response: $response")
                
                try {
                    val jsonResponse = JSONObject(response)
                    val success = jsonResponse.optBoolean("success", false)
                    val message = jsonResponse.optString("message", "RSVP processed")
                    val newStatus = jsonResponse.optBoolean("is_attending", !isAttending)
                    
                    if (success) {
                        // Log the RSVP state change explicitly
                        println("✅ [CalendarManager] RSVP successful for '$eventTitle'")
                        println("  - isAttending: $isAttending → $newStatus")
                        
                        // Update our local copy of the event immediately before reloading
                        if (existingEvent != null) {
                            // Update attendees list based on the new status
                            val newAttendees = if (newStatus && !isAttending) {
                                // Add user to attendees
                                existingEvent.attendees + currentUser
                            } else if (!newStatus && isAttending) {
                                // Remove user from attendees
                                existingEvent.attendees.filter { it != currentUser }
                            } else {
                                // No change
                                existingEvent.attendees
                            }
                            
                            // Create an updated event with the new attendees
                            val updatedEvent = existingEvent.copy(attendees = newAttendees)
                            
                            // Replace the old event in our cache
                            val eventIndex = events.indexOfFirst { it.id == eventId }
                            if (eventIndex >= 0) {
                                events[eventIndex] = updatedEvent
                                println("🔄 [CalendarManager] Updated local event cache with new attendee status")
                            }
                        }
                        
                        // Refresh events after successful RSVP to get server's updated data
                        // This will merge with our local updates
                        fetchEvents()
                        onComplete(true, message)
                    } else {
                        println("❌ [CalendarManager] RSVP failed: $message")
                        isLoading = false
                        onComplete(false, message)
                    }
                } catch (e: Exception) {
                    println("❌ [CalendarManager] RSVP parsing error: ${e.message}")
                    e.printStackTrace()
                    isLoading = false
                    onComplete(false, "Error processing RSVP: ${e.message}")
                }
            },
            onError = { error ->
                println("❌ [CalendarManager] RSVP error: $error")
                isLoading = false
                onComplete(false, "RSVP error: $error")
            }
        )
    }
    
    /**
     * Create a new event on the server
     */
    fun createEvent(event: StudyEvent, onComplete: (Boolean, String) -> Unit) {
        val currentUser = accountManager.currentUser
        if (currentUser == null) {
            onComplete(false, "User not logged in")
            return
        }
        
        println("🔍 [CalendarManager] Creating event: ${event.title}")
        isLoading = true
        
        // Convert the event to a Map for the request body
        val requestBody = mapOf(
            "id" to event.id.toString(),
            "title" to event.title,
            "time" to event.time.format(DateTimeFormatter.ISO_DATE_TIME),
            "endTime" to (event.endTime?.format(DateTimeFormatter.ISO_DATE_TIME) ?: ""),
            "description" to (event.description ?: ""),
            "invitedFriends" to event.invitedFriends,
            "attendees" to event.attendees,
            "isPublic" to event.isPublic,
            "host" to event.host,
            "hostIsCertified" to event.hostIsCertified,
            "eventType" to (event.eventType ?: "study")
        )
        
        accountManager.makeApiRequest(
            endpoint = "create_study_event/",
            method = "POST",
            body = requestBody,
            onSuccess = { response ->
                println("📦 [CalendarManager] Create event response: $response")
                
                try {
                    val jsonResponse = JSONObject(response)
                    val success = jsonResponse.optBoolean("success", false)
                    val message = jsonResponse.optString("message", "Event created")
                    
                    if (success) {
                        // Add the event to our local list
                        addEvent(event)
                        isLoading = false
                        onComplete(true, message)
                    } else {
                        isLoading = false
                        onComplete(false, message)
                    }
                } catch (e: Exception) {
                    println("❌ [CalendarManager] Create event parsing error: ${e.message}")
                    isLoading = false
                    onComplete(false, "Error creating event: ${e.message}")
                }
            },
            onError = { error ->
                println("❌ [CalendarManager] Create event error: $error")
                isLoading = false
                onComplete(false, "Create event error: $error")
            }
        )
    }
} 