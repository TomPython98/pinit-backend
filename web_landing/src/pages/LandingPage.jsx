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
              New in Town?
              <span className="gradient-text"> Meet People Tonight.</span>
            </h1>
            <p className="hero-description">
              The app for international students who are tired of sitting alone. 
              See what's happening right now on your campus. Join study groups, 
              parties, and cultural meetups in one tap.
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
                <div className="stat-number">3 sec</div>
                <div className="stat-label">To find an event</div>
              </div>
              <div className="stat">
                <div className="stat-number">Live</div>
                <div className="stat-label">See what's happening now</div>
              </div>
              <div className="stat">
                <div className="stat-number">Real</div>
                <div className="stat-label">Verified student hosts</div>
              </div>
            </div>
          </div>
        </div>
      </section>


      {/* Features Section */}
      <section className="features">
        <div className="container">
          <h2 className="section-title">Why International Students Love PinIt</h2>
          <div className="features-grid">
            <div className="feature-card">
              <div className="feature-icon">🗺️</div>
              <h3 className="feature-title">See What's Happening NOW</h3>
              <p className="feature-description">
                Open the map. See live events near you. Join in seconds. No endless scrolling through dead group chats.
              </p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">🎓</div>
              <h3 className="feature-title">Study Together, Not Alone</h3>
              <p className="feature-description">
                Find study groups for your courses. Library at 10PM? You're not the only one cramming.
              </p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">🌍</div>
              <h3 className="feature-title">Meet Other Internationals</h3>
              <p className="feature-description">
                Connect with students who get it. Language exchanges, cultural nights, or just grabbing coffee with someone who understands.
              </p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">🎉</div>
              <h3 className="feature-title">Don't Miss Out Anymore</h3>
              <p className="feature-description">
                That party everyone's talking about? You'll actually know about it before it happens.
              </p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">✅</div>
              <h3 className="feature-title">Safe & Verified</h3>
              <p className="feature-description">
                Hosts are verified students. See ratings. Know who you're meeting. Your safety matters.
              </p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">⚡</div>
              <h3 className="feature-title">One Tap to Join</h3>
              <p className="feature-description">
                See event. Tap RSVP. Done. No group chat politics. No wondering if you're actually invited. Just go.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="cta">
        <div className="container">
          <div className="cta-content">
            <h2 className="cta-title">Stop Scrolling. Start Living.</h2>
            <p className="cta-description">
              You didn't move abroad to sit in your dorm room. There's stuff happening right now near you.
            </p>
            <button 
              className="btn btn-large btn-primary"
              onClick={() => handleAuthClick('signup')}
            >
              Show Me What's Happening Tonight
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


