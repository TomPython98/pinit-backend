import Foundation

struct UserRating: Identifiable, Codable, Equatable {
    let id: String  // Changed from UUID to String to match backend
    let fromUser: String
    let toUser: String
    let eventId: String?  // Changed from UUID? to String? to match backend
    let rating: Int // 1-5 stars
    let reference: String?
    let createdAt: String  // Changed from Date to String to match backend
    
    enum CodingKeys: String, CodingKey {
        case id
        case fromUser = "from_username"
        case toUser = "to_username"
        case eventId = "event_id"
        case rating
        case reference
        case createdAt = "created_at"
    }
    
    init(id: String = UUID().uuidString, fromUser: String, toUser: String, eventId: String? = nil, rating: Int, reference: String? = nil, createdAt: String = Date().ISO8601Format()) {
        self.id = id
        self.fromUser = fromUser
        self.toUser = toUser
        self.eventId = eventId
        self.rating = max(1, min(5, rating)) // Ensure rating is between 1-5
        self.reference = reference
        self.createdAt = createdAt
    }
}

struct UserTrustLevel: Codable, Equatable {
    var level: Int
    var title: String
    var requiredRatings: Int
    var minAverageRating: Double
    
    static let levels: [UserTrustLevel] = [
        UserTrustLevel(level: 1, title: "Newcomer", requiredRatings: 0, minAverageRating: 0.0),
        UserTrustLevel(level: 2, title: "Participant", requiredRatings: 3, minAverageRating: 3.0),
        UserTrustLevel(level: 3, title: "Trusted Member", requiredRatings: 10, minAverageRating: 3.5),
        UserTrustLevel(level: 4, title: "Event Expert", requiredRatings: 20, minAverageRating: 4.0),
        UserTrustLevel(level: 5, title: "Community Leader", requiredRatings: 50, minAverageRating: 4.5)
    ]
    
    static func getLevelForStats(totalRatings: Int, averageRating: Double) -> UserTrustLevel {
        var highestMatchingLevel = levels[0]
        
        for level in levels {
            if totalRatings >= level.requiredRatings && averageRating >= level.minAverageRating {
                highestMatchingLevel = level
            } else {
                break
            }
        }
        
        return highestMatchingLevel
    }
    
    // Regular initializer for creating instances programmatically
    init(level: Int, title: String, requiredRatings: Int, minAverageRating: Double) {
        self.level = level
        self.title = title
        self.requiredRatings = requiredRatings
        self.minAverageRating = minAverageRating
    }
    
    // Custom decoder to handle backend response that only has level and title
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        level = try container.decode(Int.self, forKey: .level)
        title = try container.decode(String.self, forKey: .title)
        
        // Set default values for fields not provided by backend
        requiredRatings = 0
        minAverageRating = 0.0
        
        // Try to find matching level from static levels array
        if let matchingLevel = UserTrustLevel.levels.first(where: { $0.level == level && $0.title == title }) {
            requiredRatings = matchingLevel.requiredRatings
            minAverageRating = matchingLevel.minAverageRating
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(level, forKey: .level)
        try container.encode(title, forKey: .title)
        try container.encode(requiredRatings, forKey: .requiredRatings)
        try container.encode(minAverageRating, forKey: .minAverageRating)
    }
    
    enum CodingKeys: String, CodingKey {
        case level, title, requiredRatings, minAverageRating
    }
}

struct UserReputationStats: Codable, Equatable {
    var totalRatings: Int
    var averageRating: Double
    var trustLevel: UserTrustLevel
    var eventsHosted: Int
    var eventsAttended: Int
    
    init(totalRatings: Int = 0, 
         averageRating: Double = 0.0, 
         eventsHosted: Int = 0, 
         eventsAttended: Int = 0) {
        self.totalRatings = totalRatings
        self.averageRating = averageRating
        self.eventsHosted = eventsHosted
        self.eventsAttended = eventsAttended
        self.trustLevel = UserTrustLevel.getLevelForStats(totalRatings: totalRatings, averageRating: averageRating)
    }
    
    enum CodingKeys: String, CodingKey {
        case totalRatings = "total_ratings"
        case averageRating = "average_rating"
        case eventsHosted = "events_hosted"
        case eventsAttended = "events_attended"
        case trustLevel = "trust_level"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        totalRatings = try container.decode(Int.self, forKey: .totalRatings)
        averageRating = try container.decode(Double.self, forKey: .averageRating)
        eventsHosted = try container.decode(Int.self, forKey: .eventsHosted)
        eventsAttended = try container.decode(Int.self, forKey: .eventsAttended)
        
        // Decode the nested trust_level object
        trustLevel = try container.decode(UserTrustLevel.self, forKey: .trustLevel)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(totalRatings, forKey: .totalRatings)
        try container.encode(averageRating, forKey: .averageRating)
        try container.encode(eventsHosted, forKey: .eventsHosted)
        try container.encode(eventsAttended, forKey: .eventsAttended)
        try container.encode(trustLevel, forKey: .trustLevel)
    }
} 