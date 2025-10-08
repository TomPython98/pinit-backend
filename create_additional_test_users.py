#!/usr/bin/env python3
"""
Create additional test users for PinIt app
"""

import requests
import json

# Backend URL
BASE_URL = "https://pinit-backend-production.up.railway.app/api"

# Additional test user data
ADDITIONAL_USERS = [
    {
        "username": "anna_physics",
        "password": "testpass123",
        "full_name": "Anna Schmidt",
        "university": "MIT",
        "degree": "Physics",
        "year": "Graduate",
        "bio": "PhD student in quantum physics. Love discussing complex theories over coffee!",
        "interests": ["Physics", "Study", "Academic", "Science"]
    },
    {
        "username": "james_law",
        "password": "testpass123",
        "full_name": "James Wilson",
        "university": "Yale Law School",
        "degree": "Law",
        "year": "Senior",
        "bio": "Law student preparing for the bar exam. Study groups are essential!",
        "interests": ["Law", "Study", "Academic", "Professional"]
    },
    {
        "username": "sophie_psychology",
        "password": "testpass123",
        "full_name": "Sophie Martinez",
        "university": "Stanford University",
        "degree": "Psychology",
        "year": "Junior",
        "bio": "Psychology major interested in cognitive science. Always up for study sessions!",
        "interests": ["Psychology", "Study", "Academic", "Social"]
    },
    {
        "username": "carlos_medicine",
        "password": "testpass123",
        "full_name": "Carlos Rodriguez",
        "university": "Johns Hopkins Medical School",
        "degree": "Medicine",
        "year": "Graduate",
        "bio": "Medical student specializing in cardiology. Study groups help with complex material!",
        "interests": ["Medicine", "Study", "Academic", "Healthcare"]
    },
    {
        "username": "lisa_engineering",
        "password": "testpass123",
        "full_name": "Lisa Chen",
        "university": "Caltech",
        "degree": "Electrical Engineering",
        "year": "Senior",
        "bio": "Engineering student working on robotics. Collaborative problem solving is key!",
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
    print("🚀 Creating additional test users...")
    
    # Register all users
    registered_users = []
    for user_data in ADDITIONAL_USERS:
        if register_user(user_data):
            registered_users.append(user_data)
    
    print(f"\n📊 Successfully registered {len(registered_users)} additional users")
    
    print("\n✅ Additional test users created!")
    print("\nNew test accounts:")
    for user in registered_users:
        print(f"  👤 {user['username']} ({user['full_name']})")
        print(f"     University: {user['university']}")
        print(f"     Degree: {user['degree']} - {user['year']}")
        print(f"     Bio: {user['bio']}")
        print(f"     Interests: {', '.join(user['interests'])}")
        print(f"     Password: testpass123")
        print()
    
    print("🎯 You now have more test accounts to work with!")
    print("   - Test profile viewing with different user types")
    print("   - Test friend requests between users")
    print("   - Test image loading with various profiles")

if __name__ == "__main__":
    main()
