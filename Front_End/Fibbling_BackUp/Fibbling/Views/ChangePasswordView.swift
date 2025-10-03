import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var accountManager: UserAccountManager
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                        .accessibilityLabel("Current password field")
                    SecureField("New Password", text: $newPassword)
                        .accessibilityLabel("New password field")
                    SecureField("Confirm New Password", text: $confirmPassword)
                        .accessibilityLabel("Confirm new password field")
                }
                
                Section {
                    Button(action: updatePassword) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("Update Password")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isLoading || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                    .accessibilityLabel("Update password")
                    .accessibilityHint("Update your account password")
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel password change")
                }
            }
            .alert("Password Update", isPresented: $showAlert) {
                Button("OK") {
                    if alertMessage == "Password updated successfully!" {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func updatePassword() {
        // Validate inputs
        guard !currentPassword.isEmpty else {
            alertMessage = "Please enter your current password"
            showAlert = true
            return
        }
        
        guard !newPassword.isEmpty else {
            alertMessage = "Please enter a new password"
            showAlert = true
            return
        }
        
        guard newPassword.count >= 6 else {
            alertMessage = "New password must be at least 6 characters long"
            showAlert = true
            return
        }
        
        guard newPassword == confirmPassword else {
            alertMessage = "New passwords don't match"
            showAlert = true
            return
        }
        
        guard let username = accountManager.currentUser else {
            alertMessage = "User not found. Please log in again."
            showAlert = true
            return
        }
        
        isLoading = true
        
        // API call to change password
        guard let url = URL(string: "\(APIConfig.primaryBaseURL)/change_password/") else {
            alertMessage = "Invalid server URL"
            showAlert = true
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let passwordData = [
            "username": username,
            "current_password": currentPassword,
            "new_password": newPassword
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: passwordData)
        } catch {
            alertMessage = "Error preparing request: \(error.localizedDescription)"
            showAlert = true
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    alertMessage = "Network error: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    alertMessage = "Invalid server response"
                    showAlert = true
                    return
                }
                
                switch httpResponse.statusCode {
                case 200:
                    alertMessage = "Password updated successfully!"
                    showAlert = true
                    // Clear the form
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                    
                case 400:
                    alertMessage = "Invalid current password"
                    showAlert = true
                    
                case 401:
                    alertMessage = "Authentication failed. Please log in again."
                    showAlert = true
                    
                case 500:
                    alertMessage = "Server error. Please try again later."
                    showAlert = true
                    
                default:
                    alertMessage = "Unexpected error occurred"
                    showAlert = true
                }
            }
        }.resume()
    }
}

#Preview {
    ChangePasswordView()
}
