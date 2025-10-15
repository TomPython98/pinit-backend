import SwiftUI

struct MapTutorialOverlay: View {
    @AppStorage("hasSeenMapTutorial") private var hasSeenMapTutorial = false
    @Binding var isShowing: Bool
    @State private var currentStep = 0
    @State private var arrowOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Semi-transparent black background
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    nextStep()
                }
            
            VStack {
                Spacer()
                
                // Tutorial content based on current step
                if currentStep == 0 {
                    // Step 1: Point to map
                    VStack(spacing: 20) {
                        Spacer().frame(height: 100)
                        
                        // Animated arrow pointing down to map
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .offset(y: arrowOffset)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                    arrowOffset = 20
                                }
                            }
                        
                        Text("Tap on pins to see events")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Text("Each pin is a real event near you")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                } else if currentStep == 1 {
                    // Step 2: Point to bottom tabs
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Text("Explore your tools")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Text("Events, Friends, Invites & more")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        // Animated arrow pointing up to tabs
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .offset(y: -arrowOffset)
                        
                        Spacer().frame(height: 200)
                    }
                } else if currentStep == 2 {
                    // Step 3: Create events
                    VStack(spacing: 30) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.brandPrimary)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 100, height: 100)
                            )
                            .scaleEffect(1.0 + abs(sin(arrowOffset / 10)) * 0.1)
                        
                        Text("Create Your Own Events")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Text("Tap the + button to host events")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        // Get Started button
                        Button(action: {
                            completeRTutorial()
                        }) {
                            HStack(spacing: 12) {
                                Text("Got It!")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                            }
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.white.opacity(0.3), radius: 12, x: 0, y: 6)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                    }
                }
                
                Spacer()
                
                // Step indicator & skip button
                VStack(spacing: 16) {
                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(currentStep == index ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentStep == index ? 1.3 : 1.0)
                        }
                    }
                    
                    // Tap to continue or skip
                    if currentStep < 2 {
                        VStack(spacing: 8) {
                            Text("Tap anywhere to continue")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Button("Skip Tutorial") {
                                completeRTutorial()
                            }
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func nextStep() {
        if currentStep < 2 {
            withAnimation(.spring()) {
                currentStep += 1
            }
        }
    }
    
    private func completeRTutorial() {
        withAnimation(.easeOut) {
            hasSeenMapTutorial = true
            isShowing = false
        }
    }
}

#Preview {
    MapTutorialOverlay(isShowing: .constant(true))
}

