import SwiftUI
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject var accountManager: UserAccountManager
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - App Storage for Preferences
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("appLanguage") private var selectedLanguage = "English"
    @AppStorage("showOnlineStatus") private var showOnlineStatus = true
    @AppStorage("allowTagging") private var allowTagging = true
    @AppStorage("allowDirectMessages") private var allowDirectMessages = true
    @AppStorage("showActivityStatus") private var showActivityStatus = true
    @AppStorage("allowAutoMatching") private var allowAutoMatching = true
    
    // State variables
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var showImagePicker = false
    @State private var bio = "Hey there! I'm using BrainMap 👋"
    @State private var isEditingBio = false
    
    let supportedLanguages = ["English", "German", "Spanish", "French", "Italian"]

    var body: some View {
        NavigationStack {
            ZStack {
                // Enhanced background with animated gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.socialLight.opacity(0.9),
                        Color.socialAccent.opacity(0.8),
                        Color.socialPrimary.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Profile Section
                        profileSection
                            .padding(.top)
                        
                        // Account Settings
                        settingsSection("Account", icon: "person.fill") {
                            accountSettings
                        }
                        
                        // Privacy Settings
                        settingsSection("Privacy", icon: "lock.fill") {
                            privacySettings
                        }
                        
                        // Notification Settings
                        settingsSection("Notifications", icon: "bell.fill") {
                            notificationSettings
                        }
                        
                        // App Settings
                        settingsSection("App Settings", icon: "gearshape.fill") {
                            appSettings
                        }
                        
                        // Help & Support
                        settingsSection("Help & Support", icon: "questionmark.circle.fill") {
                            supportSettings
                        }
                        
                        // Danger Zone
                        dangerZone
                            .padding(.top)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: 15) {
            ZStack(alignment: .bottomTrailing) {
                if let profileImage {
                    profileImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundStyle(Color.socialPrimary)
                        .background(.white)
                        .clipShape(Circle())
                }
                
                PhotosPicker(selection: $selectedImage, matching: .images) {
                    Image(systemName: "camera.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.socialPrimary)
                        .background(.white)
                        .clipShape(Circle())
                }
            }
            
            VStack(spacing: 8) {
                Text(accountManager.currentUser ?? "Guest")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                if isEditingBio {
                    TextField("Bio", text: $bio, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        .onSubmit { isEditingBio = false }
                } else {
                    Text(bio)
                        .foregroundStyle(.white)
                        .onTapGesture { isEditingBio = true }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.socialMedium.opacity(0.7))
        )
    }
    
    // MARK: - Settings Sections
    private func settingsSection<Content: View>(_ title: String, icon: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.title3.bold())
            }
            .foregroundStyle(Color.socialDark)
            
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.9))
        )
    }
    
    // MARK: - Settings Content
    private var accountSettings: some View {
        VStack(spacing: 15) {
            NavigationLink("Edit Profile") {
                EditProfileView()
            }
            NavigationLink("Change Password") {
                ChangePasswordView()
            }
            NavigationLink("Connected Accounts") {
                Text("Connected Accounts")
            }

        }
    }
    
    private var privacySettings: some View {
        VStack(spacing: 15) {
            Toggle("Show Online Status", isOn: $showOnlineStatus)
            Toggle("Allow Tagging", isOn: $allowTagging)
            Toggle("Allow Direct Messages", isOn: $allowDirectMessages)
            Toggle("Show Activity Status", isOn: $showActivityStatus)
            Toggle("Enable Auto-Matching", isOn: $allowAutoMatching)
        }
    }
    
    private var notificationSettings: some View {
        VStack(spacing: 15) {
            Toggle("Push Notifications", isOn: $enableNotifications)
            NavigationLink("Notification Preferences") {
                Text("Notification Preferences")
            }
        }
    }
    
    private var appSettings: some View {
        VStack(spacing: 15) {
            Toggle("Dark Mode", isOn: $darkMode)
            
            HStack {
                Text("Language")
                Spacer()
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(supportedLanguages, id: \.self) { lang in
                        Text(lang).tag(lang)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    private var supportSettings: some View {
        VStack(spacing: 15) {
            Link("Help Center", destination: URL(string: "https://help.brainmap.com")!)
            Link("Privacy Policy", destination: URL(string: "https://brainmap.com/privacy")!)
            Link("Terms of Service", destination: URL(string: "https://brainmap.com/terms")!)
            Text("Version 1.0.0")
                .foregroundStyle(.gray)
        }
    }
    
    private var dangerZone: some View {
        VStack(spacing: 15) {
            Button(role: .destructive) {
                showLogoutAlert = true
            } label: {
                Label("Logout", systemImage: "arrow.right.circle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Delete Account", systemImage: "trash")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                accountManager.logout { success, _ in
                    if success {
                        isLoggedIn = false
                    }
                }
            }
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                accountManager.deleteAccount { success, _ in
                    if success {
                        isLoggedIn = false
                    }
                }
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(UserAccountManager())
}
