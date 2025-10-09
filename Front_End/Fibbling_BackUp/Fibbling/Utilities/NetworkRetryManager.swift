import Foundation
import Network

/// Manages network retry logic with exponential backoff
class NetworkRetryManager {
    static let shared = NetworkRetryManager()
    
    private let maxRetries = 3
    private let baseDelay: TimeInterval = 2.0
    private let maxDelay: TimeInterval = 30.0
    
    private init() {}
    
    /// Retry a network operation with exponential backoff
    func retry<T>(
        operation: @escaping () async throws -> T,
        onFailure: @escaping (Error, Int) -> Void = { _, _ in },
        onSuccess: @escaping (T) -> Void = { _ in }
    ) async {
        var attempt = 1
        
        while attempt <= maxRetries {
            do {
                let result = try await operation()
                onSuccess(result)
                return
            } catch {
                onFailure(error, attempt)
                
                if attempt == maxRetries {
                    AppLogger.error("Max retries reached for network operation", error: error, category: AppLogger.network)
                    return
                }
                
                let delay = calculateDelay(for: attempt)
                AppLogger.debug("Retrying in \(delay)s (attempt \(attempt + 1)/\(maxRetries))", category: AppLogger.network)
                
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                attempt += 1
            }
        }
    }
    
    /// Calculate exponential backoff delay
    private func calculateDelay(for attempt: Int) -> TimeInterval {
        let delay = baseDelay * pow(2.0, Double(attempt - 1))
        return min(delay, maxDelay)
    }
    
    /// Check if error is retryable
    func isRetryableError(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotConnectToHost:
                return true
            default:
                return false
            }
        }
        
        if let posixError = error as? POSIXError {
            switch posixError.code {
            case .ECONNRESET, .ECONNABORTED, .ENETUNREACH:
                return true
            default:
                return false
            }
        }
        
        return false
    }
}


