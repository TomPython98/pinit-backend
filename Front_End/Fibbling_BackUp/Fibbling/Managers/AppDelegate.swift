import Foundation
import UserNotifications

#if canImport(UIKit)
import UIKit
#endif

#if os(iOS) || os(visionOS)
// iOS or visionOS specific AppDelegate
class FibblingAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    // Base server URL - this should match what's used in the rest of the app
    private let serverBaseURL = "http://127.0.0.1:8000"
    
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
        print("📲 [AppDelegate] Device token: \(tokenString)")
        
        // Send the token to your server
        sendTokenToServer(token: tokenString)
    }
    
    // Called if registration for remote notifications fails
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ [AppDelegate] Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // Process incoming push notifications
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("📩 [AppDelegate] Received remote notification: \(userInfo)")
        
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
        guard let username = UserAccountManager.shared.currentUser, !username.isEmpty else {
            print("⚠️ [AppDelegate] No username available, can't register device token")
            return
        }
        
        // Use the constant base URL
        let url = URL(string: "\(serverBaseURL)/api/register-device/")!
        
        // Create request body
        let body: [String: Any] = [
            "username": username,
            "device_token": token,
            "device_type": "ios"
        ]
        
        // Convert body to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            print("❌ [AppDelegate] Failed to serialize JSON")
            return
        }
        
        // Create and configure request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // No auth token needed for this request
        
        // Send request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [AppDelegate] Error sending device token: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    print("✅ [AppDelegate] Device token registered successfully")
                } else {
                    print("⚠️ [AppDelegate] Server returned status code: \(httpResponse.statusCode)")
                    
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("📄 [AppDelegate] Response: \(responseString)")
                    }
                }
            }
        }.resume()
    }
}
#endif 