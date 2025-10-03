# 🚀 DEPLOY YOUR PINIT BACKEND NOW!

## ⚡ Quick 5-Minute Deployment

Your backend is ready to deploy! Follow these simple steps:

### Step 1: Create GitHub Repository (2 minutes)
1. Go to https://github.com/new
2. Repository name: `pinit-backend`
3. Description: `PinIt App Backend - Django API`
4. Make it **Public** (required for free Railway deployment)
5. **Don't** initialize with README
6. Click "Create repository"

### Step 2: Push Your Code (1 minute)
Run these commands in your terminal:

```bash
# Add GitHub remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/pinit-backend.git

# Push your code
git branch -M main
git push -u origin main
```

### Step 3: Deploy to Railway (2 minutes)
1. Go to https://railway.app
2. Sign up with **GitHub** (recommended)
3. Click "New Project"
4. Select "Deploy from GitHub repo"
5. Choose your `pinit-backend` repository
6. Railway will automatically detect Django and deploy!

### Step 4: Configure Environment Variables
In Railway dashboard, go to Variables tab and add:

```
DEBUG=False
DJANGO_SETTINGS_MODULE=StudyCon.settings_production
SECRET_KEY=your-super-secret-key-here-make-it-long-and-random-change-this
ALLOWED_HOSTS=*.railway.app,pin-it.net,www.pin-it.net
```

### Step 5: Add Database
1. In Railway dashboard, click "New"
2. Select "Database" → "PostgreSQL"
3. Railway will automatically connect it

### Step 6: Test Your API
1. Wait for deployment to complete (2-3 minutes)
2. Click on your app URL in Railway dashboard
3. Test: `https://your-app.railway.app/api/get_all_users/`
4. If you see JSON, your API is working! 🎉

---

## 📱 Next: Update iOS App

1. Open your iOS project in Xcode
2. Replace all hardcoded URLs:
   - `http://127.0.0.1:8000` → `https://your-app.railway.app`
   - `http://localhost:8000` → `https://your-app.railway.app`
3. Use the `APIConfig.swift` file I created
4. Test your iOS app with the production backend

## 🌐 Custom Domain Setup

1. In Railway dashboard → Settings → Domains
2. Add custom domain: `pin-it.net`
3. Update DNS records as shown
4. Wait for DNS propagation (up to 24 hours)

## 💰 Cost: FREE!

- Railway: Free tier with $5 credit monthly
- Domain: You already own pin-it.net ✅
- Total cost: $0/month

---

## 🎯 Your Backend Will Be Live in 5 Minutes!

**Current Status:**
- ✅ Django backend ready
- ✅ Production settings configured
- ✅ Database models created
- ✅ Deployment files prepared
- ✅ Git repository initialized

**Next Steps:**
1. Create GitHub repo
2. Push code
3. Deploy to Railway
4. Test API
5. Update iOS app
6. Submit to App Store

---

**Need help? All deployment files are ready in this directory!**
