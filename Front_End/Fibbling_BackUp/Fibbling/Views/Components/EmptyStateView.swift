import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundColor(.gray.opacity(0.7))
                .padding(.bottom, 10)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let buttonTitle = buttonTitle, let action = action {
                Button(action: action) {
                    Text(buttonTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 30)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    EmptyStateView(
        title: "No Events Found",
        message: "There are no upcoming events matching your criteria. Try adjusting your filters or create a new event.",
        icon: "calendar.badge.exclamationmark",
        buttonTitle: "Create Event",
        action: { print("Create event tapped") }
    )
} 