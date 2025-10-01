#!/usr/bin/env python3
"""
Test script to verify Railway deployment and auto-matching fix
"""

import requests
import json
import time

PRODUCTION_URL = "https://pinit-backend-production.up.railway.app/api"

def test_health():
    """Test if the API is responding"""
    try:
        response = requests.get(f"{PRODUCTION_URL.replace('/api', '')}/health/", timeout=10)
        if response.status_code == 200:
            print("✅ API Health Check: PASSED")
            return True
        else:
            print(f"❌ API Health Check: FAILED ({response.status_code})")
            return False
    except Exception as e:
        print(f"❌ API Health Check: ERROR - {e}")
        return False

def test_auto_matching():
    """Test if auto-matching endpoint works"""
    try:
        # Test with a known event ID
        test_event_id = "7c210d9e-9f52-46b4-b863-02f7b2b4f705"
        
        response = requests.post(
            f"{PRODUCTION_URL}/advanced_auto_match/",
            headers={"Content-Type": "application/json"},
            json={"event_id": test_event_id},
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Auto-Matching Endpoint: WORKING")
            print(f"   Response: {result}")
            return True
        else:
            print(f"❌ Auto-Matching Endpoint: FAILED ({response.status_code})")
            print(f"   Error: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Auto-Matching Endpoint: ERROR - {e}")
        return False

def test_user_events(username):
    """Test if a user has auto-matched events"""
    try:
        response = requests.get(f"{PRODUCTION_URL}/get_study_events/{username}/", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            events = data.get('events', [])
            
            auto_matched_count = sum(1 for event in events if event.get('isAutoMatched', False))
            total_events = len(events)
            
            print(f"✅ User Events Test ({username}):")
            print(f"   Total Events: {total_events}")
            print(f"   Auto-Matched Events: {auto_matched_count}")
            
            return auto_matched_count > 0
        else:
            print(f"❌ User Events Test: FAILED ({response.status_code})")
            return False
            
    except Exception as e:
        print(f"❌ User Events Test: ERROR - {e}")
        return False

def main():
    """Main test function"""
    print("🧪 Testing Railway Deployment")
    print("=" * 40)
    
    # Test 1: Health Check
    if not test_health():
        print("\n❌ Deployment not ready yet. Please wait and try again.")
        return
    
    print("\n" + "=" * 40)
    
    # Test 2: Auto-Matching Endpoint
    auto_matching_works = test_auto_matching()
    
    print("\n" + "=" * 40)
    
    # Test 3: User Events
    test_user_events("marlene_lombard_203")
    
    print("\n" + "=" * 40)
    
    # Summary
    if auto_matching_works:
        print("🎉 DEPLOYMENT SUCCESS!")
        print("✅ Auto-matching fix is working")
        print("✅ Both iOS and Android apps should now show auto-matched events")
    else:
        print("❌ DEPLOYMENT ISSUE")
        print("❌ Auto-matching still broken")
        print("❌ May need to wait longer or check Railway logs")

if __name__ == "__main__":
    main()
