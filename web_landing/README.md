# PinIt Landing Page

A modern, responsive landing page for the PinIt app built with React and Vite.

## Features

- 🎨 Modern, beautiful UI with smooth animations
- 🔐 User authentication (sign up / login)
- 📱 Responsive design for all devices
- 🚀 Fast development with Vite
- 🔌 Connected to PinIt backend API
- 💫 Dashboard for logged-in users

## Getting Started

### Prerequisites

- Node.js (v16 or higher)
- npm or yarn

### Installation

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file in the root directory:
```bash
cp .env.example .env
```

3. Update the `.env` file with your backend API URL:
```
VITE_API_URL=https://your-backend-url.railway.app
```

### Development

Run the development server:
```bash
npm run dev
```

The app will be available at `http://localhost:3000`

### Build for Production

Build the app:
```bash
npm run build
```

Preview the production build:
```bash
npm run preview
```

## Project Structure

```
web_landing/
├── src/
│   ├── components/       # React components
│   │   └── AuthModal.jsx # Login/Signup modal
│   ├── pages/           # Page components
│   │   ├── LandingPage.jsx
│   │   └── Dashboard.jsx
│   ├── services/        # API services
│   │   └── api.js       # API client
│   ├── App.jsx          # Main app component
│   ├── main.jsx         # Entry point
│   └── index.css        # Global styles
├── index.html           # HTML template
├── vite.config.js       # Vite configuration
└── package.json         # Dependencies
```

## API Integration

The landing page connects to your existing PinIt Django backend. Make sure your backend allows CORS from your frontend domain.

### Backend Setup

Add these settings to your Django `settings.py`:

```python
# Add to INSTALLED_APPS
INSTALLED_APPS = [
    # ...
    'corsheaders',
]

# Add to MIDDLEWARE (before CommonMiddleware)
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    # ...
]

# CORS settings for development
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
]

# For production, add your frontend domain
# CORS_ALLOWED_ORIGINS = [
#     "https://your-frontend-domain.com",
# ]
```

Install django-cors-headers if not already installed:
```bash
pip install django-cors-headers
```

## Deployment

### Deploy to Vercel (Recommended)

1. Install Vercel CLI:
```bash
npm install -g vercel
```

2. Deploy:
```bash
vercel
```

### Deploy to Netlify

1. Build the project:
```bash
npm run build
```

2. Drag and drop the `dist` folder to Netlify

### Environment Variables

Make sure to set the `VITE_API_URL` environment variable in your deployment platform to your production backend URL.

## Features Implemented

- ✅ Landing page with hero section
- ✅ Features showcase
- ✅ User authentication (signup/login)
- ✅ Protected dashboard
- ✅ JWT token authentication
- ✅ Responsive design
- ✅ Error handling
- ✅ Loading states

## Technologies Used

- React 18
- Vite
- React Router
- Axios
- CSS3 with modern features

## License

This project is part of the PinIt app.


