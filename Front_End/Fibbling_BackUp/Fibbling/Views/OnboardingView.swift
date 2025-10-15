import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Clean white background for readability
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(.textSecondary)
                    .padding()
                }
                
                // Content
                TabView(selection: $currentPage) {
                    // Page 1: Welcome
                    OnboardingPage(
                        image: "AppLogo",
                        isLogo: true,
                        title: "Welcome to PinIt",
                        subtitle: "Stop Scrolling. Start Living.",
                        description: "Connect with people near you and make real memories",
                        accentColor: .brandPrimary
                    )
                    .tag(0)
                    
                    // Page 2: Discover
                    OnboardingPage(
                        systemImage: "map.fill",
                        title: "Discover Events",
                        subtitle: "Find what's happening nearby",
                        description: "Study groups, social meetups, networking events—all on one map",
                        accentColor: .brandSecondary
                    )
                    .tag(1)
                    
                    // Page 3: Connect
                    OnboardingPage(
                        systemImage: "person.2.fill",
                        title: "Make Real Friends",
                        subtitle: "No more doom scrolling",
                        description: "Meet people in person, build genuine connections, create memories",
                        accentColor: .brandAccent
                    )
                    .tag(2)
                    
                    // Page 4: Get Started
                    OnboardingPage(
                        systemImage: "sparkles",
                        title: "Ready to Start?",
                        subtitle: "Your next adventure awaits",
                        description: "Make real connections and create memories near you",
                        accentColor: .brandPrimary,
                        isLastPage: true,
                        onGetStarted: completeOnboarding
                    )
                    .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(currentPage == index ? Color.brandPrimary : Color.brandPrimary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.6)) {
                isAnimating = true
            }
        }
    }
    
    private func completeOnboarding() {
        withAnimation(.spring()) {
            hasCompletedOnboarding = true
            onComplete()
        }
    }
}

// MARK: - Onboarding Page Component
struct OnboardingPage: View {
    var systemImage: String = ""
    var image: String = ""
    var isLogo: Bool = false
    var title: String
    var subtitle: String
    var description: String
    var accentColor: Color
    var isLastPage: Bool = false
    var onGetStarted: (() -> Void)? = nil
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Image/Icon
            Group {
                if isLogo {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .shadow(color: accentColor.opacity(0.3), radius: 20, x: 0, y: 10)
                } else {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.1))
                            .frame(width: 140, height: 140)
                        
                        Image(systemName: systemImage)
                            .font(.system(size: 60))
                            .foregroundColor(accentColor)
                    }
                }
            }
            .scaleEffect(isAnimating ? 1.0 : 0.6)
            .opacity(isAnimating ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isAnimating)
            
            Spacer().frame(height: 20)
            
            // Content
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: isAnimating)
                
                Text(subtitle)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(accentColor)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: isAnimating)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: isAnimating)
            }
            
            Spacer()
            
            // Get Started button (last page only)
            if isLastPage, let action = onGetStarted {
                Button(action: action) {
                    HStack(spacing: 12) {
                        Text("Get Started")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [.brandPrimary, .brandSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 40)
                .opacity(isAnimating ? 1.0 : 0.0)
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: isAnimating)
            }
            
            Spacer().frame(height: 40)
        }
        .padding()
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
        .onDisappear {
            isAnimating = false
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
