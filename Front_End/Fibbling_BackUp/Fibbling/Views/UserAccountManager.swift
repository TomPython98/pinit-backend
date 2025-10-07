import Foundation
import SwiftUI

class UserAccountManager: ObservableObject {
    @Published var currentUser: String?
    @Published var friends: [String] = []
    @Published var friendRequests: [String] = [] // ✅ Stores incoming friend requests
    @Published var isCertified: Bool = false
    
    // MARK: - Configuration
    // 🔧 FIX: Use consistent backend URL
    private let baseURL = APIConfig.primaryBaseURL

    init() {
        // Check if user is logged in at startup by reading from UserDefaults
        if UserDefaults.standard.bool(forKey: "isLoggedIn"),
           let savedUsername = UserDefaults.standard.string(forKey: "username") {
            self.currentUser = savedUsername
            
            // Fetch friends and requests on init if user is logged in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.fetchFriends()
                self.fetchFriendRequests()
            }
        } else {
        }
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
                
                AppLogger.logAuth("Registration result: \(success ? "success" : "failed")")

                DispatchQueue.main.async {
                    if success {
                        self.currentUser = username
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

                AppLogger.logAuth("Login result: \(success ? "success" : "failed")")

                DispatchQueue.main.async {
                    if success {
                        self.currentUser = username
                        // Also save to UserDefaults for persistence
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        UserDefaults.standard.set(username, forKey: "username")
                        
                        self.fetchFriends()
                        self.fetchFriendRequests()
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
        guard let username = currentUser,
              let url = URL(string: "\(baseURL)/get_friends/\(username)/") else {
            AppLogger.error("Invalid URL for fetching friends", category: AppLogger.network)
            return 
        }

        AppLogger.logRequest(url: url.absoluteString, method: "GET")

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
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

            do {
                let decodedResponse = try JSONDecoder().decode([String: [String]].self, from: data)

                if let friendsList = decodedResponse["friends"] {
                    DispatchQueue.main.async {
                        self.friends = friendsList
                        AppLogger.debug("Loaded \(friendsList.count) friends", category: AppLogger.data)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.friends = []
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

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
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
        
        let body: [String: String] = ["from_user": currentUser, "to_user": username]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            AppLogger.error("Failed to encode friend request data", category: AppLogger.data)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
    // ✅ Fetch pending friend requests
    func fetchPendingRequests() {
        guard let username = currentUser,
              let url = URL(string: "\(APIConfig.primaryBaseURL)/get_pending_requests/\(username)/") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let pendingRequestsList = json?["pending_requests"] as? [String] {
                    DispatchQueue.main.async {
                        self.friendRequests = pendingRequestsList
                    }
                } else {
                }
            } catch {
            }
        }.resume()
    }

    // ✅ ACCEPT FRIEND REQUEST
    func acceptFriendRequest(from username: String) {
        guard let currentUser = currentUser,
              let url = URL(string: "\(baseURL)/accept_friend_request/") else { 
            return 
        }


        let body: [String: String] = ["from_user": username, "to_user": currentUser]
        let jsonData = try? JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
                self.fetchPendingRequests()
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
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    let certified = json?["is_certified"] as? Bool ?? false
                    DispatchQueue.main.async {
                        self.isCertified = certified
                        AppLogger.debug("User certification status: \(certified)", category: AppLogger.data)
                    }
                } catch {
                    AppLogger.error("Failed to decode user profile", error: error, category: AppLogger.data)
                }
            }
        }.resume()
    }
    
}

