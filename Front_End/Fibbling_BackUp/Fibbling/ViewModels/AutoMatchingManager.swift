import Foundation
import Combine

class AutoMatchingManager: ObservableObject {
    @Published var isLoading = false
    @Published var potentialMatches: [PotentialMatch] = []
    @Published var error: String?
    @Published var matchDetails: [String: MatchDetail] = [:]
    
    // Use APIConfig for consistent URL management
    private let baseURLs = APIConfig.baseURLs
    // Default to the first URL, but will try others if needed
    private var currentBaseURLIndex = 0
    
    private var baseURL: String {
        return baseURLs[currentBaseURLIndex]
    }
    
    init() {
        // Try to determine the best working endpoint at startup
        testEndpoints()
    }
    
    // Tests all endpoints to find the best working one
    private func testEndpoints() {
        print("🔍 Testing API endpoints to find the best one...")
        
        // Try a simple "ping" to each endpoint
        for (index, baseURL) in baseURLs.enumerated() {
            let urlString = "\(baseURL)/ping/"
            guard let url = URL(string: urlString) else { continue }
            
            // Create a semaphore for synchronous testing
            let semaphore = DispatchSemaphore(value: 0)
            var success = false
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let httpResponse = response as? HTTPURLResponse, 
                   httpResponse.statusCode == 200 {
                    print("✅ Found working endpoint: \(urlString)")
                    success = true
                } else {
                    print("❌ Endpoint failed: \(urlString)")
                }
                semaphore.signal()
            }.resume()
            
            // Wait briefly for response
            _ = semaphore.wait(timeout: .now() + 1.0)
            
            if success {
                // Set this as our primary endpoint
                currentBaseURLIndex = index
                print("🎯 Using \(baseURLs[currentBaseURLIndex]) as primary endpoint")
                return
            }
        }
        
        // If we get here, no endpoint responded quickly
        print("⚠️ No quick response from any endpoint, using default: \(baseURLs[0])")
    }
    
    // Helper to try the next URL if one fails
    private func tryNextURL() -> Bool {
        currentBaseURLIndex = (currentBaseURLIndex + 1) % baseURLs.count
        print("🔄 Switching to next API endpoint: \(baseURL)")
        return currentBaseURLIndex != 0 // Return false if we've cycled through all URLs
    }
    
    struct PotentialMatch: Identifiable, Codable {
        let id = UUID()
        let username: String
        let matchScore: Double
        let matchingInterests: [String]
        let interestRatio: Double?
        let scoreBreakdown: ScoreBreakdown?
        
        enum CodingKeys: String, CodingKey {
            case username
            case matchScore = "match_score"
            case matchingInterests = "matching_interests"
            case interestRatio = "interest_ratio"
            case scoreBreakdown = "score_breakdown"
        }
    }
    
    struct ScoreBreakdown: Codable {
        let interestMatch: Double?
        let interestRatio: Double?
        let contentSimilarity: Double?
        let location: Double?
        let social: Double?
        let academicSimilarity: Double?
        let skillRelevance: Double?
        let bioSimilarity: Double?
        let reputationBoost: Double?
        let eventTypePreference: Double?
        let timeCompatibility: Double?
        let activityLevel: Double?
        
        enum CodingKeys: String, CodingKey {
            case interestMatch = "interest_match"
            case interestRatio = "interest_ratio"
            case contentSimilarity = "content_similarity"
            case location
            case social
            case academicSimilarity = "academic_similarity"
            case skillRelevance = "skill_relevance"
            case bioSimilarity = "bio_similarity"
            case reputationBoost = "reputation_boost"
            case eventTypePreference = "event_type_preference"
            case timeCompatibility = "time_compatibility"
            case activityLevel = "activity_level"
        }
    }
    
    struct MatchDetail {
        let username: String
        let totalScore: Double
        let breakdown: ScoreBreakdown?
        let matchingInterests: [String]
        let interestRatio: Double
        
        var topFactors: [String] {
            guard let breakdown = breakdown else { return [] }
            
            var factors: [(String, Double)] = []
            
            if let score = breakdown.interestMatch, score > 0 {
                factors.append(("Interest Match", score))
            }
            if let score = breakdown.academicSimilarity, score > 0 {
                factors.append(("Academic Similarity", score))
            }
            if let score = breakdown.skillRelevance, score > 0 {
                factors.append(("Skill Relevance", score))
            }
            if let score = breakdown.social, score > 0 {
                factors.append(("Social Connection", score))
            }
            if let score = breakdown.location, score > 0 {
                factors.append(("Location", score))
            }
            if let score = breakdown.reputationBoost, score > 0 {
                factors.append(("Reputation", score))
            }
            if let score = breakdown.bioSimilarity, score > 0 {
                factors.append(("Bio Similarity", score))
            }
            if let score = breakdown.contentSimilarity, score > 0 {
                factors.append(("Content Similarity", score))
            }
            if let score = breakdown.eventTypePreference, score > 0 {
                factors.append(("Event Type Preference", score))
            }
            if let score = breakdown.timeCompatibility, score > 0 {
                factors.append(("Time Compatibility", score))
            }
            if let score = breakdown.activityLevel, score > 0 {
                factors.append(("Activity Level", score))
            }
            
            return factors.sorted { $0.1 > $1.1 }.prefix(3).map { $0.0 }
        }
        
        var matchQuality: String {
            if totalScore >= 150 {
                return "Excellent Match"
            } else if totalScore >= 100 {
                return "Great Match"
            } else if totalScore >= 70 {
                return "Good Match"
            } else if totalScore >= 50 {
                return "Fair Match"
            } else {
                return "Basic Match"
            }
        }
    }
    
    struct MatchResponse: Codable {
        let success: Bool
        let potentialMatches: [PotentialMatch]?
        let totalPotentialMatches: Int?
        let eventId: String?
        let eventTitle: String?
        let message: String?
        
        enum CodingKeys: String, CodingKey {
            case success
            case potentialMatches = "potential_matches"
            case totalPotentialMatches = "total_potential_matches"
            case eventId = "event_id"
            case eventTitle = "event_title"
            case message
        }
    }
    
    // Fetch potential matches for an event without immediately inviting them
    func fetchPotentialMatches(forEventId eventId: UUID, completion: @escaping (Result<[PotentialMatch], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/advanced_auto_match/") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        isLoading = true
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "event_id": eventId.uuidString,
            "max_invites": 20,
            "min_score": 30.0,  // Increased minimum score for better quality matches
            "potentials_only": true  // Just fetch potentials without inviting
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    let error = NSError(domain: "No data received", code: 0, userInfo: nil)
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                do {
                    // Try to decode as a MatchResponse
                    let response = try JSONDecoder().decode(MatchResponse.self, from: data)
                    
                    if response.success, let matches = response.potentialMatches {
                        self?.potentialMatches = matches
                        
                        // Process match details for better UI feedback
                        self?.processMatchDetails(matches)
                        
                        completion(.success(matches))
                    } else {
                        let error = NSError(domain: response.message ?? "Unknown error", code: 0, userInfo: nil)
                        self?.error = error.localizedDescription
                        completion(.failure(error))
                    }
                } catch {
                    print("Decoding error: \(error)")
                    self?.error = "Failed to decode response: \(error.localizedDescription)"
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // Process match details to provide better user feedback
    private func processMatchDetails(_ matches: [PotentialMatch]) {
        var details: [String: MatchDetail] = [:]
        
        for match in matches {
            let detail = MatchDetail(
                username: match.username,
                totalScore: match.matchScore,
                breakdown: match.scoreBreakdown,
                matchingInterests: match.matchingInterests,
                interestRatio: match.interestRatio ?? 0.0
            )
            details[match.username] = detail
        }
        
        self.matchDetails = details
    }
    
    // Get detailed explanation for why a user was matched
    func getMatchExplanation(for username: String) -> String {
        guard let detail = matchDetails[username] else {
            return "No detailed information available"
        }
        
        var explanation = "\(detail.matchQuality) - Total Score: \(Int(detail.totalScore))\n\n"
        
        if !detail.matchingInterests.isEmpty {
            explanation += "🎯 Common Interests: \(detail.matchingInterests.joined(separator: ", "))\n"
        }
        
        if detail.interestRatio > 0 {
            explanation += "📊 Interest Match: \(Int(detail.interestRatio * 100))%\n"
        }
        
        if !detail.topFactors.isEmpty {
            explanation += "⭐ Top Factors: \(detail.topFactors.joined(separator: ", "))\n"
        }
        
        return explanation
    }
    
    // Directly invite a specific user to an event
    func inviteUserToEvent(eventId: UUID, username: String, markAsAutoMatched: Bool = false, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/invite_to_event/") else {
            completion(false)
            return
        }
        
        isLoading = true
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "event_id": eventId.uuidString,
            "username": username,
            "mark_as_auto_matched": markAsAutoMatched
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Failed to serialize invitation request: \(error)")
            isLoading = false
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Invitation error: \(error)")
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Successfully invited user \(username) to event")
                    completion(true)
                } else {
                    print("Failed to invite user, unexpected response")
                    completion(false)
                }
            }
        }.resume()
    }
    
    // Update user's interests and auto-matching preferences
    func updateUserInterests(username: String, interests: [String], skills: [String: String], 
                             allowAutoMatching: Bool, preferredRadius: Double, 
                             completion: @escaping (Bool) -> Void) {
        tryUpdateUserInterests(username: username, 
                              interests: interests, 
                              skills: skills, 
                              allowAutoMatching: allowAutoMatching, 
                              preferredRadius: preferredRadius, 
                              retriesLeft: baseURLs.count,
                              completion: completion)
    }
    
    private func tryUpdateUserInterests(username: String, interests: [String], skills: [String: String], 
                                     allowAutoMatching: Bool, preferredRadius: Double, 
                                     retriesLeft: Int,
                                     completion: @escaping (Bool) -> Void) {
        guard retriesLeft > 0 else {
            print("❌ Exhausted all API endpoint attempts")
            isLoading = false
            completion(false)
            return
        }
        
        guard let url = URL(string: "\(baseURL)/update_user_interests/") else {
            print("❌ Invalid URL for updating user interests")
            completion(false)
            return
        }
        
        print("📡 Sending update to \(url.absoluteString)")
        isLoading = true
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "username": username,
            "full_name": "",  // Empty for backward compatibility
            "university": "",  // Empty for backward compatibility
            "degree": "",      // Empty for backward compatibility
            "year": "",        // Empty for backward compatibility
            "bio": "",         // Empty for backward compatibility
            "interests": interests,
            "skills": skills,
            "auto_invite_preference": allowAutoMatching,
            "preferred_radius": preferredRadius
        ]
        
        print("📦 Request body: \(body)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ Failed to serialize interests update: \(error)")
            isLoading = false
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Check for network errors
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                
                // Try the next URL if available
                if self.tryNextURL() {
                    print("🔄 Retrying with next API endpoint")
                    self.tryUpdateUserInterests(
                        username: username,
                        interests: interests, 
                        skills: skills,
                        allowAutoMatching: allowAutoMatching,
                        preferredRadius: preferredRadius,
                        retriesLeft: retriesLeft - 1,
                        completion: completion
                    )
                    return
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        completion(false)
                    }
                    return
                }
            }
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    print("✅ Successfully updated user interests")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        completion(true)
                    }
                } else {
                    print("❌ Server error: \(httpResponse.statusCode)")
                    
                    // Try next URL on server error
                    if self.tryNextURL() {
                        print("🔄 Retrying with next API endpoint due to server error")
                        self.tryUpdateUserInterests(
                            username: username,
                            interests: interests, 
                            skills: skills,
                            allowAutoMatching: allowAutoMatching,
                            preferredRadius: preferredRadius,
                            retriesLeft: retriesLeft - 1,
                            completion: completion
                        )
                        return
                    } else {
                        DispatchQueue.main.async {
                            self.isLoading = false
                            completion(false)
                        }
                    }
                }
            } else {
                print("❌ Unexpected response type")
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(false)
                }
            }
        }.resume()
    }
} 