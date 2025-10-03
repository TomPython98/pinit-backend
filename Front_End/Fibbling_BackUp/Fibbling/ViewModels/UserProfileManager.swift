import Foundation
import SwiftUI

class UserProfileManager: ObservableObject {
    // Basic profile information
    @Published var fullName: String = ""
    @Published var university: String = ""
    @Published var degree: String = ""
    @Published var year: String = ""
    @Published var bio: String = ""
    
    // Smart matching preferences
    @Published var interests: [String] = []
    @Published var skills: [String: String] = [:]
    @Published var isCertified: Bool = false
    @Published var autoInviteEnabled: Bool = true
    @Published var preferredRadius: Double = 10.0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Profile completion details from backend
    @Published var completionPercentage: Double = 0.0
    @Published var missingItems: [String] = []
    @Published var benefitsMessage: String = ""
    @Published var completionLevel: String = ""
    @Published var categoryBreakdown: [String: [String: Any]] = [:]

    // Use APIConfig for consistent URL management
    private let baseURLs = APIConfig.baseURLs
    
    // MARK: - API Methods
    
    func fetchUserProfile(username: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        
        // Try each URL in sequence
        tryNextURL(index: 0, username: username, completion: completion)
    }
    
    private func tryNextURL(index: Int, username: String, completion: @escaping (Bool) -> Void) {
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
        
        guard let url = URL(string: "\(baseURL)/get_user_profile/\(username)/") else {
            // Skip to next URL if this one can't be constructed
            tryNextURL(index: index + 1, username: username, completion: completion)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let httpResponse = response as? HTTPURLResponse {
                
                // If we got a valid response (even an error), log it
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                }
                
                // If we got a successful response, parse it
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    self.parseProfileData(data: data, completion: completion)
                    return
                }
            }
            
            if let error = error {
            }
            
            // Try the next URL
            self.tryNextURL(index: index + 1, username: username, completion: completion)
        }
        
        task.resume()
    }
    
    private func parseProfileData(data: Data?, completion: @escaping (Bool) -> Void) {
        guard let data = data else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "No data received from server"
                completion(false)
            }
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            DispatchQueue.main.async {
                // Parse basic profile information
                if let fullName = json?["full_name"] as? String {
                    self.fullName = fullName
                } else {
                }
                
                if let university = json?["university"] as? String {
                    self.university = university
                } else {
                }
                
                if let degree = json?["degree"] as? String {
                    self.degree = degree
                } else {
                }
                
                if let year = json?["year"] as? String {
                    self.year = year
                } else {
                }
                
                if let bio = json?["bio"] as? String {
                    self.bio = bio
                } else {
                }
                
                // Parse interests
                if let interestsArray = json?["interests"] as? [String] {
                    self.interests = interestsArray
                } else {
                }
                
                // Parse skills
                if let skillsDict = json?["skills"] as? [String: String] {
                    self.skills = skillsDict
                } else {
                }
                
                // Parse auto-matching preferences
                if let autoInviteEnabled = json?["auto_invite_enabled"] as? Bool {
                    self.autoInviteEnabled = autoInviteEnabled
                } else {
                }
                
                // Parse preferred radius
                if let radius = json?["preferred_radius"] as? Double {
                    self.preferredRadius = radius
                } else {
                }
                
                // Parse certification status
                if let isCertified = json?["is_certified"] as? Bool {
                    self.isCertified = isCertified
                } else {
                }
                
                self.isLoading = false
                completion(true)
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error parsing profile data: \(error.localizedDescription)"
                completion(false)
            }
        }
    }
    
    func updateUserProfile(
        username: String,
        fullName: String,
        university: String,
        degree: String,
        year: String,
        bio: String,
        interests: [String],
        skills: [String: String],
        autoInviteEnabled: Bool,
        preferredRadius: Double,
        completion: @escaping (Bool) -> Void
    ) {
        isLoading = true
        errorMessage = nil
        
        
        // Try each URL in sequence
        tryUpdateWithNextURL(index: 0, 
                            username: username,
                            fullName: fullName,
                            university: university,
                            degree: degree,
                            year: year,
                            bio: bio,
                            interests: interests,
                            skills: skills,
                            autoInviteEnabled: autoInviteEnabled,
                            preferredRadius: preferredRadius,
                            completion: completion)
    }
    
    private func tryUpdateWithNextURL(
        index: Int,
        username: String,
        fullName: String,
        university: String,
        degree: String,
        year: String,
        bio: String,
        interests: [String],
        skills: [String: String],
        autoInviteEnabled: Bool,
        preferredRadius: Double,
        completion: @escaping (Bool) -> Void
    ) {
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
        
        guard let url = URL(string: "\(baseURL)/update_user_interests/") else {
            // Skip to next URL if this one can't be constructed
            tryUpdateWithNextURL(index: index + 1, 
                               username: username,
                               fullName: fullName,
                               university: university,
                               degree: degree,
                               year: year,
                               bio: bio,
                               interests: interests,
                               skills: skills,
                               autoInviteEnabled: autoInviteEnabled,
                               preferredRadius: preferredRadius,
                               completion: completion)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "username": username,
            "full_name": fullName,
            "university": university,
            "degree": degree,
            "year": year,
            "bio": bio,
            "interests": interests,
            "skills": skills,
            "auto_invite_preference": autoInviteEnabled,
            "preferred_radius": preferredRadius
        ]
        
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
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
            self.tryUpdateWithNextURL(
                index: index + 1,
                username: username,
                fullName: fullName,
                university: university,
                degree: degree,
                year: year,
                bio: bio,
                interests: interests,
                skills: skills,
                autoInviteEnabled: autoInviteEnabled,
                preferredRadius: preferredRadius,
                completion: completion
            )
        }
        
        task.resume()
    }
    
    // Fetch profile completion details from backend
    func fetchProfileCompletion(username: String, completion: @escaping (Bool) -> Void) {
        // Try each URL in sequence
        tryNextCompletionURL(index: 0, username: username, completion: completion)
    }
    
    private func tryNextCompletionURL(index: Int, username: String, completion: @escaping (Bool) -> Void) {
        guard index < baseURLs.count else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to fetch profile completion from any server"
                completion(false)
            }
            return
        }
        let baseURL = baseURLs[index]
        guard let url = URL(string: "\(baseURL)/profile_completion/\(username)/") else {
            tryNextCompletionURL(index: index + 1, username: username, completion: completion)
            return
        }
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            if let httpResponse = response as? HTTPURLResponse {
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                }
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    self.parseProfileCompletionData(data: data, completion: completion)
                    return
                }
            }
            if let error = error {
            }
            self.tryNextCompletionURL(index: index + 1, username: username, completion: completion)
        }
        task.resume()
    }
    
    private func parseProfileCompletionData(data: Data?, completion: @escaping (Bool) -> Void) {
        guard let data = data else {
            DispatchQueue.main.async {
                self.errorMessage = "No data received from server (profile completion)"
                completion(false)
            }
            return
        }
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            DispatchQueue.main.async {
                self.completionPercentage = (json?["completion_percentage"] as? Double) ?? 0.0
                self.missingItems = (json?["missing_items"] as? [String]) ?? []
                self.benefitsMessage = (json?["benefits_message"] as? String) ?? ""
                self.completionLevel = (json?["completion_level"] as? String) ?? ""
                self.categoryBreakdown = (json?["category_breakdown"] as? [String: [String: Any]]) ?? [:]
                completion(true)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Error parsing profile completion data: \(error.localizedDescription)"
                completion(false)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func getSuggestedInterests() -> [String] {
        return [
            "Math", "Physics", "Chemistry", "Biology", "Computer Science",
            "History", "Literature", "Philosophy", "Psychology", "Art",
            "Music", "Business", "Economics", "Law", "Medicine",
            "Engineering", "Languages", "Cooking", "Sports", "Gaming"
        ]
    }
    
    func getSkillLevels() -> [String] {
        return ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"]
    }
    
    func getSuggestedUniversities() -> [String] {
        return [
            "University of Buenos Aires",
            "National University of La Plata",
            "University of San Andrés",
            "Torcuato Di Tella University",
            "University of Belgrano",
            "University of Palermo",
            "University of Salvador",
            "National University of Córdoba",
            "National University of Rosario",
            "University of San Martín"
        ]
    }
    
    func getSuggestedDegrees() -> [String] {
        return [
            "Computer Science",
            "Software Engineering",
            "Information Systems",
            "Mathematics",
            "Physics",
            "Chemistry",
            "Biology",
            "Medicine",
            "Law",
            "Business Administration",
            "Economics",
            "Psychology",
            "Philosophy",
            "History",
            "Literature",
            "Art",
            "Music",
            "Architecture",
            "Engineering",
            "Education"
        ]
    }
    
    func getSuggestedYears() -> [String] {
        return [
            "1st Year",
            "2nd Year", 
            "3rd Year",
            "4th Year",
            "5th Year",
            "Master's 1st Year",
            "Master's 2nd Year",
            "PhD Student",
            "Graduate"
        ]
    }
} 