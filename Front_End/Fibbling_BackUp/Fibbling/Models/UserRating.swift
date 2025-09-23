import Foundation

struct UserRating: Identifiable, Codable, Equatable {
    let id: UUID
    let fromUser: String
    let toUser: String
    let eventId: UUID?
    let rating: Int // 1-5 stars
    let reference: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case fromUser = "from_username"
        case toUser = "to_username"
        case eventId = "event_id"
        case rating
        case reference
        case createdAt = "created_at"
    }
    
    init(id: UUID = UUID(), fromUser: String, toUser: String, eventId: UUID? = nil, rating: Int, reference: String? = nil, createdAt: Date = Date()) {
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
} 