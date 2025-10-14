# PinIt Landing Page - Setup Guide

## Quick Start

Follow these steps to get your PinIt landing page up and running:

### 1. Install Dependencies

```bash
cd web_landing
npm install
```

### 2. Configure Environment

Create a `.env` file in the `web_landing` directory:

```bash
# For local development with local backend
VITE_API_URL=http://localhost:8000

# Or for production backend
VITE_API_URL=https://pinit-backend-production.up.railway.app
```

### 3. Start Development Server

```bash
npm run dev
```

The landing page will be available at: **http://localhost:3000**

## Backend Configuration

Your Django backend is already configured to accept requests from the landing page! 

The following CORS origin is already set in `StudyCon/settings.py`:
```python
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",  # ✅ Already configured!
    # ...
]
```

### If Deploying to Production

When you deploy your landing page to a production domain, add that domain to `CORS_ALLOWED_ORIGINS` in your Django settings:

```python
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "https://your-landing-page-domain.com",  # Add your production domain
    "https://pinit-backend-production.up.railway.app",
]
```

And add it to `CSRF_TRUSTED_ORIGINS`:

```python
CSRF_TRUSTED_ORIGINS = [
    'https://pinit-backend-production.up.railway.app',
    'https://your-landing-page-domain.com',  # Add your production domain
]
```

## Features

✅ **Beautiful Landing Page** - Modern, responsive design with smooth animations  
✅ **User Authentication** - Sign up and login functionality  
✅ **Protected Dashboard** - Dashboard for logged-in users  
✅ **API Integration** - Fully connected to your Django backend  
✅ **JWT Authentication** - Secure token-based auth  
✅ **Mobile Responsive** - Works on all devices  

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build locally

## API Endpoints Used

The landing page uses the following backend endpoints:

- `POST /api/register/` - User registration
- `POST /api/login/` - User login
- `POST /api/logout/` - User logout
- `GET /api/get_user_profile/<username>/` - Get user profile
- `GET /api/get_study_events/<username>/` - Get user events

## Deployment Options

### Option 1: Vercel (Recommended)

1. Install Vercel CLI:
```bash
npm install -g vercel
```

2. Deploy:
```bash
cd web_landing
vercel
```

3. Set environment variable in Vercel dashboard:
   - `VITE_API_URL` = `https://pinit-backend-production.up.railway.app`

### Option 2: Netlify

1. Build the project:
```bash
npm run build
```

2. Deploy the `dist` folder to Netlify

3. Set environment variable in Netlify dashboard:
   - `VITE_API_URL` = `https://pinit-backend-production.up.railway.app`

### Option 3: Railway

1. Create a new Railway project
2. Connect your GitHub repository
3. Set the root directory to `web_landing`
4. Add environment variable:
   - `VITE_API_URL` = `https://pinit-backend-production.up.railway.app`
5. Railway will automatically detect Vite and deploy

## Testing

### Test Locally

1. Make sure your Django backend is running (locally or on Railway)
2. Start the landing page: `npm run dev`
3. Visit http://localhost:3000
4. Try signing up with a new account
5. Check if you can log in
6. Verify the dashboard loads

### Test User Flow

1. Click "Sign Up" on the landing page
2. Create a new account (username + password)
3. You'll be automatically logged in and redirected to the dashboard
4. The dashboard will show:
   - Your username
   - Event count
   - Friend count
   - Trust level
   - App download section

## Troubleshooting

### CORS Errors

If you see CORS errors in the browser console:

1. Make sure your backend is running
2. Check that `corsheaders` is installed: `pip install django-cors-headers`
3. Verify CORS settings in `settings.py` (should already be configured)
4. Make sure your frontend URL is in `CORS_ALLOWED_ORIGINS`

### API Connection Issues

If you can't connect to the API:

1. Check your `.env` file has the correct `VITE_API_URL`
2. Make sure the backend is accessible (try opening the URL in a browser)
3. Check browser console for detailed error messages

### Build Errors

If you get build errors:

1. Delete `node_modules` and `package-lock.json`
2. Run `npm install` again
3. Try `npm run build` again

## Project Structure

```
web_landing/
├── public/              # Static assets
│   └── icon.png        # PinIt logo
├── src/
│   ├── components/     # React components
│   │   ├── AuthModal.jsx
│   │   └── AuthModal.css
│   ├── pages/          # Page components
│   │   ├── LandingPage.jsx
│   │   ├── LandingPage.css
│   │   ├── Dashboard.jsx
│   │   └── Dashboard.css
│   ├── services/       # API services
│   │   └── api.js      # Axios API client
│   ├── App.jsx         # Main app component
│   ├── App.css
│   ├── main.jsx        # Entry point
│   └── index.css       # Global styles
├── index.html          # HTML template
├── vite.config.js      # Vite configuration
├── package.json        # Dependencies
├── .env                # Environment variables (create this)
├── .gitignore
├── README.md
└── SETUP.md           # This file
```

## Next Steps

After getting the landing page running:

1. ✅ Test user registration and login
2. ✅ Customize the landing page copy and images
3. ✅ Add your own branding
4. ✅ Deploy to production
5. ✅ Share the link with users!

## Support

If you run into any issues:

1. Check the browser console for errors
2. Check the terminal for build errors
3. Verify your backend is running and accessible
4. Make sure all environment variables are set correctly

Enjoy your new PinIt landing page! 🎉


