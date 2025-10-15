# Quick Installation Guide for New APNs Implementation

## Installation Steps

### Option 1: Install via pip (when SSL is working)
```bash
cd /Users/tombesinger/Desktop/PinItApp
source venv/bin/activate
pip install aioapns==3.2 'httpx[http2]>=0.27.0'
```

### Option 2: Install via requirements.txt
```bash
cd /Users/tombesinger/Desktop/PinItApp
source venv/bin/activate
pip install -r requirements.txt
```

### Option 3: If SSL certificate issues persist
```bash
# Install certificates (macOS)
cd /Applications/Python\ 3.13/
./Install\ Certificates.command

# Then retry installation
cd /Users/tombesinger/Desktop/PinItApp
source venv/bin/activate
pip install -r requirements.txt
```

## Verify Installation

```bash
python -c "import aioapns; print('✅ aioapns installed successfully')"
python -c "import httpx; print('✅ httpx installed successfully')"
```

## Deploy to Railway

Railway will automatically install dependencies from `requirements.txt`:

```bash
git add requirements.txt myapp/views.py StudyCon/settings.py PYTHON_313_APNS_FIX.md
git commit -m "Fix: Replace apns2 with aioapns for Python 3.13 compatibility"
git push origin main
```

Railway will:
1. Detect changes to requirements.txt
2. Install aioapns and httpx automatically
3. Restart your service
4. Push notifications will work!

## What Was Changed

### Code Changes ✅
- `requirements.txt` - Replaced apns2-plus with aioapns
- `myapp/views.py` - Rewrote push notification sending
- `StudyCon/settings.py` - Removed django-push-notifications

### No Changes Needed ✅
- iOS app (works as-is)
- Environment variables (same format)
- Database models (Device model unchanged)
- API endpoints (same endpoints)

## Testing

Once installed, test with:

```bash
# Start Django server
python manage.py runserver

# In another terminal, test push notifications
python test_push_notifications.py
```

## Environment Variables Required

Make sure these are set (same as before):
```bash
APNS_AUTH_KEY_PATH=/path/to/AuthKey_ABC123.p8
APNS_AUTH_KEY_ID=ABC1234DEF
APNS_TEAM_ID=XYZ9876ABC
APNS_TOPIC=com.pinit.app
APNS_USE_SANDBOX=True
```

## Dependencies Installed

When you run `pip install -r requirements.txt`, these will be installed:

**New:**
- `aioapns==3.2` - Modern APNs client for Python 3.13
- `httpx[http2]>=0.27.0` - HTTP/2 support for APNs

**Removed:**
- ❌ `apns2-plus==0.7.2.1` - Broken on Python 3.13
- ❌ `django-push-notifications==3.0.0` - Depends on apns2

**Kept (unchanged):**
- Django==5.1.6
- channels==4.0.0
- All other dependencies

---

**Next Step:** 
When Railway deploys, push notifications will automatically work with Python 3.13! 🎉

