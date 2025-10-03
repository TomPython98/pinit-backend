#!/usr/bin/env python3
"""
Fix User Profiles with Update Endpoint
Use the update_user_interests endpoint to populate profile data
"""

import requests
import json
import time
import random

# Production server URL
PRODUCTION_BASE_URL = "https://pinit-backend-production.up.railway.app/api/"

# Enhanced data lists
FIRST_NAMES = ['Ana', 'Carlos', 'Maria', 'Diego', 'Sofia', 'Lucas', 'Valentina', 'Mateo', 'Isabella', 'Santiago', 'Camila', 'Sebastian', 'Lucia', 'Nicolas', 'Fernanda', 'Andres', 'Gabriela', 'Alejandro', 'Paula', 'Daniel', 'Emma', 'Liam', 'Olivia', 'Noah', 'Ava', 'William', 'Sophia', 'James', 'Charlotte', 'Benjamin']
LAST_NAMES = ['Garcia', 'Rodriguez', 'Martinez', 'Lopez', 'Gonzalez', 'Perez', 'Sanchez', 'Ramirez', 'Cruz', 'Flores', 'Herrera', 'Jimenez', 'Moreno', 'Alvarez', 'Ruiz', 'Diaz', 'Torres', 'Vargas', 'Ramos', 'Mendoza', 'Silva', 'Castro', 'Rivera', 'Morales', 'Gutierrez', 'Ortiz', 'Chavez', 'Reyes', 'Mendoza', 'Herrera']

UNIVERSITIES = [
    'Universidad de Buenos Aires (UBA)',
    'Universidad Torcuato di Tella',
    'Universidad de San Andrés',
    'Universidad del Salvador',
    'Universidad Católica Argentina',
    'Universidad Nacional de La Plata',
    'Universidad de Belgrano',
    'Universidad de Palermo',
    'Universidad de Buenos Aires - Facultad de Ciencias Exactas',
    'Universidad de Buenos Aires - Facultad de Ingeniería'
]

DEGREES = [
    'Computer Science', 'Business Administration', 'International Relations',
    'Economics', 'Psychology', 'Engineering', 'Medicine', 'Law',
    'Architecture', 'Marketing', 'Finance', 'Spanish Literature',
    'Mathematics', 'Physics', 'Chemistry', 'Biology', 'History',
    'Philosophy', 'Political Science', 'Sociology', 'Anthropology',
    'Data Science', 'Cybersecurity', 'Environmental Science', 'Journalism'
]

YEARS = ['1st Year', '2nd Year', '3rd Year', '4th Year', 'Graduate', 'PhD', 'Masters']

INTERESTS = [
    'Music', 'Sports', 'Art', 'Technology', 'Travel', 'Food', 'Photography',
    'Reading', 'Gaming', 'Fitness', 'Dancing', 'Movies', 'Languages',
    'Volunteering', 'Entrepreneurship', 'Research', 'Writing', 'Design',
    'Environment', 'Politics', 'Culture', 'Fashion', 'Cooking', 'Nature',
    'Programming', 'Data Analysis', 'Machine Learning', 'Sustainability',
    'Social Justice', 'Mental Health', 'Education', 'Innovation'
]

SKILLS = [
    'Leadership', 'Communication', 'Problem Solving', 'Teamwork', 'Creativity',
    'Analytical Thinking', 'Project Management', 'Public Speaking', 'Writing',
    'Research', 'Data Analysis', 'Programming', 'Design', 'Marketing',
    'Negotiation', 'Time Management', 'Critical Thinking', 'Adaptability',
    'Mentoring', 'Strategic Planning', 'Customer Service', 'Sales'
]

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
            if isinstance(users_data, list):
                usernames = [user.get('username') for user in users_data if isinstance(user, dict) and user.get('username')]
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

def create_complete_profile_data(username):
    """Create complete profile data for a user"""
    # Extract name from username (e.g., "liam_cruz_879" -> "Liam Cruz")
    name_parts = username.split('_')
    if len(name_parts) >= 2:
        first_name = name_parts[0].capitalize()
        last_name = name_parts[1].capitalize()
        full_name = f"{first_name} {last_name}"
    else:
        first_name = random.choice(FIRST_NAMES)
        last_name = random.choice(LAST_NAMES)
        full_name = f"{first_name} {last_name}"
    
    university = random.choice(UNIVERSITIES)
    degree = random.choice(DEGREES)
    year = random.choice(YEARS)
    interests = random.sample(INTERESTS, random.randint(4, 8))
    skills_list = random.sample(SKILLS, random.randint(3, 6))
    
    # Convert skills list to dict with skill levels
    skills = {skill: random.choice(['BEGINNER', 'INTERMEDIATE', 'ADVANCED']) for skill in skills_list}
    
    # Generate comprehensive bio
    bio_templates = [
        f"Hi! I'm {first_name}, a {year.lower()} student studying {degree.lower()} at {university}. I'm passionate about {', '.join(interests[:3])} and love connecting with fellow students who share similar interests. I'm always up for study sessions, cultural exchanges, and meaningful conversations!",
        f"Hello! I'm {first_name}, currently pursuing {degree.lower()} at {university}. As a {year.lower()} student, I'm deeply interested in {', '.join(interests[:3])} and enjoy collaborating on projects and study groups. Let's learn and grow together!",
        f"Hey there! I'm {first_name}, a {year.lower()} {degree.lower()} student at {university}. I'm passionate about {', '.join(interests[:3])}. I believe in the power of community and love meeting new people through shared academic interests!"
    ]
    
    profile_data = {
        "username": username,
        "full_name": full_name,
        "university": university,
        "degree": degree,
        "year": year,
        "bio": random.choice(bio_templates),
        "interests": interests,
        "skills": skills,
        "auto_invite_preference": random.choice([True, False]),
        "preferred_radius": random.randint(2, 15)
    }
    
    return profile_data

def update_user_profile(username, profile_data):
    """Update user profile using the update_user_interests endpoint"""
    print(f"🔄 Updating profile for: {username}")
    
    try:
        response = requests.post(f"{PRODUCTION_BASE_URL}update_user_interests/", json=profile_data, timeout=10)
        
        if response.status_code == 200:
            print(f"✅ Profile updated successfully for {username}")
            return True
        else:
            print(f"❌ Profile update failed for {username}: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Profile update error for {username}: {e}")
        return False

def verify_profile_update(username):
    """Verify that profile was updated successfully"""
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}get_user_profile/{username}/", timeout=10)
        if response.status_code == 200:
            profile = response.json()
            has_name = bool(profile.get('full_name'))
            has_university = bool(profile.get('university'))
            has_bio = bool(profile.get('bio'))
            has_interests = len(profile.get('interests', [])) > 0
            
            if has_name and has_university and has_bio and has_interests:
                print(f"✅ Profile verification PASSED for {username}")
                print(f"   Name: {profile.get('full_name')}")
                print(f"   University: {profile.get('university')}")
                print(f"   Interests: {len(profile.get('interests', []))} items")
                return True
            else:
                print(f"❌ Profile verification FAILED for {username}")
                print(f"   Name: {has_name}, University: {has_university}, Bio: {has_bio}, Interests: {has_interests}")
                return False
        else:
            print(f"❌ Could not verify profile for {username}: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Profile verification error for {username}: {e}")
        return False

def main():
    """Main function to fix user profiles"""
    print("🔧 PinIt User Profile Fixer (Using Update Endpoint)")
    print("=" * 70)
    
    # Get existing users
    users = get_existing_users()
    if not users:
        print("❌ No users found.")
        return
    
    print(f"👥 Found {len(users)} users to update")
    
    successful_updates = 0
    failed_updates = 0
    
    for i, username in enumerate(users, 1):
        print(f"\n📝 Processing user {i}/{len(users)}: {username}")
        print("-" * 50)
        
        # Create complete profile data
        profile_data = create_complete_profile_data(username)
        
        # Update user profile
        if update_user_profile(username, profile_data):
            # Verify the update
            if verify_profile_update(username):
                successful_updates += 1
                print(f"🎉 Successfully updated profile for {username}")
            else:
                failed_updates += 1
                print(f"❌ Profile update verification failed for {username}")
        else:
            failed_updates += 1
            print(f"❌ Failed to update profile for {username}")
        
        # Rate limiting
        time.sleep(0.3)
    
    print(f"\n🎯 PROFILE UPDATE SUMMARY")
    print("=" * 70)
    print(f"✅ Successful updates: {successful_updates}")
    print(f"❌ Failed updates: {failed_updates}")
    print(f"📊 Success rate: {successful_updates/(successful_updates+failed_updates)*100:.1f}%")
    
    if successful_updates > 0:
        print(f"\n🎉 Profile data has been populated!")
        print(f"   - Users now have complete profiles")
        print(f"   - Auto-matching should work better")
        print(f"   - Social features are fully functional")
        
        print(f"\n🔑 Test these users (Password: password123):")
        for i, user in enumerate(users[:5], 1):
            print(f"   {i}. {user}")
            
        print(f"\n🚀 Next steps:")
        print(f"   1. Test auto-matching with populated profiles")
        print(f"   2. Test direct invitations")
        print(f"   3. Verify all social features work")
    else:
        print(f"\n❌ No profiles were updated successfully.")
        print(f"   Check the backend implementation of update_user_interests endpoint.")

if __name__ == "__main__":
    main()
