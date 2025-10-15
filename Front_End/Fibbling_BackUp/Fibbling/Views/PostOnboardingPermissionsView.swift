import SwiftUI

struct PostOnboardingPermissionsView: View {
    @ObservedObject var notificationManager: NotificationManager
    @ObservedObject var locationManager: LocationManager
    var onComplete: () -> Void
    
    @State private var currentStep: Int = 0 // 0 = notifications, 1 = location, 2 = complete
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.bgSurface.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 4) {
                    ForEach(0..<2) { index in
                        Capsule()
                            .fill(index <= currentStep ? Color.brandPrimary : Color.brandPrimary.opacity(0.2))
                            .frame(height: 4)
                            .scaleEffect(index == currentStep ? 1.1 : 1.0, anchor: .center)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .padding(.bottom, 24)
                
                // Content
                VStack(spacing: 32) {
                    Spacer()
                    
                    if currentStep == 0 {
                        // Notification permissions
                        permissionStepView(
                            icon: "bell.badge.fill",
                            iconColor: Color.brandPrimary,
                            title: "Stay Updated",
                            subtitle: "Get Notified About Events",
                            description: "Never miss invitations, event updates, or messages from your friends",
                            primaryButtonText: "Enable Notifications",
                            secondaryButtonText: "Not Now",
                            onPrimary: requestNotifications,
                            onSecondary: skipNotifications
                        )
                    } else if currentStep == 1 {
                        // Location permissions
                        permissionStepView(
                            icon: "location.fill",
                            iconColor: Color.brandSecondary,
                            title: "Find Nearby Events",
                            subtitle: "Discover What's Around You",
                            description: "We'll help you find events and people near your location",
                            primaryButtonText: "Enable Location",
                            secondaryButtonText: "Not Now",
                            onPrimary: requestLocation,
                            onSecondary: skipLocation
                        )
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.6)) {
                isAnimating = true
            }
        }
    }
    
    private func permissionStepView(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        description: String,
        primaryButtonText: String,
        secondaryButtonText: String,
        onPrimary: @escaping () -> Void,
        onSecondary: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundColor(iconColor)
            }
            .scaleEffect(isAnimating ? 1.0 : 0.6)
            .opacity(isAnimating ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isAnimating)
            
            // Text
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.headline)
                    .foregroundColor(iconColor)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            .opacity(isAnimating ? 1.0 : 0.0)
            .offset(y: isAnimating ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.2), value: isAnimating)
            
            // Buttons
            VStack(spacing: 12) {
                Button(action: onPrimary) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(primaryButtonText)
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [iconColor, iconColor.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    )
                }
                
                Button(action: onSecondary) {
                    Text(secondaryButtonText)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cardStroke, lineWidth: 1)
                        )
                }
            }
            .opacity(isAnimating ? 1.0 : 0.0)
            .scaleEffect(isAnimating ? 1.0 : 0.8, anchor: .center)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: isAnimating)
        }
    }
    
    private func requestNotifications() {
        notificationManager.requestPermission()
        // Move to next step after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.4)) {
                isAnimating = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentStep = 1
                isAnimating = true
            }
        }
    }
    
    private func skipNotifications() {
        // Move to next step
        withAnimation(.easeInOut(duration: 0.4)) {
            isAnimating = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            currentStep = 1
            isAnimating = true
        }
    }
    
    private func requestLocation() {
        locationManager.requestLocationPermission()
        // Complete after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                isAnimating = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onComplete()
            }
        }
    }
    
    private func skipLocation() {
        // Complete the flow
        withAnimation(.easeOut(duration: 0.3)) {
            isAnimating = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onComplete()
        }
    }
}

#Preview {
    PostOnboardingPermissionsView(
        notificationManager: NotificationManager.shared,
        locationManager: LocationManager(),
        onComplete: {}
    )
}
