import React from 'react'
import './PrivacyPolicy.css'

const PrivacyPolicy = () => {
  return (
    <div className="legal-page">
      <div className="legal-container">
        <header className="legal-header">
          <h1>Privacy Policy</h1>
          <p className="effective-date">Effective Date: January 2025</p>
        </header>

        <div className="legal-content">
          <section>
            <h2>1. Introduction</h2>
            <p>
              PinIt ("we," "our," or "us") respects your privacy and is committed to protecting your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.
            </p>
          </section>

          <section>
            <h2>2. Information We Collect</h2>
            
            <h3>2.1 Account Information</h3>
            <ul>
              <li>Name and Email: For account creation and communication</li>
              <li>Profile Information: University, degree, year, bio, interests, skills</li>
              <li>Authentication Data: Username and encrypted password</li>
            </ul>

            <h3>2.2 Location Data</h3>
            <ul>
              <li>Precise Location: For event creation and discovery (when permission granted)</li>
              <li>Approximate Location: For map-based features and nearby event suggestions</li>
              <li>Location History: Temporarily stored for event recommendations</li>
            </ul>

            <h3>2.3 Content Data</h3>
            <ul>
              <li>Photos and Videos: Uploaded for profiles and events</li>
              <li>Messages: Sent in group chats and direct messages</li>
              <li>Event Descriptions: Created by users</li>
              <li>Reviews and Ratings: User-generated content</li>
            </ul>

            <h3>2.4 Technical Data</h3>
            <ul>
              <li>Device Information: Device type, operating system, app version</li>
              <li>Usage Analytics: App interactions, features used, session duration</li>
              <li>Error Logs: Technical issues and crash reports</li>
              <li>Network Information: IP address, connection type</li>
            </ul>
          </section>

          <section>
            <h2>3. How We Use Your Information</h2>
            
            <h3>3.1 Service Provision</h3>
            <ul>
              <li>Account Management: Creating and maintaining user accounts</li>
              <li>Event Matching: Connecting users with relevant events</li>
              <li>Location Services: Showing nearby events and users</li>
              <li>Communication: Enabling chat and messaging features</li>
            </ul>

            <h3>3.2 Personalization</h3>
            <ul>
              <li>Recommendations: Suggesting relevant events and connections</li>
              <li>Customization: Tailoring the app experience to your preferences</li>
              <li>Notifications: Sending relevant updates and alerts</li>
            </ul>

            <h3>3.3 Analytics and Improvement</h3>
            <ul>
              <li>App Performance: Monitoring and improving app functionality</li>
              <li>User Experience: Understanding how users interact with features</li>
              <li>Feature Development: Creating new features based on usage patterns</li>
            </ul>
          </section>

          <section>
            <h2>4. Information Sharing</h2>
            
            <h3>4.1 With Other Users</h3>
            <ul>
              <li>Profile Information: Visible to other users as per your privacy settings</li>
              <li>Event Participation: Your attendance at events may be visible</li>
              <li>Reviews and Ratings: Your feedback on events and users</li>
            </ul>

            <h3>4.2 With Service Providers</h3>
            <ul>
              <li>Cloud Storage: Secure data storage and backup</li>
              <li>Analytics Services: Understanding app usage (anonymized data)</li>
              <li>Push Notifications: Delivering messages and updates</li>
            </ul>

            <h3>4.3 Legal Requirements</h3>
            <ul>
              <li>Law Enforcement: When required by law or legal process</li>
              <li>Safety: To protect users and prevent harm</li>
              <li>Legal Compliance: Meeting regulatory requirements</li>
            </ul>
          </section>

          <section>
            <h2>5. Data Security</h2>
            
            <h3>5.1 Technical Safeguards</h3>
            <ul>
              <li>Encryption: Data encrypted in transit and at rest</li>
              <li>Access Controls: Limited access to personal information</li>
              <li>Regular Audits: Security assessments and updates</li>
            </ul>

            <h3>5.2 Administrative Safeguards</h3>
            <ul>
              <li>Staff Training: Privacy and security awareness</li>
              <li>Data Minimization: Collecting only necessary information</li>
              <li>Retention Policies: Deleting data when no longer needed</li>
            </ul>
          </section>

          <section>
            <h2>6. Your Rights and Choices</h2>
            
            <h3>6.1 Access and Control</h3>
            <ul>
              <li>View Data: Access your personal information</li>
              <li>Update Information: Modify your profile and preferences</li>
              <li>Delete Account: Remove your account and data</li>
              <li>Data Portability: Export your data</li>
            </ul>

            <h3>6.2 Privacy Settings</h3>
            <ul>
              <li>Profile Visibility: Control who can see your information</li>
              <li>Location Sharing: Manage location data sharing</li>
              <li>Notifications: Customize notification preferences</li>
              <li>Data Collection: Opt out of certain data collection</li>
            </ul>
          </section>

          <section>
            <h2>7. Data Retention</h2>
            <ul>
              <li>Account Data: Retained while your account is active</li>
              <li>Messages: Stored for functionality, deleted upon account deletion</li>
              <li>Analytics Data: Anonymized and retained for improvement purposes</li>
              <li>Legal Requirements: Some data retained for compliance</li>
            </ul>
          </section>

          <section>
            <h2>8. Children's Privacy</h2>
            <ul>
              <li>Age Requirement: Users must be at least 13 years old</li>
              <li>Parental Consent: Required for users under 18</li>
              <li>No Collection: We do not knowingly collect data from children under 13</li>
              <li>Removal: Contact us to remove any child's data</li>
            </ul>
          </section>

          <section>
            <h2>9. International Data Transfers</h2>
            <ul>
              <li>Global Service: Data may be processed in different countries</li>
              <li>Adequate Protection: Appropriate safeguards for international transfers</li>
              <li>Compliance: Meeting local data protection requirements</li>
            </ul>
          </section>

          <section>
            <h2>10. Third-Party Services</h2>
            <ul>
              <li>External Links: Our app may contain links to third-party websites</li>
              <li>No Control: We are not responsible for third-party privacy practices</li>
              <li>Review Policies: Check third-party privacy policies before sharing data</li>
            </ul>
          </section>

          <section>
            <h2>11. Changes to This Policy</h2>
            <ul>
              <li>Updates: We may update this Privacy Policy periodically</li>
              <li>Notification: Users will be notified of significant changes</li>
              <li>Continued Use: Using the app after changes constitutes acceptance</li>
              <li>Version History: Previous versions available upon request</li>
            </ul>
          </section>

          <section>
            <h2>12. Contact Information</h2>
            
            <h3>12.1 Privacy Questions</h3>
            <ul>
              <li>Email: <a href="mailto:tom.besinger@icloud.com">tom.besinger@icloud.com</a></li>
              <li>Subject Line: "Privacy Policy Inquiry"</li>
              <li>Response Time: Within 30 days</li>
            </ul>

            <h3>12.2 Data Protection Officer</h3>
            <ul>
              <li>Contact: <a href="mailto:tom.besinger@icloud.com">tom.besinger@icloud.com</a></li>
              <li>Purpose: Privacy and data protection matters</li>
              <li>Languages: English and Spanish</li>
            </ul>
          </section>

          <section>
            <h2>13. Regional Variations</h2>
            
            <h3>13.1 European Union (GDPR)</h3>
            <ul>
              <li>Enhanced Rights: Additional data protection rights</li>
              <li>Lawful Basis: Clear legal grounds for processing</li>
              <li>Data Protection Impact: Assessments for high-risk processing</li>
            </ul>

            <h3>13.2 California (CCPA)</h3>
            <ul>
              <li>Consumer Rights: Access, deletion, and opt-out rights</li>
              <li>Non-Discrimination: No penalties for exercising rights</li>
              <li>Disclosure: Clear information about data practices</li>
            </ul>
          </section>

          <section>
            <h2>14. Complaints and Disputes</h2>
            
            <h3>14.1 Resolution Process</h3>
            <ul>
              <li>Direct Contact: First attempt to resolve directly</li>
              <li>Mediation: Third-party mediation if needed</li>
              <li>Regulatory: Contact relevant data protection authority</li>
            </ul>

            <h3>14.2 Supervisory Authority</h3>
            <ul>
              <li>EU Users: Contact local data protection authority</li>
              <li>Other Regions: Relevant privacy regulator</li>
              <li>App Store: Report through Apple's App Store</li>
            </ul>
          </section>
        </div>

        <footer className="legal-footer">
          <p>Last Updated: January 2025 | Version: 2.0</p>
          <p>
            This Privacy Policy is effective as of the date listed above and will remain in effect except with respect to any changes in its provisions in the future, which will be in effect immediately after being posted in the App.
          </p>
        </footer>
      </div>
    </div>
  )
}

export default PrivacyPolicy
