#!/usr/bin/env python3
"""
API Testing and Fixing Script
Tests all endpoints and attempts to identify and fix issues
"""

import requests
import json
import time
import random
from datetime import datetime, timedelta

# Production server URL
PRODUCTION_BASE_URL = "https://pinit-backend-production.up.railway.app/api/"

def test_endpoint(endpoint, method='GET', data=None, expected_status=200):
    """Test an API endpoint and return results"""
    url = f"{PRODUCTION_BASE_URL}{endpoint}"
    
    try:
        if method == 'GET':
            response = requests.get(url, timeout=10)
        elif method == 'POST':
            response = requests.post(url, json=data, timeout=10)
        elif method == 'PUT':
            response = requests.put(url, json=data, timeout=10)
        elif method == 'DELETE':
            response = requests.delete(url, timeout=10)
        
        return {
            'endpoint': endpoint,
            'method': method,
            'status_code': response.status_code,
            'success': response.status_code == expected_status,
            'response': response.text[:500] if response.text else None,
            'headers': dict(response.headers)
        }
    except Exception as e:
        return {
            'endpoint': endpoint,
            'method': method,
            'status_code': 'ERROR',
            'success': False,
            'error': str(e),
            'response': None
        }

def test_authentication():
    """Test authentication endpoints"""
    print("🔐 Testing Authentication Endpoints...")
    
    # Test registration
    test_user = {
        "username": f"test_auth_{random.randint(1000, 9999)}",
        "password": "test123",
        "first_name": "Test",
        "last_name": "User",
        "email": f"test_{random.randint(1000, 9999)}@example.com",
        "university": "UBA",
        "degree": "Computer Science",
        "year": "3rd Year",
        "country": "Argentina",
        "bio": "Test user for API testing",
        "interests": ["Technology"],
        "skills": ["Programming"],
        "auto_invite_preference": True,
        "preferred_radius": 5
    }
    
    register_result = test_endpoint("register/", 'POST', test_user, 201)
    print(f"  Registration: {'✅' if register_result['success'] else '❌'} - {register_result['status_code']}")
    
    if register_result['success']:
        # Test login
        login_data = {
            "username": test_user["username"],
            "password": test_user["password"]
        }
        login_result = test_endpoint("login/", 'POST', login_data, 200)
        print(f"  Login: {'✅' if login_result['success'] else '❌'} - {login_result['status_code']}")
        
        return test_user["username"]
    
    return None

def test_event_management(username):
    """Test event management endpoints"""
    print("📅 Testing Event Management Endpoints...")
    
    if not username:
        print("  ❌ No username provided, skipping event tests")
        return None
    
    # Test create event
    event_data = {
        "host": username,
        "title": f"Test Event - {random.randint(100, 999)}",
        "description": "Test event for API testing",
        "latitude": -34.5889 + random.uniform(-0.01, 0.01),
        "longitude": -58.4108 + random.uniform(-0.01, 0.01),
        "time": (datetime.now() + timedelta(days=1)).isoformat(),
        "end_time": (datetime.now() + timedelta(days=1, hours=2)).isoformat(),
        "max_participants": 10,
        "event_type": "study",
        "interest_tags": ["Study", "Test"],
        "auto_matching_enabled": True
    }
    
    create_result = test_endpoint("create_study_event/", 'POST', event_data, 201)
    print(f"  Create Event: {'✅' if create_result['success'] else '❌'} - {create_result['status_code']}")
    
    if create_result['success']:
        try:
            response_data = json.loads(create_result['response'])
            event_id = response_data.get('event_id')
            print(f"  Event ID: {event_id}")
            return event_id
        except:
            print("  ❌ Could not parse event ID from response")
            return None
    
    return None

def test_event_interactions(username, event_id):
    """Test event interaction endpoints"""
    print("💬 Testing Event Interaction Endpoints...")
    
    if not username or not event_id:
        print("  ❌ Missing username or event_id, skipping interaction tests")
        return
    
    # Test RSVP
    rsvp_data = {"username": username, "event_id": event_id}
    rsvp_result = test_endpoint("rsvp_study_event/", 'POST', rsvp_data, 200)
    print(f"  RSVP: {'✅' if rsvp_result['success'] else '❌'} - {rsvp_result['status_code']}")
    
    # Test Comment
    comment_data = {"username": username, "event_id": event_id, "text": "Test comment"}
    comment_result = test_endpoint("events/comment/", 'POST', comment_data, 200)
    print(f"  Comment: {'✅' if comment_result['success'] else '❌'} - {comment_result['status_code']}")
    
    # Test Like
    like_data = {"username": username, "event_id": event_id}
    like_result = test_endpoint("events/like/", 'POST', like_data, 200)
    print(f"  Like: {'✅' if like_result['success'] else '❌'} - {like_result['status_code']}")
    
    # Test Share
    share_data = {"username": username, "event_id": event_id, "shared_platform": "test"}
    share_result = test_endpoint("events/share/", 'POST', share_data, 200)
    print(f"  Share: {'✅' if share_result['success'] else '❌'} - {share_result['status_code']}")

def test_social_connections(username):
    """Test social connection endpoints"""
    print("🤝 Testing Social Connection Endpoints...")
    
    if not username:
        print("  ❌ No username provided, skipping social tests")
        return
    
    # Create a second user for testing
    test_user2 = {
        "username": f"test_social_{random.randint(1000, 9999)}",
        "password": "test123",
        "first_name": "Social",
        "last_name": "Test",
        "email": f"social_{random.randint(1000, 9999)}@example.com",
        "university": "UBA",
        "degree": "Business",
        "year": "2nd Year",
        "country": "Argentina",
        "bio": "Social test user",
        "interests": ["Business"],
        "skills": ["Leadership"],
        "auto_invite_preference": False,
        "preferred_radius": 3
    }
    
    # Register second user
    register_result = test_endpoint("register/", 'POST', test_user2, 201)
    print(f"  Second User Registration: {'✅' if register_result['success'] else '❌'} - {register_result['status_code']}")
    
    if register_result['success']:
        # Test friend request
        friend_request_data = {"from_user": username, "to_user": test_user2["username"]}
        friend_request_result = test_endpoint("send_friend_request/", 'POST', friend_request_data, 201)
        print(f"  Send Friend Request: {'✅' if friend_request_result['success'] else '❌'} - {friend_request_result['status_code']}")
        
        # Test accept friend request
        accept_request_data = {"from_user": username, "to_user": test_user2["username"]}
        accept_request_result = test_endpoint("accept_friend_request/", 'POST', accept_request_data, 200)
        print(f"  Accept Friend Request: {'✅' if accept_request_result['success'] else '❌'} - {accept_request_result['status_code']}")
        
        return test_user2["username"]
    
    return None

def test_missing_endpoints():
    """Test endpoints that should exist but don't"""
    print("❌ Testing Missing Endpoints...")
    
    missing_endpoints = [
        ("health/", "GET"),
        ("invite_user_to_event/", "POST"),
        ("run_auto_matching/", "POST"),
        ("events/", "GET"),
        ("users/", "GET"),
        ("friends/", "GET"),
        ("notifications/", "GET")
    ]
    
    for endpoint, method in missing_endpoints:
        result = test_endpoint(endpoint, method)
        print(f"  {method} {endpoint}: {'❌' if result['status_code'] == 404 else '⚠️'} - {result['status_code']}")

def test_friend_request_issue():
    """Test the friend request acceptance issue"""
    print("🔍 Investigating Friend Request Issue...")
    
    # Create two users
    user1_data = {
        "username": f"friend_test_1_{random.randint(1000, 9999)}",
        "password": "test123",
        "first_name": "Friend",
        "last_name": "One",
        "email": f"friend1_{random.randint(1000, 9999)}@example.com",
        "university": "UBA",
        "degree": "Computer Science",
        "year": "3rd Year",
        "country": "Argentina",
        "bio": "Friend test user 1",
        "interests": ["Technology"],
        "skills": ["Programming"],
        "auto_invite_preference": True,
        "preferred_radius": 5
    }
    
    user2_data = {
        "username": f"friend_test_2_{random.randint(1000, 9999)}",
        "password": "test123",
        "first_name": "Friend",
        "last_name": "Two",
        "email": f"friend2_{random.randint(1000, 9999)}@example.com",
        "university": "UBA",
        "degree": "Business",
        "year": "2nd Year",
        "country": "Argentina",
        "bio": "Friend test user 2",
        "interests": ["Business"],
        "skills": ["Leadership"],
        "auto_invite_preference": False,
        "preferred_radius": 3
    }
    
    # Register both users
    user1_result = test_endpoint("register/", 'POST', user1_data, 201)
    user2_result = test_endpoint("register/", 'POST', user2_data, 201)
    
    if user1_result['success'] and user2_result['success']:
        print(f"  ✅ Both users created successfully")
        
        # Send friend request
        friend_request_data = {"from_user": user1_data["username"], "to_user": user2_data["username"]}
        request_result = test_endpoint("send_friend_request/", 'POST', friend_request_data, 201)
        print(f"  Friend Request Sent: {'✅' if request_result['success'] else '❌'}")
        
        if request_result['success']:
            # Wait a moment
            time.sleep(1)
            
            # Try to accept the request
            accept_data = {"from_user": user1_data["username"], "to_user": user2_data["username"]}
            accept_result = test_endpoint("accept_friend_request/", 'POST', accept_data, 200)
            print(f"  Friend Request Accept: {'✅' if accept_result['success'] else '❌'}")
            
            if not accept_result['success']:
                print(f"  Error Response: {accept_result['response']}")
                
                # Try the reverse direction
                reverse_accept_data = {"from_user": user2_data["username"], "to_user": user1_data["username"]}
                reverse_accept_result = test_endpoint("accept_friend_request/", 'POST', reverse_accept_data, 200)
                print(f"  Reverse Accept: {'✅' if reverse_accept_result['success'] else '❌'}")
                
                if not reverse_accept_result['success']:
                    print(f"  Reverse Error Response: {reverse_accept_result['response']}")

def generate_fix_recommendations():
    """Generate recommendations for fixing identified issues"""
    print("\n🛠️ FIX RECOMMENDATIONS:")
    print("=" * 50)
    
    print("\n1. FRIEND REQUEST ACCEPTANCE ISSUE:")
    print("   - Problem: Many friend request acceptances fail with 'Friend request not found'")
    print("   - Possible Causes:")
    print("     * Timing issue - request not yet processed")
    print("     * Wrong parameter order in accept endpoint")
    print("     * Missing validation for request existence")
    print("   - Recommended Fix:")
    print("     * Add delay between send and accept")
    print("     * Verify parameter order matches database schema")
    print("     * Add proper error handling and validation")
    
    print("\n2. MISSING ENDPOINTS:")
    print("   - Problem: Several endpoints return 404")
    print("   - Missing Endpoints:")
    print("     * GET /health/ - Server health check")
    print("     * POST /invite_user_to_event/ - Direct event invitations")
    print("     * POST /run_auto_matching/ - Auto-matching system")
    print("     * GET /events/ - List all events")
    print("     * GET /users/ - List all users")
    print("     * GET /friends/ - List user's friends")
    print("     * GET /notifications/ - User notifications")
    print("   - Recommended Fix:")
    print("     * Implement missing endpoints")
    print("     * Add proper error handling")
    print("     * Add input validation")
    
    print("\n3. ERROR HANDLING IMPROVEMENTS:")
    print("   - Problem: Generic 404 errors make debugging difficult")
    print("   - Recommended Fix:")
    print("     * Add specific error messages")
    print("     * Add error codes")
    print("     * Add request validation")
    print("     * Add logging for debugging")
    
    print("\n4. API DOCUMENTATION:")
    print("   - Problem: No self-documenting API")
    print("   - Recommended Fix:")
    print("     * Add OpenAPI/Swagger documentation")
    print("     * Add endpoint descriptions")
    print("     * Add request/response examples")
    print("     * Add error code documentation")

def main():
    """Main testing function"""
    print("🧪 PinIt Backend API Testing and Analysis")
    print("=" * 50)
    
    # Test authentication
    username = test_authentication()
    print()
    
    # Test event management
    event_id = test_event_management(username)
    print()
    
    # Test event interactions
    test_event_interactions(username, event_id)
    print()
    
    # Test social connections
    test_social_connections(username)
    print()
    
    # Test missing endpoints
    test_missing_endpoints()
    print()
    
    # Investigate friend request issue
    test_friend_request_issue()
    print()
    
    # Generate fix recommendations
    generate_fix_recommendations()
    
    print("\n🎉 API Testing Complete!")
    print("Check the results above for working and non-working endpoints.")

if __name__ == "__main__":
    main()
