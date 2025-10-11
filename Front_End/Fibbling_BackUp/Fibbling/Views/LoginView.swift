import SwiftUI

struct LoginView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    @State private var username = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isRegistering = false
    @State private var showPassword = false
    @State private var email = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false
    
    var body: some View {
        ZStack {
            // Clean professional background like ContentView
            Color.bgSurface
            .ignoresSafeArea()
            
            // Elegant background gradient like ContentView
            LinearGradient(
                colors: [Color.gradientStart.opacity(0.1), Color.gradientEnd.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // App Logo & Title with professional styling
                    VStack(spacing: 15) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.brandPrimary)
                            .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
                        
                        Text("PinIt")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                            .tracking(0.2)
                        
                        Text(isRegistering ? "Create your account" : "Sign in to continue")
                            .font(.headline)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 40)
                    
                    // Login/Register Card with Professional Styling
                    VStack(spacing: 20) {
                        if isRegistering {
                            customTextField(title: "Email", text: $email, icon: "envelope", keyboardType: .emailAddress)
                        }
                        
                        customTextField(title: "Username", text: $username, icon: "person")
                        
                        // Inline Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(.brandPrimary)
                                Text("Password")
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)
                            }
                            
                            ZStack(alignment: .trailing) {
                                if showPassword {
                                    ZStack(alignment: .leading) {
                                        if password.isEmpty {
                                            Text("Enter your password")
                                                .foregroundColor(Color.gray.opacity(0.6))
                                                .padding(.horizontal, 12)
                                        }
                                        TextField("", text: $password)
                                            .padding(12)
                                            .foregroundColor(Color.textPrimary)
                                    }
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.bgCard)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.cardStroke, lineWidth: 1)
                                    )
                                } else {
                                    ZStack(alignment: .leading) {
                                        if password.isEmpty {
                                            Text("Enter your password")
                                                .foregroundColor(Color.gray.opacity(0.6))
                                                .padding(.horizontal, 12)
                                        }
                                        SecureField("", text: $password)
                                            .padding(12)
                                            .foregroundColor(Color.textPrimary)
                                    }
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.bgCard)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.cardStroke, lineWidth: 1)
                                    )
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(.trailing, 12)
                            }
                        }
                        
                        if isRegistering {
                            customTextField(title: "Confirm Password", text: $confirmPassword, icon: "lock", isSecure: true)
                            
                            HStack {
                                Toggle("", isOn: $agreedToTerms)
                                    .toggleStyle(SwitchToggleStyle(tint: .brandPrimary))
                                
                                Text("I agree to Terms & Privacy Policy")
                                    .font(.footnote)
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        
                        Button(action: {
                            if isRegistering {
                                guard password == confirmPassword else {
                                    alertMessage = "Passwords don't match"
                                    showAlert = true
                                    return
                                }
                                guard agreedToTerms else {
                                    alertMessage = "Please agree to terms and conditions"
                                    showAlert = true
                                    return
                                }
                                accountManager.register(username: username, password: password) { success, message in
                                    if success {
                                        isLoggedIn = true
                                    } else {
                                        alertMessage = message
                                        showAlert = true
                                    }
                                }
                            } else {
                                accountManager.login(username: username, password: password) { success, message in
                                    if success {
                                        isLoggedIn = true
                                    } else {
                                        alertMessage = message
                                        showAlert = true
                                    }
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: isRegistering ? "person.badge.plus" : "arrow.right.circle.fill")
                                    .font(.headline)
                                Text(isRegistering ? "Create Account" : "Sign In")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.brandPrimary, .brandSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
                        }
                        
                        Button(action: { isRegistering.toggle() }) {
                            Text(isRegistering ? "Already have an account? Sign In" : "Don't have an account? Register")
                                .font(.footnote)
                                .foregroundColor(.textSecondary)
                        }
                        
                        if !isRegistering {
                            Button("Forgot Password?") {
                                // Handle forgot password
                            }
                            .font(.footnote)
                            .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(25)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.bgCard)
                            .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(.bottom, 40)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(UserAccountManager())
    }
    
    // MARK: - Custom Form Fields
    private func customTextField(title: String, text: Binding<String>, icon: String, keyboardType: UIKeyboardType = .default, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.brandPrimary)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
            }
            
            // Generate placeholder based on field type
            let placeholder = getPlaceholder(for: title, keyboardType: keyboardType)
            
            if isSecure {
                ZStack(alignment: .leading) {
                    if text.wrappedValue.isEmpty {
                        Text(placeholder)
                            .foregroundColor(Color.gray.opacity(0.6))
                            .padding(.horizontal, 12)
                    }
                    SecureField("", text: text)
                        .padding(12)
                        .foregroundColor(Color.textPrimary)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.bgCard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cardStroke, lineWidth: 1)
                )
            } else {
                ZStack(alignment: .leading) {
                    if text.wrappedValue.isEmpty {
                        Text(placeholder)
                            .foregroundColor(Color.gray.opacity(0.6))
                            .padding(.horizontal, 12)
                    }
                    TextField("", text: text)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .padding(12)
                        .foregroundColor(Color.textPrimary)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.bgCard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cardStroke, lineWidth: 1)
                )
            }
        }
    }
    
    // Generate contextual placeholders
    private func getPlaceholder(for title: String, keyboardType: UIKeyboardType) -> String {
        switch title.lowercased() {
        case let t where t.contains("email"):
            return "Enter your email address"
        case let t where t.contains("username"):
            return "Enter your username"
        case let t where t.contains("confirm"):
            return "Re-enter your password"
        case let t where t.contains("password"):
            return "Enter your password"
        default:
            if keyboardType == .emailAddress {
                return "example@email.com"
            }
            return "Enter \(title.lowercased())"
        }
    }
