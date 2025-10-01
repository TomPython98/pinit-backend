#!/usr/bin/env python3
"""
Production Database Setup Script for PinIt App
This script sets up the production database with all necessary tables and initial data.
"""

import os
import sys
import django
from pathlib import Path

# Add the project directory to Python path
project_dir = Path(__file__).resolve().parent / 'StudyCon'
sys.path.append(str(project_dir))

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings_production')
django.setup()

from django.core.management import execute_from_command_line
from django.contrib.auth.models import User
from myapp.models import (
    UserProfile, UserTrustLevel, UserReputationStats, 
    StudyEvent, FriendRequest, Device
)
from django.db import transaction
import json

def setup_database():
    """Main function to set up the production database"""
    print("🚀 Setting up PinIt Production Database...")
    
    try:
        # Step 1: Run migrations
        print("\n📋 Step 1: Running database migrations...")
        execute_from_command_line(['manage.py', 'migrate'])
        print("✅ Migrations completed successfully!")
        
        # Step 2: Create superuser if it doesn't exist
        print("\n👤 Step 2: Setting up admin user...")
        create_admin_user()
        
        # Step 3: Initialize trust levels
        print("\n🏆 Step 3: Setting up trust levels...")
        setup_trust_levels()
        
        # Step 4: Create sample data (optional)
        print("\n📊 Step 4: Creating sample data...")
        create_sample_data()
        
        # Step 5: Verify database setup
        print("\n✅ Step 5: Verifying database setup...")
        verify_database()
        
        print("\n🎉 Production database setup completed successfully!")
        print("🌐 Your database is ready for pin-it.net deployment!")
        
    except Exception as e:
        print(f"❌ Error setting up database: {e}")
        sys.exit(1)

def create_admin_user():
    """Create admin superuser for production"""
    try:
        # Check if admin user already exists
        if User.objects.filter(username='admin').exists():
            print("ℹ️  Admin user already exists")
            return
        
        # Create admin user
        admin_user = User.objects.create_superuser(
            username='admin',
            email='admin@pin-it.net',
            password='PinItAdmin2025!'  # Change this in production!
        )
        
        # Ensure UserProfile is created
        if not hasattr(admin_user, 'userprofile'):
            UserProfile.objects.create(
                user=admin_user,
                full_name='PinIt Administrator',
                is_certified=True,
                bio='System administrator for PinIt app'
            )
        
        print("✅ Admin user created successfully!")
        print("   Username: admin")
        print("   Password: PinItAdmin2025!")
        print("   ⚠️  IMPORTANT: Change the admin password after first login!")
        
    except Exception as e:
        print(f"❌ Error creating admin user: {e}")

def setup_trust_levels():
    """Set up user trust levels"""
    try:
        # Check if trust levels already exist
        if UserTrustLevel.objects.exists():
            print("ℹ️  Trust levels already exist")
            return
        
        trust_levels = [
            {"level": 1, "title": "Newcomer", "required_ratings": 0, "min_average_rating": 0.0},
            {"level": 2, "title": "Participant", "required_ratings": 3, "min_average_rating": 3.0},
            {"level": 3, "title": "Trusted Member", "required_ratings": 10, "min_average_rating": 3.5},
            {"level": 4, "title": "Event Expert", "required_ratings": 20, "min_average_rating": 4.0},
            {"level": 5, "title": "Community Leader", "required_ratings": 50, "min_average_rating": 4.5}
        ]
        
        for level_data in trust_levels:
            UserTrustLevel.objects.create(**level_data)
        
        print("✅ Trust levels created successfully!")
        
    except Exception as e:
        print(f"❌ Error setting up trust levels: {e}")

def create_sample_data():
    """Create some sample data for testing"""
    try:
        # Create a few sample users
        sample_users = [
            {
                'username': 'demo_user1',
                'email': 'demo1@pin-it.net',
                'password': 'DemoPass123!',
                'profile': {
                    'full_name': 'Demo User One',
                    'university': 'Sample University',
                    'degree': 'Computer Science',
                    'year': '3rd Year',
                    'bio': 'Demo user for testing PinIt app',
                    'interests': ['Programming', 'Study Groups', 'Technology'],
                    'skills': {'Python': 'INTERMEDIATE', 'JavaScript': 'BEGINNER'}
                }
            },
            {
                'username': 'demo_user2',
                'email': 'demo2@pin-it.net',
                'password': 'DemoPass123!',
                'profile': {
                    'full_name': 'Demo User Two',
                    'university': 'Sample University',
                    'degree': 'Business Administration',
                    'year': '2nd Year',
                    'bio': 'Another demo user for testing',
                    'interests': ['Business', 'Networking', 'Study Groups'],
                    'skills': {'Marketing': 'ADVANCED', 'Finance': 'INTERMEDIATE'}
                }
            }
        ]
        
        for user_data in sample_users:
            # Check if user already exists
            if User.objects.filter(username=user_data['username']).exists():
                continue
                
            # Create user
            user = User.objects.create_user(
                username=user_data['username'],
                email=user_data['email'],
                password=user_data['password']
            )
            
            # Update profile
            profile = user.userprofile
            profile.full_name = user_data['profile']['full_name']
            profile.university = user_data['profile']['university']
            profile.degree = user_data['profile']['degree']
            profile.year = user_data['profile']['year']
            profile.bio = user_data['profile']['bio']
            profile.interests = user_data['profile']['interests']
            profile.skills = user_data['profile']['skills']
            profile.save()
            
            # Create reputation stats
            UserReputationStats.objects.get_or_create(
                user=user,
                defaults={'trust_level': UserTrustLevel.objects.get(level=1)}
            )
        
        print("✅ Sample users created successfully!")
        print("   Demo users: demo_user1, demo_user2")
        print("   Password: DemoPass123!")
        
    except Exception as e:
        print(f"❌ Error creating sample data: {e}")

def verify_database():
    """Verify that the database is set up correctly"""
    try:
        # Check tables exist and have data
        checks = [
            ("Users", User.objects.count()),
            ("User Profiles", UserProfile.objects.count()),
            ("Trust Levels", UserTrustLevel.objects.count()),
            ("Reputation Stats", UserReputationStats.objects.count()),
            ("Study Events", StudyEvent.objects.count()),
        ]
        
        print("📊 Database Statistics:")
        for name, count in checks:
            print(f"   {name}: {count}")
        
        # Test database connectivity
        from django.db import connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            result = cursor.fetchone()
            if result[0] == 1:
                print("✅ Database connectivity test passed!")
            else:
                print("❌ Database connectivity test failed!")
        
    except Exception as e:
        print(f"❌ Error verifying database: {e}")

def export_database_schema():
    """Export the database schema for documentation"""
    try:
        print("\n📋 Exporting database schema...")
        
        # Get all models
        from django.apps import apps
        models = apps.get_models()
        
        schema_info = {}
        for model in models:
            if model._meta.app_label == 'myapp':
                fields = []
                for field in model._meta.fields:
                    fields.append({
                        'name': field.name,
                        'type': field.__class__.__name__,
                        'null': field.null,
                        'blank': field.blank
                    })
                
                schema_info[model.__name__] = {
                    'fields': fields,
                    'table_name': model._meta.db_table
                }
        
        # Save schema to file
        schema_file = Path(__file__).parent / 'database_schema.json'
        with open(schema_file, 'w') as f:
            json.dump(schema_info, f, indent=2)
        
        print(f"✅ Database schema exported to: {schema_file}")
        
    except Exception as e:
        print(f"❌ Error exporting schema: {e}")

if __name__ == "__main__":
    print("🎯 PinIt Production Database Setup")
    print("=" * 50)
    
    # Check if we're in the right directory
    if not os.path.exists('StudyCon/manage.py'):
        print("❌ Error: Please run this script from the Back_End/StudyCon directory")
        print("   Current directory:", os.getcwd())
        sys.exit(1)
    
    # Change to the Django project directory
    os.chdir('StudyCon')
    
    # Run the setup
    setup_database()
    
    # Export schema
    export_database_schema()
    
    print("\n🚀 Next Steps:")
    print("1. Test your API endpoints")
    print("2. Update your iOS app to use the production URL")
    print("3. Deploy to your hosting provider")
    print("4. Update DNS settings for pin-it.net")
    print("\n🌐 Your PinIt app is ready for production!")
