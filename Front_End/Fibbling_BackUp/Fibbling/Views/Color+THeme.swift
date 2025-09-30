import SwiftUI

// MARK: - PinIt Color Theme System
extension Color {
    // MARK: - Primary Brand Colors
    static let pinItPrimary = Color(red: 0.2, green: 0.4, blue: 0.8)        // Deep Blue
    static let pinItSecondary = Color(red: 0.9, green: 0.3, blue: 0.2)      // Coral Red
    static let pinItAccent = Color(red: 0.1, green: 0.7, blue: 0.4)         // Emerald Green

    // MARK: - Neutral Colors
    static let pinItDark = Color(red: 0.1, green: 0.1, blue: 0.1)           // Almost Black
    static let pinItMedium = Color(red: 0.3, green: 0.3, blue: 0.3)         // Dark Gray
    static let pinItLight = Color(red: 0.95, green: 0.95, blue: 0.95)       // Light Gray
    static let pinItWhite = Color.white

    // MARK: - Status Colors
    static let pinItSuccess = Color(red: 0.1, green: 0.7, blue: 0.4)        // Green
    static let pinItWarning = Color(red: 1.0, green: 0.6, blue: 0.0)        // Orange
    static let pinItError = Color(red: 0.9, green: 0.2, blue: 0.2)          // Red
    static let pinItInfo = Color(red: 0.2, green: 0.5, blue: 0.9)           // Blue

    // MARK: - Background Colors
    static let pinItBackground = Color(red: 0.98, green: 0.98, blue: 0.99)  // Off White
    static let pinItCardBackground = Color.white
    static let pinItOverlay = Color.black.opacity(0.3)

    // MARK: - Text Colors
    static let pinItTextPrimary = Color(red: 0.1, green: 0.1, blue: 0.1)    // Dark Text
    static let pinItTextSecondary = Color(red: 0.4, green: 0.4, blue: 0.4)  // Medium Text
    static let pinItTextTertiary = Color(red: 0.6, green: 0.6, blue: 0.6)   // Light Text
    static let pinItTextInverse = Color.white

    // MARK: - Event Type Colors
    static let pinItStudy = Color(red: 0.2, green: 0.4, blue: 0.8)          // Blue
    static let pinItParty = Color(red: 0.8, green: 0.2, blue: 0.6)          // Pink
    static let pinItBusiness = Color(red: 0.1, green: 0.7, blue: 0.4)       // Green
    static let pinItCultural = Color(red: 1.0, green: 0.6, blue: 0.0)       // Orange
    static let pinItAcademic = Color(red: 0.4, green: 0.2, blue: 0.8)       // Purple
    static let pinItNetworking = Color(red: 0.9, green: 0.3, blue: 0.2)     // Coral
    static let pinItSocial = Color(red: 0.2, green: 0.6, blue: 0.8)         // Light Blue
    static let pinItLanguage = Color(red: 0.0, green: 0.7, blue: 0.7)       // Teal
    static let pinItOther = Color(red: 0.6, green: 0.6, blue: 0.6)          // Gray

    // MARK: - Gradient Colors
    static let pinItGradientStart = Color(red: 0.2, green: 0.4, blue: 0.8)
    static let pinItGradientEnd = Color(red: 0.1, green: 0.7, blue: 0.4)
    
    // MARK: - Legacy Support (for backward compatibility)
    // Note: socialPrimary, socialAccent, socialDark, socialMedium, socialLight are already defined in ContentView.swift
}

// MARK: - PinIt Theme Manager
class PinItTheme: ObservableObject {
    @Published var isDarkMode: Bool = false
    @Published var selectedAccentColor: PinItAccentColor = .blue
    @Published var fontSize: PinItFontSize = .medium

    enum PinItAccentColor: String, CaseIterable {
        case blue = "Blue"
        case green = "Green"
        case coral = "Coral"
        case purple = "Purple"

        var color: Color {
            switch self {
            case .blue: return .pinItPrimary
            case .green: return .pinItAccent
            case .coral: return .pinItSecondary
            case .purple: return .pinItAcademic
            }
        }
    }

    enum PinItFontSize: String, CaseIterable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"

        var scaleFactor: CGFloat {
            switch self {
            case .small: return 0.9
            case .medium: return 1.0
            case .large: return 1.1
            }
        }
    }

    var primaryColor: Color {
        selectedAccentColor.color
    }

    var backgroundColor: Color {
        isDarkMode ? .pinItDark : .pinItBackground
    }

    var cardBackgroundColor: Color {
        isDarkMode ? .pinItMedium : .pinItCardBackground
    }

    var textPrimaryColor: Color {
        isDarkMode ? .pinItTextInverse : .pinItTextPrimary
    }

    var textSecondaryColor: Color {
        isDarkMode ? .pinItTextTertiary : .pinItTextSecondary
    }
}

// MARK: - PinIt Style Modifiers
struct PinItCardStyle: ViewModifier {
    let isDarkMode: Bool

    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDarkMode ? Color.pinItMedium : Color.pinItCardBackground)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
    }
}

struct PinItButtonStyle: ViewModifier {
    let style: PinItButtonType
    let isDarkMode: Bool

    enum PinItButtonType {
        case primary
        case secondary
        case destructive
        case ghost
    }

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .pinItTextInverse
        case .secondary:
            return isDarkMode ? .pinItTextInverse : .pinItPrimary
        case .destructive:
            return .pinItTextInverse
        case .ghost:
            return isDarkMode ? .pinItTextInverse : .pinItPrimary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return .pinItPrimary
        case .secondary:
            return isDarkMode ? .pinItMedium : .pinItLight
        case .destructive:
            return .pinItError
        case .ghost:
            return .clear
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:
            return .clear
        case .secondary:
            return isDarkMode ? .pinItLight : .pinItPrimary
        case .destructive:
            return .clear
        case .ghost:
            return isDarkMode ? .pinItLight : .pinItPrimary
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .primary, .destructive:
            return 0
        case .secondary, .ghost:
            return 1
        }
    }
}

// MARK: - View Extensions
extension View {
    func pinItCard(isDarkMode: Bool = false) -> some View {
        modifier(PinItCardStyle(isDarkMode: isDarkMode))
    }

    func pinItButton(_ style: PinItButtonStyle.PinItButtonType, isDarkMode: Bool = false) -> some View {
        modifier(PinItButtonStyle(style: style, isDarkMode: isDarkMode))
    }
}

// MARK: - PinIt Icons
struct PinItIcons {
    static let pin = "mappin.circle.fill"
    static let event = "calendar.circle.fill"
    static let map = "map.fill"
    static let profile = "person.circle.fill"
    static let settings = "gearshape.fill"
    static let notification = "bell.fill"
    static let privacy = "lock.fill"
    static let help = "questionmark.circle.fill"
    static let logout = "arrow.right.circle.fill"
    static let delete = "trash.fill"
    static let edit = "pencil.circle.fill"
    static let add = "plus.circle.fill"
    static let checkmark = "checkmark.circle.fill"
    static let star = "star.fill"
    static let heart = "heart.fill"
    static let message = "message.fill"
    static let share = "square.and.arrow.up.fill"
    static let camera = "camera.fill"
    static let location = "location.fill"
    static let time = "clock.fill"
    static let people = "person.2.fill"
    static let tag = "tag.fill"
    static let filter = "line.3.horizontal.decrease.circle.fill"
    static let search = "magnifyingglass"
    static let refresh = "arrow.clockwise"
    static let close = "xmark.circle.fill"
    static let chevronRight = "chevron.right"
    static let chevronDown = "chevron.down"
    static let chevronUp = "chevron.up"
}
