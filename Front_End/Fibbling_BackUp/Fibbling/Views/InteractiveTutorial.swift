import SwiftUI

// MARK: - Interactive Tutorial Overlay
struct InteractiveTutorial: View {
    @AppStorage("hasSeenMapTutorial") private var hasSeenMapTutorial = false
    @Binding var isShowing: Bool
    @ObservedObject var tutorialManager = TutorialManager.shared
    @State private var pulseScale: CGFloat = 1.0
    @State private var showConfetti = false
    
    var currentStep: TutorialManager.TutorialStep {
        tutorialManager.tutorialStep
    }
    
    var body: some View {
        ZStack {
            // Professional dark overlay
            Color.black
                .opacity(0.85)
                .ignoresSafeArea()
                .allowsHitTesting(currentStep == .completed)
            
            // Spotlight effect for specific areas
            if currentStep == .tapOnMap {
                // Spotlight on map area
                mapSpotlight
            } else if currentStep == .tapAddEvent {
                // Spotlight on + button
                addButtonSpotlight
            }
            
            // Tutorial content
            VStack {
                Spacer()
                
                if currentStep == .tapOnMap {
                    tutorialTooltip(
                        icon: "map.fill",
                        title: "Tap on any pin",
                        subtitle: "See what events are happening near you",
                        position: .top
                    )
                } else if currentStep == .tapAddEvent {
                    tutorialTooltip(
                        icon: "plus.circle.fill",
                        title: "Create your own event",
                        subtitle: "Tap the + button to host an event",
                        position: .bottom
                    )
                }
                
                Spacer()
                
                // Skip button at bottom
                if currentStep != .completed {
                    Button(action: skipTutorial) {
                        Text("Skip Tutorial")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            startPulseAnimation()
        }
        .onChange(of: currentStep) { oldStep, newStep in
            if newStep == .completed {
                // Auto-dismiss when tutorial completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    completeTutorial()
                }
            }
        }
    }
    
    // MARK: - Spotlight for Map
    private var mapSpotlight: some View {
        GeometryReader { geometry in
            // Clear circle in the middle of map area
            ZStack {
                Color.black.opacity(0.85)
                    .ignoresSafeArea()
                
                // Cutout circle in center
                Circle()
                    .fill(Color.clear)
                    .frame(width: 200, height: 200)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 50)
                    .blendMode(.destinationOut)
                
                // Pulsing ring around the spotlight
                Circle()
                    .stroke(Color.brandPrimary.opacity(0.6), lineWidth: 4)
                    .frame(width: 200 * pulseScale, height: 200 * pulseScale)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 50)
            }
            .compositingGroup()
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Spotlight for Add Button
    private var addButtonSpotlight: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.85)
                    .ignoresSafeArea()
                
                // Cutout circle for + button (bottom right)
                Circle()
                    .fill(Color.clear)
                    .frame(width: 120, height: 120)
                    .position(x: geometry.size.width - 80, y: geometry.size.height - 150)
                    .blendMode(.destinationOut)
                
                // Pulsing ring
                Circle()
                    .stroke(Color.brandAccent.opacity(0.6), lineWidth: 4)
                    .frame(width: 120 * pulseScale, height: 120 * pulseScale)
                    .position(x: geometry.size.width - 80, y: geometry.size.height - 150)
            }
            .compositingGroup()
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Professional Tooltip
    private func tutorialTooltip(icon: String, title: String, subtitle: String, position: TooltipPosition) -> some View {
        VStack(spacing: 16) {
            // Icon with glow
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brandPrimary.opacity(0.3), Color.brandSecondary.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            
            // Text content
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
        )
        .padding(.horizontal, 40)
        .padding(position == .top ? .top : .bottom, position == .top ? 100 : 200)
    }
    
    enum TooltipPosition {
        case top, bottom
    }
    
    // MARK: - Animations
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
    }
    
    // MARK: - Tutorial Completion
    private func skipTutorial() {
        withAnimation(.easeOut(duration: 0.3)) {
            completeTutorial()
        }
    }
    
    private func completeTutorial() {
        tutorialManager.isActive = false
        hasSeenMapTutorial = true
        isShowing = false
    }
}

// MARK: - Tutorial Tracking Helper
class TutorialManager: ObservableObject {
    enum TutorialStep {
        case tapOnMap
        case tapAddEvent
        case completed
    }
    
    @Published var tutorialStep: TutorialStep = .tapOnMap
    @Published var isActive = false
    
    static let shared = TutorialManager()
    
    func mapPinTapped() {
        if tutorialStep == .tapOnMap && isActive {
            withAnimation {
                tutorialStep = .tapAddEvent
            }
        }
    }
    
    func addButtonTapped() {
        if tutorialStep == .tapAddEvent && isActive {
            withAnimation {
                tutorialStep = .completed
                isActive = false
            }
        }
    }
}

#Preview {
    InteractiveTutorial(isShowing: .constant(true))
}

