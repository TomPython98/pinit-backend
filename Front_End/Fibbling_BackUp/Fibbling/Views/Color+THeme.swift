import SwiftUI

// MARK: - Professional PinIt Color Theme System
extension Color {
    // MARK: - Primary Brand Colors (Refined Professional Palette)
    static let pinItPrimary = Color(red: 79/255, green: 70/255, blue: 229/255)       // Indigo primary - professional
    static let pinItSecondary = Color(red: 59/255, green: 130/255, blue: 246/255)     // Royal blue - trustable
    static let pinItAccent = Color(red: 16/255, green: 185/255, blue: 129/255)        // Emerald success - modern
    
    // MARK: - Background Colors (Enhanced Professional Design)
    static let pinItBackground = Color(red: 248/255, green: 250/255, blue: 255/255)  // Light bg surface (clean)
    static let pinItCardBackground = Color.white                                        // Pure white cards
    static let pinItSecondaryBackground = Color(red: 242/255, green: 245/255, blue: 250/255)  // Subtle secondary
    static let pinItAccentBackground = Color(red: 240/255, green: 242/255, blue: 255/255)     // Light accent bg
    // Improved light colors with better contrast for various iPhone displays
    static let pinItLight = Color(red: 248/255, green: 250/255, blue: 255/255)             // Light bg for cards - same as background for consistency
    
    // MARK: - Text Colors (Optimal Contrast for Readability)
    static let pinItTextPrimary = Color(red: 15/255, green: 23/255, blue: 42/255)     // Near black - excellent readability
    static let pinItTextSecondary = Color(red: 71/255, green: 85/255, blue: 105/255)    // Slate 600 - readable
    static let pinItTextTertiary = Color(red: 100/255, green: 116/255, blue: 139/255)  // Slate 500 - supportive
    static let pinItTextInverse = Color.white                                          // White on dark
    
    // MARK: - Status Colors (Professional Vibrancy)
    static let pinItSuccess = Color(red: 16/255, green: 185/255, blue: 129/255)        // Emerald
    static let pinItWarning = Color(red: 245/255, green: 158/255, blue: 11/255)        // Amber
    static let pinItError = Color(red: 239/255, green: 68/255, blue: 68/255)           // Red
    static let pinItInfo = Color(red: 59/255, green: 130/255, blue: 246/255)           // Blue
    
    // MARK: - Special Colors for Dark Mode Support
    static let pinItDark = Color(red: 15/255, green: 23/255, blue: 42/255)             // Dark mode bg
    static let pinItDarkSecondary = Color(red: 30/255, green: 41/255, blue: 59/255)   // Dark mode secondary
    
    // MARK: - Additional UI Colors
    static let pinItMedium = Color(red: 30/255, green: 41/255, blue: 59/255)           // Medium bg for dark mode

    // MARK: - Event Type Colors (Professional Category System)
    static let pinItStudy = Color(red: 59/255, green: 130/255, blue: 246/255)          // Blue - Study
    static let pinItParty = Color(red: 236/255, green: 72/255, blue: 153/255)          // Pink - Party
    static let pinItBusiness = Color(red: 16/255, green: 185/255, blue: 129/255)        // Green - Business
    static let pinItCultural = Color(red: 245/255, green: 158/255, blue: 11/255)        // Orange - Cultural
    static let pinItAcademic = Color(red: 124/255, green: 58/255, blue: 237/255)       // Purple - Academic
    static let pinItNetworking = Color(red: 251/255, green: 146/255, blue: 60/255)      // Orange - Networking
    static let pinItSocial = Color(red: 34/255, green: 197/255, blue: 94/255)           // Green - Social
    static let pinItLanguage = Color(red: 20/255, green: 184/255, blue: 166/255)       // Teal - Language
    static let pinItOther = Color(red: 156/255, green: 163/255, blue: 175/255)         // Gray - Other

    // MARK: - UI Element Colors (Polish & Shadows)
    static let pinItDivider = Color(red: 226/255, green: 232/255, blue: 240/255)       // Subtle dividers
    static let pinItCardShadow = Color(red: 15/255, green: 23/255, blue: 42/255).opacity(0.08)  // Elegful shadows
    static let pinItCardStroke = Color(red: 226/255, green: 232/255, blue: 240/255)    // Clean borders
    static let pinItOverlay = Color.black.opacity(0.3)                                 // Modal overlays
    
    // MARK: - Legacy Support (Modernized Alias Colors)
    static let bgSurface = pinItBackground
    static let bgCard = pinItCardBackground
    static let bgSecondary = pinItSecondaryBackground
    static let bgAccent = pinItAccentBackground
    static let textPrimary = pinItTextPrimary
    static let textSecondary = pinItTextSecondary
    static let textLight = pinItTextInverse
    static let textMuted = Color(red: 148/255, green: 163/255, blue: 184/255)
    static let divider = pinItDivider
    static let cardShadow = pinItCardShadow
    static let cardStroke = pinItCardStroke
    static let brandPrimary = pinItPrimary
    static let brandSecondary = pinItSecondary
    static let brandAccent = Color(red: 236/255, green: 72/255, blue: 153/255)
    static let brandSuccess = pinItSuccess
    static let brandWarning = pinItWarning
    
    // Legacy social colors - now consistent
    static let socialPrimary = pinItSecondary
    static let socialMedium = Color(red: 59/255, green: 130/255, blue: 246/255)
    static let socialAccent = Color(red: 129/255, green: 176/255, blue: 250/255)
    static let socialDark = pinItTextPrimary
    static let socialLight = pinItAccentBackground
}

// MARK: - Enhanced PinIt Theme Manager
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
            case .coral: return .brandAccent
            case .purple: return Color(red: 124/255, green: 58/255, blue: 237/255)
            }
        }
        
        var displayName: String {
            switch self {
            case .blue: return "Professional Blue"
            case .green: return "Success Green"
            case .coral: return "Warm Coral"
            case .purple: return "Elegant Purple"
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
        
        var displayName: String {
            switch self {
            case .small: return "Compact"
            case .medium: return "Standard"
            case .large: return "Large"
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
        isDarkMode ? .pinItDarkSecondary : .pinItCardBackground
    }

    var textPrimaryColor: Color {
        isDarkMode ? .pinItTextInverse : .pinItTextPrimary
    }

    var textSecondaryColor: Color {
        isDarkMode ? .pinItTextTertiary : .pinItTextSecondary
    }
    
    // Additional computed properties for consistency
    var elevatedBackgroundColor: Color {
        isDarkMode ? .pinItDarkSecondary : .pinItCardBackground
    }
    
    var dividerColor: Color {
        isDarkMode ? .pinItTextTertiary : .pinItDivider
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
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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
            return Color.pinItTextInverse
        case .secondary:
            return isDarkMode ? Color.pinItTextInverse : Color.pinItPrimary
        case .destructive:
            return Color.pinItTextInverse
        case .ghost:
            return isDarkMode ? Color.pinItTextInverse : Color.pinItPrimary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return Color.pinItPrimary
        case .secondary:
            return isDarkMode ? Color.pinItMedium : Color.pinItLight
        case .destructive:
            return Color.pinItError
        case .ghost:
            return Color.clear
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:
            return Color.clear
        case .secondary:
            return isDarkMode ? Color.pinItLight : Color.pinItPrimary
        case .destructive:
            return Color.clear
        case .ghost:
            return isDarkMode ? Color.pinItLight : Color.pinItPrimary
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

// MARK: - Custom Stepper Style
struct PinItStepperStyle: ViewModifier {
    let isDarkMode: Bool

    func body(content: Content) -> some View {
        content
            .tint(Color.pinItPrimary) // Use custom primary color instead of system tint
    }
}

// MARK: - Enhanced Stepper Component
struct PinItStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int = 1
    let isDarkMode: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Minus button
            Button(action: {
                if value > range.lowerBound {
                    value -= step
                }
            }) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(value > range.lowerBound ? Color.pinItPrimary : Color.pinItTextSecondary)
                    .frame(width: 32, height: 32)
            }
            .disabled(value <= range.lowerBound)

            // Current value display
            Text("\(value)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.pinItTextPrimary)
                .frame(minWidth: 40, alignment: .center)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isDarkMode ? Color.pinItMedium : Color.pinItSecondaryBackground.opacity(0.6))
                        .stroke(Color.pinItPrimary.opacity(0.4), lineWidth: 1)
                )

            // Plus button
            Button(action: {
                if value < range.upperBound {
                    value += step
                }
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(value < range.upperBound ? Color.pinItPrimary : Color.pinItTextSecondary)
                    .frame(width: 32, height: 32)
            }
            .disabled(value >= range.upperBound)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDarkMode ? Color.pinItMedium : Color.pinItSecondaryBackground.opacity(0.4))
                .stroke(Color.pinItPrimary.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - View Extensions for Stepper
extension View {
    func pinItStepperStyle(isDarkMode: Bool = false) -> some View {
        modifier(PinItStepperStyle(isDarkMode: isDarkMode))
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
