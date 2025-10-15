import Foundation
import UserNotifications

#if canImport(UIKit)
import UIKit
#endif

#if os(iOS) || os(visionOS)
// iOS or visionOS specific AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    // Base server URL - this should match what's used in the rest of the app
    private let serverBaseURL = APIConfig.serverBaseURL
    
    func application(_ application: UIApplication, 
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Register as notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // Called when a device token is available for push notifications
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        // Send the token to your server
        sendTokenToServer(token: tokenString)
    }
    
    // Called if registration for remote notifications fails
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
    
    // Process incoming push notifications
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // Pass to notification manager for processing
        NotificationManager.shared.handlePushNotification(userInfo: userInfo)
        
        completionHandler(.newData)
    }
    
    // UNUserNotificationCenterDelegate methods for handling notifications in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              willPresent notification: UNNotification, 
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Let the NotificationManager handle it
        NotificationManager.shared.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
    }
    
    // Handle notification actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              didReceive response: UNNotificationResponse, 
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        // Let the NotificationManager handle it
        NotificationManager.shared.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }
    
    // Send device token to your Django server
    private func sendTokenToServer(token: String) {
        // Check if user is logged in
        guard let username = UserAccountManager.shared.currentUser, !username.isEmpty else {
            print("⚠️ Cannot register device: No user logged in")
            return
        }
        
        // Get JWT token from UserAccountManager
        guard let jwtToken = UserAccountManager.shared.jwtToken, !jwtToken.isEmpty else {
            print("⚠️ Cannot register device: No JWT token available")
            return
        }
        
        // Use the constant base URL
        let url = URL(string: "\(serverBaseURL)/api/register-device/")!
        
        // Create request body - only need device token and type
        let body: [String: Any] = [
            "device_token": token,
            "device_type": "ios"
        ]
        
        // Convert body to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            print("❌ Failed to serialize device registration JSON")
            return
        }
        
        // Create and configure request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        
        print("📱 Registering device token with server...")
        
        // Send request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Device registration network error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    print("✅ Device token registered successfully for user: \(username)")
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("📱 Server response: \(responseString)")
                    }
                } else {
                    print("❌ Device registration failed with status: \(httpResponse.statusCode)")
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("❌ Error response: \(responseString)")
                    }
                }
            }
        }.resume()
    }
}
#endif 