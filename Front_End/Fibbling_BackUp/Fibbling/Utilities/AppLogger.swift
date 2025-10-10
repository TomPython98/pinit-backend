import Foundation
import os.log

/// Professional logging framework for PinIt app
/// Uses OSLog for optimal performance and privacy
struct AppLogger {
    // MARK: - Log Categories
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pinit.app", category: "network")
    static let ui = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pinit.app", category: "ui")
    static let data = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pinit.app", category: "data")
    static let websocket = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pinit.app", category: "websocket")
    static let image = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pinit.app", category: "image")
    static let auth = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pinit.app", category: "auth")
    static let cache = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pinit.app", category: "cache")
    
    // MARK: - Logging Methods
    
    /// Log a message with specified level and category
    /// - Parameters:
    ///   - message: The message to log
    ///   - level: Log level (default, info, debug, error, fault)
    ///   - category: Logger category to use
    static func log(_ message: String, level: OSLogType = .default, category: Logger = AppLogger.network) {
        #if DEBUG
        // In debug mode, log everything
        category.log(level: level, "\(message)")
        #else
        // In production, only log errors and faults
        if level == .error || level == .fault {
            category.log(level: level, "\(message)")
        }
        #endif
    }
    
    /// Log debug information (only in DEBUG builds)
    static func debug(_ message: String, category: Logger = AppLogger.network) {
        #if DEBUG
        category.log(level: .debug, "🔍 \(message)")
        #endif
    }
    
    /// Log informational message
    static func info(_ message: String, category: Logger = AppLogger.network) {
        log(message, level: .info, category: category)
    }
    
    /// Log error with context
    static func error(_ message: String, error: Error? = nil, category: Logger = AppLogger.network) {
        if let error = error {
            category.log(level: .error, "❌ \(message): \(error.localizedDescription)")
        } else {
            category.log(level: .error, "❌ \(message)")
        }
    }
    
    /// Log critical fault
    static func fault(_ message: String, category: Logger = AppLogger.network) {
        category.log(level: .fault, "💥 \(message)")
    }
    
    /// Log network request
    static func logRequest(url: String, method: String = "GET") {
        debug("→ \(method) \(url)", category: AppLogger.network)
    }
    
    /// Log network response
    static func logResponse(url: String, statusCode: Int) {
        if statusCode >= 200 && statusCode < 300 {
            debug("← \(statusCode) \(url)", category: AppLogger.network)
        } else {
            error("← \(statusCode) \(url)", category: AppLogger.network)
        }
    }
    
    /// Log WebSocket event
    static func logWebSocket(_ event: String, details: String? = nil) {
        if let details = details {
            debug("🔌 \(event): \(details)", category: AppLogger.websocket)
        } else {
            debug("🔌 \(event)", category: AppLogger.websocket)
        }
    }
    
    /// Log image operation
    static func logImage(_ operation: String, details: String? = nil) {
        if let details = details {
            debug("🖼️ \(operation): \(details)", category: AppLogger.image)
        } else {
            debug("🖼️ \(operation)", category: AppLogger.image)
        }
    }
    
    /// Log cache operation
    static func logCache(_ operation: String, details: String? = nil) {
        if let details = details {
            debug("💾 \(operation): \(details)", category: AppLogger.cache)
        } else {
            debug("💾 \(operation)", category: AppLogger.cache)
        }
    }
    
    /// Log authentication event
    static func logAuth(_ event: String) {
        // Never log sensitive auth data in production
        #if DEBUG
        debug("🔐 \(event)", category: AppLogger.auth)
        #else
        info("Auth event", category: AppLogger.auth)
        #endif
    }
}

// MARK: - Error Logging Extension
extension Error {
    /// Log this error with context
    func log(context: String, category: Logger = AppLogger.network) {
        AppLogger.error(context, error: self, category: category)
    }
}
