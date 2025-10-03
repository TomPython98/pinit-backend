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
        // Ensure your Django Channels routing uses a URL like:
        // ws://127.0.0.1:8000/ws/events/<username>/
        guard let url = URL(string: "ws://127.0.0.1:8000/ws/events/\(username)/") else {
            return
        }
        
        // Close any existing connection
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        
        // Create and start a new connection
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        
        // Start listening for messages
        listenForMessages()
        
        // Start periodic pings to keep the connection alive
        startPingTimer()
    }
    
    /// Start periodic ping timer to keep the connection alive
    private func startPingTimer() {
        // Clean up any existing timer
        pingTimer?.invalidate()
        
        // Create a new ping timer that fires every 30 seconds
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.sendPing()
        }
    }
    
    /// Disconnect from the WebSocket server
    func disconnect() {
        
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
        
        // Calculate backoff time
        reconnectAttempt += 1
        let backoffTime = min(reconnectInterval * pow(1.5, Double(reconnectAttempt - 1)), maxReconnectInterval)
        
        
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
            
            // Log the actual data for debugging
            if let textData = String(data: data, encoding: .utf8) {
                
                // Try to extract event_id manually from the JSON string if possible
                if let eventIdIndex = textData.range(of: "\"event_id\":")?.upperBound,
                   let endQuoteIndex = textData.range(of: "\"", range: eventIdIndex..<textData.endIndex)?.upperBound,
                   let closingQuoteIndex = textData.range(of: "\"", range: endQuoteIndex..<textData.endIndex)?.lowerBound {
                    
                    let eventIdString = String(textData[endQuoteIndex..<closingQuoteIndex])
                    
                    if let eventId = UUID(uuidString: eventIdString) {
                        let typeString = textData.contains("\"type\":\"update\"") ? "update" :
                                          textData.contains("\"type\":\"create\"") ? "create" :
                                          textData.contains("\"type\":\"delete\"") ? "delete" : "unknown"
                        
                        
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
                self?.handleConnectionError()
            } else {
            }
        }
    }
} 