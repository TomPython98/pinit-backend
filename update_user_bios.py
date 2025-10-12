#!/usr/bin/env python3
"""
Update existing users with bio and profile information
"""

import requests
import json
import random

BASE_URL = "https://pinit-backend-production.up.railway.app"

# Test users that were created
TEST_USERS = [
    {"username": "alex_cs_stanford_1760310792", "full_name": "Alex Chen", "university": "Stanford University", "degree": "Computer Science"},
    {"username": "sarah_med_harvard_1760310792", "full_name": "Sarah Johnson", "university": "Harvard Medical School", "degree": "Medicine"},
    {"username": "mike_business_wharton_1760310792", "full_name": "Mike Rodriguez", "university": "Wharton School", "degree": "Business Administration"},
    {"username": "emma_arts_nyu_1760310792", "full_name": "Emma Williams", "university": "NYU Tisch", "degree": "Fine Arts"},
    {"username": "david_eng_mit_1760310792", "full_name": "David Kim", "university": "MIT", "degree": "Mechanical Engineering"},
    {"username": "anna_physics_mit_1760310792", "full_name": "Anna Schmidt", "university": "MIT", "degree": "Physics"},
    {"username": "james_law_yale_1760310792", "full_name": "James Thompson", "university": "Yale Law School", "degree": "Law"},
    {"username": "sophie_psych_stanford_1760310792", "full_name": "Sophie Davis", "university": "Stanford University", "degree": "Psychology"},
    {"username": "carlos_med_johns_hopkins_1760310792", "full_name": "Carlos Martinez", "university": "Johns Hopkins", "degree": "Medicine"},
    {"username": "lisa_eng_caltech_1760310792", "full_name": "Lisa Wang", "university": "Caltech", "degree": "Computer Engineering"}
]

def get_auth_token(username, password):
    """Get JWT token for authentication"""
    url = f"{BASE_URL}/api/token/"
    data = {"username": username, "password": password}
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            return response.json().get("access_token")
        else:
            print(f"❌ Failed to get token for {username}: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Error getting token for {username}: {e}")
        return None

def update_user_profile(username, user_data, token):
    """Update user profile with bio and university info"""
    url = f"{BASE_URL}/api/update_user_interests/"
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    # Generate skills
    skills_list = ["Python", "JavaScript", "Java", "C++", "Machine Learning", "Data Analysis", "Web Development", "Mobile Development", "UI/UX Design", "Project Management", "Leadership", "Communication", "Public Speaking", "Teamwork", "Problem Solving", "Research", "Writing", "Teaching", "Marketing", "Sales"]
    skill_names = random.sample(skills_list, random.randint(2, 4))
    proficiency_levels = ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"]
    user_skills = {}
    for skill in skill_names:
        user_skills[skill] = random.choice(proficiency_levels)
    
    # Generate bio based on user data
    bio_templates = [
        f"Passionate {user_data.get('degree', 'student')} student at {user_data.get('university', 'university')}. Love learning and connecting with like-minded people!",
        f"Studying {user_data.get('degree', 'my field')} at {user_data.get('university', 'my university')}. Always excited to collaborate on projects and study sessions.",
        f"Current {user_data.get('degree', 'student')} at {user_data.get('university', 'university')}. Looking forward to meeting new people and sharing knowledge!",
        f"Enthusiastic learner pursuing {user_data.get('degree', 'my studies')} at {user_data.get('university', 'university')}. Love working in groups and helping others succeed.",
        f"Focused on {user_data.get('degree', 'my academic goals')} at {user_data.get('university', 'university')}. Always up for productive study sessions and meaningful connections."
    ]
    
    bio = random.choice(bio_templates)
    
    # Generate interests based on degree
    interest_map = {
        "Computer Science": ["Computer Science", "AI", "Machine Learning", "Study", "Technology"],
        "Medicine": ["Medicine", "Study", "Academic", "Healthcare", "Research"],
        "Business Administration": ["Business", "Networking", "Social", "Leadership", "Finance"],
        "Fine Arts": ["Arts", "Cultural", "Creative", "Social", "Design"],
        "Mechanical Engineering": ["Engineering", "Study", "Academic", "Technology", "Innovation"],
        "Physics": ["Physics", "Study", "Academic", "Science", "Research"],
        "Law": ["Law", "Study", "Academic", "Professional", "Justice"],
        "Psychology": ["Psychology", "Study", "Academic", "Social", "Research"],
        "Computer Engineering": ["Engineering", "Study", "Academic", "Technology", "Sustainability"]
    }
    
    interests = interest_map.get(user_data.get('degree', ''), ["Study", "Academic", "Social", "Learning"])
    
    data = {
        "username": username,
        "full_name": user_data.get("full_name", ""),
        "university": user_data.get("university", ""),
        "degree": user_data.get("degree", ""),
        "year": random.choice(["1st year", "2nd year", "3rd year", "4th year", "Graduate"]),
        "bio": bio,
        "interests": interests,
        "skills": user_skills,
        "auto_invite_preference": True,
        "preferred_radius": 10.0
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code == 200:
            print(f"✅ Updated profile for {username}")
            print(f"   📝 Bio: {bio[:50]}...")
            print(f"   🎓 University: {user_data.get('university', 'N/A')}")
            print(f"   📚 Degree: {user_data.get('degree', 'N/A')}")
            return True
        else:
            print(f"❌ Failed to update profile for {username}: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error updating profile for {username}: {e}")
        return False

def main():
    print("👤 Updating existing users with bio and profile information...")
    
    updated_count = 0
    
    for user_data in TEST_USERS:
        username = user_data["username"]
        password = "password123"
        
        print(f"\n🔑 Getting token for {username}...")
        token = get_auth_token(username, password)
        if not token:
            continue
        
        print(f"✅ Got token for {username}")
        
        # Update profile
        if update_user_profile(username, user_data, token):
            updated_count += 1
        
        # Small delay between users
        import time
        time.sleep(1)
    
    print(f"\n🎉 Updated {updated_count}/{len(TEST_USERS)} user profiles!")
    print(f"\n📋 All users now have:")
    print(f"   ✅ Bio descriptions")
    print(f"   ✅ University information")
    print(f"   ✅ Degree programs")
    print(f"   ✅ Academic year")
    print(f"   ✅ Skills and interests")
    
    print(f"\n🔑 Test user credentials:")
    for user_data in TEST_USERS:
        print(f"   👤 {user_data['username']} (password: password123)")

if __name__ == "__main__":
    main()
