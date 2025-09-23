#!/usr/bin/env python3
"""
Test script to verify profile completion integration.
"""

import requests
import json
from datetime import datetime

# Test configuration
BASE_URL = "http://127.0.0.1:8000/api"
TEST_USER = "Tatalia"

def test_profile_completion():
    """Test the complete profile completion flow."""
    
    print("🧪 Testing Profile Completion Integration")
    print("=" * 50)
    
    # Test 1: Get current profile
    print("\n1️⃣ Getting current profile...")
    response = requests.get(f"{BASE_URL}/get_user_profile/{TEST_USER}/")
    
    if response.status_code == 200:
        profile_data = response.json()
        print("✅ Current profile retrieved:")
        print(f"   Full Name: '{profile_data.get('full_name', '')}'")
        print(f"   University: '{profile_data.get('university', '')}'")
        print(f"   Degree: '{profile_data.get('degree', '')}'")
        print(f"   Year: '{profile_data.get('year', '')}'")
        print(f"   Bio: '{profile_data.get('bio', '')}'")
        print(f"   Interests: {profile_data.get('interests', [])}")
        print(f"   Skills: {profile_data.get('skills', {})}")
    else:
        print(f"❌ Failed to get profile: {response.status_code}")
        return False
    
    # Test 2: Update profile with complete information
    print("\n2️⃣ Updating profile with complete information...")
    
    update_data = {
        "username": TEST_USER,
        "full_name": "Tatalia Student",
        "university": "Vienna University of Technology",
        "degree": "Computer Science",
        "year": "3rd Year",
        "bio": "I'm a passionate computer science student interested in AI, mobile development, and creating innovative solutions. I love collaborating with other students and sharing knowledge!",
        "interests": ["Computer Science", "AI", "Mobile Development", "Swift", "Python"],
        "skills": {
            "Swift": "INTERMEDIATE",
            "Python": "ADVANCED",
            "UI Design": "BEGINNER"
        },
        "auto_invite_preference": True,
        "preferred_radius": 15.0
    }
    
    response = requests.post(
        f"{BASE_URL}/update_user_interests/",
        json=update_data,
        headers={"Content-Type": "application/json"}
    )
    
    if response.status_code == 200:
        result = response.json()
        print("✅ Profile updated successfully!")
        print(f"   Message: {result.get('message', '')}")
    else:
        print(f"❌ Failed to update profile: {response.status_code}")
        print(f"   Response: {response.text}")
        return False
    
    # Test 3: Verify the update
    print("\n3️⃣ Verifying the update...")
    response = requests.get(f"{BASE_URL}/get_user_profile/{TEST_USER}/")
    
    if response.status_code == 200:
        updated_profile = response.json()
        print("✅ Updated profile retrieved:")
        print(f"   Full Name: '{updated_profile.get('full_name', '')}'")
        print(f"   University: '{updated_profile.get('university', '')}'")
        print(f"   Degree: '{updated_profile.get('degree', '')}'")
        print(f"   Year: '{updated_profile.get('year', '')}'")
        print(f"   Bio: '{updated_profile.get('bio', '')}'")
        print(f"   Interests: {updated_profile.get('interests', [])}")
        print(f"   Skills: {updated_profile.get('skills', {})}")
        
        # Verify all fields were updated correctly
        if (updated_profile.get('full_name') == update_data['full_name'] and
            updated_profile.get('university') == update_data['university'] and
            updated_profile.get('degree') == update_data['degree'] and
            updated_profile.get('year') == update_data['year'] and
            updated_profile.get('bio') == update_data['bio']):
            print("✅ All profile fields updated correctly!")
            return True
        else:
            print("❌ Some fields were not updated correctly")
            return False
    else:
        print(f"❌ Failed to verify update: {response.status_code}")
        return False

def calculate_profile_completion(profile_data):
    """Calculate profile completion percentage based on frontend logic."""
    completed_items = 0
    total_items = 6  # Base number of profile items
    
    # Check basic profile information
    if profile_data.get('full_name'): completed_items += 1
    if profile_data.get('university'): completed_items += 1
    if profile_data.get('degree'): completed_items += 1
    if profile_data.get('year'): completed_items += 1
    if len(profile_data.get('bio', '')) > 20: completed_items += 1
    
    # Add points for skills (up to 3)
    skills_count = len(profile_data.get('skills', {}))
    skill_points = min(skills_count, 3)
    completed_items += skill_points
    total_items += 3
    
    # Add points for interests (up to 3)
    interests_count = len(profile_data.get('interests', []))
    interest_points = min(interests_count, 3)
    completed_items += interest_points
    total_items += 3
    
    return (completed_items / total_items) * 100

if __name__ == "__main__":
    print("🚀 Starting Profile Completion Integration Test")
    print(f"📡 Testing with user: {TEST_USER}")
    print(f"🌐 API Base URL: {BASE_URL}")
    
    success = test_profile_completion()
    
    if success:
        print("\n🎉 Profile completion integration test PASSED!")
        
        # Calculate completion percentage
        response = requests.get(f"{BASE_URL}/get_user_profile/{TEST_USER}/")
        if response.status_code == 200:
            profile_data = response.json()
            completion_percentage = calculate_profile_completion(profile_data)
            print(f"📊 Profile completion: {completion_percentage:.1f}%")
    else:
        print("\n💥 Profile completion integration test FAILED!")
    
    print("\n" + "=" * 50) 