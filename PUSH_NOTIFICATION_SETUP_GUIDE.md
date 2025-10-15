# Push Notification Setup Guide for PinIt

This guide will help you configure push notifications for both iOS and Android platforms.

## Overview

Push notifications are now properly integrated in PinIt! This document covers:
1. iOS APNs (Apple Push Notification service) setup
2. Backend configuration
3. Testing and troubleshooting

---

## 🍎 iOS APNs Setup

### Step 1: Create APNs Authentication Key (Recommended)

**Modern Token-Based Authentication** - This is the recommended approach as it:
- Never expires (unlike certificates)
- Works for both development and production
- Easier to maintain

#### 1.1 Generate APNs Auth Key from Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
2. Click the **+** button to create a new key
3. Give it a name (e.g., "PinIt Push Notifications")
4. Check **Apple Push Notifications service (APNs)**
5. Click **Continue** and then **Register**
6. **Download the .p8 file** (you can only download it once!)
7. Note your **Key ID** (10-character string, e.g., `ABC1234DEF`)
8. Note your **Team ID** (found in top-right corner of developer portal)

#### 1.2 Save the Auth Key Securely

```bash
# Save the downloaded .p8 file in a secure location
# For Railway deployment, you'll upload this file
mkdir -p /path/to/secure/location
mv ~/Downloads/AuthKey_ABC1234DEF.p8 /path/to/secure/location/
```

### Step 2: Configure Backend Environment Variables

You need to set these environment variables on your deployment platform (Railway, Heroku, etc.):

```bash
# Modern APNs Token-Based Authentication (RECOMMENDED)
APNS_AUTH_KEY_PATH=/path/to/AuthKey_ABC1234DEF.p8
APNS_AUTH_KEY_ID=ABC1234DEF      # Your 10-character Key ID
APNS_TEAM_ID=XYZ9876ABC          # Your 10-character Team ID
APNS_TOPIC=com.pinit.app         # Your app's Bundle ID
APNS_USE_SANDBOX=False           # True for development, False for production
```

#### Setting Environment Variables on Railway:

1. Go to your Railway project dashboard
2. Select your service
3. Go to **Variables** tab
4. Add each variable above
5. For `APNS_AUTH_KEY_PATH`, you have two options:
   - Upload the .p8 file to Railway and use the path
   - Or store the key content directly (see alternative method below)

#### Alternative: Store APNs Key Content as Environment Variable

Instead of uploading the .p8 file, you can store its content:

```bash
# Read the .p8 file content
cat /path/to/AuthKey_ABC1234DEF.p8

# Set it as an environment variable (copy the entire content)
APNS_AUTH_KEY_CONTENT="-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
-----END PRIVATE KEY-----"
```

Then update `settings.py` to handle both:

```python
# In StudyCon/settings.py
import os
import tempfile

# Handle APNs auth key from file or environment variable
apns_auth_key_path = os.environ.get('APNS_AUTH_KEY_PATH', '')
apns_auth_key_content = os.environ.get('APNS_AUTH_KEY_CONTENT', '')

if apns_auth_key_content and not apns_auth_key_path:
    # Create a temporary file with the key content
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.p8') as f:
        f.write(apns_auth_key_content)
        apns_auth_key_path = f.name
```

---

### Step 3: Configure iOS App Capabilities

1. Open your Xcode project
2. Select your app target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **Push Notifications**
6. Add **Background Modes** and enable:
   - Remote notifications

---

### Step 4: Update iOS Bundle ID

Make sure your app's Bundle ID matches the `APNS_TOPIC`:

1. In Xcode, select your project
2. Select your target
3. Go to **General** tab
4. Set **Bundle Identifier** to `com.pinit.app` (or whatever you set as APNS_TOPIC)

---

## 🔧 Backend Configuration (Already Done!)

The following has been implemented:

### ✅ Device Registration Endpoint
- **URL**: `/api/register-device/`
- **Method**: POST
- **Authentication**: JWT Bearer token required
- **Body**:
```json
{
  "device_token": "your_device_token_here",
  "device_type": "ios"
}
```

### ✅ Push Notification Types Supported

The following notification types are already implemented:

1. **event_invitation** - When a user is invited to an event
2. **event_update** - When an event is updated
3. **event_cancellation** - When an event is cancelled
4. **new_attendee** - When someone joins your event
5. **join_request** - When someone requests to join your private event
6. **request_approved** - When your join request is approved
7. **new_rating** - When you receive a rating
8. **trust_level_change** - When you level up
9. **rating_reminder** - Reminder to rate attendees

---

## 🧪 Testing Push Notifications

### Test 1: Device Registration

After logging in, the app should automatically register the device. Check the backend logs:

```
✅ Device registered for user john_doe: ios - abc123...
✅ Registered APNS device for user john_doe
```

### Test 2: Send a Test Notification

You can test by creating an event and inviting another user. The invited user should receive a push notification.

Or use Django shell to send a test:

```python
from myapp.views import send_push_notification

# Send test notification to user ID 1
send_push_notification(
    user_id=1,
    notification_type='event_invitation',
    event_title='Test Event',
    from_user='Test User',
    event_id='some-uuid-here'
)
```

### Test 3: Check APNs Connection

Add this test endpoint to your Django views (for debugging only):

```python
@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def test_push_notification(request):
    """Test endpoint to send a push notification to the current user"""
    try:
        send_push_notification(
            user_id=request.user.id,
            notification_type='event_invitation',
            event_title='Test Event',
            from_user='System Test',
            event_id='test-123'
        )
        return Response({'message': 'Test notification sent'})
    except Exception as e:
        return Response({'error': str(e)}, status=500)
```

Then add to `urls.py`:
```python
path('api/test-push/', views.test_push_notification, name='test_push'),
```

---

## 🐛 Troubleshooting

### Issue: No device token received

**Symptoms**: App never receives a device token, AppDelegate `didRegisterForRemoteNotificationsWithDeviceToken` never called.

**Solutions**:
1. Make sure push notifications capability is enabled in Xcode
2. Test on a real device (push notifications don't work on simulator for production APNs)
3. Check that you're signed in with a valid Apple Developer account
4. Verify bundle ID matches your provisioning profile

### Issue: Device registered but no notifications received

**Symptoms**: Backend logs show notifications sent but nothing appears on device.

**Solutions**:
1. Check `APNS_USE_SANDBOX` setting:
   - Use `True` for development builds
   - Use `False` for TestFlight and App Store builds
2. Verify the APNs auth key credentials are correct
3. Check device notification settings (Settings > PinIt > Notifications)
4. Make sure notification permission is granted in the app

### Issue: "Invalid device token" error

**Solutions**:
1. Device tokens change when:
   - App is reinstalled
   - Device is restored
   - App is updated
2. Make sure device re-registers after these events
3. The app already handles this by registering on each login

### Issue: Notifications work in development but not production

**Solutions**:
1. Check `APNS_USE_SANDBOX`:
   - Development/Debug builds: `True`
   - TestFlight/Production builds: `False`
2. Verify your production push certificate/key is valid
3. Check bundle ID matches exactly

---

## 📊 Monitoring

### Backend Logs

The push notification system now includes comprehensive logging:

```
📱 Sending event_invitation notification to user_id: 123 (1 device(s))
✅ Push notification sent to iOS device: Event Invitation - John invited you to Study Session
```

### Check Registered Devices

Use Django admin or shell:

```python
from myapp.models import Device
from push_notifications.models import APNSDevice

# Check devices in your custom model
Device.objects.filter(is_active=True).count()

# Check APNs devices
APNSDevice.objects.filter(active=True).count()
```

---

## 🔒 Security Notes

1. **Never commit** your .p8 files to version control
2. Add to `.gitignore`:
   ```
   *.p8
   *.pem
   *.p12
   ```
3. Store APNs credentials securely as environment variables
4. Rotate keys periodically (at least once per year)
5. Use different keys for development and production if possible

---

## 📱 iOS Implementation Details

The iOS app is already configured with:

✅ **NotificationManager** - Handles local and remote notifications
✅ **AppDelegate** - Registers device tokens with backend
✅ **JWT Authentication** - Securely registers devices
✅ **Automatic Registration** - Registers on login
✅ **Notification Handling** - Processes all notification types

---

## 🚀 Deployment Checklist

Before deploying to production:

- [ ] APNs Auth Key (.p8 file) obtained from Apple Developer Portal
- [ ] Key ID and Team ID noted
- [ ] Environment variables set on Railway/hosting platform
- [ ] `APNS_USE_SANDBOX=False` for production
- [ ] Bundle ID matches `APNS_TOPIC`
- [ ] Push Notifications capability enabled in Xcode
- [ ] Tested on real device (not simulator)
- [ ] App Store / TestFlight build tested
- [ ] Monitoring and logging verified

---

## 🆘 Need Help?

If you're still having issues:

1. Check the backend logs for errors
2. Check Xcode console for iOS errors
3. Verify all environment variables are set correctly
4. Test with the Django shell test script
5. Make sure you're testing on a real device for production builds

---

## 📚 Additional Resources

- [Apple Push Notification Service Documentation](https://developer.apple.com/documentation/usernotifications)
- [django-push-notifications Documentation](https://github.com/jazzband/django-push-notifications)
- [Token-Based APNs Guide](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns)

---

## ✅ What's Next?

After setting up push notifications:

1. **Android Support**: Add FCM (Firebase Cloud Messaging) for Android
2. **Rich Notifications**: Add images and actions to notifications
3. **Notification Preferences**: Let users customize which notifications they receive
4. **Analytics**: Track notification delivery and engagement
5. **A/B Testing**: Test different notification messages

---

Last Updated: October 15, 2025
Version: 1.0

