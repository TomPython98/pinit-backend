package com.example.pinit.models

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import kotlin.random.Random

// Basic User Account Manager
class UserAccountManager : ViewModel() {
    var currentUser by mutableStateOf<String?>(null)
    var isLoggedIn by mutableStateOf(false)
    var friends by mutableStateOf<List<String>>(emptyList())
    var friendRequests by mutableStateOf<List<String>>(emptyList())
    var isCertified by mutableStateOf(false)
    var connectionErrorMessage by mutableStateOf<String?>(null)
    var serverStatus by mutableStateOf("Checking server...")
    
    // Store the application context when available
    private var appContext: android.content.Context? = null
    
    // Set the application context
    fun setAppContext(context: android.content.Context) {
        appContext = context.applicationContext
    }
    
    // Multiple server configuration options to try
    private val possibleApiBaseUrls = listOf(
        "https://pinit-backend-production.up.railway.app",  // Production server (primary)
        "https://pin-it.net",                              // Production domain
        "https://api.pin-it.net",                         // API subdomain
        "http://10.0.2.2:8000",                           // Local development (fallback)
        "http://127.0.0.1:8000"                           // Local development (fallback)
    )
    
    // Start with the first option
    private var apiBaseUrl = possibleApiBaseUrls[0]
    
    // DEMO MODE: If you can't connect to any server
    var useDemoMode = false // Set to false to use real backend connection
    
    init {
        // Always try to connect to the server
        pingAllServers()
    }
    
    // Function to test if any server is reachable
    fun pingAllServers() {
        connectionErrorMessage = null
        serverStatus = "Checking server availability..."
        
        // Make sure to run on IO dispatcher
        viewModelScope.launch(Dispatchers.IO) {
            try {
                // Try multiple URL paths to the production server to diagnose issues
                val testUrls = listOf(
                    "https://pinit-backend-production.up.railway.app",  // Production server root
                    "https://pinit-backend-production.up.railway.app/", // Root with trailing slash
                    "https://pinit-backend-production.up.railway.app/api", // API path without trailing slash
                    "https://pinit-backend-production.up.railway.app/api/", // API path with trailing slash
                    "https://pinit-backend-production.up.railway.app/api/login/", // Login endpoint
                    "https://pinit-backend-production.up.railway.app/admin/" // Django admin
                )
                
                var serverFound = false
                
                for (urlString in testUrls) {
                    try {
                        val url = URL(urlString)
                        println("🔄 Testing connection to emulator host URL: $urlString")
                        withContext(Dispatchers.Main) {
                            serverStatus = "Testing URL: $urlString"
                        }
                        
                        val connection = url.openConnection() as HttpURLConnection
                        connection.requestMethod = "GET"
                        connection.connectTimeout = 5000
                        connection.readTimeout = 5000
                        
                        try {
                            // Try to connect
                            connection.connect()
                            val responseCode = connection.responseCode
                            println("🔄 Server ping response code for $urlString: $responseCode")
                            
                            // Any response code means the server is reachable
                            if (responseCode >= 200) {
                                println("✅ Server reached at $urlString with response code $responseCode")
                                apiBaseUrl = "https://pinit-backend-production.up.railway.app"  // Set production base URL
                                
                                withContext(Dispatchers.Main) {
                                    serverStatus = "Connected to production server\nURL $urlString returned code $responseCode"
                                    connectionErrorMessage = null
                                }
                                
                                serverFound = true
                                break
                            }
                        } catch (e: IOException) {
                            println("❌ Connection failed for $urlString: ${e.message}")
                        } finally {
                            connection.disconnect()
                        }
                    } catch (e: Exception) {
                        println("❌ Error setting up connection to $urlString: ${e.message}")
                    }
                }
                
                if (!serverFound) {
                    println("❌ Failed to connect to emulator host on any path")
                    
                    // Try all other server URLs one by one
                    for (serverUrl in possibleApiBaseUrls.drop(1)) { // Skip the first one we already tried
                        try {
                            println("🔄 Testing connection to server: $serverUrl")
                            val url = URL("$serverUrl/")
                            
                            withContext(Dispatchers.Main) {
                                serverStatus = "Testing URL: $serverUrl"
                            }
                            
                            val connection = url.openConnection() as HttpURLConnection
                            connection.requestMethod = "GET"
                            connection.connectTimeout = 5000
                            connection.readTimeout = 5000
                            
                            try {
                                // Try to connect
                                connection.connect()
                                val responseCode = connection.responseCode
                                println("🔄 Server ping response code for $serverUrl: $responseCode")
                                
                                // Any response code means the server is reachable
                                if (responseCode >= 200) {
                                    println("✅ Server reached at $serverUrl with response code $responseCode")
                                    apiBaseUrl = serverUrl
                                    
                                    withContext(Dispatchers.Main) {
                                        serverStatus = "Connected to $serverUrl\nServer returned code $responseCode"
                                        connectionErrorMessage = null
                                    }
                                    
                                    serverFound = true
                                    break
                                }
                            } catch (e: IOException) {
                                println("❌ Connection failed for $serverUrl: ${e.message}")
                            } finally {
                                connection.disconnect()
                            }
                        } catch (e: Exception) {
                            println("❌ Error setting up connection to $serverUrl: ${e.message}")
                        }
                    }
                    
                    if (!serverFound) {
                        withContext(Dispatchers.Main) {
                            connectionErrorMessage = "Could not connect to any server. Make sure your Django server is running on any of these URLs:\n" +
                                possibleApiBaseUrls.joinToString(separator = "\n") + 
                                "\n\nStart your server with: python manage.py runserver 0.0.0.0:8000"
                            serverStatus = "No server available"
                        }
                        
                        // Try Google as a backup to check general internet connectivity
                        try {
                            println("🔄 Testing general internet connectivity...")
                            val googleConnection = URL("https://www.google.com").openConnection() as HttpURLConnection
                            googleConnection.connectTimeout = 5000
                            googleConnection.connect()
                            
                            // Internet works, but Django server unreachable
                            println("✅ Internet connection works, but can't reach Django server")
                            
                            withContext(Dispatchers.Main) {
                                connectionErrorMessage = "Internet works, but Django server unreachable.\n" +
                                    "Make sure Django is running with:\n" +
                                    "python manage.py runserver 0.0.0.0:8000"
                                serverStatus = "Internet OK, Django server unreachable"
                            }
                        } catch (e: Exception) {
                            // No internet connection at all
                            withContext(Dispatchers.Main) {
                                connectionErrorMessage = "No internet connection. Check Wi-Fi settings."
                                serverStatus = "No internet connection"
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                println("❌ Unexpected error in pingAllServers: ${e.javaClass.simpleName} - ${e.message}")
                e.printStackTrace()
                
                withContext(Dispatchers.Main) {
                    connectionErrorMessage = "Error checking server: ${e.message}"
                    serverStatus = "Error checking server"
                }
            }
        }
    }
    
    // Function to test if the server is reachable
    fun pingServer() {
        // Use the new multi-server ping method
        pingAllServers()
    }
    
    // Login function with actual backend connection
    fun login(username: String, password: String, callback: (Boolean, String) -> Unit) {
        // Reset connection error message
        connectionErrorMessage = null
        
        // Check if username and password are empty
        if (username.isEmpty() || password.isEmpty()) {
            callback(false, "Username and password cannot be empty")
            return
        }
        
        // Explicitly use Dispatchers.IO for network operations
        viewModelScope.launch(Dispatchers.IO) {
            try {
                println("🔐 Attempting login for user: $username")
                
                // Always use real backend connection
                val loginUrl = URL("$apiBaseUrl/api/login/")
                println("📡 Login request to: $loginUrl")
                
                try {
                    val connection = loginUrl.openConnection() as HttpURLConnection
                    connection.requestMethod = "POST"
                    connection.doOutput = true
                    connection.setRequestProperty("Content-Type", "application/json")
                    connection.connectTimeout = 15000
                    connection.readTimeout = 15000
                    
                    // Create login payload
                    val data = JSONObject().apply {
                        put("username", username)
                        put("password", password)
                    }
                    
                    println("📦 Sending payload: $data")
                    
                    // Send the request
                    val outputStream = connection.outputStream
                    outputStream.write(data.toString().toByteArray())
                    outputStream.close()
                    
                    // Read the response code
                    val responseCode = connection.responseCode
                    println("📥 HTTP Response code: $responseCode")
                    
                    // Handle response
                    if (responseCode == HttpURLConnection.HTTP_OK) {
                        val response = connection.inputStream.bufferedReader().use { it.readText() }
                        println("📄 Response body: $response")
                        
                        try {
                            val jsonResponse = JSONObject(response)
                            val success = jsonResponse.optBoolean("success", false)
                            val message = jsonResponse.optString("message", "Unknown error")
                            
                            withContext(Dispatchers.Main) {
                                if (success) {
                                    println("✅ Login successful for user: $username")
                                    handleSuccessfulLogin(username)
                                    callback(true, "Login successful")
                                } else {
                                    println("❌ Login failed: $message")
                                    callback(false, message)
                                }
                            }
                        } catch (e: Exception) {
                            println("❌ Failed to parse JSON: ${e.javaClass.simpleName}")
                            println("❌ Exception details: ${e.message ?: "No message"}")
                            println("📄 Raw response was: $response")
                            
                            withContext(Dispatchers.Main) {
                                callback(false, "Error parsing server response: ${e.javaClass.simpleName}")
                            }
                        }
                    } else {
                        // Error response
                        val errorStream = connection.errorStream
                        val errorResponse = errorStream?.bufferedReader()?.use { it.readText() } ?: "Unknown error"
                        println("❌ HTTP Error $responseCode: $errorResponse")
                        
                        withContext(Dispatchers.Main) {
                            connectionErrorMessage = "Server error code: $responseCode"
                            callback(false, "Login failed with status code $responseCode: $errorResponse")
                        }
                    }
                } catch (e: IOException) {
                    println("❌ Network error connecting to server: ${e.javaClass.simpleName}")
                    println("❌ Error details: ${e.message ?: "Connection refused or timed out"}")
                    
                    // Try to ping all servers to see if any are reachable
                    pingAllServers()
                    
                    withContext(Dispatchers.Main) {
                        connectionErrorMessage = "Network error: Cannot connect to server. Make sure the server is running."
                        callback(false, "Network error: Cannot connect to server at $apiBaseUrl. Please check your connection and Django server status.")
                    }
                }
            } catch (e: Exception) {
                println("❌ Unexpected error: ${e.javaClass.simpleName}")
                println("❌ Error details: ${e.message ?: "Unknown error"}")
                e.printStackTrace()
                
                withContext(Dispatchers.Main) {
                    connectionErrorMessage = "Error connecting to server"
                    callback(false, "Connection error: ${e.javaClass.simpleName} - " + 
                             (e.message ?: "Unknown error"))
                }
            }
        }
    }
    
    // Register function with actual backend connection
    fun register(username: String, password: String, callback: (Boolean, String) -> Unit) {
        // Reset connection error message
        connectionErrorMessage = null
        
        // Check if username and password are empty
        if (username.isEmpty() || password.isEmpty()) {
            callback(false, "Username and password cannot be empty")
            return
        }
        
        // Explicitly use Dispatchers.IO for network operations
        viewModelScope.launch(Dispatchers.IO) {
            try {
                println("📝 Attempting registration for user: $username")
                
                // Always use real backend connection
                val registerUrl = URL("$apiBaseUrl/api/register/")
                println("📡 Registration request to: $registerUrl")
                
                try {
                    val connection = registerUrl.openConnection() as HttpURLConnection
                    connection.requestMethod = "POST"
                    connection.doOutput = true
                    connection.setRequestProperty("Content-Type", "application/json")
                    connection.connectTimeout = 15000
                    connection.readTimeout = 15000
                    
                    // Create registration payload
                    val data = JSONObject().apply {
                        put("username", username)
                        put("password", password)
                    }
                    
                    println("📦 Sending payload: $data")
                    
                    // Send the request
                    val outputStream = connection.outputStream
                    outputStream.write(data.toString().toByteArray())
                    outputStream.close()
                    
                    // Read the response
                    val responseCode = connection.responseCode
                    if (responseCode == HttpURLConnection.HTTP_CREATED || responseCode == HttpURLConnection.HTTP_OK) {
                        val response = connection.inputStream.bufferedReader().use { it.readText() }
                        val jsonResponse = JSONObject(response)
                        val success = jsonResponse.getBoolean("success")
                        
                        if (success) {
                            println("✅ Registration successful for user: $username")
                            handleSuccessfulLogin(username)
                            
                            withContext(Dispatchers.Main) {
                                callback(true, "Registration successful")
                            }
                        } else {
                            val message = jsonResponse.getString("message")
                            println("❌ Registration failed: $message")
                            
                            withContext(Dispatchers.Main) {
                                callback(false, message)
                            }
                        }
                    } else {
                        val errorMessage = connection.errorStream?.bufferedReader()?.use { it.readText() }
                            ?: "Unknown error occurred"
                        println("❌ HTTP Error $responseCode: $errorMessage")
                        
                        withContext(Dispatchers.Main) {
                            connectionErrorMessage = "Server error code: $responseCode"
                            callback(false, "Registration failed: $errorMessage")
                        }
                    }
                    
                    connection.disconnect()
                } catch (e: IOException) {
                    println("❌ Network error connecting to server: ${e.javaClass.simpleName}")
                    println("❌ Error details: ${e.message ?: "Connection refused or timed out"}")
                    
                    // Try to ping all servers to see if any are reachable
                    pingAllServers()
                    
                    withContext(Dispatchers.Main) {
                        connectionErrorMessage = "Network error: Cannot connect to server. Make sure the server is running."
                        callback(false, "Network error: Cannot connect to server at $apiBaseUrl. Please check your connection and Django server status.")
                    }
                }
            } catch (e: Exception) {
                println("❌ Unexpected error: ${e.javaClass.simpleName}")
                println("❌ Error details: ${e.message ?: "Unknown error"}")
                e.printStackTrace()
                
                withContext(Dispatchers.Main) {
                    connectionErrorMessage = "Error connecting to server"
                    callback(false, "Error: ${e.localizedMessage ?: "Unknown error"}")
                }
            }
        }
    }
    
    // Logout function
    fun logout() {
        if (!useDemoMode) {
            // Call the server to logout
            viewModelScope.launch {
                try {
                    val logoutUrl = URL("$apiBaseUrl/api/logout/")
                    val connection = logoutUrl.openConnection() as HttpURLConnection
                    connection.requestMethod = "POST"
                    connection.disconnect()
                } catch (e: Exception) {
                    // Silently handle failed logout
                }
            }
        }
        // In a real app, you would also invalidate the token on the server
        currentUser = null
        isLoggedIn = false
        friends = emptyList()
        friendRequests = emptyList()
    }
    
    // Helper function for successful login
    private fun handleSuccessfulLogin(username: String) {
        currentUser = username
        isLoggedIn = true
        
        // Try to load friends from saved preferences first
        loadFriendsFromSharedPreferences()
        
        // Then fetch fresh data from the server
        fetchFriends { success ->
            if (success) {
                println("✅ Successfully refreshed friends list after login")
            } else {
                println("⚠️ Could not refresh friends list from server, using cached data")
            }
        }
        
        // Fetch friend requests
        fetchFriendRequests()
    }
    
    // Fetch friends
    fun fetchFriends(callback: ((Boolean) -> Unit)? = null) {
        // Use the IO dispatcher for network operations
        viewModelScope.launch(Dispatchers.IO) {
            try {
                println("👥 Fetching friends for user: $currentUser")
                val friendsUrl = URL("$apiBaseUrl/api/get_friends/${currentUser}/")
                val connection = friendsUrl.openConnection() as HttpURLConnection
                
                connection.requestMethod = "GET"
                connection.connectTimeout = 15000
                connection.readTimeout = 15000
                
                try {
                    val responseCode = connection.responseCode
                    if (responseCode == HttpURLConnection.HTTP_OK) {
                        val response = connection.inputStream.bufferedReader().use { it.readText() }
                        println("📄 Friends response: $response")
                        
                        try {
                            val jsonResponse = JSONObject(response)
                            val friendsList = jsonResponse.getJSONArray("friends")
                            
                            val friendNames = mutableListOf<String>()
                            for (i in 0 until friendsList.length()) {
                                friendNames.add(friendsList.getString(i))
                            }
                            
                            println("✅ Fetched ${friendNames.size} friends: $friendNames")
                            
                            withContext(Dispatchers.Main) {
                                // Update the state with the new friends list
                                friends = friendNames
                                
                                // Store the friends list for persistence across app restarts
                                saveToSharedPreferences(friendNames)
                                
                                // Notify the caller of success
                                callback?.invoke(true)
                            }
                        } catch (e: Exception) {
                            println("❌ Error parsing friends response: ${e.message}")
                            e.printStackTrace()
                            
                            withContext(Dispatchers.Main) {
                                // Keep the current friends list on error
                                callback?.invoke(false)
                            }
                        }
                    } else {
                        val errorResponse = connection.errorStream?.bufferedReader()?.use { it.readText() } ?: "Unknown error"
                        println("❌ Error fetching friends: HTTP $responseCode - $errorResponse")
                        
                        withContext(Dispatchers.Main) {
                            // Keep the current friends list on error
                            callback?.invoke(false)
                        }
                    }
                    
                    connection.disconnect()
                } catch (e: Exception) {
                    println("❌ Error processing friends response: ${e.message}")
                    e.printStackTrace()
                    
                    withContext(Dispatchers.Main) {
                        // Keep the current friends list on error
                        callback?.invoke(false)
                    }
                }
            } catch (e: Exception) {
                println("❌ Error creating connection for friends: ${e.message}")
                e.printStackTrace()
                
                withContext(Dispatchers.Main) {
                    // Keep the current friends list on error
                    callback?.invoke(false)
                }
            }
        }
    }
    
    // Helper method to save friends list to SharedPreferences for persistence
    private fun saveToSharedPreferences(friendsList: List<String>) {
        if (currentUser.isNullOrEmpty() || appContext == null) {
            println("⚠️ Cannot save friends: no current user or context")
            return
        }
        
        try {
            val sharedPrefs = appContext!!.getSharedPreferences("PinItPrefs", android.content.Context.MODE_PRIVATE)
            
            // Store the friends list as a JSON string
            val friendsJson = org.json.JSONArray(friendsList).toString()
            sharedPrefs.edit()
                .putString("${currentUser}_friends", friendsJson)
                .apply()
            
            println("✅ Saved ${friendsList.size} friends to SharedPreferences")
        } catch (e: Exception) {
            println("❌ Error saving friends to SharedPreferences: ${e.message}")
        }
    }

    // Helper method to load friends list from SharedPreferences on startup
    fun loadFriendsFromSharedPreferences() {
        if (currentUser.isNullOrEmpty() || appContext == null) {
            println("⚠️ Cannot load friends: no current user or context")
            return
        }
        
        try {
            val sharedPrefs = appContext!!.getSharedPreferences("PinItPrefs", android.content.Context.MODE_PRIVATE)
            
            // Retrieve the stored friends list
            val friendsJson = sharedPrefs.getString("${currentUser}_friends", null)
            if (friendsJson != null) {
                val friendsArray = org.json.JSONArray(friendsJson)
                val loadedFriends = mutableListOf<String>()
                
                for (i in 0 until friendsArray.length()) {
                    loadedFriends.add(friendsArray.getString(i))
                }
                
                // Update the friends list with the loaded data
                friends = loadedFriends
                println("✅ Loaded ${loadedFriends.size} friends from SharedPreferences")
            }
        } catch (e: Exception) {
            println("❌ Error loading friends from SharedPreferences: ${e.message}")
        }
    }
    
    // Fetch friend requests
    fun fetchFriendRequests(callback: ((Boolean) -> Unit)? = null) {
        // In a real app, you would fetch from your backend
        viewModelScope.launch(Dispatchers.IO) {
            try {
                println("👥 Fetching friend requests for user: $currentUser")
                val friendRequestsUrl = URL("$apiBaseUrl/api/get_pending_requests/${currentUser}/")
                val connection = friendRequestsUrl.openConnection() as HttpURLConnection
                
                connection.requestMethod = "GET"
                connection.connectTimeout = 15000
                connection.readTimeout = 15000
                
                try {
                    val responseCode = connection.responseCode
                    println("📥 Friend requests response code: $responseCode")
                    
                    if (responseCode == HttpURLConnection.HTTP_OK) {
                        val response = connection.inputStream.bufferedReader().use { it.readText() }
                        println("📄 Friend requests response: $response")
                        
                        val jsonResponse = JSONObject(response)
                        val requestsList = jsonResponse.getJSONArray("pending_requests")
                        
                        val requestNames = mutableListOf<String>()
                        for (i in 0 until requestsList.length()) {
                            requestNames.add(requestsList.getString(i))
                        }
                        
                        println("✅ Fetched ${requestNames.size} friend requests: $requestNames")
                        withContext(Dispatchers.Main) {
                            friendRequests = requestNames
                            callback?.invoke(true)
                        }
                    } else {
                        val errorResponse = connection.errorStream?.bufferedReader()?.use { it.readText() } ?: "Unknown error"
                        println("❌ Error fetching friend requests: HTTP $responseCode - $errorResponse")
                        
                        withContext(Dispatchers.Main) {
                            // Keep the current friend requests list
                            callback?.invoke(false)
                        }
                    }
                    
                    connection.disconnect()
                } catch (e: Exception) {
                    println("❌ Error processing friend requests response: ${e.message}")
                    e.printStackTrace()
                    
                    withContext(Dispatchers.Main) {
                        // Keep the current friend requests list
                        callback?.invoke(false)
                    }
                }
            } catch (e: Exception) {
                println("❌ Error creating connection for friend requests: ${e.message}")
                e.printStackTrace()
                
                withContext(Dispatchers.Main) {
                    // Keep the current friend requests list
                    callback?.invoke(false)
                }
            }
        }
    }
    
    // Send friend request
    fun sendFriendRequest(to: String, callback: ((Boolean, String) -> Unit)? = null) {
        if (useDemoMode) {
            // Demo implementation
            callback?.invoke(true, "Friend request sent successfully")
            return
        }
        
        // In a real app, you would call your backend API
        viewModelScope.launch(Dispatchers.IO) {
            try {
                println("🔍 Sending friend request from ${currentUser} to: $to")
                println("🔗 Using API URL: $apiBaseUrl/api/send_friend_request/")
                val sendRequestUrl = URL("$apiBaseUrl/api/send_friend_request/")
                val connection = sendRequestUrl.openConnection() as HttpURLConnection
                
                connection.requestMethod = "POST"
                connection.doOutput = true
                connection.setRequestProperty("Content-Type", "application/json")
                connection.connectTimeout = 15000
                connection.readTimeout = 15000
                
                // Create request payload
                val data = JSONObject().apply {
                    put("from_user", currentUser)
                    put("to_user", to)
                }
                
                println("📦 Sending friend request payload: $data")
                
                val outputStream = connection.outputStream
                outputStream.write(data.toString().toByteArray())
                outputStream.close()
                
                // Get the response and verify it
                val responseCode = connection.responseCode
                println("📥 Friend request response code: $responseCode")
                
                // Handle success codes: 200 OK or 201 Created
                if (responseCode == HttpURLConnection.HTTP_OK || responseCode == HttpURLConnection.HTTP_CREATED) {
                    try {
                        val response = connection.inputStream.bufferedReader().use { it.readText() }
                        println("📄 Friend request response: $response")
                        
                        // Try to parse JSON response
                        try {
                            val jsonResponse = JSONObject(response)
                            val success = jsonResponse.optBoolean("success", true) // Default to true if field not present
                            val message = jsonResponse.optString("message", if (responseCode == HttpURLConnection.HTTP_CREATED) 
                                "Friend request sent successfully" else "Friend request sent")
                            
                            withContext(Dispatchers.Main) {
                                callback?.invoke(success, message)
                            }
                        } catch (e: Exception) {
                            // If JSON parsing fails, still treat as success based on HTTP code
                            println("⚠️ Error parsing friend request response: ${e.message}")
                            e.printStackTrace()
                            withContext(Dispatchers.Main) {
                                callback?.invoke(true, if (responseCode == HttpURLConnection.HTTP_CREATED) 
                                    "Friend request created successfully" else "Friend request sent")
                            }
                        }
                    } catch (e: Exception) {
                        // If reading the response fails, still treat as success based on HTTP code
                        println("⚠️ Error reading friend request response: ${e.message}")
                        e.printStackTrace()
                        withContext(Dispatchers.Main) {
                            callback?.invoke(true, if (responseCode == HttpURLConnection.HTTP_CREATED) 
                                "Friend request created successfully" else "Friend request sent")
                        }
                    }
                } else {
                    println("❌ Error HTTP code: $responseCode")
                    
                    // Try to read error response
                    val errorResponse = if (connection.errorStream != null) {
                        try {
                            connection.errorStream.bufferedReader().use { it.readText() }
                        } catch (e: Exception) {
                            "Error reading error stream: ${e.message}"
                        }
                    } else {
                        "No error details available (code $responseCode)"
                    }
                    
                    println("❌ Error response details: $errorResponse")
                    
                    // Try to parse JSON error if available
                    try {
                        val jsonError = JSONObject(errorResponse)
                        val errorMessage = jsonError.optString("message", "Unknown server error")
                        println("❌ JSON error message: $errorMessage")
                        
                        withContext(Dispatchers.Main) {
                            callback?.invoke(false, errorMessage)
                        }
                    } catch (e: Exception) {
                        // If not JSON, return the raw error
                        withContext(Dispatchers.Main) {
                            callback?.invoke(false, "Server error ($responseCode): $errorResponse")
                        }
                    }
                }
                
                connection.disconnect()
            } catch (e: Exception) {
                println("❌ Error sending friend request: ${e.javaClass.simpleName}: ${e.message}")
                e.printStackTrace()
                
                withContext(Dispatchers.Main) {
                    callback?.invoke(false, "Network error: ${e.javaClass.simpleName}: ${e.message ?: "Unknown error"}")
                }
            }
        }
    }
    
    // Accept friend request
    fun acceptFriendRequest(from: String) {
        if (useDemoMode) {
            // Demo implementation
            friendRequests = friendRequests.filter { it != from }
            if (!friends.contains(from)) {
                friends = friends + from
            }
        } else {
            // In a real app, you would call your backend API
            viewModelScope.launch(Dispatchers.IO) {
                try {
                    println("🔄 Accepting friend request from: $from")
                    val acceptRequestUrl = URL("$apiBaseUrl/api/accept_friend_request/")
                    val connection = acceptRequestUrl.openConnection() as HttpURLConnection
                    
                    connection.requestMethod = "POST"
                    connection.doOutput = true
                    connection.setRequestProperty("Content-Type", "application/json")
                    connection.connectTimeout = 15000
                    connection.readTimeout = 15000
                    
                    // Create request payload
                    val data = JSONObject().apply {
                        put("from_user", from)
                        put("to_user", currentUser)
                    }
                    
                    println("📦 Sending payload: $data")
                    
                    val outputStream = connection.outputStream
                    outputStream.write(data.toString().toByteArray())
                    outputStream.close()
                    
                    // Update local state if request was successful
                    val responseCode = connection.responseCode
                    println("📥 HTTP Response code: $responseCode")
                    
                    if (responseCode == HttpURLConnection.HTTP_OK || responseCode == HttpURLConnection.HTTP_CREATED) {
                        try {
                            // Try to parse response to get detailed success information
                            val response = connection.inputStream.bufferedReader().use { it.readText() }
                            println("📄 Response: $response")
                            
                            val jsonResponse = JSONObject(response)
                            val success = jsonResponse.optBoolean("success", true) // Default to true if not found
                            
                            // Get the friends lists from the response if available
                            val fromUserFriends = jsonResponse.optJSONArray("from_user_friends")?.let { array ->
                                List(array.length()) { i -> array.getString(i) }
                            }
                            val toUserFriends = jsonResponse.optJSONArray("to_user_friends")?.let { array ->
                                List(array.length()) { i -> array.getString(i) }
                            }
                            
                            withContext(Dispatchers.Main) {
                                if (success) {
                                    // Update UI immediately for better user experience
                                    friendRequests = friendRequests.filter { it != from }
                                    
                                    // If the server returned the friends lists, use them
                                    if (toUserFriends != null) {
                                        // This is my (current user's) friends list
                                        println("✅ Server returned my friends list: $toUserFriends")
                                        friends = toUserFriends.toList()
                                    } else {
                                        // Add the friend locally if server didn't return friends list
                                        if (!friends.contains(from)) {
                                            friends = friends + from
                                        }
                                    }
                                    
                                    // Force a refresh of friends data to ensure we have the latest
                                    fetchFriends()
                                    
                                    println("✅ Successfully accepted friend request from: $from")
                                    
                                    // Now notify the sender by making an additional API call
                                    // This helps ensure both sides of the friendship are synchronized
                                    notifySenderOfAcceptedRequest(from)
                                } else {
                                    val message = jsonResponse.optString("message", "Unknown error")
                                    println("⚠️ Server returned success=false: $message")
                                    // Still remove from requests but don't add to friends
                                    friendRequests = friendRequests.filter { it != from }
                                }
                            }
                        } catch (e: Exception) {
                            println("⚠️ Error parsing response: ${e.message}")
                            // Assume success if we got HTTP 200 but couldn't parse
                            withContext(Dispatchers.Main) {
                                friendRequests = friendRequests.filter { it != from }
                                if (!friends.contains(from)) {
                                    friends = friends + from
                                }
                                
                                // Retry fetching friends list
                                fetchFriends()
                                
                                // Still try to notify sender even if we couldn't parse the response
                                notifySenderOfAcceptedRequest(from)
                            }
                        }
                    } else {
                        // Log the error response
                        val errorResponse = connection.errorStream?.bufferedReader()?.use { it.readText() } ?: "Unknown error"
                        println("❌ HTTP Error $responseCode: $errorResponse")
                    }
                    
                    connection.disconnect()
                } catch (e: Exception) {
                    println("❌ Error accepting friend request: ${e.message}")
                    e.printStackTrace()
                }
            }
        }
    }
    
    // Helper method to notify the sender that their request was accepted
    private fun notifySenderOfAcceptedRequest(sender: String) {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                println("🔔 Notifying $sender that their friend request was accepted")
                
                // First attempt to use the standard accept_friend_request API with reversed roles
                // This is the most reliable way to ensure bidirectional friendship
                try {
                    val acceptUrl = URL("$apiBaseUrl/api/accept_friend_request/")
                    val connection = acceptUrl.openConnection() as HttpURLConnection
                    
                    connection.requestMethod = "POST"
                    connection.doOutput = true
                    connection.setRequestProperty("Content-Type", "application/json")
                    connection.connectTimeout = 10000
                    connection.readTimeout = 10000
                    
                    // Create reversed payload (current user is now shown as from_user)
                    // This forces both users to be processed as acceptors in the backend
                    val data = JSONObject().apply {
                        put("from_user", currentUser) // Current user is now "sending" 
                        put("to_user", sender)      // Original sender is now "accepting"
                    }
                    
                    println("📦 Sending reversed accept payload for bidirectional friendship: $data")
                    
                    val outputStream = connection.outputStream
                    outputStream.write(data.toString().toByteArray())
                    outputStream.close()
                    
                    val responseCode = connection.responseCode
                    println("📥 Bidirectional accept response code: $responseCode")
                    
                    if (responseCode == HttpURLConnection.HTTP_OK || responseCode == HttpURLConnection.HTTP_CREATED) {
                        println("✅ Successfully ensured bidirectional friendship")
                        
                        // Try to parse response for debugging
                        try {
                            val response = connection.inputStream.bufferedReader().use { it.readText() }
                            println("📄 Bidirectional accept response: $response")
                        } catch (e: Exception) {
                            println("⚠️ Could not read response body: ${e.message}")
                        }
                        
                        return@launch // Exit early since we succeeded with primary method
                    } else {
                        val errorResponse = connection.errorStream?.bufferedReader()?.use { it.readText() } ?: "Unknown error"
                        println("⚠️ Bidirectional friendship creation failed: $errorResponse")
                        // Continue to fallback methods
                    }
                    connection.disconnect()
                } catch (e: Exception) {
                    println("⚠️ Error in bidirectional accept call: ${e.message}")
                    // Continue to fallback methods
                }
                
                // Try notification-specific endpoints as fallbacks
                val notifyEndpoints = listOf(
                    "$apiBaseUrl/api/notify_request_accepted/",
                    "$apiBaseUrl/api/sync_friendship/"
                )
                
                for (endpoint in notifyEndpoints) {
                    try {
                        val notifyUrl = URL(endpoint)
                        val connection = notifyUrl.openConnection() as HttpURLConnection
                        
                        connection.requestMethod = "POST"
                        connection.doOutput = true
                        connection.setRequestProperty("Content-Type", "application/json")
                        connection.connectTimeout = 10000
                        connection.readTimeout = 10000
                        
                        // Create notification payload
                        val data = JSONObject().apply {
                            put("from_user", currentUser)  // Current user accepted the request
                            put("to_user", sender)         // The original sender needs to be notified
                        }
                        
                        println("📦 Sending notification payload to $endpoint: $data")
                        
                        val outputStream = connection.outputStream
                        outputStream.write(data.toString().toByteArray())
                        outputStream.close()
                        
                        val responseCode = connection.responseCode
                        println("📥 Notification response code from $endpoint: $responseCode")
                        
                        if (responseCode == HttpURLConnection.HTTP_OK || responseCode == HttpURLConnection.HTTP_CREATED) {
                            println("✅ Successfully notified $sender via $endpoint")
                            return@launch  // Exit if any notification endpoint succeeds
                        } else {
                            val errorResponse = connection.errorStream?.bufferedReader()?.use { it.readText() } ?: "Unknown error"
                            println("⚠️ Notification failed via $endpoint: $errorResponse")
                        }
                        
                        connection.disconnect()
                    } catch (e: Exception) {
                        println("⚠️ Error notifying via $endpoint: ${e.message}")
                    }
                }
                
                println("⚠️ All notification attempts failed, friendship may be one-sided")
            } catch (e: Exception) {
                println("❌ Overall error in notification process: ${e.message}")
                e.printStackTrace()
            }
        }
    }
    
    // Decline friend request
    fun declineFriendRequest(from: String) {
        if (useDemoMode) {
            // Demo implementation
            friendRequests = friendRequests.filter { it != from }
        } else {
            // In a real app, you would call your backend API
            viewModelScope.launch {
                try {
                    val declineRequestUrl = URL("$apiBaseUrl/api/decline_friend_request/")
                    val connection = declineRequestUrl.openConnection() as HttpURLConnection
                    
                    connection.requestMethod = "POST"
                    connection.doOutput = true
                    connection.setRequestProperty("Content-Type", "application/json")
                    
                    // Create request payload
                    val data = JSONObject().apply {
                        put("from_user", from)
                        put("to_user", currentUser)
                    }
                    
                    val outputStream = connection.outputStream
                    outputStream.write(data.toString().toByteArray())
                    outputStream.close()
                    
                    // Update local state if request was successful
                    val responseCode = connection.responseCode
                    if (responseCode == HttpURLConnection.HTTP_OK) {
                        friendRequests = friendRequests.filter { it != from }
                    }
                    
                    connection.disconnect()
                } catch (e: Exception) {
                    // Handle error
                }
            }
        }
    }

    // Function specifically for testing connections that can be called from UI
    fun testConnectionsForUI(callback: (String) -> Unit) {
        // Ensure we're in a background thread
        viewModelScope.launch(Dispatchers.IO) {
            val results = StringBuilder()
            
            try {
                results.append("🔍 Testing server connections...\n")
                
                // First test Google to verify general internet connectivity
                try {
                    results.append("Testing internet connectivity with Google...\n")
                    val googleConnection = URL("https://www.google.com").openConnection() as HttpURLConnection
                    googleConnection.connectTimeout = 3000
                    googleConnection.readTimeout = 3000
                    googleConnection.connect()
                    val responseCode = googleConnection.responseCode
                    results.append("✅ Internet connectivity OK (Google responded with $responseCode)\n\n")
                    googleConnection.disconnect()
                } catch (e: Exception) {
                    results.append("❌ Internet connectivity failed: ${e.javaClass.simpleName} - ${e.message}\n\n")
                }
                
                // Test each server URL
                for (serverUrl in possibleApiBaseUrls) {
                    try {
                        results.append("Testing $serverUrl...\n")
                        val testUrl = URL("$serverUrl/")
                        val connection = testUrl.openConnection() as HttpURLConnection
                        connection.connectTimeout = 3000
                        connection.readTimeout = 3000
                        connection.requestMethod = "GET"
                        
                        try {
                            connection.connect()
                            val responseCode = connection.responseCode
                            results.append("✅ Response code: $responseCode\n")
                            
                            // Try the API path too
                            val apiUrl = URL("$serverUrl/api/")
                            val apiConnection = apiUrl.openConnection() as HttpURLConnection
                            apiConnection.connectTimeout = 3000
                            apiConnection.readTimeout = 3000
                            
                            try {
                                apiConnection.connect()
                                val apiResponseCode = apiConnection.responseCode
                                results.append("API path response: $apiResponseCode\n\n")
                                apiConnection.disconnect()
                            } catch (e: Exception) {
                                results.append("API path error: ${e.javaClass.simpleName}\n\n")
                            }
                        } catch (e: Exception) {
                            results.append("❌ Connection failed: ${e.javaClass.simpleName} - ${e.message}\n\n")
                        } finally {
                            connection.disconnect()
                        }
                    } catch (e: Exception) {
                        results.append("❌ Error with $serverUrl: ${e.javaClass.simpleName} - ${e.message}\n\n")
                    }
                }
                
                // Update UI on main thread
                withContext(Dispatchers.Main) {
                    callback(results.toString())
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback("❌ Test failed: ${e.javaClass.simpleName} - ${e.message}\n\n${e.stackTraceToString()}")
                }
            }
        }
    }

    // Generic API request helper
    fun makeApiRequest(
        endpoint: String,
        method: String = "GET",
        body: Map<String, Any>? = null,
        onSuccess: (String) -> Unit,
        onError: (String) -> Unit
    ) {
        // Make sure we're running on IO thread
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val fullUrl = URL("$apiBaseUrl/api/$endpoint")
                println("📡 Making $method request to: $fullUrl")
                
                val connection = fullUrl.openConnection() as HttpURLConnection
                connection.requestMethod = method
                connection.connectTimeout = 15000
                connection.readTimeout = 15000
                
                if (method == "POST" || method == "PUT") {
                    connection.doOutput = true
                    connection.setRequestProperty("Content-Type", "application/json")
                    
                    // Write request body if provided
                    if (body != null) {
                        val json = JSONObject(body)
                        val outputStream = connection.outputStream
                        outputStream.write(json.toString().toByteArray())
                        outputStream.close()
                        println("📦 Sent payload: $json")
                    }
                }
                
                val responseCode = connection.responseCode
                println("📥 HTTP Response code: $responseCode")
                
                if (responseCode in 200..299) {
                    // Success response
                    val response = connection.inputStream.bufferedReader().use { it.readText() }
                    println("📄 Response: $response")
                    
                    withContext(Dispatchers.Main) {
                        onSuccess(response)
                    }
                } else {
                    // Error response
                    val errorResponse = connection.errorStream?.bufferedReader()?.use { it.readText() } ?: "Unknown error"
                    println("❌ HTTP Error $responseCode: $errorResponse")
                    
                    withContext(Dispatchers.Main) {
                        onError("Error $responseCode: $errorResponse")
                    }
                }
            } catch (e: Exception) {
                println("❌ Request failed: ${e.javaClass.simpleName} - ${e.message}")
                
                withContext(Dispatchers.Main) {
                    onError("Network error: ${e.localizedMessage ?: e.javaClass.simpleName}")
                }
            }
        }
    }

    // Search for users to add as friends
    fun searchUsers(query: String, callback: (List<String>) -> Unit) {
        if (query.isEmpty()) {
            callback(emptyList())
            return
        }
        
        if (useDemoMode) {
            // Demo implementation
            val demoUsers = listOf(
                "alice_student", "bob_researcher", "charlie_prof", 
                "david_ta", "eve_student", "frank_admin"
            )
            val results = demoUsers.filter { it.contains(query, ignoreCase = true) }
            callback(results)
            return
        }
        
        // Use the API endpoint to search for users
        viewModelScope.launch(Dispatchers.IO) {
            try {
                println("🔍 Searching for users with query: $query")
                
                // Since the backend doesn't have a search_users endpoint yet, we'll use get_all_users
                // In a real app, you would call a dedicated search endpoint
                val searchUrl = URL("$apiBaseUrl/api/get_all_users/")
                val connection = searchUrl.openConnection() as HttpURLConnection
                
                connection.requestMethod = "GET"
                connection.connectTimeout = 5000
                connection.readTimeout = 5000
                
                val responseCode = connection.responseCode
                println("📥 User search response code: $responseCode")
                
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    val response = connection.inputStream.bufferedReader().use { it.readText() }
                    println("📄 User search response: $response")
                    
                    try {
                        // Parse the array response
                        val usersList = JSONObject(response).getJSONArray("users")
                        val allUsers = mutableListOf<String>()
                        
                        // Convert JSON array to list
                        for (i in 0 until usersList.length()) {
                            allUsers.add(usersList.getString(i))
                        }
                        
                        // Filter users based on query
                        val filteredUsers = allUsers.filter { 
                            it.contains(query, ignoreCase = true) &&
                            it != currentUser &&
                            !friends.contains(it)
                        }
                        
                        println("✅ Found ${filteredUsers.size} users matching '$query'")
                        
                        withContext(Dispatchers.Main) {
                            callback(filteredUsers)
                        }
                    } catch (e: Exception) {
                        println("⚠️ Error parsing user list: ${e.message}")
                        
                        // Try parsing as a direct array if JSONObject fails
                        try {
                            val jsonArray = org.json.JSONArray(response)
                            val userList = mutableListOf<String>()
                            
                            for (i in 0 until jsonArray.length()) {
                                userList.add(jsonArray.getString(i))
                            }
                            
                            // Filter users based on query
                            val filteredUsers = userList.filter { 
                                it.contains(query, ignoreCase = true) &&
                                it != currentUser &&
                                !friends.contains(it)
                            }
                            
                            println("✅ Found ${filteredUsers.size} users matching '$query' (array format)")
                            
                            withContext(Dispatchers.Main) {
                                callback(filteredUsers)
                            }
                        } catch (e2: Exception) {
                            println("❌ Failed to parse user response as array too: ${e2.message}")
                            withContext(Dispatchers.Main) {
                                callback(emptyList())
                            }
                        }
                    }
                } else {
                    val errorResponse = connection.errorStream?.bufferedReader()?.use { it.readText() } ?: "Unknown error"
                    println("❌ HTTP Error $responseCode: $errorResponse")
                    
                    withContext(Dispatchers.Main) {
                        callback(emptyList())
                    }
                }
                
                connection.disconnect()
            } catch (e: Exception) {
                println("❌ Error searching users: ${e.message}")
                e.printStackTrace()
                
                withContext(Dispatchers.Main) {
                    callback(emptyList())
                }
            }
        }
    }
    
    // Fetch sent friend requests
    fun fetchSentRequests(callback: (List<String>) -> Unit) {
        if (useDemoMode) {
            // Demo implementation
            callback(emptyList())
            return
        }
        
        // In a real app, you would call your backend API
        viewModelScope.launch(Dispatchers.IO) {
            try {
                println("🔍 Fetching sent friend requests for user: $currentUser")
                val sentRequestsUrl = URL("$apiBaseUrl/api/get_sent_requests/${currentUser}/")
                val connection = sentRequestsUrl.openConnection() as HttpURLConnection
                
                connection.requestMethod = "GET"
                connection.connectTimeout = 5000
                connection.readTimeout = 5000
                
                val responseCode = connection.responseCode
                println("📥 Sent requests response code: $responseCode")
                
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    val response = connection.inputStream.bufferedReader().use { it.readText() }
                    println("📄 Sent requests response: $response")
                    
                    try {
                        val jsonResponse = JSONObject(response)
                        val sentList = jsonResponse.getJSONArray("sent_requests")
                        
                        val sentRequests = mutableListOf<String>()
                        for (i in 0 until sentList.length()) {
                            sentRequests.add(sentList.getString(i))
                        }
                        
                        println("✅ Fetched ${sentRequests.size} sent friend requests")
                        
                        withContext(Dispatchers.Main) {
                            callback(sentRequests)
                        }
                    } catch (e: Exception) {
                        println("⚠️ Error parsing sent requests: ${e.message}")
                        withContext(Dispatchers.Main) {
                            callback(emptyList())
                        }
                    }
                } else {
                    val errorResponse = connection.errorStream?.bufferedReader()?.use { it.readText() } ?: "Unknown error"
                    println("❌ HTTP Error $responseCode: $errorResponse")
                    
                    withContext(Dispatchers.Main) {
                        callback(emptyList())
                    }
                }
                
                connection.disconnect()
            } catch (e: Exception) {
                println("❌ Error fetching sent requests: ${e.message}")
                e.printStackTrace()
                
                withContext(Dispatchers.Main) {
                    callback(emptyList())
                }
            }
        }
    }

    // Test the friend request API endpoint
    fun testFriendRequestAPI(from: String, to: String, callback: (String) -> Unit) {
        viewModelScope.launch(Dispatchers.IO) {
            val results = StringBuilder()
            results.append("🔍 Testing friend request API endpoints\n\n")
            
            // Try multiple variations of the endpoint
            val possibleEndpoints = listOf(
                "$apiBaseUrl/api/send_friend_request/",
                "$apiBaseUrl/api/send_friend_request",
                "$apiBaseUrl/api/friend_request/send/",
                "$apiBaseUrl/api/friend-request/",
                "$apiBaseUrl/api/friendship/request/"
            )
            
            // Test payload format variations
            val payloadVariations = listOf(
                JSONObject().apply {
                    put("from_user", from)
                    put("to_user", to)
                },
                JSONObject().apply {
                    put("from", from)
                    put("to", to)
                },
                JSONObject().apply {
                    put("sender", from)
                    put("recipient", to)
                },
                JSONObject().apply {
                    put("username", from)
                    put("friend", to)
                }
            )
            
            // Test all combinations
            for (endpoint in possibleEndpoints) {
                results.append("Testing endpoint: $endpoint\n")
                
                for ((i, payload) in payloadVariations.withIndex()) {
                    results.append("  Payload variation $i: $payload\n")
                    
                    try {
                        val url = URL(endpoint)
                        val connection = url.openConnection() as HttpURLConnection
                        connection.requestMethod = "POST"
                        connection.doOutput = true
                        connection.setRequestProperty("Content-Type", "application/json")
                        connection.connectTimeout = 5000
                        connection.readTimeout = 5000
                        
                        val outputStream = connection.outputStream
                        outputStream.write(payload.toString().toByteArray())
                        outputStream.close()
                        
                        val responseCode = connection.responseCode
                        results.append("    Response code: $responseCode\n")
                        
                        if (responseCode == HttpURLConnection.HTTP_OK) {
                            val response = connection.inputStream.bufferedReader().use { it.readText() }
                            results.append("    Response: $response\n")
                            
                            // Mark this as likely working
                            results.append("    ✅ This endpoint + payload combination seems to work!\n")
                        } else {
                            val errorText = if (connection.errorStream != null) {
                                connection.errorStream.bufferedReader().use { it.readText() }
                            } else {
                                "No error stream available"
                            }
                            results.append("    Error: $errorText\n")
                        }
                        
                        connection.disconnect()
                    } catch (e: Exception) {
                        results.append("    Exception: ${e.javaClass.simpleName}: ${e.message}\n")
                    }
                    
                    results.append("\n")
                }
                
                results.append("\n")
            }
            
            withContext(Dispatchers.Main) {
                callback(results.toString())
            }
        }
    }
}

// Weather ViewModel
class WeatherViewModel : ViewModel() {
    var temperature by mutableStateOf("24°")
    var condition by mutableStateOf("Sunny")
    var location by mutableStateOf("Buenos Aires")
    var forecastItems by mutableStateOf(
        listOf(
            WeatherForecast("Mon", "23°", "sunny"),
            WeatherForecast("Tue", "21°", "partly_cloudy"),
            WeatherForecast("Wed", "19°", "cloudy"),
            WeatherForecast("Thu", "22°", "sunny"),
            WeatherForecast("Fri", "25°", "sunny")
        )
    )

    fun fetchWeather(city: String) {
        // Simulate API call with random weather
        location = city
        temperature = "${Random.nextInt(15, 28)}°"
        
        val conditions = listOf("Sunny", "Partly Cloudy", "Cloudy", "Light Rain")
        condition = conditions.random()
    }
}

// Weather forecast data class
data class WeatherForecast(
    val day: String,
    val temperature: String,
    val condition: String
)

// Chat Message data class
data class ChatMessage(
    val sender: String,
    val message: String
)

// Chat Session data class
data class ChatSession(
    val participants: List<String>,
    var messages: MutableList<ChatMessage>
)

// Chat Manager
class ChatManager {
    var chatSessions = mutableStateOf<List<ChatSession>>(emptyList())
    
    fun sendMessage(to: String, sender: String, message: String) {
        val chatKey = listOf(sender, to).sorted()
        val existingSessionIndex = chatSessions.value.indexOfFirst { 
            it.participants == chatKey 
        }
        
        if (existingSessionIndex >= 0) {
            val updatedSessions = chatSessions.value.toMutableList()
            updatedSessions[existingSessionIndex].messages.add(
                ChatMessage(sender = sender, message = message)
            )
            chatSessions.value = updatedSessions
        } else {
            val newSession = ChatSession(
                participants = chatKey,
                messages = mutableListOf(ChatMessage(sender = sender, message = message))
            )
            chatSessions.value = chatSessions.value + newSession
        }
    }
    
    fun getMessages(sender: String, receiver: String): List<ChatMessage> {
        val chatKey = listOf(sender, receiver).sorted()
        return chatSessions.value
            .firstOrNull { it.participants == chatKey }
            ?.messages ?: emptyList()
    }
}
