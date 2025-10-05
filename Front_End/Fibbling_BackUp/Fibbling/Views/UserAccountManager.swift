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
        let registerURL = APIConfig.fullURL(for: "register")
        print("🔍 Registration URL: \(registerURL)")
        
        guard let url = URL(string: registerURL) else {
            completion(false, "Invalid URL")
            return
        }
        
        let body: [String: String] = ["username": username, "password": password]
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        print("📤 Registration body: \(body)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            print("📡 Registration response received")
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 Registration status code: \(httpResponse.statusCode)")
            }
            
            if let error = error {
                print("❌ Registration error: \(error.localizedDescription)")
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(false, "No response from server.")
                }
                return
            }
            
            if let dataString = String(data: data, encoding: .utf8) {
                print("📄 Registration response data: \(dataString)")
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let success = json?["success"] as? Bool ?? false
                let message = json?["message"] as? String ?? "Unknown error."
                
                print("✅ Registration success: \(success), message: \(message)")

                DispatchQueue.main.async {
                    if success {
                        self.currentUser = username
                        // Also save to UserDefaults for persistence
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        UserDefaults.standard.set(username, forKey: "username")
                        print("💾 User data saved to UserDefaults")
                    }
                    completion(success, message)
                }
            } catch {
                print("❌ Registration JSON parsing error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false, "Invalid response from server.")
                }
            }
        }.resume()
    }

    // ✅ LOGIN USER & FETCH FRIENDS
    func login(username: String, password: String, completion: @escaping (Bool, String) -> Void) {
        let loginURL = APIConfig.fullURL(for: "login")
        guard let url = URL(string: loginURL) else {
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
            return 
        }


        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                return
            }
            
            guard let data = data else {
                return
            }

            do {
                // ✅ Print raw response before decoding
                let rawJSON = String(data: data, encoding: .utf8) ?? "N/A"

                let decodedResponse = try JSONDecoder().decode([String: [String]].self, from: data)

                if let friendsList = decodedResponse["friends"] {
                    DispatchQueue.main.async {
                        self.friends = friendsList
                    }
                } else {
                    DispatchQueue.main.async {
                        self.friends = []
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.friends = []
                }
            }
        }.resume()
    }

    func fetchFriendRequests() {
        guard let username = currentUser,
              let url = URL(string: "\(baseURL)/get_pending_requests/\(username)/") else { 
            return 
        }


        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                // Parse the response properly
                let rawJSON = String(data: data, encoding: .utf8) ?? "N/A"
                
                let decodedResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                if let pendingRequests = decodedResponse?["pending_requests"] as? [String] {
                    DispatchQueue.main.async {
                        self.friendRequests = pendingRequests
                    }
                } else {
                    DispatchQueue.main.async {
                        self.friendRequests = []
                    }
                }
            } catch {
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
            return 
        }
        
        
        let body: [String: String] = ["from_user": currentUser, "to_user": username]
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
                }
            }
        }.resume()
    }
    
}

