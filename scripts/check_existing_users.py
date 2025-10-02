#!/usr/bin/env python3

import requests
import json

PRODUCTION_BASE_URL = "https://pinit-backend-production.up.railway.app/api/"

def check_existing_users():
    """Check what users exist in the database"""
    print("🔍 Checking existing users...")
    
    # Get all users
    url = f"{PRODUCTION_BASE_URL}get_all_users/"
    
    try:
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        
        users = data if isinstance(data, list) else []
        print(f"📊 Total users: {len(users)}")
        
        # Show first 10 users
        print(f"\n👥 First 10 users:")
        for i, user in enumerate(users[:10]):
            print(f"  {i+1}. {user}")
        
        # Check if ana_cruz exists
        if 'ana_cruz' in users:
            print(f"\n✅ ana_cruz exists!")
        else:
            print(f"\n❌ ana_cruz does not exist")
            # Find similar usernames
            similar_users = [user for user in users if 'ana' in user.lower() or 'cruz' in user.lower()]
            if similar_users:
                print(f"🔍 Similar usernames: {similar_users}")
        
        # Pick a random user to test with
        if users:
            test_user = users[0]
            print(f"\n🧪 Testing with user: {test_user}")
            test_user_events(test_user)
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Error: {e}")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

def test_user_events(username):
    """Test events for a specific user"""
    print(f"\n🔍 Testing events for {username}...")
    
    url = f"{PRODUCTION_BASE_URL}get_study_events/{username}/"
    
    try:
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        
        events = data.get('events', [])
        print(f"📊 Total events returned: {len(events)}")
        
        # Categorize events
        hosting_events = []
        attending_events = []
        invited_events = []
        auto_matched_events = []
        
        for event in events:
            title = event.get('title', 'Unknown')
            host = event.get('host', 'Unknown')
            attendees = event.get('attendees', [])
            invited_friends = event.get('invitedFriends', [])
            is_auto_matched = event.get('isAutoMatched', False)
            
            # Check categories
            is_hosting = host == username
            is_attending = username in attendees
            is_invited = username in invited_friends
            
            if is_hosting:
                hosting_events.append(title)
            if is_attending:
                attending_events.append(title)
            if is_invited:
                invited_events.append(title)
            if is_auto_matched:
                auto_matched_events.append(title)
        
        print(f"\n📋 Event Categories for {username}:")
        print(f"🏠 Hosting: {len(hosting_events)} events")
        print(f"👤 Attending: {len(attending_events)} events")
        print(f"📩 Invited: {len(invited_events)} events")
        print(f"🎯 Auto-Matched: {len(auto_matched_events)} events")
        
        # Calculate "My Events" (hosting + attending)
        my_events = len(hosting_events) + len(attending_events)
        print(f"\n✅ 'My Events' should be: {my_events} (hosting: {len(hosting_events)} + attending: {len(attending_events)})")
        
        # Show some sample events with full details
        print(f"\n🔍 Sample Event Details:")
        for i, event in enumerate(events[:3]):  # Show first 3 events
            print(f"\nEvent {i+1}: {event.get('title', 'Unknown')}")
            print(f"  Host: {event.get('host', 'Unknown')}")
            print(f"  Attendees: {event.get('attendees', [])}")
            print(f"  Invited: {event.get('invitedFriends', [])}")
            print(f"  Auto-Matched: {event.get('isAutoMatched', False)}")
            print(f"  Event Type: {event.get('event_type', 'Unknown')}")
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Error getting events for {username}: {e}")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

if __name__ == "__main__":
    check_existing_users()

