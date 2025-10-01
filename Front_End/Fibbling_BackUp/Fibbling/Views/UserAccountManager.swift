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
            print("✅ UserAccountManager: Retrieved user from UserDefaults: \(savedUsername)")
            
            // Fetch friends and requests on init if user is logged in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.fetchFriends()
                self.fetchFriendRequests()
            }
        } else {
            print("ℹ️ UserAccountManager: No logged in user found in UserDefaults")
        }
    }

    // ✅ REGISTER USER
    func register(username: String, password: String, completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: "\(baseURL)/register/") else {
            completion(false, "Invalid URL")
            return
        }
        
        let body: [String: String] = ["username": username, "password": password]
        let jsonData = try? JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(false, "No response from server.")
                }
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let success = json?["success"] as? Bool ?? false
                let message = json?["message"] as? String ?? "Unknown error."

                DispatchQueue.main.async {
                    if success {
                        self.currentUser = username
                        // Also save to UserDefaults for persistence
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        UserDefaults.standard.set(username, forKey: "username")
                        print("✅ UserAccountManager: Saved username to UserDefaults: \(username)")
                    }
                    completion(success, message)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, "Invalid response from server.")
                }
            }
        }.resume()
    }

    // ✅ LOGIN USER & FETCH FRIENDS
    func login(username: String, password: String, completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: "\(baseURL)/login/") else {
            completion(false, "Invalid URL")
            return
        }
        
        let body: [String: String] = ["username": username, "password": password]
        let jsonData = try? JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else {
                DispatchQueue.main.async { completion(false, "No response from server.") }
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let success = json?["success"] as? Bool ?? false
                let message = json?["message"] as? String ?? "Unknown error."

                DispatchQueue.main.async {
                    if success {
                        self.currentUser = username
                        // Also save to UserDefaults for persistence
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        UserDefaults.standard.set(username, forKey: "username")
                        print("✅ UserAccountManager: Saved username to UserDefaults: \(username)")
                        
                        self.fetchFriends()
                        self.fetchFriendRequests()
                    }
                    completion(success, message)
                }
            } catch {
                DispatchQueue.main.async { completion(false, "Invalid response from server.") }
            }
            
            
        }.resume()
    }

    func fetchFriends() {
        guard let username = currentUser,
              let url = URL(string: "\(baseURL)/get_friends/\(username)/") else { 
            print("❌ UserAccountManager: Invalid URL for fetching friends")
            return 
        }

        print("🔍 UserAccountManager: Fetching friends for \(username)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ UserAccountManager: Network error fetching friends: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ UserAccountManager: Invalid response type")
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ UserAccountManager: HTTP error \(httpResponse.statusCode) when fetching friends")
                return
            }
            
            guard let data = data else {
                print("❌ UserAccountManager: No data when fetching friends")
                return
            }

            do {
                // ✅ Print raw response before decoding
                let rawJSON = String(data: data, encoding: .utf8) ?? "N/A"
                print("📩 UserAccountManager: Raw Friends API Response: \(rawJSON)")

                let decodedResponse = try JSONDecoder().decode([String: [String]].self, from: data)

                if let friendsList = decodedResponse["friends"] {
                    DispatchQueue.main.async {
                        self.friends = friendsList
                        print("✅ UserAccountManager: Updated Friends List: \(friendsList)")
                    }
                } else {
                    print("❌ UserAccountManager: 'friends' key not found in JSON")
                    DispatchQueue.main.async {
                        self.friends = []
                    }
                }
            } catch {
                print("❌ UserAccountManager: Error decoding friends JSON: \(error)")
                DispatchQueue.main.async {
                    self.friends = []
                }
            }
        }.resume()
    }

    func fetchFriendRequests() {
        guard let username = currentUser,
              let url = URL(string: "\(baseURL)/get_pending_requests/\(username)/") else { 
            print("❌ UserAccountManager: Invalid URL for fetching friend requests")
            return 
        }

        print("🔍 UserAccountManager: Fetching friend requests for \(username)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ UserAccountManager: Network error fetching friend requests: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("❌ UserAccountManager: Invalid API response for friend requests (\(httpResponse.statusCode))")
                return
            }
            
            guard let data = data else {
                print("❌ UserAccountManager: No data when fetching friend requests")
                return
            }
            
            do {
                // Parse the response properly
                let rawJSON = String(data: data, encoding: .utf8) ?? "N/A"
                print("📩 UserAccountManager: Raw Friend Requests Response: \(rawJSON)")
                
                let decodedResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                if let pendingRequests = decodedResponse?["pending_requests"] as? [String] {
                    DispatchQueue.main.async {
                        self.friendRequests = pendingRequests
                        print("✅ UserAccountManager: Fetched \(pendingRequests.count) Friend Requests: \(pendingRequests)")
                    }
                } else {
                    print("❌ UserAccountManager: Invalid friend requests JSON structure")
                    DispatchQueue.main.async {
                        self.friendRequests = []
                    }
                }
            } catch {
                print("❌ UserAccountManager: Error decoding friend requests JSON: \(error)")
                DispatchQueue.main.async {
                    self.friendRequests = []
                }
            }
        }.resume()
    }

    // ✅ SEND FRIEND REQUEST
    func sendFriendRequest(to username: String) {
        guard let currentUser = currentUser, 
              let url = URL(string: "\(baseURL)/send_friend_request/") else { 
            print("❌ UserAccountManager: Invalid URL for sending friend request")
            return 
        }
        
        print("🔍 UserAccountManager: Sending friend request from \(currentUser) to \(username)")
        
        let body: [String: String] = ["from_user": currentUser, "to_user": username]
        let jsonData = try? JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ UserAccountManager: Error sending friend request: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                let responseString = String(data: data, encoding: .utf8) ?? "N/A"
                print("📩 UserAccountManager: Friend request response: \(responseString)")
            }
            
            DispatchQueue.main.async {
                self.fetchFriendRequests() // ✅ Refresh pending requests after sending one
            }
        }.resume()
    }
    // ✅ Fetch pending friend requests
    func fetchPendingRequests() {
        guard let username = currentUser,
              let url = URL(string: "http://127.0.0.1:8000/api/get_pending_requests/\(username)/") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                print("❌ Error: No response when fetching pending requests")
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let pendingRequestsList = json?["pending_requests"] as? [String] {
                    DispatchQueue.main.async {
                        self.friendRequests = pendingRequestsList
                        print("✅ Fetched Pending Requests: \(pendingRequestsList)")
                    }
                } else {
                    print("❌ Error: Invalid pending requests JSON structure")
                }
            } catch {
                print("❌ Error decoding pending requests JSON: \(error)")
            }
        }.resume()
    }

    // ✅ ACCEPT FRIEND REQUEST
    func acceptFriendRequest(from username: String) {
        guard let currentUser = currentUser,
              let url = URL(string: "\(baseURL)/accept_friend_request/") else { 
            print("❌ UserAccountManager: Invalid URL for accepting friend request")
            return 
        }

        print("🔍 UserAccountManager: Accepting friend request from \(username) to \(currentUser)")

        let body: [String: String] = ["from_user": username, "to_user": currentUser]
        let jsonData = try? JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ UserAccountManager: Error accepting friend request: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                let responseString = String(data: data, encoding: .utf8) ?? "N/A"
                print("📩 UserAccountManager: Accept friend request response: \(responseString)")
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
        print("🔒 [UserAccountManager] Starting logout process")
        
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
            print("🧹 [UserAccountManager] Removed username from UserDefaults")
            
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
              let url = URL(string: "\(baseURL)/get_user_profile/\(username)/") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    let certified = json?["is_certified"] as? Bool ?? false
                    DispatchQueue.main.async {
                        self.isCertified = certified
                    }
                } catch {
                    print("Error parsing user profile: \(error)")
                }
            }
        }.resume()
    }
    
}

