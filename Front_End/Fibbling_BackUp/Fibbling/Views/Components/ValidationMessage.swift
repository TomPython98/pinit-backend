import SwiftUI

enum ValidationState {
    case valid
    case error
    case warning
    case info
    
    var icon: String {
        switch self {
        case .valid: return "checkmark.circle.fill"
        case .error: return "exclamationmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .valid: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

struct ValidationMessage: View {
    let message: String
    let state: ValidationState
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: state.icon)
                .foregroundColor(state.color)
            
            Text(message)
                .font(.footnote)
                .foregroundColor(state.color)
            
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        ValidationMessage(
            message: "Password must be at least 8 characters long",
            state: .error
        )
        
        ValidationMessage(
            message: "Your password is medium strength",
            state: .warning
        )
        
        ValidationMessage(
            message: "Form submitted successfully",
            state: .valid
        )
        
        ValidationMessage(
            message: "You'll receive a confirmation email shortly",
            state: .info
        )
    }
    .padding()
} 