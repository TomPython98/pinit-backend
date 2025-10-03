import Foundation
import Combine

/// Simple model for each group chat message
struct GroupChatMessage: Identifiable {
    let id = UUID()
    let sender: String
    let text: String
}

class GroupChatWebSocketManager: ObservableObject {
    @Published var messages: [GroupChatMessage] = []
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)
    
    let eventID: UUID      // This is our "group" identifier
    let currentUsername: String
    
    init(eventID: UUID, currentUsername: String) {
        self.eventID = eventID
        self.currentUsername = currentUsername
    }
    
    func connect() {
        // Use production WebSocket URL
        let wsURL = APIConfig.serverBaseURL.replacingOccurrences(of: "https://", with: "wss://").replacingOccurrences(of: "http://", with: "ws://")
        guard let url = URL(string: "\(wsURL)/ws/group_chat/\(eventID.uuidString)/") else {
            return
        }
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        listenForMessages()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
    
    func sendMessage(_ message: String) {
        let payload: [String: Any] = [
            "sender": currentUsername,
            "message": message
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            let wsMessage = URLSessionWebSocketTask.Message.data(data)
            webSocketTask?.send(wsMessage) { error in
                if let error = error {
                }
            }
        }
    }
    
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                break
            case .success(let message):
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
                self.listenForMessages() // Continue listening
            }
        }
    }
    
    private func handleIncoming(_ data: Data) {
        if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let sender = dict["sender"] as? String,
           let msgText = dict["message"] as? String {
            DispatchQueue.main.async {
                let newMsg = GroupChatMessage(sender: sender, text: msgText)
                self.messages.append(newMsg)
            }
        }
    }
}
