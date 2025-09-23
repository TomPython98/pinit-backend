import SwiftUI
import Foundation

@main
struct StudyConApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @StateObject private var accountManager:     UserAccountManager
    @StateObject private var chatManager = ChatManager()  // Global ChatManager
    @StateObject private var calendarManager: CalendarManager
    @StateObject private var notificationManager = NotificationManager.shared
    
    // Handle push notification registration
    @UIApplicationDelegateAdaptor(FibblingAppDelegate.self) private var appDelegate

    init() {
        print("📱 [StudyConApp] Initializing app...")
        
        // Create account manager
        let am = UserAccountManager()
        _accountManager = StateObject(wrappedValue: am)
        
        // Create calendar manager with the account manager
        _calendarManager = StateObject(wrappedValue: CalendarManager(accountManager: am))
        
        print("✅ [StudyConApp] Managers initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                ContentView()
                    .environmentObject(accountManager)
                    .environmentObject(calendarManager)
                    .environmentObject(chatManager)
                    .environmentObject(notificationManager)
                    .onAppear {
                        print("🔐 [StudyConApp] User logged in, showing ContentView")
                        
                        // When app appears while logged in, refresh calendar events
                        if let username = accountManager.currentUser, !username.isEmpty {
                            print("🔄 [StudyConApp] Setting up WebSocket connection for \(username)")
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
                        print("🔒 [StudyConApp] User not logged in, showing LoginView")
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
