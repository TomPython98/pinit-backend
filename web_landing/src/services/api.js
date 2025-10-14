import axios from 'axios'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Add token to requests if available
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Handle token expiration
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('access_token')
      localStorage.removeItem('username')
      window.location.href = '/'
    }
    return Promise.reject(error)
  }
)

export const authAPI = {
  register: async (username, password) => {
    const response = await api.post('/api/register/', { username, password })
    return response.data
  },
  
  login: async (username, password) => {
    const response = await api.post('/api/login/', { username, password })
    return response.data
  },
  
  logout: async () => {
    const response = await api.post('/api/logout/')
    return response.data
  },
}

export const userAPI = {
  getProfile: async (username) => {
    const response = await api.get(`/api/get_user_profile/${username}/`)
    return response.data
  },
  
  getAllUsers: async () => {
    const response = await api.get('/api/get_all_users/')
    return response.data
  },
}

export const eventAPI = {
  getEvents: async (username) => {
    const response = await api.get(`/api/get_study_events/${username}/`)
    return response.data
  },
  
  searchEvents: async (params) => {
    const response = await api.post('/api/search_events/', params)
    return response.data
  },
  
  createEvent: async (eventData) => {
    const response = await api.post('/api/create_study_event/', eventData)
    return response.data
  },
  
  rsvpEvent: async (eventId) => {
    const response = await api.post('/api/rsvp_study_event/', { event_id: eventId })
    return response.data
  },
}

export const invitationAPI = {
  getInvitations: async (username) => {
    const response = await api.get(`/api/get_invitations/${username}/`)
    return response.data
  },
  
  declineInvitation: async (invitationData) => {
    const response = await api.post('/api/decline_invitation/', invitationData)
    return response.data
  },
}

export default api


