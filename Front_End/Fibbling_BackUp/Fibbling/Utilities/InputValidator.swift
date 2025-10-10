import Foundation

/// Input validation utilities for the PinIt app
struct InputValidator {
    
    // MARK: - Email Validation
    
    /// Validate email format
    /// - Parameter email: Email address to validate
    /// - Returns: True if email is valid
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }
    
    // MARK: - Password Validation
    
    /// Validate password strength
    /// - Parameter password: Password to validate
    /// - Returns: Tuple with validation result and error message
    static func isValidPassword(_ password: String) -> (isValid: Bool, error: AppError?) {
        guard password.count >= 8 else {
            return (false, .invalidPassword("Password must be at least 8 characters"))
        }
        
        guard password.rangeOfCharacter(from: .uppercaseLetters) != nil else {
            return (false, .invalidPassword("Password must contain an uppercase letter"))
        }
        
        guard password.rangeOfCharacter(from: .lowercaseLetters) != nil else {
            return (false, .invalidPassword("Password must contain a lowercase letter"))
        }
        
        guard password.rangeOfCharacter(from: .decimalDigits) != nil else {
            return (false, .invalidPassword("Password must contain a number"))
        }
        
        return (true, nil)
    }
    
    // MARK: - Username Validation
    
    /// Validate username
    /// - Parameter username: Username to validate
    /// - Returns: Tuple with validation result and error message
    static func isValidUsername(_ username: String) -> (isValid: Bool, error: AppError?) {
        // Check length
        guard username.count >= 3 else {
            return (false, .invalidInput("Username must be at least 3 characters"))
        }
        
        guard username.count <= 30 else {
            return (false, .fieldTooLong("Username", 30))
        }
        
        // Check for valid characters (alphanumeric, underscore, hyphen)
        let usernameRegex = "^[a-zA-Z0-9_-]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        
        guard predicate.evaluate(with: username) else {
            return (false, .invalidInput("Username can only contain letters, numbers, underscore, and hyphen"))
        }
        
        return (true, nil)
    }
    
    // MARK: - Text Field Validation
    
    /// Validate text field with length constraints
    /// - Parameters:
    ///   - text: Text to validate
    ///   - fieldName: Name of the field for error messages
    ///   - minLength: Minimum length (default: 0)
    ///   - maxLength: Maximum length
    /// - Returns: Tuple with validation result and error message
    static func validateTextField(_ text: String, 
                                   fieldName: String,
                                   minLength: Int = 0,
                                   maxLength: Int) -> (isValid: Bool, error: AppError?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmed.count >= minLength else {
            return (false, .invalidInput("\(fieldName) must be at least \(minLength) characters"))
        }
        
        guard trimmed.count <= maxLength else {
            return (false, .fieldTooLong(fieldName, maxLength))
        }
        
        return (true, nil)
    }
    
    // MARK: - Text Sanitization
    
    /// Sanitize text input to prevent XSS and other attacks
    /// - Parameters:
    ///   - text: Text to sanitize
    ///   - maxLength: Maximum allowed length (default: 500)
    /// - Returns: Sanitized text
    static func sanitizeText(_ text: String, maxLength: Int = 500) -> String {
        // Define allowed character set
        var allowed = CharacterSet.alphanumerics
        allowed.formUnion(.whitespaces)
        allowed.formUnion(.punctuationCharacters)
        allowed.formUnion(CharacterSet(charactersIn: "\n\r"))
        
        // Filter characters
        let filtered = text.unicodeScalars.filter { allowed.contains($0) }
        let sanitized = String(String.UnicodeScalarView(filtered))
        
        // Trim whitespace and limit length
        let trimmed = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(maxLength))
    }
    
    // MARK: - Event Validation
    
    /// Validate event title
    /// - Parameter title: Event title to validate
    /// - Returns: Tuple with validation result and error message
    static func validateEventTitle(_ title: String) -> (isValid: Bool, error: AppError?) {
        return validateTextField(title, fieldName: "Event title", minLength: 3, maxLength: 100)
    }
    
    /// Validate event description
    /// - Parameter description: Event description to validate
    /// - Returns: Tuple with validation result and error message
    static func validateEventDescription(_ description: String?) -> (isValid: Bool, error: AppError?) {
        guard let description = description, !description.isEmpty else {
            return (true, nil) // Description is optional
        }
        
        return validateTextField(description, fieldName: "Event description", maxLength: 1000)
    }
    
    /// Validate event dates
    /// - Parameters:
    ///   - startDate: Event start date
    ///   - endDate: Event end date
    /// - Returns: Tuple with validation result and error message
    static func validateEventDates(startDate: Date, endDate: Date) -> (isValid: Bool, error: AppError?) {
        // Check if start date is in the past
        guard startDate > Date() else {
            return (false, .eventInPast)
        }
        
        // Check if end date is after start date
        guard endDate > startDate else {
            return (false, .invalidInput("End time must be after start time"))
        }
        
        // Check if event is not too long (e.g., max 24 hours)
        let duration = endDate.timeIntervalSince(startDate)
        let maxDuration: TimeInterval = 24 * 60 * 60 // 24 hours
        
        guard duration <= maxDuration else {
            return (false, .invalidInput("Event cannot be longer than 24 hours"))
        }
        
        return (true, nil)
    }
    
    // MARK: - Bio Validation
    
    /// Validate user bio
    /// - Parameter bio: User bio to validate
    /// - Returns: Tuple with validation result and error message
    static func validateBio(_ bio: String?) -> (isValid: Bool, error: AppError?) {
        guard let bio = bio, !bio.isEmpty else {
            return (true, nil) // Bio is optional
        }
        
        return validateTextField(bio, fieldName: "Bio", maxLength: 500)
    }
    
    // MARK: - URL Validation
    
    /// Validate URL format
    /// - Parameter urlString: URL string to validate
    /// - Returns: True if URL is valid
    static func isValidURL(_ urlString: String) -> Bool {
        guard !urlString.isEmpty else { return false }
        
        // Try to create URL
        guard let url = URL(string: urlString) else { return false }
        
        // Check for valid scheme
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }
    
    // MARK: - Image Validation
    
    /// Validate image size
    /// - Parameters:
    ///   - data: Image data
    ///   - maxSizeInMB: Maximum size in megabytes (default: 10)
    /// - Returns: Tuple with validation result and error message
    static func validateImageSize(_ data: Data, maxSizeInMB: Int = 10) -> (isValid: Bool, error: AppError?) {
        let maxBytes = maxSizeInMB * 1024 * 1024
        
        guard data.count <= maxBytes else {
            return (false, .imageTooLarge)
        }
        
        return (true, nil)
    }
    
    // MARK: - Tag Validation
    
    /// Validate interest/event tag
    /// - Parameter tag: Tag to validate
    /// - Returns: Tuple with validation result and error message
    static func validateTag(_ tag: String) -> (isValid: Bool, error: AppError?) {
        return validateTextField(tag, fieldName: "Tag", minLength: 2, maxLength: 30)
    }
}

// MARK: - String Extension for Validation
extension String {
    /// Check if string is a valid email
    var isValidEmail: Bool {
        InputValidator.isValidEmail(self)
    }
    
    /// Check if string is a valid URL
    var isValidURL: Bool {
        InputValidator.isValidURL(self)
    }
    
    /// Sanitize the string
    func sanitized(maxLength: Int = 500) -> String {
        InputValidator.sanitizeText(self, maxLength: maxLength)
    }
}
