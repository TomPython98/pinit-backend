import SwiftUI

// MARK: - Interactive Tutorial Overlay
struct InteractiveTutorial: View {
    @AppStorage("hasSeenMapTutorial") private var hasSeenMapTutorial = false
    @Binding var isShowing: Bool
    @ObservedObject var tutorialManager = TutorialManager.shared
    @State private var pulseScale: CGFloat = 1.0
    
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
            if currentStep == .openMap {
                // Spotlight on "View Full Map" card (middle of screen)
                mapCardSpotlight
            }
            // Other steps (tapOnPin, tapAddEvent) show on MapView itself
            
            // Tutorial content
            VStack {
                Spacer()
                
                if currentStep == .openMap {
                    tutorialTooltip(
                        icon: "map.fill",
                        title: "Open the map",
                        subtitle: "Tap 'View Full Map' to see events near you",
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
            if newStep == .tapOnPin {
                // User opened map - hide ContentView tutorial
                withAnimation {
                    isShowing = false
                }
            } else if newStep == .completed {
                // Tutorial fully complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    completeTutorial()
                }
            }
        }
    }
    
    // MARK: - Spotlight for Map Card (on ContentView)
    private var mapCardSpotlight: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.85)
                    .ignoresSafeArea()
                
                // Cutout rectangle for map card (center of screen, below header)
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.clear)
                    .frame(width: geometry.size.width - 40, height: 220)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.35)
                    .blendMode(.destinationOut)
                
                // Pulsing border around the card
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.brandPrimary.opacity(0.8), lineWidth: 4)
                    .frame(width: (geometry.size.width - 40) * pulseScale, 
                           height: 220 * pulseScale)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.35)
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
        .padding(position == .top ? .top : .bottom, position == .top ? 80 : 180)
    }
    
    enum TooltipPosition {
        case top, bottom
    }
    
    // MARK: - Animations
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
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
        tutorialManager.tutorialStep = .completed
        hasSeenMapTutorial = true
        isShowing = false
    }
}

// MARK: - Map Tutorial Overlay (shows on MapView)
struct MapTutorialOverlay: View {
    @ObservedObject var tutorialManager = TutorialManager.shared
    @State private var pulseScale: CGFloat = 1.0
    
    var currentStep: TutorialManager.TutorialStep {
        tutorialManager.tutorialStep
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent overlay that doesn't block touches
                Color.clear
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                // Pulsing ring indicators (no black overlay, just hints)
                if currentStep == .tapOnPin {
                    // Pulsing circle in center
                    Circle()
                        .stroke(Color.brandPrimary, lineWidth: 4)
                        .frame(width: 220 * pulseScale, height: 220 * pulseScale)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 50)
                        .shadow(color: Color.brandPrimary.opacity(0.6), radius: 10)
                } else if currentStep == .tapAddEvent {
                    // Pulsing circle on + button
                    Circle()
                        .stroke(Color.brandAccent, lineWidth: 4)
                        .frame(width: 140 * pulseScale, height: 140 * pulseScale)
                        .position(x: geometry.size.width - 80, y: geometry.size.height - 150)
                        .shadow(color: Color.brandAccent.opacity(0.6), radius: 10)
                }
                
                // Tutorial tooltips
                VStack {
                    if currentStep == .tapOnPin {
                        tutorialTooltip(
                            icon: "map.fill",
                            title: "Tap on any pin",
                            subtitle: "See what events are happening near you",
                            position: .top
                        )
                        .padding(.top, 60)
                    } else if currentStep == .tapAddEvent {
                        Spacer()
                        tutorialTooltip(
                            icon: "plus.circle.fill",
                            title: "Create your own event",
                            subtitle: "Tap the + button to host an event",
                            position: .bottom
                        )
                        .padding(.bottom, 220)
                    }
                    
                    Spacer()
                    
                    // Skip button
                    Button(action: skipTutorial) {
                        HStack {
                            Text("Skip Tutorial")
                                .font(.subheadline.weight(.semibold))
                            Image(systemName: "xmark.circle.fill")
                                .font(.subheadline)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.6))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            startPulseAnimation()
        }
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
    
    private func skipTutorial() {
        tutorialManager.isActive = false
        tutorialManager.tutorialStep = .completed
    }
}

// MARK: - Tutorial Tracking Helper
class TutorialManager: ObservableObject {
    enum TutorialStep {
        case openMap        // Step 1: Open map from ContentView
        case tapOnPin       // Step 2: Tap a pin on the map
        case tapAddEvent    // Step 3: Tap + button
        case completed      // Done!
    }
    
    @Published var tutorialStep: TutorialStep = .openMap
    @Published var isActive = false
    
    static let shared = TutorialManager()
    
    func mapOpened() {
        // User navigated to map
        if tutorialStep == .openMap && isActive {
            withAnimation {
                tutorialStep = .tapOnPin
            }
        }
    }
    
    func mapPinTapped() {
        // User tapped a pin on map
        if tutorialStep == .tapOnPin && isActive {
            withAnimation {
                tutorialStep = .tapAddEvent
            }
        }
    }
    
    func addButtonTapped() {
        // User tapped add event button
        if tutorialStep == .tapAddEvent && isActive {
            withAnimation {
                tutorialStep = .completed
                isActive = false
            }
        }
    }
    
    func reset() {
        tutorialStep = .openMap
        isActive = false
    }
}

#Preview {
    InteractiveTutorial(isShowing: .constant(true))
}
