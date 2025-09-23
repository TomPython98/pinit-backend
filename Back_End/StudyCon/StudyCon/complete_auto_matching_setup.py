#!/usr/bin/env python3
"""
Complete Auto-Matching Setup Script
===================================

This script creates a fully functional StudyCon environment with:
- Users with auto-matching enabled by default
- Events with auto-matching enabled
- Comprehensive auto-matched invitations for all users
- Realistic user profiles with interests and skills
- Active community simulation

Usage: python complete_auto_matching_setup.py [num_users] [num_events]
"""

import os
import sys
import django
import random
import json
from datetime import datetime, timedelta
from django.db import transaction
from django.contrib.auth.models import User
from django.utils import timezone

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from myapp.models import UserProfile, StudyEvent, EventInvitation

# Configuration
DEFAULT_NUM_USERS = 200
DEFAULT_NUM_EVENTS = 150
DEFAULT_PASSWORD = "pass123"

# Realistic data pools
FIRST_NAMES = [
    "Emma", "Liam", "Sophia", "Noah", "Isabella", "Oliver", "Ava", "William",
    "Mia", "James", "Charlotte", "Benjamin", "Amelia", "Lucas", "Harper",
    "Henry", "Evelyn", "Alexander", "Abigail", "Mason", "Emily", "Michael",
    "Elizabeth", "Ethan", "Sofia", "Daniel", "Avery", "Jacob", "Ella",
    "Logan", "Madison", "Jackson", "Scarlett", "Levi", "Victoria", "Sebastian",
    "Aria", "Mateo", "Grace", "Jack", "Chloe", "Owen", "Camila", "Theodore",
    "Penelope", "Aiden", "Riley", "Samuel", "Layla", "Joseph", "Lillian"
]

LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller",
    "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez",
    "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin",
    "Lee", "Perez", "Thompson", "White", "Harris", "Sanchez", "Clark",
    "Ramirez", "Lewis", "Robinson", "Walker", "Young", "Allen", "King",
    "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores", "Green",
    "Adams", "Nelson", "Baker", "Hall", "Rivera", "Campbell", "Mitchell"
]

UNIVERSITIES = [
    "University of Vienna", "Vienna University of Technology", "Medical University of Vienna",
    "University of Graz", "University of Innsbruck", "Johannes Kepler University",
    "University of Salzburg", "University of Klagenfurt", "University of Linz",
    "Vienna University of Economics", "University of Applied Sciences Vienna",
    "FH Campus Vienna", "FH Technikum Wien", "FH Joanneum", "FH St. Pölten"
]

INTERESTS = [
    "Mathematics", "Physics", "Chemistry", "Biology", "Computer Science",
    "Engineering", "Medicine", "Psychology", "Economics", "Business",
    "Languages", "History", "Philosophy", "Art", "Music", "Sports",
    "Technology", "Research", "Writing", "Reading", "Travel", "Cooking",
    "Photography", "Gaming", "Fitness", "Yoga", "Dancing", "Theater",
    "Volunteering", "Environmental Science", "Data Science", "AI/ML"
]

SKILLS = [
    "Python", "Java", "JavaScript", "C++", "R", "MATLAB", "SQL", "HTML/CSS",
    "Machine Learning", "Data Analysis", "Statistics", "Research Methods",
    "Public Speaking", "Writing", "Project Management", "Team Leadership",
    "Problem Solving", "Critical Thinking", "Communication", "Time Management",
    "Presentation Skills", "Academic Writing", "Lab Work", "Field Research",
    "Software Development", "Web Development", "Mobile Development", "Database Design"
]

EVENT_TYPES = [
    "Study Group", "Exam Preparation", "Project Collaboration", "Research Discussion",
    "Language Exchange", "Workshop", "Seminar", "Tutorial", "Lab Session",
    "Group Discussion", "Peer Review", "Case Study", "Presentation Practice",
    "Code Review", "Literature Review", "Data Analysis", "Thesis Support"
]

EVENT_TITLES = [
    "Advanced Calculus Study Group", "Machine Learning Workshop", "Database Design Tutorial",
    "Organic Chemistry Lab Prep", "Statistics Exam Review", "Python Programming Session",
    "Research Methodology Discussion", "Academic Writing Workshop", "Presentation Skills Training",
    "Data Visualization Techniques", "Algorithm Design Study", "Literature Review Session",
    "Thesis Writing Support", "Peer Learning Circle", "Exam Strategy Discussion",
    "Project Planning Meeting", "Code Debugging Session", "Research Paper Analysis",
    "Study Technique Workshop", "Academic Career Planning"
]

def clear_existing_data():
    """Clear all existing data to start fresh"""
    print("🧹 Clearing existing data...")
    
    with transaction.atomic():
        EventInvitation.objects.all().delete()
        StudyEvent.objects.all().delete()
        UserProfile.objects.all().delete()
        User.objects.exclude(is_superuser=True).delete()
    
    print("✅ Existing data cleared")

def create_users(num_users):
    """Create users with auto-matching enabled by default"""
    print(f"👥 Creating {num_users} users...")
    
    users_created = []
    
    with transaction.atomic():
        for i in range(num_users):
            # Generate realistic name
            first_name = random.choice(FIRST_NAMES)
            last_name = random.choice(LAST_NAMES)
            username = f"{first_name.lower()}_{last_name.lower()}_{i+1}"
            email = f"{username}@example.com"
            
            # Create user
            user = User.objects.create_user(
                username=username,
                email=email,
                password=DEFAULT_PASSWORD,
                first_name=first_name,
                last_name=last_name
            )
            
            # Create profile with auto-matching enabled
            profile = UserProfile.objects.create(
                user=user,
                is_certified=random.choice([True, False]),
                full_name=f"{first_name} {last_name}",
                university=random.choice(UNIVERSITIES),
                interests=json.dumps(random.sample(INTERESTS, random.randint(3, 8))),
                skills=json.dumps(random.sample(SKILLS, random.randint(4, 10))),
                auto_invite_enabled=True,  # Always enabled
                preferred_radius=random.randint(5, 50)
            )
            
            users_created.append({
                'username': username,
                'password': DEFAULT_PASSWORD,
                'email': email,
                'full_name': f"{first_name} {last_name}"
            })
    
    print(f"✅ Created {len(users_created)} users")
    return users_created

def create_events(num_events):
    """Create events with auto-matching enabled by default"""
    print(f"📅 Creating {num_events} events...")
    
    events_created = []
    users = list(User.objects.all())
    
    with transaction.atomic():
        for i in range(num_events):
            # Generate event details
            title = random.choice(EVENT_TITLES)
            event_type = random.choice(EVENT_TYPES)
            host = random.choice(users)
            
            # Random date within next 30 days
            start_date = timezone.now() + timedelta(days=random.randint(1, 30))
            end_date = start_date + timedelta(hours=random.randint(1, 4))
            
            # Create event with auto-matching enabled
            event = StudyEvent.objects.create(
                title=title,
                description=f"Join us for an engaging {event_type.lower()} session focused on {title.lower()}.",
                event_type=event_type,
                host=host,
                start_date=start_date,
                end_date=end_date,
                location=f"Room {random.randint(100, 999)}",
                max_participants=random.randint(5, 25),
                auto_matching_enabled=True,  # Always enabled
                is_active=True
            )
            
            events_created.append({
                'id': event.id,
                'title': title,
                'event_type': event_type,
                'host': host.username
            })
    
    print(f"✅ Created {len(events_created)} events")
    return events_created

def create_auto_matched_invitations():
    """Create comprehensive auto-matched invitations for all users"""
    print("🎯 Creating auto-matched invitations...")
    
    users = list(User.objects.all())
    events = list(StudyEvent.objects.filter(auto_matching_enabled=True))
    
    invitations_created = 0
    
    with transaction.atomic():
        for user in users:
            # Each user gets 5-15 auto-matched invitations
            num_invitations = random.randint(5, 15)
            selected_events = random.sample(events, min(num_invitations, len(events)))
            
            for event in selected_events:
                # Skip if user is the host
                if event.host == user:
                    continue
                
                # Check if invitation already exists
                if not EventInvitation.objects.filter(user=user, event=event).exists():
                    EventInvitation.objects.create(
                        user=user,
                        event=event,
                        is_auto_matched=True
                    )
                    invitations_created += 1
    
    print(f"✅ Created {invitations_created} auto-matched invitations")

def create_direct_invitations():
    """Create some direct invitations between users"""
    print("📨 Creating direct invitations...")
    
    users = list(User.objects.all())
    events = list(StudyEvent.objects.all())
    
    direct_invitations = 0
    
    with transaction.atomic():
        for _ in range(len(users) * 2):  # 2 direct invitations per user on average
            user = random.choice(users)
            event = random.choice(events)
            
            # Skip if user is the host or already invited
            if event.host == user or EventInvitation.objects.filter(user=user, event=event).exists():
                continue
            
            EventInvitation.objects.create(
                user=user,
                event=event,
                is_auto_matched=False
            )
            direct_invitations += 1
    
    print(f"✅ Created {direct_invitations} direct invitations")

def save_credentials(users):
    """Save user credentials to file"""
    print("💾 Saving user credentials...")
    
    with open('user_credentials.txt', 'w') as f:
        f.write("Username,Password,Email,Full Name\n")
        for user in users:
            f.write(f"{user['username']},{user['password']},{user['email']},{user['full_name']}\n")
    
    print("✅ Credentials saved to user_credentials.txt")

def print_summary():
    """Print a summary of the created data"""
    print("\n" + "="*60)
    print("🎉 SETUP COMPLETE! 🎉")
    print("="*60)
    
    total_users = User.objects.count()
    total_events = StudyEvent.objects.count()
    total_invitations = EventInvitation.objects.count()
    auto_matched_invitations = EventInvitation.objects.filter(is_auto_matched=True).count()
    
    print(f"👥 Total Users: {total_users}")
    print(f"📅 Total Events: {total_events}")
    print(f"📨 Total Invitations: {total_invitations}")
    print(f"🎯 Auto-Matched Invitations: {auto_matched_invitations}")
    print(f"📊 Direct Invitations: {total_invitations - auto_matched_invitations}")
    
    print("\n🔑 Login Credentials:")
    print("   Username: emma_johnson")
    print("   Password: pass123")
    print("   (All users have the same password: pass123)")
    
    print("\n🌐 API Endpoints:")
    print("   - Get user profile: GET /api/get_user_profile/{username}/")
    print("   - Get invitations: GET /api/get_invitations/{username}/")
    print("   - Search events: GET /api/enhanced_search_events/?username={username}&auto_matched=true")
    print("   - Login: POST /api/login/")
    
    print("\n✨ Features Enabled:")
    print("   - Auto-matching enabled for ALL users")
    print("   - Auto-matching enabled for ALL events")
    print("   - Comprehensive invitation system")
    print("   - Realistic user profiles with interests and skills")
    print("   - Active community simulation")
    
    print("="*60)

def main():
    """Main function"""
    print("🚀 Starting Complete Auto-Matching Setup...")
    
    # Get parameters
    num_users = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_NUM_USERS
    num_events = int(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_NUM_EVENTS
    
    print(f"📊 Configuration: {num_users} users, {num_events} events")
    
    try:
        # Clear existing data
        clear_existing_data()
        
        # Create users
        users = create_users(num_users)
        
        # Create events
        events = create_events(num_events)
        
        # Create invitations
        create_auto_matched_invitations()
        create_direct_invitations()
        
        # Save credentials
        save_credentials(users)
        
        # Print summary
        print_summary()
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

