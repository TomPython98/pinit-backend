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
    
    private var lastReadTimestamps: [String: Date] = [:] // ✅ Track when user last read each chat
    private var currentlyOpenChat: String? = nil // ✅ Track which chat is currently open

    private let storageKey = "chatMessages"
    private let unreadStorageKey = "unreadMessageCounts"
    private let lastReadStorageKey = "lastReadTimestamps"
    private var webSocketManager: PrivateChatWebSocketManager?
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadMessages()  // ✅ Load messages when app starts
        loadUnreadCounts() // ✅ Load unread counts
        loadLastReadTimestamps() // ✅ Load last read timestamps
        updateAllUnreadCounts() // ✅ Calculate unread counts based on messages
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
        
        // ✅ Track currently open chat
        currentlyOpenChat = receiver
        
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
    
    /// Refresh unread counts for all friends (call this when opening Friends list)
    func refreshUnreadCounts(currentUser: String) {
        print("🔄 Refreshing unread counts for all friends...")
        
        // Get all friends from chat sessions
        for session in chatSessions {
            for participant in session.participants where participant != currentUser {
                updateUnreadCount(for: participant, currentUser: currentUser)
            }
        }
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
        // ✅ Clear currently open chat
        currentlyOpenChat = nil
        
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
                    
                    // ✅ Update unread counts for the sender (if not currently in that chat)
                    if self.currentlyOpenChat != receiver {
                        self.updateUnreadCount(for: receiver, currentUser: sender)
                    }
                    
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
        // ✅ Update last read timestamp to now
        lastReadTimestamps[friend] = Date()
        saveLastReadTimestamps()
        
        // ✅ Immediately update unread count for this friend
        unreadCounts[friend] = 0
        saveUnreadCounts()
        
        print("✅ Marked \(friend) as read at \(Date())")
    }
    
    /// Update unread count for a specific friend based on messages received after last read
    func updateUnreadCount(for friend: String, currentUser: String) {
        let chatKey = [currentUser, friend].sorted()
        
        guard let session = chatSessions.first(where: { $0.participants == chatKey }) else {
            return
        }
        
        // Get last read timestamp (default to very old date if never read)
        let lastRead = lastReadTimestamps[friend] ?? Date(timeIntervalSince1970: 0)
        
        // Count messages from friend that are newer than lastRead
        let unreadCount = session.messages.filter { message in
            message.sender == friend && // Message is from the friend
            message.sender != "📅" && // Not a date separator
            message.timestamp > lastRead // Newer than last read
        }.count
        
        if unreadCount != unreadCounts[friend] {
            unreadCounts[friend] = unreadCount
            saveUnreadCounts()
            print("📊 Updated unread count for \(friend): \(unreadCount)")
        }
    }
    
    /// Update all unread counts (called on app launch)
    private func updateAllUnreadCounts() {
        // Get all unique friends from chat sessions
        var allFriends = Set<String>()
        for session in chatSessions {
            allFriends.formUnion(session.participants)
        }
        
        // Update count for each friend
        // Note: We don't know currentUser yet, so we'll update this when connect() is called
        for friend in allFriends {
            if let session = chatSessions.first(where: { $0.participants.contains(friend) }) {
                let otherParticipant = session.participants.first { $0 != friend }
                if let currentUser = otherParticipant {
                    updateUnreadCount(for: friend, currentUser: currentUser)
                }
            }
        }
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
    
    /// Save last read timestamps to UserDefaults
    private func saveLastReadTimestamps() {
        // Convert Date dictionary to TimeInterval dictionary for storage
        let timeIntervals = lastReadTimestamps.mapValues { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(timeIntervals, forKey: lastReadStorageKey)
    }
    
    /// Load last read timestamps from UserDefaults
    private func loadLastReadTimestamps() {
        if let saved = UserDefaults.standard.dictionary(forKey: lastReadStorageKey) as? [String: Double] {
            lastReadTimestamps = saved.mapValues { Date(timeIntervalSince1970: $0) }
        }
    }
}
