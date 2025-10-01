package com.example.pinit.repository

import android.util.Log
import com.example.pinit.models.StudyEventMap
import com.example.pinit.models.EventType
import com.example.pinit.network.ApiClient
import com.example.pinit.network.EventCreateRequest
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import com.google.gson.Gson
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.flowOn
import java.time.LocalDateTime
import android.graphics.PointF
import java.util.Date
import com.example.pinit.models.EventResponse

/**
 * Repository for accessing event data
 */
class EventRepository {
    val apiService = ApiClient.apiService
    private val gson = Gson()
    private val TAG = "EventRepository"
    
    // Removed event caching
    
    /**
     * Fetch events for a user
     */
    fun getEventsForUser(username: String): Flow<Result<List<StudyEventMap>>> = flow {
        try {
            Log.d(TAG, "🔍 DETAILED DEBUG: Requesting events for user: $username")
            
            // Make the API call to get events for the user
            val response = apiService.getStudyEvents(username)
            
            if (response.isSuccessful) {
                Log.d(TAG, "API call successful with status code: ${response.code()}")
                
                val responseBody = response.body()
                if (responseBody != null) {
                    // Extra debugging: Print the complete raw response for techuser1
                    if (username.equals("techuser1", ignoreCase = true)) {
                        Log.d(TAG, "👤 TECHUSER1 RAW API RESPONSE: ${gson.toJson(responseBody)}")
                        
                        // Explicitly check for auto-matched events in response
                        val autoMatchCount = responseBody.events.count { it.isAutoMatched }
                        Log.d(TAG, "👤 TECHUSER1: Found $autoMatchCount auto-matched events in raw API response")
                        
                        // Print details of each event to debug
                        responseBody.events.forEachIndexed { index, event ->
                            Log.d(TAG, "👤 TECHUSER1 EVENT[$index]:")
                            Log.d(TAG, "   - ID: ${event.id}")
                            Log.d(TAG, "   - Title: ${event.title}")
                            Log.d(TAG, "   - isAutoMatched: ${event.isAutoMatched}")
                            Log.d(TAG, "   - invitedFriends: ${event.invitedFriends?.joinToString(", ") ?: "null"}")
                            Log.d(TAG, "   - attendees: ${event.attendees?.joinToString(", ") ?: "null"}")
                        }
                    }
                    
                    // Convert API response to domain model
                    val allEvents = responseBody.events.mapNotNull { eventResponse -> 
                        try {
                            // Check if user is in attendees list
                            val attendeesList = eventResponse.attendees ?: emptyList()
                            val userIsAttendee = attendeesList.contains(username)
                            
                            // Check coordinates
                            Log.d(TAG, "Event ${eventResponse.id} - Coordinates: lat=${eventResponse.latitude}, lon=${eventResponse.longitude}")
                            
                            // Debug auto-matched status
                            if (eventResponse.isAutoMatched) {
                                Log.d(TAG, "🔍 AUTO-MATCHED EVENT FOUND: ${eventResponse.id} - ${eventResponse.title}")
                            }
                            
                            // Create StudyEventMap with proper attendance flag
                            val event = eventResponse.toStudyEventMap(isUserAttending = userIsAttendee)
                            
                            // Still check the PotentialMatchRegistry for matches, but don't cache the event
                            val normalizedId = event.id?.trim()?.lowercase() ?: ""
                            if (normalizedId.isNotEmpty() && 
                                com.example.pinit.utils.PotentialMatchRegistry.isEventPotentialMatch(event.id)) {
                                
                                Log.d(TAG, "✨ IMPORTANT: Found event in potential matches registry: ${event.id}")
                                
                                // Force the isAutoMatched flag to be true
                                val updatedEvent = event.copy(isAutoMatched = true)
                                
                                // Debug the updated event
                                Log.d(TAG, "Converted event ${updatedEvent.id} - Title: ${updatedEvent.title}, " +
                                       "Coordinates: ${updatedEvent.coordinate}, Type: ${updatedEvent.eventType}, " +
                                       "AutoMatched: ${updatedEvent.isAutoMatched}")
                                
                                return@mapNotNull updatedEvent
                            }
                            
                            // Debug the created event
                            Log.d(TAG, "Converted event ${event.id} - Title: ${event.title}, " +
                                   "Coordinates: ${event.coordinate}, Type: ${event.eventType}, " +
                                   "AutoMatched: ${event.isAutoMatched}")
                            
                            event
                        } catch (e: Exception) {
                            Log.e(TAG, "Error converting event: ${e.message}", e)
                            e.printStackTrace() // Print stack trace for more detailed error information
                            null // Skip this event due to conversion error
                        }
                    }
                    
                    Log.d(TAG, "✅ Retrieved ${allEvents.size} total events")
                    
                    // Debug all events before filtering
                    allEvents.forEachIndexed { index, event ->
                        Log.d(TAG, "AllEvent[$index] - ID: ${event.id}, Title: ${event.title}, " +
                             "Coordinates: ${event.coordinate}, Type: ${event.eventType}")
                    }
                    
                    // Filter events based on access rules:
                    // Events are visible if:
                    // 1. Public events
                    // 2. Events where the user is the host
                    // 3. Events where the user is attending (has explicitly accepted an invitation)
                    // 4. Private events are only visible if user is host or attendee
                    val filteredEvents = allEvents.filter { event ->
                        val userIsHost = event.host == username
                        val isPublic = event.isPublic
                        val userIsAttending = event.isUserAttending
                        
                        // Check if user is in invitedFriends list (but may not have accepted yet)
                        val userIsInvited = event.invitedFriends.contains(username)
                        
                        // An event should be visible if:
                        // - It's public (and user is not specifically invited but not attending), OR
                        // - User is the host, OR
                        // - User is attending (has accepted an invitation)
                        val isVisible = (isPublic && (!userIsInvited || userIsAttending)) || userIsHost || userIsAttending
                        
                        if (!isVisible) {
                            Log.d(TAG, "Filtered out event ${event.id} - ${event.title}: " +
                                 "public=$isPublic, host=$userIsHost, attending=$userIsAttending, invited=$userIsInvited")
                        }
                        
                        isVisible
                    }
                    
                    Log.d(TAG, "After filtering, showing ${filteredEvents.size} events (${allEvents.size - filteredEvents.size} hidden)")
                    
                    // Log detailed information about visible/hidden events
                    val publicCount = filteredEvents.count { it.isPublic }
                    val hostCount = filteredEvents.count { it.host == username }
                    val attendingCount = filteredEvents.count { it.isUserAttending }
                    
                    Log.d(TAG, "Event visibility breakdown:")
                    Log.d(TAG, "- Public events: $publicCount")
                    Log.d(TAG, "- Hosting: $hostCount")
                    Log.d(TAG, "- Attending: $attendingCount")
                    
                    // Log each visible event for debugging
                    filteredEvents.forEachIndexed { index, event ->
                        val statusTags = mutableListOf<String>()
                        if (event.host == username) statusTags.add("HOST")
                        if (event.isUserAttending) statusTags.add("ATTENDING")
                        if (event.invitedFriends.contains(username) && !event.isUserAttending) statusTags.add("INVITED")
                        if (event.isPublic) statusTags.add("PUBLIC")
                        
                        Log.d(TAG, "FilteredEvent[$index]: id=${event.id}, title=${event.title}, " +
                                "coord=${event.coordinate}, type=${event.eventType}, " +
                                "status=[${statusTags.joinToString(",")}]")
                    }
                    
                    emit(Result.success(filteredEvents))
                } else {
                    Log.e(TAG, "API response body was null")
                    emit(Result.failure(Exception("API response body was null")))
                }
            } else {
                val errorBody = response.errorBody()?.string()
                Log.e(TAG, "API Error: ${response.code()} - $errorBody")
                emit(Result.failure(Exception("API Error: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception while fetching events: ${e.message}", e)
            e.printStackTrace() // Print stack trace for more detailed error information
            emit(Result.failure(e))
        }
    }.flowOn(Dispatchers.IO)
    
    /**
     * Search for events
     */
    fun searchEvents(
        query: String,
        publicOnly: Boolean = false,
        certifiedOnly: Boolean = false,
        eventType: String? = null
    ): Flow<Result<List<StudyEventMap>>> = flow {
        try {
            Log.d(TAG, "Searching events with query: $query")
            val response = apiService.searchEvents(
                query = query,
                publicOnly = publicOnly,
                certifiedOnly = certifiedOnly,
                eventType = eventType,
                semantic = true
            )
            
            if (response.isSuccessful) {
                Log.d(TAG, "Search API call successful with status code: ${response.code()}")
                
                val responseBody = response.body()
                if (responseBody != null) {
                    // Log raw JSON for debugging
                    Log.d(TAG, "Raw search response: ${gson.toJson(responseBody)}")
                    
                    val events = responseBody.events.map { it.toStudyEventMap() }
                    Log.d(TAG, "Search found ${events.size} events")
                    
                    // Log each event for debugging
                    events.forEachIndexed { index, event ->
                        Log.d(TAG, "SearchResult[$index]: id=${event.id}, title=${event.title}, " +
                             "coord=${event.coordinate}, type=${event.eventType}")
                    }
                    
                    emit(Result.success(events))
                } else {
                    Log.e(TAG, "Successful search response but body is null")
                    emit(Result.failure(Exception("API Error: Response body is null")))
                }
            } else {
                Log.e(TAG, "Search API Error: ${response.code()} - ${response.errorBody()?.string()}")
                emit(Result.failure(Exception("API Error: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Search exception: ${e.message}", e)
            emit(Result.failure(e))
        }
    }
    
    /**
     * Get an event by its ID
     */
    fun getEventById(eventId: String): Flow<Result<StudyEventMap>> = flow {
        try {
            Log.d(TAG, "📝 Fetching event by ID: '$eventId'")
            
            // Normalize the input ID (trim and lowercase)
            val normalizedId = eventId.trim().lowercase()
            
            // Get the current username to fetch events visible to this user
            val username = ApiClient.getCurrentUsername() ?: "guest"
            Log.d(TAG, "👤 Fetching events for user: $username")
            
            // Fetch all visible events for the user
            val response = apiService.getUserEvents(username)
            
            if (!response.isSuccessful) {
                Log.e(TAG, "❌ Failed to fetch events: ${response.code()} - ${response.errorBody()?.string()}")
                throw Exception("Failed to fetch events: ${response.code()}")
            }
            
            val responseBody = response.body()
            if (responseBody == null) {
                Log.e(TAG, "❌ Response body was null when fetching events")
                throw Exception("Response body was null when fetching events")
            }
            
            val responseEvents = responseBody.events
            
            // Log total events returned for debugging
            Log.d(TAG, "📊 Retrieved ${responseEvents.size} events from API")
            
            // Log all event IDs for debugging
            val eventIds = responseEvents.map { it.id }
            Log.d(TAG, "🔍 All event IDs in response: $eventIds")
            
            // Direct comparison with normalized IDs
            var matchFound = false
            var matchedEvent: EventResponse? = null
            
            // Try exact match with normalization first
            for (event in responseEvents) {
                val normalizedResponseId = event.id.trim().lowercase()
                Log.d(TAG, "Comparing normalized ID '$normalizedId' with response ID '$normalizedResponseId'")
                
                if (normalizedId == normalizedResponseId) {
                    Log.d(TAG, "✅ Found exact normalized match for ID: $normalizedId")
                    matchFound = true
                    matchedEvent = event
                    break
                }
            }
            
            // If no exact match, try contains or other fuzzier matching
            if (!matchFound) {
                Log.d(TAG, "⚠️ No exact match found, trying alternative matching...")
                
                // If there's only one event in the response, use it as a fallback (common case)
                if (responseEvents.size == 1) {
                    val onlyEvent = responseEvents.first()
                    Log.d(TAG, "⚠️ Only one event in response, using it as fallback. ID: ${onlyEvent.id}")
                    matchedEvent = onlyEvent
                    matchFound = true
                } else {
                    // Try case-insensitive contains match as last resort
                    for (event in responseEvents) {
                        if (event.id.contains(eventId, ignoreCase = true) || 
                            eventId.contains(event.id, ignoreCase = true)) {
                            Log.d(TAG, "⚠️ Found partial match. Requested: $eventId, Found: ${event.id}")
                            matchedEvent = event
                            matchFound = true
                            break
                        }
                    }
                }
            }
            
            if (matchedEvent != null) {
                // Check if user is in the attendees list
                val attendeesList = matchedEvent.attendees ?: emptyList()
                val userIsAttendee = attendeesList.contains(username)
                
                // Create the event with correct attendance flag in one step
                val resultEvent = matchedEvent.toStudyEventMap(isUserAttending = userIsAttendee)
                
                // Verify the event ID matches what we requested
                if (resultEvent.id?.trim()?.lowercase() != normalizedId) {
                    Log.w(TAG, "⚠️ ID mismatch! Requested: $normalizedId, Found: ${resultEvent.id}")
                    
                    // Create a modified event with warning message but keep attendance flag
                    val warningEvent = StudyEventMap(
                        id = resultEvent.id,
                        title = "⚠️ ID MISMATCH: ${resultEvent.title}",
                        coordinate = resultEvent.coordinate,
                        time = resultEvent.time,
                        endTime = resultEvent.endTime,
                        description = "Warning: Event ID mismatch. Requested: $eventId, Found: ${resultEvent.id}\n\n${resultEvent.description ?: ""}",
                        invitedFriends = resultEvent.invitedFriends,
                        attendees = resultEvent.attendees,
                        isPublic = resultEvent.isPublic,
                        host = resultEvent.host,
                        hostIsCertified = resultEvent.hostIsCertified,
                        eventType = resultEvent.eventType,
                        isUserAttending = userIsAttendee
                    )
                    
                    emit(Result.success(warningEvent))
                } else {
                    emit(Result.success(resultEvent))
                }
            } else {
                Log.e(TAG, "❌ Event with ID '$eventId' not found in list of ${responseEvents.size} events")
                
                // Create a placeholder error event
                val errorEvent = StudyEventMap(
                    id = eventId,
                    title = "Error: Event Not Found",
                    description = "The event with ID $eventId could not be found. This could be due to:\n" +
                            "- The event was recently deleted\n" +
                            "- You don't have permission to view this event\n" +
                            "- There was an error with the server",
                    coordinate = Pair(0.0, 0.0),
                    time = LocalDateTime.now(),
                    endTime = LocalDateTime.now(),
                    isPublic = true,
                    host = username,
                    hostIsCertified = false,
                    eventType = EventType.OTHER,
                    invitedFriends = emptyList(),
                    attendees = 0
                )
                
                emit(Result.success(errorEvent))
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception while fetching event by ID: ${e.message}", e)
            emit(Result.failure(e))
        }
    }.flowOn(Dispatchers.IO)
    
    /**
     * Create a new event
     */
    fun createEvent(event: StudyEventMap): Flow<Result<StudyEventMap>> = flow {
        try {
            // Get the current username for the host
            val username = ApiClient.getCurrentUsername()
            Log.d(TAG, "Creating new event: ${event.title} with logged-in user: $username")
            
            // Check if we have all required information
            if (username == null) {
                Log.e(TAG, "❌ Cannot create event: No username available from ApiClient")
                emit(Result.failure(Exception("User not logged in")))
                return@flow
            }
            
            if (event.title.isBlank()) {
                Log.e(TAG, "❌ Cannot create event: Title is blank")
                emit(Result.failure(Exception("Event title is required")))
                return@flow
            }
            
            if (event.coordinate == null) {
                Log.e(TAG, "❌ Cannot create event: No location coordinates provided")
                emit(Result.failure(Exception("Event location is required")))
                return@flow
            }
            
            // Check if host is blank, if so, use the logged in username
            if (event.host.isBlank()) {
                Log.e(TAG, "❌ Host field is blank, falling back to logged-in username: $username")
            }
            
            // Create the API request
            Log.d(TAG, "Creating event with host: ${event.host}, logged-in user: $username")
            val createRequest = EventCreateRequest.fromStudyEventMap(event, username)
            
            // Log the request details for debugging
            Log.d(TAG, "Making API call to create event with request: ${gson.toJson(createRequest)}")
            
            // Debug information about the API endpoint
            val apiServiceClass = apiService::class.java
            val createEventMethod = apiServiceClass.methods.find { it.name == "createEvent" }
            val annotations = createEventMethod?.annotations ?: emptyArray()
            val postAnnotation = annotations.find { it is retrofit2.http.POST } as? retrofit2.http.POST
            val endpoint = postAnnotation?.value
            
            Log.d(TAG, "📡 API endpoint URL: ${ApiClient.getBaseUrl()}${endpoint}")
            
            // Make the API call
            val response = apiService.createEvent(createRequest)
            
            if (response.isSuccessful) {
                Log.d(TAG, "API call successful with status code: ${response.code()}")
                
                val responseBody = response.body()
                if (responseBody != null) {
                    try {
                        // Log the response for debugging
                        Log.d(TAG, "Raw API response: ${gson.toJson(responseBody)}")
                        
                        // Log the fields that might cause NullPointerException
                        Log.d(TAG, "Response attendees: ${responseBody.attendees ?: "null"}")
                        Log.d(TAG, "Response invitedFriends: ${responseBody.invitedFriends ?: "null"}")
                        
                        // Convert the response to our domain model
                        val createdEvent = responseBody.toStudyEventMap()
                        
                        Log.d(TAG, "✅ Successfully created event with ID: ${createdEvent.id}")
                        
                        // Create a new StudyEventMap with the correct ID from the backend
                        // This ensures we're working with the exact ID the server created
                        val finalEvent = StudyEventMap(
                            id = createdEvent.id,  // This is the ID from the server
                            title = createdEvent.title,
                            coordinate = createdEvent.coordinate,
                            time = createdEvent.time,
                            endTime = createdEvent.endTime,
                            description = createdEvent.description,
                            invitedFriends = createdEvent.invitedFriends,
                            attendees = createdEvent.attendees,
                            isPublic = createdEvent.isPublic,
                            host = createdEvent.host,
                            hostIsCertified = createdEvent.hostIsCertified,
                            eventType = createdEvent.eventType
                        )
                        
                        emit(Result.success(finalEvent))
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Exception processing response: ${e.message}", e)
                        Log.e(TAG, "❌ Response was: ${gson.toJson(responseBody)}")
                        // Still return a success with the original event as a fallback
                        emit(Result.success(event))
                    }
                } else {
                    Log.e(TAG, "Successful response but body is null")
                    emit(Result.success(event)) // Return the original event as fallback
                }
            } else {
                val errorBody = response.errorBody()?.string()
                Log.e(TAG, "❌ API Error when creating event: ${response.code()} - $errorBody")
                Log.e(TAG, "❌ Request body was: ${gson.toJson(createRequest)}")
                Log.e(TAG, "❌ Request URL was: ${response.raw().request.url}")
                Log.e(TAG, "❌ Request method was: ${response.raw().request.method}")
                
                // If we failed to create the event on the server, still return the local event
                // but log the error for debugging
                emit(Result.success(event))
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception while creating event: ${e.message}", e)
            emit(Result.failure(e))
        }
    }.flowOn(Dispatchers.IO)

    /**
     * Helper function to create a placeholder event for error cases
     */
    private fun createPlaceholderEvent(eventId: String, errorMessage: String): StudyEventMap {
        return StudyEventMap(
            id = eventId,
            title = "Error: $errorMessage",
            description = "There was an error loading this event. Please try again later.",
            host = "System",
            coordinate = Pair(0.0, 0.0),
            eventType = EventType.OTHER,
            attendees = 0,
            isPublic = true,
            time = LocalDateTime.now(),
            endTime = LocalDateTime.now().plusHours(1)
        )
    }

    /**
     * Auto-match users to an event based on interests, skills, and availability
     * 
     * @param eventId ID of the event to find matches for
     * @return Flow with Result containing map of usernames to match scores
     */
    fun autoMatchEvent(eventId: String): Flow<Result<Map<String, Double>>> = flow {
        try {
            Log.d(TAG, "Requesting auto-matching for event: $eventId")
            
            // Prepare the request body
            val requestBody = mapOf(
                "event_id" to eventId,
                "mark_as_auto_matched" to true  // Explicitly tag these invitations as auto-matched
            )
            
            Log.d(TAG, "Auto-match request body: $requestBody")
            Log.d(TAG, "API Base URL: ${ApiClient.getBaseUrl()}")
            Log.d(TAG, "Endpoint: auto_match_event/")
            
            // Call the API endpoint
            val response = apiService.autoMatchEvent(requestBody)
            
            if (response.isSuccessful) {
                val responseBody = response.body()
                if (responseBody != null) {
                    // Extract the matched_users map from the response
                    @Suppress("UNCHECKED_CAST")
                    val matchedUsers = responseBody["matched_users"] as? Map<String, Double>
                        ?: emptyMap()
                    
                    // Process the results
                    val matchCount = matchedUsers.size
                    Log.d(TAG, "✅ Auto-matching found $matchCount potential users for event $eventId")
                    
                    // Log each matched user and their score
                    matchedUsers.forEach { (username, score) ->
                        Log.d(TAG, "  - Match: $username (score: $score)")
                    }
                    
                    emit(Result.success(matchedUsers))
                } else {
                    Log.e(TAG, "❌ Auto-matching response body was null")
                    emit(Result.failure(Exception("API response body was null")))
                }
            } else {
                val errorBody = response.errorBody()?.string()
                Log.e(TAG, "❌ API Error during auto-matching: ${response.code()} - $errorBody")
                Log.e(TAG, "❌ Request URL: ${response.raw().request.url}")
                Log.e(TAG, "❌ Request method: ${response.raw().request.method}")
                Log.e(TAG, "❌ Request body: $requestBody")
                emit(Result.failure(Exception("API Error: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception during auto-matching: ${e.message}", e)
            emit(Result.failure(e))
        }
    }.flowOn(Dispatchers.IO)

    /**
     * Auto-match users to an event with an enhanced algorithm
     * Uses the advanced auto-matching endpoint that considers multiple factors
     *
     * @param eventId The ID of the event to match users to
     * @param maxInvites Maximum number of users to invite (default 10)
     * @param minScore Minimum score threshold for matches (default 30.0)
     * @return Flow with Result containing the matching results
     */
    fun advancedAutoMatchEvent(
        eventId: String,
        maxInvites: Int = 10,
        minScore: Float = 30.0f
    ): Flow<Result<Map<String, Any>>> = flow {
        try {
            Log.d(TAG, "🔍 Performing advanced auto-matching for event: $eventId")
            Log.d(TAG, "   Max invites: $maxInvites, Min score: $minScore")
            
            val requestBody = mapOf(
                "event_id" to eventId,
                "max_invites" to maxInvites,
                "min_score" to minScore,
                "mark_as_auto_matched" to true  // Ensure these are tagged as auto-matched invitations
            )
            
            val response = apiService.advancedAutoMatch(requestBody)
            
            if (response.isSuccessful) {
                val result = response.body()
                if (result != null) {
                    val matchedUsers = result["matched_users"] as? List<*>
                    val invitesSent = result["invites_sent"] as? Number
                    
                    Log.d(TAG, "✅ Advanced auto-matching successful!")
                    Log.d(TAG, "   Matched users: ${matchedUsers?.size ?: 0}")
                    Log.d(TAG, "   Invites sent: ${invitesSent ?: 0}")
                    
                    emit(Result.success(result))
                } else {
                    Log.e(TAG, "❌ Empty response body from advanced auto-matching")
                    emit(Result.failure(Exception("Empty response from server")))
                }
            } else {
                val errorBody = response.errorBody()?.string()
                Log.e(TAG, "❌ Advanced auto-matching failed: ${response.code()} - $errorBody")
                emit(Result.failure(Exception("Error: ${response.code()} - $errorBody")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception during advanced auto-matching: ${e.message}", e)
            emit(Result.failure(e))
        }
    }

    /**
     * Get potential auto-match users for an event without inviting them
     * This is used to display potential matches in the UI separately from direct invites
     *
     * @param eventId ID of the event to find potential matches for
     * @return Flow with Result containing map of usernames to match scores
     */
    fun getAutoMatchPotentials(eventId: String): Flow<Result<Map<String, Double>>> = flow {
        try {
            Log.d(TAG, "Getting potential auto-matches for event: $eventId")
            
            // Prepare the request body
            val requestBody = mapOf(
                "event_id" to eventId,
                "get_potentials_only" to true  // Don't actually invite users
            )
            
            Log.d(TAG, "Auto-match potentials request body: $requestBody")
            
            // Call the API endpoint
            val response = apiService.autoMatchEvent(requestBody)
            
            if (response.isSuccessful) {
                val responseBody = response.body()
                if (responseBody != null) {
                    // Extract the potential_matches map from the response
                    @Suppress("UNCHECKED_CAST")
                    val potentialMatches = responseBody["potential_matches"] as? Map<String, Double>
                        ?: emptyMap()
                    
                    // Process the results
                    val matchCount = potentialMatches.size
                    Log.d(TAG, "✅ Found $matchCount potential matches for event $eventId")
                    
                    // Log each potential match and their score
                    potentialMatches.forEach { (username, score) ->
                        Log.d(TAG, "  - Potential match: $username (score: $score)")
                    }
                    
                    emit(Result.success(potentialMatches))
                } else {
                    Log.e(TAG, "❌ Auto-matching potentials response body was null")
                    emit(Result.failure(Exception("API response body was null")))
                }
            } else {
                val errorBody = response.errorBody()?.string()
                Log.e(TAG, "❌ API Error during getting auto-match potentials: ${response.code()} - $errorBody")
                emit(Result.failure(Exception("API Error: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception during getting auto-match potentials: ${e.message}", e)
            emit(Result.failure(e))
        }
    }.flowOn(Dispatchers.IO)

    /**
     * Invite a specific user to an event
     *
     * @param eventId ID of the event
     * @param username Username of the user to invite
     * @param isAutoMatched Whether this invitation is being made from auto-matched suggestions
     * @return Flow with Result indicating success or failure
     */
    fun inviteUserToEvent(eventId: String, username: String, isAutoMatched: Boolean = false): Flow<Result<Boolean>> = flow {
        try {
            Log.d(TAG, "Inviting user $username to event $eventId (autoMatched=$isAutoMatched)")
            
            // Prepare the request body
            val requestBody = mapOf(
                "event_id" to eventId,
                "username" to username,
                "mark_as_auto_matched" to isAutoMatched  // Indicate whether this is from auto-matching
            )
            
            // Call the API endpoint
            val response = apiService.inviteUserToEvent(requestBody)
            
            if (response.isSuccessful) {
                Log.d(TAG, "✅ Successfully invited user $username to event $eventId")
                emit(Result.success(true))
            } else {
                val errorBody = response.errorBody()?.string()
                Log.e(TAG, "❌ API Error while inviting user: ${response.code()} - $errorBody")
                emit(Result.failure(Exception("API Error: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception while inviting user: ${e.message}", e)
            emit(Result.failure(e))
        }
    }.flowOn(Dispatchers.IO)

    /**
     * Create a test auto-matched event for debugging purposes
     * This is a helper function to quickly verify potential match display
     */
    fun createTestAutoMatchedEvent(username: String): Flow<Result<StudyEventMap>> = flow {
        try {
            // Generate an event near Buenos Aires
            val buenosAires = Pair(-58.3816, -34.6037)
            // Add small random offset to display separately
            val longitude = buenosAires.first + (Math.random() * 0.01 - 0.005)
            val longitude2dp = (longitude * 10000).toInt() / 10000.0
            val latitude = buenosAires.second + (Math.random() * 0.01 - 0.005)
            val latitude2dp = (latitude * 10000).toInt() / 10000.0
            
            // Create a unique title
            val uniqueId = System.currentTimeMillis() % 10000
            val eventTitle = "Test Auto-Match $uniqueId"
            
            // Create a test event that's explicitly marked as auto-matched
            val testEvent = StudyEventMap(
                id = "test_auto_$uniqueId",
                title = eventTitle,
                coordinate = Pair(longitude2dp, latitude2dp),
                time = java.time.LocalDateTime.now().plusHours(1),
                endTime = java.time.LocalDateTime.now().plusHours(3),
                description = "This is a test auto-matched event to verify the potential matches feature",
                invitedFriends = listOf(username),
                attendees = 2,
                isPublic = false,
                host = "TestHost",
                hostIsCertified = true,
                eventType = EventType.STUDY,
                isUserAttending = false,
                isAutoMatched = true  // Critical flag for potential match
            )
            
            // Log the created test event
            val normalizedId = testEvent.id?.trim()?.lowercase() ?: ""
            if (normalizedId.isNotEmpty()) {
                Log.d(TAG, "✅ Created test auto-matched event: $eventTitle at ($longitude2dp, $latitude2dp)")
            }
            
            emit(Result.success(testEvent))
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error creating test auto-matched event: ${e.message}", e)
            emit(Result.failure(e))
        }
    }

    /**
     * Get invitations for a user including potential matches
     */
    suspend fun getInvitations(username: String): Flow<Result<org.json.JSONObject>> = flow {
        try {
            Log.d(TAG, "🔍 Getting invitations for user: $username")
            val response = apiService.getInvitations(username)
            
            if (response.isSuccessful) {
                val responseBody = response.body()
                if (responseBody != null) {
                    emit(Result.success(responseBody))
                } else {
                    Log.e(TAG, "❌ Invitations response body was null")
                    emit(Result.failure(Exception("Invitations response body was null")))
                }
            } else {
                val errorBody = response.errorBody()?.string()
                Log.e(TAG, "❌ Invitations API Error: ${response.code()} - $errorBody")
                emit(Result.failure(Exception("Invitations API Error: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception getting invitations: ${e.message}", e)
            emit(Result.failure(e))
        }
    }.flowOn(Dispatchers.IO)
} 