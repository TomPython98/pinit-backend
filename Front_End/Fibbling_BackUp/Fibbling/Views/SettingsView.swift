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
    @StateObject private var localizationManager = LocalizationManager.shared
    @AppStorage("showOnlineStatus") private var showOnlineStatus = true
    @AppStorage("allowTagging") private var allowTagging = true
    @AppStorage("allowDirectMessages") private var allowDirectMessages = true
    @AppStorage("showActivityStatus") private var showActivityStatus = true
    
    // State variables
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @State private var bio = ""
    @State private var isEditingBio = false
    @State private var showNotificationPreferences = false
    @State private var showPrivacySettings = false
    @State private var showLegalDocuments = false
    @State private var selectedLegalDocument: LegalDocumentType = .privacyPolicy
    @State private var showChangePassword = false
    
    enum LegalDocumentType: String, CaseIterable {
        case privacyPolicy = "Privacy Policy"
        case termsOfService = "Terms of Service"
        
        var content: String {
            switch self {
            case .privacyPolicy:
                return Self.privacyPolicyContent
            case .termsOfService:
                return Self.termsOfServiceContent
            }
        }
        
        var icon: String {
            switch self {
            case .privacyPolicy:
                return "hand.raised.fill"
            case .termsOfService:
                return "doc.text.fill"
            }
        }
        
        static let privacyPolicyContent = """
        Privacy Policy for PinIt

        Effective Date: January 2025

        1. Introduction

        PinIt ("we," "our," or "us") respects your privacy and is committed to protecting your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.

        2. Information We Collect

        2.1 Account Information
        • Name and Email: For account creation and communication
        • Profile Information: University, degree, year, bio, interests, skills
        • Authentication Data: Username and encrypted password

        2.2 Location Data
        • Precise Location: For event creation and discovery (when permission granted)
        • Approximate Location: For map-based features and nearby event suggestions
        • Location History: Temporarily stored for event recommendations

        2.3 Content Data
        • Photos and Videos: Uploaded for profiles and events
        • Messages: Sent in group chats and direct messages
        • Event Descriptions: Created by users
        • Reviews and Ratings: User-generated content

        2.4 Technical Data
        • Device Information: Device type, operating system, app version
        • Usage Analytics: App interactions, features used, session duration
        • Crash Reports: Error logs and performance data
        • IP Address: For security and analytics purposes

        3. How We Use Your Information

        3.1 Core Services
        • Event Management: Create, discover, and manage study events
        • Social Features: Connect users, facilitate friendships
        • Location Services: Show nearby events and study partners
        • Communication: Enable chat and messaging features

        3.2 App Improvement
        • Analytics: Understand user behavior and app usage
        • Performance: Monitor app stability and fix crashes
        • Features: Develop new functionality based on user needs
        • Personalization: Provide relevant event recommendations

        3.3 Safety and Security
        • Account Security: Protect against unauthorized access
        • Content Moderation: Monitor for inappropriate content
        • Fraud Prevention: Detect and prevent misuse
        • Legal Compliance: Meet regulatory requirements

        4. Information Sharing

        4.1 We Do NOT Sell Your Data
        We do not sell, rent, or trade your personal information to third parties.

        4.2 Limited Sharing
        We may share information only in these circumstances:
        • With Your Consent: When you explicitly agree
        • Service Providers: Trusted partners who help operate the App
        • Legal Requirements: When required by law or legal process
        • Safety: To protect users or prevent harm

        4.3 Public Information
        Some information is public by design:
        • Profile Information: Name, university, interests (as you choose)
        • Event Details: Public events you create or join
        • Reviews: Ratings and reviews you write

        5. Data Security

        5.1 Protection Measures
        • Encryption: Data transmitted using industry-standard encryption
        • Secure Storage: Information stored on secure servers
        • Access Controls: Limited access to authorized personnel
        • Regular Audits: Security assessments and updates

        5.2 Data Breach Response
        • Immediate Notification: Users notified within 72 hours
        • Investigation: Thorough analysis of breach scope
        • Remediation: Steps to prevent future incidents
        • Support: Assistance for affected users

        6. Your Rights and Choices

        6.1 Access and Control
        • View Your Data: Access your profile and activity information
        • Update Information: Modify your profile and preferences
        • Delete Account: Remove your account and associated data
        • Data Export: Download your data in a portable format

        6.2 Privacy Settings
        • Location Sharing: Control location data collection
        • Profile Visibility: Manage who can see your information
        • Communication: Control who can contact you
        • Analytics: Opt out of usage tracking

        6.3 GDPR Rights (EU Users)
        • Right to Access: Request copies of your data
        • Right to Rectification: Correct inaccurate information
        • Right to Erasure: Request data deletion
        • Right to Portability: Transfer your data
        • Right to Object: Opt out of certain processing

        7. Data Retention

        7.1 Retention Periods
        • Account Data: Retained while account is active
        • Location Data: Deleted after 30 days unless needed for events
        • Messages: Stored for 1 year for safety purposes
        • Analytics: Aggregated data retained for 2 years

        7.2 Deletion Process
        • Account Deletion: Data removed within 30 days
        • Backup Data: Securely deleted from all systems
        • Legal Holds: Some data may be retained for legal compliance

        8. Children's Privacy

        8.1 Age Requirements
        • Minimum Age: 13 years old
        • Parental Consent: Required for users under 18
        • No Collection: We do not knowingly collect data from children under 13

        8.2 Protection Measures
        • Age Verification: Account creation requires age confirmation
        • Content Filtering: Enhanced protection for younger users
        • Parental Controls: Tools for parents to monitor activity

        9. International Data Transfers

        9.1 Data Processing
        • Primary Location: Argentina (Buenos Aires)
        • Backup Locations: Secure cloud providers
        • Adequate Protection: Appropriate safeguards in place

        9.2 Cross-Border Transfers
        • Standard Contractual Clauses: For EU data transfers
        • Adequacy Decisions: Where applicable
        • User Consent: For transfers to third countries

        10. Third-Party Services

        10.1 Integrated Services
        • Map Services: Mapbox for location features
        • Analytics: App usage and performance data
        • Cloud Storage: Secure data hosting

        10.2 Third-Party Policies
        • Separate Terms: Each service has its own privacy policy
        • Limited Sharing: Only necessary data shared
        • User Control: Options to limit third-party access

        11. Changes to This Policy

        11.1 Updates
        • Regular Review: Policy updated as needed
        • User Notification: Significant changes communicated
        • Version History: Previous versions available
        • Effective Date: Changes take effect when posted

        11.2 Continued Use
        • Acceptance: Continued use constitutes acceptance
        • Objection: Users can object to material changes
        • Account Closure: Option to delete account if disagree

        12. Contact Information

        12.1 Privacy Questions
        • Email: tom.besinger@icloud.com
        • Subject Line: "Privacy Policy Inquiry"
        • Response Time: Within 30 days

        12.2 Data Protection Officer
        • Contact: tom.besinger@icloud.com
        • Purpose: Privacy and data protection matters
        • Languages: English and Spanish

        13. Regional Variations

        13.1 European Union (GDPR)
        • Enhanced Rights: Additional data protection rights
        • Lawful Basis: Clear legal grounds for processing
        • Data Protection Impact: Assessments for high-risk processing

        13.2 California (CCPA)
        • Consumer Rights: Access, deletion, and opt-out rights
        • Non-Discrimination: No penalties for exercising rights
        • Disclosure: Clear information about data practices

        14. Complaints and Disputes

        14.1 Resolution Process
        • Direct Contact: First attempt to resolve directly
        • Mediation: Third-party mediation if needed
        • Regulatory: Contact relevant data protection authority

        14.2 Supervisory Authority
        • EU Users: Contact local data protection authority
        • Other Regions: Relevant privacy regulator
        • App Store: Report through Apple's App Store

        Last Updated: January 2025
        Version: 2.0

        This Privacy Policy is effective as of the date listed above and will remain in effect except with respect to any changes in its provisions in the future, which will be in effect immediately after being posted in the App.
        """
        
        static let termsOfServiceContent = """
        Terms of Service for PinIt

        Effective Date: January 2025

        1. Acceptance of Terms

        By downloading, installing, or using the PinIt mobile application ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.

        2. Description of Service

        PinIt is a social networking platform that connects students and professionals for study groups, events, and networking opportunities. The App allows users to:
        • Create and join study events
        • Connect with other users
        • Share location-based information
        • Communicate through chat features
        • Rate and review other users

        3. User Eligibility

        • You must be at least 13 years old to use PinIt
        • Users under 18 must have parental consent
        • You must provide accurate and complete information
        • You are responsible for maintaining account security

        4. User Conduct

        Prohibited Activities:
        • Harassment, bullying, or threatening behavior
        • Sharing inappropriate, offensive, or illegal content
        • Impersonating others or providing false information
        • Spamming or unsolicited communications
        • Violating others' privacy or intellectual property rights
        • Using the App for commercial purposes without permission

        5. Content and Intellectual Property

        • You retain ownership of content you create
        • You grant PinIt a license to use your content for App functionality
        • PinIt respects intellectual property rights
        • Report copyright violations to: tom.besinger@icloud.com

        6. Privacy and Data

        • Your privacy is important to us
        • See our Privacy Policy for data handling details
        • We collect location data for event discovery
        • We may use analytics to improve the App

        7. Location Services

        • PinIt requires location access for core functionality
        • Location data is used to show nearby events
        • You can disable location services in device settings
        • Location data is not shared with third parties

        8. Termination

        • You may delete your account at any time
        • We may suspend or terminate accounts for Terms violations
        • Upon termination, your data may be deleted
        • Some data may be retained for legal compliance

        9. Disclaimers

        • PinIt is provided "as is" without warranties
        • We do not guarantee uninterrupted service
        • Users interact at their own risk
        • We are not responsible for user-generated content

        10. Limitation of Liability

        • PinIt's liability is limited to the maximum extent permitted by law
        • We are not liable for indirect or consequential damages
        • Our total liability shall not exceed $100 USD

        11. Changes to Terms

        • We may update these Terms from time to time
        • Continued use constitutes acceptance of changes
        • We will notify users of significant changes
        • Updated Terms will be posted in the App

        12. Governing Law

        These Terms are governed by the laws of Argentina, without regard to conflict of law principles.

        13. Contact Information

        For questions about these Terms, contact:
        • Email: tom.besinger@icloud.com
        • Address: Buenos Aires, Argentina

        14. Severability

        If any provision of these Terms is found to be unenforceable, the remaining provisions will remain in effect.

        Last Updated: January 2025
        """
    }
    

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
                            
                            // Help & Support
                            settingsCard("Help & Support", icon: PinItIcons.help, color: .pinItInfo) {
                                supportSettings
                            }
                            
                            // About PinIt
                            aboutSection
                            
                            // Account Actions
                            settingsCard("Account Actions", icon: PinItIcons.delete, color: .pinItError) {
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
        .sheet(isPresented: $showLegalDocuments) {
            legalDocumentsSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showChangePassword) {
            NavigationStack {
                ChangePasswordView()
                    .environmentObject(accountManager)
            }
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                accountManager.logout { success, error in
                    if success {
                        DispatchQueue.main.async {
                            isLoggedIn = false
                        }
                    }
                }
            }
        } message: {
            Text("Are you sure you want to logout from PinIt?")
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted from PinIt.")
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: 16) {
            // Profile Picture
            UserProfileImageView(
                username: accountManager.currentUser ?? "Guest", 
                size: 100, 
                showBorder: true, 
                borderColor: .pinItPrimary
            )
            
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
            settingsButton(icon: "key", title: "Change Password", action: {
                showChangePassword = true
            })
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
                        .toggleStyle(SwitchToggleStyle(tint: Color.pinItPrimary))
                }
                .padding(.vertical, 4)
                
                HStack {
                    Text("Allow Tagging")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.pinItTextPrimary)
                    Spacer()
                    Toggle("", isOn: $allowTagging)
                        .toggleStyle(SwitchToggleStyle(tint: Color.pinItPrimary))
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
                        .toggleStyle(SwitchToggleStyle(tint: Color.pinItPrimary))
                }
                .padding(.vertical, 4)
                
                HStack {
                    Text("Show Activity Status")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.pinItTextPrimary)
                    Spacer()
                    Toggle("", isOn: $showActivityStatus)
                        .toggleStyle(SwitchToggleStyle(tint: Color.pinItPrimary))
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var supportSettings: some View {
        VStack(spacing: 12) {
            settingsButton(icon: "questionmark.circle", title: "Help Center", action: {
                // Open help center - could be in-app or external
                if let url = URL(string: "mailto:tom.besinger@icloud.com?subject=PinIt%20Help") {
                    UIApplication.shared.open(url)
                }
            })
            
            settingsButton(icon: "envelope", title: "Contact Support", action: {
                // Open support email
                if let url = URL(string: "mailto:tom.besinger@icloud.com?subject=PinIt%20Support") {
                    UIApplication.shared.open(url)
                }
            })
            
            settingsButton(icon: "hand.raised", title: "Privacy Policy", action: {
                selectedLegalDocument = .privacyPolicy
                showLegalDocuments = true
            })
            
            settingsButton(icon: "doc.text", title: "Terms of Service", action: {
                selectedLegalDocument = .termsOfService
                showLegalDocuments = true
            })
            
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
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(spacing: 20) {
            // Logo
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
            
            // App Name
            Text("PinIt")
                .font(.title2.bold())
                .foregroundColor(.textPrimary)
            
            // Tagline
            Text("Stop Scrolling. Start Living.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            
            Divider()
                .padding(.vertical, 8)
            
            // Version Info
            HStack {
                Text("Version")
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.textPrimary)
                    .fontWeight(.medium)
            }
            
            // Copyright
            Text("© 2025 PinIt Social. All rights reserved.")
                .font(.caption)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.bgCard)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    private var dangerZone: some View {
        VStack(spacing: 12) {
            settingsButton(icon: "arrow.right.square", title: "Logout", action: {
                showLogoutAlert = true
            })
            
            settingsButton(icon: "trash", title: "Delete Account", action: {
                showDeleteAlert = true
            })
        }
    }

    // MARK: - Delete Account
    private func deleteAccount() {
        guard let url = URL(string: APIConfig.fullURL(for: "deleteAccount")) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        accountManager.addAuthHeader(to: &request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    // Log out locally after successful deletion
                    isLoggedIn = false
                }
            }
        }.resume()
    }
    
    // MARK: - Legal Documents Sheet
    private var legalDocumentsSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Document Selector
                Picker("Document", selection: $selectedLegalDocument) {
                    ForEach(LegalDocumentType.allCases, id: \.self) { document in
                        Text(document.rawValue).tag(document)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.bgCard)
                
                // Document Content - Lazy loaded
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: selectedLegalDocument.icon)
                                .font(.system(size: 40))
                                .foregroundColor(.brandPrimary)
                            
                            Text(selectedLegalDocument.rawValue)
                                .font(.title.weight(.bold))
                                .foregroundColor(.textPrimary)
                            
                            Text("Last Updated: January 2025")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                        
                        // Content - Only render when needed
                        if selectedLegalDocument == .privacyPolicy {
                            Text(LegalDocumentType.privacyPolicyContent)
                                .font(.body)
                                .foregroundColor(.textPrimary)
                                .lineSpacing(4)
                                .padding(.horizontal, 20)
                        } else {
                            Text(LegalDocumentType.termsOfServiceContent)
                                .font(.body)
                                .foregroundColor(.textPrimary)
                                .lineSpacing(4)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .background(Color.bgSurface.ignoresSafeArea())
            .navigationTitle("Legal Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showLegalDocuments = false
                    }
                    .font(.headline)
                    .foregroundColor(.brandPrimary)
                }
            }
        }
    }
    
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(UserAccountManager())
}