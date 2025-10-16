import React, { useState, useEffect } from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate, useParams } from 'react-router-dom'
import LandingPage from './pages/LandingPage'
import Dashboard from './pages/Dashboard'
import EventInvite from './pages/EventInvite'
import TermsOfService from './pages/TermsOfService'
import PrivacyPolicy from './pages/PrivacyPolicy'
import './App.css'

function App() {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Check if user is logged in
    const token = localStorage.getItem('access_token')
    const username = localStorage.getItem('username')
    
    if (token && username) {
      setUser({ username, token })
    }
    setLoading(false)
  }, [])

  const handleLogin = (userData) => {
    setUser(userData)
    localStorage.setItem('access_token', userData.access_token)
    localStorage.setItem('username', userData.username)
  }

  const handleLogout = () => {
    setUser(null)
    localStorage.removeItem('access_token')
    localStorage.removeItem('username')
  }

  if (loading) {
    return <div className="loading">Loading...</div>
  }

  return (
    <Router>
      <Routes>
        <Route 
          path="/" 
          element={
            user ? 
            <Navigate to="/dashboard" /> : 
            <LandingPage onLogin={handleLogin} />
          } 
        />
        <Route 
          path="/dashboard" 
          element={
            user ? 
            <Dashboard user={user} onLogout={handleLogout} /> : 
            <Navigate to="/" />
          } 
        />
        <Route 
          path="/event/:eventId" 
          element={<EventInvite user={user} onLogin={handleLogin} />}
        />
        <Route 
          path="/terms-of-service" 
          element={<TermsOfService />}
        />
        <Route 
          path="/privacy-policy" 
          element={<PrivacyPolicy />}
        />
      </Routes>
    </Router>
  )
}

export default App


