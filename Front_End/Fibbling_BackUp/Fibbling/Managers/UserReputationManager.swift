import Foundation
import SwiftUI

class UserReputationManager: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var userRatings: [UserRating] = []
    @Published var userStats: UserReputationStats = UserReputationStats()
    
    // Use APIConfig for consistent URL management
    private let baseURLs = APIConfig.baseURLs
    
    // MARK: - API Methods
    
    func fetchUserReputation(username: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        print("🔵 Attempting to fetch reputation for: \(username)")
        
        // Try each URL in sequence
        tryNextURL(index: 0, endpoint: "get_user_reputation", username: username) { [weak self] success, data in
            guard let self = self, success, let data = data else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Failed to fetch reputation data"
                    completion(false)
                }
                return
            }
            
            self.parseReputationData(data: data, completion: completion)
        }
    }
    
    func fetchUserRatings(username: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        print("🔵 Attempting to fetch ratings for: \(username)")
        
        // Try each URL in sequence
        tryNextURL(index: 0, endpoint: "get_user_ratings", username: username) { [weak self] success, data in
            guard let self = self, success, let data = data else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Failed to fetch ratings data"
                    completion(false)
                }
                return
            }
            
            self.parseRatingsData(data: data, completion: completion)
        }
    }
    
    func submitRating(fromUser: String, toUser: String, eventId: String?, rating: Int, reference: String?, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        print("🔵 Attempting to submit rating from \(fromUser) to \(toUser)")
        
        // Create the rating object
        let userRating = UserRating(
            fromUser: fromUser,
            toUser: toUser,
            eventId: eventId,
            rating: rating,
            reference: reference
        )
        
        // Try each URL in sequence
        trySubmitRating(index: 0, userRating: userRating, completion: completion)
    }
    
    // MARK: - Helper Methods
    
    private func tryNextURL(index: Int, endpoint: String, username: String, completion: @escaping (Bool, Data?) -> Void) {
        // Check if we've tried all URLs
        guard index < baseURLs.count else {
            print("❌ Tried all base URLs, none responded")
            completion(false, nil)
            return
        }
        
        let baseURL = baseURLs[index]
        print("🔵 Trying API URL: \(baseURL)/\(endpoint)/\(username)/")
        
        guard let url = URL(string: "\(baseURL)/\(endpoint)/\(username)/") else {
            // Skip to next URL if this one can't be constructed
            tryNextURL(index: index + 1, endpoint: endpoint, username: username, completion: completion)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("🔵 HTTP Status Code: \(httpResponse.statusCode)")
                
                // If we got a valid response (even an error), log it
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    print("🔵 Response Data: \(dataString)")
                }
                
                // If we got a successful response, return the data
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    completion(true, data)
                    return
                }
            }
            
            if let error = error {
                print("🔵 Network Error with \(baseURL): \(error.localizedDescription)")
            }
            
            // Try the next URL
            self.tryNextURL(index: index + 1, endpoint: endpoint, username: username, completion: completion)
        }
        
        task.resume()
    }
    
    private func trySubmitRating(index: Int, userRating: UserRating, completion: @escaping (Bool) -> Void) {
        // Check if we've tried all URLs
        guard index < baseURLs.count else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Failed to connect to any server"
                print("❌ Tried all base URLs for rating submission, none responded")
                completion(false)
            }
            return
        }
        
        let baseURL = baseURLs[index]
        print("🔵 Trying API URL: \(baseURL)/submit_user_rating/")
        
        guard let url = URL(string: "\(baseURL)/submit_user_rating/") else {
            // Skip to next URL if this one can't be constructed
            trySubmitRating(index: index + 1, userRating: userRating, completion: completion)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create a dictionary that matches the backend's expected format
        let ratingData: [String: Any] = [
            "from_username": userRating.fromUser,
            "to_username": userRating.toUser,
            "event_id": userRating.eventId as Any,
            "rating": userRating.rating,
            "reference": userRating.reference as Any
        ]
        
        // Use JSONSerialization instead of encoder to ensure proper field names
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: ratingData)
            print("🔵 Successfully encoded rating data")
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error encoding data: \(error.localizedDescription)"
                print("❌ Error encoding data: \(error.localizedDescription)")
                completion(false)
            }
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔵 HTTP Status Code: \(httpResponse.statusCode)")
                
                // If we got a valid response (even an error), log it
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    print("🔵 Response Data: \(dataString)")
                }
                
                // If we got a successful response, return success
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        print("✅ Rating submitted successfully")
                        completion(true)
                    }
                    return
                }
            }
            
            if let error = error {
                print("🔵 Network Error with \(baseURL): \(error.localizedDescription)")
            }
            
            // Try the next URL
            self.trySubmitRating(index: index + 1, userRating: userRating, completion: completion)
        }
        
        task.resume()
    }
    
    private func parseReputationData(data: Data, completion: @escaping (Bool) -> Void) {
        do {
            print("🔵 Attempting to parse reputation JSON data")
            
            // Debug: Print raw JSON data
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Raw reputation JSON: \(jsonString)")
            }
            
            let decoder = JSONDecoder()
            let stats = try decoder.decode(UserReputationStats.self, from: data)
            
            DispatchQueue.main.async {
                self.userStats = stats
                self.isLoading = false
                print("✅ Reputation data successfully parsed:")
                print("   Total ratings: \(stats.totalRatings)")
                print("   Average rating: \(stats.averageRating)")
                print("   Events hosted: \(stats.eventsHosted)")
                print("   Events attended: \(stats.eventsAttended)")
                print("   Trust level: \(stats.trustLevel.title)")
                completion(true)
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error parsing reputation data: \(error.localizedDescription)"
                print("❌ Error parsing reputation data: \(error.localizedDescription)")
                print("❌ Error details: \(error)")
                completion(false)
            }
        }
    }
    
    private func parseRatingsData(data: Data, completion: @escaping (Bool) -> Void) {
        do {
            print("🔵 Attempting to parse ratings JSON data")
            
            // Parse the backend response structure
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let ratingsArray = json?["ratings_received"] as? [[String: Any]] else {
                throw NSError(domain: "ParseError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid ratings structure"])
            }
            
            // Convert to UserRating objects
            let decoder = JSONDecoder()
            let ratingsData = try JSONSerialization.data(withJSONObject: ratingsArray)
            let ratings = try decoder.decode([UserRating].self, from: ratingsData)
            
            DispatchQueue.main.async {
                self.userRatings = ratings
                self.isLoading = false
                print("✅ Ratings data successfully parsed: \(ratings.count) ratings")
                completion(true)
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error parsing ratings data: \(error.localizedDescription)"
                print("❌ Error parsing ratings data: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    // Mock implementation for testing without backend
    func mockFetchUserReputation(username: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Mock data based on username
            // More characters in username = higher trust level for demo purposes
            let totalRatings = min(username.count * 5, 60)
            let averageRating = min(Double(username.count) * 0.5, 5.0)
            
            self.userStats = UserReputationStats(
                totalRatings: totalRatings,
                averageRating: averageRating,
                eventsHosted: username.count + 3,
                eventsAttended: username.count * 2 + 5
            )
            
            completion(true)
        }
    }
    
    func mockFetchUserRatings(username: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Create 5 mock ratings with different dates
            var mockRatings: [UserRating] = []
            
            let raterNames = ["Alice", "Bob", "Charlie", "Diana", "Evan"]
            let references = [
                "Great event host, very organized!",
                "Always on time and well prepared.",
                "Made everyone feel welcome and included.",
                "Knowledgeable and patient when explaining concepts.",
                "Would definitely attend another event they organize."
            ]
            
            for i in 0..<min(5, username.count) {
                let daysAgo = Double(i * 7) // Each rating is 1 week apart
                let date = Calendar.current.date(byAdding: .day, value: -Int(daysAgo), to: Date()) ?? Date()
                
                mockRatings.append(UserRating(
                    fromUser: raterNames[i % raterNames.count],
                    toUser: username,
                    eventId: UUID().uuidString,
                    rating: min(i + 3, 5),
                    reference: references[i % references.count],
                    createdAt: date.ISO8601Format()
                ))
            }
            
            self.userRatings = mockRatings
            completion(true)
        }
    }
} 