# Auto-Matching Troubleshooting Guide

## 🚨 Common Issue: Auto-Matched Events Not Appearing on Map

### Problem Description
Auto-matched events are created successfully in the database but don't appear on the map view in the iOS app.

### Root Cause Analysis
The issue occurs when test data events have **past dates**. The `/api/get_study_events/<username>/` endpoint correctly filters out events where `end_time < now`, which means auto-matched invitations to past events won't be returned.

### Symptoms
- ✅ Auto-matched invitations exist in database (`EventInvitation.objects.filter(is_auto_matched=True)`)
- ✅ `/api/get_invitations/<username>/` returns auto-matched events in "Potential Matches" tab
- ❌ Auto-matched events don't appear on map
- ❌ `/api/get_study_events/<username>/` returns fewer events than expected

### Diagnostic Commands

#### 1. Check Event Dates
```bash
cd Back_End/StudyCon/StudyCon && source ../venv/bin/activate
python manage.py shell -c "
from myapp.models import StudyEvent
from django.utils import timezone

now = timezone.now()
past_events = StudyEvent.objects.filter(end_time__lt=now).count()
future_events = StudyEvent.objects.filter(end_time__gt=now).count()

print(f'Past events: {past_events}')
print(f'Future events: {future_events}')
"
```

#### 2. Check Auto-Matched Invitations
```bash
python manage.py shell -c "
from myapp.models import EventInvitation, User

user = User.objects.get(username='test_username')
auto_invitations = EventInvitation.objects.filter(user=user, is_auto_matched=True)

print(f'Auto-matched invitations: {auto_invitations.count()}')
for inv in auto_invitations[:3]:
    print(f'  - {inv.event.title} (Future: {inv.event.end_time > timezone.now()})')
"
```

#### 3. Test API Endpoint
```bash
curl -s "http://localhost:8000/api/get_study_events/test_username/" | python3 -c "
import sys, json
data = json.load(sys.stdin)
events = data.get('events', [])
auto_matched = sum(1 for e in events if e.get('isAutoMatched', False))
print(f'Total events: {len(events)}')
print(f'Auto-matched: {auto_matched}')
"
```

### Solution: Update Event Dates

```python
# Run this in Django shell
from myapp.models import StudyEvent
from django.utils import timezone
import random
from datetime import timedelta

now = timezone.now()

# Update all events to future dates
for event in StudyEvent.objects.all():
    days_ahead = random.randint(1, 30)
    hours_ahead = random.randint(1, 23)
    
    new_time = now + timedelta(days=days_ahead, hours=hours_ahead)
    new_end_time = new_time + timedelta(hours=2)
    
    event.time = new_time
    event.end_time = new_end_time
    event.save()

print("✅ All events updated to future dates")
```

### Prevention: Fix Data Generation Scripts

When creating test data, ensure events have **future dates**:

```python
# In data generation scripts
from django.utils import timezone
from datetime import timedelta
import random

# Generate future dates
now = timezone.now()
days_ahead = random.randint(1, 30)
hours_ahead = random.randint(1, 23)

event_time = now + timedelta(days=days_ahead, hours=hours_ahead)
event_end_time = event_time + timedelta(hours=2)

StudyEvent.objects.create(
    title="Test Event",
    time=event_time,
    end_time=event_end_time,
    # ... other fields
)
```

### System Architecture Context

#### How Auto-Matching Should Work
1. **Data Generation**: Scripts create users, events, and auto-matched invitations
2. **API Endpoint**: `/api/get_study_events/<username>/` returns user's events including auto-matched ones
3. **Frontend**: CalendarManager fetches events and map displays them
4. **Real-time**: WebSocket updates keep data synchronized

#### Key API Endpoints
- **✅ Correct for Map**: `/api/get_study_events/<username>/` - Returns user-specific events with `isAutoMatched` field
- **❌ Wrong for Map**: `/api/enhanced_search_events/` - Public event discovery, no user context
- **✅ Correct for Invitations**: `/api/get_invitations/<username>/` - Returns pending invitations

### Related Documentation
- [System Interactions](./System_Interactions.md#event-discovery-flow)
- [API Documentation](./API_Documentation.md#get-study-events)
- [Frontend Architecture](./Frontend_Architecture.md#calendar-manager)

### Verification Steps
After applying the fix:

1. **Check API Response**:
   ```bash
   curl "http://localhost:8000/api/get_study_events/username/" | jq '.events | length'
   ```

2. **Verify Auto-Matched Count**:
   ```bash
   curl "http://localhost:8000/api/get_study_events/username/" | jq '[.events[] | select(.isAutoMatched == true)] | length'
   ```

3. **Test in iOS App**:
   - Log in with test account
   - Check map view for auto-matched events
   - Verify events appear with proper indicators

### Last Updated
**Date**: January 2025  
**Issue**: Auto-matched events not appearing due to past event dates  
**Status**: ✅ Resolved  
**Prevention**: Updated data generation scripts to use future dates

---

## 📋 Quick Reference

### Problem Checklist
- [ ] Check if events have future dates
- [ ] Verify auto-matched invitations exist in database
- [ ] Test correct API endpoint (`/api/get_study_events/<username>/`)
- [ ] Confirm CalendarManager is being used (not direct API calls in map)

### Solution Checklist  
- [ ] Update existing events to future dates
- [ ] Fix data generation scripts to use future dates
- [ ] Verify API returns auto-matched events
- [ ] Test in iOS app

### Prevention Checklist
- [ ] Always use `timezone.now() + timedelta()` for event dates
- [ ] Add date validation in data generation scripts
- [ ] Include future date checks in test suites
- [ ] Document date requirements for test data
