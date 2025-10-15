import Foundation
import SwiftUI

class UserAccountManager: ObservableObject {
    @Published var currentUser: String?
    @Published var friends: [String] = []
    @Published var friendRequests: [String] = [] // ✅ Stores incoming friend requests
    @Published var isCertified: Bool = false
    @Published var accessToken: String?
    @Published var refreshToken: String?
    
    // Computed property for JWT token (alias for accessToken)
    var jwtToken: String? {
        return accessToken
    }
    
    // MARK: - Configuration
    private let baseURL = APIConfig.primaryBaseURL
    
    private let accessTokenKey = "access_token" // Backend returns "access_token"
    private let refreshTokenKey = "refresh_token" // Backend returns "refresh_token"
    
    // Cache keys for performance optimization
    private let friendsCacheKey = "cached_friends"
    private let friendRequestsCacheKey = "cached_friend_requests"
    private let cacheTimestampKey = "cache_timestamp"

    init() {
        // Load cached data FIRST for instant display
        self.loadFriendsCache()
        self.loadFriendRequestsCache()
        
        // Check if user is logged in at startup by reading from UserDefaults
        if UserDefaults.standard.bool(forKey: "isLoggedIn"),
           let savedUsername = UserDefaults.standard.string(forKey: "username") {
            self.currentUser = savedUsername
            
            // Load saved tokens
            self.accessToken = UserDefaults.standard.string(forKey: accessTokenKey)
            self.refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey)
            
            // Debug logging removed for production
            
            // Only fetch data if we have valid tokens
            if self.accessToken != nil {
                // Fetch all data in parallel immediately (updates cache in background)
                Task {
                    await self.fetchAllUserDataParallel()
                }
            } else {
                // No access token found - user needs to login again
                // Clear invalid login state
                self.clearTokens()
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
                UserDefaults.standard.removeObject(forKey: "username")
                self.currentUser = nil
            }
        } else {
            // No saved login state found at startup
        }
    }
    
    // MARK: - Token Management
    func saveTokens(access: String, refresh: String) {
        accessToken = access
        refreshToken = refresh
        UserDefaults.standard.set(access, forKey: accessTokenKey)
        UserDefaults.standard.set(refresh, forKey: refreshTokenKey)
        
        print("💾 Tokens saved to UserDefaults:")
        print("   Key '\(accessTokenKey)': \(access.prefix(20))...")
        print("   Key '\(refreshTokenKey)': \(refresh.prefix(20))...")
    }
    
    func addAuthHeader(to request: inout URLRequest) {
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 Adding auth header with token: \(token.prefix(20))...")
        } else {
            print("❌ No access token available for auth header")
            print("🔍 Checking UserDefaults keys:")
            print("   access_token: \(UserDefaults.standard.string(forKey: "access_token")?.prefix(20) ?? "nil")")
            print("   access: \(UserDefaults.standard.string(forKey: "access")?.prefix(20) ?? "nil")")
        }
    }
    
    // MARK: - Token Refresh
    func refreshAccessToken() async -> Bool {
        guard let refreshToken = refreshToken else {
            return false
        }
        
        let refreshURL = APIConfig.fullURL(for: "token/refresh/")
        guard let url = URL(string: refreshURL) else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["refresh": refreshToken]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return false
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let newAccessToken = json["access"] as? String {
                
                // Update the access token
                DispatchQueue.main.async {
                    self.accessToken = newAccessToken
                    UserDefaults.standard.set(newAccessToken, forKey: self.accessTokenKey)
                }
                return true
            }
        } catch {
            // Token refresh failed
        }
        
        return false
    }
    
    func addAuthHeaderWithRefresh(to request: inout URLRequest) async {
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            // Try to refresh token if we don't have one
            let refreshed = await refreshAccessToken()
            if refreshed, let token = accessToken {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
    }
    
    func clearTokens() {
        accessToken = nil
        refreshToken = nil
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
    }

    // ✅ REGISTER USER
    func register(username: String, password: String, completion: @escaping (Bool, String) -> Void) {
        // Validate input
        let usernameValidation = InputValidator.isValidUsername(username)
        guard usernameValidation.isValid else {
            completion(false, usernameValidation.error?.errorDescription ?? "Invalid username")
            return
        }
        
        let passwordValidation = InputValidator.isValidPassword(password)
        guard passwordValidation.isValid else {
            completion(false, passwordValidation.error?.errorDescription ?? "Invalid password")
            return
        }
        
        let registerURL = APIConfig.fullURL(for: "register")
        AppLogger.logRequest(url: registerURL, method: "POST")
        
        guard let url = URL(string: registerURL) else {
            AppLogger.error("Invalid registration URL", category: AppLogger.auth)
            completion(false, AppError.invalidURL.errorDescription ?? "Invalid URL")
            return
        }
        
        let body: [String: String] = ["username": username, "password": password]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            AppLogger.error("Failed to encode registration data", category: AppLogger.auth)
            completion(false, AppError.encodingError("registration data").errorDescription ?? "Encoding failed")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let httpResponse = response as? HTTPURLResponse {
                AppLogger.logResponse(url: registerURL, statusCode: httpResponse.statusCode)
            }
            
            if let error = error {
                AppLogger.error("Registration network error", error: error, category: AppLogger.auth)
                DispatchQueue.main.async {
                    completion(false, AppError.networkError(error.localizedDescription).errorDescription ?? "Network error")
                }
                return
            }
            
            guard let data = data else {
                AppLogger.error("No data received from registration", category: AppLogger.auth)
                DispatchQueue.main.async {
                    completion(false, AppError.invalidResponse.errorDescription ?? "No response from server.")
                }
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let success = json?["success"] as? Bool ?? false
                let message = json?["message"] as? String ?? "Unknown error."
                
                // Extract JWT tokens if registration successful
                let accessToken = json?["access"] as? String
                let refreshToken = json?["refresh"] as? String
                
                AppLogger.logAuth("Registration result: \(success ? "success" : "failed")")

                DispatchQueue.main.async {
                    if success {
                        self.currentUser = username
                        
                        // Save JWT tokens if provided (same as login flow)
                        if let access = accessToken, let refresh = refreshToken {
                            self.saveTokens(access: access, refresh: refresh)
                            
                            // Fetch all user data in parallel immediately
                            Task {
                                await self.fetchAllUserDataParallel()
                            }
                        } else {
                        }
                        
                        // Also save to UserDefaults for persistence
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        UserDefaults.standard.set(username, forKey: "username")
                        AppLogger.logAuth("User data persisted")
                    }
                    completion(success, message)
                }
            } catch {
                AppLogger.error("Failed to parse registration response", error: error, category: AppLogger.auth)
                DispatchQueue.main.async {
                    completion(false, AppError.decodingError("registration response").errorDescription ?? "Invalid response from server.")
                }
            }
        }.resume()
    }

    // ✅ LOGIN USER & FETCH FRIENDS
    func login(username: String, password: String, completion: @escaping (Bool, String) -> Void) {
        let loginURL = APIConfig.fullURL(for: "login")
        AppLogger.logRequest(url: loginURL, method: "POST")
        
        guard let url = URL(string: loginURL) else {
            AppLogger.error("Invalid login URL", category: AppLogger.auth)
            completion(false, AppError.invalidURL.errorDescription ?? "Invalid URL")
            return
        }
        
        let body: [String: String] = ["username": username, "password": password]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            AppLogger.error("Failed to encode login data", category: AppLogger.auth)
            completion(false, AppError.encodingError("login data").errorDescription ?? "Encoding failed")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let httpResponse = response as? HTTPURLResponse {
                AppLogger.logResponse(url: loginURL, statusCode: httpResponse.statusCode)
            }
            
            if let error = error {
                AppLogger.error("Login network error", error: error, category: AppLogger.auth)
                DispatchQueue.main.async {
                    completion(false, AppError.networkError(error.localizedDescription).errorDescription ?? "Network error")
                }
                return
            }
            
            guard let data = data else {
                AppLogger.error("No data received from login", category: AppLogger.auth)
                DispatchQueue.main.async {
                    completion(false, AppError.invalidResponse.errorDescription ?? "No response from server.")
                }
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let success = json?["success"] as? Bool ?? false
                let message = json?["message"] as? String ?? "Unknown error."
                
                // Extract JWT tokens if login successful
                let accessToken = json?["access_token"] as? String
                let refreshToken = json?["refresh_token"] as? String
                
                // Debug: Log token extraction
                print("🔍 Login response keys: \(json?.keys.sorted() ?? [])")
                print("🔍 Access token: \(accessToken?.prefix(20) ?? "nil")...")
                print("🔍 Refresh token: \(refreshToken?.prefix(20) ?? "nil")...")

                AppLogger.logAuth("Login result: \(success ? "success" : "failed")")

                DispatchQueue.main.async {
                    if success {
                        self.currentUser = username
                        // Save tokens if provided
                        if let access = accessToken, let refresh = refreshToken {
                            self.saveTokens(access: access, refresh: refresh)
                            
                            // Fetch all user data in parallel immediately
                            Task {
                                await self.fetchAllUserDataParallel()
                            }
                        } else {
                        }
                        // Also save to UserDefaults for persistence
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        UserDefaults.standard.set(username, forKey: "username")
                    }
                    completion(success, message)
                }
            } catch {
                AppLogger.error("Failed to parse login response", error: error, category: AppLogger.auth)
                DispatchQueue.main.async {
                    completion(false, AppError.decodingError("login response").errorDescription ?? "Invalid response from server.")
                }
            }
        }.resume()
    }

    func fetchFriends() {
        guard let username = currentUser else {
            AppLogger.error("Invalid URL for fetching friends", category: AppLogger.network)
            return 
        }
        
        let urlString = "\(baseURL)/get_friends/\(username)/"
        
        guard let url = URL(string: urlString) else {
            AppLogger.error("Invalid URL for fetching friends", category: AppLogger.network)
            return 
        }

        AppLogger.logRequest(url: url.absoluteString, method: "GET")

        var request = URLRequest(url: url)
        addAuthHeader(to: &request)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { 
                return 
            }
            
            if let error = error {
                AppLogger.error("Failed to fetch friends", error: error, category: AppLogger.network)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                AppLogger.error("Invalid response when fetching friends", category: AppLogger.network)
                return
            }
            
            AppLogger.logResponse(url: url.absoluteString, statusCode: httpResponse.statusCode)
            
            guard httpResponse.statusCode == 200 else {
                AppLogger.error("HTTP \(httpResponse.statusCode) when fetching friends", category: AppLogger.network)
                return
            }
            
            guard let data = data else {
                AppLogger.error("No data received when fetching friends", category: AppLogger.network)
                return
            }

            
            // Log raw response for debugging
            if let rawString = String(data: data, encoding: .utf8) {
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode([String: [String]].self, from: data)

                if let friendsList = decodedResponse["friends"] {
                    DispatchQueue.main.async {
                        self.friends = friendsList
                        self.saveFriendsCache(friendsList)
                        AppLogger.debug("Loaded \(friendsList.count) friends", category: AppLogger.data)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.friends = []
                        self.saveFriendsCache([])
                    }
                }
            } catch {
                AppLogger.error("Failed to decode friends response", error: error, category: AppLogger.data)
                DispatchQueue.main.async {
                    self.friends = []
                }
            }
        }.resume()
    }

    func fetchFriendRequests() {
        
        guard let username = currentUser,
              let url = URL(string: "\(baseURL)/get_pending_requests/\(username)/") else {
            AppLogger.error("Invalid URL for fetching friend requests", category: AppLogger.network)
            return 
        }

        AppLogger.logRequest(url: url.absoluteString, method: "GET")

        var request = URLRequest(url: url)
        addAuthHeader(to: &request)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                AppLogger.error("Failed to fetch friend requests", error: error, category: AppLogger.network)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                AppLogger.logResponse(url: url.absoluteString, statusCode: httpResponse.statusCode)
                guard httpResponse.statusCode == 200 else {
                    return
                }
            }
            
            guard let data = data else {
                AppLogger.error("No data received when fetching friend requests", category: AppLogger.network)
                return
            }
            
            // Log raw response for debugging
            if let rawString = String(data: data, encoding: .utf8) {
                AppLogger.debug("Raw friend requests response: \(rawString)", category: AppLogger.data)
            }
            
            do {
                let decodedResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                if let pendingRequests = decodedResponse?["pending_requests"] as? [String] {
                    DispatchQueue.main.async {
                        self.friendRequests = pendingRequests
                        self.saveFriendRequestsCache(pendingRequests)
                        AppLogger.debug("Loaded \(pendingRequests.count) friend requests", category: AppLogger.data)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.friendRequests = []
                    }
                }
            } catch {
                AppLogger.error("Failed to decode friend requests", error: error, category: AppLogger.data)
                // Try to parse as array directly (in case backend returns array instead of object)
                do {
                    let directArray = try JSONSerialization.jsonObject(with: data, options: []) as? [String]
                    DispatchQueue.main.async {
                        self.friendRequests = directArray ?? []
                        AppLogger.debug("Loaded \(directArray?.count ?? 0) friend requests (direct array)", category: AppLogger.data)
                    }
                } catch {
                    AppLogger.error("Failed to parse friend requests as array", error: error, category: AppLogger.data)
                    DispatchQueue.main.async {
                        self.friendRequests = []
                    }
                }
            }
        }.resume()
    }

    // ✅ SEND FRIEND REQUEST
    func sendFriendRequest(to username: String) {
        guard let currentUser = currentUser, 
              let url = URL(string: "\(baseURL)/send_friend_request/") else {
            AppLogger.error("Invalid URL for sending friend request", category: AppLogger.network)
            return 
        }
        
        AppLogger.logRequest(url: url.absoluteString, method: "POST")
        
        let body: [String: String] = ["to_user": username]  // Remove from_user since it's now from authenticated user
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            AppLogger.error("Failed to encode friend request data", category: AppLogger.data)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeader(to: &request)  // Add JWT authentication

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                AppLogger.error("Failed to send friend request", error: error, category: AppLogger.network)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                AppLogger.logResponse(url: url.absoluteString, statusCode: httpResponse.statusCode)
            }
            
            AppLogger.info("Friend request sent to \(username)", category: AppLogger.network)
            
            DispatchQueue.main.async {
                self.fetchFriendRequests() // ✅ Refresh pending requests after sending one
            }
        }.resume()
    }

    // ✅ ACCEPT FRIEND REQUEST
    func acceptFriendRequest(from username: String) {
        guard let currentUser = currentUser,
              let url = URL(string: "\(baseURL)/accept_friend_request/") else { 
            return 
        }
        let body: [String: String] = ["from_user": username]  // Only send from_user - backend gets to_user from JWT
        let jsonData = try? JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // ✅ Add JWT authentication header
        addAuthHeader(to: &request)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                return
            }
            
            if let data = data {
                let responseString = String(data: data, encoding: .utf8) ?? "N/A"
            }
            
            DispatchQueue.main.async {
                // ✅ Remove from pending requests
                self.friendRequests.removeAll { $0 == username }

                // ✅ Immediately add to friends list
                if !self.friends.contains(username) {
                    self.friends.append(username)
                }

                // ✅ Force-refresh friends & pending requests
                self.fetchFriends()
                self.fetchFriendRequests()
            }
        }.resume()
    }

    // ✅ LOGOUT FUNCTION
    func logout(completion: @escaping (Bool, String) -> Void) {
        AppLogger.logAuth("User logging out")
        
        // Post a notification to let all subscribers know we're about to logout
        // This gives any active managers a chance to clean up resources
        NotificationCenter.default.post(name: NSNotification.Name("UserWillLogout"), object: nil)
        
        // Wait a moment to allow other components to clean up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Now perform the actual logout
            self.currentUser = nil
            self.friends = []
            self.friendRequests = []
            
            // Clear tokens
            self.clearTokens()
            
            // Clear user data from UserDefaults
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            UserDefaults.standard.removeObject(forKey: "username")
            
            AppLogger.logAuth("User logged out successfully")
            completion(true, "Logged out successfully.")
        }
    }
}

extension UserAccountManager {
    /// Example placeholder for deleting an account on the backend.
    /// Adjust the URL, HTTP method, and JSON as needed for your API.
    func deleteAccount(completion: @escaping (Bool, String) -> Void) {
        guard let username = currentUser else {
            completion(false, "No user is currently logged in.")
            return
        }
        // Suppose your backend has an endpoint like:
        // DELETE http://127.0.0.1:8000/api/delete_account/<username>/
        guard let url = URL(string: "\(baseURL)/delete_account/\(username)/") else {
            completion(false, "Invalid delete account URL.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"  // or "POST" if your server expects that

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(false, "No response from server.")
                }
                return
            }

            do {
                // Adjust this based on how your server returns JSON
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let success = json?["success"] as? Bool ?? false
                let message = json?["message"] as? String ?? "Unknown error."
                
                DispatchQueue.main.async {
                    if success {
                        // Optionally log the user out as well
                        self.logout { _, _ in
                            completion(true, "Account deleted and user logged out.")
                        }
                    } else {
                        completion(false, message)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, "Error parsing server response.")
                }
            }
        }.resume()
    }
    
    
    

    func fetchUserProfile() {
        guard let username = currentUser,
              let url = URL(string: "\(baseURL)/get_user_profile/\(username)/") else {
            AppLogger.error("Invalid URL for fetching user profile", category: AppLogger.network)
            return
        }

        AppLogger.logRequest(url: url.absoluteString, method: "GET")

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                AppLogger.error("Failed to fetch user profile", error: error, category: AppLogger.network)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                AppLogger.logResponse(url: url.absoluteString, statusCode: httpResponse.statusCode)
            }
            
            Task {
                guard let data = data else { return }
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    let certified = json?["is_certified"] as? Bool ?? false
                    await MainActor.run {
                        self.isCertified = certified
                        AppLogger.debug("User certification status: \(certified)", category: AppLogger.data)
                    }
                } catch {
                    AppLogger.error("Failed to decode user profile", error: error, category: AppLogger.data)
                }
            }
        }.resume()
    }
    
    // MARK: - Cache Management (Performance Optimization)
    
    /// Load cached friends on app startup for instant display
    private func loadFriendsCache() {
        if let cached = UserDefaults.standard.array(forKey: friendsCacheKey) as? [String] {
            self.friends = cached
            print("📦 Loaded \(cached.count) friends from cache")
        }
    }
    
    /// Save friends to cache for next app launch
    private func saveFriendsCache(_ friendsList: [String]) {
        UserDefaults.standard.set(friendsList, forKey: friendsCacheKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
    }
    
    /// Load cached friend requests on app startup
    private func loadFriendRequestsCache() {
        if let cached = UserDefaults.standard.array(forKey: friendRequestsCacheKey) as? [String] {
            self.friendRequests = cached
            print("📦 Loaded \(cached.count) friend requests from cache")
        }
    }
    
    /// Save friend requests to cache
    private func saveFriendRequestsCache(_ requests: [String]) {
        UserDefaults.standard.set(requests, forKey: friendRequestsCacheKey)
    }
    
    // MARK: - Parallel Data Fetching (Performance Optimization)
    
    /// Fetch all user data in parallel for maximum performance
    func fetchAllUserDataParallel() async {
        async let friendsTask: Void = fetchFriendsAsync()
        async let requestsTask: Void = fetchFriendRequestsAsync()
        
        // Wait for both to complete
        _ = await (friendsTask, requestsTask)
        print("✅ All user data loaded in parallel")
    }
    
    /// Async version of fetchFriends for parallel execution
    private func fetchFriendsAsync() async {
        guard let username = currentUser else { return }
        
        let urlString = "\(baseURL)/get_friends/\(username)/"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        addAuthHeader(to: &request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return
            }
            
            let decodedResponse = try JSONDecoder().decode([String: [String]].self, from: data)
            
            if let friendsList = decodedResponse["friends"] {
                await MainActor.run {
                    self.friends = friendsList
                    self.saveFriendsCache(friendsList)
                }
            }
        } catch {
            print("❌ Failed to fetch friends: \(error)")
        }
    }
    
    /// Async version of fetchFriendRequests for parallel execution
    private func fetchFriendRequestsAsync() async {
        guard let username = currentUser else { return }
        guard let url = URL(string: "\(baseURL)/get_pending_requests/\(username)/") else { return }
        
        var request = URLRequest(url: url)
        addAuthHeader(to: &request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return
            }
            
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            if let pendingRequests = json?["pending_requests"] as? [String] {
                await MainActor.run {
                    self.friendRequests = pendingRequests
                    self.saveFriendRequestsCache(pendingRequests)
                }
            }
        } catch {
            print("❌ Failed to fetch friend requests: \(error)")
        }
    }
    
}
