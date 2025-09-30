# 🚀 Railway Deployment Guide for PinIt Backend

## Quick Deploy to Railway (Easiest Option)

Railway is the fastest way to deploy your Django backend. It's free to start and handles everything automatically.

### Step 1: Create Railway Account
1. Go to https://railway.app
2. Sign up with GitHub (recommended)
3. Verify your email

### Step 2: Deploy Your App
1. Click "New Project"
2. Select "Deploy from GitHub repo"
3. Choose your repository (or create one first)
4. Railway will automatically detect it's a Django app

### Step 3: Configure Environment Variables
In Railway dashboard, go to Variables tab and add:

```
DEBUG=False
DJANGO_SETTINGS_MODULE=StudyCon.settings_production
SECRET_KEY=your-super-secret-key-here-make-it-long-and-random
ALLOWED_HOSTS=*.railway.app,pin-it.net,www.pin-it.net
```

### Step 4: Add Database
1. Click "New" → "Database" → "PostgreSQL"
2. Railway will automatically set DATABASE_URL
3. Your app will connect automatically

### Step 5: Deploy
1. Railway will automatically build and deploy
2. Your app will be available at: `https://your-app-name.railway.app`
3. Test your API: `https://your-app-name.railway.app/api/get_all_users/`

## Alternative: Manual Railway CLI Deployment

### Install Railway CLI
```bash
npm install -g @railway/cli
```

### Login and Deploy
```bash
railway login
railway init
railway up
```

## 🌐 Domain Setup

### Add Custom Domain
1. In Railway dashboard, go to Settings
2. Click "Domains"
3. Add your domain: `pin-it.net`
4. Update DNS records as shown

### Update Environment Variables
Add your domain to ALLOWED_HOSTS:
```
ALLOWED_HOSTS=*.railway.app,pin-it.net,www.pin-it.net,api.pin-it.net
```

## 📱 Next Steps

1. ✅ Test your API endpoints
2. ✅ Update iOS app to use Railway URL
3. ✅ Set up custom domain
4. ✅ Submit iOS app to App Store

## 💰 Railway Pricing

- **Free Tier**: $5 credit monthly (enough for small apps)
- **Pro**: $5/month per service
- **Database**: $5/month for PostgreSQL

## 🔧 Useful Railway Commands

```bash
# View logs
railway logs

# Connect to database
railway connect

# Open app in browser
railway open

# Check status
railway status
```

---

**Your PinIt backend will be live in minutes!**
