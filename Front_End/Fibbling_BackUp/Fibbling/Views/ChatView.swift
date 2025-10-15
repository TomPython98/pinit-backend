import SwiftUI

// NOTE: Ensure your ChatManager and ChatMessage types are correctly imported from your module (e.g., `import Fibbling`).
// Also ensure ChatMessage has a unique `id` property (e.g., UUID) and conforms to Identifiable.

struct ChatView: View {
    @EnvironmentObject var chatManager: ChatManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var message = ""
    @State private var isSending = false
    @State private var scrollToBottom = false
    @FocusState private var isInputFocused: Bool

    // Pending messages optimistically shown until confirmed by manager
    @State private var pendingMessages: [ChatMessage] = []

    // Computed view of messages: manager + pending (deduped)
    private var displayMessages: [ChatMessage] {
        let managerMessages = chatManager.getMessages(sender: sender, receiver: receiver)
        var merged = managerMessages
        for p in pendingMessages {
            let exists = merged.contains { m in
                m.sender == p.sender && m.message == p.message && abs(m.timestamp.timeIntervalSince(p.timestamp)) < 5.0
            }
            if !exists {
                merged.append(p)
            }
        }
        return merged.sorted { a, b in a.timestamp < b.timestamp }
    }
    
    let sender: String
    let receiver: String

    var body: some View {
        ZStack {
            // Professional background like ContentView
            Color.bgSurface
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom navigation header
                chatHeader
                
                // Messages list
                messagesListView
                
                // Input area
                messageInputBar
            }
        }
        .toolbar(.hidden)
        .onAppear {
            print("🔍 ChatView onAppear - Sender: '\(sender)', Receiver: '\(receiver)'")
            chatManager.connect(sender: sender, receiver: receiver)
            // Mark messages as read when opening chat
            chatManager.markAsRead(for: receiver)
            // Fetch messages when view appears
            updateMessagesList()
        }
        .onDisappear {
            chatManager.disconnect()
        }
        .onReceive(chatManager.$chatSessions) { _ in
            // ✅ Update messages when chat sessions change
            print("🔍 ChatView: chatSessions changed, updating messages")
            updateMessagesList()
        }
        .onChange(of: pendingMessages.count) { oldCount, newCount in
            // Scroll to bottom when new messages arrive
            if !pendingMessages.isEmpty && newCount > oldCount {
                // Set flag to scroll - will be processed in ScrollViewReader
                scrollToBottom = true
            }
        }
    }
    
    // MARK: - UI Components
    
    var chatHeader: some View {
        HStack(spacing: 16) {
            // Back button
            Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.textPrimary)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.bgCard)
                                    .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
                            )
            }
            
            // Friend avatar
            Circle()
                .fill(friendColor(for: receiver))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(receiver.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                )
            
            // Receiver name and status
            VStack(alignment: .leading, spacing: 2) {
                Text(receiver)
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                
                Text(receiver == "general" ? "Group Chat" : "Online")
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
            
            // Info icon
            Button(action: {}) {
                Image(systemName: "info.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.gray) // Use gray instead of black
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
        )
    }
    
    var messagesListView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                if displayMessages.isEmpty {
                    // Empty state for no messages
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(Color.textMuted)
                        
                        VStack(spacing: 8) {
                            Text("No Messages Yet")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.textPrimary)
                            
                            Text("Start the conversation by sending a message below")
                                .font(.subheadline)
                                .foregroundColor(Color.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 400)
                    .padding(.vertical, 60)
                } else {
                    LazyVStack(spacing: 8) {
                        // Use the state property instead of fetching in the view directly
                        ForEach(displayMessages, id: \.id) { msg in
                            
                            if msg.sender == "📅" {
                                // Date message
                                Text(msg.message)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(16)
                                    .padding(.vertical, 4)
                            } else {
                                // Regular message bubble
                                MessageBubble(message: msg, isFromCurrentUser: msg.sender == sender)
                            }
                        }
                        
                        // Bottom spacer for scrolling
                        Color.clear
                            .frame(height: 1)
                            .id("bottomID")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .onChange(of: scrollToBottom) { _, shouldScroll in
                if shouldScroll {
                    withAnimation {
                        scrollProxy.scrollTo("bottomID", anchor: .bottom)
                    }
                    // Reset the flag
                    DispatchQueue.main.async {
                        scrollToBottom = false
                    }
                }
            }
            .onChange(of: displayMessages.count) { _ in
                // Scroll to bottom when messages update
                scrollToBottom = true
            }
            .onAppear {
                // Initial scroll to bottom
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToBottom = true
                }
            }
        }
        .background(Color.gray.opacity(0.05)) // Light gray background
    }
    
    var messageInputBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Message input field
                ZStack(alignment: .leading) {
                    if message.isEmpty {
                        Text("Message...")
                            .foregroundColor(.black.opacity(0.4))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    TextField("", text: $message)
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .focused($isInputFocused)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.bgCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.cardStroke, lineWidth: 1)
                        )
                )
                .frame(maxWidth: .infinity)
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(message.isEmpty || isSending ? Color.gray : .blue)
                }
                .disabled(message.isEmpty || isSending)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.bgCard)
        }
    }

    // MARK: - Helper Views
    
    struct DateMessageView: View {
        let message: String
        
        var body: some View {
            Text(message)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
                .padding(.vertical, 4)
        }
    }

    struct MessageBubble: View {
        let message: ChatMessage
        let isFromCurrentUser: Bool
        
        var body: some View {
            HStack {
                if isFromCurrentUser {
                    Spacer(minLength: 60)
                }
                
                VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                    if !isFromCurrentUser && message.sender != "general" {
                        Text(message.sender)
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                            .padding(.leading, 12)
                    }
                    
                    Text(message.message)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(isFromCurrentUser ? Color.brandPrimary : Color.bgCard)
                        )
                        .foregroundColor(isFromCurrentUser ? .white : Color.textPrimary)
                    
                    Text(formattedTime)
                        .font(.system(size: 11))
                        .foregroundColor(Color.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.top, 2)
                }
                
                if !isFromCurrentUser {
                    Spacer(minLength: 60)
                }
            }
            .padding(.vertical, 4)
        }
        
        private var formattedTime: String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: message.timestamp)
        }
    }

    // MARK: - Methods
    
    // Add this method to keep pending clean if manager catches up
    private func updateMessagesList() {
        // Remove any pending that manager already has
        let managerMessages = chatManager.getMessages(sender: sender, receiver: receiver)
        let filteredPending = pendingMessages.filter { p in
            !managerMessages.contains { m in
                m.sender == p.sender && m.message == p.message && abs(m.timestamp.timeIntervalSince(p.timestamp)) < 5.0
            }
        }
        if filteredPending.count != pendingMessages.count {
            pendingMessages = filteredPending
        }
        print("✅ UI display messages count: \(displayMessages.count)")
    }
    
    // Get consistent color for friend
    func friendColor(for username: String) -> Color {
        let colors: [Color] = [.blue, .green, .purple, .orange, .pink, .teal]
        var total = 0
        for char in username.utf8 {
            total += Int(char)
        }
        return colors[total % colors.count]
    }
    
    private func sendMessage() {
        let messageToSend = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageToSend.isEmpty, !isSending else { return }

        isSending = true

        // ✅ Optimistic UI update: append locally so it shows immediately
        let optimistic = ChatMessage(sender: sender, message: messageToSend, timestamp: Date())
        pendingMessages.append(optimistic)
        scrollToBottom = true

        chatManager.sendMessage(to: receiver, sender: sender, message: messageToSend)

        // ✅ Reset fields immediately - ChatManager handles the rest
        DispatchQueue.main.async {
            self.message = ""
            self.isSending = false
            self.scrollToBottom = true // Scroll after sending
        }
    }
}

// For previewing
#Preview {
    ChatView(sender: "User1", receiver: "User2")
        .environmentObject(ChatManager())
}
