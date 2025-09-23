import SwiftUI
import UserNotifications

struct DebugView: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        List {
            Section(header: Text("Push Notification Testing")) {
                // Request permission button
                Button("Request Notification Permission") {
                    notificationManager.requestPermission()
                }
                
                // Status indicator
                HStack {
                    Text("Permission Status:")
                    Spacer()
                    Text(notificationManager.hasPermission ? "Granted" : "Denied")
                        .foregroundColor(notificationManager.hasPermission ? .green : .red)
                }
                
                // Test local notification
                Button("Send Test Local Notification") {
                    let content = UNMutableNotificationContent()
                    content.title = "Test Notification"
                    content.body = "This is a test notification"
                    content.sound = .default
                    
                    let request = UNNotificationRequest(
                        identifier: UUID().uuidString,
                        content: content,
                        trigger: nil) // nil trigger means send immediately
                    
                    UNUserNotificationCenter.current().add(request)
                }
                
                // Simulate push notification with various types
                Section(header: Text("Simulate Push Notifications")) {
                    Button("Simulate Event Invitation") {
                        simulatePushNotification(type: "event_invitation")
                    }
                    
                    Button("Simulate Event Update") {
                        simulatePushNotification(type: "event_update")
                    }
                    
                    Button("Simulate Event Cancellation") {
                        simulatePushNotification(type: "event_cancellation")
                    }
                    
                    Button("Simulate Auto Match") {
                        simulatePushNotification(type: "auto_match")
                    }
                }
            }
        }
        .navigationTitle("Debug Tools")
    }
    
    func simulatePushNotification(type: String) {
        var userInfo: [AnyHashable: Any] = ["type": type]
        
        // Add additional info based on type
        switch type {
        case "event_invitation", "event_update":
            userInfo["event_id"] = UUID().uuidString
            userInfo["event_title"] = "Test Event"
            
        case "event_cancellation":
            userInfo["event_title"] = "Cancelled Event"
            
        case "new_attendee":
            userInfo["event_title"] = "Your Event"
            userInfo["attendee_name"] = "Test User"
            
        case "auto_match":
            userInfo["event_title"] = "Matched Event"
            
        default:
            break
        }
        
        // Process the notification through the manager
        NotificationManager.shared.handlePushNotification(userInfo: userInfo)
    }
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DebugView()
        }
    }
} 