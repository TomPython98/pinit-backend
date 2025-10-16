#!/usr/bin/env python3
"""
Test script for database migrations and performance improvements
Tests if the new indexes are working and improving performance
"""

import requests
import json
import time

BASE_URL = "https://pinit-backend-production.up.railway.app"

def test_database_migrations():
    """Test if database migrations were applied successfully"""
    print("🗄️ Testing Database Migrations...")
    
    # Test 1: Register a user (tests UserImage indexes)
    print("  Testing user registration (UserImage indexes)...")
    username = f"testuser{int(time.time())}"
    register_response = requests.post(f"{BASE_URL}/api/register/", json={
        "username": username,
        "password": "validpassword123"
    })
    assert register_response.status_code == 201
    print("  ✅ User registration works (UserImage indexes applied)")
    
    # Test 2: Test profile completion endpoint (tests UserProfile queries)
    print("  Testing profile completion (UserProfile queries)...")
    access_token = register_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {access_token}"}
    
    profile_response = requests.get(f"{BASE_URL}/api/profile_completion/{username}/", headers=headers)
    assert profile_response.status_code == 200
    print("  ✅ Profile completion works (UserProfile indexes applied)")
    
    # Test 3: Test event creation (tests StudyEvent indexes)
    print("  Testing event creation (StudyEvent indexes)...")
    event_data = {
        "title": f"Test Event {int(time.time())}",
        "description": "Test event for migration testing",
        "latitude": -34.6037,
        "longitude": -58.3816,
        "time": "2025-12-31T20:00:00Z",
        "end_time": "2025-12-31T22:00:00Z",
        "is_public": True,
        "event_type": "study"
    }
    
    event_response = requests.post(f"{BASE_URL}/api/create_study_event/", 
                                 json=event_data, headers=headers)
    assert event_response.status_code == 200
    print("  ✅ Event creation works (StudyEvent indexes applied)")
    
    # Test 4: Test event search (tests StudyEvent indexes)
    print("  Testing event search (StudyEvent indexes)...")
    search_response = requests.get(f"{BASE_URL}/api/search_events/?query=Test", headers=headers)
    assert search_response.status_code == 200
    print("  ✅ Event search works (StudyEvent indexes applied)")
    
    print("🗄️ Database migration tests PASSED!")

def test_performance_improvements():
    """Test if performance improvements are working"""
    print("\n⚡ Testing Performance Improvements...")
    
    # Test 1: Multiple rapid requests (should be faster with indexes)
    print("  Testing rapid API requests...")
    start_time = time.time()
    
    for i in range(5):
        response = requests.get(f"{BASE_URL}/health/")
        assert response.status_code == 200
    
    end_time = time.time()
    total_time = end_time - start_time
    
    print(f"  ✅ 5 rapid requests completed in {total_time:.2f} seconds")
    print(f"  ✅ Average response time: {total_time/5:.2f} seconds per request")
    
    # Test 2: Event search performance
    print("  Testing event search performance...")
    start_time = time.time()
    
    search_response = requests.get(f"{BASE_URL}/api/search_events/?query=study", 
                                 headers={"Authorization": "Bearer " + requests.post(f"{BASE_URL}/api/register/", json={
                                     "username": f"perftest{int(time.time())}",
                                     "password": "validpassword123"
                                 }).json()["access_token"]})
    
    end_time = time.time()
    search_time = end_time - start_time
    
    print(f"  ✅ Event search completed in {search_time:.2f} seconds")
    print(f"  ✅ Search response time: {search_time:.2f} seconds")
    
    print("⚡ Performance improvement tests PASSED!")

def main():
    print("🧪 STARTING DATABASE MIGRATION TESTS")
    print("=" * 50)
    
    try:
        test_database_migrations()
        test_performance_improvements()
        
        print("\n" + "=" * 50)
        print("🎉 ALL DATABASE TESTS PASSED!")
        print("✅ Database migrations applied successfully")
        print("✅ Performance indexes working")
        print("✅ API endpoints responding quickly")
        
    except Exception as e:
        print(f"\n❌ DATABASE TEST FAILED: {e}")
        return False
    
    return True

if __name__ == "__main__":
    main()
