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
    @Published var unreadCounts: [String: Int] = [:] // ✅ Track unread messages per user

    private let storageKey = "chatMessages"
    private let unreadStorageKey = "unreadMessageCounts"
    private var webSocketManager: PrivateChatWebSocketManager?
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadMessages()  // ✅ Load messages when app starts
        loadUnreadCounts() // ✅ Load unread counts
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
        
        // ✅ Fetch chat history from server
        fetchChatHistory(sender: sender, receiver: receiver)
        
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
    
    // ✅ Fetch chat history from server
    private func fetchChatHistory(sender: String, receiver: String) {
        let baseURL = APIConfig.baseURLs[0]
        let endpoint = "/get_chat_history/\(sender)/\(receiver)/"
        
        guard let url = URL(string: baseURL + endpoint) else {
            print("❌ Invalid chat history URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // ✅ Add JWT authentication
        if let token = UserDefaults.standard.string(forKey: "access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Failed to fetch chat history: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("❌ No data received from chat history")
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let success = json?["success"] as? Bool, success,
                   let messages = json?["messages"] as? [[String: Any]] {
                    
                    print("📥 Fetched \(messages.count) messages from server")
                    
                    let chatKey = [sender, receiver].sorted()
                    
                    DispatchQueue.main.async {
                        var sessions = self.chatSessions
                        
                        if let index = sessions.firstIndex(where: { $0.participants == chatKey }) {
                            // Clear existing messages and load from server
                            sessions[index].messages.removeAll()
                            
                            for msgData in messages {
                                guard let msgSender = msgData["sender"] as? String,
                                      let msgText = msgData["message"] as? String,
                                      let timestampStr = msgData["timestamp"] as? String else {
                                    continue
                                }
                                
                                // Parse ISO 8601 timestamp
                                let formatter = ISO8601DateFormatter()
                                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                                let timestamp = formatter.date(from: timestampStr) ?? Date()
                                
                                sessions[index].messages.append(ChatMessage(
                                    sender: msgSender,
                                    message: msgText,
                                    timestamp: timestamp
                                ))
                            }
                            
                            self.chatSessions = sessions
                            self.saveMessages()
                            print("✅ Loaded \(sessions[index].messages.count) messages from server")
                        }
                    }
                }
            } catch {
                print("❌ Failed to parse chat history: \(error.localizedDescription)")
            }
        }.resume()
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
                        
                        // ✅ Increment unread count if message is from the other person
                        if wsMessage.sender != sender {
                            self.incrementUnreadCount(for: wsMessage.sender, currentUser: sender)
                        }
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
    
    // MARK: - Unread Message Management
    
    /// Get unread count for a specific friend
    func getUnreadCount(for friend: String) -> Int {
        return unreadCounts[friend] ?? 0
    }
    
    /// Mark messages as read when opening a chat
    func markAsRead(for friend: String) {
        unreadCounts[friend] = 0
        saveUnreadCounts()
    }
    
    /// Increment unread count for incoming messages
    func incrementUnreadCount(for friend: String, currentUser: String) {
        // Only increment if we're not currently in the chat with this friend
        // This prevents counting messages while the chat is open
        unreadCounts[friend, default: 0] += 1
        saveUnreadCounts()
    }
    
    /// Save unread counts to UserDefaults
    private func saveUnreadCounts() {
        UserDefaults.standard.set(unreadCounts, forKey: unreadStorageKey)
    }
    
    /// Load unread counts from UserDefaults
    private func loadUnreadCounts() {
        if let saved = UserDefaults.standard.dictionary(forKey: unreadStorageKey) as? [String: Int] {
            DispatchQueue.main.async {
                self.unreadCounts = saved
            }
        }
    }
}
