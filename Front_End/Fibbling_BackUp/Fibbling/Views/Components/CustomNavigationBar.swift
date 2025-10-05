import SwiftUI

struct CustomNavigationBar: View {
    var title: String
    var showBackButton: Bool = true
    var trailingContent: AnyView? = nil
    var onBackPressed: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            if showBackButton {
                Button(action: {
                    onBackPressed?()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                        .padding(8)
                        .background(Color.bgCard)
                        .cornerRadius(8)
                        .shadow(color: Color.cardShadow, radius: 2, x: 0, y: 1)
                }
            }
            
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(1)
            
            Spacer()
            
            if let trailingContent = trailingContent {
                trailingContent
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color.bgCard.opacity(0.95))
                .shadow(color: Color.cardShadow, radius: 3, x: 0, y: 1)
                .edgesIgnoringSafeArea(.top)
        )
    }
}

// Extension for easy creation of trailing content
extension CustomNavigationBar {
    // Helper for creating a button with an icon
    static func iconButton(icon: String, action: @escaping () -> Void) -> AnyView {
        AnyView(
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
        )
    }
    
    // Helper for creating multiple buttons
    static func multipleButtons(buttons: [AnyView]) -> AnyView {
        AnyView(
            HStack(spacing: 12) {
                ForEach(0..<buttons.count, id: \.self) { index in
                    buttons[index]
                }
            }
        )
    }
}

#Preview {
    VStack(spacing: 30) {
        // Simple navigation bar with back button
        CustomNavigationBar(
            title: "Event Details",
            onBackPressed: { }
        )
        
        // Navigation bar with trailing content
        CustomNavigationBar(
            title: "Messages",
            trailingContent: CustomNavigationBar.iconButton(
                icon: "plus",
                action: { }
            ),
            onBackPressed: { }
        )
        
        // Navigation bar with multiple trailing buttons
        CustomNavigationBar(
            title: "Calendar",
            trailingContent: CustomNavigationBar.multipleButtons(
                buttons: [
                    CustomNavigationBar.iconButton(icon: "magnifyingglass", action: { }),
                    CustomNavigationBar.iconButton(icon: "slider.horizontal.3", action: { })
                ]
            ),
            onBackPressed: { }
        )
    }
    .background(Color.gray.opacity(0.1))
    .ignoresSafeArea(.container, edges: .top)
} 