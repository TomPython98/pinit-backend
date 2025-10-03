//
//  StudyEvent.swift
//  YourProjectName
//
//  Created by Your Name on 2025-03-XX.
//

import Foundation
import MapKit

enum EventType: String, Codable, CaseIterable, Identifiable {
    case study, party, business, other, cultural, academic, networking, social, language_exchange
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .study:    return "Study"
        case .party:    return "Party"
        case .business: return "Business"
        case .cultural: return "Cultural"
        case .academic: return "Academic"
        case .networking: return "Networking"
        case .social: return "Social"
        case .language_exchange: return "Language Exchange"
        case .other:    return "Other"
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawString = try container.decode(String.self).lowercased()
        self = EventType(rawValue: rawString) ?? .other
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

struct StudyEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let coordinate: CLLocationCoordinate2D
    let time: Date
    let endTime: Date
    var description: String?
    var invitedFriends: [String]
    var attendees: [String]
    var isPublic: Bool
    var host: String
    var hostIsCertified: Bool
    var eventType: EventType
    var isAutoMatched: Bool?
    var interestTags: [String]?
    var matchedUsers: [String]?

    enum CodingKeys: String, CodingKey {
        case id, title, time, description, invitedFriends = "invitedFriends",
             attendees, isPublic, host, hostIsCertified, latitude, longitude
        case endTime = "end_time"
        case eventType = "event_type"  // Make sure this exactly matches the JSON
        case isAutoMatched = "isAutoMatched" // Add the new field
        case interestTags = "interest_tags"  // Add mapping for interest tags
        case matchedUsers = "matchedUsers"   // Add mapping for matched users
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        isPublic = try container.decode(Bool.self, forKey: .isPublic)
        host = try container.decode(String.self, forKey: .host)
        hostIsCertified = (try? container.decode(Bool.self, forKey: .hostIsCertified)) ?? false
        description = try container.decodeIfPresent(String.self, forKey: .description)
        invitedFriends = (try? container.decode([String].self, forKey: .invitedFriends)) ?? []
        attendees = (try? container.decode([String].self, forKey: .attendees)) ?? []
        isAutoMatched = try? container.decodeIfPresent(Bool.self, forKey: .isAutoMatched)
        if let autoMatched = isAutoMatched {
        } else {
        }
        interestTags = try? container.decodeIfPresent([String].self, forKey: .interestTags)
        matchedUsers = try? container.decodeIfPresent([String].self, forKey: .matchedUsers)
        
        // In StudyEvent struct, modify the decoder for event_type:

        if let rawType = try? container.decode(String.self, forKey: .eventType) {
            // Normalize the string by trimming and converting to lowercase
            let normalizedType = rawType.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Try to match with the enum cases
            if let parsedType = EventType(rawValue: normalizedType) {
                eventType = parsedType
            } else {
                // If no match is found, default to .other but log the issue
                eventType = .other
            }
        } else {
            eventType = .other
        }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Handle start time
        let startStr = try container.decode(String.self, forKey: .time)
        if let startDate = StudyEvent.parseDate(from: startStr, formatter: isoFormatter) {
            time = startDate
        } else {
            throw DecodingError.dataCorruptedError(forKey: .time, in: container, debugDescription: "Invalid date format for 'time'")
        }
        
        // Handle end time
        let endStr = try container.decode(String.self, forKey: .endTime)
        if let endDate = StudyEvent.parseDate(from: endStr, formatter: isoFormatter) {
            endTime = endDate
        } else {
            // If end time can't be parsed, default to start time + 1 hour
            endTime = time.addingTimeInterval(3600)
        }
        
        let lat = try container.decode(Double.self, forKey: .latitude)
        let lon = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(isPublic, forKey: .isPublic)
        try container.encode(host, forKey: .host)
        try container.encode(hostIsCertified, forKey: .hostIsCertified)
        try container.encode(description, forKey: .description)
        try container.encode(invitedFriends, forKey: .invitedFriends)
        try container.encode(attendees, forKey: .attendees)
        try container.encode(eventType, forKey: .eventType)
        if let isAutoMatched = isAutoMatched {
            try container.encode(isAutoMatched, forKey: .isAutoMatched)
        }
        if let interestTags = interestTags {
            try container.encode(interestTags, forKey: .interestTags)
        }
        if let matchedUsers = matchedUsers {
            try container.encode(matchedUsers, forKey: .matchedUsers)
        }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(isoFormatter.string(from: time), forKey: .time)
        try container.encode(isoFormatter.string(from: endTime), forKey: .endTime)
        
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
    
    private static func parseDate(from string: String, formatter: ISO8601DateFormatter) -> Date? {
        // First try with the standard formatter
        if let date = formatter.date(from: string) { 
            return date 
        }
        
        // If that fails, we might have microseconds instead of milliseconds
        // Try to handle microsecond precision by truncating to milliseconds
        if string.contains(".") {
            // For example: "2025-04-19T14:08:14.583000+00:00"
            let components = string.split(separator: ".")
            if components.count == 2 {
                let beforeDecimal = components[0]
                let afterDecimal = components[1]
                
                // Take the part after decimal and truncate to 3 digits for milliseconds
                // Then add back the timezone part
                if afterDecimal.count > 3 {
                    let milliseconds = afterDecimal.prefix(3)
                    let timezonePart = afterDecimal.dropFirst(6) // Drop the microseconds
                    let modifiedString = "\(beforeDecimal).\(milliseconds)\(timezonePart)"
                    
                    
                    // Try parsing with the modified string
                    if let date = formatter.date(from: modifiedString) {
                        return date
                    }
                }
            }
        }
        
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) {
            return date
        }
        
        // Last resort: try to manually parse the date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = dateFormatter.date(from: String(string.prefix(19))) {
            return date
        }
        
        return nil
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        coordinate: CLLocationCoordinate2D,
        time: Date,
        endTime: Date,
        description: String? = nil,
        invitedFriends: [String] = [],
        attendees: [String] = [],
        isPublic: Bool,
        host: String,
        hostIsCertified: Bool = false,
        eventType: EventType,
        isAutoMatched: Bool? = nil,
        interestTags: [String]? = nil,
        matchedUsers: [String]? = nil
    ) {
        self.id = id
        self.title = title
        self.coordinate = coordinate
        self.time = time
        self.endTime = endTime
        self.description = description
        self.invitedFriends = invitedFriends
        self.attendees = attendees
        self.isPublic = isPublic
        self.host = host
        self.hostIsCertified = hostIsCertified
        self.eventType = eventType
        self.isAutoMatched = isAutoMatched
        self.interestTags = interestTags
        self.matchedUsers = matchedUsers
    }
    
    static func == (lhs: StudyEvent, rhs: StudyEvent) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.time == rhs.time &&
        lhs.endTime == rhs.endTime &&
        lhs.description == rhs.description &&
        lhs.invitedFriends == rhs.invitedFriends &&
        lhs.attendees == rhs.attendees &&
        lhs.isPublic == rhs.isPublic &&
        lhs.host == rhs.host &&
        lhs.hostIsCertified == rhs.hostIsCertified &&
        lhs.eventType == rhs.eventType &&
        lhs.isAutoMatched == rhs.isAutoMatched &&
        lhs.interestTags == rhs.interestTags &&
        lhs.matchedUsers == rhs.matchedUsers
    }
}
