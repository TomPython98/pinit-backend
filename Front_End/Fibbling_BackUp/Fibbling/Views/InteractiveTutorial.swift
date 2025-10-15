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

// MARK: - Professional Interactive Tutorial
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
                            Image(systemName: "map.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.brandPrimary)
                                .offset(y: animationAmount * 4)
                            
                            VStack(spacing: 8) {
                                Text("Explore Events")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                
                                Text("Tap on event pins to see what's happening near you")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.textSecondary)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Feature highlights
                        VStack(spacing: 12) {
                            FeatureRow(icon: "location.fill", text: "See nearby events")
                            FeatureRow(icon: "mappin.and.ellipse", text: "Filter by distance")
                            FeatureRow(icon: "heart.fill", text: "Add events to favorites")
                        }
                        
                        // Action button
                        Button(action: dismissTutorial) {
                            Text("Continue")
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
                                Text("Create & Share")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                
                                Text("Tap 'Add Event' to create your own and invite friends")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.textSecondary)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Feature highlights
                        VStack(spacing: 12) {
                            FeatureRow(icon: "plus.app.fill", text: "Create new events")
                            FeatureRow(icon: "person.2.fill", text: "Invite your friends")
                            FeatureRow(icon: "checkmark.circle.fill", text: "Manage RSVPs")
                        }
                        
                        // Action buttons
                        VStack(spacing: 10) {
                            Button(action: dismissTutorial) {
                                Text("Try It Out")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.brandPrimary)
                                    )
                            }
                            
                            Button(action: dismissTutorial) {
                                Text("Skip Tutorial")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.brandPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
                                    )
                            }
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
            TutorialManager.shared.completeTutorial()
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

// MARK: - Tutorial Manager
class TutorialManager: ObservableObject {
    enum TutorialStep {
        case welcome       // ContentView - highlights existing map card
        case map           // Map view tutorial
        case completed     // Done
    }
    
    @Published var tutorialStep: TutorialStep = .welcome
    @Published var isActive = false
    
    static let shared = TutorialManager()
    
    func moveToMapStep() {
        tutorialStep = .map
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
