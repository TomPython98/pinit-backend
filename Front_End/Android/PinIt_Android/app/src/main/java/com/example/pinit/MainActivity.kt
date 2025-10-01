package com.example.pinit

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material.icons.rounded.*
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.lifecycleScope
import com.example.pinit.components.*
import com.example.pinit.models.ChatManager
import com.example.pinit.models.UserAccountManager
import com.example.pinit.models.WeatherViewModel
import com.example.pinit.ui.theme.*
import com.example.pinit.utils.MapboxHelper
import com.example.pinit.views.*
import kotlinx.coroutines.delay
import java.time.LocalDate
import java.util.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.collectLatest
import org.json.JSONObject
import org.json.JSONArray

class MainActivity : ComponentActivity() {
    private val TAG = "MainActivity"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        
        // Set up global exception handler to prevent crashes
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            Log.e(TAG, "Uncaught exception in thread $thread", throwable)
        }
        
        // Initialize Mapbox early with explicit token setting
        initializeMapbox()
        
        // DEBUG: Test auto-matched event handling - remove in production
        testAutoMatchedEventsHandling()
        
        setContent {
            // Get a reference to the UserAccountManager
            val accountManager: UserAccountManager = viewModel()
            
            // Set the application context for persistence
            accountManager.setAppContext(applicationContext)
            
            // Set the UserAccountManager in ApiClient for authentication
            com.example.pinit.network.ApiClient.setUserAccountManager(accountManager)
            
            // Reset the PotentialMatchRegistry for clean state
            com.example.pinit.utils.PotentialMatchRegistry.resetForUser(accountManager.currentUser)
            
            // Observe user changes and reset the registry when user changes
            var prevUser by remember { mutableStateOf(accountManager.currentUser) }
            LaunchedEffect(accountManager.currentUser) {
                if (prevUser != accountManager.currentUser) {
                    // Clear potential matches when user changes
                    com.example.pinit.utils.PotentialMatchRegistry.resetForUser(accountManager.currentUser)
                    Log.d(TAG, "User changed to ${accountManager.currentUser} - resetting potential matches registry")
                    prevUser = accountManager.currentUser
                }
            }
            
            PinItTheme {
                PinItApp()
            }
        }
    }
    
    /**
     * Initialize Mapbox SDK
     */
    private fun initializeMapbox() {
        try {
            Log.d(TAG, "Initializing Mapbox in MainActivity")
            
            // Get the token
            val mapboxToken = "pk.eyJ1IjoidG9tYmVzaSIsImEiOiJjbTdwNDdvbXAwY3I3MmtzYmZ3dzVtaGJrIn0.yiXVdzVGYjTucLPZPa0hjw"
            
            // IMPORTANT: Set the token DIRECTLY with the correct class for Mapbox v11
            com.mapbox.common.MapboxOptions.accessToken = mapboxToken
            
            // Also use our helper for consistent initialization
            val success = MapboxHelper.initialize(applicationContext)
            
            if (success) {
                Log.d(TAG, "Mapbox initialized successfully in MainActivity with token: ${mapboxToken.take(15)}...")
            } else {
                Log.e(TAG, "Failed to initialize Mapbox in MainActivity")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing Mapbox: ${e.message}", e)
        }
    }
    
    // Debug function to test auto-matched events implementation
    private fun testAutoMatchedEventsHandling() {
        // Comment this out for now until we fix the JSON processing
        /*
        // Run this in a background thread
        lifecycleScope.launch(Dispatchers.IO) {
            try {
                Log.d("MainActivity", "🧪 TESTING AUTO-MATCHED EVENTS HANDLING")
                val repository = com.example.pinit.repository.EventRepository()
                
                // Clear the registry first
                com.example.pinit.utils.PotentialMatchRegistry.clear()
                
                // Get invitations for techuser1
                val invitationsResult = repository.getInvitations("techuser1").first()
                if (invitationsResult.isSuccess) {
                    val responseBody = invitationsResult.getOrNull()
                    if (responseBody != null && responseBody.has("invitations")) {
                        val invitationsArray = responseBody.getJSONArray("invitations")
                        Log.d("MainActivity", "✅ Found ${invitationsArray.length()} invitations for techuser1")
                        
                        // Process each invitation to find auto-matched ones
                        var autoMatchCount = 0
                        for (i in 0 until invitationsArray.length()) {
                            val invitation = invitationsArray.getJSONObject(i)
                            val eventId = invitation.getString("id")
                            val title = invitation.getString("title")
                            val isAutoMatched = invitation.optBoolean("isAutoMatched", false)
                            
                            Log.d("MainActivity", "📩 Invitation: $title (autoMatched=$isAutoMatched)")
                            
                            if (isAutoMatched) {
                                autoMatchCount++
                                // Get coordinates
                                val latitude = invitation.getDouble("latitude")
                                val longitude = invitation.getDouble("longitude")
                                Log.d("MainActivity", "🔍 AUTO-MATCHED INVITATION FOUND: $title")
                                Log.d("MainActivity", "   - ID: $eventId")
                                Log.d("MainActivity", "   - Coordinates: ($longitude, $latitude)")
                                
                                // Register in PotentialMatchRegistry
                                com.example.pinit.utils.PotentialMatchRegistry.registerPotentialMatch(eventId)
                                Log.d("MainActivity", "🔖 Registered in PotentialMatchRegistry")
                            }
                        }
                        
                        Log.d("MainActivity", "📊 SUMMARY: Found $autoMatchCount auto-matched invitations")
                        Log.d("MainActivity", "🔍 PotentialMatchRegistry now has ${com.example.pinit.utils.PotentialMatchRegistry.count()} entries")
                    }
                } else {
                    val error = invitationsResult.exceptionOrNull()
                    Log.e("MainActivity", "❌ Error getting invitations: ${error?.message}", error)
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "❌ Exception in testAutoMatchedEventsHandling: ${e.message}", e)
            }
        }
        */
        
        // Temporary placeholder for testing
        Log.d("MainActivity", "🧪 Auto-matched events testing disabled temporarily")
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PinItApp() {
    // Safe state initialization
    var showLoginView by remember { mutableStateOf(false) }
    var showProfileView by remember { mutableStateOf(false) }
    var showSettingsView by remember { mutableStateOf(false) }
    var showFriendsView by remember { mutableStateOf(false) }
    var showCalendarView by remember { mutableStateOf(false) }
    var showInvitationsView by remember { mutableStateOf(false) }
    var showFlashcardsView by remember { mutableStateOf(false) }
    var showChatView by remember { mutableStateOf(false) }
    var showGeneralChatView by remember { mutableStateOf(false) }
    var showMapView by remember { mutableStateOf(false) }
    var selectedChatFriend by remember { mutableStateOf("") }
    
    // Add a state to control when to show the map
    var showMiniMap by remember { mutableStateOf(false) }
    
    // Initialize ViewModels directly without try-catch
    val accountManager: UserAccountManager = viewModel()
    val weatherViewModel: WeatherViewModel = viewModel()
    
    // Create chat manager
    val chatManager: ChatManager = remember { ChatManager() }
    
    // Create CalendarManager manually (not as viewModel) to avoid type issues
    val calendarManager = remember { com.example.pinit.models.CalendarManager(accountManager) }
    
    // State for welcome animation
    val isAnimating by remember { mutableStateOf(true) }
    
    // Get connection error
    val connectionError = accountManager.connectionErrorMessage
    
    // Update login state
    LaunchedEffect(key1 = accountManager.isLoggedIn) {
        showLoginView = !accountManager.isLoggedIn
    }
    
    // Fetch weather data
    LaunchedEffect(key1 = Unit) {
        weatherViewModel.fetchWeather("Vienna")
    }
    
    // Fetch calendar events when logged in
    LaunchedEffect(key1 = accountManager.isLoggedIn) {
        if (accountManager.isLoggedIn) {
            calendarManager.fetchEvents()
        }
    }
    
    // Delay loading the map to ensure app UI is initialized first
    LaunchedEffect(Unit) {
        // Delay to allow main UI to initialize
        kotlinx.coroutines.delay(500)
        showMiniMap = true
    }
    
    Box(modifier = Modifier.fillMaxSize()) {
        // Background with subtle patterns
        BackgroundWithPatterns(isAnimating = isAnimating)
        
        // Show login view if not logged in
        if (showLoginView) {
            // Use the LoginView from views package
            LoginView(
                accountManager = accountManager,
                onLoginSuccess = { showLoginView = false },
                onRegisterClick = { /* Handle register here */ }
            )
        } else {
            // Main content when logged in
            Column(modifier = Modifier.fillMaxSize()) {
                // Custom top bar
                CustomTopBar(
                    onProfileClick = { showProfileView = true },
                    onSettingsClick = { showSettingsView = true },
                    userName = accountManager.currentUser ?: "Guest",
                    connectionError = connectionError,
                    onRetryConnection = { accountManager.pingAllServers() }
                )
                
                // Scrollable content
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(bottom = 24.dp)
                ) {
                    // Welcome header
                    WelcomeHeader(userName = accountManager.currentUser ?: "Guest", calendarManager = calendarManager)
                    
                    // Show connection status indicator in welcome header if there's an error
                    if (connectionError != null) {
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = Color.Red.copy(alpha = 0.1f)
                            ),
                            modifier = Modifier
                                .padding(horizontal = 16.dp, vertical = 8.dp)
                                .fillMaxWidth()
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.padding(12.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.CloudOff,
                                    contentDescription = "Connection Error",
                                    tint = Color.Red,
                                    modifier = Modifier.size(24.dp)
                                )
                                Spacer(modifier = Modifier.width(12.dp))
                                Column(
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Text(
                                        text = "Connection Error",
                                        style = MaterialTheme.typography.labelLarge,
                                        color = Color.Red,
                                        fontWeight = FontWeight.Bold
                                    )
                                    Text(
                                        text = connectionError,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = Color.DarkGray
                                    )
                                }
                                Button(
                                    onClick = { accountManager.pingAllServers() },
                                    colors = ButtonDefaults.buttonColors(
                                        containerColor = Color.Red.copy(alpha = 0.8f)
                                    ),
                                    modifier = Modifier.padding(start = 8.dp)
                                ) {
                                    Text("Retry")
                                }
                            }
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // Replace with our MapAndCalendarView
                    if (showMiniMap) {
                        // Use our new MapAndCalendarView component
                        var currentDate = remember { mutableStateOf(LocalDate.now()) }
                        var showCalendar = remember { mutableStateOf(false) }
                        MapAndCalendarView(
                            selectedDate = currentDate,
                            showCalendar = showCalendar,
                            onCalendarClick = { showCalendarView = true },
                            onMapClick = { showMapView = true }
                        )
                    } else {
                        // Show a placeholder while loading
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(200.dp)
                                .padding(horizontal = 16.dp),
                            shape = RoundedCornerShape(24.dp),
                            colors = CardDefaults.cardColors(containerColor = BgCard),
                            elevation = CardDefaults.cardElevation(defaultElevation = 3.dp)
                        ) {
                            Box(
                                modifier = Modifier.fillMaxSize(),
                                contentAlignment = Alignment.Center
                            ) {
                                CircularProgressIndicator(color = BrandPrimary)
                            }
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // Academic tools section
                    SectionHeader(title = "Academic Tools")
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    // Tools grid
                    ToolsGrid(
                        onFriendsClick = { showFriendsView = true },
                        onCalendarClick = { showCalendarView = true },
                        onInvitationsClick = { showInvitationsView = true },
                        onFlashcardsClick = { showFlashcardsView = true }
                    )
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // Quick access section
                    SectionHeader(title = "Quick Access")
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    // Quick access row
                    QuickAccessRow(
                        onMapClick = { showMapView = true }
                    )
                    
                    // App version
                    Text(
                        text = "PinIt | v2.1.0",
                        style = MaterialTheme.typography.bodySmall,
                        color = TextMuted,
                        modifier = Modifier
                            .padding(top = 24.dp)
                            .align(Alignment.CenterHorizontally)
                    )
                }
            }
            
            // Handle modal sheets
            if (showProfileView) {
                EnhancedProfileView(
                    accountManager = accountManager,
                    onDismiss = { showProfileView = false },
                    onLogout = {
                        showProfileView = false
                        showLoginView = true
                        accountManager.logout()
                    }
                )
            }
            
            if (showSettingsView) {
                PlaceholderSheet(title = "Settings", onDismiss = { showSettingsView = false })
            }
            
            if (showFriendsView) {
                FriendsView(
                    accountManager = accountManager,
                    chatManager = chatManager,
                    onDismiss = { showFriendsView = false },
                    onChatWithFriend = { friend ->
                        selectedChatFriend = friend
                        showFriendsView = false
                        showChatView = true
                    },
                    onGeneralChat = {
                        showFriendsView = false
                        showGeneralChatView = true
                    }
                )
            }
            
            if (showCalendarView) {
                CalendarView(
                    accountManager = accountManager,
                    calendarManager = calendarManager,
                    onDismiss = { showCalendarView = false }
                )
            }
            
            if (showInvitationsView) {
                InvitationsView(
                    accountManager = accountManager,
                    calendarManager = calendarManager,
                    onDismiss = { showInvitationsView = false }
                )
            }
            
            if (showFlashcardsView) {
                PlaceholderSheet(title = "Flashcards", onDismiss = { showFlashcardsView = false })
            }
            
            if (showChatView && selectedChatFriend.isNotEmpty()) {
                ChatView(
                    accountManager = accountManager,
                    chatManager = chatManager,
                    friendUsername = selectedChatFriend,
                    onDismiss = { 
                        showChatView = false 
                        // Don't clear the selectedChatFriend here so the chat history is preserved
                    }
                )
            }
            
            if (showGeneralChatView) {
                ChatView(
                    accountManager = accountManager,
                    chatManager = chatManager,
                    friendUsername = "general",
                    onDismiss = { 
                        showGeneralChatView = false 
                    }
                )
            }
            
            if (showMapView) {
                FullScreenMapView(
                    onClose = { showMapView = false },
                    accountManager = accountManager
                )
            }
        }
    }
}

@Composable
fun BackgroundWithPatterns(isAnimating: Boolean) {
    Box(modifier = Modifier.fillMaxSize()) {
        // Base gradient background
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(BgSurface, BgSecondary)
                    )
                )
        )
        
        // Subtle pattern elements with soft shadows
        Box(
            modifier = Modifier
                .size(120.dp)
                .offset(x = 20.dp, y = 100.dp)
                .shadow(
                    elevation = 2.dp,
                    shape = CircleShape,
                    spotColor = Color.Black.copy(alpha = 0.1f)
                )
                .background(
                    brush = Brush.radialGradient(
                        colors = listOf(
                            BgAccent.copy(alpha = 0.1f),
                            Color.Transparent
                        )
                    )
                )
        )
        
        Box(
            modifier = Modifier
                .size(80.dp)
                .offset(x = 250.dp, y = 200.dp)
                .shadow(
                    elevation = 1.dp,
                    shape = CircleShape,
                    spotColor = Color.Black.copy(alpha = 0.05f)
                )
                .background(
                    brush = Brush.radialGradient(
                        colors = listOf(
                            BgSecondary.copy(alpha = 0.15f),
                            Color.Transparent
                        )
                    )
                )
        )
    }
}

@Composable
fun QuickAccessRow(
    onMapClick: () -> Unit = {}
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        QuickAccessButton(
            title = "Library",
            icon = Icons.AutoMirrored.Filled.MenuBook,
            onClick = {}
        )
        
        QuickAccessButton(
            title = "Forum",
            icon = Icons.AutoMirrored.Filled.Chat,
            onClick = {}
        )
        
        QuickAccessButton(
            title = "Grades",
            icon = Icons.Filled.BarChart,
            onClick = {}
        )
        
        QuickAccessButton(
            title = "Map",
            icon = Icons.Default.Place,
            onClick = onMapClick
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlaceholderSheet(title: String, onDismiss: () -> Unit) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = BgSurface
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "$title View",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = TextPrimary
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Text(
                text = "This is a placeholder for the $title feature",
                style = MaterialTheme.typography.bodyLarge,
                color = TextSecondary,
                textAlign = TextAlign.Center
            )
            
            Spacer(modifier = Modifier.height(24.dp))
            
            Button(
                onClick = onDismiss,
                colors = ButtonDefaults.buttonColors(
                    containerColor = BrandPrimary
                ),
                shape = RoundedCornerShape(12.dp)
            ) {
    Text(
                    text = "Close",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    color = Color.White
                )
            }
            
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CustomTopBar(
    onProfileClick: () -> Unit,
    onSettingsClick: () -> Unit,
    userName: String,
    connectionError: String?,
    onRetryConnection: () -> Unit
) {
    Column {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(BgCard)
                .shadow(
                    elevation = 8.dp,
                    spotColor = CardShadow
                )
                .padding(horizontal = 16.dp, vertical = 12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Left profile button
                IconButton(
                    onClick = onProfileClick,
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(BgCard)
                        .shadow(
                            elevation = 4.dp,
                            shape = CircleShape,
                            spotColor = CardShadow
                        )
                ) {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = "Profile",
                        tint = BrandPrimary
                    )
                }
                
                // Center app logo and name
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Place,
                        contentDescription = "PinIt Logo",
                        tint = BrandPrimary,
                        modifier = Modifier.size(24.dp)
                    )
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    Text(
                        text = "PinIt",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = TextPrimary
                    )
                }
                
                // Right settings button
                IconButton(
                    onClick = onSettingsClick,
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(BgCard)
                        .shadow(
                            elevation = 4.dp,
                            shape = CircleShape,
                            spotColor = CardShadow
                        )
                ) {
                    Icon(
                        imageVector = Icons.Default.Settings,
                        contentDescription = "Settings",
                        tint = BrandPrimary
                    )
                }
            }
        }
        
        // Add connection error alert if needed
        if (connectionError != null) {
            Alert(
                text = "Connection issue: $connectionError",
                buttonText = "Retry",
                onButtonClick = onRetryConnection
            )
        }
    }
}

@Composable
fun Alert(
    text: String,
    buttonText: String,
    onButtonClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.Red.copy(alpha = 0.1f))
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = Icons.Default.Warning,
            contentDescription = "Warning",
            tint = Color.Red,
            modifier = Modifier.size(20.dp)
        )
        
        Spacer(modifier = Modifier.width(8.dp))
        
        Text(
            text = text,
            style = MaterialTheme.typography.bodySmall,
            color = Color.Red,
            modifier = Modifier.weight(1f)
        )
        
        TextButton(
            onClick = onButtonClick,
            colors = ButtonDefaults.textButtonColors(
                contentColor = Color.Red
            )
        ) {
            Text(buttonText)
        }
    }
}

@Composable
fun WelcomeHeader(
    userName: String? = null,
    calendarManager: com.example.pinit.models.CalendarManager? = null
) {
    // Import LocalTime here
    val currentTime = remember { java.time.LocalTime.now() }
    val greeting = remember(currentTime) {
        when (currentTime.hour) {
            in 0..11 -> "Ready for your morning classes"
            in 12..17 -> "Your afternoon schedule is on track"
            else -> "Time for evening study sessions"
        }
    }
    
    val dateFormatter = remember { java.time.format.DateTimeFormatter.ofPattern("d MMM yyyy") }
    val weekdayFormatter = remember { java.time.format.DateTimeFormatter.ofPattern("EEEE") }
    val today = remember { java.time.LocalDate.now() }
    
    // Find the next upcoming event
    val nextEvent = remember(calendarManager?.events) {
        calendarManager?.events
            ?.filter { it.time.isAfter(java.time.LocalDateTime.now()) }
            ?.minByOrNull { it.time }
    }
    
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .shadow(
                elevation = 8.dp,
                spotColor = CardShadow,
                shape = RoundedCornerShape(20.dp),
                ambientColor = CardShadow.copy(alpha = 0.3f)
            ),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = BgCard)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Welcome message with user name
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Greeting on the left
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = "Hello, ${userName?.split(" ")?.firstOrNull() ?: "Student"}!",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = TextPrimary
                    )
                    
                    Text(
                        text = greeting,
                        style = MaterialTheme.typography.bodyMedium,
                        color = TextSecondary
                    )
                    
                    // Show next upcoming event if available
                    if (nextEvent != null) {
                        Spacer(modifier = Modifier.height(8.dp))
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(top = 4.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Event,
                                contentDescription = "Next Event",
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "Next: ${nextEvent.title}",
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                        // Show time for the next event
                        Text(
                            text = "Today at ${nextEvent.time.format(java.time.format.DateTimeFormatter.ofPattern("h:mm a"))}",
                            style = MaterialTheme.typography.bodySmall,
                            color = TextSecondary
                        )
                    }
                }
                
                // Date display on the right
                Card(
                    modifier = Modifier
                        .padding(4.dp),
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(containerColor = BgAccent),
                    elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = today.format(weekdayFormatter),
                            style = MaterialTheme.typography.bodySmall,
                            color = TextMuted
                        )
                        
                        Text(
                            text = today.dayOfMonth.toString(),
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = PrimaryColor
                        )
                        
                        Text(
                            text = today.format(dateFormatter),
                            style = MaterialTheme.typography.bodySmall,
                            color = TextMuted
                        )
                    }
                }
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
fun MainScreenPreview() {
    PinItTheme {
        PinItApp()
    }
}