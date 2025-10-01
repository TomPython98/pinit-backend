package com.example.pinit.services

import android.content.Context
import android.location.Geocoder
import android.os.Build
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import java.io.IOException
import java.util.Locale
import kotlin.coroutines.resume
import java.time.LocalDateTime
import java.util.UUID
import com.example.pinit.models.EventType
import com.example.pinit.models.StudyEventMap
import com.example.pinit.network.ApiClient
import com.example.pinit.repository.EventRepository

/**
 * Service to handle location searches and geocoding using Android's built-in Geocoder
 * Enables global address search for any location in the world
 */
class LocationSearchService(private val context: Context) {
    private val TAG = "LocationSearchService"
    
    // Pre-defined locations for development purposes
    private val predefinedLocations = listOf(
        // Major landmarks
        LocationSuggestion(
            id = "1",
            name = "Vienna University of Technology",
            address = "Karlsplatz 13, 1040 Wien, Austria",
            coordinates = Pair(16.3699, 48.1986)
        ),
        LocationSuggestion(
            id = "2",
            name = "University of Vienna",
            address = "Universitätsring 1, 1010 Wien, Austria",
            coordinates = Pair(16.3606, 48.2131)
        ),
        LocationSuggestion(
            id = "3",
            name = "Vienna Central Station",
            address = "Am Hauptbahnhof 1, 1100 Wien, Austria",
            coordinates = Pair(16.3759, 48.1848)
        ),
        LocationSuggestion(
            id = "4",
            name = "Schönbrunn Palace",
            address = "Schönbrunner Schloßstraße 47, 1130 Wien, Austria",
            coordinates = Pair(16.3122, 48.1847)
        ),
        LocationSuggestion(
            id = "5",
            name = "Belvedere Palace",
            address = "Prinz Eugen-Straße 27, 1030 Wien, Austria",
            coordinates = Pair(16.3818, 48.1915)
        ),
        LocationSuggestion(
            id = "6",
            name = "St. Stephen's Cathedral",
            address = "Stephansplatz 3, 1010 Wien, Austria",
            coordinates = Pair(16.3731, 48.2086)
        ),
        LocationSuggestion(
            id = "7",
            name = "Vienna State Opera",
            address = "Opernring 2, 1010 Wien, Austria",
            coordinates = Pair(16.3691, 48.2035)
        ),
        
        // Streets and areas
        LocationSuggestion(
            id = "11",
            name = "Mariahilfer Strasse",
            address = "Shopping street, 1060 Wien, Austria",
            coordinates = Pair(16.3520, 48.1982)
        ),
        LocationSuggestion(
            id = "12",
            name = "Kärntner Strasse",
            address = "Pedestrian street, 1010 Wien, Austria",
            coordinates = Pair(16.3699, 48.2053)
        ),
        LocationSuggestion(
            id = "13",
            name = "Graben",
            address = "Famous street, 1010 Wien, Austria",
            coordinates = Pair(16.3700, 48.2090)
        ),
        LocationSuggestion(
            id = "14",
            name = "Schwedenplatz",
            address = "Square in Vienna, 1010 Wien, Austria",
            coordinates = Pair(16.3780, 48.2120)
        ),
        LocationSuggestion(
            id = "15",
            name = "Ringstrasse",
            address = "Circular boulevard, Wien, Austria",
            coordinates = Pair(16.3650, 48.2100)
        ),
        
        // Parks and recreational areas
        LocationSuggestion(
            id = "21",
            name = "Prater Park",
            address = "Large public park, 1020 Wien, Austria",
            coordinates = Pair(16.3961, 48.2162)
        ),
        LocationSuggestion(
            id = "22",
            name = "Stadtpark",
            address = "City Park, 1030 Wien, Austria",
            coordinates = Pair(16.3800, 48.2050)
        ),
        LocationSuggestion(
            id = "23",
            name = "Augarten",
            address = "Baroque park, 1020 Wien, Austria",
            coordinates = Pair(16.3725, 48.2242)
        ),
        
        // Transport hubs
        LocationSuggestion(
            id = "31",
            name = "Vienna International Airport",
            address = "Schwechat, Austria",
            coordinates = Pair(16.5697, 48.1103)
        ),
        LocationSuggestion(
            id = "32",
            name = "Westbahnhof",
            address = "Railway station, 1150 Wien, Austria",
            coordinates = Pair(16.3371, 48.1957)
        ),
        
        // Shopping areas
        LocationSuggestion(
            id = "41",
            name = "Shopping City Süd",
            address = "Vösendorf, Austria",
            coordinates = Pair(16.3211, 48.1086)
        ),
        LocationSuggestion(
            id = "42",
            name = "Donau Zentrum",
            address = "Shopping mall, 1220 Wien, Austria",
            coordinates = Pair(16.4300, 48.2400)
        ),
        
        // Museums
        LocationSuggestion(
            id = "51",
            name = "Kunsthistorisches Museum",
            address = "Maria-Theresien-Platz, 1010 Wien, Austria",
            coordinates = Pair(16.3611, 48.2038)
        ),
        LocationSuggestion(
            id = "52",
            name = "Albertina Museum",
            address = "Albertinaplatz 1, 1010 Wien, Austria",
            coordinates = Pair(16.3681, 48.2044)
        ),
        LocationSuggestion(
            id = "53",
            name = "Leopold Museum",
            address = "MuseumsQuartier, 1070 Wien, Austria",
            coordinates = Pair(16.3593, 48.2033)
        ),
        
        // Restaurants and cafes
        LocationSuggestion(
            id = "61",
            name = "Café Central",
            address = "Herrengasse 14, 1010 Wien, Austria",
            coordinates = Pair(16.3665, 48.2106)
        ),
        LocationSuggestion(
            id = "62",
            name = "Café Sacher",
            address = "Philharmoniker Str. 4, 1010 Wien, Austria",
            coordinates = Pair(16.3694, 48.2038)
        ),
        LocationSuggestion(
            id = "63",
            name = "Figlmüller",
            address = "Wollzeile 5, 1010 Wien, Austria",
            coordinates = Pair(16.3750, 48.2086)
        )
    )
    
    /**
     * Search for location suggestions based on query
     * Uses Geocoder as primary search method with fallback to predefined locations
     * 
     * @param query The search query
     * @return List of location suggestions from anywhere in the world
     */
    suspend fun searchLocations(query: String): List<LocationSuggestion> {
        if (query.isBlank()) {
            return emptyList()
        }
        
        Log.d(TAG, "Searching for locations with query: $query")
        
        // First try to use the Geocoder for worldwide locations
        if (Geocoder.isPresent()) {
            try {
                val geocodedResults = geocodeAddress(query)
                if (geocodedResults.isNotEmpty()) {
                    Log.d(TAG, "Found ${geocodedResults.size} geocoded results for: $query")
                    // If we found geocoded results, return them directly
                    return geocodedResults
                }
                Log.d(TAG, "No geocoded results found for: $query, falling back to predefined locations")
            } catch (e: Exception) {
                Log.e(TAG, "Error during geocoding: ${e.message}", e)
            }
        } else {
            Log.w(TAG, "Geocoder is not present on this device, using predefined locations only")
        }
        
        // If Geocoder failed or returned no results, fall back to predefined locations
        // Split the query terms to allow for more flexible matching
        val queryTerms = query.split(" ", "-", ",").filter { it.isNotBlank() }
        
        // Score and rank locations based on how well they match the query
        val scoredLocations = predefinedLocations.map { location ->
            val nameScore = calculateMatchScore(location.name, queryTerms)
            val addressScore = calculateMatchScore(location.address, queryTerms)
            Triple(location, nameScore, addressScore)
        }
        
        // Filter locations with a positive score and sort by score (descending)
        val filteredLocations = scoredLocations
            .filter { it.second > 0 || it.third > 0 }
            .sortedByDescending { it.second + it.third }
            .take(5) // Limit to top 5 matches
            .map { it.first }
        
        if (filteredLocations.isEmpty()) {
            return fuzzySearchLocations(query)
        }
        
        return filteredLocations
    }
    
    /**
     * Calculate a match score between text and query terms
     */
    private fun calculateMatchScore(text: String, queryTerms: List<String>): Int {
        var score = 0
        val lowerText = text.lowercase()
        
        queryTerms.forEach { term ->
            val lowerTerm = term.lowercase()
            when {
                // Exact match
                lowerText.contains(lowerTerm) -> score += 10
                
                // Partial match at word boundary
                lowerText.split(" ", "-", ",").any { 
                    it.startsWith(lowerTerm) || it.endsWith(lowerTerm) 
                } -> score += 5
                
                // Contains part of term
                lowerText.contains(lowerTerm.take(3)) && lowerTerm.length >= 3 -> score += 2
            }
        }
        
        return score
    }
    
    /**
     * Fuzzy search for locations when exact match fails
     */
    private fun fuzzySearchLocations(query: String): List<LocationSuggestion> {
        // This is a fallback search for when the more precise search doesn't find anything
        val lowerQuery = query.lowercase()
        
        return predefinedLocations.filter { location ->
            location.name.lowercase().contains(lowerQuery.take(3)) || 
            location.address.lowercase().contains(lowerQuery.take(3))
        }.take(3)
    }
    
    /**
     * Get location details by searching for an address
     */
    private suspend fun geocodeAddress(address: String): List<LocationSuggestion> = withContext(Dispatchers.IO) {
        val geocoder = Geocoder(context, Locale.getDefault())
        val results = mutableListOf<LocationSuggestion>()
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                // Use the newer API for Android 13+
                suspendCancellableCoroutine { continuation ->
                    geocoder.getFromLocationName(address, 10) { addresses ->
                        val suggestions = addresses.map { addr ->
                            LocationSuggestion(
                                id = "${addr.latitude},${addr.longitude}",
                                name = createLocationName(addr),
                                address = formatAddress(addr),
                                coordinates = Pair(addr.longitude, addr.latitude)
                            )
                        }
                        results.addAll(suggestions)
                        
                        // Log for debugging
                        Log.d(TAG, "Geocoder returned ${suggestions.size} results")
                        
                        if (!continuation.isCompleted) {
                            continuation.resume(Unit)
                        }
                    }
                }
            } else {
                // Use the older API for older versions
                @Suppress("DEPRECATION")
                val addresses = geocoder.getFromLocationName(address, 10)
                if (addresses != null) {
                    addresses.forEach { addr ->
                        val suggestion = LocationSuggestion(
                            id = "${addr.latitude},${addr.longitude}",
                            name = createLocationName(addr),
                            address = formatAddress(addr),
                            coordinates = Pair(addr.longitude, addr.latitude)
                        )
                        results.add(suggestion)
                    }
                    
                    // Log for debugging
                    Log.d(TAG, "Geocoder returned ${addresses.size} results")
                }
            }
        } catch (e: IOException) {
            Log.e(TAG, "Geocoder failed: ${e.message}", e)
        }
        
        return@withContext results
    }
    
    /**
     * Create a meaningful location name from Address
     */
    private fun createLocationName(address: android.location.Address): String {
        // Try to create the most meaningful name based on available address components
        return when {
            !address.featureName.isNullOrEmpty() && !address.thoroughfare.isNullOrEmpty() && 
                    address.featureName != address.thoroughfare -> 
                "${address.featureName}, ${address.thoroughfare}"
                
            !address.featureName.isNullOrEmpty() -> 
                address.featureName
                
            !address.thoroughfare.isNullOrEmpty() -> 
                address.thoroughfare
                
            !address.locality.isNullOrEmpty() -> 
                address.locality
                
            else -> "Location at ${address.latitude}, ${address.longitude}"
        }
    }
    
    /**
     * Format address from Android Address object
     */
    private fun formatAddress(address: android.location.Address): String {
        val addressLines = mutableListOf<String>()
        
        // Add street number if available
        if (!address.subThoroughfare.isNullOrEmpty()) {
            addressLines.add(address.subThoroughfare)
        }
        
        // Add thoroughfare (street name)
        if (!address.thoroughfare.isNullOrEmpty()) {
            if (addressLines.isEmpty()) {
                addressLines.add(address.thoroughfare)
            } else {
                // Combine street number and name
                addressLines[0] = "${addressLines[0]} ${address.thoroughfare}"
            }
        }
        
        // Add postal code
        if (!address.postalCode.isNullOrEmpty()) {
            addressLines.add(address.postalCode)
        }
        
        // Add locality (city)
        if (!address.locality.isNullOrEmpty()) {
            if (addressLines.isNotEmpty() && !address.postalCode.isNullOrEmpty()) {
                // Combine postal code and city
                addressLines[addressLines.size - 1] = "${addressLines.last()} ${address.locality}"
            } else {
                addressLines.add(address.locality)
            }
        }
        
        // Add admin area (state/province)
        if (!address.adminArea.isNullOrEmpty() && (address.locality.isNullOrEmpty() || address.adminArea != address.locality)) {
            addressLines.add(address.adminArea)
        }
        
        // Add country
        if (!address.countryName.isNullOrEmpty()) {
            addressLines.add(address.countryName)
        }
        
        return addressLines.joinToString(", ")
    }
    
    /**
     * Get details for a selected suggestion
     */
    suspend fun getLocationDetails(suggestion: LocationSuggestion): LocationDetail {
        // For places with predefined coordinates, return immediately
        if (suggestion.coordinates != null) {
            return LocationDetail(
                name = suggestion.name,
                address = suggestion.address,
                coordinates = suggestion.coordinates
            )
        }
        
        // For other cases, try to geocode the address
        return withContext(Dispatchers.IO) {
            try {
                val geocoder = Geocoder(context, Locale.getDefault())
                val addressToSearch = "${suggestion.name}, ${suggestion.address}"
                Log.d(TAG, "Geocoding address: $addressToSearch")
                
                var foundCoordinates: Pair<Double, Double>? = null
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    suspendCancellableCoroutine<Unit> { continuation ->
                        geocoder.getFromLocationName(addressToSearch, 1) { addresses ->
                            if (addresses.isNotEmpty()) {
                                val address = addresses.first()
                                foundCoordinates = Pair(address.longitude, address.latitude)
                                Log.d(TAG, "Successfully geocoded to coordinates: ${address.latitude}, ${address.longitude}")
                            } else {
                                Log.d(TAG, "No results found for geocoding: $addressToSearch")
                            }
                            
                            if (!continuation.isCompleted) {
                                continuation.resume(Unit)
                            }
                        }
                    }
                } else {
                    @Suppress("DEPRECATION")
                    val addresses = geocoder.getFromLocationName(addressToSearch, 1)
                    if (addresses != null && addresses.isNotEmpty()) {
                        val address = addresses.first()
                        foundCoordinates = Pair(address.longitude, address.latitude)
                        Log.d(TAG, "Successfully geocoded to coordinates: ${address.latitude}, ${address.longitude}")
                    } else {
                        Log.d(TAG, "No results found for geocoding: $addressToSearch")
                    }
                }
                
                // Return details with coordinates if found
                if (foundCoordinates != null) {
                    return@withContext LocationDetail(
                        name = suggestion.name,
                        address = suggestion.address,
                        coordinates = foundCoordinates!!
                    )
                }
                
                // If geocoding failed, try a reverse search approach by keywords
                Log.d(TAG, "Attempting keyword-based geocoding as fallback")
                val keywordResults = searchLocations(suggestion.name.split(",")[0])
                if (keywordResults.isNotEmpty() && keywordResults.first().coordinates != null) {
                    val bestMatch = keywordResults.first()
                    Log.d(TAG, "Found fallback coordinates from keyword search: ${bestMatch.coordinates}")
                    return@withContext LocationDetail(
                        name = suggestion.name,
                        address = suggestion.address,
                        coordinates = bestMatch.coordinates!!
                    )
                }
                
                // Last resort fallback to a default location
                Log.w(TAG, "All geocoding attempts failed, using default world coordinates")
                LocationDetail(
                    name = suggestion.name,
                    address = suggestion.address,
                    coordinates = Pair(0.0, 0.0) // International standard prime meridian (0,0)
                )
            } catch (e: Exception) {
                Log.e(TAG, "Error getting location details: ${e.message}", e)
                LocationDetail(
                    name = suggestion.name,
                    address = suggestion.address,
                    coordinates = Pair(0.0, 0.0) // Default to prime meridian
                )
            }
        }
    }
    
    /**
     * Reverse geocode coordinates to get address information
     * Useful for getting location information when only coordinates are available
     */
    suspend fun reverseGeocode(latitude: Double, longitude: Double): LocationDetail? = withContext(Dispatchers.IO) {
        try {
            if (!Geocoder.isPresent()) {
                Log.w(TAG, "Geocoder is not present on this device")
                return@withContext null
            }
            
            val geocoder = Geocoder(context, Locale.getDefault())
            var result: LocationDetail? = null
            
            Log.d(TAG, "Reverse geocoding coordinates: $latitude, $longitude")
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                suspendCancellableCoroutine<Unit> { continuation ->
                    geocoder.getFromLocation(latitude, longitude, 1) { addresses ->
                        if (addresses.isNotEmpty()) {
                            val address = addresses.first()
                            val name = createLocationName(address)
                            val formattedAddress = formatAddress(address)
                            
                            result = LocationDetail(
                                name = name,
                                address = formattedAddress,
                                coordinates = Pair(longitude, latitude)
                            )
                            
                            Log.d(TAG, "Successfully reverse geocoded to: $name, $formattedAddress")
                        } else {
                            Log.d(TAG, "No reverse geocoding results for coordinates: $latitude, $longitude")
                        }
                        
                        if (!continuation.isCompleted) {
                            continuation.resume(Unit)
                        }
                    }
                }
            } else {
                @Suppress("DEPRECATION")
                val addresses = geocoder.getFromLocation(latitude, longitude, 1)
                if (addresses != null && addresses.isNotEmpty()) {
                    val address = addresses.first()
                    val name = createLocationName(address)
                    val formattedAddress = formatAddress(address)
                    
                    result = LocationDetail(
                        name = name,
                        address = formattedAddress,
                        coordinates = Pair(longitude, latitude)
                    )
                    
                    Log.d(TAG, "Successfully reverse geocoded to: $name, $formattedAddress")
                } else {
                    Log.d(TAG, "No reverse geocoding results for coordinates: $latitude, $longitude")
                }
            }
            
            return@withContext result
        } catch (e: Exception) {
            Log.e(TAG, "Error during reverse geocoding: ${e.message}", e)
            return@withContext null
        }
    }

    private suspend fun saveEvent(
        title: String,
        description: String,
        coordinate: Pair<Double, Double>?,
        time: LocalDateTime,
        endTime: LocalDateTime?,
        isPublic: Boolean,
        eventType: EventType,
        invitedFriends: List<String>,
        interestTags: List<String>,
        autoMatchingEnabled: Boolean
    ) {
        try {
            Log.d("EventCreation", "Creating event: $title")
            Log.d("EventCreation", "Invited friends: $invitedFriends")
            Log.d("EventCreation", "Interest tags: $interestTags")
            Log.d("EventCreation", "Auto-matching enabled: $autoMatchingEnabled")
            
            // Create the event map without a pre-generated ID, let the server generate it
            val eventMap = StudyEventMap(
                id = null, // Let the server generate the ID
                title = title,
                description = description,
                coordinate = coordinate,
                time = time,
                endTime = endTime ?: time.plusHours(2),
                host = ApiClient.getCurrentUsername() ?: "unknown",
                isPublic = isPublic,
                eventType = eventType,
                invitedFriends = invitedFriends,
                interestTags = interestTags,
                autoMatchingEnabled = autoMatchingEnabled
            )
            
            val eventRepository = EventRepository()
            
            eventRepository.createEvent(eventMap).collect { result ->
                if (result.isSuccess) {
                    val createdEvent = result.getOrNull()
                    if (createdEvent != null) {
                        val serverEventId = createdEvent.id
                        Log.d("EventCreation", "Event created with server ID: $serverEventId")
                        
                        // No need for client-side auto-matching - it's handled by the backend
                        
                    } else {
                        Log.e("EventCreation", "Created event was null")
                    }
                } else {
                    val exception = result.exceptionOrNull()
                    Log.e("EventCreation", "Error creating event: ${exception?.message}", exception)
                }
            }
        }
        catch (e: Exception) {
            Log.e("EventCreation", "Error in saveEvent: ${e.message}", e)
        }
    }
}

/**
 * Model for location suggestions
 */
data class LocationSuggestion(
    val id: String,
    val name: String,
    val address: String,
    val coordinates: Pair<Double, Double>?
)

/**
 * Model for detailed location information
 */
data class LocationDetail(
    val name: String,
    val address: String,
    val coordinates: Pair<Double, Double>
) 