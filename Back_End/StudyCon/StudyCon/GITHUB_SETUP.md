# 🚀 GitHub Repository Setup - GO LIVE NOW!

## Quick GitHub Setup (2 minutes)

### Step 1: Create Repository
1. **Go to**: https://github.com/new
2. **Repository name**: `pinit-backend`
3. **Description**: `PinIt App Backend - Django API`
4. **Make it PUBLIC** (required for free Railway deployment)
5. **DON'T** initialize with README, .gitignore, or license
6. **Click**: "Create repository"

### Step 2: Push Your Code
After creating the repository, GitHub will show you commands. Run these in your terminal:

```bash
# Replace YOUR_USERNAME with your actual GitHub username
git remote add origin https://github.com/YOUR_USERNAME/pinit-backend.git
git branch -M main
git push -u origin main
```

### Step 3: Deploy to Railway
1. **Go to**: https://railway.app
2. **Sign up** with GitHub
3. **Click**: "New Project"
4. **Select**: "Deploy from GitHub repo"
5. **Choose**: your `pinit-backend` repository
6. **Railway will automatically detect Django and deploy!**

### Step 4: Configure Environment Variables
In Railway dashboard → Variables tab, add:

```
DEBUG=False
DJANGO_SETTINGS_MODULE=StudyCon.settings_production
SECRET_KEY=your-super-secret-key-here-make-it-long-and-random-change-this
ALLOWED_HOSTS=*.railway.app,pin-it.net,www.pin-it.net
```

### Step 5: Add Database
1. **In Railway dashboard**: Click "New"
2. **Select**: "Database" → "PostgreSQL"
3. **Railway will automatically connect it**

### Step 6: Test Your Live API
1. **Wait** for deployment (2-3 minutes)
2. **Click** on your app URL in Railway dashboard
3. **Test**: `https://your-app.railway.app/api/get_all_users/`
4. **If you see JSON**: Your API is working! 🎉

---

## 🎯 Your App Will Be Live in 5 Minutes!

**Current Status:**
- ✅ Django backend ready
- ✅ Production settings configured
- ✅ Database models ready
- ✅ Deployment files prepared
- ✅ Git repository initialized

**Next Steps:**
1. Create GitHub repo (2 min)
2. Push code (1 min)
3. Deploy to Railway (2 min)
4. Test API (1 min)

**Total Time: 6 minutes to go live!**

---

## 📱 After Deployment

### Update iOS App
Your iOS app is already configured to use `APIConfig.swift`. Just replace the Railway URL in the config.

### Custom Domain
1. Railway dashboard → Settings → Domains
2. Add: `pin-it.net`
3. Update DNS records
4. Wait for propagation

### App Store Submission
1. Apple Developer Account ($99/year)
2. Create App Store Connect listing
3. Upload app for review
4. Wait for approval (1-7 days)

---

**🚀 Ready to go live? Follow the steps above!**

