import SwiftUI
import Foundation

@main
struct PinItApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasRequestedPermissions") private var hasRequestedPermissions = false
    @StateObject private var accountManager:     UserAccountManager
    @StateObject private var chatManager = ChatManager()  // Global ChatManager
    @StateObject private var calendarManager: CalendarManager
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var locationManager = LocationManager()  // Global LocationManager
    
    // Handle push notification registration
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        
        // Create account manager
        let am = UserAccountManager()
        _accountManager = StateObject(wrappedValue: am)
        
        // Create calendar manager with the account manager
        _calendarManager = StateObject(wrappedValue: CalendarManager(accountManager: am))
        
    }
    
    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                OnboardingView {
                    hasCompletedOnboarding = true
                    hasRequestedPermissions = false  // Reset so permissions are requested next
                }
                .environmentObject(accountManager)
            } else if !hasRequestedPermissions && isLoggedIn {
                // Show permissions request after onboarding
                PostOnboardingPermissionsView(
                    notificationManager: notificationManager,
                    locationManager: locationManager,
                    onComplete: {
                        hasRequestedPermissions = true
                    }
                )
            } else if isLoggedIn {
                ContentView()
                    .environmentObject(accountManager)
                    .environmentObject(calendarManager)
                    .environmentObject(chatManager)
                    .environmentObject(notificationManager)
                    .environmentObject(locationManager)
                    .onAppear {
                        // Initialize ImageManager with account manager for JWT authentication
                        ImageManager.shared.setAccountManager(accountManager)
                    }
            } else {
                LoginView()
                    .environmentObject(accountManager)
                    .environmentObject(chatManager)
                    .environmentObject(notificationManager)
                    .onAppear {
                        // Initialize ImageManager with account manager for JWT authentication
                        ImageManager.shared.setAccountManager(accountManager)
                    }
            }
        }
    }
}

// MARK: - UserAccountManager Singleton Extension
extension UserAccountManager {
    // Add a singleton instance for cases where we need it before SwiftUI creates the StateObject
    static let shared = UserAccountManager()
}
