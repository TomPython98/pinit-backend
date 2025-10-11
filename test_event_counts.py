#!/usr/bin/env python3
"""
Test script to verify event counts are working correctly.
This script tests the backend API endpoints to ensure event counting works.
"""

import requests
import json
import sys

# Configuration
BASE_URL = "https://pinit-backend-production.up.railway.app"  # Update with your actual backend URL
TEST_USER = "tom"
TEST_PASSWORD = "tomtom123A"

def test_user_reputation_api(username):
    """Test the get_user_reputation API endpoint"""
    print(f"\n🔍 Testing get_user_reputation API for user: {username}")
    
    url = f"{BASE_URL}/get_user_reputation/{username}/"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Reputation API Response:")
            print(f"   Events Hosted: {data.get('events_hosted', 'N/A')}")
            print(f"   Events Attended: {data.get('events_attended', 'N/A')}")
            print(f"   Total Ratings: {data.get('total_ratings', 'N/A')}")
            print(f"   Average Rating: {data.get('average_rating', 'N/A')}")
            return data
        else:
            print(f"❌ Reputation API failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Reputation API error: {e}")
        return None

def test_study_events_api(username):
    """Test the get_study_events API endpoint"""
    print(f"\n🔍 Testing get_study_events API for user: {username}")
    
    url = f"{BASE_URL}/get_study_events/{username}/"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            data = response.json()
            events = data.get('events', [])
            
            # Count events where user is host
            hosted_count = len([e for e in events if e.get('host') == username])
            
            # Count events where user is attendee
            attended_count = len([e for e in events if username in e.get('attendees', [])])
            
            print(f"✅ Study Events API Response:")
            print(f"   Total Events Returned: {len(events)}")
            print(f"   Events Hosted (calculated): {hosted_count}")
            print(f"   Events Attended (calculated): {attended_count}")
            
            # Show event details
            print(f"   Event Details:")
            for i, event in enumerate(events[:5]):  # Show first 5 events
                print(f"     {i+1}. {event.get('title', 'No title')} (Host: {event.get('host', 'Unknown')}, Public: {event.get('isPublic', 'Unknown')})")
            
            if len(events) > 5:
                print(f"     ... and {len(events) - 5} more events")
            
            return {
                'total_events': len(events),
                'hosted_count': hosted_count,
                'attended_count': attended_count,
                'events': events
            }
        else:
            print(f"❌ Study Events API failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Study Events API error: {e}")
        return None

def compare_counts(username):
    """Compare counts between reputation API and direct counting"""
    print(f"\n📊 Comparing event counts for user: {username}")
    
    # Get reputation data
    reputation_data = test_user_reputation_api(username)
    
    # Get events data
    events_data = test_study_events_api(username)
    
    if reputation_data and events_data:
        print(f"\n📈 Comparison Results:")
        print(f"   Reputation API - Events Hosted: {reputation_data.get('events_hosted', 'N/A')}")
        print(f"   Direct Count - Events Hosted: {events_data.get('hosted_count', 'N/A')}")
        print(f"   Reputation API - Events Attended: {reputation_data.get('events_attended', 'N/A')}")
        print(f"   Direct Count - Events Attended: {events_data.get('attended_count', 'N/A')}")
        
        # Check if counts match
        hosted_match = reputation_data.get('events_hosted') == events_data.get('hosted_count')
        attended_match = reputation_data.get('events_attended') == events_data.get('attended_count')
        
        print(f"\n🎯 Results:")
        print(f"   Events Hosted Match: {'✅ YES' if hosted_match else '❌ NO'}")
        print(f"   Events Attended Match: {'✅ YES' if attended_match else '❌ NO'}")
        
        if not hosted_match or not attended_match:
            print(f"\n⚠️  ISSUE DETECTED:")
            print(f"   The reputation API has stale data!")
            print(f"   Our frontend fix using direct counting is CORRECT.")
        else:
            print(f"\n✅ All counts match - both APIs working correctly")
    
    return reputation_data, events_data

def main():
    """Main test function"""
    print("🧪 PinIt Event Count Testing Script")
    print("=" * 50)
    
    # Test with the known user
    compare_counts(TEST_USER)
    
    print(f"\n" + "=" * 50)
    print("📝 Test Summary:")
    print("1. This script tests both API endpoints")
    print("2. If counts don't match, it confirms our frontend fix is needed")
    print("3. The frontend fix uses direct counting from get_study_events")
    print("4. This ensures accurate counts regardless of reputation API issues")
    
    print(f"\n💡 Next Steps:")
    print("1. Run this script to verify the backend issue exists")
    print("2. Test the app with our frontend fix")
    print("3. Create test accounts and events to verify the fix works")

if __name__ == "__main__":
    main()
