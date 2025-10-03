#!/usr/bin/env python3
"""
Test Specific Endpoints Script
Test the actual working endpoints for profiles, invitations, and matches
"""

import requests
import json
import time

# Production server URL
PRODUCTION_BASE_URL = "https://pinit-backend-production.up.railway.app/api/"

def test_user_profile(username):
    """Test user profile endpoint"""
    print(f"🔍 Testing user profile for: {username}")
    print("-" * 50)
    
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}get_user_profile/{username}/", timeout=10)
        if response.status_code == 200:
            print("✅ User profile endpoint works!")
            profile_data = response.json()
            print(f"Profile data: {json.dumps(profile_data, indent=2)}")
            return True
        else:
            print(f"❌ User profile failed: {response.status_code}")
            print(f"Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ User profile error: {e}")
        return False

def test_friends_list(username):
    """Test friends list endpoint"""
    print(f"\n🤝 Testing friends list for: {username}")
    print("-" * 50)
    
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}get_friends/{username}/", timeout=10)
        if response.status_code == 200:
            print("✅ Friends list endpoint works!")
            friends_data = response.json()
            print(f"Friends data: {json.dumps(friends_data, indent=2)}")
            return True
        else:
            print(f"❌ Friends list failed: {response.status_code}")
            print(f"Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Friends list error: {e}")
        return False

def test_invitations(username):
    """Test invitations endpoint"""
    print(f"\n📨 Testing invitations for: {username}")
    print("-" * 50)
    
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}get_invitations/{username}/", timeout=10)
        if response.status_code == 200:
            print("✅ Invitations endpoint works!")
            invitations_data = response.json()
            print(f"Invitations data: {json.dumps(invitations_data, indent=2)}")
            return True
        else:
            print(f"❌ Invitations failed: {response.status_code}")
            print(f"Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Invitations error: {e}")
        return False

def test_events_list(username):
    """Test events list endpoint"""
    print(f"\n📅 Testing events list for: {username}")
    print("-" * 50)
    
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}get_study_events/{username}/", timeout=10)
        if response.status_code == 200:
            print("✅ Events list endpoint works!")
            events_data = response.json()
            print(f"Events data: {json.dumps(events_data, indent=2)}")
            return True
        else:
            print(f"❌ Events list failed: {response.status_code}")
            print(f"Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Events list error: {e}")
        return False

def test_direct_invitation():
    """Test direct invitation endpoint"""
    print(f"\n📨 Testing direct invitation endpoint")
    print("-" * 50)
    
    # First, get an event ID
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}get_study_events/liam_cruz_879/", timeout=10)
        if response.status_code == 200:
            events_data = response.json()
            if events_data.get('events') and len(events_data['events']) > 0:
                event_id = events_data['events'][0]['id']
                print(f"Found event ID: {event_id}")
                
                # Test direct invitation
                invite_data = {
                    "event_id": event_id,
                    "username": "paula_chavez_469"
                }
                
                invite_response = requests.post(f"{PRODUCTION_BASE_URL}invite_to_event/", json=invite_data, timeout=10)
                if invite_response.status_code == 200:
                    print("✅ Direct invitation endpoint works!")
                    print(f"Response: {invite_response.json()}")
                    return True
                else:
                    print(f"❌ Direct invitation failed: {invite_response.status_code}")
                    print(f"Response: {invite_response.text}")
                    return False
            else:
                print("❌ No events found to test invitation")
                return False
        else:
            print(f"❌ Could not get events: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Direct invitation error: {e}")
        return False

def test_auto_matching():
    """Test auto-matching endpoint"""
    print(f"\n🎯 Testing auto-matching endpoint")
    print("-" * 50)
    
    # First, get an event ID
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}get_study_events/liam_cruz_879/", timeout=10)
        if response.status_code == 200:
            events_data = response.json()
            if events_data.get('events') and len(events_data['events']) > 0:
                event_id = events_data['events'][0]['id']
                print(f"Found event ID: {event_id}")
                
                # Test auto-matching
                match_data = {
                    "event_id": event_id,
                    "max_invites": 5,
                    "min_score": 30.0
                }
                
                match_response = requests.post(f"{PRODUCTION_BASE_URL}advanced_auto_match/", json=match_data, timeout=10)
                if match_response.status_code == 200:
                    print("✅ Auto-matching endpoint works!")
                    print(f"Response: {match_response.json()}")
                    return True
                else:
                    print(f"❌ Auto-matching failed: {match_response.status_code}")
                    print(f"Response: {match_response.text}")
                    return False
            else:
                print("❌ No events found to test auto-matching")
                return False
        else:
            print(f"❌ Could not get events: {match_response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Auto-matching error: {e}")
        return False

def main():
    """Main test function"""
    print("🔍 PinIt Specific Endpoints Test")
    print("=" * 60)
    
    test_username = "liam_cruz_879"
    
    # Test user profile
    profile_works = test_user_profile(test_username)
    
    # Test friends list
    friends_works = test_friends_list(test_username)
    
    # Test invitations
    invitations_works = test_invitations(test_username)
    
    # Test events list
    events_works = test_events_list(test_username)
    
    # Test direct invitation
    direct_invite_works = test_direct_invitation()
    
    # Test auto-matching
    auto_match_works = test_auto_matching()
    
    print(f"\n🎯 TEST RESULTS SUMMARY")
    print("=" * 60)
    print(f"✅ User Profile: {'WORKING' if profile_works else 'FAILED'}")
    print(f"✅ Friends List: {'WORKING' if friends_works else 'FAILED'}")
    print(f"✅ Invitations: {'WORKING' if invitations_works else 'FAILED'}")
    print(f"✅ Events List: {'WORKING' if events_works else 'FAILED'}")
    print(f"✅ Direct Invitations: {'WORKING' if direct_invite_works else 'FAILED'}")
    print(f"✅ Auto-Matching: {'WORKING' if auto_match_works else 'FAILED'}")
    
    working_count = sum([profile_works, friends_works, invitations_works, events_works, direct_invite_works, auto_match_works])
    total_count = 6
    
    print(f"\n📊 Overall: {working_count}/{total_count} endpoints working ({working_count/total_count*100:.1f}%)")
    
    if working_count == total_count:
        print("🎉 All endpoints are working! The issue might be in the frontend implementation.")
    else:
        print("⚠️  Some endpoints are not working. Check the backend implementation.")

if __name__ == "__main__":
    main()
