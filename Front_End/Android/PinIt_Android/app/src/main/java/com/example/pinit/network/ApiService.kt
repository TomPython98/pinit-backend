package com.example.pinit.network

import com.example.pinit.models.ApiEventsResponse
import com.example.pinit.models.AuthResponse
import com.example.pinit.models.EventResponse
import com.example.pinit.models.UserProfileResponse
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query
import com.google.gson.annotations.SerializedName

/**
 * Data class for updating user profile interests and preferences
 */
data class UpdateUserInterestsRequest(
    @SerializedName("username") val username: String,
    @SerializedName("interests") val interests: List<String>,
    @SerializedName("skills") val skills: Map<String, String>,
    @SerializedName("auto_invite_preference") val autoInvitePreference: Boolean,
    @SerializedName("preferred_radius") val preferredRadius: Float,
    // Enhanced profile fields to match iOS
    @SerializedName("full_name") val fullName: String = "",
    @SerializedName("university") val university: String = "",
    @SerializedName("degree") val degree: String = "",
    @SerializedName("year") val year: String = "",
    @SerializedName("bio") val bio: String = ""
)

/**
 * Retrofit API service interface for the PinIt Django backend
 */
interface ApiService {
    
    /**
     * Login user
     */
    @POST("login/")
    suspend fun loginUser(@Body loginRequest: Map<String, String>): Response<AuthResponse>
    
    /**
     * Register user
     */
    @POST("register/")
    suspend fun registerUser(@Body registerRequest: Map<String, String>): Response<AuthResponse>
    
    /**
     * Get study events for a user
     * 
     * This endpoint returns all events that are visible to the specified user, including:
     * - Public events
     * - Events the user is hosting
     * - Private events the user has been invited to
     * 
     * The response includes a list of event objects with their complete details.
     */
    @GET("get_study_events/{username}/")
    suspend fun getStudyEvents(@Path("username") username: String): Response<ApiEventsResponse>
    
    /**
     * Get events for a user - alias for getStudyEvents for better semantics
     * 
     * This provides the same functionality as getStudyEvents but with a clearer name
     * for use in the repository.
     */
    @GET("get_study_events/{username}/")
    suspend fun getUserEvents(@Path("username") username: String): Response<ApiEventsResponse>
    
    /**
     * Get user profile
     */
    @GET("get_user_profile/{username}/")
    suspend fun getUserProfile(@Path("username") username: String): Response<UserProfileResponse>
    
    /**
     * Get profile completion details
     */
    @GET("profile_completion/{username}/")
    suspend fun getProfileCompletion(@Path("username") username: String): Response<com.example.pinit.models.ProfileCompletionResponse>
    
    /**
     * Search events
     */
    @GET("search_events/")
    suspend fun searchEvents(
        @Query("query") query: String,
        @Query("public_only") publicOnly: Boolean = false,
        @Query("certified_only") certifiedOnly: Boolean = false,
        @Query("event_type") eventType: String? = null,
        @Query("semantic") semantic: Boolean = false
    ): Response<ApiEventsResponse>

    /**
     * API endpoint to get a specific event by ID
     * 
     * This endpoint takes a username and event_id parameter.
     * The Django backend filters events by the event_id parameter.
     * 
     * IMPORTANT: This may have reliability issues if the backend doesn't handle
     * the event_id parameter correctly. In cases where this fails, we can fall back
     * to retrieving all events and filtering client-side.
     */
    @GET("get_study_events/{username}/")
    suspend fun getEventById(
        @Path("username") username: String,
        @Query("event_id") eventId: String
    ): Response<ApiEventsResponse>

    /**
     * API endpoint to create a new event
     */
    @POST("create_study_event/")
    suspend fun createEvent(
        @Body eventData: EventCreateRequest
    ): Response<EventResponse>

    @POST("rsvp_study_event/")
    suspend fun rsvpEvent(@Body requestBody: Map<String, String>): Response<Map<String, Any>>

    /**
     * Update user interests and preferences
     */
    @POST("update_user_interests/")
    suspend fun updateUserInterests(@Body request: UpdateUserInterestsRequest): Response<Map<String, Any>>
    
    /**
     * Auto-match users to an event based on interests and skills
     */
    @POST("auto_match_event/")
    suspend fun autoMatchEvent(@Body requestBody: Map<String, Any>): Response<Map<String, Any>>
    
    /**
     * Invite a specific user to an event
     */
    @POST("invite_to_event/")
    suspend fun inviteUserToEvent(@Body requestBody: Map<String, Any>): Response<Map<String, Any>>
    
    /**
     * Advanced auto-matching algorithm that considers multiple factors:
     * - Semantic matching of title and description
     * - Interest overlap
     * - Skills matching
     * - Location proximity
     * - Time availability
     * - Past event attendance patterns
     * - Host-attendee relationship
     */
    @POST("advanced_auto_match/")
    suspend fun advancedAutoMatch(@Body requestBody: Map<String, Any>): Response<Map<String, Any>>

    /**
     * Get user invitations (both direct and auto-matched)
     */
    @GET("get_invitations/{username}/")
    suspend fun getInvitations(@Path("username") username: String): Response<org.json.JSONObject>
} 