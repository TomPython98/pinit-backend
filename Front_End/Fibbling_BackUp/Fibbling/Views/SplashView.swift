import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Beautiful gradient background matching login
            LinearGradient(
                colors: [Color.gradientStart.opacity(0.2), Color.gradientEnd.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Animated Logo
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .shadow(color: Color.cardShadow.opacity(0.4), radius: 20, x: 0, y: 10)
                    .scaleEffect(isAnimating ? 1.0 : 0.6)
                    .opacity(isAnimating ? 1.0 : 0.3)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: isAnimating)
                
                // App Name
                Text("PinIt")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .tracking(1.0)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: isAnimating)
                
                // Tagline
                Text("Connect. Study. Grow.")
                    .font(.headline)
                    .foregroundColor(.textSecondary)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(0.5), value: isAnimating)
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .brandPrimary))
                    .scaleEffect(1.2)
                    .padding(.top, 20)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(0.7), value: isAnimating)
            }
        }
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }
}

#Preview {
    SplashView()
}

