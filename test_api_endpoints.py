#!/usr/bin/env python3
"""
Test script to verify API endpoints before running full data generation
"""

import requests
import json
import random
from datetime import datetime, timedelta
import time

BASE_URL = "https://pinit-backend-production.up.railway.app"

def test_api_endpoints():
    """Test basic API functionality"""
    print("Testing API endpoints...")
    
    # Test registration
    test_user = {
        "username": f"test_user_{random.randint(1000, 9999)}",
        "password": "test123456"
    }
    
    print(f"Testing registration for user: {test_user['username']}")
    response = requests.post(f"{BASE_URL}/api/register/", json=test_user)
    
    if response.status_code == 201:
        data = response.json()
        if data.get("success"):
            token = data.get("access_token")
            print(f"✅ Registration successful! Token: {token[:20]}...")
            
            # Test profile update
            profile_data = {
                "username": test_user["username"],
                "full_name": "Test User",
                "university": "Universidad de Buenos Aires (UBA)",
                "degree": "Medicina",
                "year": "3er año",
                "bio": "Estudiante de medicina en Buenos Aires",
                "interests": ["Medicina", "Estudio", "Mate"],
                "skills": ["Spanish", "English", "Leadership"]
            }
            
            headers = {"Authorization": f"Bearer {token}"}
            response = requests.post(f"{BASE_URL}/api/update_user_interests/", json=profile_data, headers=headers)
            
            if response.status_code == 200:
                print("✅ Profile update successful!")
                
                # Test event creation
                event_data = {
                    "title": "Test Event - Medicina",
                    "description": "Evento de prueba para estudiantes de medicina",
                    "latitude": -34.5997,
                    "longitude": -58.3979,
                    "time": (datetime.now() + timedelta(days=1)).isoformat(),
                    "end_time": (datetime.now() + timedelta(days=1, hours=2)).isoformat(),
                    "event_type": "study",
                    "interest_tags": ["Medicina", "Estudio"],
                    "is_public": True,
                    "auto_matching_enabled": True,
                    "max_participants": 10
                }
                
                response = requests.post(f"{BASE_URL}/api/create_study_event/", json=event_data, headers=headers)
                
                if response.status_code == 201:
                    data = response.json()
                    if data.get("success"):
                        event_id = data.get("event_id")
                        print(f"✅ Event creation successful! Event ID: {event_id}")
                        
                        # Test getting events
                        response = requests.get(f"{BASE_URL}/api/get_study_events/{test_user['username']}/", headers=headers)
                        if response.status_code == 200:
                            events = response.json()
                            print(f"✅ Events retrieval successful! Found {len(events)} events")
                            
                            # Test user reputation
                            response = requests.get(f"{BASE_URL}/api/get_user_reputation/{test_user['username']}/", headers=headers)
                            if response.status_code == 200:
                                reputation = response.json()
                                print(f"✅ User reputation successful! Trust level: {reputation.get('trust_level', 'N/A')}")
                                
                                print("\n🎉 All API endpoints working correctly!")
                                return True
                            else:
                                print(f"❌ User reputation failed: {response.status_code}")
                        else:
                            print(f"❌ Events retrieval failed: {response.status_code}")
                    else:
                        print(f"❌ Event creation failed: {data}")
                else:
                    print(f"❌ Event creation failed: {response.status_code} - {response.text}")
            else:
                print(f"❌ Profile update failed: {response.status_code} - {response.text}")
        else:
            print(f"❌ Registration failed: {data}")
    else:
        print(f"❌ Registration failed: {response.status_code} - {response.text}")
    
    return False

if __name__ == "__main__":
    test_api_endpoints()
