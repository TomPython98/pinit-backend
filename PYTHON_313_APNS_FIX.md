# Python 3.13 APNs Push Notification Fix

## Summary
Replaced the broken `apns2-plus` and `django-push-notifications` packages with modern `aioapns` library that is fully compatible with Python 3.13.

## Changes Made

### 1. Updated `requirements.txt`
**Removed:**
- `django-push-notifications==3.0.0` (depends on broken apns2)
- `apns2-plus==0.7.2.1` (not compatible with Python 3.13)

**Added:**
- `aioapns==3.2` - Modern, async APNs library with Python 3.13 support
- `httpx[http2]>=0.27.0` - Required for HTTP/2 support (APNs requirement)

### 2. Updated `myapp/views.py`

#### Removed APNSDevice Dependency
- Removed import: `from push_notifications.models import APNSDevice`
- Removed APNSDevice registration code from `register_device()` endpoint
- Now only uses the custom `Device` model for tracking devices

#### Rewrote `send_push_notification()` Function
The function now:
- Uses `aioapns` library directly instead of `django-push-notifications`
- Maintains all existing notification types (event_invitation, event_update, etc.)
- Calls new internal `_send_apns_notification()` helper function

#### Added `_send_apns_notification()` Helper Function
New internal function that:
- Uses `aioapns` to send notifications via HTTP/2
- Reads APNs configuration from Django settings (same as before)
- Validates auth key file exists before sending
- Uses async/await with event loop for synchronous Django compatibility
- Provides detailed logging for debugging

### 3. Updated `StudyCon/settings.py`
- Removed `'push_notifications'` from `INSTALLED_APPS`
- Kept all `PUSH_NOTIFICATIONS_SETTINGS` unchanged (same config format)

## What Stayed The Same

✅ **No changes needed to:**
- iOS app code
- Device registration endpoint API
- APNs environment variables (same format)
- Notification payload structure
- All notification types and messages

✅ **Configuration remains identical:**
```bash
APNS_AUTH_KEY_PATH=/path/to/AuthKey_ABC123.p8
APNS_AUTH_KEY_ID=ABC1234DEF
APNS_TEAM_ID=XYZ9876ABC
APNS_TOPIC=com.pinit.app
APNS_USE_SANDBOX=True  # or False for production
```

## Installation Instructions

1. **Install new dependencies:**
```bash
pip install -r requirements.txt
```

2. **Verify the auth key path:**
Make sure your APNs auth key (.p8 file) is accessible at the path specified in `APNS_AUTH_KEY_PATH` environment variable.

3. **Run migrations (if needed):**
```bash
python manage.py migrate
```

4. **Test push notifications:**
```bash
python test_push_notifications.py
```

## Technical Details

### Why aioapns?
- ✅ **Python 3.13 compatible** - Uses modern asyncio and HTTP/2
- ✅ **Actively maintained** - Last updated 2024
- ✅ **Standard compliant** - Follows Apple's APNs HTTP/2 protocol
- ✅ **Well documented** - Clear API and examples
- ✅ **Lightweight** - No heavy dependencies

### How It Works

1. **Device Registration** (unchanged):
   - iOS app sends device token to `/api/register-device/`
   - Backend stores in `Device` model

2. **Sending Notifications**:
   - `send_push_notification()` is called with user_id and notification_type
   - Gets all active devices for user from `Device` model
   - For iOS devices, calls `_send_apns_notification()`
   - Creates HTTP/2 connection to APNs using auth key
   - Sends notification with proper payload structure
   - Closes connection

3. **Async/Sync Bridge**:
   - `aioapns` is async-first
   - `_send_apns_notification()` runs async code synchronously
   - Creates new event loop for each notification
   - Compatible with Django's synchronous views

## Notification Types Supported

All existing notification types are maintained:
- `event_invitation` - User invited to event
- `event_update` - Event details changed
- `event_cancellation` - Event cancelled
- `new_attendee` - Someone joined your event
- `join_request` - Someone wants to join your event
- `request_approved` - Join request approved
- `new_rating` - Received a rating
- `trust_level_change` - Leveled up
- `rating_reminder` - Reminder to rate attendees
- `review_reminder` - Reminder to review attendees

## Testing

### Test with curl:
```bash
curl -X POST https://your-backend.railway.app/api/test-push/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

### Check APNs configuration:
```bash
curl https://your-backend.railway.app/api/debug-apns/
```

### Expected log output:
```
📱 Sending event_invitation notification to user_id: 1 (1 device(s))
🔍 Attempting to send APNs notification...
🔍 APNs device: 1234567890abcdef...
🔍 Message: John invited you to Study Session
🔍 Title: Event Invitation
🔍 Using sandbox: True
✅ APNs notification sent successfully: <APNsResponse>
✅ Push notification sent to iOS device: Event Invitation - John invited you to Study Session
```

## Migration Notes

### For Development:
```bash
# 1. Update code (already done)
# 2. Install dependencies
pip install -r requirements.txt

# 3. Restart Django server
python manage.py runserver
```

### For Railway Deployment:
```bash
# 1. Commit changes
git add requirements.txt myapp/views.py StudyCon/settings.py
git commit -m "Fix: Replace apns2 with aioapns for Python 3.13 compatibility"

# 2. Push to Railway
git push origin main

# 3. Railway will automatically:
#    - Install new dependencies from requirements.txt
#    - Restart the service
#    - Push notifications will work automatically
```

### Environment Variables to Verify:
Make sure these are set in Railway:
- `APNS_AUTH_KEY_PATH` or `APNS_AUTH_KEY_CONTENT` ✅
- `APNS_AUTH_KEY_ID` ✅
- `APNS_TEAM_ID` ✅
- `APNS_TOPIC` ✅
- `APNS_USE_SANDBOX` ✅

## Troubleshooting

### Error: "APNs auth key not found"
- Check `APNS_AUTH_KEY_PATH` points to valid .p8 file
- Or use `APNS_AUTH_KEY_CONTENT` to pass file content directly

### Error: "APNs configuration incomplete"
- Verify `APNS_AUTH_KEY_ID` and `APNS_TEAM_ID` are set
- Both should be 10-character strings

### Error: "Invalid device token"
- Device token from iOS might be invalid
- Re-register device from iOS app
- Check device token format (64 hex characters)

### Error: "BadDeviceToken"
- Wrong `APNS_USE_SANDBOX` setting
- Development builds need `APNS_USE_SANDBOX=True`
- Production/TestFlight needs `APNS_USE_SANDBOX=False`

## Benefits of This Change

✅ **Python 3.13 Compatible** - Works with latest Python
✅ **No Breaking Changes** - Same API for iOS and backend
✅ **Better Performance** - Native HTTP/2 support
✅ **More Reliable** - Actively maintained library
✅ **Cleaner Code** - Removed unused django-push-notifications dependency
✅ **Same Configuration** - No environment variable changes needed

## Next Steps

1. ✅ Install dependencies: `pip install -r requirements.txt`
2. ✅ Test locally with test_push_notifications.py
3. ✅ Commit and push to Railway
4. ✅ Verify push notifications work on production
5. ✅ Test on both development (sandbox) and production apps

## Files Modified

- `requirements.txt` - Updated dependencies
- `myapp/views.py` - Rewrote push notification implementation
- `StudyCon/settings.py` - Removed django-push-notifications app
- `PYTHON_313_APNS_FIX.md` - This documentation

## Files Unchanged

- All iOS app files (no changes needed)
- `myapp/models.py` - Device model unchanged
- Environment variable format unchanged
- APNs auth key files unchanged

---

**Status: ✅ Ready for Testing**

The implementation is complete and ready to use. Push notifications will now work with Python 3.13!

