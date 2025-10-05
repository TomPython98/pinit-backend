import SwiftUI

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.brandPrimary)
                    .frame(width: 22)
            }
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cardStroke, lineWidth: 1)
        )
        .foregroundColor(Color.textPrimary)
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomTextField(
            placeholder: "Email",
            text: .constant(""),
            icon: "envelope"
        )
        
        CustomTextField(
            placeholder: "Password",
            text: .constant("password123"),
            icon: "lock",
            isSecure: true
        )
    }
    .padding()
    .background(Color.bgSurface)
} 