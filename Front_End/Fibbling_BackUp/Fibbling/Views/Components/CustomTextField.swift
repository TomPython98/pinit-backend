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
                    .foregroundColor(.blue)
                    .frame(width: 22)
            }
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
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
    .background(Color.gray.opacity(0.1))
} 