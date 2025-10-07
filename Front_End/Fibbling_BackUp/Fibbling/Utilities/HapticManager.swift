import UIKit
import SwiftUI

// MARK: - Haptic Feedback Manager
/// Provides professional haptic feedback throughout the app

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Feedback
    
    /// Light impact for subtle interactions (e.g., button taps, switches)
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium impact for standard interactions (e.g., selections, toggles)
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Heavy impact for significant actions (e.g., delete, important confirmations)
    func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Soft impact for gentle feedback (iOS 13+)
    func soft() {
        if #available(iOS 13.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        } else {
            light()
        }
    }
    
    /// Rigid impact for firm feedback (iOS 13+)
    func rigid() {
        if #available(iOS 13.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()
        } else {
            medium()
        }
    }
    
    // MARK: - Notification Feedback
    
    /// Success feedback (e.g., upload complete, action successful)
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Warning feedback (e.g., validation error, caution needed)
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Error feedback (e.g., failed action, critical error)
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    
    /// Selection feedback for picker-like interactions
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - Contextual Feedback Methods
    
    /// Feedback for button press
    func buttonPress() {
        medium()
    }
    
    /// Feedback for toggle switch
    func toggleSwitch() {
        light()
    }
    
    /// Feedback for successful upload/save
    func uploadSuccess() {
        success()
    }
    
    /// Feedback for failed upload/save
    func uploadFailed() {
        error()
    }
    
    /// Feedback for sending a message
    func messageSent() {
        soft()
    }
    
    /// Feedback for receiving a notification
    func notification() {
        medium()
    }
    
    /// Feedback for pull-to-refresh
    func pullToRefresh() {
        light()
    }
    
    /// Feedback for long press
    func longPress() {
        heavy()
    }
    
    /// Feedback for swipe action
    func swipeAction() {
        medium()
    }
    
    /// Feedback for delete action
    func deleteAction() {
        heavy()
    }
    
    /// Feedback for adding to favorites
    func favorite() {
        rigid()
    }
}

// MARK: - SwiftUI View Extension
extension View {
    /// Add haptic feedback on tap
    func hapticFeedback(_ style: HapticStyle = .medium, onTap: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    switch style {
                    case .light:
                        HapticManager.shared.light()
                    case .medium:
                        HapticManager.shared.medium()
                    case .heavy:
                        HapticManager.shared.heavy()
                    case .soft:
                        HapticManager.shared.soft()
                    case .rigid:
                        HapticManager.shared.rigid()
                    case .selection:
                        HapticManager.shared.selection()
                    }
                    onTap()
                }
        )
    }
    
    /// Add haptic feedback on button press
    func hapticButton(_ style: HapticStyle = .medium) -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    switch style {
                    case .light:
                        HapticManager.shared.light()
                    case .medium:
                        HapticManager.shared.medium()
                    case .heavy:
                        HapticManager.shared.heavy()
                    case .soft:
                        HapticManager.shared.soft()
                    case .rigid:
                        HapticManager.shared.rigid()
                    case .selection:
                        HapticManager.shared.selection()
                    }
                }
        )
    }
}

// MARK: - Haptic Style Enum
enum HapticStyle {
    case light
    case medium
    case heavy
    case soft
    case rigid
    case selection
}

// MARK: - Usage Examples
/*
 // In your view:
 
 // Simple button with haptic
 Button("Tap Me") {
     print("Tapped!")
 }
 .hapticButton(.medium)
 
 // Custom action with specific feedback
 Button("Delete") {
     deleteItem()
 }
 .simultaneousGesture(TapGesture().onEnded { _ in
     HapticManager.shared.deleteAction()
 })
 
 // Toggle with haptic
 Toggle("Enable", isOn: $isEnabled)
     .onChange(of: isEnabled) { _ in
         HapticManager.shared.toggleSwitch()
     }
 
 // Success/Error feedback
 Task {
     let success = await uploadImage()
     if success {
         HapticManager.shared.uploadSuccess()
     } else {
         HapticManager.shared.uploadFailed()
     }
 }
 */

