import React, { useState, useEffect } from 'react'
import { eventAPI, userAPI } from '../services/api'
import './Dashboard.css'

const Dashboard = ({ user, onLogout }) => {
  const [profile, setProfile] = useState(null)
  const [events, setEvents] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadData()
  }, [user])

  const loadData = async () => {
    try {
      setLoading(true)
      
      // Load user profile and events in parallel
      const [profileRes, eventsRes] = await Promise.all([
        userAPI.getProfile(user.username).catch(() => null),
        eventAPI.getEvents(user.username).catch(() => ({ events: [] }))
      ])

      if (profileRes) {
        setProfile(profileRes)
      }
      
      if (eventsRes && eventsRes.events) {
        setEvents(eventsRes.events)
      }
    } catch (error) {
      console.error('Error loading data:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleLogout = () => {
    if (window.confirm('Are you sure you want to logout?')) {
      onLogout()
    }
  }

  if (loading) {
    return (
      <div className="dashboard">
        <div className="loading-container">
          <div className="spinner"></div>
          <p>Loading your dashboard...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="dashboard">
      {/* Header */}
      <header className="dashboard-header">
        <div className="container">
          <div className="dashboard-nav">
            <div className="logo">
              <span className="logo-icon">📍</span>
              <span className="logo-text">PinIt</span>
            </div>
            <div className="user-menu">
              <span className="username">@{user.username}</span>
              <button className="btn btn-ghost btn-small" onClick={handleLogout}>
                Logout
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="dashboard-main">
        <div className="container">
          {/* Welcome Section */}
          <section className="welcome-section">
            <h1 className="welcome-title">
              Welcome back, <span className="gradient-text">{user.username}</span>!
            </h1>
            <p className="welcome-subtitle">
              Ready to discover new events and connect with amazing people?
            </p>
          </section>

          {/* Stats Cards */}
          <div className="stats-grid">
            <div className="stat-card">
              <div className="stat-icon">📅</div>
              <div className="stat-info">
                <div className="stat-value">{events.length}</div>
                <div className="stat-label">Your Events</div>
              </div>
            </div>
            <div className="stat-card">
              <div className="stat-icon">👥</div>
              <div className="stat-info">
                <div className="stat-value">{profile?.friends_count || 0}</div>
                <div className="stat-label">Friends</div>
              </div>
            </div>
            <div className="stat-card">
              <div className="stat-icon">⭐</div>
              <div className="stat-info">
                <div className="stat-value">{profile?.trust_level || 'New'}</div>
                <div className="stat-label">Trust Level</div>
              </div>
            </div>
          </div>

          {/* Download App Section */}
          <section className="app-download-section">
            <div className="app-download-card">
              <div className="app-download-icon">📱</div>
              <div className="app-download-content">
                <h2>Get the Full Experience</h2>
                <p>Download the PinIt mobile app for iOS to unlock all features including:</p>
                <ul className="features-list">
                  <li>✓ Interactive map view to discover nearby events</li>
                  <li>✓ Real-time notifications for event updates</li>
                  <li>✓ Create and manage events on the go</li>
                  <li>✓ Chat with friends and event attendees</li>
                  <li>✓ Advanced search and filtering</li>
                </ul>
                <div className="download-buttons">
                  <button className="btn btn-primary btn-large">
                    🍎 Download for iOS
                  </button>
                  <button className="btn btn-outline btn-large" disabled>
                    🤖 Android (Coming Soon)
                  </button>
                </div>
              </div>
            </div>
          </section>

          {/* Recent Events */}
          {events.length > 0 && (
            <section className="events-section">
              <h2 className="section-title">Your Recent Events</h2>
              <div className="events-grid">
                {events.slice(0, 6).map((event) => (
                  <div key={event.id} className="event-card">
                    <div className="event-icon">
                      {getEventIcon(event.category || event.event_type)}
                    </div>
                    <h3 className="event-name">{event.title || event.name}</h3>
                    <p className="event-description">
                      {event.description || 'No description'}
                    </p>
                    <div className="event-meta">
                      <span className="event-date">
                        📅 {formatDate(event.date || event.created_at)}
                      </span>
                      <span className="event-location">
                        📍 {event.location || 'Location TBD'}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </section>
          )}

          {events.length === 0 && (
            <section className="empty-state">
              <div className="empty-icon">📭</div>
              <h2>No Events Yet</h2>
              <p>Download the mobile app to start creating and discovering events!</p>
            </section>
          )}
        </div>
      </main>
    </div>
  )
}

// Helper functions
const getEventIcon = (category) => {
  const icons = {
    'Study': '📚',
    'Social': '🎉',
    'Academic': '🎓',
    'Party': '🎊',
    'Networking': '🤝',
    'Cultural': '🎭',
    'Business': '💼',
    'Language_Exchange': '🗣️',
    'Other': '🌟'
  }
  return icons[category] || '📌'
}

const formatDate = (dateString) => {
  if (!dateString) return 'TBD'
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', { 
    month: 'short', 
    day: 'numeric',
    year: 'numeric'
  })
}

export default Dashboard


