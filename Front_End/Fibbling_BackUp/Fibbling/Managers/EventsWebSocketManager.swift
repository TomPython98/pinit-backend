import Foundation
import Combine

// Protocol to handle WebSocket events
protocol EventsWebSocketManagerDelegate: AnyObject {
    func didReceiveEventUpdate(eventID: UUID)
    func didReceiveEventCreation(eventID: UUID)
    func didReceiveEventDeletion(eventID: UUID)
}

/// This enum represents the types of event changes the WebSocket can receive
enum EventChangeType: String, Codable {
    case update = "update"   // Event was updated
    case create = "create"   // New event created
    case delete = "delete"   // Event was deleted
}

/// Message structure for events WebSocket
struct EventChangeMessage: Codable {
    let type: EventChangeType
    let eventID: UUID
    
    enum CodingKeys: String, CodingKey {
        case type
        case eventID = "event_id"
    }
}

/// WebSocket manager for real-time event updates
class EventsWebSocketManager: ObservableObject {
    weak var delegate: EventsWebSocketManagerDelegate?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)
    private let username: String
    
    // Track connection state
    @Published var isConnected = false
    private var reconnectAttempt = 0
    private var reconnectTimer: Timer?
    private var pingTimer: Timer?
    private var reconnectInterval: TimeInterval = 5.0 // Start with 5 seconds
    private let maxReconnectInterval: TimeInterval = 60.0 // Max 1 minute between retries
    
    init(username: String) {
        self.username = username
    }
    
    deinit {
        // Cancel the timers first to prevent any retain cycles
        stopTimers()
        
        // Then disconnect
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    private func stopTimers() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    /// Connect to the WebSocket server
    func connect() {
        // Use API configuration for WebSocket URL
        let wsBaseURL = APIConfig.websocketURL
        guard let url = URL(string: "\(wsBaseURL)events/\(username)/") else {
            AppLogger.error("Invalid WebSocket URL", category: AppLogger.websocket)
            return
        }
        
        // Close any existing connection
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        
        // Create and start a new connection
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        AppLogger.logWebSocket("Connecting to WebSocket", details: url.absoluteString)
        
        // Start listening for messages
        listenForMessages()
        
        // Start periodic pings to keep the connection alive
        startPingTimer()
    }
    
    /// Start periodic ping timer to keep the connection alive
    private func startPingTimer() {
        // Clean up any existing timer
        pingTimer?.invalidate()
        
        // Create a new ping timer that fires every 20 seconds (more frequent for stability)
        pingTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.sendPing()
        }
    }
    
    /// Disconnect from the WebSocket server
    func disconnect() {
        AppLogger.logWebSocket("Disconnecting from WebSocket")
        
        // Cancel timers
        stopTimers()
        
        // Close the connection
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    /// Handle WebSocket connection errors with exponential backoff
    private func handleConnectionError() {
        DispatchQueue.main.async {
            self.isConnected = false
        }
        
        // Calculate backoff time with jitter to prevent thundering herd
        reconnectAttempt += 1
        let baseBackoffTime = min(reconnectInterval * pow(1.5, Double(reconnectAttempt - 1)), maxReconnectInterval)
        let jitter = Double.random(in: 0.1...0.3) * baseBackoffTime
        let backoffTime = baseBackoffTime + jitter
        
        AppLogger.logWebSocket("Connection error, reconnecting in \(Int(backoffTime))s", details: "Attempt \(reconnectAttempt)")
        
        // Schedule reconnect - use weak self to prevent retain cycles
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.reconnectTimer?.invalidate()
            
            self.reconnectTimer = Timer.scheduledTimer(withTimeInterval: backoffTime, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.connect()
            }
        }
    }
    
    /// Reset reconnection parameters on successful connection
    private func handleSuccessfulConnection() {
        DispatchQueue.main.async {
            self.isConnected = true
            self.reconnectAttempt = 0
            self.reconnectTimer?.invalidate()
            self.reconnectTimer = nil
            
            // Reset ping timer
            self.startPingTimer()
        }
    }
    
    /// Listen for incoming WebSocket messages
    private func listenForMessages() {
        // Use weak self to prevent retain cycles
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                AppLogger.error("WebSocket receive failed", error: error, category: AppLogger.websocket)
                self.handleConnectionError()
                
            case .success(let message):
                // Connection is working if we receive a message
                self.handleSuccessfulConnection()
                
                // Process the message
                switch message {
                case .data(let data):
                    self.handleIncoming(data)
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        self.handleIncoming(data)
                    }
                @unknown default:
                    break
                }
                
                // Continue listening if still connected
                if self.webSocketTask != nil {
                    self.listenForMessages()
                }
            }
        }
    }
    
    /// Process incoming WebSocket data
    private func handleIncoming(_ data: Data) {
        let decoder = JSONDecoder()
        
        do {
            let message = try decoder.decode(EventChangeMessage.self, from: data)
            
            // Notify delegate on the main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let delegate = self.delegate else { return }
                switch message.type {
                case .update:
                    delegate.didReceiveEventUpdate(eventID: message.eventID)
                case .create:
                    delegate.didReceiveEventCreation(eventID: message.eventID)
                case .delete:
                    delegate.didReceiveEventDeletion(eventID: message.eventID)
                }
            }
        } catch {
            AppLogger.error("Failed to decode WebSocket message", error: error, category: AppLogger.websocket)
            
            // Log the actual data for debugging
            if let textData = String(data: data, encoding: .utf8) {
                AppLogger.debug("Raw message: \(textData)", category: AppLogger.websocket)
                
                // Try to extract event_id manually from the JSON string if possible
                if let eventIdIndex = textData.range(of: "\"event_id\":")?.upperBound,
                   let endQuoteIndex = textData.range(of: "\"", range: eventIdIndex..<textData.endIndex)?.upperBound,
                   let closingQuoteIndex = textData.range(of: "\"", range: endQuoteIndex..<textData.endIndex)?.lowerBound {
                    
                    let eventIdString = String(textData[endQuoteIndex..<closingQuoteIndex])
                    
                    if let eventId = UUID(uuidString: eventIdString) {
                        let typeString = textData.contains("\"type\":\"update\"") ? "update" :
                                          textData.contains("\"type\":\"create\"") ? "create" :
                                          textData.contains("\"type\":\"delete\"") ? "delete" : "unknown"
                        
                        AppLogger.logWebSocket("Parsed event change", details: "\(typeString) - \(eventId)")
                        
                        // Notify delegate of the event change
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self, let delegate = self.delegate else { return }
                            switch typeString {
                            case "update": delegate.didReceiveEventUpdate(eventID: eventId)
                            case "create": delegate.didReceiveEventCreation(eventID: eventId)
                            case "delete": delegate.didReceiveEventDeletion(eventID: eventId)
                            default: break
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Send a ping to keep the connection alive
    func sendPing() {
        guard webSocketTask != nil else { return }
        
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                AppLogger.error("WebSocket ping failed", error: error, category: AppLogger.websocket)
                // Only reconnect if it's a connection error, not just a ping failure
                if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                    self?.handleConnectionError()
                }
            } else {
                AppLogger.debug("WebSocket ping successful", category: AppLogger.websocket)
            }
        }
    }
} 