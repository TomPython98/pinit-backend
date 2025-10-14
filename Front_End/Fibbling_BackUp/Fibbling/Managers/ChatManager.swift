import Foundation
import SwiftUI
import Combine

// ✅ Struct to store each chat message
struct ChatMessage: Codable, Identifiable {
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

// ✅ Struct to store chat conversations between users
struct ChatSession: Codable {
    let participants: [String]  // Stores two usernames
    var messages: [ChatMessage]
}

class ChatManager: ObservableObject {
    @Published var chatSessions: [ChatSession] = [] // ✅ Stores conversations

    private let storageKey = "chatMessages"
    private var webSocketManager: PrivateChatWebSocketManager?
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadMessages()  // ✅ Load messages when app starts
    }

    func sendMessage(to receiver: String, sender: String, message: String) {
        print("📤 ChatManager sendMessage called:")
        print("   To: \(receiver)")
        print("   From: \(sender)")
        print("   Message: \(message)")
        
        // ✅ Store locally FIRST for immediate UI update
        let chatKey = [sender, receiver].sorted()
        let timestamp = getCurrentDateString()
        
        DispatchQueue.main.async {
            // ✅ Create a mutable copy to trigger SwiftUI updates
            var sessions = self.chatSessions
            
            if let index = sessions.firstIndex(where: { $0.participants == chatKey }) {
                if sessions[index].messages.isEmpty {
                    sessions[index].messages.append(ChatMessage(sender: "📅", message: timestamp))
                }
                sessions[index].messages.append(ChatMessage(sender: sender, message: message))
            } else {
                let newChat = ChatSession(participants: chatKey, messages: [
                    ChatMessage(sender: "📅", message: timestamp),
                    ChatMessage(sender: sender, message: message)
                ])
                sessions.append(newChat)
            }
            
            // ✅ Replace the entire array to trigger SwiftUI update
            self.chatSessions = sessions
            self.saveMessages()
            print("✅ Message stored locally and UI updated")
            
            // ✅ Send through WebSocket AFTER local storage
            self.webSocketManager?.sendMessage(message)
            print("📡 Message sent via WebSocket")
        }
    }

    func getMessages(sender: String, receiver: String) -> [ChatMessage] {
        let chatKey = [sender, receiver].sorted()
        return chatSessions.first(where: { $0.participants == chatKey })?.messages ?? []
    }

    func connect(sender: String, receiver: String) {
        // ✅ Validate parameters before connecting
        guard !sender.isEmpty, !receiver.isEmpty else {
            print("❌ ChatManager: Cannot connect with empty sender or receiver")
            print("   Sender: '\(sender)', Receiver: '\(receiver)'")
            return
        }
        
        let chatKey = [sender, receiver].sorted()
        if !chatSessions.contains(where: { $0.participants == chatKey }) {
            chatSessions.append(ChatSession(participants: chatKey, messages: []))
        }
        
        // ✅ Initialize WebSocket connection
        webSocketManager = PrivateChatWebSocketManager(sender: sender, receiver: receiver)
        
        // ✅ Set up message handling
        webSocketManager?.$messages
            .sink { [weak self] messages in
                self?.handleIncomingWebSocketMessages(messages, sender: sender, receiver: receiver)
            }
            .store(in: &cancellables)
        
        // ✅ Connect to WebSocket
        webSocketManager?.connect()
    }

    func disconnect() {
        // ✅ Disconnect WebSocket
        webSocketManager?.disconnect()
        webSocketManager = nil
        
        // ✅ Cancel all subscriptions
        cancellables.removeAll()
    }
    
    // ✅ Handle incoming WebSocket messages
    private func handleIncomingWebSocketMessages(_ messages: [PrivateChatMessage], sender: String, receiver: String) {
        // Process ALL new messages, not just the last one
        guard !messages.isEmpty else { return }
        
        let chatKey = [sender, receiver].sorted()
        
        DispatchQueue.main.async {
            // ✅ Create a mutable copy to trigger SwiftUI updates
            var sessions = self.chatSessions
            
            if let index = sessions.firstIndex(where: { $0.participants == chatKey }) {
                var newMessagesAdded = 0
                
                // Process all messages from WebSocket
                for wsMessage in messages {
                    // ✅ More precise duplicate detection - check both sender AND message content
                    let messageExists = sessions[index].messages.contains { 
                        $0.sender == wsMessage.sender && 
                        $0.message == wsMessage.message &&
                        abs($0.timestamp.timeIntervalSince(wsMessage.timestamp)) < 2.0 // Within 2 seconds
                    }
                    
                    if !messageExists {
                        sessions[index].messages.append(ChatMessage(
                            sender: wsMessage.sender, 
                            message: wsMessage.message,
                            timestamp: wsMessage.timestamp
                        ))
                        newMessagesAdded += 1
                        print("✅ Added WebSocket message: '\(wsMessage.message)' from \(wsMessage.sender)")
                    }
                }
                
                if newMessagesAdded > 0 {
                    // ✅ Replace the entire array to trigger SwiftUI update
                    self.chatSessions = sessions
                    self.saveMessages()
                    print("📩 Processed \(newMessagesAdded) new WebSocket messages - UI should update")
                }
            }
        }
    }

    // ✅ Save messages to UserDefaults
    private func saveMessages() {
        do {
            let encodedData = try JSONEncoder().encode(chatSessions)
            UserDefaults.standard.set(encodedData, forKey: storageKey)
        } catch {
        }
    }

    // ✅ Load messages from UserDefaults
    private func loadMessages() {
        if let savedData = UserDefaults.standard.data(forKey: storageKey) {
            do {
                let decodedMessages = try JSONDecoder().decode([ChatSession].self, from: savedData)
                DispatchQueue.main.async {
                    self.chatSessions = decodedMessages
                }
            } catch {
            }
        }
    }

    // ✅ Get current date as a formatted string
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: Date())
    }
}
