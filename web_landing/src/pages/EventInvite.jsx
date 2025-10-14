import React, { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { eventAPI } from '../services/api'
import AuthModal from '../components/AuthModal'
import './EventInvite.css'

const EventInvite = ({ user, onLogin }) => {
  const { eventId } = useParams()
  const navigate = useNavigate()
  const [event, setEvent] = useState(null)
  const [loading, setLoading] = useState(true)
  const [showAuth, setShowAuth] = useState(false)
  const [authMode, setAuthMode] = useState('signup')
  const [error, setError] = useState(null)

  useEffect(() => {
    loadEvent()
  }, [eventId])

  const loadEvent = async () => {
    try {
      setLoading(true)
      // Try to get event details from search (public events)
      const response = await eventAPI.searchEvents({ is_public: true })
      const foundEvent = response.events?.find(e => e.id === eventId)
      
      if (foundEvent) {
        setEvent(foundEvent)
      } else {
        setError('Event not found or is private')
      }
    } catch (err) {
      console.error('Error loading event:', err)
      setError('Failed to load event')
    } finally {
      setLoading(false)
    }
  }

  const handleRSVP = async () => {
    if (!user) {
      setShowAuth(true)
      return
    }

    try {
      await eventAPI.rsvpEvent(eventId)
      alert('✅ You\'re going!\n\nDownload the app to:\n• See exact location\n• Chat with attendees\n• Get reminded before it starts')
      navigate('/dashboard')
    } catch (error) {
      console.error('Error RSVPing:', error)
      alert(error.response?.data?.error || 'Failed to RSVP. Please try again.')
    }
  }

  const handleAuthSuccess = async (userData) => {
    onLogin(userData)
    setShowAuth(false)
    // Auto-RSVP after signup
    try {
      await eventAPI.rsvpEvent(eventId)
      alert('🎉 Account created AND you\'re going to this event!\n\nDownload the app to get the full experience.')
      navigate('/dashboard')
    } catch (error) {
      console.error('Error auto-RSVPing:', error)
      navigate('/dashboard')
    }
  }

  const formatDate = (dateString) => {
    if (!dateString) return 'TBD'
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', { 
      weekday: 'long',
      month: 'long', 
      day: 'numeric',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

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

  if (loading) {
    return (
      <div className="event-invite-page">
        <div className="loading-container">
          <div className="spinner"></div>
          <p>Loading event...</p>
        </div>
      </div>
    )
  }

  if (error || !event) {
    return (
      <div className="event-invite-page">
        <div className="error-container">
          <div className="error-icon">😕</div>
          <h1>Event Not Found</h1>
          <p>{error || 'This event might be private or no longer available.'}</p>
          <button className="btn btn-primary" onClick={() => navigate('/')}>
            Browse Other Events
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="event-invite-page">
      <div className="event-invite-container">
        <div className="event-invite-header">
          <div className="event-large-icon">
            {getEventIcon(event.category || event.event_type)}
          </div>
          <h1 className="event-invite-title">{event.title || event.name}</h1>
          {event.is_public && <span className="public-badge">PUBLIC EVENT</span>}
        </div>

        <div className="event-invite-body">
          <div className="invite-section">
            <h2>📝 What's happening</h2>
            <p>{event.description || 'No description provided'}</p>
          </div>

          <div className="invite-section">
            <h2>📅 When</h2>
            <p className="highlight">{formatDate(event.time || event.date || event.created_at)}</p>
          </div>

          <div className="invite-section">
            <h2>📍 Where</h2>
            <p className="highlight">{event.location || 'Location will be shared with attendees'}</p>
            {!user && (
              <p className="app-hint">💡 Sign up to see exact location</p>
            )}
          </div>

          <div className="invite-section">
            <h2>👤 Hosted by</h2>
            <p className="highlight">
              {event.host}
              {event.host_is_certified && <span className="verified-badge">✅ Verified</span>}
            </p>
          </div>

          <div className="invite-section">
            <h2>👥 Who's going</h2>
            <p className="highlight">{event.attendee_count || 0} people confirmed</p>
            {!user && (
              <p className="app-hint">💡 Sign up to see who else is going</p>
            )}
          </div>
        </div>

        <div className="event-invite-footer">
          {user ? (
            <>
              <button className="btn btn-primary btn-huge" onClick={handleRSVP}>
                ✅ I'm Going!
              </button>
              <p className="footer-hint">
                Tap to confirm. Then download the app to chat with everyone attending.
              </p>
            </>
          ) : (
            <>
              <h3 className="join-prompt">Want to join?</h3>
              <p className="join-subtitle">Create a free account to RSVP and meet everyone going</p>
              <button 
                className="btn btn-primary btn-huge" 
                onClick={() => { setAuthMode('signup'); setShowAuth(true); }}
              >
                Sign Up & Join This Event
              </button>
              <p className="footer-hint">
                Already have an account?{' '}
                <button 
                  className="link-btn"
                  onClick={() => { setAuthMode('login'); setShowAuth(true); }}
                >
                  Log in
                </button>
              </p>
            </>
          )}
        </div>

        <div className="app-promo">
          <div className="app-promo-icon">📱</div>
          <div className="app-promo-content">
            <h3>Get the Full Experience</h3>
            <p>Download PinIt to see events on a map, chat with attendees, and get notified when plans change.</p>
            <button className="btn btn-outline">Download App</button>
          </div>
        </div>
      </div>

      {showAuth && (
        <AuthModal
          mode={authMode}
          onClose={() => setShowAuth(false)}
          onLogin={handleAuthSuccess}
          onSwitchMode={() => setAuthMode(authMode === 'login' ? 'signup' : 'login')}
        />
      )}
    </div>
  )
}

export default EventInvite

