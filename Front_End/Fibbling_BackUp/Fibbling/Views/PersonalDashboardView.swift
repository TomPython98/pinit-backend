import SwiftUI
import MessageUI

struct ShareEventView: UIViewControllerRepresentable {
    let event: StudyEvent
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let text = "Join me at '\(event.title)' on \(formatDate(event.time))! 🎉"
        let url = URL(string: "https://pinit.app/event/\(event.id.uuidString)")
        
        var items: [Any] = [text]
        if let url = url {
            items.append(url)
        }
        
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            dismiss()
        }
        
        return activityViewController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PersonalDashboardView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @State private var userStats = UserStats()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    profileHeader
                    
                    // Stats Cards
                    statsSection
                    
                    // Recent Activity
                    recentActivitySection
                    
                    // Achievements
                    achievementsSection
                }
                .padding()
            }
            .navigationTitle("My Dashboard")
            .background(Color.bgSurface)
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.brandPrimary)
                .frame(width: 80, height: 80)
                .overlay(
                    Text(String(accountManager.currentUser?.first ?? "U"))
                        .font(.title.bold())
                        .foregroundColor(.white)
                )
            
            Text(accountManager.currentUser ?? "User")
                .font(.title2.bold())
                .foregroundColor(Color.textPrimary)
            
            Text("Member since \(formatJoinDate())")
                .font(.caption)
                .foregroundColor(Color.textSecondary)
        }
        .padding()
        .background(Color.bgCard)
        .cornerRadius(16)
    }
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            Text("Your Activity")
                .font(.headline)
                .foregroundColor(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Events Hosted",
                    value: "\(userStats.eventsHosted)",
                    icon: "calendar.badge.plus",
                    color: .brandPrimary
                )
                
                StatCard(
                    title: "Events Attended",
                    value: "\(userStats.eventsAttended)",
                    icon: "person.2.fill",
                    color: .green
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Friends Made",
                    value: "\(userStats.friendsCount)",
                    icon: "heart.fill",
                    color: .pink
                )
                
                StatCard(
                    title: "Average Rating",
                    value: String(format: "%.1f", userStats.averageRating),
                    icon: "star.fill",
                    color: .orange
                )
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(Color.textPrimary)
            
            VStack(spacing: 8) {
                ActivityRow(
                    icon: "calendar.badge.plus",
                    title: "Created 'Study Group'",
                    time: "2 hours ago",
                    color: .brandPrimary
                )
                
                ActivityRow(
                    icon: "person.badge.plus",
                    title: "Made 3 new friends",
                    time: "1 day ago",
                    color: .green
                )
                
                ActivityRow(
                    icon: "star.fill",
                    title: "Received 5-star rating",
                    time: "3 days ago",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.bgCard)
        .cornerRadius(16)
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
                .foregroundColor(Color.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                AchievementBadge(
                    title: "First Event",
                    icon: "calendar.badge.plus",
                    isUnlocked: userStats.eventsHosted > 0,
                    color: .brandPrimary
                )
                
                AchievementBadge(
                    title: "Social Butterfly",
                    icon: "person.3.fill",
                    isUnlocked: userStats.friendsCount >= 10,
                    color: .pink
                )
                
                AchievementBadge(
                    title: "Top Host",
                    icon: "crown.fill",
                    isUnlocked: userStats.eventsHosted >= 5,
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.bgCard)
        .cornerRadius(16)
    }
    
    private func formatJoinDate() -> String {
        // This would come from user data
        return "January 2025"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title.bold())
                .foregroundColor(Color.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.bgCard)
        .cornerRadius(12)
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Color.textPrimary)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AchievementBadge: View {
    let title: String
    let icon: String
    let isUnlocked: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isUnlocked ? color : Color.textMuted)
            
            Text(title)
                .font(.caption)
                .foregroundColor(isUnlocked ? Color.textPrimary : Color.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(isUnlocked ? color.opacity(0.1) : Color.bgSecondary)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnlocked ? color : Color.textMuted.opacity(0.3), lineWidth: 1)
        )
    }
}

struct UserStats {
    var eventsHosted: Int = 3
    var eventsAttended: Int = 12
    var friendsCount: Int = 8
    var averageRating: Double = 4.7
}

#Preview {
    PersonalDashboardView()
        .environmentObject(UserAccountManager())
}
