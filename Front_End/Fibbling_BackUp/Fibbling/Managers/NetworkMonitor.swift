import Foundation
import Network
import SwiftUI

// MARK: - Network Monitor
/// Monitors network connectivity and speed to optimize image loading
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var connectionSpeed: ConnectionSpeed = .good
    @Published var isConnected = true
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionSpeed {
        case excellent  // WiFi or 5G
        case good      // 4G
        case fair      // 3G
        case poor      // 2G or worse
        case offline
        
        var timeout: TimeInterval {
            switch self {
            case .excellent: return 10.0
            case .good: return 15.0
            case .fair: return 25.0
            case .poor: return 40.0
            case .offline: return 5.0
            }
        }
        
        var maxConcurrentDownloads: Int {
            switch self {
            case .excellent: return 8
            case .good: return 4
            case .fair: return 2
            case .poor: return 1
            case .offline: return 0
            }
        }
        
        var shouldLoadThumbnailsOnly: Bool {
            return self == .fair || self == .poor
        }
        
        var compressionQuality: CGFloat {
            switch self {
            case .excellent: return 0.9
            case .good: return 0.8
            case .fair: return 0.6
            case .poor: return 0.4
            case .offline: return 0.8
            }
        }
    }
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self = self else { return }
                
                self.isConnected = path.status == .satisfied
                
                // Determine connection speed based on interface type
                if !self.isConnected {
                    self.connectionSpeed = .offline
                } else if path.usesInterfaceType(.wifi) {
                    self.connectionSpeed = .excellent
                } else if path.usesInterfaceType(.cellular) {
                    // Estimate cellular speed (this is a rough heuristic)
                    // In a production app, you'd measure actual download speeds
                    self.connectionSpeed = .good
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionSpeed = .excellent
                } else {
                    self.connectionSpeed = .fair
                }
                
                print("📡 Network: \(self.connectionSpeed) - Connected: \(self.isConnected)")
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
    
    /// Measure actual download speed by downloading a small test file
    func measureActualSpeed() async -> ConnectionSpeed {
        // In a production app, you could implement actual speed testing
        // For now, we rely on interface type detection
        return connectionSpeed
    }
}

