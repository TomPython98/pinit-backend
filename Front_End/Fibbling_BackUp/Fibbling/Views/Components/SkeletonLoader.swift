import SwiftUI

// MARK: - Skeleton Loader Components
/// Professional skeleton loaders for better perceived performance

struct SkeletonLoader: View {
    @State private var isAnimating = false
    
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(width: CGFloat? = nil, height: CGFloat = 20, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemGray6),
                        Color(.systemGray5),
                        Color(.systemGray6)
                    ]),
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Skeleton User Card
struct SkeletonUserCard: View {
    var body: some View {
        HStack(spacing: 16) {
            // Avatar skeleton
            SkeletonLoader(width: 50, height: 50, cornerRadius: 25)
            
            VStack(alignment: .leading, spacing: 8) {
                // Name skeleton
                SkeletonLoader(width: 120, height: 16, cornerRadius: 4)
                
                // Status skeleton
                SkeletonLoader(width: 80, height: 12, cornerRadius: 4)
            }
            
            Spacer()
            
            // Button skeleton
            SkeletonLoader(width: 80, height: 32, cornerRadius: 16)
        }
        .padding()
        .background(Color.bgCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cardStroke, lineWidth: 1)
        )
    }
}

// MARK: - Skeleton Event Card
struct SkeletonEventCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Icon skeleton
                SkeletonLoader(width: 40, height: 40, cornerRadius: 20)
                
                VStack(alignment: .leading, spacing: 6) {
                    // Title skeleton
                    SkeletonLoader(width: 150, height: 18, cornerRadius: 4)
                    
                    // Type skeleton
                    SkeletonLoader(width: 100, height: 14, cornerRadius: 4)
                }
                
                Spacer()
            }
            
            // Description skeleton
            SkeletonLoader(width: nil, height: 14, cornerRadius: 4)
            SkeletonLoader(width: 200, height: 14, cornerRadius: 4)
            
            HStack(spacing: 12) {
                // Date skeleton
                SkeletonLoader(width: 100, height: 12, cornerRadius: 4)
                
                Spacer()
                
                // Attendees skeleton
                SkeletonLoader(width: 60, height: 12, cornerRadius: 4)
            }
        }
        .padding()
        .background(Color.bgCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Skeleton List Loading
struct SkeletonListView: View {
    let itemType: SkeletonItemType
    let count: Int
    
    enum SkeletonItemType {
        case userCard
        case eventCard
        case messageRow
        case calendarDay
    }
    
    init(itemType: SkeletonItemType = .userCard, count: Int = 5) {
        self.itemType = itemType
        self.count = count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<count, id: \.self) { _ in
                switch itemType {
                case .userCard:
                    SkeletonUserCard()
                case .eventCard:
                    SkeletonEventCard()
                case .messageRow:
                    SkeletonMessageRow()
                case .calendarDay:
                    SkeletonCalendarDay()
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Skeleton Message Row
struct SkeletonMessageRow: View {
    @State private var isFromCurrentUser = Bool.random()
    
    var body: some View {
        HStack {
            if !isFromCurrentUser {
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonLoader(width: 200, height: 14, cornerRadius: 4)
                    SkeletonLoader(width: 150, height: 14, cornerRadius: 4)
                }
                .padding()
                .background(Color.bgCard)
                .cornerRadius(16, corners: [.topRight, .bottomLeft, .bottomRight])
                
                Spacer()
            } else {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    SkeletonLoader(width: 180, height: 14, cornerRadius: 4)
                    SkeletonLoader(width: 120, height: 14, cornerRadius: 4)
                }
                .padding()
                .background(Color.brandPrimary.opacity(0.2))
                .cornerRadius(16, corners: [.topLeft, .bottomLeft, .bottomRight])
            }
        }
    }
}

// MARK: - Skeleton Calendar Day
struct SkeletonCalendarDay: View {
    var body: some View {
        VStack(spacing: 8) {
            // Day number
            SkeletonLoader(width: 40, height: 40, cornerRadius: 20)
            
            // Event indicators
            HStack(spacing: 4) {
                SkeletonLoader(width: 6, height: 6, cornerRadius: 3)
                SkeletonLoader(width: 6, height: 6, cornerRadius: 3)
            }
        }
        .frame(width: 50, height: 70)
    }
}

// Note: RoundedCorner and cornerRadius extension are defined in CalendarView.swift
// They are shared across the app

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Text("Skeleton Loaders").font(.title.bold())
            
            Text("User Cards").font(.headline)
            SkeletonListView(itemType: .userCard, count: 3)
            
            Text("Event Cards").font(.headline).padding(.top)
            SkeletonListView(itemType: .eventCard, count: 2)
            
            Text("Messages").font(.headline).padding(.top)
            SkeletonListView(itemType: .messageRow, count: 4)
        }
        .padding()
    }
    .background(Color.bgSurface)
}

