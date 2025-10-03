import Foundation
import UserNotifications
import SwiftUI
import MapKit  // For CLLocationCoordinate2D

#if canImport(UIKit)
import UIKit
#endif

// We don't need a separate import for StudyEvent as it's defined in the app bundle
// StudyEvent is defined in StudyEvent.swift within the project's Models directory

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @Published var hasPermission = false
    @Published var lastNotificationPayload: [AnyHashable: Any]? = nil
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        checkPermission()
    }
    
    func requestPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.hasPermission = granted
                
                // Register for remote notifications on the main thread
                if granted {
                    #if os(iOS)
                    DispatchQueue.main.async {
                        #if targetEnvironment(simulator)
                        #else
                        UIApplication.shared.registerForRemoteNotifications()
                        #endif
                    }
                    #endif
                }
                
                if let error = error {
                }
            }
        }
    }
    
    func checkPermission() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // This method accepts a dictionary with event properties instead of a StudyEvent object
    // Use this method until direct StudyEvent imports are working
    func scheduleEventNotificationFromDict(
        eventId: UUID,
        title: String,
        startTime: Date,
        reminderMinutes: Int = 30
    ) {
        self.scheduleEventNotification(
            title: title,
            eventId: eventId,
            startTime: startTime,
            reminderMinutes: reminderMinutes
        )
    }
    
    // Schedule a local notification for an event
    // This is a simplified version - it will be implemented fully when the StudyEvent model is accessible
    func scheduleEventNotification(title: String, eventId: UUID, startTime: Date, reminderMinutes: Int = 30) {
        guard hasPermission else {
            return
        }
        
        // Create event reminder
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "Starting in \(reminderMinutes) minutes"
        content.sound = .default
        content.userInfo = ["eventId": eventId.uuidString]
        
        // Calculate trigger time (30 minutes before event start)
        let reminderTime = startTime.addingTimeInterval(-Double(reminderMinutes * 60))
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request and add to notification center
        let identifier = "event-reminder-\(eventId.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
            } else {
            }
        }
    }
    
    // Cancel a notification for a specific event
    func cancelEventNotification(for eventId: UUID) {
        let identifier = "event-reminder-\(eventId.uuidString)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // Handle incoming notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               willPresent notification: UNNotification, 
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even if app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification taps
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               didReceive response: UNNotificationResponse, 
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        lastNotificationPayload = userInfo
        
        // Handle navigation to event detail if eventId is present
        if let eventIdString = userInfo["eventId"] as? String,
           let eventId = UUID(uuidString: eventIdString) {
            // You can post a notification to notify ContentView to navigate to this event
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToEvent"), 
                                          object: nil,
                                          userInfo: ["eventId": eventId])
        }
        
        completionHandler()
    }
    
    // Parse and handle push notification payload
    func handlePushNotification(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        
        
        // Process different notification types
        switch type {
        case "event_invitation":
            if let eventId = userInfo["event_id"] as? String, 
               let eventTitle = userInfo["event_title"] as? String {
                createLocalNotification(title: "New Event Invitation", 
                                     body: "You've been invited to \(eventTitle)",
                                     userInfo: ["eventId": eventId] as [AnyHashable: Any])
            }
            
        case "event_update":
            if let eventId = userInfo["event_id"] as? String,
               let eventTitle = userInfo["event_title"] as? String {
                createLocalNotification(title: "Event Updated", 
                                     body: "\(eventTitle) has been updated",
                                     userInfo: ["eventId": eventId] as [AnyHashable: Any])
                
                // Also handle RSVP updates by posting a notification that views can listen for
                if let eventUUID = UUID(uuidString: eventId) {
                    handleEventRSVPUpdate(eventID: eventUUID)
                }
            }
            
        case "event_cancellation":
            if let eventTitle = userInfo["event_title"] as? String {
                createLocalNotification(title: "Event Cancelled", 
                                     body: "\(eventTitle) has been cancelled",
                                     userInfo: userInfo)
            }
            
        case "new_attendee":
            if let eventTitle = userInfo["event_title"] as? String,
               let attendeeName = userInfo["attendee_name"] as? String {
                createLocalNotification(title: "New Attendee", 
                                     body: "\(attendeeName) joined your event: \(eventTitle)",
                                     userInfo: userInfo)
            }
            
        case "auto_match":
            if let eventTitle = userInfo["event_title"] as? String {
                createLocalNotification(title: "New Auto Match", 
                                     body: "Your event \(eventTitle) was matched with similar interests",
                                     userInfo: userInfo)
            }
            
        // New reputation-related notification types
        case "new_rating":
            handleNewRatingNotification(userInfo: userInfo)
            
        case "trust_level_change":
            handleTrustLevelChange(userInfo: userInfo)
            
        case "rate_reminder":
            if let eventId = userInfo["event_id"] as? String,
               let eventTitle = userInfo["event_title"] as? String,
               let hostName = userInfo["host_name"] as? String,
               let eventUUID = UUID(uuidString: eventId) {
                schedulePostEventRatingReminder(eventId: eventUUID, hostName: hostName, eventTitle: eventTitle)
            }
            
        case "event_rating_reminder":
            if let eventId = userInfo["event_id"] as? String,
               let eventTitle = userInfo["event_title"] as? String {
                // Post notification for ContentView to navigate to rate attendees view
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowEventRatingView"),
                    object: nil,
                    userInfo: [
                        "event_id": eventId,
                        "event_title": eventTitle,
                        "attendees": userInfo["attendees"] as? [String] ?? []
                    ]
                )
                
                // Also show a local notification if the app isn't in foreground
                createLocalNotification(
                    title: "Rate Event Attendees",
                    body: "How was your experience with attendees at \"\(eventTitle)\"?",
                    userInfo: userInfo
                )
            }
            
        default:
            break
        }
    }
    
    // Create and present a local notification immediately
    private func createLocalNotification(title: String, body: String, userInfo: [AnyHashable: Any]) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        
        // Create request with immediate trigger
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
            }
        }
    }
    
    // Handle WebSocket event updates for RSVPs
    func handleEventRSVPUpdate(eventID: UUID) {
        
        // Post notification for other components to listen for
        NotificationCenter.default.post(
            name: NSNotification.Name("EventRSVPStatusChanged"),
            object: nil,
            userInfo: ["eventID": eventID]
        )
        
        // This notification can be listened for in CalendarManager to update event status
        // without requiring a full refresh from the API
    }
    
    // MARK: - User Reputation Notifications
    
    // Handle receiving a new rating notification
    func handleNewRatingNotification(userInfo: [AnyHashable: Any]) {
        guard let fromUser = userInfo["from_user"] as? String,
              let rating = userInfo["rating"] as? Int else {
            return
        }
        
        let message = "You received a \(rating)-star rating from \(fromUser)"
        createLocalNotification(
            title: "New Rating Received",
            body: message,
            userInfo: userInfo
        )
        
        // Post notification for other components to listen for
        NotificationCenter.default.post(
            name: NSNotification.Name("UserRatingReceived"),
            object: nil,
            userInfo: userInfo
        )
        
    }
    
    // Handle trust level change notification
    func handleTrustLevelChange(userInfo: [AnyHashable: Any]) {
        guard let newLevel = userInfo["trust_level"] as? Int,
              let levelTitle = userInfo["level_title"] as? String else {
            return
        }
        
        let message = "Congratulations! You've reached the \(levelTitle) level"
        createLocalNotification(
            title: "Trust Level Increased",
            body: message,
            userInfo: userInfo
        )
        
        // Post notification for other components to listen for
        NotificationCenter.default.post(
            name: NSNotification.Name("UserTrustLevelChanged"),
            object: nil,
            userInfo: userInfo
        )
        
    }
    
    // Remind user to rate an event host after event completion
    func schedulePostEventRatingReminder(eventId: UUID, hostName: String, eventTitle: String) {
        guard hasPermission else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "How was your event?"
        content.body = "Rate \(hostName)'s event: \(eventTitle)"
        content.sound = .default
        content.userInfo = [
            "type": "rate_host_reminder",
            "event_id": eventId.uuidString,
            "host_name": hostName,
            "event_title": eventTitle
        ]
        
        // Schedule for 15 minutes after now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15 * 60, repeats: false)
        
        // Create request with unique identifier
        let identifier = "rate-host-\(eventId.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
            } else {
            }
        }
    }
    
    // Schedule a notification to remind users to rate event attendees
    func scheduleEventRatingReminder(eventId: UUID, eventTitle: String, attendees: [String]) {
        guard hasPermission, !attendees.isEmpty else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Rate Event Attendees"
        content.body = "How was your experience with attendees at \"\(eventTitle)\"?"
        content.sound = .default
        content.userInfo = [
            "type": "event_rating_reminder",
            "event_id": eventId.uuidString,
            "event_title": eventTitle,
            "attendees": attendees
        ]
        
        // Schedule for 15 minutes after now (typically called when event ends)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15 * 60, repeats: false)
        
        // Create request with unique identifier
        let identifier = "rate-attendees-\(eventId.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
            } else {
            }
        }
    }
} 
