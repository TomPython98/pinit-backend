import Foundation
import SwiftUI

// MARK: - Content Moderation Manager for App Store Compliance

class ContentModerationManager: ObservableObject {
    static let shared = ContentModerationManager()
    
    @Published var isModerationEnabled = true
    @Published var reportedContent: [ReportedContent] = []
    @Published var blockedUsers: Set<String> = []
    
    private init() {
        loadBlockedUsers()
    }
    
    // MARK: - Content Filtering
    
    /// Filters inappropriate content from text
    func filterText(_ text: String) -> String {
        guard isModerationEnabled else { return text }
        
        let inappropriateWords = [
            "spam", "scam", "fake", "hate", "harassment",
            "bullying", "threat", "violence", "explicit",
            "inappropriate", "offensive"
        ]
        
        var filteredText = text
        
        for word in inappropriateWords {
            let pattern = "\\b\(word)\\b"
            filteredText = filteredText.replacingOccurrences(
                of: pattern,
                with: String(repeating: "*", count: word.count),
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        return filteredText
    }
    
    /// Checks if content contains inappropriate material
    func isContentAppropriate(_ content: String) -> Bool {
        guard isModerationEnabled else { return true }
        
        let inappropriatePatterns = [
            "spam", "scam", "fake", "hate", "harassment",
            "bullying", "threat", "violence", "explicit"
        ]
        
        let lowercaseContent = content.lowercased()
        
        for pattern in inappropriatePatterns {
            if lowercaseContent.contains(pattern) {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Reporting System
    
    /// Reports inappropriate content
    func reportContent(
        contentId: String,
        contentType: ContentType,
        reason: ReportReason,
        reporter: String,
        description: String? = nil
    ) {
        let report = ReportedContent(
            id: UUID().uuidString,
            contentId: contentId,
            contentType: contentType,
            reason: reason,
            reporter: reporter,
            description: description,
            timestamp: Date(),
            status: .pending
        )
        
        DispatchQueue.main.async {
            self.reportedContent.append(report)
        }
        
        // Send report to backend
        sendReportToBackend(report)
    }
    
    /// Reports a user for inappropriate behavior
    func reportUser(
        username: String,
        reason: ReportReason,
        reporter: String,
        description: String? = nil
    ) {
        reportContent(
            contentId: username,
            contentType: .user,
            reason: reason,
            reporter: reporter,
            description: description
        )
    }
    
    /// Reports an event for inappropriate content
    func reportEvent(
        eventId: String,
        reason: ReportReason,
        reporter: String,
        description: String? = nil
    ) {
        reportContent(
            contentId: eventId,
            contentType: .event,
            reason: reason,
            reporter: reporter,
            description: description
        )
    }
    
    /// Reports a message for inappropriate content
    func reportMessage(
        messageId: String,
        reason: ReportReason,
        reporter: String,
        description: String? = nil
    ) {
        reportContent(
            contentId: messageId,
            contentType: .message,
            reason: reason,
            reporter: reporter,
            description: description
        )
    }
    
    // MARK: - Blocking System
    
    /// Blocks a user
    func blockUser(_ username: String) {
        DispatchQueue.main.async {
            self.blockedUsers.insert(username)
        }
        
        saveBlockedUsers()
        
        // Send block to backend
        sendBlockToBackend(username)
    }
    
    /// Unblocks a user
    func unblockUser(_ username: String) {
        DispatchQueue.main.async {
            self.blockedUsers.remove(username)
        }
        
        saveBlockedUsers()
        
        // Send unblock to backend
        sendUnblockToBackend(username)
    }
    
    /// Checks if a user is blocked
    func isUserBlocked(_ username: String) -> Bool {
        return blockedUsers.contains(username)
    }
    
    // MARK: - Backend Integration
    
    private func sendReportToBackend(_ report: ReportedContent) {
        guard let url = URL(string: "\(APIConfig.serverBaseURL)/report_content/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "content_id": report.contentId,
            "content_type": report.contentType.rawValue,
            "reason": report.reason.rawValue,
            "reporter": report.reporter,
            "description": report.description ?? "",
            "timestamp": ISO8601DateFormatter().string(from: report.timestamp)
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Failed to send report: \(error)")
                }
            }.resume()
        } catch {
            print("Failed to encode report: \(error)")
        }
    }
    
    private func sendBlockToBackend(_ username: String) {
        guard let url = URL(string: "\(APIConfig.serverBaseURL)/block_user/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "blocked_user": username
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Failed to block user: \(error)")
                }
            }.resume()
        } catch {
            print("Failed to encode block: \(error)")
        }
    }
    
    private func sendUnblockToBackend(_ username: String) {
        guard let url = URL(string: "\(APIConfig.serverBaseURL)/unblock_user/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "unblocked_user": username
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Failed to unblock user: \(error)")
                }
            }.resume()
        } catch {
            print("Failed to encode unblock: \(error)")
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveBlockedUsers() {
        let blockedArray = Array(blockedUsers)
        UserDefaults.standard.set(blockedArray, forKey: "blockedUsers")
    }
    
    private func loadBlockedUsers() {
        if let blockedArray = UserDefaults.standard.array(forKey: "blockedUsers") as? [String] {
            blockedUsers = Set(blockedArray)
        }
    }
}

// MARK: - Data Models

struct ReportedContent: Identifiable, Codable {
    let id: String
    let contentId: String
    let contentType: ContentType
    let reason: ReportReason
    let reporter: String
    let description: String?
    let timestamp: Date
    var status: ReportStatus
    
    enum CodingKeys: String, CodingKey {
        case id, contentId = "content_id", contentType = "content_type"
        case reason, reporter, description, timestamp, status
    }
}

enum ContentType: String, Codable, CaseIterable {
    case user = "user"
    case event = "event"
    case message = "message"
    case profile = "profile"
    
    var displayName: String {
        switch self {
        case .user: return "User"
        case .event: return "Event"
        case .message: return "Message"
        case .profile: return "Profile"
        }
    }
}

enum ReportReason: String, Codable, CaseIterable {
    case spam = "spam"
    case harassment = "harassment"
    case inappropriate = "inappropriate"
    case fake = "fake"
    case violence = "violence"
    case hate = "hate"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .spam: return "Spam"
        case .harassment: return "Harassment"
        case .inappropriate: return "Inappropriate Content"
        case .fake: return "Fake Account"
        case .violence: return "Violence"
        case .hate: return "Hate Speech"
        case .other: return "Other"
        }
    }
    
    var description: String {
        switch self {
        case .spam: return "Repetitive or unwanted content"
        case .harassment: return "Bullying or threatening behavior"
        case .inappropriate: return "Offensive or explicit content"
        case .fake: return "Impersonation or false information"
        case .violence: return "Threats or violent content"
        case .hate: return "Discriminatory or hateful speech"
        case .other: return "Other violation of community guidelines"
        }
    }
}

enum ReportStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case reviewed = "reviewed"
    case resolved = "resolved"
    case dismissed = "dismissed"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending Review"
        case .reviewed: return "Under Review"
        case .resolved: return "Resolved"
        case .dismissed: return "Dismissed"
        }
    }
}

// MARK: - Content Moderation Views

struct ReportContentView: View {
    let contentType: ContentType
    let contentId: String
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason?
    @State private var description = ""
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.brandWarning)
                    
                    Text("Report \(contentType.displayName)")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Help us keep PinIt safe by reporting inappropriate content")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Reason Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Why are you reporting this?")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    ForEach(ReportReason.allCases, id: \.self) { reason in
                        Button(action: {
                            selectedReason = reason
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(reason.displayName)
                                        .font(.body.weight(.medium))
                                        .foregroundColor(.textPrimary)
                                    
                                    Text(reason.description)
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                                
                                Spacer()
                                
                                if selectedReason == reason {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.brandPrimary)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.textMuted)
                                }
                            }
                            .padding()
                            .background(Color.bgCard)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedReason == reason ? Color.brandPrimary : Color.cardStroke, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Additional Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Additional Details (Optional)")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .padding(12)
                        .background(Color.bgCard)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cardStroke, lineWidth: 1)
                        )
                }
                
                Spacer()
                
                // Submit Button
                Button(action: {
                    showingConfirmation = true
                }) {
                    Text("Submit Report")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedReason != nil ? Color.brandPrimary : Color.textMuted)
                        .cornerRadius(12)
                }
                .disabled(selectedReason == nil)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.bgSurface.ignoresSafeArea())
            .navigationBarHidden(true)
            .alert("Report Submitted", isPresented: $showingConfirmation) {
                Button("OK") {
                    submitReport()
                    dismiss()
                }
            } message: {
                Text("Thank you for helping keep PinIt safe. We'll review your report.")
            }
        }
    }
    
    private func submitReport() {
        guard let reason = selectedReason else { return }
        
        ContentModerationManager.shared.reportContent(
            contentId: contentId,
            contentType: contentType,
            reason: reason,
            reporter: "current_user", // Replace with actual current user
            description: description.isEmpty ? nil : description
        )
    }
}

// MARK: - Preview
#Preview {
    ReportContentView(
        contentType: .user,
        contentId: "test_user"
    )
}





