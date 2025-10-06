import Foundation
import SwiftUI

// MARK: - UserImage Model
struct UserImage: Identifiable, Codable, Hashable {
    let id: String
    let url: String
    let imageType: ImageType
    let isPrimary: Bool
    let caption: String
    let uploadedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case url
        case imageType = "image_type"
        case isPrimary = "is_primary"
        case caption
        case uploadedAt = "uploaded_at"
    }
    
    enum ImageType: String, CaseIterable, Codable {
        case profile = "profile"
        case gallery = "gallery"
        case cover = "cover"
        
        var displayName: String {
            switch self {
            case .profile: return "Profile Picture"
            case .gallery: return "Gallery Image"
            case .cover: return "Cover Photo"
            }
        }
        
        var icon: String {
            switch self {
            case .profile: return "person.circle"
            case .gallery: return "photo"
            case .cover: return "rectangle.3.group"
            }
        }
    }
    
    // Computed property for formatted upload date
    var formattedUploadDate: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: uploadedAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return uploadedAt
    }
}

// MARK: - User Images Response
struct UserImagesResponse: Codable {
    let success: Bool
    let images: [UserImage]
    let count: Int
}

// MARK: - Image Upload Response
struct ImageUploadResponse: Codable {
    let success: Bool
    let message: String
    let image: UserImage?
}

// MARK: - Image Upload Request
struct ImageUploadRequest {
    let username: String
    let imageData: Data
    let imageType: UserImage.ImageType
    let isPrimary: Bool
    let caption: String
    let filename: String
    
    var mimeType: String {
        // Determine MIME type based on image data
        if imageData.starts(with: [0xFF, 0xD8, 0xFF]) {
            return "image/jpeg"
        } else if imageData.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return "image/png"
        } else if imageData.starts(with: [0x47, 0x49, 0x46]) {
            return "image/gif"
        } else if imageData.starts(with: [0x52, 0x49, 0x46, 0x46]) {
            return "image/webp"
        }
        return "image/jpeg" // Default fallback
    }
    
    var fileExtension: String {
        switch mimeType {
        case "image/jpeg": return "jpg"
        case "image/png": return "png"
        case "image/gif": return "gif"
        case "image/webp": return "webp"
        default: return "jpg"
        }
    }
}
