# How to Test Push Notifications - Step by Step

## 🎯 Quick Test Guide

### Step 1: Check APNs Configuration ✅

First, verify your APNs settings are configured correctly:

```bash
curl https://pinit-backend-production.up.railway.app/api/debug-apns/
```

**Expected Response:**
```json
{
  "APNS_AUTH_KEY_PATH": "/app/AuthKey_ABC123.p8",
  "APNS_AUTH_KEY_ID": "ABC1234DEF",
  "APNS_TEAM_ID": "XYZ9876ABC",
  "APNS_TOPIC": "com.pinit.app",
  "APNS_USE_SANDBOX": true,
  "auth_key_exists": true
}
```

**What to check:**
- ✅ All fields should have values (not empty strings)
- ✅ `auth_key_exists` should be `true`
- ✅ `APNS_USE_SANDBOX` should match your build type:
  - `true` for development builds
  - `false` for TestFlight/production builds

---

### Step 2: Register Device from iOS 📱

**Option A: Fresh Registration (Easiest)**
1. Open your PinIt iOS app
2. **Logout** if currently logged in
3. **Login** again
4. Device token will automatically register on login

**Option B: Already Logged In**
- Device should already be registered
- Check Railway logs for: "✅ Device registered for user..."

**Check Registration in Railway Logs:**
```
📱 Registering device token with server...
✅ Device registered for user john: ios - 1234567890abcdef...
```

---

### Step 3: Get Your JWT Token 🔑

You need a JWT token to make authenticated requests.

**Method 1: From iOS App**
- The JWT is stored in UserAccountManager
- Check Xcode console after login for the token

**Method 2: Login via curl**
```bash
curl -X POST https://pinit-backend-production.up.railway.app/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "your_username",
    "password": "your_password"
  }'
```

**Response:**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {...}
}
```

Copy the `access` token - this is your JWT!

---

### Step 4: Send Test Notification 🚀

**Use the test endpoint:**
```bash
curl -X POST https://pinit-backend-production.up.railway.app/api/test-push/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

**Replace `YOUR_JWT_TOKEN_HERE` with your actual JWT token!**

**Example with real token:**
```bash
curl -X POST https://pinit-backend-production.up.railway.app/api/test-push/ \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..." \
  -H "Content-Type: application/json"
```

---

### Step 5: Verify It Works ✅

**What should happen:**

**1. On your iPhone:**
- 🔔 Notification appears: "Test Notification - This is a test notification"
- Sound plays
- Badge appears on app icon

**2. Railway Logs show:**
```
📱 Sending test notification to user_id: 1 (1 device(s))
🔍 Attempting to send APNs notification...
🔍 APNs device: 1234567890abcdef...
🔍 Message: This is a test notification
🔍 Title: Test Notification
🔍 Using sandbox: True
✅ APNs notification sent successfully: <APNsResponse>
✅ Push notification sent to iOS device: Test Notification - This is a test notification
```

**3. API Response:**
```json
{
  "message": "Test notification sent successfully"
}
```

---

## 🐛 Troubleshooting

### Problem: "No active devices found"

**Check:**
1. Did you login to the iOS app?
2. Check Railway logs for device registration
3. Query the database:
```bash
# Check if device is registered
curl https://pinit-backend-production.up.railway.app/admin/
```

**Solution:**
- Logout and login again from iOS app
- Device will re-register automatically

---

### Problem: "APNs auth key not found"

**Railway Logs show:**
```
❌ APNs auth key not found at: /app/AuthKey_ABC123.p8
```

**Solution:**
1. Check Railway environment variables:
   - `APNS_AUTH_KEY_PATH` or `APNS_AUTH_KEY_CONTENT` must be set
2. If using `APNS_AUTH_KEY_CONTENT`, make sure it contains the full .p8 file content
3. Redeploy Railway after fixing

---

### Problem: "BadDeviceToken" Error

**Railway Logs show:**
```
❌ APNs send error: BadDeviceToken
```

**This means wrong sandbox setting!**

**Solution:**
- **Development Build:** Set `APNS_USE_SANDBOX=True` in Railway
- **TestFlight/Production:** Set `APNS_USE_SANDBOX=False` in Railway
- Redeploy after changing

---

### Problem: "401 Unauthorized"

**Error:**
```
❌ Device registration failed with status: 401
```

**Solution:**
- Your JWT token expired
- Get a fresh token by logging in again
- JWT tokens expire after a certain time

---

### Problem: No notification received on device

**Checklist:**
- [ ] Device is registered (check Railway logs)
- [ ] APNs config is correct (`/api/debug-apns/`)
- [ ] Sandbox setting matches your build
- [ ] Notification permissions enabled on iPhone
- [ ] iPhone has internet connection
- [ ] Not using iOS Simulator (push doesn't work on simulator!)

---

## 📋 Complete Testing Workflow

### Full Test Script

```bash
#!/bin/bash

# 1. Check APNs configuration
echo "1. Checking APNs config..."
curl https://pinit-backend-production.up.railway.app/api/debug-apns/
echo ""

# 2. Login to get JWT token
echo "2. Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST https://pinit-backend-production.up.railway.app/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "your_username",
    "password": "your_password"
  }')

# Extract JWT token
JWT_TOKEN=$(echo $LOGIN_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['access'])")
echo "JWT Token: ${JWT_TOKEN:0:50}..."
echo ""

# 3. Send test notification
echo "3. Sending test notification..."
curl -X POST https://pinit-backend-production.up.railway.app/api/test-push/ \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json"
echo ""

echo "4. Check your iPhone for notification!"
```

**To use:**
1. Replace `your_username` and `your_password`
2. Save as `test_push.sh`
3. Run: `chmod +x test_push.sh && ./test_push.sh`

---

## 🎨 Advanced: Test Different Notification Types

### Event Invitation Notification

From another user, invite your test user to an event. The backend will automatically send:

```python
send_push_notification(
    user_id=invited_user.id,
    notification_type='event_invitation',
    event_id=str(event.id),
    event_title=event.title,
    from_user=request.user.username
)
```

### New Rating Notification

Rate a user to trigger:

```bash
curl -X POST https://pinit-backend-production.up.railway.app/api/rate-user/ \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "to_user_id": 2,
    "rating": 5,
    "reference": "Great event host!"
  }'
```

This will send a `new_rating` notification to user 2.

---

## 📊 Monitoring Push Notifications

### Check Railway Logs

**View live logs:**
1. Go to Railway dashboard
2. Select your service
3. Click "View Logs"
4. Filter for: "push" or "APNs"

**What to look for:**
- ✅ `Device registered for user...`
- ✅ `Sending ... notification to user_id...`
- ✅ `APNs notification sent successfully`
- ❌ Any errors with "APNs" or "notification"

### Check Device Registration

**Python shell on Railway:**
```python
from myapp.models import Device

# See all registered devices
for device in Device.objects.filter(is_active=True):
    print(f"{device.user.username}: {device.device_type} - {device.token[:20]}...")

# Check specific user
user_devices = Device.objects.filter(user__username='john', is_active=True)
print(f"User has {user_devices.count()} device(s) registered")
```

---

## ✅ Success Indicators

**You'll know push notifications are working when:**

1. ✅ `/api/debug-apns/` shows all config values
2. ✅ iOS app registers device on login (logs confirm)
3. ✅ Test notification appears on iPhone
4. ✅ Railway logs show "✅ APNs notification sent successfully"
5. ✅ Real notifications work (invites, ratings, etc.)

---

## 🚨 Important Notes

### About iOS Simulator
❌ **Push notifications DON'T work on iOS Simulator!**
- You MUST test on a real iPhone device
- Simulator can register device tokens, but won't receive notifications

### About Sandbox vs Production
- **Development builds** → `APNS_USE_SANDBOX=True`
- **TestFlight builds** → `APNS_USE_SANDBOX=False`
- **App Store builds** → `APNS_USE_SANDBOX=False`

### About APNs Delays
- Some notifications may take a few seconds to arrive
- If app is in foreground, notification banner may not show (but will appear in notification center)
- Background notifications arrive immediately

---

## 📞 Quick Reference

| Action | Command |
|--------|---------|
| Check config | `curl .../api/debug-apns/` |
| Get JWT | `curl -X POST .../login/ -d {...}` |
| Test push | `curl -X POST .../api/test-push/ -H "Authorization: Bearer ..."` |
| Register device | Open iOS app, login |
| Check logs | Railway dashboard → View Logs |

---

## 🎉 You're Ready!

Follow these steps and you'll have push notifications working in minutes!

**Next Steps:**
1. ✅ Check APNs config
2. ✅ Login to iOS app (registers device)
3. ✅ Get JWT token
4. ✅ Send test notification
5. ✅ See notification on iPhone!

Good luck! 🚀

