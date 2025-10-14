import React, { useState, useEffect } from 'react'
import { eventAPI, userAPI, invitationAPI } from '../services/api'
import './Dashboard.css'

const Dashboard = ({ user, onLogout }) => {
  const [profile, setProfile] = useState(null)
  const [events, setEvents] = useState([])
  const [invitations, setInvitations] = useState([])
  const [publicEvents, setPublicEvents] = useState([])
  const [selectedEvent, setSelectedEvent] = useState(null)
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState('discover')

  useEffect(() => {
    loadData()
  }, [user])

  const loadData = async () => {
    try {
      setLoading(true)
      
      // Load user profile, events, invitations, and public events in parallel
      const [profileRes, eventsRes, invitationsRes, publicEventsRes] = await Promise.all([
        userAPI.getProfile(user.username).catch(() => null),
        eventAPI.getEvents(user.username).catch(() => ({ events: [] })),
        invitationAPI.getInvitations(user.username).catch(() => ({ invitations: [] })),
        eventAPI.searchEvents({ is_public: true }).catch(() => ({ events: [] }))
      ])

      if (profileRes) {
        setProfile(profileRes)
      }
      
      if (eventsRes && eventsRes.events) {
        setEvents(eventsRes.events)
      }
      
      if (invitationsRes && invitationsRes.invitations) {
        setInvitations(invitationsRes.invitations)
      }
      
      if (publicEventsRes && publicEventsRes.events) {
        setPublicEvents(publicEventsRes.events)
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

  const handleAcceptInvitation = async (eventId) => {
    try {
      await eventAPI.rsvpEvent(eventId)
      loadData()
      setSelectedEvent(null)
      alert('🎉 You\'re going!\n\nNow download the app to:\n• See exact meeting location on map\n• Chat with everyone attending\n• Get reminded before it starts\n\nDon\'t be that person who shows up to the wrong place.')
    } catch (error) {
      console.error('Error accepting invitation:', error)
      alert('Failed to accept invitation. Please try again.')
    }
  }

  const handleDeclineInvitation = async (eventId) => {
    try {
      await invitationAPI.declineInvitation({ event_id: eventId })
      loadData()
      setSelectedEvent(null)
      alert('Invitation declined.')
    } catch (error) {
      console.error('Error declining invitation:', error)
      alert('Failed to decline invitation. Please try again.')
    }
  }

  const handleRSVP = async (eventId) => {
    try {
      await eventAPI.rsvpEvent(eventId)
      loadData()
      setSelectedEvent(null)
      alert('✅ See you there!\n\nQuick tip: Download the app so you can:\n• See who else is going (maybe someone from your classes?)\n• Get the exact pin location\n• Chat in the group\n• Know if plans change\n\nThis web version is cool, but you\'re missing out on the good stuff.')
    } catch (error) {
      console.error('Error RSVPing:', error)
      alert(error.response?.data?.error || 'Failed to RSVP. Please try again.')
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
              Hey <span className="gradient-text">{user.username}</span>, what's happening tonight?
            </h1>
            <p className="welcome-subtitle">
              Browse events, accept invitations, or download the app to create your own meetups
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
              <div className="stat-icon">📨</div>
              <div className="stat-info">
                <div className="stat-value">{invitations.length}</div>
                <div className="stat-label">Invitations</div>
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

          {/* Navigation Tabs */}
          <div className="tabs">
            <button 
              className={`tab ${activeTab === 'discover' ? 'active' : ''}`}
              onClick={() => setActiveTab('discover')}
            >
              🔥 Discover Events ({publicEvents.length})
            </button>
            <button 
              className={`tab ${activeTab === 'invitations' ? 'active' : ''}`}
              onClick={() => setActiveTab('invitations')}
            >
              📨 Invitations {invitations.length > 0 && `(${invitations.length})`}
            </button>
            <button 
              className={`tab ${activeTab === 'events' ? 'active' : ''}`}
              onClick={() => setActiveTab('events')}
            >
              📅 My Events ({events.length})
            </button>
          </div>

          {/* Tab Content */}
          {activeTab === 'discover' && (
            <>
              <section className="discover-header">
                <div className="discover-title-section">
                  <h2 className="section-title">What's Happening Right Now</h2>
                  <p className="discover-subtitle">
                    Live events near you. Tap to join. Want to host? Download the app.
                  </p>
                </div>
                <button 
                  className="btn btn-primary"
                  onClick={() => alert('📱 Want to organize something?\n\nDownload the app to:\n• Drop a pin on the map\n• Set your vibe (study, party, cultural)\n• Invite people instantly\n• Chat with your group\n\nBe the one who makes plans, not the one waiting for them.')}
                >
                  ➕ Host an Event (Download App)
                </button>
              </section>
              
              <section className="events-section">
                {publicEvents.length > 0 ? (
                  <div className="events-grid">
                    {publicEvents.map((event) => (
                      <div 
                        key={event.id} 
                        className="event-card clickable"
                        onClick={() => setSelectedEvent(event)}
                      >
                        <div className="event-badge">PUBLIC</div>
                        <div className="event-icon">
                          {getEventIcon(event.category || event.event_type)}
                        </div>
                        <h3 className="event-name">{event.title || event.name}</h3>
                        <p className="event-description">
                          {event.description || 'No description'}
                        </p>
                        <div className="event-meta">
                          <span className="event-date">
                            📅 {formatDate(event.time || event.date || event.created_at)}
                          </span>
                          <span className="event-location">
                            📍 {event.location || 'Location TBD'}
                          </span>
                          <span className="event-attendees">
                            👥 {event.attendee_count || 0} going
                          </span>
                        </div>
                        <button className="btn btn-primary btn-full btn-small">
                          View Details →
                        </button>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="empty-state">
                    <div className="empty-icon">🤔</div>
                    <h2>Nothing happening yet?</h2>
                    <p>Be the one who starts something. Download the app and create the first event on your campus.</p>
                    <button className="btn btn-primary" onClick={() => alert('📱 Download PinIt\n\nDon\'t wait for someone else to organize. Take 30 seconds to create a study group, coffee meetup, or party.\n\nYour future friends are waiting for someone to make the first move.')}>
                      📱 I'll Start Something
                    </button>
                  </div>
                )}
              </section>
            </>
          )}

          {activeTab === 'invitations' && (
            <section className="invitations-section">
              <h2 className="section-title">Event Invitations</h2>
              {invitations.length > 0 ? (
                <div className="invitations-grid">
                  {invitations.map((invitation) => (
                    <div key={invitation.id} className="invitation-card">
                      <div className="invitation-icon">
                        {getEventIcon(invitation.event_type || invitation.category)}
                      </div>
                      <h3 className="invitation-title">{invitation.title || invitation.name}</h3>
                      <p className="invitation-description">
                        {invitation.description || 'No description'}
                      </p>
                      <div className="invitation-meta">
                        <span className="invitation-date">
                          📅 {formatDate(invitation.date || invitation.created_at)}
                        </span>
                        <span className="invitation-location">
                          📍 {invitation.location || 'Location TBD'}
                        </span>
                        <span className="invitation-host">
                          👤 Host: {invitation.host}
                        </span>
                      </div>
                      <div className="invitation-actions">
                        <button 
                          className="btn btn-primary btn-small"
                          onClick={() => handleAcceptInvitation(invitation.id)}
                        >
                          ✅ Accept
                        </button>
                        <button 
                          className="btn btn-outline btn-small"
                          onClick={() => handleDeclineInvitation(invitation.id)}
                        >
                          ❌ Decline
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="empty-state">
                  <div className="empty-icon">👀</div>
                  <h2>No invitations yet</h2>
                  <p>Check the Discover tab to find events happening now. Or download the app to get invited to private meetups.</p>
                </div>
              )}
            </section>
          )}

          {activeTab === 'events' && (
            <section className="events-section">
              <h2 className="section-title">Your Events</h2>
              {events.length > 0 ? (
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
              ) : (
                <div className="empty-state">
                  <div className="empty-icon">🎯</div>
                  <h2>Your calendar is empty</h2>
                  <p>Go to Discover to find something happening tonight. Or download the app to organize your own.</p>
                </div>
              )}
            </section>
          )}

        </div>
      </main>

      {/* Event Details Modal */}
      {selectedEvent && (
        <div className="modal-overlay" onClick={() => setSelectedEvent(null)}>
          <div className="event-modal" onClick={(e) => e.stopPropagation()}>
            <button className="modal-close" onClick={() => setSelectedEvent(null)}>
              ×
            </button>
            
            <div className="event-modal-header">
              <div className="event-modal-icon">
                {getEventIcon(selectedEvent.category || selectedEvent.event_type)}
              </div>
              <h2 className="event-modal-title">{selectedEvent.title || selectedEvent.name}</h2>
              {selectedEvent.is_public && <span className="event-badge">PUBLIC</span>}
            </div>

            <div className="event-modal-body">
              <div className="event-modal-section">
                <h3>📝 Description</h3>
                <p>{selectedEvent.description || 'No description provided'}</p>
              </div>

              <div className="event-modal-section">
                <h3>📅 When</h3>
                <p>{formatDate(selectedEvent.time || selectedEvent.date || selectedEvent.created_at)}</p>
                {selectedEvent.end_time && <p>Until: {formatDate(selectedEvent.end_time)}</p>}
              </div>

              <div className="event-modal-section">
                <h3>📍 Where</h3>
                <p>{selectedEvent.location || 'Location to be announced'}</p>
                <p className="app-cta-text">💡 Download the app to see exact location on map</p>
              </div>

              <div className="event-modal-section">
                <h3>👤 Host</h3>
                <p>{selectedEvent.host}</p>
                {selectedEvent.host_is_certified && <span className="cert-badge">✅ Verified</span>}
              </div>

              <div className="event-modal-section">
                <h3>👥 Attendees</h3>
                <p>{selectedEvent.attendee_count || 0} people going</p>
                <p className="app-cta-text">💡 Download the app to see who's attending and chat with them</p>
              </div>

              {selectedEvent.event_type && (
                <div className="event-modal-section">
                  <h3>🏷️ Type</h3>
                  <p>{selectedEvent.event_type}</p>
                </div>
              )}
            </div>

            <div className="event-modal-footer">
              <button 
                className="btn btn-primary btn-large btn-full"
                onClick={() => handleRSVP(selectedEvent.id)}
              >
                ✅ RSVP - I'm Going!
              </button>
              <p className="app-reminder">
                📱 <strong>Want the real thing?</strong> Download the app to see exact locations on the map, chat with everyone going, and get notified when plans change. This is just the preview.
              </p>
            </div>
          </div>
        </div>
      )}
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


