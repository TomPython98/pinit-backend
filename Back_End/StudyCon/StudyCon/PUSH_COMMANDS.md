# 🚀 Push Your Code to GitHub - COMMANDS TO RUN

## Quick Push Commands

**Replace `YOUR_USERNAME` with your actual GitHub username and run these commands:**

```bash
# Add GitHub remote
git remote add origin https://github.com/YOUR_USERNAME/pinit-backend.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## Example:
If your GitHub username is `tombesinger`, run:

```bash
git remote add origin https://github.com/tombesinger/pinit-backend.git
git branch -M main
git push -u origin main
```

## After Pushing:

1. **Go to Railway**: https://railway.app
2. **Sign up** with GitHub
3. **Click**: "New Project"
4. **Select**: "Deploy from GitHub repo"
5. **Choose**: your `pinit-backend` repository
6. **Railway will auto-deploy!**

## Environment Variables to Set in Railway:

```
DEBUG=False
DJANGO_SETTINGS_MODULE=StudyCon.settings_production
SECRET_KEY=your-super-secret-key-here-make-it-long-and-random-change-this
ALLOWED_HOSTS=*.railway.app,pin-it.net,www.pin-it.net
```

## Add Database:
1. Railway dashboard → Click "New"
2. Select "Database" → "PostgreSQL"
3. Railway auto-connects it!

---

**Your PinIt backend will be LIVE in 2 minutes!** 🎉




