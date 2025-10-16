import SwiftUI

// MARK: - Preference Keys for UI Component Positions
struct MapCardFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct AddEventButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - Main Dashboard Tutorial
struct InteractiveTutorial: View {
    @AppStorage("hasSeenMapTutorial") private var hasSeenMapTutorial = false
    @Binding var isShowing: Bool
    @State private var mapCardFrame: CGRect = .zero
    @State private var animationAmount: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent dark backdrop with blur effect
                Color.black
                    .opacity(0.6)
                    .ignoresSafeArea()
                
                // Spotlight cutout
                if mapCardFrame != .zero {
                    Canvas { context, _ in
                        // Draw the dark overlay
                        var path = Path(CGRect(origin: .zero, size: geometry.size))
                        
                        // Create spotlight with rounded rectangle
                        let spotlightRect = mapCardFrame.insetBy(dx: -12, dy: -12)
                        let spotlightPath = Path(roundedRect: spotlightRect, cornerRadius: 24)
                        
                        path.addPath(spotlightPath)
                        
                        context.fill(
                            path,
                            with: .color(.black.opacity(0.65))
                        )
                    }
                    .ignoresSafeArea()
                    
                    // Animated glow ring around spotlight
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .brandPrimary.opacity(0.8),
                                    .brandPrimary.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(
                            width: mapCardFrame.width + 24,
                            height: mapCardFrame.height + 24
                        )
                        .position(x: mapCardFrame.midX, y: mapCardFrame.midY)
                        .shadow(color: .brandPrimary.opacity(0.6), radius: 8 + animationAmount * 6)
                        .opacity(0.8 + animationAmount * 0.2)
                }
                
                // Tutorial content card (positioned above or below spotlight, not overlapping)
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        // Header with icon and title
                        VStack(spacing: 12) {
                            Image(systemName: "app.badge.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.brandPrimary)
                                .offset(y: animationAmount * 4)
                            
                            VStack(spacing: 8) {
                                Text("Welcome to PinIt")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                
                                Text("Set up your profile, manage events, and connect with your community. Here's how to get started")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.textSecondary)
                                    .lineLimit(4)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Main dashboard features
                        VStack(spacing: 12) {
                            FeatureRow(icon: "person.circle.fill", text: "Profile Setup")
                            FeatureRow(icon: "ticket.fill", text: "Event Management")
                            FeatureRow(icon: "calendar", text: "Calendar View")
                            FeatureRow(icon: "person.3.fill", text: "Community Hub")
                        }
                        
                        // Feature Details
                        VStack(spacing: 8) {
                            Text("What You Can Do")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textPrimary)
                                .padding(.top, 8)
                            
                            VStack(spacing: 6) {
                                NavigationGuideRow(icon: "person.circle.fill", text: "Profile", description: "Set skills, interests & bio to match")
                                NavigationGuideRow(icon: "ticket.fill", text: "Events", description: "View invitations & hosted events")
                                NavigationGuideRow(icon: "calendar", text: "Calendar", description: "See all events in your schedule")
                                NavigationGuideRow(icon: "person.3.fill", text: "Community Hub", description: "Discover trending events")
                            }
                        }
                        
                        // Action button
                        Button(action: dismissTutorial) {
                            Text("Get Started")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.brandPrimary)
                                )
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.bgCard)
                            .shadow(
                                color: Color.black.opacity(0.15),
                                radius: 20,
                                x: 0,
                                y: 10
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .opacity(opacity)
            }
        }
        .onPreferenceChange(MapCardFramePreferenceKey.self) { frame in
            mapCardFrame = frame
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1
            }
            startPulse()
        }
    }
    
    private func startPulse() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            animationAmount = 1.0
        }
    }
    
    private func dismissTutorial() {
        withAnimation(.easeOut(duration: 0.4)) {
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isShowing = false
            TutorialManager.shared.moveToMapStep()
        }
    }
}

// MARK: - Professional Map Tutorial Overlay
struct MapTutorialOverlay: View {
    @AppStorage("hasSeenMapTutorial") private var hasSeenMapTutorial = false
    @State private var addButtonFrame: CGRect = .zero
    @State private var animationAmount: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var slideOffset: CGFloat = 50
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent dark backdrop
                Color.black
                    .opacity(0.6)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { dismissTutorial() }
                
                // Spotlight cutout around add button
                if addButtonFrame != .zero {
                    Canvas { context, _ in
                        // Draw the dark overlay
                        var path = Path(CGRect(origin: .zero, size: geometry.size))
                        
                        // Create spotlight with capsule shape
                        let spotlightRect = addButtonFrame.insetBy(dx: -10, dy: -10)
                        let spotlightPath = Path(roundedRect: spotlightRect, cornerRadius: spotlightRect.height / 2)
                        
                        path.addPath(spotlightPath)
                        
                        context.fill(
                            path,
                            with: .color(.black.opacity(0.65))
                        )
                    }
                    .ignoresSafeArea()
                    
                    // Animated glow ring
                    Capsule()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .brandPrimary.opacity(0.8),
                                    .brandPrimary.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                        .frame(
                            width: addButtonFrame.width + 20,
                            height: addButtonFrame.height + 20
                        )
                        .position(x: addButtonFrame.midX, y: addButtonFrame.midY)
                        .shadow(color: .brandPrimary.opacity(0.7), radius: 10 + animationAmount * 8)
                        .opacity(0.8 + animationAmount * 0.2)
                }
                
                // Professional tutorial card positioned to avoid overlap
                VStack(spacing: 0) {
                    // Close button top-right
                    HStack {
                        Spacer()
                        Button(action: dismissTutorial) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.textSecondary.opacity(0.6))
                        }
                        .padding(.top, 16)
                        .padding(.trailing, 16)
                    }
                    
                    Spacer()
                    
                    // Content card
                    VStack(spacing: 20) {
                        // Icon and title
                        VStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.brandPrimary)
                                .offset(y: animationAmount * 4)
                            
                            VStack(spacing: 8) {
                                Text("Map Features")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                
                                Text("Discover events on the map with filtering and event creation tools")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.textSecondary)
                                    .lineLimit(4)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Feature highlights
                        VStack(spacing: 12) {
                            FeatureRow(icon: "plus.circle.fill", text: "Create Event Button")
                            FeatureRow(icon: "line.3.horizontal.decrease", text: "Filter Events")
                            FeatureRow(icon: "magnifyingglass", text: "Search Events")
                            FeatureRow(icon: "mappin.and.ellipse", text: "View Event Locations")
                        }
                        
                        // Map Filter Options
                        VStack(spacing: 8) {
                            Text("Filter Options")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textPrimary)
                                .padding(.top, 8)
                            
                            VStack(spacing: 6) {
                                NavigationGuideRow(icon: "checkmark.circle.fill", text: "My Events", description: "Events you've RSVP'd to")
                                NavigationGuideRow(icon: "person.2.fill", text: "Auto Matched", description: "Events matched to your interests")
                                NavigationGuideRow(icon: "globe", text: "All Events", description: "All public events nearby")
                                NavigationGuideRow(icon: "magnifyingglass", text: "Search", description: "Find events by keywords")
                            }
                        }
                        
                        // Action button
                        Button(action: dismissTutorial) {
                            Text("Explore Map")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.brandPrimary)
                                )
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.bgCard)
                            .shadow(
                                color: Color.black.opacity(0.15),
                                radius: 24,
                                x: 0,
                                y: 12
                            )
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    .offset(y: slideOffset)
                }
                .opacity(opacity)
            }
        }
        .onPreferenceChange(AddEventButtonFramePreferenceKey.self) { frame in
            addButtonFrame = frame
        }
        .onAppear {
            slideOffset = 50
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1
                slideOffset = 0
            }
            startPulse()
        }
    }
    
    private func startPulse() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            animationAmount = 1.0
        }
    }
    
    private func dismissTutorial() {
        withAnimation(.easeOut(duration: 0.4)) {
            opacity = 0
            slideOffset = 50
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            hasSeenMapTutorial = true
            TutorialManager.shared.moveToSocialStep()
        }
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.brandPrimary)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.brandPrimary.opacity(0.08))
        )
    }
}

// MARK: - Navigation Guide Row Component
struct NavigationGuideRow: View {
    let icon: String
    let text: String
    let description: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.brandSecondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text(description)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.brandSecondary.opacity(0.05))
        )
    }
}

// MARK: - Social Features Tutorial Overlay
struct SocialFeaturesTutorialOverlay: View {
    @AppStorage("hasSeenSocialTutorial") private var hasSeenSocialTutorial = false
    @State private var animationAmount: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var slideOffset: CGFloat = 50
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent dark backdrop
                Color.black
                    .opacity(0.6)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { dismissTutorial() }
                
                // Professional tutorial card
                VStack(spacing: 0) {
                    // Close button top-right
                    HStack {
                        Spacer()
                        Button(action: dismissTutorial) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.textSecondary.opacity(0.6))
                        }
                        .padding(.top, 16)
                        .padding(.trailing, 16)
                    }
                    
                    Spacer()
                    
                    // Content card
                    VStack(spacing: 20) {
                        // Icon and title
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.brandPrimary)
                                .offset(y: animationAmount * 4)
                            
                            VStack(spacing: 8) {
                                Text("Connect & Socialize")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                
                                Text("Build your network, chat with friends, and discover like-minded people in your community")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.textSecondary)
                                    .lineLimit(4)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Feature highlights
                        VStack(spacing: 12) {
                            FeatureRow(icon: "person.badge.plus", text: "Send friend requests")
                            FeatureRow(icon: "bubble.left.and.bubble.right.fill", text: "Chat with friends")
                            FeatureRow(icon: "star.circle.fill", text: "Rate event experiences")
                            FeatureRow(icon: "person.3.fill", text: "Join community discussions")
                        }
                        
                        // Specific Feature Locations
                        VStack(spacing: 8) {
                            Text("Where to Find Features")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textPrimary)
                                .padding(.top, 8)
                            
                            VStack(spacing: 6) {
                                NavigationGuideRow(icon: "ticket.fill", text: "Events", description: "See invitations & manage hosted events")
                                NavigationGuideRow(icon: "person.2.fill", text: "Friends", description: "View friends list & chat messages")
                                NavigationGuideRow(icon: "calendar", text: "Calendar", description: "See all events & your schedule")
                                NavigationGuideRow(icon: "person.circle.fill", text: "Profile", description: "Edit profile & app settings")
                            }
                        }
                        
                        // Action button
                        Button(action: dismissTutorial) {
                            Text("Start Connecting")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.brandPrimary)
                                )
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.bgCard)
                            .shadow(
                                color: Color.black.opacity(0.15),
                                radius: 24,
                                x: 0,
                                y: 12
                            )
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    .offset(y: slideOffset)
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            slideOffset = 50
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1
                slideOffset = 0
            }
            startPulse()
        }
    }
    
    private func startPulse() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            animationAmount = 1.0
        }
    }
    
    private func dismissTutorial() {
        withAnimation(.easeOut(duration: 0.4)) {
            opacity = 0
            slideOffset = 50
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            hasSeenSocialTutorial = true
            TutorialManager.shared.completeTutorial()
        }
    }
}

// MARK: - Tutorial Manager
class TutorialManager: ObservableObject {
    enum TutorialStep {
        case welcome       // ContentView - highlights existing map card
        case map           // Map view tutorial
        case social        // Social features tutorial
        case completed     // Done
    }
    
    @Published var tutorialStep: TutorialStep = .welcome
    @Published var isActive = false
    
    static let shared = TutorialManager()
    
    func moveToMapStep() {
        tutorialStep = .map
        isActive = true
    }
    
    func moveToSocialStep() {
        tutorialStep = .social
        isActive = true
    }
    
    func completeTutorial() {
        tutorialStep = .completed
        isActive = false
    }
    
    func reset() {
        tutorialStep = .welcome
        isActive = false
    }
}

#Preview {
    InteractiveTutorial(isShowing: .constant(true))
}
