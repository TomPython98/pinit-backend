import Foundation
import UIKit

/// Manages image loading with retry logic and timeout handling
class ImageRetryManager {
    static let shared = ImageRetryManager()
    
    private let maxRetries = 3
    private let timeout: TimeInterval = 15.0
    private let baseDelay: TimeInterval = 2.0
    
    private init() {}
    
    /// Load image with retry logic
    func loadImageWithRetry(
        from url: String,
        retryCount: Int = 0,
        completion: @escaping (UIImage?) -> Void
    ) {
        guard let imageURL = URL(string: url) else {
            AppLogger.error("Invalid image URL: \(url)", category: AppLogger.image)
            completion(nil)
            return
        }
        
        var request = URLRequest(url: imageURL)
        request.timeoutInterval = timeout
        request.cachePolicy = .returnCacheDataElseLoad
        
        AppLogger.debug("Loading image (attempt \(retryCount + 1)/\(maxRetries)): \(url)", category: AppLogger.image)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                AppLogger.error("Image load failed (attempt \(retryCount + 1))", error: error, category: AppLogger.image)
                
                if retryCount < self?.maxRetries ?? 0 && self?.shouldRetry(error) == true {
                    let delay = self?.calculateDelay(for: retryCount) ?? 2.0
                    AppLogger.debug("Retrying image load in \(delay)s", category: AppLogger.image)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self?.loadImageWithRetry(from: url, retryCount: retryCount + 1, completion: completion)
                    }
                } else {
                    AppLogger.error("Max retries reached for image: \(url)", category: AppLogger.image)
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                AppLogger.error("Invalid image data received for: \(url)", category: AppLogger.image)
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            AppLogger.debug("Successfully loaded image: \(url)", category: AppLogger.image)
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    /// Check if error is retryable
    private func shouldRetry(_ error: Error) -> Bool {
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
    
    /// Calculate retry delay with exponential backoff
    private func calculateDelay(for attempt: Int) -> TimeInterval {
        return baseDelay * pow(2.0, Double(attempt))
    }
}


