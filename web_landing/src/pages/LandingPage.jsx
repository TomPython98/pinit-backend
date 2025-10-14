import React, { useState } from 'react'
import AuthModal from '../components/AuthModal'
import './LandingPage.css'

const LandingPage = ({ onLogin }) => {
  const [showAuth, setShowAuth] = useState(false)
  const [authMode, setAuthMode] = useState('signup') // 'signup' or 'login'

  const handleAuthClick = (mode) => {
    setAuthMode(mode)
    setShowAuth(true)
  }

  return (
    <div className="landing-page">
      {/* Header */}
      <header className="header">
        <div className="container">
          <nav className="nav">
            <div className="logo">
              <span className="logo-icon">📍</span>
              <span className="logo-text">PinIt</span>
            </div>
            <div className="nav-buttons">
              <button 
                className="btn btn-ghost" 
                onClick={() => handleAuthClick('login')}
              >
                Log In
              </button>
              <button 
                className="btn btn-primary" 
                onClick={() => handleAuthClick('signup')}
              >
                Sign Up
              </button>
            </div>
          </nav>
        </div>
      </header>

      {/* Hero Section */}
      <section className="hero">
        <div className="container">
          <div className="hero-content fade-in">
            <h1 className="hero-title">
              Connect, Meet, and Make
              <span className="gradient-text"> Memories</span>
            </h1>
            <p className="hero-description">
              Join PinIt to discover and create amazing events near you. 
              Connect with like-minded people and make every moment count.
            </p>
            <div className="hero-buttons">
              <button 
                className="btn btn-large btn-primary"
                onClick={() => handleAuthClick('signup')}
              >
                Get Started
              </button>
              <button className="btn btn-large btn-outline">
                Learn More
              </button>
            </div>
            <div className="hero-stats">
              <div className="stat">
                <div className="stat-number">10K+</div>
                <div className="stat-label">Active Users</div>
              </div>
              <div className="stat">
                <div className="stat-number">50K+</div>
                <div className="stat-label">Events Created</div>
              </div>
              <div className="stat">
                <div className="stat-number">100+</div>
                <div className="stat-label">Cities</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="features">
        <div className="container">
          <h2 className="section-title">Why Choose PinIt?</h2>
          <div className="features-grid">
            <div className="feature-card">
              <div className="feature-icon">🗺️</div>
              <h3 className="feature-title">Discover Events</h3>
              <p className="feature-description">
                Find interesting events happening around you on an interactive map
              </p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">👥</div>
              <h3 className="feature-title">Connect with People</h3>
              <p className="feature-description">
                Meet new friends who share your interests and passions
              </p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">📅</div>
              <h3 className="feature-title">Create Events</h3>
              <p className="feature-description">
                Organize your own events and invite others to join
              </p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">⭐</div>
              <h3 className="feature-title">Build Reputation</h3>
              <p className="feature-description">
                Gain trust and reputation through positive interactions
              </p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">🔔</div>
              <h3 className="feature-title">Stay Updated</h3>
              <p className="feature-description">
                Get notified about events and friend requests
              </p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">🌍</div>
              <h3 className="feature-title">Global Community</h3>
              <p className="feature-description">
                Connect with people from around the world
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="cta">
        <div className="container">
          <div className="cta-content">
            <h2 className="cta-title">Ready to Get Started?</h2>
            <p className="cta-description">
              Join thousands of users already making connections on PinIt
            </p>
            <button 
              className="btn btn-large btn-primary"
              onClick={() => handleAuthClick('signup')}
            >
              Create Your Account
            </button>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="footer">
        <div className="container">
          <div className="footer-content">
            <div className="footer-section">
              <div className="logo">
                <span className="logo-icon">📍</span>
                <span className="logo-text">PinIt</span>
              </div>
              <p className="footer-text">
                Making real-world connections easier, one event at a time.
              </p>
            </div>
            <div className="footer-section">
              <h4>Product</h4>
              <ul className="footer-links">
                <li><a href="#features">Features</a></li>
                <li><a href="#about">About</a></li>
                <li><a href="#pricing">Pricing</a></li>
              </ul>
            </div>
            <div className="footer-section">
              <h4>Company</h4>
              <ul className="footer-links">
                <li><a href="#careers">Careers</a></li>
                <li><a href="#blog">Blog</a></li>
                <li><a href="#contact">Contact</a></li>
              </ul>
            </div>
            <div className="footer-section">
              <h4>Legal</h4>
              <ul className="footer-links">
                <li><a href="#privacy">Privacy</a></li>
                <li><a href="#terms">Terms</a></li>
                <li><a href="#security">Security</a></li>
              </ul>
            </div>
          </div>
          <div className="footer-bottom">
            <p>&copy; 2025 PinIt. All rights reserved.</p>
          </div>
        </div>
      </footer>

      {/* Auth Modal */}
      {showAuth && (
        <AuthModal
          mode={authMode}
          onClose={() => setShowAuth(false)}
          onLogin={onLogin}
          onSwitchMode={() => setAuthMode(authMode === 'login' ? 'signup' : 'login')}
        />
      )}
    </div>
  )
}

export default LandingPage


