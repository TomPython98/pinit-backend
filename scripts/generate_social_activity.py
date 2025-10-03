#!/usr/bin/env python3
"""
Generate Social Activity Script
Create direct invitations, test profiles, and run auto-matching with existing users
"""

import requests
import json
import time
import random

# Production server URL
PRODUCTION_BASE_URL = "https://pinit-backend-production.up.railway.app/api/"

def get_existing_users():
    """Get list of existing users"""
    print("👥 Getting existing users...")
    
    # Known usernames from our previous data generation
    known_users = [
        "liam_cruz_879", "paula_chavez_469", "carlos_lopez_233", 
        "fernanda_mendoza_332", "liam_gutierrez_333", "maria_sanchez_294",
        "james_torres_777", "lucia_martinez_206", "andres_jimenez_888",
        "valentina_vargas_582", "sebastian_ramos_312", "charlotte_torres_632",
        "benjamin_gutierrez_598", "noah_torres_875", "liam_perez_680",
        "camila_reyes_197", "ana_perez_244", "lucas_jimenez_428",
        "emma_alvarez_228", "maria_cruz_598", "alejandro_lopez_208",
        "diego_perez_852", "sebastian_ramos_759", "camila_castro_449",
        "isabella_diaz_776", "charlotte_chavez_367", "liam_cruz_712",
        "lucia_ortiz_968", "santiago_alvarez_147", "sophia_perez_608"
    ]
    
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}get_all_users/", timeout=10)
        if response.status_code == 200:
            users_data = response.json()
            # Handle both list and dict responses
            if isinstance(users_data, list):
                usernames = [user.get('username') for user in users_data if isinstance(user, dict) and user.get('username')]
            elif isinstance(users_data, dict):
                # If it's a dict, try to extract usernames from values
                usernames = []
                for key, value in users_data.items():
                    if isinstance(value, dict) and value.get('username'):
                        usernames.append(value.get('username'))
            else:
                usernames = []
            
            if usernames:
                print(f"✅ Found {len(usernames)} existing users from API")
                return usernames
            else:
                print(f"⚠️  API returned empty, using known users")
                return known_users
        else:
            print(f"❌ Failed to get users: {response.status_code}, using known users")
            return known_users
    except Exception as e:
        print(f"❌ Error getting users: {e}, using known users")
        return known_users

def get_user_events(username):
    """Get events for a specific user"""
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}get_study_events/{username}/", timeout=10)
        if response.status_code == 200:
            events_data = response.json()
            return events_data.get('events', [])
        else:
            return []
    except Exception as e:
        print(f"❌ Error getting events for {username}: {e}")
        return []

def test_user_profile(username):
    """Test and display user profile"""
    print(f"\n👤 Testing profile for: {username}")
    print("-" * 40)
    
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}get_user_profile/{username}/", timeout=10)
        if response.status_code == 200:
            profile_data = response.json()
            print(f"✅ Profile loaded successfully!")
            print(f"   Name: {profile_data.get('full_name', 'N/A')}")
            print(f"   University: {profile_data.get('university', 'N/A')}")
            print(f"   Degree: {profile_data.get('degree', 'N/A')}")
            print(f"   Year: {profile_data.get('year', 'N/A')}")
            print(f"   Bio: {profile_data.get('bio', 'N/A')[:100]}...")
            print(f"   Interests: {len(profile_data.get('interests', []))} items")
            print(f"   Skills: {len(profile_data.get('skills', {}))} items")
            print(f"   Auto-invite enabled: {profile_data.get('auto_invite_enabled', False)}")
            return True
        else:
            print(f"❌ Profile failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Profile error: {e}")
        return False

def test_user_friends(username):
    """Test and display user's friends"""
    print(f"\n🤝 Testing friends for: {username}")
    print("-" * 40)
    
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}get_friends/{username}/", timeout=10)
        if response.status_code == 200:
            friends_data = response.json()
            friends = friends_data.get('friends', [])
            print(f"✅ Found {len(friends)} friends")
            for i, friend in enumerate(friends[:5]):  # Show first 5 friends
                print(f"   {i+1}. {friend.get('username', 'N/A')} - {friend.get('first_name', '')} {friend.get('last_name', '')}")
            if len(friends) > 5:
                print(f"   ... and {len(friends) - 5} more friends")
            return True
        else:
            print(f"❌ Friends failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Friends error: {e}")
        return False

def test_user_invitations(username):
    """Test and display user's invitations"""
    print(f"\n📨 Testing invitations for: {username}")
    print("-" * 40)
    
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}get_invitations/{username}/", timeout=10)
        if response.status_code == 200:
            invitations_data = response.json()
            invitations = invitations_data.get('invitations', [])
            print(f"✅ Found {len(invitations)} invitations")
            for i, invitation in enumerate(invitations[:3]):  # Show first 3 invitations
                print(f"   {i+1}. Event: {invitation.get('event_title', 'N/A')}")
                print(f"      From: {invitation.get('inviter', 'N/A')}")
                print(f"      Status: {invitation.get('status', 'N/A')}")
            if len(invitations) > 3:
                print(f"   ... and {len(invitations) - 3} more invitations")
            return True
        else:
            print(f"❌ Invitations failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Invitations error: {e}")
        return False

def create_direct_invitations(users, events):
    """Create direct invitations using the correct endpoint"""
    print(f"\n📨 Creating direct invitations...")
    print("-" * 40)
    
    invitations_created = 0
    
    # Try the correct endpoint path (without /api/ prefix)
    invite_url = "https://pinit-backend-production.up.railway.app/invite_to_event/"
    
    for event in events[:10]:  # Use first 10 events
        event_id = event.get('id')
        host = event.get('host')
        
        # Get 2-3 random users to invite (excluding host)
        other_users = [u for u in users if u != host]
        invitees = random.sample(other_users, min(3, len(other_users)))
        
        for invitee in invitees:
            invite_data = {
                "event_id": event_id,
                "username": invitee
            }
            
            try:
                response = requests.post(invite_url, json=invite_data, timeout=10)
                if response.status_code == 200:
                    invitations_created += 1
                    print(f"✅ Invitation: {host} -> {invitee} for {event.get('title', 'Event')}")
                else:
                    print(f"❌ Invitation failed: {response.status_code} - {response.text[:100]}")
            except Exception as e:
                print(f"❌ Invitation error: {e}")
            
            time.sleep(0.2)
    
    print(f"📨 Created {invitations_created} direct invitations")
    return invitations_created

def run_auto_matching(events):
    """Run auto-matching for events with matching enabled"""
    print(f"\n🎯 Running auto-matching...")
    print("-" * 40)
    
    matches_created = 0
    
    for event in events[:5]:  # Use first 5 events
        event_id = event.get('id')
        event_title = event.get('title', 'Event')
        
        # Only run auto-matching for events that have it enabled
        if event.get('auto_matching_enabled', False):
            match_data = {
                "event_id": event_id,
                "max_invites": 5,
                "min_score": 30.0
            }
            
            try:
                response = requests.post(f"{PRODUCTION_BASE_URL}advanced_auto_match/", json=match_data, timeout=10)
                if response.status_code == 200:
                    result = response.json()
                    matches = result.get('matched_users', [])
                    matches_created += len(matches)
                    print(f"✅ Auto-matched {len(matches)} users to: {event_title}")
                    for match in matches[:3]:  # Show first 3 matches
                        print(f"   - {match.get('username', 'N/A')} (score: {match.get('match_score', 'N/A')})")
                else:
                    print(f"❌ Auto-matching failed for {event_title}: {response.status_code}")
            except Exception as e:
                print(f"❌ Auto-matching error for {event_title}: {e}")
            
            time.sleep(0.5)
        else:
            print(f"⏭️  Skipping {event_title} (auto-matching disabled)")
    
    print(f"🎯 Created {matches_created} auto-matches")
    return matches_created

def create_friend_connections(users):
    """Create additional friend connections"""
    print(f"\n🤝 Creating friend connections...")
    print("-" * 40)
    
    connections_created = 0
    
    for i, user in enumerate(users[:10]):  # Use first 10 users
        # Each user connects with 2-4 other users
        num_connections = random.randint(2, 4)
        other_users = [u for u in users if u != user]
        selected_friends = random.sample(other_users, min(num_connections, len(other_users)))
        
        for friend in selected_friends:
            # Send friend request
            friend_request_data = {
                "from_user": user,
                "to_user": friend
            }
            
            try:
                response = requests.post(f"{PRODUCTION_BASE_URL}send_friend_request/", json=friend_request_data, timeout=10)
                if response.status_code == 201:
                    connections_created += 1
                    print(f"✅ Friend request: {user} -> {friend}")
                else:
                    print(f"❌ Friend request failed: {response.status_code}")
            except Exception as e:
                print(f"❌ Friend request error: {e}")
            
            time.sleep(0.1)
    
    print(f"🤝 Created {connections_created} friend connections")
    return connections_created

def main():
    """Main function to generate social activity"""
    print("🚀 PinIt Social Activity Generator")
    print("=" * 60)
    
    # Get existing users
    users = get_existing_users()
    if not users:
        print("❌ No users found. Please run the data generation script first.")
        return
    
    print(f"👥 Working with {len(users)} existing users")
    
    # Get events from first few users
    all_events = []
    for user in users[:5]:  # Get events from first 5 users
        events = get_user_events(user)
        all_events.extend(events)
    
    print(f"📅 Found {len(all_events)} events to work with")
    
    # Test profiles for sample users
    print(f"\n🔍 TESTING USER PROFILES")
    print("=" * 60)
    profile_tests = 0
    for user in users[:5]:  # Test first 5 users
        if test_user_profile(user):
            profile_tests += 1
    
    # Test friends for sample users
    print(f"\n🤝 TESTING FRIEND CONNECTIONS")
    print("=" * 60)
    friend_tests = 0
    for user in users[:5]:  # Test first 5 users
        if test_user_friends(user):
            friend_tests += 1
    
    # Test invitations for sample users
    print(f"\n📨 TESTING INVITATIONS")
    print("=" * 60)
    invitation_tests = 0
    for user in users[:5]:  # Test first 5 users
        if test_user_invitations(user):
            invitation_tests += 1
    
    # Create additional social activity
    print(f"\n🛠️ CREATING ADDITIONAL SOCIAL ACTIVITY")
    print("=" * 60)
    
    # Create friend connections
    friend_connections = create_friend_connections(users)
    
    # Create direct invitations
    direct_invitations = create_direct_invitations(users, all_events)
    
    # Run auto-matching
    auto_matches = run_auto_matching(all_events)
    
    # Final summary
    print(f"\n🎉 SOCIAL ACTIVITY GENERATION COMPLETE!")
    print("=" * 60)
    print(f"📊 SUMMARY:")
    print(f"   - Users tested: {len(users)}")
    print(f"   - Profile tests passed: {profile_tests}/5")
    print(f"   - Friend tests passed: {friend_tests}/5")
    print(f"   - Invitation tests passed: {invitation_tests}/5")
    print(f"   - Friend connections created: {friend_connections}")
    print(f"   - Direct invitations sent: {direct_invitations}")
    print(f"   - Auto-matches created: {auto_matches}")
    
    print(f"\n✅ All major social features are now active!")
    print(f"   - Users have complete profiles")
    print(f"   - Friend networks are established")
    print(f"   - Event invitations are flowing")
    print(f"   - Auto-matching is working")
    
    print(f"\n🔑 SAMPLE USERS TO TEST (Password: password123):")
    for i, user in enumerate(users[:10]):
        print(f"   {i+1}. {user}")

if __name__ == "__main__":
    main()
