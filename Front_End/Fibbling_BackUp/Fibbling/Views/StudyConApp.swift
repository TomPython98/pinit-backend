import SwiftUI
import Foundation

@main
struct PinItApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var accountManager:     UserAccountManager
    @StateObject private var chatManager = ChatManager()  // Global ChatManager
    @StateObject private var calendarManager: CalendarManager
    @StateObject private var notificationManager = NotificationManager.shared
    
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
                OnboardingView()
            } else if isLoggedIn {
                ContentView()
                    .environmentObject(accountManager)
                    .environmentObject(calendarManager)
                    .environmentObject(chatManager)
                    .environmentObject(notificationManager)
                    .onAppear {
                        
                        // Initialize ImageManager with account manager for JWT authentication
                        ImageManager.shared.setAccountManager(accountManager)
                        
                        // When app appears while logged in, refresh calendar events
                        if let username = accountManager.currentUser, !username.isEmpty {
                            // calendarManager.fetchEvents() // Removed - WebSocket will handle updates
                            
                            // Request notification permission
                            notificationManager.requestPermission()
                        }
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
