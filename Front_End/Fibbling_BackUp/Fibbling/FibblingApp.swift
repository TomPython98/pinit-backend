import SwiftUI

// This file contains utility functions and extensions for the app
// Note: The main app entry point is in StudyConApp.swift

// MARK: - App Color Extensions
extension Color {
    // Primary brand colors
    static let appPrimary = Color.blue
    static let appSecondary = Color.indigo
    static let appAccent = Color.pink
    
    // Background colors
    static let appBackground = Color(.systemBackground)
    static let appSecondaryBackground = Color(.secondarySystemBackground)
    
    // Text colors
    static let appText = Color(.label)
    static let appSecondaryText = Color(.secondaryLabel)
}

// MARK: - App Sizing Constants
struct AppSizes {
    static let buttonHeight: CGFloat = 44
    static let cornerRadius: CGFloat = 8
    static let iconSize: CGFloat = 24
    static let spacing: CGFloat = 16
    static let padding: CGFloat = 20
}

// MARK: - App Animation Settings
struct AppAnimations {
    static let defaultAnimation = Animation.easeInOut(duration: 0.3)
    static let quickAnimation = Animation.easeOut(duration: 0.2)
    static let slowAnimation = Animation.easeInOut(duration: 0.5)
}
