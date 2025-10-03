#!/usr/bin/env python3
"""
User Data Investigation Script
Check specific user data and identify missing information
"""

import requests
import json
import time

# Production server URL
PRODUCTION_BASE_URL = "https://pinit-backend-production.up.railway.app/api/"

def check_user_profile(username):
    """Check user profile completeness"""
    print(f"🔍 Investigating user: {username}")
    print("=" * 50)
    
    # Try to get user profile (this endpoint might not exist)
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}users/{username}/", timeout=10)
        if response.status_code == 200:
            profile_data = response.json()
            print("✅ User profile found:")
            print(json.dumps(profile_data, indent=2))
        else:
            print(f"❌ User profile endpoint not found: {response.status_code}")
    except Exception as e:
        print(f"❌ Error getting user profile: {e}")
    
    # Check if user exists by trying to login
    login_data = {
        "username": username,
        "password": "password123"
    }
    
    try:
        response = requests.post(f"{PRODUCTION_BASE_URL}login/", json=login_data, timeout=10)
        if response.status_code == 200:
            print("✅ User login successful - user exists")
            login_result = response.json()
            print(f"Login response: {json.dumps(login_result, indent=2)}")
        else:
            print(f"❌ User login failed: {response.status_code}")
            print(f"Response: {response.text}")
    except Exception as e:
        print(f"❌ Error during login: {e}")

def check_user_events(username):
    """Check events created by user"""
    print(f"\n📅 Checking events for {username}")
    print("-" * 30)
    
    # Try to get events list
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}events/", timeout=10)
        if response.status_code == 200:
            events_data = response.json()
            user_events = [e for e in events_data.get('events', []) if e.get('host') == username]
            print(f"✅ Found {len(user_events)} events created by {username}")
            for event in user_events:
                print(f"  - {event.get('title')} (ID: {event.get('id')})")
        else:
            print(f"❌ Events list endpoint not found: {response.status_code}")
    except Exception as e:
        print(f"❌ Error getting events: {e}")

def check_user_friends(username):
    """Check user's friends"""
    print(f"\n🤝 Checking friends for {username}")
    print("-" * 30)
    
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}users/{username}/friends/", timeout=10)
        if response.status_code == 200:
            friends_data = response.json()
            print(f"✅ Found {len(friends_data.get('friends', []))} friends")
            for friend in friends_data.get('friends', []):
                print(f"  - {friend.get('username')} ({friend.get('first_name')} {friend.get('last_name')})")
        else:
            print(f"❌ Friends endpoint not found: {response.status_code}")
    except Exception as e:
        print(f"❌ Error getting friends: {e}")

def check_user_invitations(username):
    """Check user's invitations"""
    print(f"\n📨 Checking invitations for {username}")
    print("-" * 30)
    
    # Try to get notifications (which might include invitations)
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}users/{username}/notifications/", timeout=10)
        if response.status_code == 200:
            notifications_data = response.json()
            print(f"✅ Found {len(notifications_data.get('notifications', []))} notifications")
            for notification in notifications_data.get('notifications', []):
                print(f"  - {notification.get('title')}: {notification.get('message')}")
        else:
            print(f"❌ Notifications endpoint not found: {response.status_code}")
    except Exception as e:
        print(f"❌ Error getting notifications: {e}")

def check_user_rsvps(username):
    """Check user's RSVPs"""
    print(f"\n📝 Checking RSVPs for {username}")
    print("-" * 30)
    
    # This is harder to check without a specific endpoint
    # We can try to get events and see if user is in participants
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}events/", timeout=10)
        if response.status_code == 200:
            events_data = response.json()
            rsvp_count = 0
            for event in events_data.get('events', []):
                if username in event.get('participants', []):
                    rsvp_count += 1
                    print(f"  - RSVP'd to: {event.get('title')}")
            print(f"✅ Found {rsvp_count} RSVPs")
        else:
            print(f"❌ Events list endpoint not found: {response.status_code}")
    except Exception as e:
        print(f"❌ Error checking RSVPs: {e}")

def check_profile_completeness(username):
    """Check profile completion percentage"""
    print(f"\n📊 Checking profile completeness for {username}")
    print("-" * 30)
    
    # Try to get user data through login
    login_data = {
        "username": username,
        "password": "password123"
    }
    
    try:
        response = requests.post(f"{PRODUCTION_BASE_URL}login/", json=login_data, timeout=10)
        if response.status_code == 200:
            login_result = response.json()
            user_data = login_result.get('user', {})
            
            # Calculate completion percentage
            required_fields = [
                'username', 'first_name', 'last_name', 'email', 
                'university', 'degree', 'year', 'country', 'bio'
            ]
            
            completed_fields = 0
            total_fields = len(required_fields)
            
            for field in required_fields:
                if user_data.get(field) and user_data[field].strip():
                    completed_fields += 1
                else:
                    print(f"  ❌ Missing: {field}")
            
            completion_percentage = (completed_fields / total_fields) * 100
            print(f"✅ Profile completion: {completion_percentage:.1f}% ({completed_fields}/{total_fields} fields)")
            
            # Check optional fields
            optional_fields = ['interests', 'skills', 'auto_invite_preference', 'preferred_radius']
            optional_completed = 0
            for field in optional_fields:
                if user_data.get(field):
                    optional_completed += 1
                else:
                    print(f"  ⚠️  Optional missing: {field}")
            
            print(f"Optional fields: {optional_completed}/{len(optional_fields)} completed")
            
        else:
            print(f"❌ Cannot check profile - login failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Error checking profile: {e}")

def create_missing_data_for_user(username):
    """Create missing data for the user"""
    print(f"\n🛠️ Creating missing data for {username}")
    print("-" * 30)
    
    # First, let's try to get some events to invite the user to
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}events/", timeout=10)
        if response.status_code == 200:
            events_data = response.json()
            events = events_data.get('events', [])
            
            if events:
                # Try to invite user to first few events
                for i, event in enumerate(events[:3]):
                    invite_data = {
                        "username": username,
                        "event_id": event.get('id'),
                        "inviter": event.get('host')
                    }
                    
                    try:
                        invite_response = requests.post(
                            f"{PRODUCTION_BASE_URL}invite_user_to_event/", 
                            json=invite_data, 
                            timeout=10
                        )
                        if invite_response.status_code == 201:
                            print(f"✅ Sent invitation to {event.get('title')}")
                        else:
                            print(f"❌ Failed to send invitation: {invite_response.status_code}")
                    except Exception as e:
                        print(f"❌ Error sending invitation: {e}")
            else:
                print("❌ No events found to invite user to")
        else:
            print(f"❌ Cannot get events list: {response.status_code}")
    except Exception as e:
        print(f"❌ Error getting events: {e}")

def main():
    """Main investigation function"""
    username = "ana_moreno_999"
    
    print("🔍 PinIt User Data Investigation")
    print("=" * 50)
    
    # Check user profile
    check_user_profile(username)
    
    # Check profile completeness
    check_profile_completeness(username)
    
    # Check user's events
    check_user_events(username)
    
    # Check user's friends
    check_user_friends(username)
    
    # Check user's invitations
    check_user_invitations(username)
    
    # Check user's RSVPs
    check_user_rsvps(username)
    
    # Try to create missing data
    create_missing_data_for_user(username)
    
    print("\n🎯 INVESTIGATION COMPLETE")
    print("=" * 50)
    print("This investigation reveals what data is missing for the user")
    print("and what endpoints need to be implemented to provide complete functionality.")

if __name__ == "__main__":
    main()
