import SwiftUI

struct GroupChatView: View {
    // Create the WebSocket manager as a StateObject
    @StateObject private var webSocketManager: GroupChatWebSocketManager
    
    @State private var messageText = ""
    @State private var isSending = false
    
    let eventID: UUID
    let currentUser: String
    let eventTitle: String  // NEW: the actual event title
    
    init(eventID: UUID, currentUser: String, eventTitle: String) {
        _webSocketManager = StateObject(
            wrappedValue: GroupChatWebSocketManager(eventID: eventID, currentUsername: currentUser)
        )
        self.eventID = eventID
        self.currentUser = currentUser
        self.eventTitle = eventTitle
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [.socialLight, .socialAccent]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    headerView
                    messagesList
                    messageInput
                }
                .padding(.bottom, 10)
            }
            .navigationBarHidden(true)
            .onAppear {
                webSocketManager.connect()
            }
            .onDisappear {
                webSocketManager.disconnect()
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        // Use the actual event title here
        Text("Group Chat: \(eventTitle)")
            .font(.system(size: 26, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.socialDark)
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            .padding(.horizontal)
    }
    
    // MARK: - Messages List
    private var messagesList: some View {
        List {
            ForEach(webSocketManager.messages) { msg in
                HStack(alignment: .bottom) {
                    if msg.sender == currentUser {
                        Spacer(minLength: 50)
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(msg.sender)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(msg.text)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .foregroundColor(.white)
                                .background(Color.socialPrimary)
                                .cornerRadius(12)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(msg.sender)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(msg.text)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .foregroundColor(.black)
                                .background(Color.white.opacity(0.85))
                                .cornerRadius(12)
                        }
                        Spacer(minLength: 50)
                    }
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.horizontal)
    }
    
    // MARK: - Message Input
    private var messageInput: some View {
        HStack {
            TextField("Type a message...", text: $messageText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button {
                sendMessage()
            } label: {
                Text("Send")
                    .padding()
                    .background(isSending ? Color.gray : Color.socialPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isSending)
        }
        .padding()
        .background(
            Color.white.opacity(0.85)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
        )
    }
    
    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }
        
        isSending = true
        webSocketManager.sendMessage(trimmed)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.messageText = ""
            self.isSending = false
        }
    }
}
