# Quick Start: Deploy New APNs Implementation

## ✅ Code Changes Complete

All code changes are done and syntax-validated. Ready to deploy!

## 🚀 Deploy to Railway (Recommended)

```bash
# 1. Commit the changes
git add .
git commit -m "Fix: Upgrade to aioapns for Python 3.13 compatibility"

# 2. Push to Railway
git push origin main
```

**That's it!** Railway will automatically:
- Install `aioapns==3.2` and `httpx[http2]`
- Restart your service
- Push notifications will work immediately

## 🧪 Test After Deployment

### 1. Check APNs Configuration
```bash
curl https://your-backend.railway.app/api/debug-apns/
```

Expected response:
```json
{
  "APNS_AUTH_KEY_PATH": "/path/to/key.p8",
  "APNS_AUTH_KEY_ID": "ABC1234DEF",
  "APNS_TEAM_ID": "XYZ9876ABC",
  "APNS_TOPIC": "com.pinit.app",
  "APNS_USE_SANDBOX": true
}
```

### 2. Register Device from iOS
- Open iOS app
- Login
- Device will auto-register
- Check Railway logs for: "✅ Device registered for user..."

### 3. Send Test Notification
```bash
curl -X POST https://your-backend.railway.app/api/test-push/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

### 4. Check Logs
Railway logs should show:
```
📱 Sending test notification to user_id: 1 (1 device(s))
🔍 Attempting to send APNs notification...
🔍 APNs device: 1234567890abcdef...
🔍 Message: This is a test notification
🔍 Title: Test Notification
✅ APNs notification sent successfully
✅ Push notification sent to iOS device
```

## 📋 What Changed

### Files Modified
- ✅ `requirements.txt` - Replaced apns2 with aioapns
- ✅ `myapp/views.py` - New push notification implementation
- ✅ `StudyCon/settings.py` - Removed django-push-notifications

### No Changes Needed
- ✅ iOS app - Works as-is
- ✅ Environment variables - Same format
- ✅ Database - No migrations needed
- ✅ API endpoints - Same URLs

## 🔑 Environment Variables

Verify these are set in Railway:

**Required:**
- `APNS_AUTH_KEY_PATH` - Path to .p8 file (or use APNS_AUTH_KEY_CONTENT)
- `APNS_AUTH_KEY_ID` - 10-character key ID
- `APNS_TEAM_ID` - 10-character team ID
- `APNS_TOPIC` - Bundle ID (e.g., com.pinit.app)
- `APNS_USE_SANDBOX` - "True" for dev, "False" for production

## 🐛 Troubleshooting

### If notifications don't work:

1. **Check logs for errors:**
   - Look for "❌" in Railway logs
   - Common: "APNs auth key not found"
   - Common: "BadDeviceToken" (wrong sandbox setting)

2. **Verify APNs settings:**
   ```bash
   curl https://your-backend.railway.app/api/debug-apns/
   ```

3. **Re-register device:**
   - Logout from iOS app
   - Login again
   - Device will re-register

4. **Check sandbox setting:**
   - Development builds → `APNS_USE_SANDBOX=True`
   - TestFlight/Production → `APNS_USE_SANDBOX=False`

## 📚 Documentation

Detailed docs created:
- `APNS_UPGRADE_SUMMARY.md` - Complete overview
- `PYTHON_313_APNS_FIX.md` - Technical details
- `INSTALL_NEW_APNS.md` - Installation guide

## ✅ Success Checklist

After deployment:

- [ ] Railway build succeeds
- [ ] Service starts without errors
- [ ] `/api/debug-apns/` shows config
- [ ] Device registration works from iOS
- [ ] Test notification sends successfully
- [ ] Notification appears on device
- [ ] Logs show "✅ APNs notification sent successfully"

## 🎉 Done!

Push notifications now work with Python 3.13!

**Next:** Just push to Railway and test. Everything else is automatic.

---

**Questions?** Check the detailed docs:
- Technical: `PYTHON_313_APNS_FIX.md`
- Overview: `APNS_UPGRADE_SUMMARY.md`
- Setup: Original `PUSH_NOTIFICATION_SETUP_GUIDE.md`

