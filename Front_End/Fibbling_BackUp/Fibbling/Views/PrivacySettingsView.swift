import SwiftUI

struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var theme = PinItTheme()

    // MARK: - App Storage for Privacy Preferences
    @AppStorage("showOnlineStatus") private var showOnlineStatus = true
    @AppStorage("showActivityStatus") private var showActivityStatus = true
    @AppStorage("shareLocation") private var shareLocation = true
    @AppStorage("allowTagging") private var allowTagging = true
    @AppStorage("allowDirectMessages") private var allowDirectMessages = true
    @AppStorage("allowEventDiscovery") private var allowEventDiscovery = true
    @AppStorage("dataSharingEnabled") private var dataSharingEnabled = true
    @AppStorage("analyticsEnabled") private var analyticsEnabled = true
    @AppStorage("crashReportingEnabled") private var crashReportingEnabled = true

    // State variables
    @State private var showExportDataAlert = false
    @State private var showDeleteDataAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Clean background
                Color.pinItBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Visibility
                        settingsCard("Profile Visibility", icon: PinItIcons.profile, color: .pinItPrimary) {
                            VStack(spacing: 16) {
                                Toggle("Show Online Status", isOn: $showOnlineStatus)
                                    .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
                                Text("Let other users see when you are online.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)

                                Toggle("Show Activity Status", isOn: $showActivityStatus)
                                    .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
                                Text("Display your recent activity, like events attended.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)

                                Toggle("Share My Location", isOn: $shareLocation)
                                    .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
                                Text("Allow PinIt to use your location for event discovery and matching.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        // Social Interactions
                        settingsCard("Social Interactions", icon: PinItIcons.people, color: .pinItAccent) {
                            VStack(spacing: 16) {
                                Toggle("Allow Tagging in Events", isOn: $allowTagging)
                                    .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
                                Toggle("Allow Direct Messages", isOn: $allowDirectMessages)
                                    .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
                                Toggle("Allow Event Discovery by Friends", isOn: $allowEventDiscovery)
                                    .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
                            }
                        }
                        
                        // Data & Privacy
                        settingsCard("Data & Privacy", icon: PinItIcons.privacy, color: .pinItSecondary) {
                            VStack(spacing: 16) {
                                Toggle("Enable Data Sharing", isOn: $dataSharingEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
                                Text("Allow PinIt to share anonymized data with partners for app improvement.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)

                                Toggle("Send Analytics Data", isOn: $analyticsEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
                                Toggle("Send Crash Reports", isOn: $crashReportingEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
                            }
                        }
                        
                        // Privacy Actions
                        settingsCard("Privacy Actions", icon: PinItIcons.delete, color: .pinItError) {
                            VStack(spacing: 16) {
                                Button(action: { showExportDataAlert = true }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundStyle(theme.primaryColor)
                                        Text("Export My Data")
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Image(systemName: PinItIcons.chevronRight)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Button(action: { showDeleteDataAlert = true }) {
                                    HStack {
                                        Image(systemName: PinItIcons.delete)
                                            .foregroundStyle(Color.pinItError)
                                        Text("Delete All My Data")
                                            .foregroundStyle(Color.pinItError)
                                        Spacer()
                                        Image(systemName: PinItIcons.chevronRight)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
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
                        Image(systemName: PinItIcons.privacy)
                            .foregroundStyle(Color.pinItPrimary)
                        Text("Privacy & Security")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .onAppear {
            theme.isDarkMode = false
            theme.selectedAccentColor = .blue
        }
        .alert("Export Data", isPresented: $showExportDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Export", role: .none) {
                // Implement data export logic
            }
        } message: {
            Text("Your data will be prepared for download. This may take a few minutes.")
        }
        .alert("Delete All Data", isPresented: $showDeleteDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Implement data deletion logic
            }
        } message: {
            Text("This action cannot be undone. All your personal data will be permanently deleted from PinIt.")
        }
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
}

// MARK: - Preview
#Preview {
    PrivacySettingsView()
}