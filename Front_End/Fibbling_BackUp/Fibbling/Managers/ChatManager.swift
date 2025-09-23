import Foundation
import SwiftUI

// ✅ Struct to store each chat message
struct ChatMessage: Codable {
    let sender: String
    let message: String
}

// ✅ Struct to store chat conversations between users
struct ChatSession: Codable {
    let participants: [String]  // Stores two usernames
    var messages: [ChatMessage]
}

class ChatManager: ObservableObject {
    @Published var chatSessions: [ChatSession] = [] // ✅ Stores conversations

    private let storageKey = "chatMessages"

    init() {
        loadMessages()  // ✅ Load messages when app starts
    }

    func sendMessage(to receiver: String, sender: String, message: String) {
        let chatKey = [sender, receiver].sorted()  // ✅ Unique key for chat
        let timestamp = getCurrentDateString() // ✅ Get the date
        
        DispatchQueue.main.async {
            if let index = self.chatSessions.firstIndex(where: { $0.participants == chatKey }) {
                if self.chatSessions[index].messages.isEmpty { // ✅ First message includes date
                    self.chatSessions[index].messages.append(ChatMessage(sender: "📅", message: timestamp))
                }
                self.chatSessions[index].messages.append(ChatMessage(sender: sender, message: message))
            } else {
                // ✅ Create new chat session with date
                let newChat = ChatSession(participants: chatKey, messages: [
                    ChatMessage(sender: "📅", message: timestamp),
                    ChatMessage(sender: sender, message: message)
                ])
                self.chatSessions.append(newChat)
            }

            self.saveMessages()  // ✅ Save messages
            self.objectWillChange.send()
        }
    }

    func getMessages(sender: String, receiver: String) -> [ChatMessage] {
        let chatKey = [sender, receiver].sorted()
        return chatSessions.first(where: { $0.participants == chatKey })?.messages ?? []
    }

    func connect(sender: String, receiver: String) {
        let chatKey = [sender, receiver].sorted()
        if !chatSessions.contains(where: { $0.participants == chatKey }) {
            chatSessions.append(ChatSession(participants: chatKey, messages: []))
        }
    }

    func disconnect() {
        // Handle any cleanup if needed
    }

    // ✅ Save messages to UserDefaults
    private func saveMessages() {
        do {
            let encodedData = try JSONEncoder().encode(chatSessions)
            UserDefaults.standard.set(encodedData, forKey: storageKey)
        } catch {
            print("❌ Error saving messages: \(error)")
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
                print("❌ Error loading messages: \(error)")
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
