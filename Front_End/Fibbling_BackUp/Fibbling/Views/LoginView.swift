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
            // Enhanced background gradient
            LinearGradient(
                gradient: Gradient(colors: [.socialLight, .socialAccent, .socialPrimary]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated background shapes
            GeometryReader { geometry in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)
                    .offset(x: geometry.size.width * 0.6, y: geometry.size.height * 0.4)
            }
            
            ScrollView {
                VStack(spacing: 30) {
                    // App Logo & Title
                    VStack(spacing: 15) {
                        Image(systemName: "lightbulb.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4)
                        
                        Text("Welcome to UniVerse")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4)
                        
                        Text(isRegistering ? "Create your account" : "Sign in to continue")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.top, 40)
                    
                    // Login/Register Card
                    VStack(spacing: 20) {
                        if isRegistering {
                            TextField("Email", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        TextField("Username", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.username)
                            .autocapitalization(.none)
                        
                        ZStack(alignment: .trailing) {
                            if showPassword {
                                TextField("Password", text: $password)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.password)
                            } else {
                                SecureField("Password", text: $password)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.password)
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 8)
                        }
                        
                        if isRegistering {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.password)
                            
                            Toggle("I agree to Terms & Privacy Policy", isOn: $agreedToTerms)
                                .font(.footnote)
                                .tint(.socialPrimary)
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
                            Text(isRegistering ? "Create Account" : "Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.socialPrimary)
                                .cornerRadius(10)
                        }
                        
                        Button(action: { isRegistering.toggle() }) {
                            Text(isRegistering ? "Already have an account? Sign In" : "Don't have an account? Register")
                                .font(.footnote)
                                .foregroundColor(.socialDark)
                        }
                        
                        if !isRegistering {
                            Button("Forgot Password?") {
                                // Handle forgot password
                            }
                            .font(.footnote)
                            .foregroundColor(.socialDark)
                        }
                    }
                    .padding(25)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.95))
                            .shadow(color: Color.black.opacity(0.15), radius: 10)
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
