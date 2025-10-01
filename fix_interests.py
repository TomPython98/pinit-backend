#!/usr/bin/env python
import os
import sys
import json
import random

# Set up Django environment
sys.path.append('.')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')

import django
django.setup()

from django.contrib.auth.models import User
from myapp.models import UserProfile, StudyEvent, EventInvitation
from django.db import connection

# Define interest categories
interest_categories = {
    "Academic": [
        "Mathematics", "Computer Science", "Physics", "Chemistry", "Biology", 
        "Medicine", "Psychology", "Sociology", "Economics", "Business", 
        "Law", "Political Science", "History", "Philosophy", "Literature",
        "Languages", "Engineering", "Architecture", "Statistics", "Data Science"
    ],
    "Arts & Culture": [
        "Painting", "Drawing", "Photography", "Film", "Theater", 
        "Music", "Dance", "Sculpture", "Art History", "Design", 
        "Creative Writing", "Poetry", "Fashion", "Architecture", "Classical Music"
    ],
    "Sports & Fitness": [
        "Football", "Basketball", "Volleyball", "Tennis", "Running", 
        "Swimming", "Yoga", "Fitness", "Cycling", "Hiking", 
        "Martial Arts", "Rock Climbing", "Skiing", "Snowboarding", "Gym Workouts"
    ],
    "Leisure & Hobbies": [
        "Gaming", "Board Games", "Reading", "Cooking", "Baking", 
        "Travel", "Hiking", "Photography", "Gardening", "Crafts", 
        "Collecting", "DIY Projects", "Volunteering", "Meditation", "Wine Tasting"
    ],
    "Technology": [
        "Programming", "Web Development", "App Development", "Artificial Intelligence", "Machine Learning", 
        "Data Science", "Robotics", "Cybersecurity", "Blockchain", "AR/VR", 
        "Hardware", "UX/UI Design", "Game Development", "Open Source", "Cloud Computing"
    ]
}

# Flatten into a single list of interests
all_interests = []
for category, interests in interest_categories.items():
    all_interests.extend(interests)

def debug_profile_fields():
    """Debug a user profile to check field types"""
    try:
        # Get first user
        user = User.objects.filter(is_superuser=False, is_staff=False).first()
        if not user:
            print("No regular users found")
            return
            
        profile = UserProfile.objects.get(user=user)
        
        print("UserProfile Field Debug:")
        print(f"Profile ID: {profile.id}")
        print(f"Profile User: {profile.user.username}")
        print(f"Profile Interests Type: {type(profile.interests)}")
        print(f"Profile Interests Value: {profile.interests}")
        print(f"Profile Skills Type: {type(profile.skills)}")
        print(f"Profile Skills Value: {profile.skills}")
        
        # Direct database check
        with connection.cursor() as cursor:
            cursor.execute("SELECT id, interests, skills FROM myapp_userprofile WHERE id = %s", [profile.id])
            row = cursor.fetchone()
            print("\nRaw Database Values:")
            print(f"ID: {row[0]}")
            print(f"Interests: {row[1]}")
            print(f"Skills: {row[2]}")
    except Exception as e:
        print(f"Error debugging profile: {str(e)}")

def fix_user_interests():
    """Fix user interests by directly setting the JSON field"""
    
    print("Fixing user interests...")
    users = User.objects.filter(is_superuser=False, is_staff=False)
    
    for user in users:
        try:
            profile = UserProfile.objects.get(user=user)
            
            # Generate new interests for the user (3-8 interests)
            num_interests = random.randint(3, 8)
            user_interests = random.sample(all_interests, num_interests)
            
            # Set the interests directly
            profile.interests = user_interests  # Django will handle JSON serialization
            profile.save()
            
            # Verify the interests were saved
            profile.refresh_from_db()
            saved_interests = profile.interests
            print(f"Fixed interests for {user.username}: {saved_interests}")
        except Exception as e:
            print(f"Error fixing interests for {user.username}: {str(e)}")
    
    print("Interest fixing completed!")

def fix_event_interests():
    """Fix event interest tags"""
    
    print("\nFixing event interest tags...")
    events = StudyEvent.objects.all()
    
    for event in events:
        try:
            # Generate new interest tags (1-5 tags)
            num_tags = random.randint(1, 5)
            event_tags = random.sample(all_interests, num_tags)
            
            # Set the interest tags directly
            event.interest_tags = event_tags  # Django will handle JSON serialization
            event.save()
            
            # Verify the tags were saved
            event.refresh_from_db()
            saved_tags = event.interest_tags
            print(f"Fixed interest tags for event {event.title}: {saved_tags}")
        except Exception as e:
            print(f"Error fixing interest tags for event {event.id}: {str(e)}")
    
    print("Event interest tags fixing completed!")

def perform_auto_matching():
    """Perform auto-matching between users and events"""
    
    print("\nPerforming auto-matching...")
    
    # Clear existing auto-matched invitations
    EventInvitation.objects.filter(is_auto_matched=True).delete()
    print("Cleared existing auto-matched invitations")
    
    events = StudyEvent.objects.filter(auto_matching_enabled=True)
    users = User.objects.filter(is_superuser=False, is_staff=False)
    
    matched_count = 0
    
    for event in events:
        event_interests = event.interest_tags
        if not event_interests:
            continue
            
        print(f"Looking for matches for event: {event.title}")
        print(f"Event interests: {event_interests}")
        
        event_host = event.host
        matched_users_for_event = 0
        
        for user in users:
            # Skip if user is the host or already attending
            if user == event_host or user in event.attendees.all():
                continue
                
            # Get user's profile and interests
            profile = UserProfile.objects.get(user=user)
            user_interests = profile.interests
            
            if not user_interests:
                continue
                
            # Calculate interest overlap
            matching_interests = set(user_interests).intersection(set(event_interests))
            
            if matching_interests:
                try:
                    # Add to invited friends
                    event.invited_friends.add(user)
                    
                    # Create invitation record
                    EventInvitation.objects.create(
                        event=event,
                        user=user,
                        is_auto_matched=True
                    )
                    
                    matched_count += 1
                    matched_users_for_event += 1
                    print(f"  ✓ Auto-matched user {user.username} to event '{event.title}' based on interests: {matching_interests}")
                except Exception as e:
                    print(f"  ✗ Failed to auto-match user {user.username} to event '{event.title}': {str(e)}")
        
        print(f"Total matches for event '{event.title}': {matched_users_for_event}")
    
    print(f"\nCompleted auto-matching with {matched_count} matches")

if __name__ == "__main__":
    debug_profile_fields()
    fix_user_interests()
    fix_event_interests()
    perform_auto_matching() 