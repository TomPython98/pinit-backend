import SwiftUI

struct NotificationPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var theme = PinItTheme()

    // MARK: - App Storage for Notification Preferences
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("eventReminders") private var eventReminders = true
    @AppStorage("friendRequests") private var friendRequests = true
    @AppStorage("eventInvitations") private var eventInvitations = true
    @AppStorage("ratingNotifications") private var ratingNotifications = true
    @AppStorage("chatMessages") private var chatMessages = true
    @AppStorage("autoMatchingNotifications") private var autoMatchingNotifications = true
    @AppStorage("quietHoursEnabled") private var quietHoursEnabled = false
    @AppStorage("quietHoursStart") private var quietHoursStart: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
    @AppStorage("quietHoursEnd") private var quietHoursEnd: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @AppStorage("reminderTime") private var reminderTime: Double = 15 // minutes before event

    var body: some View {
        NavigationStack {
            ZStack {
                // Clean background
                Color.pinItBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // General Notifications
                        settingsCard("General", icon: PinItIcons.notification, color: .pinItPrimary) {
                            VStack(spacing: 16) {
                                Toggle("Enable All Notifications", isOn: $enableNotifications)
                                    .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
                                    .foregroundStyle(Color.pinItTextPrimary)
                                Text("Turn off to disable all push notifications from PinIt.")
                                    .font(.caption)
                                    .foregroundStyle(Color.pinItTextSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        if enableNotifications {
                            // Event Notifications
                            settingsCard("Events", icon: PinItIcons.event, color: .pinItAccent) {
                                VStack(spacing: 16) {
                                    Toggle("Event Reminders", isOn: $eventReminders)
                                        .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
                                        .foregroundStyle(Color.pinItTextPrimary)
                                    Toggle("Event Invitations", isOn: $eventInvitations)
                                        .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
                                        .foregroundStyle(Color.pinItTextPrimary)
                                    Toggle("Auto-Matching Suggestions", isOn: $autoMatchingNotifications)
                                        .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
                                        .foregroundStyle(Color.pinItTextPrimary)

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Remind me before event")
                                            .foregroundStyle(Color.pinItTextPrimary)
                                        Picker("Reminder Time", selection: $reminderTime) {
                                            Text("5 minutes").tag(5.0)
                                                .foregroundStyle(Color.pinItTextPrimary)
                                            Text("15 minutes").tag(15.0)
                                                .foregroundStyle(Color.pinItTextPrimary)
                                            Text("30 minutes").tag(30.0)
                                                .foregroundStyle(Color.pinItTextPrimary)
                                            Text("1 hour").tag(60.0)
                                                .foregroundStyle(Color.pinItTextPrimary)
                                        }
                                        .pickerStyle(.segmented)
                                        .accentColor(theme.primaryColor)
                                    }
                                }
                            }
                            
                            // Social Notifications
                            settingsCard("Social", icon: PinItIcons.people, color: .pinItSecondary) {
                                VStack(spacing: 16) {
                                    Toggle("Friend Requests", isOn: $friendRequests)
                                        .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
                                        .foregroundStyle(Color.pinItTextPrimary)
                                    Toggle("Chat Messages", isOn: $chatMessages)
                                        .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
                                        .foregroundStyle(Color.pinItTextPrimary)
                                    Toggle("New Ratings & Reviews", isOn: $ratingNotifications)
                                        .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
                                        .foregroundStyle(Color.pinItTextPrimary)
                                }
                            }
                            
                            // Quiet Hours
                            settingsCard("Quiet Hours", icon: PinItIcons.time, color: .pinItAcademic) {
                                VStack(spacing: 16) {
                                    Toggle("Enable Quiet Hours", isOn: $quietHoursEnabled)
                                        .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
                                        .foregroundStyle(Color.pinItTextPrimary)

                                    if quietHoursEnabled {
                                        DatePicker("Start Time", selection: $quietHoursStart, displayedComponents: .hourAndMinute)
                                            .foregroundStyle(Color.pinItTextPrimary)
                                        DatePicker("End Time", selection: $quietHoursEnd, displayedComponents: .hourAndMinute)
                                            .foregroundStyle(Color.pinItTextPrimary)
                                        Text("Notifications will be silenced during these hours.")
                                            .font(.caption)
                                            .foregroundStyle(Color.pinItTextSecondary)
                                            .multilineTextAlignment(.center)
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
                            .foregroundStyle(Color.pinItTextPrimary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: PinItIcons.notification)
                            .foregroundStyle(Color.pinItPrimary)
                        Text("Notification Preferences")
                            .font(.title3.bold())
                            .foregroundStyle(Color.pinItTextPrimary)
                    }
                }
            }
        }
        .onAppear {
            theme.isDarkMode = false
            theme.selectedAccentColor = .blue
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
                    .foregroundStyle(Color.pinItTextPrimary)
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
    NotificationPreferencesView()
}