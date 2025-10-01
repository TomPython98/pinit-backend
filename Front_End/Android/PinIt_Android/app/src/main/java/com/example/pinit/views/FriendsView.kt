package com.example.pinit.views

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Send
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.pinit.models.ChatManager
import com.example.pinit.models.UserAccountManager
import com.example.pinit.ui.theme.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

// CompositionLocal for UserAccountManager
val LocalUserAccountManager = compositionLocalOf<UserAccountManager> { error("No UserAccountManager provided") }

enum class FriendsTab {
    FRIENDS, REQUESTS, SEARCH
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FriendsView(
    accountManager: UserAccountManager,
    chatManager: ChatManager,
    onDismiss: () -> Unit,
    onChatWithFriend: (String) -> Unit,
    onGeneralChat: () -> Unit
) {
    var selectedTab by remember { mutableStateOf(FriendsTab.FRIENDS) }
    var searchQuery by remember { mutableStateOf("") }
    var searchResults by remember { mutableStateOf<List<String>>(emptyList()) }
    var sentRequests by remember { mutableStateOf<List<String>>(emptyList()) }
    var showAlert by remember { mutableStateOf(false) }
    var alertMessage by remember { mutableStateOf("") }
    var isSearching by remember { mutableStateOf(false) }
    var showSendingIndicator by remember { mutableStateOf(false) }
    var lastRefreshTime by remember { mutableStateOf(System.currentTimeMillis()) }
    val scope = rememberCoroutineScope()
    
    // Function to handle user search
    fun performSearch(query: String) {
        if (query.length < 2) {
            searchResults = emptyList()
            return
        }
        
        isSearching = true
        accountManager.searchUsers(query) { results ->
            searchResults = results
            isSearching = false
        }
    }
    
    // Function to refresh all friend data
    fun refreshFriendData() {
        lastRefreshTime = System.currentTimeMillis()
        
        // Always fetch friends data, regardless of demo mode
        accountManager.fetchFriends()
        
        // Fetch friend requests with callback to track status
        accountManager.fetchFriendRequests { success ->
            if (!success) {
                scope.launch {
                    alertMessage = "Failed to refresh friend requests"
                    showAlert = true
                }
            }
        }
        
        // Get sent requests
        accountManager.fetchSentRequests { requests ->
            sentRequests = requests
        }
    }
    
    // Refresh friends and pending requests when the view is shown
    LaunchedEffect(Unit) {
        refreshFriendData()
    }
    
    // Periodically refresh friend requests (every 10 seconds)
    LaunchedEffect(Unit) {
        while (true) {
            delay(10000) // 10 seconds
            // Only refresh if it's been at least 8 seconds since the last manual refresh
            if (System.currentTimeMillis() - lastRefreshTime > 8000) {
                accountManager.fetchFriendRequests()
                accountManager.fetchSentRequests { requests ->
                    sentRequests = requests
                }
            }
        }
    }
    
    // Debounce search query
    LaunchedEffect(searchQuery) {
        if (searchQuery.isEmpty()) {
            searchResults = emptyList()
            return@LaunchedEffect
        }
        
        delay(300) // Small delay to avoid making too many requests
        performSearch(searchQuery)
    }
    
    // Background brush for social gradient
    val socialGradient = Brush.verticalGradient(
        colors = listOf(SocialLight, SocialAccent)
    )
    
    // Provide the UserAccountManager to descendants
    CompositionLocalProvider(LocalUserAccountManager provides accountManager) {
        ModalBottomSheet(
            onDismissRequest = onDismiss,
            containerColor = BgSurface
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(socialGradient)
                    .padding(bottom = 24.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                ) {
                    // Header view
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(SocialDark, shape = RoundedCornerShape(bottomStart = 25.dp, bottomEnd = 25.dp))
                            .padding(vertical = 16.dp),
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "👥 Friends",
                            style = MaterialTheme.typography.headlineLarge,
                            fontWeight = FontWeight.Bold,
                            color = Color.White,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.weight(1f)
                        )
                        
                        // Refresh button
                        IconButton(
                            onClick = { refreshFriendData() },
                            modifier = Modifier.padding(end = 8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Person, // Use a refresh icon if available
                                contentDescription = "Refresh",
                                tint = Color.White
                            )
                        }
                    }
                    
                    // General Chat Card
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                            .clickable { onGeneralChat() },
                        colors = CardDefaults.cardColors(
                            containerColor = SocialPrimary
                        )
                    ) {
                        Text(
                            text = "💬 General Chat",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = Color.White,
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            textAlign = TextAlign.Center
                        )
                    }
                    
                    // Search bar
                    OutlinedTextField(
                        value = searchQuery,
                        onValueChange = { searchQuery = it },
                        placeholder = { Text("Search for friends...") },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 8.dp),
                        colors = TextFieldDefaults.colors(
                            focusedContainerColor = Color.White.copy(alpha = 0.85f),
                            unfocusedContainerColor = Color.White.copy(alpha = 0.85f),
                            unfocusedIndicatorColor = Color.Transparent,
                            focusedIndicatorColor = Color.Transparent
                        ),
                        shape = RoundedCornerShape(15.dp),
                        leadingIcon = {
                            Icon(
                                imageVector = Icons.Default.Search,
                                contentDescription = "Search"
                            )
                        },
                        trailingIcon = {
                            if (searchQuery.isNotEmpty()) {
                                IconButton(onClick = { searchQuery = "" }) {
                                    Icon(
                                        imageVector = Icons.Default.Close,
                                        contentDescription = "Clear Search"
                                    )
                                }
                            }
                        }
                    )
                    
                    // Content based on search query
                    if (searchQuery.isNotEmpty()) {
                        // Show search results with loading indicator
                        if (isSearching) {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(32.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                CircularProgressIndicator(color = SocialPrimary)
                            }
                        } else {
                            SearchResultsSection(
                                searchResults = searchResults.filter { 
                                    // Additional filtering to ensure we don't show current user or already sent requests
                                    it != accountManager.currentUser &&
                                    !accountManager.friends.contains(it) &&
                                    !accountManager.friendRequests.contains(it) &&
                                    !sentRequests.contains(it)
                                },
                                onSendRequest = { username ->
                                    // Show loading indicator while sending request
                                    showSendingIndicator = true
                                    
                                    // Send the request with a callback
                                    accountManager.sendFriendRequest(username) { success, message ->
                                        showSendingIndicator = false
                                        if (success) {
                                            // Add to sent requests immediately for better UX
                                            sentRequests = sentRequests + username
                                            alertMessage = message
                                        } else {
                                            alertMessage = "Failed to send request: $message"
                                        }
                                        showAlert = true
                                        
                                        // Refresh sent requests list
                                        accountManager.fetchSentRequests { requests ->
                                            sentRequests = requests
                                        }
                                    }
                                },
                                isLoading = showSendingIndicator
                            )
                        }
                    } else {
                        // Show tabs for Friends, Requests, etc.
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp)
                        ) {
                            // Tabs
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(bottom = 16.dp)
                            ) {
                                FriendsTabButton(
                                    title = "Friends",
                                    isSelected = selectedTab == FriendsTab.FRIENDS,
                                    onClick = { selectedTab = FriendsTab.FRIENDS },
                                    modifier = Modifier.weight(1f)
                                )
                                
                                FriendsTabButton(
                                    title = "Requests",
                                    isSelected = selectedTab == FriendsTab.REQUESTS,
                                    onClick = { selectedTab = FriendsTab.REQUESTS },
                                    modifier = Modifier.weight(1f),
                                    badgeCount = accountManager.friendRequests.size
                                )
                                
                                FriendsTabButton(
                                    title = "Sent",
                                    isSelected = selectedTab == FriendsTab.SEARCH,
                                    onClick = { selectedTab = FriendsTab.SEARCH },
                                    modifier = Modifier.weight(1f),
                                    badgeCount = sentRequests.size
                                )
                            }
                            
                            // Content based on selected tab
                            when (selectedTab) {
                                FriendsTab.FRIENDS -> FriendsListSection(
                                    friends = accountManager.friends,
                                    onChatClick = onChatWithFriend
                                )
                                
                                FriendsTab.REQUESTS -> FriendRequestsSection(
                                    requests = accountManager.friendRequests,
                                    onAccept = { from ->
                                        accountManager.acceptFriendRequest(from)
                                        scope.launch {
                                            alertMessage = "You are now friends with $from!"
                                            showAlert = true
                                            
                                            // Immediately update the UI state locally
                                            val updatedRequests = accountManager.friendRequests.filter { it != from }
                                            accountManager.friendRequests = updatedRequests
                                            
                                            // Add to friends list if not already there
                                            if (!accountManager.friends.contains(from)) {
                                                accountManager.friends = accountManager.friends + from
                                            }
                                            
                                            // Force refresh friend data after a short delay
                                            delay(1000)
                                            refreshFriendData()
                                        }
                                    },
                                    onDecline = { from ->
                                        // Remove from UI immediately
                                        accountManager.declineFriendRequest(from)
                                        scope.launch {
                                            alertMessage = "Declined request from $from."
                                            showAlert = true
                                        }
                                    }
                                )
                                
                                FriendsTab.SEARCH -> SentRequestsSection(
                                    requests = sentRequests
                                )
                            }
                        }
                    }
                }
            }
            
            // Alert dialog
            if (showAlert) {
                AlertDialog(
                    onDismissRequest = { showAlert = false },
                    title = { Text("Friend Request") },
                    text = { Text(alertMessage) },
                    confirmButton = {
                        TextButton(onClick = { showAlert = false }) {
                            Text("OK")
                        }
                    }
                )
            }
        }
    } // End of CompositionLocalProvider
}

@Composable
fun FriendsTabButton(
    title: String,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    badgeCount: Int = 0
) {
    Box(
        modifier = modifier
            .padding(horizontal = 4.dp)
            .height(40.dp)
            .background(
                color = if (isSelected) SocialPrimary else Color.White.copy(alpha = 0.7f),
                shape = RoundedCornerShape(20.dp)
            )
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                color = if (isSelected) Color.White else SocialDark
            )
            
            // Show badge if count is greater than 0
            if (badgeCount > 0) {
                Box(
                    modifier = Modifier
                        .padding(start = 4.dp)
                        .size(18.dp)
                        .background(
                            color = if (isSelected) Color.White else BrandWarning,
                            shape = CircleShape
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = badgeCount.toString(),
                        style = MaterialTheme.typography.bodySmall,
                        color = if (isSelected) SocialPrimary else Color.White,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

@Composable
fun FriendsListSection(
    friends: List<String>,
    onChatClick: (String) -> Unit
) {
    SectionCard(title = "Chat with your Friends") {
        if (friends.isEmpty()) {
            EmptyStateMessage("No friends yet")
        } else {
            LazyColumn {
                items(friends) { friend ->
                    FriendItem(
                        username = friend,
                        onChatClick = { onChatClick(friend) }
                    )
                    HorizontalDivider(
                        modifier = Modifier.padding(vertical = 8.dp),
                        color = Divider.copy(alpha = 0.5f)
                    )
                }
            }
        }
    }
}

@Composable
fun FriendRequestsSection(
    requests: List<String>,
    onAccept: (String) -> Unit,
    onDecline: (String) -> Unit
) {
    SectionCard(title = "Pending Requests") {
        if (requests.isEmpty()) {
            EmptyStateMessage("No pending friend requests")
        } else {
            LazyColumn {
                items(requests) { request ->
                    FriendRequestItem(
                        username = request,
                        onAccept = { onAccept(request) },
                        onDecline = { onDecline(request) }
                    )
                    HorizontalDivider(
                        modifier = Modifier.padding(vertical = 8.dp),
                        color = Divider.copy(alpha = 0.5f)
                    )
                }
            }
        }
    }
}

@Composable
fun SentRequestsSection(
    requests: List<String>
) {
    SectionCard(title = "Sent Requests") {
        if (requests.isEmpty()) {
            EmptyStateMessage("No sent friend requests")
        } else {
            LazyColumn {
                items(requests) { request ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Avatar placeholder (circle)
                        UserAvatar(username = request, tint = SocialPrimary)
                        
                        // Username
                        Text(
                            text = request,
                            style = MaterialTheme.typography.bodyLarge,
                            modifier = Modifier
                                .padding(start = 12.dp)
                                .weight(1f)
                        )
                        
                        // Pending text
                        Text(
                            text = "Pending",
                            style = MaterialTheme.typography.bodySmall,
                            color = TextMuted
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun SearchResultsSection(
    searchResults: List<String>,
    onSendRequest: (String) -> Unit,
    isLoading: Boolean = false
) {
    var showDiagnosticDialog by remember { mutableStateOf(false) }
    var diagnosticTarget by remember { mutableStateOf("") }
    var diagnosticResult by remember { mutableStateOf("") }
    var isDiagnosing by remember { mutableStateOf(false) }
    
    SectionCard(title = "Search Results") {
        if (searchResults.isEmpty()) {
            EmptyStateMessage("No users found")
        } else {
            LazyColumn {
                items(searchResults) { user ->
                    Column {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            // Avatar placeholder (circle)
                            UserAvatar(username = user, tint = SocialPrimary)
                            
                            // Username
                            Text(
                                text = user,
                                style = MaterialTheme.typography.bodyLarge,
                                modifier = Modifier
                                    .padding(start = 12.dp)
                                    .weight(1f)
                            )
                            
                            // Add button
                            Button(
                                onClick = { onSendRequest(user) },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = SocialPrimary
                                ),
                                enabled = !isLoading
                            ) {
                                if (isLoading) {
                                    CircularProgressIndicator(
                                        modifier = Modifier.size(16.dp),
                                        color = Color.White,
                                        strokeWidth = 2.dp
                                    )
                                } else {
                                    Text("Add")
                                }
                            }
                            
                            // Diagnostic button (hidden by default)
                            IconButton(
                                onClick = {
                                    diagnosticTarget = user
                                    showDiagnosticDialog = true 
                                },
                                modifier = Modifier.size(40.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Search,
                                    contentDescription = "Diagnose",
                                    tint = Color.Gray
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Diagnostic Dialog
    if (showDiagnosticDialog) {
        AlertDialog(
            onDismissRequest = { showDiagnosticDialog = false },
            title = { Text("API Diagnostics") },
            text = {
                Column {
                    if (isDiagnosing) {
                        CircularProgressIndicator(
                            modifier = Modifier.align(Alignment.CenterHorizontally)
                        )
                        Text("Testing API endpoints for user $diagnosticTarget...")
                    } else if (diagnosticResult.isNotEmpty()) {
                        Text("Results for $diagnosticTarget:")
                        val scrollState = rememberScrollState()
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(300.dp)
                                .background(Color.LightGray.copy(alpha = 0.3f))
                                .padding(8.dp)
                                .verticalScroll(scrollState)
                        ) {
                            Text(diagnosticResult)
                        }
                    } else {
                        Text("Run diagnostic test for friend request to user: $diagnosticTarget?")
                    }
                }
            },
            confirmButton = {
                if (diagnosticResult.isEmpty()) {
                    val userAccountManager = LocalUserAccountManager.current
                    Button(
                        onClick = {
                            isDiagnosing = true
                            userAccountManager.testFriendRequestAPI(
                                userAccountManager.currentUser ?: "unknown",
                                diagnosticTarget
                            ) { result ->
                                isDiagnosing = false
                                diagnosticResult = result
                            }
                        },
                        enabled = !isDiagnosing
                    ) {
                        Text("Run Test")
                    }
                } else {
                    TextButton(onClick = { showDiagnosticDialog = false }) {
                        Text("Close")
                    }
                }
            },
            dismissButton = {
                if (diagnosticResult.isEmpty()) {
                    TextButton(onClick = { showDiagnosticDialog = false }) {
                        Text("Cancel")
                    }
                } else {
                    TextButton(
                        onClick = {
                            diagnosticResult = ""
                            isDiagnosing = false
                        }
                    ) {
                        Text("Reset")
                    }
                }
            }
        )
    }
}

@Composable
fun SectionCard(title: String, content: @Composable () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color.White.copy(alpha = 0.85f)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
        ) {
            // Section title
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = Color.White,
                modifier = Modifier
                    .fillMaxWidth()
                    .background(SocialMedium)
                    .padding(vertical = 8.dp, horizontal = 16.dp)
            )
            
            // Section content
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                content()
            }
        }
    }
}

@Composable
fun FriendItem(
    username: String,
    onChatClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Avatar placeholder (circle)
        UserAvatar(username = username)
        
        // Username
        Text(
            text = username,
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier
                .padding(start = 12.dp)
                .weight(1f)
        )
        
        // Chat button
        Button(
            onClick = onChatClick,
            colors = ButtonDefaults.buttonColors(
                containerColor = SocialPrimary
            ),
            modifier = Modifier.padding(start = 8.dp)
        ) {
            Text("Chat")
        }
    }
}

@Composable
fun UserAvatar(username: String, tint: Color = SocialPrimary) {
    Box(
        modifier = Modifier
            .size(40.dp)
            .background(color = tint.copy(alpha = 0.2f), shape = CircleShape),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = username.firstOrNull()?.toString()?.uppercase() ?: "?",
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.Bold,
            color = tint
        )
    }
}

@Composable
fun FriendRequestItem(
    username: String,
    onAccept: () -> Unit,
    onDecline: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Avatar placeholder (circle)
        UserAvatar(username = username, tint = BrandWarning)
        
        // Username
        Text(
            text = username,
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier
                .padding(start = 12.dp)
                .weight(1f)
        )
        
        // Action buttons
        Row(
            modifier = Modifier.padding(start = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Accept button
            Button(
                onClick = onAccept,
                colors = ButtonDefaults.buttonColors(
                    containerColor = BrandSuccess
                )
            ) {
                Text("Accept")
            }
            
            // Decline button
            OutlinedButton(
                onClick = onDecline
            ) {
                Text("Decline")
            }
        }
    }
}

@Composable
fun EmptyStateMessage(message: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(32.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = message,
            style = MaterialTheme.typography.bodyMedium,
            color = TextMuted,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(16.dp)
        )
    }
} 