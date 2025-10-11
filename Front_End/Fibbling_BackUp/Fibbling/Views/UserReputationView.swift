import SwiftUI

struct UserReputationView: View {
    let username: String
    @StateObject private var reputationManager = UserReputationManager()
    @State private var showRatingsList = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            if reputationManager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else if let errorMessage = reputationManager.errorMessage {
                ErrorView(message: errorMessage)
            } else {
                reputationHeader
                    .padding(.bottom, 5)
                
                trustLevelView
                    .padding(.bottom, 10)
                
                statsView
                    .padding(.bottom, 15)
                
                ratingsPreview
            }
        }
        .padding()
        .background(Color.bgCard)
        .cornerRadius(16)
        .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 2)
        .onAppear {
            // Always use real API calls to connect with the backend
            reputationManager.fetchUserReputation(username: username) { success in
                if success {
                    reputationManager.fetchUserRatings(username: username) { _ in }
                }
            }
        }
        .sheet(isPresented: $showRatingsList) {
            UserRatingsListView(ratings: reputationManager.userRatings)
        }
    }
    
    private var reputationHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Reputation")
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                
                if reputationManager.userStats.totalRatings > 0 {
                    Text("Based on \(reputationManager.userStats.totalRatings) ratings")
                        .font(.subheadline)
                        .foregroundColor(Color.textSecondary)
                } else {
                    Text("No ratings yet")
                        .font(.subheadline)
                        .foregroundColor(Color.textSecondary)
                }
            }
            
            Spacer()
            
            ratingStars
        }
    }
    
    private var ratingStars: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= Int(reputationManager.userStats.averageRating.rounded()) ? "star.fill" : "star")
                    .foregroundColor(.yellow)
            }
            
            Text(String(format: "%.1f", reputationManager.userStats.averageRating))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(Color.textPrimary)
                .padding(.leading, 4)
        }
    }
    
    private var trustLevelView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Trust Level")
                .font(.headline)
                .foregroundColor(Color.textPrimary)
            
            HStack {
                Image(systemName: trustLevelIcon)
                    .foregroundColor(trustLevelColor)
                
                Text(reputationManager.userStats.trustLevel.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(trustLevelColor)
            }
            
            // Progress to next level (if not at max)
            if reputationManager.userStats.trustLevel.level < 5 {
                let nextLevel = UserTrustLevel.levels.first { $0.level == reputationManager.userStats.trustLevel.level + 1 }
                
                if let nextLevel = nextLevel {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Progress to \(nextLevel.title):")
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                        
                        HStack {
                            // Ratings progress
                            if reputationManager.userStats.totalRatings < nextLevel.requiredRatings {
                        Text("\(reputationManager.userStats.totalRatings)/\(nextLevel.requiredRatings) ratings")
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                            }
                            
                            Spacer()
                            
                            // Rating average progress
                            if reputationManager.userStats.averageRating < nextLevel.minAverageRating {
                                Text("Need \(String(format: "%.1f", nextLevel.minAverageRating)) avg rating")
                                    .font(.caption)
                                    .foregroundColor(Color.textSecondary)
                            }
                        }
                        
                        // Progress bar
                        ProgressView(value: progressToNextLevel)
                            .tint(trustLevelColor)
                    }
                }
            }
        }
    }
    
    private var statsView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Activity")
                .font(.headline)
                .foregroundColor(Color.textPrimary)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(reputationManager.userStats.eventsHosted)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.textPrimary)
                    Text("Hosted")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
                
                VStack {
                    Text("\(reputationManager.userStats.eventsAttended)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.textPrimary)
                    Text("Attended")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
                
                VStack {
                    Text("\(reputationManager.userStats.totalRatings)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.textPrimary)
                    Text("Reviews")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 5)
        }
    }
    
    private var ratingsPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Reviews")
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                if !reputationManager.userRatings.isEmpty {
                    Button("See All") {
                        showRatingsList = true
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.brandPrimary)
                }
            }
            
            if reputationManager.userRatings.isEmpty {
                Text("No reviews yet")
                    .foregroundColor(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
            } else {
                ForEach(Array(reputationManager.userRatings.prefix(2))) { rating in
                    RatingRowView(rating: rating)
                        .padding(.vertical, 5)
                }
            }
        }
    }
    
    // Helper computed properties
    private var trustLevelIcon: String {
        switch reputationManager.userStats.trustLevel.level {
        case 1: return "person"
        case 2: return "person.fill"
        case 3: return "person.fill.checkmark"
        case 4: return "person.fill.badge.plus"
        case 5: return "crown.fill"
        default: return "person"
        }
    }
    
    private var trustLevelColor: Color {
        switch reputationManager.userStats.trustLevel.level {
        case 1: return Color.textSecondary
        case 2: return Color.brandSecondary
        case 3: return Color.brandSuccess
        case 4: return Color(red: 124/255, green: 58/255, blue: 237/255)  // Purple
        case 5: return Color.brandWarning
        default: return Color.textSecondary
        }
    }
    
    private var progressToNextLevel: Double {
        guard reputationManager.userStats.trustLevel.level < 5 else { return 1.0 }
        
        if let nextLevel = UserTrustLevel.levels.first(where: { $0.level == reputationManager.userStats.trustLevel.level + 1 }) {
            // Calculate progress as an average of ratings count and rating average progress
            let currentLevel = reputationManager.userStats.trustLevel
            
            let ratingCountProgress = min(1.0, Double(reputationManager.userStats.totalRatings) / Double(nextLevel.requiredRatings))
            
            let ratingValueRange = nextLevel.minAverageRating - currentLevel.minAverageRating
            let currentRatingProgress = min(1.0, (reputationManager.userStats.averageRating - currentLevel.minAverageRating) / ratingValueRange)
            
            // Average of the two progress measures
            return (ratingCountProgress + currentRatingProgress) / 2.0
        }
        
        return 0.0
    }
}

struct UserRatingsListView: View {
    let ratings: [UserRating]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean professional background - use white explicitly
                Color.white
                    .ignoresSafeArea()
                
                List {
                    ForEach(ratings) { rating in
                        RatingRowView(rating: rating)
                            .listRowBackground(Color.white)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.white)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("All Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.black)
                }
            }
        }
    }
}

struct RatingRowView: View {
    let rating: UserRating
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rating.fromUser)
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
            
            HStack {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= rating.rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
            
            if let reference = rating.reference, !reference.isEmpty {
                Text(reference)
                    .font(.subheadline)
                    .foregroundColor(Color.textSecondary)
                    .padding(.top, 2)
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: parseDate(from: rating.createdAt))
    }
    
    private func parseDate(from dateString: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString) ?? Date()
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
                .padding()
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
    }
}

#Preview {
    UserReputationView(username: "JohnSmith")
        .padding()
} 