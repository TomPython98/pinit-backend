# Push Notifications Quick Reference

Quick commands and endpoints for testing push notifications.

## 🔧 Backend Test Commands

### Test via Django Shell
```bash
python manage.py shell
```

```python
from myapp.views import send_push_notification

# Send test notification to user ID 1
send_push_notification(
    user_id=1,
    notification_type='event_invitation',
    event_title='Test Event',
    from_user='Admin',
    event_id='test-123'
)
```

### Run Test Script
```bash
python test_push_notifications.py
```

### Check Registered Devices
```python
from myapp.models import Device
from push_notifications.models import APNSDevice

# List all active devices
Device.objects.filter(is_active=True).values('user__username', 'device_type', 'created_at')

# List all APNs devices
APNSDevice.objects.filter(active=True).values('user__username', 'registration_id')
```

---

## 🌐 API Endpoints

### 1. Register Device
```bash
POST /api/register-device/
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "device_token": "your_apns_token_here",
  "device_type": "ios"
}
```

**cURL Example:**
```bash
curl -X POST https://your-server.com/api/register-device/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"device_token": "abc123...", "device_type": "ios"}'
```

### 2. Test Push Notification
```bash
POST /api/test-push/
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "type": "event_invitation"  # optional
}
```

**cURL Example:**
```bash
curl -X POST https://your-server.com/api/test-push/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type": "event_invitation"}'
```

### 3. Get User Devices
```bash
GET /api/user-devices/
Authorization: Bearer <JWT_TOKEN>
```

**cURL Example:**
```bash
curl -X GET https://your-server.com/api/user-devices/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 📱 iOS Testing

### Check if Device Registered
In Xcode console, look for:
```
📱 Registering device token with server...
✅ Device token registered successfully for user: username
```

### Trigger Notification Permission Request
The app automatically requests permission on login. To manually trigger:
```swift
NotificationManager.shared.requestPermission()
```

### Check Notification Settings
```swift
UNUserNotificationCenter.current().getNotificationSettings { settings in
    print("Authorization Status: \(settings.authorizationStatus)")
    // authorized = 2
}
```

---

## 🔍 Environment Variables

### Required for Production
```bash
APNS_AUTH_KEY_PATH=/path/to/AuthKey_ABC123.p8
APNS_AUTH_KEY_ID=ABC1234DEF
APNS_TEAM_ID=XYZ9876ABC
APNS_TOPIC=com.pinit.app
APNS_USE_SANDBOX=False
```

### For Development/Testing
```bash
APNS_AUTH_KEY_PATH=/path/to/AuthKey_ABC123.p8
APNS_AUTH_KEY_ID=ABC1234DEF
APNS_TEAM_ID=XYZ9876ABC
APNS_TOPIC=com.pinit.app
APNS_USE_SANDBOX=True
```

---

## 🐛 Common Issues & Solutions

### Issue: Notifications not received
```bash
# 1. Check device is registered
python manage.py shell
>>> from myapp.models import Device
>>> Device.objects.filter(is_active=True).count()

# 2. Check APNs configuration
>>> from django.conf import settings
>>> settings.PUSH_NOTIFICATIONS_SETTINGS

# 3. Send test notification and check logs
python test_push_notifications.py
```

### Issue: "Invalid device token"
```bash
# Device tokens change when app is reinstalled
# Force re-registration by logging out and back in
```

### Issue: Works in development, not production
```bash
# Check APNS_USE_SANDBOX setting:
# Development builds: APNS_USE_SANDBOX=True
# TestFlight/Production: APNS_USE_SANDBOX=False
```

---

## 📊 Monitoring Commands

### Check Recent Notifications
```python
from myapp.models import Device
from django.utils import timezone
from datetime import timedelta

# Get devices updated in last 24 hours
recent = timezone.now() - timedelta(days=1)
Device.objects.filter(updated_at__gte=recent).count()
```

### View APNs Errors (if using django-push-notifications with feedback)
```python
from push_notifications.models import APNSDevice

# Check for inactive devices
APNSDevice.objects.filter(active=False).count()
```

---

## 🎯 Notification Types

Available notification types:
- `event_invitation` - Invitation to an event
- `event_update` - Event details changed
- `event_cancellation` - Event was cancelled
- `new_attendee` - Someone joined your event
- `join_request` - Someone wants to join private event
- `request_approved` - Join request approved
- `new_rating` - Received a rating
- `trust_level_change` - Level up notification
- `rating_reminder` - Reminder to rate attendees

### Send Custom Notification Type
```python
send_push_notification(
    user_id=1,
    notification_type='event_update',
    event_title='My Event',
    event_id='uuid-here'
)
```

---

## 📝 Logs to Watch

### Backend Logs
Look for:
```
✅ Device registered for user john: ios - abc123...
✅ Registered APNS device for user john
📱 Sending event_invitation notification to user_id: 1 (1 device(s))
✅ Push notification sent to iOS device: Event Invitation - ...
```

### Error Logs
```
❌ APNS send error for user 1: ...
⚠️  No active devices found for user_id: 1
❌ Device registration failed with status: 401
```

---

## 🔐 Security Checklist

- [ ] `.p8` file is secure and not in version control
- [ ] Environment variables are set on production server
- [ ] JWT authentication is working
- [ ] HTTPS is enabled on backend
- [ ] Bundle ID matches `APNS_TOPIC`

---

## 🚀 Quick Deploy Checklist

1. **Get APNs Auth Key from Apple Developer Portal**
   - Create new key with APNs enabled
   - Download .p8 file (only once!)
   - Note Key ID and Team ID

2. **Set Environment Variables on Railway**
   ```bash
   APNS_AUTH_KEY_PATH=...
   APNS_AUTH_KEY_ID=...
   APNS_TEAM_ID=...
   APNS_TOPIC=com.pinit.app
   APNS_USE_SANDBOX=False
   ```

3. **Deploy Backend**
   ```bash
   git add .
   git commit -m "Configure push notifications"
   git push origin main
   ```

4. **Test on iOS Device**
   - Build and install app
   - Login
   - Accept notification permission
   - Send test notification

5. **Verify in Logs**
   - Check device registration
   - Check test notification sent
   - Check notification received on device

---

## 📚 More Resources

- Full Setup Guide: `PUSH_NOTIFICATION_SETUP_GUIDE.md`
- Test Script: `python test_push_notifications.py`
- Django Admin: `/admin/`

---

Last Updated: October 15, 2025

