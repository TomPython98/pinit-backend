import Foundation

/// Comprehensive error types for the PinIt app
enum AppError: LocalizedError {
    // MARK: - Network Errors
    case networkError(String)
    case noInternetConnection
    case requestTimeout
    case serverError(Int)
    case invalidResponse
    case invalidURL
    
    // MARK: - Authentication Errors
    case authenticationFailed
    case tokenExpired
    case unauthorizedAccess
    case accountDeleted
    
    // MARK: - Data Errors
    case decodingError(String)
    case encodingError(String)
    case dataCorrupted
    case missingRequiredField(String)
    
    // MARK: - Validation Errors
    case invalidEmail
    case invalidPassword(String)
    case passwordMismatch
    case invalidInput(String)
    case fieldTooLong(String, Int)
    
    // MARK: - Image Errors
    case imageUploadFailed(String)
    case imageDownloadFailed
    case imageTooLarge
    case invalidImageFormat
    
    // MARK: - Event Errors
    case eventCreationFailed(String)
    case eventNotFound
    case eventUpdateFailed(String)
    case eventInPast
    
    // MARK: - User Errors
    case userNotFound
    case usernameAlreadyExists
    case profileUpdateFailed(String)
    
    // MARK: - Cache Errors
    case cacheReadError
    case cacheWriteError
    
    // MARK: - WebSocket Errors
    case websocketConnectionFailed
    case websocketDisconnected
    
    // MARK: - Location Errors
    case locationPermissionDenied
    case locationUnavailable
    
    // MARK: - Unknown
    case unknown(String)
    
    // MARK: - Error Descriptions
    var errorDescription: String? {
        switch self {
        // Network
        case .networkError(let message):
            return "Network error: \(message)"
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
        case .requestTimeout:
            return "Request timed out. Please try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .invalidResponse:
            return "Invalid response from server."
        case .invalidURL:
            return "Invalid URL."
            
        // Authentication
        case .authenticationFailed:
            return "Login failed. Please check your credentials."
        case .tokenExpired:
            return "Your session has expired. Please log in again."
        case .unauthorizedAccess:
            return "You don't have permission to access this resource."
        case .accountDeleted:
            return "This account has been deleted."
            
        // Data
        case .decodingError(let message):
            return "Failed to load data: \(message)"
        case .encodingError(let message):
            return "Failed to prepare data: \(message)"
        case .dataCorrupted:
            return "Data is corrupted. Please try refreshing."
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
            
        // Validation
        case .invalidEmail:
            return "Please enter a valid email address."
        case .invalidPassword(let reason):
            return reason
        case .passwordMismatch:
            return "Passwords don't match."
        case .invalidInput(let field):
            return "Invalid \(field). Please check and try again."
        case .fieldTooLong(let field, let maxLength):
            return "\(field) is too long. Maximum length is \(maxLength) characters."
            
        // Image
        case .imageUploadFailed(let reason):
            return "Image upload failed: \(reason)"
        case .imageDownloadFailed:
            return "Failed to load image. Please try again."
        case .imageTooLarge:
            return "Image is too large. Please choose a smaller image."
        case .invalidImageFormat:
            return "Invalid image format. Please use JPEG or PNG."
            
        // Event
        case .eventCreationFailed(let reason):
            return "Failed to create event: \(reason)"
        case .eventNotFound:
            return "Event not found."
        case .eventUpdateFailed(let reason):
            return "Failed to update event: \(reason)"
        case .eventInPast:
            return "Event time must be in the future."
            
        // User
        case .userNotFound:
            return "User not found."
        case .usernameAlreadyExists:
            return "Username already exists. Please choose another."
        case .profileUpdateFailed(let reason):
            return "Failed to update profile: \(reason)"
            
        // Cache
        case .cacheReadError:
            return "Failed to read cached data."
        case .cacheWriteError:
            return "Failed to save data to cache."
            
        // WebSocket
        case .websocketConnectionFailed:
            return "Failed to establish real-time connection."
        case .websocketDisconnected:
            return "Real-time connection lost. Reconnecting..."
            
        // Location
        case .locationPermissionDenied:
            return "Location permission denied. Please enable it in Settings."
        case .locationUnavailable:
            return "Location unavailable. Please try again."
            
        // Unknown
        case .unknown(let message):
            return "An error occurred: \(message)"
        }
    }
    
    // MARK: - User-Friendly Title
    var errorTitle: String {
        switch self {
        case .networkError, .noInternetConnection, .requestTimeout, .serverError, .invalidResponse, .invalidURL:
            return "Connection Error"
        case .authenticationFailed, .tokenExpired, .unauthorizedAccess, .accountDeleted:
            return "Authentication Error"
        case .decodingError, .encodingError, .dataCorrupted, .missingRequiredField:
            return "Data Error"
        case .invalidEmail, .invalidPassword, .passwordMismatch, .invalidInput, .fieldTooLong:
            return "Validation Error"
        case .imageUploadFailed, .imageDownloadFailed, .imageTooLarge, .invalidImageFormat:
            return "Image Error"
        case .eventCreationFailed, .eventNotFound, .eventUpdateFailed, .eventInPast:
            return "Event Error"
        case .userNotFound, .usernameAlreadyExists, .profileUpdateFailed:
            return "User Error"
        case .cacheReadError, .cacheWriteError:
            return "Cache Error"
        case .websocketConnectionFailed, .websocketDisconnected:
            return "Connection Error"
        case .locationPermissionDenied, .locationUnavailable:
            return "Location Error"
        case .unknown:
            return "Error"
        }
    }
    
    // MARK: - Recovery Suggestion
    var recoverySuggestion: String? {
        switch self {
        case .noInternetConnection:
            return "Check your WiFi or cellular connection and try again."
        case .requestTimeout:
            return "Check your internet connection and try again."
        case .serverError:
            return "The server is experiencing issues. Please try again later."
        case .authenticationFailed:
            return "Double-check your username and password."
        case .tokenExpired:
            return "Please log in again to continue."
        case .locationPermissionDenied:
            return "Go to Settings > Privacy > Location Services to enable location access."
        case .imageTooLarge:
            return "Try choosing a smaller image or compress the current one."
        case .eventInPast:
            return "Select a time in the future."
        case .invalidEmail:
            return "Use format: example@domain.com"
        default:
            return nil
        }
    }
}

// MARK: - Result Extension
extension Result where Failure == AppError {
    /// Get the error if this result is a failure
    var error: AppError? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
    
    /// Get the value if this result is a success
    var value: Success? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }
}



