<!-- b8045cee-0b51-4beb-be47-b75be613de08 112cabed-cc1f-4ef0-8fb9-2e84720e9ee4 -->
# Complete Security Lock-Down Plan - 100% Coverage

## Current Status: 27% Secured (18/66 endpoints)

**Goal: 100% Security Coverage**

## Critical Findings

**Total Endpoints:** 66

**Currently Protected:** 18 (27%)

**Still Vulnerable:** 48 (73%)

**Debug Endpoints to Remove:** 6

### Remaining Vulnerabilities by Category

#### 1. UNPROTECTED WRITE OPERATIONS (5 endpoints) - CRITICAL

- `logout_user` - No auth required (anyone can logout)
- `update_user_preferences` - Can modify anyone's settings
- `update_matching_preferences` - Can manipulate matching algorithm
- `schedule_rating_reminder` - Spam notification system
- `update_existing_images` - Image manipulation

#### 2. UNPROTECTED SENSITIVE READS (11 endpoints) - HIGH PRIORITY

- `get_friends` - Privacy leak (view anyone's friend list)
- `get_pending_requests` - View private friend requests
- `get_sent_requests` - View private sent requests
- `get_invitations` - View private event invitations
- `get_user_preferences` - Access privacy settings
- `get_user_profile` - Profile snooping
- `get_user_images` - Image URL harvesting
- `get_user_reputation` - Reputation data
- `get_user_ratings` - Rating history
- `get_study_events` - Event data exposure
- `get_user_recent_activity` - Activity tracking

#### 3. PUBLIC READS NEEDING RATE LIMITING (10 endpoints) - MEDIUM

- `get_all_users` - User enumeration attack
- `search_events` - Search abuse/scraping
- `enhanced_search_events` - Advanced search abuse
- `get_event_interactions` - Event data scraping
- `get_event_feed` - Feed scraping
- `get_trust_levels` - System analysis
- `get_profile_completion` - Profile analysis
- `get_matching_preferences` - Matching system analysis
- `get_auto_matched_users` - Match data harvesting
- `get_multiple_user_images` - Bulk image harvesting

#### 4. DEBUG/DEVELOPMENT ENDPOINTS (6 endpoints) - IMMEDIATE REMOVAL

- `run_migration` - Database manipulation ⚠️ CRITICAL
- `test_r2_storage` - Storage system exposure
- `debug_r2_status` - Configuration exposure
- `debug_storage_config` - Security config exposure ⚠️ CRITICAL
- `debug_database_schema` - Schema exposure ⚠️ CRITICAL
- `serve_image` - Uncontrolled image serving

#### 5. DUPLICATE/LEGACY CODE (2 endpoints) - CLEANUP

- Second `add_event_comment` function (line ~1993)
- Second `toggle_event_like` function (line ~2072)

## Implementation Plan

### Phase 1: IMMEDIATE - Remove Debug Endpoints (5 min)

**Delete these functions entirely:**

```python
# Lines to delete:
- run_migration (line 4080)
- test_r2_storage (line 4101)
- debug_r2_status (line 4146)
- debug_storage_config (line 4336)
- debug_database_schema (line 4353)
- serve_image (line 4191) - unless needed for production
```

**Remove from URLs:**

- Remove all debug endpoint routes from `StudyCon/urls.py`

**Security Impact:** Prevents database manipulation, config exposure, schema leakage

### Phase 2: HIGH PRIORITY - Protect Sensitive Read Endpoints (20 min)

Add JWT authentication to protect privacy:

**Friend & Social Data:**

```python
@ratelimit(key='user', rate='100/h', method='GET', block=True)
@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def get_friends(request, username):
    # Verify: request.user.username == username
    # Only users can see their own friends
```

Apply same pattern to:

- `get_pending_requests` - Only own requests
- `get_sent_requests` - Only own sent requests  
- `get_invitations` - Only own invitations
- `get_user_preferences` - Only own preferences
- `get_user_images` - Ownership check

**Event & Activity Data:**

- `get_study_events` - Filter by user access rights
- `get_user_recent_activity` - Ownership check

**Reputation Data (Keep Public but Rate Limited):**

- `get_user_reputation` - Public OK, add rate limiting
- `get_user_ratings` - Public OK, add rate limiting
- `get_user_profile` - Public OK, add rate limiting

### Phase 3: HIGH PRIORITY - Protect Remaining Write Operations (15 min)

**Logout Endpoint:**

```python
@ratelimit(key='user', rate='10/h', method='POST', block=True)
@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def logout_user(request):
    # Blacklist the refresh token
    # Clear user session
```

**Preference Updates:**

```python
@ratelimit(key='user', rate='10/h', method='POST', block=True)
@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def update_user_preferences(request, username):
    if request.user.username != username:
        return JsonResponse({"error": "Forbidden"}, status=403)
    # Update preferences
```

Apply to:

- `update_matching_preferences`
- `schedule_rating_reminder`
- `update_existing_images`

### Phase 4: MEDIUM PRIORITY - Add Rate Limiting to Public Endpoints (10 min)

**User Enumeration Protection:**

```python
@ratelimit(key='ip', rate='50/h', method='GET', block=True)
@csrf_exempt
def get_all_users(request):
    # Add pagination (limit 50 per page)
    # Return minimal data (username only, no emails)
```

**Search Protection:**

- `search_events` - 100/h per IP
- `enhanced_search_events` - 50/h per IP

**Data Access Protection:**

- `get_event_interactions` - 100/h per IP
- `get_event_feed` - 100/h per IP
- `get_trust_levels` - 50/h per IP
- `get_profile_completion` - 100/h per IP
- `get_auto_matched_users` - 50/h per IP
- `get_multiple_user_images` - 20/h per IP

### Phase 5: MEDIUM PRIORITY - Input Validation & Sanitization (20 min)

**Create DRF Serializers:**

```python
# myapp/serializers.py
from rest_framework import serializers
import bleach

class EventCommentSerializer(serializers.Serializer):
    text = serializers.CharField(max_length=500)
    event_id = serializers.UUIDField()
    
    def validate_text(self, value):
        # Sanitize HTML/JS
        return bleach.clean(value, strip=True)
```

**Create serializers for:**

- Event creation/update
- Comment/post creation
- User profile updates
- Rating submissions
- Friend requests

**Apply bleach sanitization to:**

- All text inputs (comments, posts, bios)
- Event descriptions
- Rating references
- User names and profile fields

### Phase 6: CODE CLEANUP - Remove Duplicates (5 min)

**Remove duplicate functions:**

- Second `add_event_comment` (line ~1993)
- Second `toggle_event_like` (line ~2072)

### Phase 7: FINAL HARDENING (10 min)

**Add Security Headers to settings.py:**

```python
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
SECURE_HSTS_SECONDS = 31536000
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
```

**Add Request Size Limits:**

```python
DATA_UPLOAD_MAX_MEMORY_SIZE = 5242880  # 5MB
FILE_UPLOAD_MAX_MEMORY_SIZE = 10485760  # 10MB
```

**Add SQL Injection Protection:**

- Audit all `.raw()` queries
- Ensure all queries use ORM or parameterized queries
- Add query logging in production

## Security Metrics After Implementation

### Before (Current):

- Protected Endpoints: 18/66 (27%)
- Hardcoded Credentials: Fixed ✓
- Debug Endpoints: 6 active ⚠️
- Rate Limiting Coverage: 18/66 (27%)
- Input Validation: 0%
- JWT Authentication: 18/66 (27%)

### After (Target):

- Protected Endpoints: 66/66 (100%) ✓
- Hardcoded Credentials: Fixed ✓
- Debug Endpoints: 0 (all removed) ✓
- Rate Limiting Coverage: 66/66 (100%) ✓
- Input Validation: 100% ✓
- JWT Authentication: 35/66 (53% - sensitive ops only) ✓

## Estimated Time: 90 minutes

## Security Improvement: 73% → 100%

## Testing Checklist

After implementation, test:

1. ✓ All write operations require JWT
2. ✓ Sensitive reads require ownership verification
3. ✓ Public reads have rate limiting
4. ✓ Debug endpoints return 404
5. ✓ Input validation blocks XSS attempts
6. ✓ Rate limits trigger after threshold
7. ✓ Unauthorized access properly rejected
8. ✓ Ownership checks prevent cross-user access

### To-dos

- [ ] Remove or secure debug endpoints: run_migration, test_r2_storage, debug_*