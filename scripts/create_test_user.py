#!/usr/bin/env python3
"""
Create a proper test user for authentication
"""

import os
import sys
import django

# Add the Django project directory to the Python path
sys.path.append('/Users/tombesinger/Desktop/PinItApp/Back_End/StudyCon/StudyCon')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from django.contrib.auth.models import User
from django.contrib.auth.hashers import make_password
from myapp.models import UserProfile, UserReputationStats

def create_test_user():
    """Create a test user with proper authentication"""
    
    # Create or get the test user
    username = "testuser"
    password = "testpass123"
    email = "testuser@example.com"
    
    # Delete existing test user if it exists
    User.objects.filter(username=username).delete()
    
    # Create new user
    user = User.objects.create(
        username=username,
        email=email,
        password=make_password(password),
        first_name="Test",
        last_name="User"
    )
    
    # Create user profile
    profile = user.userprofile
    profile.bio = "Test user for Android app testing"
    profile.university = "Universidad de Buenos Aires (UBA)"
    profile.degree = "Bachelor"
    profile.year = "2nd Year"
    profile.full_name = "Test User"
    profile.is_certified = True
    profile.interests = ["Spanish Language", "Cultural Exchange", "Photography", "Travel"]
    profile.skills = {
        "Spanish Language": "INTERMEDIATE",
        "Cultural Exchange": "ADVANCED",
        "Photography": "BEGINNER"
    }
    profile.auto_invite_enabled = True
    profile.preferred_radius = 15.0
    profile.save()
    
    # Create reputation stats
    UserReputationStats.objects.create(
        user=user,
        total_ratings=5,
        average_rating=4.2,
        events_hosted=2,
        events_attended=8
    )
    
    print(f"✅ Created test user:")
    print(f"   Username: {username}")
    print(f"   Password: {password}")
    print(f"   Email: {email}")
    print(f"   User ID: {user.id}")
    
    return user

if __name__ == "__main__":
    create_test_user()
