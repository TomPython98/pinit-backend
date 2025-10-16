import React from 'react'
import './TermsOfService.css'

const TermsOfService = () => {
  return (
    <div className="legal-page">
      <div className="legal-container">
        <header className="legal-header">
          <h1>Terms of Service</h1>
          <p className="effective-date">Effective Date: January 2025</p>
        </header>

        <div className="legal-content">
          <section>
            <h2>1. Acceptance of Terms</h2>
            <p>
              By downloading, installing, or using the PinIt mobile application ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.
            </p>
          </section>

          <section>
            <h2>2. Description of Service</h2>
            <p>
              PinIt is a social networking platform that connects students and professionals for study groups, events, and networking opportunities. The App allows users to:
            </p>
            <ul>
              <li>Create and join study events</li>
              <li>Connect with other users</li>
              <li>Share location-based information</li>
              <li>Communicate through chat features</li>
              <li>Rate and review other users</li>
            </ul>
          </section>

          <section>
            <h2>3. User Eligibility</h2>
            <ul>
              <li>You must be at least 13 years old to use PinIt</li>
              <li>Users under 18 must have parental consent</li>
              <li>You must provide accurate and complete information</li>
              <li>You are responsible for maintaining account security</li>
            </ul>
          </section>

          <section>
            <h2>4. User Conduct</h2>
            <p><strong>Prohibited Activities:</strong></p>
            <ul>
              <li>Harassment, bullying, or threatening behavior</li>
              <li>Sharing inappropriate, offensive, or illegal content</li>
              <li>Impersonating others or providing false information</li>
              <li>Spamming or unsolicited communications</li>
              <li>Violating others' privacy or intellectual property rights</li>
              <li>Using the App for commercial purposes without permission</li>
            </ul>
          </section>

          <section>
            <h2>5. Content and Intellectual Property</h2>
            <ul>
              <li>You retain ownership of content you create</li>
              <li>You grant PinIt a license to use your content for App functionality</li>
              <li>PinIt respects intellectual property rights</li>
              <li>Report copyright violations to: <a href="mailto:tom.besinger@icloud.com">tom.besinger@icloud.com</a></li>
            </ul>
          </section>

          <section>
            <h2>6. Privacy and Data</h2>
            <ul>
              <li>Your privacy is important to us</li>
              <li>See our <a href="/privacy-policy">Privacy Policy</a> for data handling details</li>
              <li>We collect location data for event discovery</li>
              <li>We may use analytics to improve the App</li>
            </ul>
          </section>

          <section>
            <h2>7. Location Services</h2>
            <ul>
              <li>PinIt requires location access for core functionality</li>
              <li>Location data is used to show nearby events</li>
              <li>You can disable location services in device settings</li>
              <li>Location data is not shared with third parties</li>
            </ul>
          </section>

          <section>
            <h2>8. Termination</h2>
            <ul>
              <li>You may delete your account at any time</li>
              <li>We may suspend or terminate accounts for violations</li>
              <li>Termination does not affect your liability for past actions</li>
            </ul>
          </section>

          <section>
            <h2>9. Disclaimers</h2>
            <p>
              PinIt is provided "as is" without warranties. We do not guarantee the App will be error-free or uninterrupted. Use at your own risk.
            </p>
          </section>

          <section>
            <h2>10. Limitation of Liability</h2>
            <p>
              To the maximum extent permitted by law, PinIt shall not be liable for any indirect, incidental, special, or consequential damages.
            </p>
          </section>

          <section>
            <h2>11. Changes to Terms</h2>
            <p>
              We may update these Terms at any time. Continued use of the App after changes constitutes acceptance of new Terms.
            </p>
          </section>

          <section>
            <h2>12. Contact Information</h2>
            <p>
              For questions about these Terms, contact us at:
            </p>
            <ul>
              <li>Email: <a href="mailto:tom.besinger@icloud.com">tom.besinger@icloud.com</a></li>
              <li>Subject Line: "Terms of Service Inquiry"</li>
            </ul>
          </section>

          <section>
            <h2>13. Governing Law</h2>
            <p>
              These Terms are governed by the laws of the jurisdiction where PinIt operates, without regard to conflict of law principles.
            </p>
          </section>

          <section>
            <h2>14. Severability</h2>
            <p>
              If any provision of these Terms is found to be unenforceable, the remaining provisions will remain in full force and effect.
            </p>
          </section>

          <section>
            <h2>15. Entire Agreement</h2>
            <p>
              These Terms, together with our Privacy Policy, constitute the entire agreement between you and PinIt regarding the use of the App.
            </p>
          </section>
        </div>

        <footer className="legal-footer">
          <p>Last Updated: January 2025 | Version: 2.0</p>
          <p>
            This Terms of Service is effective as of the date listed above and will remain in effect except with respect to any changes in its provisions in the future, which will be in effect immediately after being posted in the App.
          </p>
        </footer>
      </div>
    </div>
  )
}

export default TermsOfService
