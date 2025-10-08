#!/usr/bin/env python3
"""
Simple test data generation for PinIt app
Just creates basic test users
"""

import requests
import json

# Backend URL
BASE_URL = "https://pinit-backend-production.up.railway.app/api"

# Test user data
TEST_USERS = [
    {
        "username": "alex_student",
        "password": "testpass123",
        "full_name": "Alex Johnson",
        "university": "Stanford University",
        "degree": "Computer Science",
        "year": "Junior",
        "bio": "CS student passionate about AI and machine learning. Love studying with others!",
        "interests": ["Computer Science", "AI", "Study", "Technology"]
    },
    {
        "username": "sarah_med",
        "password": "testpass123",
        "full_name": "Sarah Chen",
        "university": "Harvard Medical School",
        "degree": "Medicine",
        "year": "Senior",
        "bio": "Pre-med student focused on cardiology. Looking for study partners for MCAT prep!",
        "interests": ["Medicine", "Study", "Academic", "Healthcare"]
    },
    {
        "username": "mike_business",
        "password": "testpass123",
        "full_name": "Mike Rodriguez",
        "university": "Wharton School",
        "degree": "Business Administration",
        "year": "Graduate",
        "bio": "MBA student specializing in entrepreneurship. Always up for networking!",
        "interests": ["Business", "Networking", "Social", "Leadership"]
    },
    {
        "username": "emma_arts",
        "password": "testpass123",
        "full_name": "Emma Wilson",
        "university": "NYU Tisch",
        "degree": "Fine Arts",
        "year": "Sophomore",
        "bio": "Art student exploring digital media and traditional painting. Creative study sessions welcome!",
        "interests": ["Arts", "Cultural", "Creative", "Social"]
    },
    {
        "username": "david_engineering",
        "password": "testpass123",
        "full_name": "David Kim",
        "university": "MIT",
        "degree": "Mechanical Engineering",
        "year": "Junior",
        "bio": "Engineering student working on robotics projects. Love collaborative problem solving!",
        "interests": ["Engineering", "Study", "Academic", "Technology"]
    }
]

def register_user(user_data):
    """Register a new user"""
    url = f"{BASE_URL}/register/"
    data = {
        "username": user_data["username"],
        "password": user_data["password"]
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 201:
            print(f"✅ Registered user: {user_data['username']}")
            return True
        else:
            print(f"❌ Failed to register {user_data['username']}: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error registering {user_data['username']}: {e}")
        return False

def main():
    print("🚀 Creating test users...")
    
    # Register all users
    registered_users = []
    for user_data in TEST_USERS:
        if register_user(user_data):
            registered_users.append(user_data)
    
    print(f"\n📊 Successfully registered {len(registered_users)} users")
    
    print("\n✅ Test users created!")
    print("\nTest accounts:")
    for user in registered_users:
        print(f"  👤 {user['username']} ({user['full_name']})")
        print(f"     University: {user['university']}")
        print(f"     Degree: {user['degree']} - {user['year']}")
        print(f"     Bio: {user['bio']}")
        print(f"     Interests: {', '.join(user['interests'])}")
        print(f"     Password: testpass123")
        print()
    
    print("🎯 You can now test the app with these accounts!")
    print("   - Login with any username and password 'testpass123'")
    print("   - Test profile viewing, friend requests, and events")
    print("   - All users have different backgrounds for variety")

if __name__ == "__main__":
    main()
