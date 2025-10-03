import Foundation

struct APIConfig {
    // MARK: - Environment Configuration
    
    #if DEBUG
    // Development URLs - prioritize production for TestFlight builds
    static let baseURLs = [
        "https://pinit-backend-production.up.railway.app/api",
        "https://pin-it.net/api",
        "https://api.pin-it.net/api",
        "http://127.0.0.1:8000/api",
        "http://localhost:8000/api",
        "http://10.0.0.30:8000/api"
    ]
    static let serverBaseURL = "https://pinit-backend-production.up.railway.app"
    static let isProduction = true  // Force production mode for TestFlight
    #else
    // Production URLs - for App Store release
    static let baseURLs = [
        "https://pinit-backend-production.up.railway.app/api",
        "https://pin-it.net/api",
        "https://api.pin-it.net/api"
    ]
    static let serverBaseURL = "https://pinit-backend-production.up.railway.app"
    static let isProduction = true
    #endif
    
    // MARK: - API Endpoints
    
    static var primaryBaseURL: String {
        return baseURLs.first ?? ""
    }
    
    // Common endpoints
    static let endpoints = [
        "register": "/register_user/",
        "login": "/login_user/",
        "getUserProfile": "/get_user_profile/",
        "updateProfile": "/update_user_profile/",
        "getEvents": "/get_study_events/",
        "createEvent": "/create_study_event/",
        "getFriends": "/get_friends/",
        "sendFriendRequest": "/send_friend_request/",
        "getFriendRequests": "/get_friend_requests/",
        "acceptFriendRequest": "/accept_friend_request/",
        "getUserReputation": "/get_user_reputation/",
        "getUserRatings": "/get_user_ratings/",
        "rateUser": "/rate_user/",
        "getPotentialMatches": "/get_potential_matches/",
        "getMatchDetails": "/get_match_details/"
    ]
    
    // MARK: - Helper Methods
    
    static func fullURL(for endpoint: String, baseURL: String? = nil) -> String {
        let base = baseURL ?? primaryBaseURL
        let endpointPath = endpoints[endpoint] ?? endpoint
        return base + endpointPath
    }
    
    static func allURLsFor(endpoint: String) -> [String] {
        return baseURLs.map { baseURL in
            let endpointPath = endpoints[endpoint] ?? endpoint
            return baseURL + endpointPath
        }
    }
    
    // MARK: - Push Notifications
    
    static var pushNotificationTopic: String {
        return isProduction ? "com.pinit.app" : "com.pinit.app.dev"
    }
    
    // MARK: - WebSocket Configuration
    
    static var websocketURL: String {
        return isProduction ? "wss://pinit-backend-production.up.railway.app/ws/" : "ws://127.0.0.1:8000/ws/"
    }
}

// MARK: - URL Testing Helper

extension APIConfig {
    static func testConnection(to url: String, completion: @escaping (Bool) -> Void) {
        guard let testURL = URL(string: url + "/health/") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: testURL)
        request.timeoutInterval = 5.0
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                completion(httpResponse.statusCode == 200)
            } else {
                completion(false)
            }
        }.resume()
    }
    
    static func findWorkingBaseURL(completion: @escaping (String?) -> Void) {
        let group = DispatchGroup()
        var workingURL: String?
        
        for url in baseURLs {
            group.enter()
            testConnection(to: url) { isWorking in
                if isWorking && workingURL == nil {
                    workingURL = url
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(workingURL)
        }
    }
}
