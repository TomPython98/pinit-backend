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
        
        
        // Try each URL in sequence
        tryNextURL(index: 0, endpoint: "getUserReputation", username: username) { [weak self] success, data in
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
        
        
        // Try each URL in sequence
        tryNextURL(index: 0, endpoint: "getUserRatings", username: username) { [weak self] success, data in
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
            completion(false, nil)
            return
        }
        
        let baseURL = baseURLs[index]
        let endpointPath = APIConfig.endpoints[endpoint] ?? endpoint
        let fullURL = "\(baseURL)\(endpointPath)\(username)/"
        
        guard let url = URL(string: fullURL) else {
            // Skip to next URL if this one can't be constructed
            tryNextURL(index: index + 1, endpoint: endpoint, username: username, completion: completion)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                
                // If we got a valid response (even an error), log it
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                }
                
                // If we got a successful response, return the data
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    completion(true, data)
                    return
                }
            }
            
            if let error = error {
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
                completion(false)
            }
            return
        }
        
        let baseURL = baseURLs[index]
        
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
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error encoding data: \(error.localizedDescription)"
                completion(false)
            }
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let httpResponse = response as? HTTPURLResponse {
                
                // If we got a valid response (even an error), log it
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                }
                
                // If we got a successful response, return success
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        completion(true)
                    }
                    return
                }
            }
            
            if let error = error {
            }
            
            // Try the next URL
            self.trySubmitRating(index: index + 1, userRating: userRating, completion: completion)
        }
        
        task.resume()
    }
    
    private func parseReputationData(data: Data, completion: @escaping (Bool) -> Void) {
        do {
            
            // Debug: Print raw JSON data
            if let jsonString = String(data: data, encoding: .utf8) {
            }
            
            let decoder = JSONDecoder()
            let stats = try decoder.decode(UserReputationStats.self, from: data)
            
            DispatchQueue.main.async {
                self.userStats = stats
                self.isLoading = false
                completion(true)
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error parsing reputation data: \(error.localizedDescription)"
                completion(false)
            }
        }
    }
    
    private func parseRatingsData(data: Data, completion: @escaping (Bool) -> Void) {
        do {
            
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
                completion(true)
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error parsing ratings data: \(error.localizedDescription)"
                completion(false)
            }
        }
    }
    
    // Mock implementation for testing without backend
    func mockFetchUserReputation(username: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // More realistic mock data based on username
            let baseMultiplier = username.count
            
            // Generate realistic stats that match trust level requirements
            let totalRatings = min(baseMultiplier * 2, 15) // Max 15 ratings for demo
            let averageRating = min(3.0 + Double(baseMultiplier) * 0.2, 4.8) // Range 3.0-4.8
            
            // Ensure trust level is appropriate for the stats
            let eventsHosted = baseMultiplier + 2
            let eventsAttended = baseMultiplier * 3 + 5
            
            self.userStats = UserReputationStats(
                totalRatings: totalRatings,
                averageRating: averageRating,
                eventsHosted: eventsHosted,
                eventsAttended: eventsAttended
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