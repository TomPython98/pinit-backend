import SwiftUI
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
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
    @State private var bio = ""
    @State private var isEditingBio = false
    @State private var showNotificationPreferences = false
    @State private var showPrivacySettings = false
    
    let supportedLanguages = ["English", "German", "Spanish", "French", "Italian", "Portuguese", "Chinese", "Japanese"]

    var body: some View {
        NavigationStack {
            ZStack {
                // Clean, elegant background
                Color.bgSurface
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Profile Section
                        profileSection
                            .padding(.top, 24)
                        
                        // Settings Sections - Clean single column layout
                        VStack(spacing: 24) {
                            // Account Settings
                            settingsCard("Account", icon: PinItIcons.profile, color: .pinItPrimary) {
                                accountSettings
                            }
                            
                            // Privacy & Security
                            settingsCard("Privacy & Security", icon: PinItIcons.privacy, color: .pinItAccent) {
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
                            
                            // Help & Support
                            settingsCard("Help & Support", icon: PinItIcons.help, color: .pinItInfo) {
                                supportSettings
                            }
                            
                            // Danger Zone
                            settingsCard("Danger Zone", icon: PinItIcons.delete, color: .pinItError) {
                                dangerZone
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgCard, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color.textPrimary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.title2.bold())
                        .foregroundColor(Color.textPrimary)
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
                    .foregroundStyle(Color.pinItTextPrimary)
                
                if isEditingBio {
                    TextField("Bio", text: $bio, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        .onSubmit { isEditingBio = false }
                } else {
                    Text(bio)
                        .foregroundStyle(Color.pinItTextSecondary)
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
        VStack(alignment: .leading, spacing: 20) {
            // Header with icon and title
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(Color.pinItTextPrimary)
                
                Spacer()
            }
            
            // Content with proper spacing
            content()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
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
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.pinItTextSecondary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.pinItTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Color.pinItTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Image(systemName: PinItIcons.chevronRight)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(overlay())
    }
    
    // MARK: - Settings Content
    private var accountSettings: some View {
        VStack(spacing: 12) {
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
        VStack(spacing: 16) {
            settingsButton(
                icon: "shield.lefthalf.filled",
                title: "Privacy & Security",
                subtitle: "Manage your privacy settings",
                action: { showPrivacySettings = true }
            )
            
            Divider()
                .padding(.vertical, 8)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Show Online Status")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.pinItTextPrimary)
                    Spacer()
                    Toggle("", isOn: $showOnlineStatus)
                        .toggleStyle(SwitchToggleStyle(tint: Color.pinItAccent))
                }
                .padding(.vertical, 4)
                
                HStack {
                    Text("Allow Tagging")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.pinItTextPrimary)
                    Spacer()
                    Toggle("", isOn: $allowTagging)
                        .toggleStyle(SwitchToggleStyle(tint: Color.pinItAccent))
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var notificationSettings: some View {
        VStack(spacing: 16) {
            settingsButton(
                icon: "bell.badge",
                title: "Notification Preferences",
                subtitle: "Customize your notifications",
                action: { showNotificationPreferences = true }
            )
            
            Divider()
                .padding(.vertical, 8)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Enable Notifications")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.pinItTextPrimary)
                    Spacer()
                    Toggle("", isOn: $enableNotifications)
                        .toggleStyle(SwitchToggleStyle(tint: Color.pinItSecondary))
                }
                .padding(.vertical, 4)
                
                HStack {
                    Text("Show Activity Status")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.pinItTextPrimary)
                    Spacer()
                    Toggle("", isOn: $showActivityStatus)
                        .toggleStyle(SwitchToggleStyle(tint: Color.pinItSecondary))
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var appSettings: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Dark Mode")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.pinItTextPrimary)
                Spacer()
                Toggle("", isOn: $darkMode)
                    .toggleStyle(SwitchToggleStyle(tint: Color.pinItAcademic))
                    .onChange(of: darkMode) { newValue in
                        theme.isDarkMode = newValue
                    }
            }
            .padding(.vertical, 4)
            
            Divider()
                .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    Image(systemName: "globe")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.pinItTextSecondary)
                        .frame(width: 24, height: 24)
                    Text("Language")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.pinItTextPrimary)
                    Spacer()
                }
                
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(supportedLanguages, id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
                .pickerStyle(.menu)
                .padding(.leading, 40)
            }
        }
    }
    
    private var supportSettings: some View {
        VStack(spacing: 12) {
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
            
            #if DEBUG
            Button(action: {
                hasCompletedOnboarding = false
            }) {
                settingsButton(icon: "arrow.clockwise", title: "Reset Onboarding", action: {})
            }
            #endif
            
            Divider()
                .padding(.vertical, 8)
            
            HStack(spacing: 16) {
                Image(systemName: "info.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.pinItTextSecondary)
                    .frame(width: 24, height: 24)
                Text("App Version")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.pinItTextSecondary)
                Spacer()
                Text("1.0.0")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(Color.pinItTextSecondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
            )
        }
    }
    
    private var dangerZone: some View {
        VStack(spacing: 12) {
            Button(action: { showLogoutAlert = true }) {
                HStack(spacing: 16) {
                    Image(systemName: PinItIcons.logout)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.pinItError)
                        .frame(width: 24, height: 24)
                    
                    Text("Logout")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.pinItError)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: PinItIcons.chevronRight)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.pinItError.opacity(0.6))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.pinItError.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Button(action: { showDeleteAlert = true }) {
                HStack(spacing: 16) {
                    Image(systemName: PinItIcons.delete)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.pinItError)
                        .frame(width: 24, height: 24)
                    
                    Text("Delete Account")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.pinItError)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: PinItIcons.chevronRight)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.pinItError.opacity(0.6))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.pinItError.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
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