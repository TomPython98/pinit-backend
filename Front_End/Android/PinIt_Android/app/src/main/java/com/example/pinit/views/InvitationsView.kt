package com.example.pinit.views

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.clickable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Event
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.pinit.models.*
import com.example.pinit.ui.theme.*
import kotlinx.coroutines.delay
import org.json.JSONObject
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.*

/**
 * Screen that displays the user's pending event invitations
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InvitationsView(
    accountManager: UserAccountManager,
    calendarManager: CalendarManager,
    onDismiss: () -> Unit
) {
    // State variables
    var directInvitations by remember { mutableStateOf<List<Invitation>>(emptyList()) }
    var potentialMatches by remember { mutableStateOf<List<Invitation>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var showAlert by remember { mutableStateOf(false) }
    var alertMessage by remember { mutableStateOf("") }
    
    // UI state for expandable sections
    var expandedSection by remember { mutableStateOf<String?>("direct") } // Default to direct invites expanded
    
    // Function to fetch invitations - now separates direct and potential auto-matched invitations
    val fetchInvitations = {
        isLoading = true
        errorMessage = null
        val username = accountManager.currentUser
        
        // Debug demo data if needed
        if (username == null) {
            isLoading = false
            errorMessage = "User not logged in"
        } else {
            // Make API request to fetch invitations
            // First try with the standard endpoint
            accountManager.makeApiRequest(
                endpoint = "get_invitations/$username/",
                method = "GET",
                onSuccess = { response ->
                    try {
                        // Log the raw response for debugging
                        println("📊 Raw invitation response: $response")
                        
                        val jsonResponse = JSONObject(response)
                        val invitationsArray = jsonResponse.getJSONArray("invitations")
                        println("✅ Found ${invitationsArray.length()} invitations in the response")
                        
                        // Parse invitations
                        val directList = mutableListOf<Invitation>()
                        val potentialList = mutableListOf<Invitation>()
                        
                        for (i in 0 until invitationsArray.length()) {
                            val eventJson = invitationsArray.getJSONObject(i)
                            
                            // Debug: Print available JSON keys
                            println("🔑 Event ${i+1} JSON keys: ${eventJson.keys().asSequence().toList()}")
                            
                            // Parse basic event info
                            val id = UUID.fromString(eventJson.getString("id"))
                            val title = eventJson.getString("title")
                            val host = eventJson.getString("host")
                            println("📝 Parsing event: id=$id, title=$title, host=$host")
                            
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
                            
                            // Use "invitedFriends" to match the Django response
                            // Support multiple possible field names for compatibility
                            val invitedArray = when {
                                eventJson.has("invitedFriends") -> eventJson.getJSONArray("invitedFriends")
                                eventJson.has("invited_friends") -> eventJson.getJSONArray("invited_friends")
                                eventJson.has("invited") -> eventJson.getJSONArray("invited")
                                else -> JSONObject().getJSONArray("[]") // Empty array fallback
                            }
                            
                            println("👥 Invited friends array length: ${invitedArray.length()}")
                            for (j in 0 until invitedArray.length()) {
                                invitedFriends.add(invitedArray.getString(j))
                            }
                            
                            val attendeesArray = when {
                                eventJson.has("attendees") -> eventJson.getJSONArray("attendees")
                                eventJson.has("participants") -> eventJson.getJSONArray("participants")
                                else -> JSONObject().getJSONArray("[]") // Empty array fallback
                            }
                            
                            println("👥 Attendees array length: ${attendeesArray.length()}")
                            for (j in 0 until attendeesArray.length()) {
                                attendees.add(attendeesArray.getString(j))
                            }
                            
                            // Get description and host certification status
                            val hostIsCertified = eventJson.optBoolean("hostIsCertified", false)
                            val isPublic = eventJson.optBoolean("isPublic", false)
                            val eventType = eventJson.optString("eventType", "study")
                            
                            // Check if this is an auto-match invitation or direct invitation
                            val isAutoMatched = eventJson.optBoolean("isAutoMatched", false)
                            
                            println("📅 Creating StudyEvent with type=$eventType, public=$isPublic, certified=$hostIsCertified, autoMatched=$isAutoMatched")
                            
                            // Create event
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
                            
                            // Create invitation and check if the current user is invited but not attending
                            val invitation = Invitation(id = id, event = studyEvent, currentUser = username)
                            if (invitation.isPending) {
                                println("✅ Adding pending invitation for event: $title (autoMatched=$isAutoMatched)")
                                if (isAutoMatched) {
                                    potentialList.add(invitation)
                                    
                                    // Register as potential match in the registry
                                    id?.let { eventId -> 
                                        com.example.pinit.utils.PotentialMatchRegistry.registerPotentialMatch(eventId.toString())
                                        println("🔍 Registered potential match in registry: $eventId (${studyEvent.title})")
                                    }
                                } else {
                                    directList.add(invitation)
                                }
                            } else {
                                println("❌ Invitation not pending for event: $title")
                            }
                        }
                        
                        // Update state
                        directInvitations = directList
                        potentialMatches = potentialList
                        isLoading = false
                        println("✅ Fetched ${directList.size} direct invitations and ${potentialList.size} potential matches")
                    } catch (e: Exception) {
                        println("❌ Error parsing invitations: ${e.message}")
                        e.printStackTrace()
                        
                        // Try the alternate endpoint for invitations
                        accountManager.makeApiRequest(
                            endpoint = "get_event_invitations/$username/",
                            method = "GET",
                            onSuccess = { alternateResponse ->
                                try {
                                    println("🔄 Trying alternate endpoint, raw response: $alternateResponse")
                                    val jsonResponse = JSONObject(alternateResponse)
                                    val invitationsArray = when {
                                        jsonResponse.has("invitations") -> jsonResponse.getJSONArray("invitations")
                                        jsonResponse.has("events") -> jsonResponse.getJSONArray("events")
                                        else -> JSONObject().getJSONArray("[]") // Empty array fallback
                                    }
                                    
                                    val directList = mutableListOf<Invitation>()
                                    for (i in 0 until invitationsArray.length()) {
                                        val eventJson = invitationsArray.getJSONObject(i)
                                        
                                        // Try to parse with more relaxed error handling
                                        try {
                                            val id = UUID.fromString(eventJson.getString("id"))
                                            val title = eventJson.getString("title")
                                            val host = eventJson.getString("host")
                                            val timeStr = eventJson.getString("time")
                                            val time = LocalDateTime.parse(timeStr, DateTimeFormatter.ISO_DATE_TIME)
                                            
                                            // Create a basic event with all required fields
                                            val studyEvent = StudyEvent(
                                                id = id,
                                                title = title,
                                                time = time,
                                                host = host,
                                                invitedFriends = listOf(username)
                                            )
                                            
                                            val invitation = Invitation(id = id, event = studyEvent, currentUser = username)
                                            directList.add(invitation)
                                        } catch (e: Exception) {
                                            println("⚠️ Error parsing individual invitation: ${e.message}")
                                        }
                                    }
                                    
                                    directInvitations = directList
                                    potentialMatches = emptyList() // No potentials from alternate endpoint
                                    isLoading = false
                                    errorMessage = null
                                    println("✅ Fetched ${directList.size} invitations from alternate endpoint")
                                } catch (e: Exception) {
                                    println("❌ Error parsing alternate invitations: ${e.message}")
                                    isLoading = false
                                    errorMessage = "Error loading invitations. Please try again later."
                                }
                            },
                            onError = { alternateError ->
                                println("❌ Error with alternate endpoint: $alternateError")
                                isLoading = false
                                errorMessage = "Failed to load invitations: ${e.message}\nPlease check server connection."
                            }
                        )
                    }
                },
                onError = { error ->
                    println("❌ [InvitationsView] Error fetching invitations: $error")
                    isLoading = false
                    errorMessage = "Failed to load invitations: $error\nPlease check server connection."
                }
            )
        }
    }
    
    // Function to accept an invitation
    val acceptInvitation = { invitation: Invitation ->
        isLoading = true
        val username = accountManager.currentUser
        
        if (username != null) {
            val requestBody = mapOf(
                "username" to username,
                "event_id" to invitation.event.id.toString()
            )
            
            accountManager.makeApiRequest(
                endpoint = "rsvp_study_event/",
                method = "POST",
                body = requestBody,
                onSuccess = { response ->
                    isLoading = false
                    
                    // Create updated event with current user in attendees
                    val updatedEvent = invitation.event.copy(
                        attendees = invitation.event.attendees + username
                    )
                    
                    // Add event to calendar manager
                    calendarManager.addEvent(updatedEvent)
                    
                    // Update UI - remove from appropriate list
                    if (potentialMatches.any { it.id == invitation.id }) {
                        potentialMatches = potentialMatches.filter { it.id != invitation.id }
                    } else {
                        directInvitations = directInvitations.filter { it.id != invitation.id }
                    }
                    
                    alertMessage = "You've accepted the invitation to ${invitation.event.title}"
                    showAlert = true
                    
                    // Refresh calendar events
                    calendarManager.fetchEvents()
                },
                onError = { error ->
                    isLoading = false
                    alertMessage = "Failed to accept invitation: $error"
                    showAlert = true
                }
            )
        } else {
            isLoading = false
            alertMessage = "You need to be logged in to accept invitations"
            showAlert = true
        }
    }
    
    // Function to decline an invitation
    val declineInvitation = { invitation: Invitation ->
        isLoading = true
        val username = accountManager.currentUser
        
        if (username != null) {
            val requestBody = mapOf(
                "username" to username,
                "event_id" to invitation.event.id.toString()
            )
            
            accountManager.makeApiRequest(
                endpoint = "decline_invitation/",
                method = "POST",
                body = requestBody,
                onSuccess = { response ->
                    isLoading = false
                    
                    // Remove from appropriate invitations list
                    if (potentialMatches.any { it.id == invitation.id }) {
                        potentialMatches = potentialMatches.filter { it.id != invitation.id }
                    } else {
                        directInvitations = directInvitations.filter { it.id != invitation.id }
                    }
                    
                    alertMessage = "You've declined the invitation to ${invitation.event.title}"
                    showAlert = true
                },
                onError = { error ->
                    isLoading = false
                    alertMessage = "Failed to decline invitation: $error"
                    showAlert = true
                }
            )
        } else {
            isLoading = false
            alertMessage = "You need to be logged in to decline invitations"
            showAlert = true
        }
    }
    
    // Fetch invitations when view appears
    LaunchedEffect(Unit) {
        fetchInvitations()
    }
    
    // UI
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = BgSurface
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Invitations",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = TextPrimary,
                modifier = Modifier.padding(vertical = 16.dp)
            )
            
            // Show loading indicator
            if (isLoading) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(200.dp),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }
            // Show error if any
            else if (errorMessage != null) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = errorMessage ?: "Unknown error",
                            color = MaterialTheme.colorScheme.error,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }
            // Show empty state
            else if (directInvitations.isEmpty() && potentialMatches.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(200.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Event,
                            contentDescription = "No invitations",
                            tint = TextMuted,
                            modifier = Modifier.size(48.dp)
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "No pending invitations",
                            color = TextMuted
                        )
                    }
                }
            }
            // Show direct invitations and potential matches in separate sections
            else {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                ) {
                    // Direct Invitations Section Header
                    Surface(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { 
                                expandedSection = if (expandedSection == "direct") null else "direct" 
                            },
                        color = MaterialTheme.colorScheme.surfaceVariant,
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.Person,
                                contentDescription = "Direct Invitations",
                                tint = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Direct Invitations",
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.weight(1f))
                            Text(
                                text = "${directInvitations.size}",
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Icon(
                                if (expandedSection == "direct") Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                                contentDescription = "Expand",
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                    
                    // Direct Invitations List
                    if (expandedSection == "direct") {
                        if (directInvitations.isEmpty()) {
                            Text(
                                text = "No direct invitations",
                                fontStyle = FontStyle.Italic,
                                color = TextMuted,
                                modifier = Modifier.padding(vertical = 8.dp, horizontal = 16.dp)
                            )
                        } else {
                            LazyColumn(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(top = 8.dp)
                            ) {
                                items(directInvitations) { invitation ->
                                    InvitationRow(
                                        invitation = invitation,
                                        onAccept = { acceptInvitation(invitation) },
                                        onDecline = { declineInvitation(invitation) }
                                    )
                                    HorizontalDivider(
                                        modifier = Modifier.padding(vertical = 8.dp),
                                        color = Divider
                                    )
                                }
                            }
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // Potential Matches Section Header
                    Surface(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { 
                                expandedSection = if (expandedSection == "potential") null else "potential" 
                            },
                        color = Color(0xFFE3F2FD),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.Psychology,
                                contentDescription = "Potential Matches",
                                tint = Color(0xFF1565C0)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Potential Matches",
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF1565C0)
                            )
                            Spacer(modifier = Modifier.weight(1f))
                            Text(
                                text = "${potentialMatches.size}",
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF1565C0)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Icon(
                                if (expandedSection == "potential") Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                                contentDescription = "Expand",
                                tint = Color(0xFF1565C0)
                            )
                        }
                    }
                    
                    // Potential Matches List
                    if (expandedSection == "potential") {
                        if (potentialMatches.isEmpty()) {
                            Text(
                                text = "No potential matches",
                                fontStyle = FontStyle.Italic,
                                color = TextMuted,
                                modifier = Modifier.padding(vertical = 8.dp, horizontal = 16.dp)
                            )
                        } else {
                            LazyColumn(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(top = 8.dp)
                            ) {
                                items(potentialMatches) { invitation ->
                                    InvitationRow(
                                        invitation = invitation,
                                        onAccept = { acceptInvitation(invitation) },
                                        onDecline = { declineInvitation(invitation) },
                                        isAutoMatched = true
                                    )
                                    HorizontalDivider(
                                        modifier = Modifier.padding(vertical = 8.dp),
                                        color = Divider
                                    )
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Done button
            Button(
                onClick = onDismiss,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
            ) {
                Text("Close")
            }
        }
        
        // Alert dialog
        if (showAlert) {
            AlertDialog(
                onDismissRequest = { showAlert = false },
                title = { Text("Invitation Update") },
                text = { Text(alertMessage) },
                confirmButton = {
                    TextButton(onClick = { showAlert = false }) {
                        Text("OK")
                    }
                }
            )
        }
    }
}

/**
 * Individual invitation row component
 */
@Composable
fun InvitationRow(
    invitation: Invitation,
    onAccept: () -> Unit,
    onDecline: () -> Unit,
    isAutoMatched: Boolean = false
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isAutoMatched) Color(0xFFE3F2FD) else BgCard
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            // Badge for auto-matched events
            if (isAutoMatched) {
                Surface(
                    shape = RoundedCornerShape(4.dp),
                    color = Color(0xFF1565C0),
                    modifier = Modifier.padding(bottom = 8.dp)
                ) {
                    Text(
                        text = "Auto-Matched",
                        color = Color.White,
                        style = MaterialTheme.typography.bodySmall,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                    )
                }
            }
            
            Text(
                text = invitation.event.title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(4.dp))
            
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = "Host",
                    modifier = Modifier.size(16.dp),
                    tint = TextSecondary
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = "Hosted by ${invitation.event.host}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = TextSecondary
                )
                
                if (invitation.event.hostIsCertified) {
                    Spacer(modifier = Modifier.width(8.dp))
                    Badge(
                        containerColor = BrandPrimary
                    ) {
                        Text(
                            text = "Certified",
                            color = TextLight
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Date formatting
            val formatter = DateTimeFormatter.ofPattern("EEE, MMM d, yyyy 'at' h:mm a")
            Text(
                text = invitation.event.time.format(formatter),
                style = MaterialTheme.typography.bodySmall,
                color = TextMuted
            )
            
            // Description if available
            invitation.event.description?.let { desc ->
                if (desc.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = desc,
                        style = MaterialTheme.typography.bodyMedium,
                        color = TextPrimary
                    )
                }
            }
            
            // Action buttons
            Spacer(modifier = Modifier.height(16.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = onAccept,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = BrandSuccess
                    )
                ) {
                    Text("Accept")
                }
                
                OutlinedButton(
                    onClick = onDecline,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Decline")
                }
            }
        }
    }
} 