# 🚀 PinIt App Deployment Checklist

## ✅ Pre-Deployment Checklist

### Backend Preparation
- [ ] Production settings file created (`settings_production.py`)
- [ ] Environment variables configured (`env_example.txt`)
- [ ] Production requirements updated (`requirements_production.txt`)
- [ ] Database migrations tested
- [ ] Static files configuration verified

### iOS App Preparation
- [ ] API configuration centralized (`APIConfig.swift`)
- [ ] All hardcoded URLs replaced with APIConfig
- [ ] Bundle ID updated for production
- [ ] Push notification certificates configured
- [ ] App icons and assets prepared

## 🌐 Phase 1: Backend Deployment

### Option A: Heroku (Easiest)
```bash
# 1. Install Heroku CLI
brew install heroku/brew/heroku

# 2. Login to Heroku
heroku login

# 3. Navigate to backend directory
cd /Users/tombesinger/Desktop/PinItApp/Back_End/StudyCon

# 4. Initialize git (if not already done)
git init
git add .
git commit -m "Initial commit"

# 5. Create Heroku app
heroku create pinit-backend

# 6. Add PostgreSQL database
heroku addons:create heroku-postgresql:hobby-dev

# 7. Add Redis for WebSockets
heroku addons:create heroku-redis:hobby-dev

# 8. Set environment variables
heroku config:set SECRET_KEY=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
heroku config:set DEBUG=False
heroku config:set DJANGO_SETTINGS_MODULE=StudyCon.settings_production
heroku config:set ALLOWED_HOSTS=pinit-backend.herokuapp.com,pin-it.net,www.pin-it.net

# 9. Create Procfile
echo "web: gunicorn StudyCon.wsgi --log-file -" > Procfile
echo "worker: daphne StudyCon.asgi:application --port \$PORT --bind 0.0.0.0" >> Procfile

# 10. Deploy to Heroku
git add .
git commit -m "Add production configuration"
git push heroku main

# 11. Run database migrations
heroku run python manage.py migrate

# 12. Create superuser (optional)
heroku run python manage.py createsuperuser
```

### Option B: DigitalOcean App Platform
1. Create DigitalOcean account
2. Go to App Platform
3. Create new app from GitHub repository
4. Configure environment variables
5. Deploy

## 🌐 Phase 2: Domain Configuration

### DNS Setup (at your domain registrar)
```
Type: CNAME
Name: api
Value: pinit-backend.herokuapp.com

Type: CNAME  
Name: www
Value: pinit-backend.herokuapp.com

Type: A
Name: @
Value: [Get IP from: dig pinit-backend.herokuapp.com]
```

### SSL Certificate
- Heroku provides free SSL automatically
- Custom domain SSL: `heroku certs:auto:enable`

## 📱 Phase 3: iOS App Updates

### Update API Configuration
- [ ] Replace all hardcoded URLs in managers with `APIConfig`
- [ ] Update `AppDelegate.swift` to use `APIConfig.serverBaseURL`
- [ ] Update all ViewModels to use `APIConfig.primaryBaseURL`

### Key Files to Update:
1. `UserAccountManager.swift` - Line 12
2. `AutoMatchingManager.swift` - Lines 11-15
3. `UserProfileManager.swift` - Lines 29-33
4. `UserReputationManager.swift` - Lines 11-17
5. `AppDelegate.swift` - Line 12

### Bundle ID Configuration
1. Open Xcode project
2. Select project → Target → General
3. Change Bundle Identifier to: `com.pinit.app`
4. Update Team and Signing

## 🍎 Phase 4: App Store Submission

### Apple Developer Account
- [ ] Sign up at developer.apple.com ($99/year)
- [ ] Verify account and payment

### App Store Connect Setup
1. Create new app in App Store Connect
2. Fill out app information:
   - **Name**: PinIt
   - **Bundle ID**: com.pinit.app
   - **SKU**: pinit-app-001
   - **Category**: Social Networking / Education

### Required Assets
- [ ] App Icon (1024x1024)
- [ ] Screenshots for iPhone (6.7", 6.5", 5.5")
- [ ] Screenshots for iPad (12.9", 11")
- [ ] App description and keywords
- [ ] Privacy Policy URL
- [ ] Support URL

### Build and Upload
```bash
# 1. Archive the app
Product → Archive (in Xcode)

# 2. Upload to App Store Connect
Window → Organizer → Upload to App Store

# 3. Submit for review
Go to App Store Connect → TestFlight → Submit for Review
```

## 🔧 Testing Checklist

### Backend Testing
- [ ] API endpoints respond correctly
- [ ] Database connections work
- [ ] WebSocket connections functional
- [ ] Push notifications configured
- [ ] CORS headers properly set

### iOS App Testing
- [ ] App connects to production API
- [ ] All features work with live backend
- [ ] Push notifications work
- [ ] No crashes or memory leaks
- [ ] Proper error handling

### Integration Testing
- [ ] User registration/login works
- [ ] Profile updates sync correctly
- [ ] Real-time features functional
- [ ] Location services work
- [ ] Calendar integration works

## 🚨 Common Issues & Solutions

### Backend Issues
- **Database connection errors**: Check DATABASE_URL environment variable
- **Static files not loading**: Run `python manage.py collectstatic`
- **CORS errors**: Verify CORS_ALLOWED_ORIGINS in settings
- **SSL redirect loops**: Check SECURE_PROXY_SSL_HEADER setting

### iOS Issues
- **API connection fails**: Verify APIConfig URLs
- **Code signing errors**: Check certificates and provisioning profiles
- **App Store rejection**: Review Apple's App Store Review Guidelines

### Domain Issues
- **DNS not propagating**: Wait 24-48 hours for full propagation
- **SSL certificate errors**: Verify domain ownership
- **Subdomain not working**: Check CNAME records

## 📞 Support Resources

- **Heroku Documentation**: devcenter.heroku.com
- **Apple Developer**: developer.apple.com/support
- **Django Deployment**: docs.djangoproject.com/en/stable/howto/deployment/
- **DNS Help**: Your domain registrar's support

## 🎯 Timeline Estimate

- **Backend Deployment**: 2-4 hours
- **Domain Setup**: 1-2 hours (+ 24-48h DNS propagation)
- **iOS App Updates**: 4-6 hours
- **App Store Submission**: 2-3 hours
- **Apple Review**: 1-7 days

**Total Time**: 1-2 weeks (including review time)

---

**Last Updated**: January 2025
**Next Review**: After successful deployment




