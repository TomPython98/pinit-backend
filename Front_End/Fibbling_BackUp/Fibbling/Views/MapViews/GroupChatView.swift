import SwiftUI

struct GroupChatView: View {
    // Create the WebSocket manager as a StateObject
    @StateObject private var webSocketManager: GroupChatWebSocketManager
    
    @State private var messageText = ""
    @State private var isSending = false
    @Environment(\.dismiss) private var dismiss
    
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
                // Professional background like ContentView
                Color.bgSurface
                    .ignoresSafeArea()
                
                // Elegant background gradient
                LinearGradient(
                    colors: [Color.gradientStart.opacity(0.05), Color.gradientEnd.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Professional header with status bar
                    professionalHeaderView
                    
                    // Messages area with proper styling
                    messagesList
                    
                    // Professional input area
                    messageInput
                }
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
    
    // MARK: - Professional Header
    private var professionalHeaderView: some View {
        VStack(spacing: 0) {
            HStack {
                // Back button with professional styling
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.bgCard)
                                .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
                        )
                }
                
                Spacer()
                
                // Professional title section
                VStack(spacing: 2) {
                    Text("Group Chat")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text(eventTitle)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Chat info button
                Button(action: {}) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.bgCard)
                                .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
                        )
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
                                .foregroundColor(Color.textSecondary)
                            Text(msg.text)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .foregroundColor(.white)
                                .background(Color.brandPrimary)
                                .cornerRadius(12)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(msg.sender)
                                .font(.caption)
                                .foregroundColor(Color.textSecondary)
                            Text(msg.text)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .foregroundColor(Color.textPrimary)
                                .background(Color.bgCard)
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
    
    // MARK: - Professional Message Input
    private var messageInput: some View {
        VStack(spacing: 0) {
            // Professional input area
            HStack(spacing: 12) {
                // Message input field
                HStack {
                    TextField("Type a message...", text: $messageText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.bgCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.cardStroke, lineWidth: 1)
                                )
                        )
                        .foregroundColor(Color.textPrimary)
                }
                
                // Send button with professional styling
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(isSending ? Color.textSecondary : Color.brandPrimary)
                                .shadow(color: Color.cardShadow, radius: 6, x: 0, y: 3)
                        )
                }
                .disabled(isSending || messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .scaleEffect(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: messageText.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Rectangle()
                    .fill(Color.bgCard)
                    .shadow(color: Color.cardShadow, radius: 12, x: 0, y: -6)
            )
        }
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
