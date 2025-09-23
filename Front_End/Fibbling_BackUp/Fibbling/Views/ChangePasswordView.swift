import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
                }
                
                Section {
                    Button("Update Password") {
                        if newPassword == confirmPassword {
                            // TODO: Implement password update logic
                            alertMessage = "Password updated successfully!"
                        } else {
                            alertMessage = "New passwords don't match"
                        }
                        showAlert = true
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
}

#Preview {
    ChangePasswordView()
}
