# 🚀 PinIt Backend Deployment Instructions

## Option 1: DigitalOcean App Platform (Recommended)

### Step 1: Create DigitalOcean Account
1. Go to https://digitalocean.com
2. Sign up for an account
3. Add a payment method

### Step 2: Create App
1. Go to Apps in DigitalOcean dashboard
2. Click "Create App"
3. Connect your GitHub repository
4. Select the repository: your-username/pinit-app
5. Choose the branch: main

### Step 3: Configure App
1. App Name: pinit-backend
2. Source Directory: Back_End/StudyCon
3. Build Command: pip install -r requirements_production.txt
4. Run Command: gunicorn StudyCon.wsgi --log-file - --bind 0.0.0.0:$PORT

### Step 4: Add Database
1. Click "Add Database"
2. Choose PostgreSQL
3. Name: pinit-db
4. Version: 13

### Step 5: Set Environment Variables
- DEBUG: False
- DJANGO_SETTINGS_MODULE: StudyCon.settings_production
- SECRET_KEY: [Generate a secure secret key]
- ALLOWED_HOSTS: pinit-backend.ondigitalocean.app,pin-it.net,www.pin-it.net

### Step 6: Deploy
1. Click "Create Resources"
2. Wait for deployment to complete
3. Your app will be available at: https://pinit-backend.ondigitalocean.app

## Option 2: Docker Deployment

### Local Testing
```bash
# Build and run with Docker Compose
docker-compose up --build

# Your app will be available at: http://localhost:8080
```

### Deploy to Any Cloud Provider
1. Build Docker image: `docker build -t pinit-backend .`
2. Push to registry (Docker Hub, AWS ECR, etc.)
3. Deploy to your preferred cloud provider

## Option 3: Manual VPS Deployment

### Step 1: Set up VPS
1. Create a VPS (DigitalOcean Droplet, Linode, etc.)
2. Install Python 3.13, PostgreSQL, Redis
3. Clone your repository

### Step 2: Deploy Application
```bash
# Install dependencies
pip install -r requirements_production.txt

# Set up database
python manage.py migrate

# Collect static files
python manage.py collectstatic

# Run with Gunicorn
gunicorn StudyCon.wsgi --bind 0.0.0.0:8000
```

## 🌐 Domain Setup

### For DigitalOcean App Platform
1. Go to your app settings
2. Click "Domains"
3. Add custom domain: pin-it.net
4. Update DNS records as instructed

### For Other Providers
1. Point your domain to your server IP
2. Configure SSL certificate (Let's Encrypt)
3. Update ALLOWED_HOSTS in environment variables

## 📱 Next Steps

1. Test your API endpoints
2. Update iOS app to use production URL
3. Set up monitoring and logging
4. Configure push notifications
5. Submit iOS app to App Store

## 🔧 Useful Commands

```bash
# Check app logs
doctl apps logs <app-id> --follow

# Scale app
doctl apps update <app-id> --spec .do/app.yaml

# Database access
doctl databases connection <database-id>
```

## 💰 Estimated Costs

- DigitalOcean App Platform: $5-12/month
- Domain: Already owned ✅
- SSL Certificate: Free
- Total: ~$5-12/month

---

**Your PinIt backend is ready for production deployment!**
