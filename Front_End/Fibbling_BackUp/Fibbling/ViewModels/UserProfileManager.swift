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

    // Try multiple base URLs to maximize chances of successful connection
    private let baseURLs = [
        "http://127.0.0.1:8000/api",
        "http://localhost:8000/api",
        "http://10.0.0.30:8000/api"
    ]
    
    // MARK: - API Methods
    
    func fetchUserProfile(username: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        print("🔴 Attempting to fetch profile for: \(username)")
        
        // Try each URL in sequence
        tryNextURL(index: 0, username: username, completion: completion)
    }
    
    private func tryNextURL(index: Int, username: String, completion: @escaping (Bool) -> Void) {
        // Check if we've tried all URLs
        guard index < baseURLs.count else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Failed to connect to any server"
                print("❌ Tried all base URLs, none responded")
                completion(false)
            }
            return
        }
        
        let baseURL = baseURLs[index]
        print("🔴 Trying API URL: \(baseURL)/get_user_profile/\(username)/")
        
        guard let url = URL(string: "\(baseURL)/get_user_profile/\(username)/") else {
            // Skip to next URL if this one can't be constructed
            tryNextURL(index: index + 1, username: username, completion: completion)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔴 HTTP Status Code: \(httpResponse.statusCode)")
                
                // If we got a valid response (even an error), log it
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    print("🔴 Response Data: \(dataString)")
                }
                
                // If we got a successful response, parse it
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    self.parseProfileData(data: data, completion: completion)
                    return
                }
            }
            
            if let error = error {
                print("🔴 Network Error with \(baseURL): \(error.localizedDescription)")
            }
            
            // Try the next URL
            self.tryNextURL(index: index + 1, username: username, completion: completion)
        }
        
        print("🔴 Starting URLSession task to fetch profile from \(baseURL)")
        task.resume()
        print("🔴 URLSession task started")
    }
    
    private func parseProfileData(data: Data?, completion: @escaping (Bool) -> Void) {
        guard let data = data else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "No data received from server"
                print("❌ No data received from server")
                completion(false)
            }
            return
        }
        
        do {
            print("🔴 Attempting to parse JSON data")
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            DispatchQueue.main.async {
                // Parse basic profile information
                if let fullName = json?["full_name"] as? String {
                    self.fullName = fullName
                    print("✅ Successfully parsed full_name: \(fullName)")
                } else {
                    print("⚠️ No full_name found in response")
                }
                
                if let university = json?["university"] as? String {
                    self.university = university
                    print("✅ Successfully parsed university: \(university)")
                } else {
                    print("⚠️ No university found in response")
                }
                
                if let degree = json?["degree"] as? String {
                    self.degree = degree
                    print("✅ Successfully parsed degree: \(degree)")
                } else {
                    print("⚠️ No degree found in response")
                }
                
                if let year = json?["year"] as? String {
                    self.year = year
                    print("✅ Successfully parsed year: \(year)")
                } else {
                    print("⚠️ No year found in response")
                }
                
                if let bio = json?["bio"] as? String {
                    self.bio = bio
                    print("✅ Successfully parsed bio: \(bio)")
                } else {
                    print("⚠️ No bio found in response")
                }
                
                // Parse interests
                if let interestsArray = json?["interests"] as? [String] {
                    self.interests = interestsArray
                    print("✅ Successfully parsed interests: \(interestsArray)")
                } else {
                    print("⚠️ No interests found in response")
                }
                
                // Parse skills
                if let skillsDict = json?["skills"] as? [String: String] {
                    self.skills = skillsDict
                    print("✅ Successfully parsed skills: \(skillsDict)")
                } else {
                    print("⚠️ No skills found in response")
                }
                
                // Parse auto-matching preferences
                if let autoInviteEnabled = json?["auto_invite_enabled"] as? Bool {
                    self.autoInviteEnabled = autoInviteEnabled
                    print("✅ Successfully parsed auto_invite_enabled: \(autoInviteEnabled)")
                } else {
                    print("⚠️ No auto_invite_enabled found in response")
                }
                
                // Parse preferred radius
                if let radius = json?["preferred_radius"] as? Double {
                    self.preferredRadius = radius
                    print("✅ Successfully parsed preferred_radius: \(radius)")
                } else {
                    print("⚠️ No preferred_radius found in response")
                }
                
                // Parse certification status
                if let isCertified = json?["is_certified"] as? Bool {
                    self.isCertified = isCertified
                    print("✅ Successfully parsed is_certified: \(isCertified)")
                } else {
                    print("⚠️ No is_certified found in response")
                }
                
                self.isLoading = false
                print("✅ Profile data successfully parsed")
                completion(true)
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error parsing profile data: \(error.localizedDescription)"
                print("❌ Error parsing profile data: \(error.localizedDescription)")
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
        
        print("🔵 Attempting to update profile for: \(username)")
        
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
                print("❌ Tried all base URLs for update, none responded")
                completion(false)
            }
            return
        }
        
        let baseURL = baseURLs[index]
        print("🔵 Trying API URL: \(baseURL)/update_user_interests/")
        
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
        
        print("🔵 Request parameters: \(parameters)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            print("🔵 Successfully encoded request body")
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error encoding data: \(error.localizedDescription)"
                print("❌ Error encoding data: \(error.localizedDescription)")
                completion(false)
            }
            return
        }
        
        print("🔵 Starting URLSession task to update profile from \(baseURL)")
        
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
                        print("✅ Profile updated successfully")
                        completion(true)
                    }
                    return
                }
            }
            
            if let error = error {
                print("🔵 Network Error with \(baseURL): \(error.localizedDescription)")
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
        print("🔵 URLSession task started")
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
                    print("🟢 Profile Completion Response Data: \(dataString)")
                }
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    self.parseProfileCompletionData(data: data, completion: completion)
                    return
                }
            }
            if let error = error {
                print("🟢 Network Error (profile completion): \(error.localizedDescription)")
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
            "Vienna University of Technology",
            "University of Vienna",
            "Medical University of Vienna",
            "University of Natural Resources and Life Sciences",
            "Vienna University of Economics and Business",
            "Academy of Fine Arts Vienna",
            "University of Applied Arts Vienna",
            "University of Music and Performing Arts Vienna",
            "Central European University",
            "Webster University Vienna"
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