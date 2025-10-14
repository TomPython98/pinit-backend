import Foundation
import Combine

/// Model for private chat messages
struct PrivateChatMessage: Identifiable, Codable {
    let id = UUID()
    let sender: String
    let message: String
    let timestamp: Date
    
    init(sender: String, message: String, timestamp: Date = Date()) {
        self.sender = sender
        self.message = message
        self.timestamp = timestamp
    }
}

/// WebSocket manager for private chat messaging
class PrivateChatWebSocketManager: ObservableObject {
    @Published var messages: [PrivateChatMessage] = []
    @Published var isConnected = false
    @Published var connectionError: String?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)
    
    let sender: String
    let receiver: String
    private var reconnectAttempt = 0
    private var reconnectTimer: Timer?
    private let maxReconnectAttempts = 5
    
    init(sender: String, receiver: String) {
        self.sender = sender
        self.receiver = receiver
    }
    
    deinit {
        disconnect()
    }
    
    /// Connect to the private chat WebSocket
    func connect() {
        // Use API configuration for WebSocket URL
        let wsBaseURL = APIConfig.websocketURL
        
        // ✅ Create consistent room name regardless of sender/receiver order
        // Sort usernames to ensure both users join the same room (same as backend)
        let participants = [sender, receiver].sorted()
        let roomName = "\(participants[0])/\(participants[1])"
        
        guard let url = URL(string: "\(wsBaseURL)chat/\(roomName)/") else {
            DispatchQueue.main.async {
                self.connectionError = "Invalid WebSocket URL"
            }
            return
        }
        
        // Close any existing connection
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        
        // Create and start a new connection
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        print("🔗 Connecting to private chat WebSocket: \(url.absoluteString)")
        
        // Start listening for messages
        listenForMessages()
        
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectionError = nil
            self.reconnectAttempt = 0
        }
    }
    
    /// Disconnect from the WebSocket
    func disconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
        }
        
        print("❌ Disconnected from private chat WebSocket")
    }
    
    /// Send a message through WebSocket
    func sendMessage(_ message: String) {
        guard isConnected, let webSocketTask = webSocketTask else {
            print("❌ Cannot send message: WebSocket not connected")
            return
        }
        
        let payload: [String: Any] = [
            "sender": sender,
            "receiver": receiver,
            "message": message
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: payload)
            let wsMessage = URLSessionWebSocketTask.Message.data(data)
            
            webSocketTask.send(wsMessage) { [weak self] error in
                if let error = error {
                    print("❌ Failed to send message: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self?.connectionError = "Failed to send message"
                    }
                } else {
                    print("✅ Message sent successfully")
                }
            }
        } catch {
            print("❌ Failed to serialize message: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.connectionError = "Failed to serialize message"
            }
        }
    }
    
    /// Listen for incoming WebSocket messages
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                print("❌ WebSocket receive failed: \(error.localizedDescription)")
                self.handleConnectionError()
                
            case .success(let message):
                // Process the message
                switch message {
                case .data(let data):
                    self.handleIncomingData(data)
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        self.handleIncomingData(data)
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
    private func handleIncomingData(_ data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let sender = json["sender"] as? String,
               let message = json["message"] as? String {
                
                let chatMessage = PrivateChatMessage(sender: sender, message: message)
                
                DispatchQueue.main.async {
                    self.messages.append(chatMessage)
                    print("📩 Received message from \(sender): \(message)")
                }
            }
        } catch {
            print("❌ Failed to parse incoming message: \(error.localizedDescription)")
        }
    }
    
    /// Handle WebSocket connection errors with reconnection logic
    private func handleConnectionError() {
        DispatchQueue.main.async {
            self.isConnected = false
        }
        
        guard reconnectAttempt < maxReconnectAttempts else {
            DispatchQueue.main.async {
                self.connectionError = "Max reconnection attempts reached"
            }
            return
        }
        
        reconnectAttempt += 1
        let delay = min(5.0 * Double(reconnectAttempt), 30.0) // Exponential backoff, max 30 seconds
        
        print("🔄 Reconnecting in \(delay) seconds (attempt \(reconnectAttempt)/\(maxReconnectAttempts))")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.reconnectTimer?.invalidate()
            
            self.reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.connect()
            }
        }
    }
}
