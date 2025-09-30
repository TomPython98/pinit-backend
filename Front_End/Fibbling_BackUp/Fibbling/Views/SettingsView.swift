import SwiftUI
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @Environment(\.dismiss) private var dismiss
    @StateObject private var theme = PinItTheme()
    
    // MARK: - App Storage for Preferences
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("appLanguage") private var selectedLanguage = "English"
    @AppStorage("showOnlineStatus") private var showOnlineStatus = true
    @AppStorage("allowTagging") private var allowTagging = true
    @AppStorage("allowDirectMessages") private var allowDirectMessages = true
    @AppStorage("showActivityStatus") private var showActivityStatus = true
    
    // State variables
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var showImagePicker = false
    @State private var bio = "Hey there! I'm using PinIt 📍"
    @State private var isEditingBio = false
    @State private var showNotificationPreferences = false
    @State private var showPrivacySettings = false
    
    let supportedLanguages = ["English", "German", "Spanish", "French", "Italian", "Portuguese", "Chinese", "Japanese"]

    var body: some View {
        NavigationStack {
            ZStack {
                // Clean, elegant background
                Color.pinItBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Section
                        profileSection
                            .padding(.top, 20)
                        
                        // Main Settings Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            // Account Settings
                            settingsCard("Account", icon: PinItIcons.profile, color: .pinItPrimary) {
                                accountSettings
                            }
                            
                            // Privacy Settings
                            settingsCard("Privacy", icon: PinItIcons.privacy, color: .pinItAccent) {
                                privacySettings
                            }
                            
                            // Notifications
                            settingsCard("Notifications", icon: PinItIcons.notification, color: .pinItSecondary) {
                                notificationSettings
                            }
                            
                            // App Settings
                            settingsCard("App Settings", icon: PinItIcons.settings, color: .pinItAcademic) {
                                appSettings
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Help & Support
                        settingsCard("Help & Support", icon: PinItIcons.help, color: .pinItInfo) {
                            supportSettings
                        }
                        .padding(.horizontal, 20)
                        
                        // Danger Zone
                        settingsCard("Danger Zone", icon: PinItIcons.delete, color: .pinItError) {
                            dangerZone
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: PinItIcons.close)
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: PinItIcons.settings)
                            .foregroundStyle(Color.pinItPrimary)
                        Text("Settings")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .onAppear {
            theme.isDarkMode = darkMode
            theme.selectedAccentColor = .blue
        }
        .sheet(isPresented: $showPrivacySettings) {
            PrivacySettingsView()
        }
        .sheet(isPresented: $showNotificationPreferences) {
            NotificationPreferencesView()
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                isLoggedIn = false
                accountManager.logout { success, error in }
            }
        } message: {
            Text("Are you sure you want to logout from PinIt?")
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Implement account deletion
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted from PinIt.")
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: 16) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.pinItPrimary, .pinItAccent]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                if let profileImage = profileImage {
                    profileImage
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Image(systemName: PinItIcons.profile)
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
                
                // Camera button
                Button(action: { showImagePicker = true }) {
                    Image(systemName: PinItIcons.camera)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.pinItPrimary))
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
                .offset(x: 35, y: 35)
            }
            
            VStack(spacing: 8) {
                Text(accountManager.currentUser ?? "Guest")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                
                if isEditingBio {
                    TextField("Bio", text: $bio, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        .onSubmit { isEditingBio = false }
                } else {
                    Text(bio)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .onTapGesture { isEditingBio = true }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Settings Card
    private func settingsCard<Content: View>(_ title: String, icon: String, color: Color, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Animated Settings Button
    @ViewBuilder
    private func settingsButton<Overlay: View>(
        icon: String,
        title: String,
        subtitle: String? = nil,
        action: @escaping () -> Void,
        @ViewBuilder overlay: () -> Overlay = { EmptyView() }
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Image(systemName: PinItIcons.chevronRight)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(overlay())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
    
    // MARK: - Settings Content
    private var accountSettings: some View {
        VStack(spacing: 8) {
            settingsButton(icon: "person.circle", title: "Edit Profile", action: {
                // Navigation handled by NavigationLink
            }) {
                NavigationLink("", destination: EditProfileView())
                    .opacity(0)
            }
            
            settingsButton(icon: "key", title: "Change Password", action: {
                // Navigation handled by NavigationLink
            }) {
                NavigationLink("", destination: ChangePasswordView())
                    .opacity(0)
            }
            
            settingsButton(icon: "link", title: "Connected Accounts", action: {
                // Navigation handled by NavigationLink
            }) {
                NavigationLink("", destination: Text("Connected Accounts"))
                    .opacity(0)
            }
        }
    }
    
    private var privacySettings: some View {
        VStack(spacing: 8) {
            settingsButton(
                icon: "shield.lefthalf.filled",
                title: "Privacy & Security",
                subtitle: "Manage your privacy settings",
                action: { showPrivacySettings = true }
            )
            
            Divider()
                .padding(.vertical, 4)
            
            Toggle("Show Online Status", isOn: $showOnlineStatus)
                .toggleStyle(SwitchToggleStyle(tint: Color.pinItAccent))
            
            Toggle("Allow Tagging", isOn: $allowTagging)
                .toggleStyle(SwitchToggleStyle(tint: Color.pinItAccent))
        }
    }
    
    private var notificationSettings: some View {
        VStack(spacing: 8) {
            settingsButton(
                icon: "bell.badge",
                title: "Notification Preferences",
                subtitle: "Customize your notifications",
                action: { showNotificationPreferences = true }
            )
            
            Divider()
                .padding(.vertical, 4)
            
            Toggle("Enable Notifications", isOn: $enableNotifications)
                .toggleStyle(SwitchToggleStyle(tint: Color.pinItSecondary))
            
            Toggle("Show Activity Status", isOn: $showActivityStatus)
                .toggleStyle(SwitchToggleStyle(tint: Color.pinItSecondary))
        }
    }
    
    private var appSettings: some View {
        VStack(spacing: 8) {
            Toggle("Dark Mode", isOn: $darkMode)
                .toggleStyle(SwitchToggleStyle(tint: Color.pinItAcademic))
                .onChange(of: darkMode) { newValue in
                    theme.isDarkMode = newValue
                }
            
            Divider()
                .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "globe")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text("Language")
                        .font(.body)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(supportedLanguages, id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
                .pickerStyle(.menu)
                .padding(.leading, 32)
            }
        }
    }
    
    private var supportSettings: some View {
        VStack(spacing: 8) {
            Link(destination: URL(string: "https://pinit.app/help")!) {
                settingsButton(icon: "questionmark.circle", title: "Help Center", action: {})
            }
            
            Link(destination: URL(string: "https://pinit.app/support")!) {
                settingsButton(icon: "envelope", title: "Contact Support", action: {})
            }
            
            Link(destination: URL(string: "https://pinit.app/privacy")!) {
                settingsButton(icon: "hand.raised", title: "Privacy Policy", action: {})
            }
            
            Link(destination: URL(string: "https://pinit.app/terms")!) {
                settingsButton(icon: "doc.text", title: "Terms of Service", action: {})
            }
            
            Divider()
                .padding(.vertical, 4)
            
            HStack(spacing: 12) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                Text("App Version")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("1.0.0")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
    }
    
    private var dangerZone: some View {
        VStack(spacing: 8) {
            Button(action: { showLogoutAlert = true }) {
                HStack(spacing: 12) {
                    Image(systemName: PinItIcons.logout)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.pinItError)
                        .frame(width: 20)
                    
                    Text("Logout")
                        .font(.body)
                        .foregroundStyle(Color.pinItError)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: PinItIcons.chevronRight)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.pinItError.opacity(0.6))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.pinItError.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Button(action: { showDeleteAlert = true }) {
                HStack(spacing: 12) {
                    Image(systemName: PinItIcons.delete)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.pinItError)
                        .frame(width: 20)
                    
                    Text("Delete Account")
                        .font(.body)
                        .foregroundStyle(Color.pinItError)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: PinItIcons.chevronRight)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.pinItError.opacity(0.6))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.pinItError.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(UserAccountManager())
}