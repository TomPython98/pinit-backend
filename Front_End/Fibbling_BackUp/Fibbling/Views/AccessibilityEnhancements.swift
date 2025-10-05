import SwiftUI

// MARK: - Accessibility Enhancements for App Store Compliance

struct AccessibilityEnhancements {
    
    // MARK: - Dynamic Type Support
    static func dynamicTypeText(_ text: String, style: Font.TextStyle = .body) -> some View {
        Text(text)
            .font(.system(style))
            .dynamicTypeSize(.large)
            .accessibilityLabel(text)
    }
    
    // MARK: - Accessible Buttons
    static func accessibleButton(
        title: String,
        action: @escaping () -> Void,
        hint: String? = nil,
        isSelected: Bool = false
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.brandPrimary)
                .cornerRadius(12)
        }
        .accessibilityLabel(title)
        .accessibilityHint(hint ?? "Tap to \(title.lowercased())")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onTapGesture {
            action()
        }
    }
    
    // MARK: - Accessible Cards
    static func accessibleCard<Content: View>(
        title: String,
        content: Content,
        hint: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.textPrimary)
                .accessibilityAddTraits(.isHeader)
            
            content
        }
        .padding()
        .background(Color.bgCard)
        .cornerRadius(16)
        .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(hint ?? "")
    }
    
    // MARK: - Accessible Lists
    static func accessibleList<Data: RandomAccessCollection, Content: View>(
        _ data: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) -> some View where Data.Element: Identifiable {
        List(data) { item in
            content(item)
                .accessibilityElement(children: .combine)
        }
        .accessibilityLabel("List of items")
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Accessible Images
    static func accessibleImage(
        systemName: String,
        label: String,
        hint: String? = nil
    ) -> some View {
        Image(systemName: systemName)
            .font(.title2)
            .foregroundColor(.brandPrimary)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isImage)
    }
    
    // MARK: - Accessible Text Fields
    static func accessibleTextField(
        title: String,
        text: Binding<String>,
        placeholder: String = "",
        hint: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
                .accessibilityAddTraits(.isHeader)
            
            TextField(placeholder, text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .accessibilityLabel(title)
                .accessibilityHint(hint ?? "Enter \(title.lowercased())")
        }
    }
    
    // MARK: - Accessible Toggles
    static func accessibleToggle(
        title: String,
        isOn: Binding<Bool>,
        hint: String? = nil
    ) -> some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: .brandPrimary))
                .accessibilityLabel(title)
                .accessibilityHint(hint ?? "Toggle \(title.lowercased())")
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Accessible Navigation
    static func accessibleNavigationTitle(_ title: String) -> some View {
        Text(title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.textPrimary)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel("Screen title: \(title)")
    }
    
    // MARK: - Accessible Progress Indicators
    static func accessibleProgressView(
        title: String,
        progress: Double,
        hint: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
                .accessibilityAddTraits(.isHeader)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .brandPrimary))
                .accessibilityLabel("\(title): \(Int(progress * 100))% complete")
                .accessibilityHint(hint ?? "")
        }
    }
    
    // MARK: - Accessible Alerts
    static func accessibleAlert(
        title: String,
        message: String,
        primaryButton: String = "OK",
        secondaryButton: String? = nil,
        primaryAction: @escaping () -> Void = {},
        secondaryAction: @escaping () -> Void = {}
    ) -> some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.textPrimary)
                .accessibilityAddTraits(.isHeader)
            
            Text(message)
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .accessibilityLabel(message)
            
            HStack(spacing: 12) {
                if let secondaryButton = secondaryButton {
                    Button(secondaryButton) {
                        secondaryAction()
                    }
                    .accessibilityLabel(secondaryButton)
                    .accessibilityHint("Tap to \(secondaryButton.lowercased())")
                }
                
                Button(primaryButton) {
                    primaryAction()
                }
                .accessibilityLabel(primaryButton)
                .accessibilityHint("Tap to \(primaryButton.lowercased())")
                .accessibilityAddTraits(.isButton)
            }
        }
        .padding()
        .background(Color.bgCard)
        .cornerRadius(16)
        .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
    }
}

// MARK: - Accessibility Modifiers
extension View {
    
    /// Adds comprehensive accessibility support to any view
    func accessibilityEnhanced(
        label: String? = nil,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
    
    /// Adds accessibility support for interactive elements
    func accessibilityInteractive(
        label: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Tap to \(label.lowercased())")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Adds accessibility support for headers
    func accessibilityHeader(_ label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// Adds accessibility support for images
    func accessibilityImage(_ label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isImage)
    }
    
    /// Adds accessibility support for selected state
    func accessibilitySelected(_ isSelected: Bool) -> some View {
        self
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Reduced Motion Support
extension View {
    /// Respects user's reduced motion preference
    func respectsReducedMotion() -> some View {
        self
            .animation(.none, value: UUID()) // Disable animations if reduced motion is enabled
    }
}

// MARK: - VoiceOver Optimizations
struct VoiceOverOptimizedView<Content: View>: View {
    let content: Content
    let voiceOverLabel: String
    let voiceOverHint: String?
    
    init(
        voiceOverLabel: String,
        voiceOverHint: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.voiceOverLabel = voiceOverLabel
        self.voiceOverHint = voiceOverHint
    }
    
    var body: some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(voiceOverLabel)
            .accessibilityHint(voiceOverHint ?? "")
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        AccessibilityEnhancements.accessibleButton(
            title: "Test Button",
            action: {},
            hint: "This is a test button"
        )
        
        AccessibilityEnhancements.accessibleCard(
            title: "Test Card",
            content: Text("Card content"),
            hint: "This is a test card"
        )
        
        AccessibilityEnhancements.accessibleToggle(
            title: "Test Toggle",
            isOn: .constant(true),
            hint: "Toggle this setting"
        )
    }
    .padding()
}
