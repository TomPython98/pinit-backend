#!/usr/bin/env python3
"""
Data Migration Script for PinIt App
This script helps migrate your existing local data to the production database.
"""

import os
import sys
import django
import json
from pathlib import Path
from datetime import datetime

# Add the project directory to Python path
project_dir = Path(__file__).resolve().parent / 'StudyCon'
sys.path.append(str(project_dir))

def setup_django(use_production=False):
    """Set up Django environment"""
    if use_production:
        os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings_production')
    else:
        os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
    
    django.setup()

def export_local_data():
    """Export data from local SQLite database"""
    print("📤 Exporting data from local database...")
    
    # Set up local Django environment
    setup_django(use_production=False)
    
    from django.contrib.auth.models import User
    from myapp.models import UserProfile, StudyEvent, FriendRequest, UserRating
    
    try:
        # Export users and profiles
        users_data = []
        for user in User.objects.all():
            user_data = {
                'username': user.username,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'date_joined': user.date_joined.isoformat(),
                'is_active': user.is_active,
            }
            
            # Add profile data if exists
            if hasattr(user, 'userprofile'):
                profile = user.userprofile
                user_data['profile'] = {
                    'full_name': profile.full_name,
                    'university': profile.university,
                    'degree': profile.degree,
                    'year': profile.year,
                    'bio': profile.bio,
                    'interests': profile.get_interests(),
                    'skills': profile.get_skills(),
                    'is_certified': profile.is_certified,
                    'auto_invite_enabled': profile.auto_invite_enabled,
                    'preferred_radius': profile.preferred_radius,
                }
            
            users_data.append(user_data)
        
        # Export events
        events_data = []
        for event in StudyEvent.objects.all():
            event_data = {
                'id': str(event.id),
                'title': event.title,
                'description': event.description,
                'host_username': event.host.username,
                'latitude': event.latitude,
                'longitude': event.longitude,
                'time': event.time.isoformat(),
                'end_time': event.end_time.isoformat(),
                'is_public': event.is_public,
                'event_type': event.event_type,
                'max_participants': event.max_participants,
                'auto_matching_enabled': event.auto_matching_enabled,
                'interest_tags': event.get_interest_tags(),
                'invited_friends': [u.username for u in event.invited_friends.all()],
                'attendees': [u.username for u in event.attendees.all()],
            }
            events_data.append(event_data)
        
        # Export friend requests
        friend_requests_data = []
        for fr in FriendRequest.objects.all():
            friend_requests_data.append({
                'from_user': fr.from_user.username,
                'to_user': fr.to_user.username,
                'timestamp': fr.timestamp.isoformat(),
            })
        
        # Export ratings
        ratings_data = []
        for rating in UserRating.objects.all():
            ratings_data.append({
                'from_user': rating.from_user.username,
                'to_user': rating.to_user.username,
                'rating': rating.rating,
                'reference': rating.reference,
                'event_id': str(rating.event.id) if rating.event else None,
                'created_at': rating.created_at.isoformat(),
            })
        
        # Save all data to JSON file
        export_data = {
            'export_date': datetime.now().isoformat(),
            'users': users_data,
            'events': events_data,
            'friend_requests': friend_requests_data,
            'ratings': ratings_data,
        }
        
        export_file = Path(__file__).parent / 'local_data_export.json'
        with open(export_file, 'w') as f:
            json.dump(export_data, f, indent=2)
        
        print(f"✅ Data exported successfully to: {export_file}")
        print(f"   Users: {len(users_data)}")
        print(f"   Events: {len(events_data)}")
        print(f"   Friend Requests: {len(friend_requests_data)}")
        print(f"   Ratings: {len(ratings_data)}")
        
        return export_file
        
    except Exception as e:
        print(f"❌ Error exporting data: {e}")
        return None

def import_to_production(export_file):
    """Import data to production database"""
    print("📥 Importing data to production database...")
    
    # Set up production Django environment
    setup_django(use_production=True)
    
    from django.contrib.auth.models import User
    from myapp.models import UserProfile, StudyEvent, FriendRequest, UserRating, UserTrustLevel
    from django.db import transaction
    
    try:
        # Load exported data
        with open(export_file, 'r') as f:
            data = json.load(f)
        
        with transaction.atomic():
            # Import users
            print("👤 Importing users...")
            user_mapping = {}  # Map old usernames to new User objects
            
            for user_data in data['users']:
                # Skip if user already exists
                if User.objects.filter(username=user_data['username']).exists():
                    user = User.objects.get(username=user_data['username'])
                    user_mapping[user_data['username']] = user
                    continue
                
                # Create user
                user = User.objects.create_user(
                    username=user_data['username'],
                    email=user_data['email'],
                    first_name=user_data['first_name'],
                    last_name=user_data['last_name'],
                    password='TempPassword123!'  # Users will need to reset
                )
                user.is_active = user_data['is_active']
                user.save()
                
                user_mapping[user_data['username']] = user
                
                # Update profile if exists
                if 'profile' in user_data:
                    profile_data = user_data['profile']
                    profile = user.userprofile
                    profile.full_name = profile_data.get('full_name', '')
                    profile.university = profile_data.get('university', '')
                    profile.degree = profile_data.get('degree', '')
                    profile.year = profile_data.get('year', '')
                    profile.bio = profile_data.get('bio', '')
                    profile.interests = profile_data.get('interests', [])
                    profile.skills = profile_data.get('skills', {})
                    profile.is_certified = profile_data.get('is_certified', False)
                    profile.auto_invite_enabled = profile_data.get('auto_invite_enabled', True)
                    profile.preferred_radius = profile_data.get('preferred_radius', 10.0)
                    profile.save()
            
            print(f"✅ Imported {len(user_mapping)} users")
            
            # Import events
            print("📅 Importing events...")
            event_mapping = {}
            
            for event_data in data['events']:
                # Skip if event already exists
                if StudyEvent.objects.filter(id=event_data['id']).exists():
                    continue
                
                # Get host user
                host = user_mapping.get(event_data['host_username'])
                if not host:
                    print(f"⚠️  Skipping event {event_data['title']} - host not found")
                    continue
                
                # Create event
                event = StudyEvent.objects.create(
                    id=event_data['id'],
                    title=event_data['title'],
                    description=event_data['description'],
                    host=host,
                    latitude=event_data['latitude'],
                    longitude=event_data['longitude'],
                    time=datetime.fromisoformat(event_data['time']),
                    end_time=datetime.fromisoformat(event_data['end_time']),
                    is_public=event_data['is_public'],
                    event_type=event_data['event_type'],
                    max_participants=event_data['max_participants'],
                    auto_matching_enabled=event_data['auto_matching_enabled'],
                    interest_tags=event_data['interest_tags'],
                )
                
                # Add invited friends
                for username in event_data['invited_friends']:
                    if username in user_mapping:
                        event.invited_friends.add(user_mapping[username])
                
                # Add attendees
                for username in event_data['attendees']:
                    if username in user_mapping:
                        event.attendees.add(user_mapping[username])
                
                event_mapping[event_data['id']] = event
            
            print(f"✅ Imported {len(event_mapping)} events")
            
            # Import friend requests
            print("👥 Importing friend requests...")
            for fr_data in data['friend_requests']:
                from_user = user_mapping.get(fr_data['from_user'])
                to_user = user_mapping.get(fr_data['to_user'])
                
                if from_user and to_user:
                    FriendRequest.objects.get_or_create(
                        from_user=from_user,
                        to_user=to_user,
                        defaults={'timestamp': datetime.fromisoformat(fr_data['timestamp'])}
                    )
            
            print(f"✅ Imported {len(data['friend_requests'])} friend requests")
            
            # Import ratings
            print("⭐ Importing ratings...")
            for rating_data in data['ratings']:
                from_user = user_mapping.get(rating_data['from_user'])
                to_user = user_mapping.get(rating_data['to_user'])
                event = event_mapping.get(rating_data['event_id']) if rating_data['event_id'] else None
                
                if from_user and to_user:
                    UserRating.objects.get_or_create(
                        from_user=from_user,
                        to_user=to_user,
                        event=event,
                        defaults={
                            'rating': rating_data['rating'],
                            'reference': rating_data['reference'],
                            'created_at': datetime.fromisoformat(rating_data['created_at'])
                        }
                    )
            
            print(f"✅ Imported {len(data['ratings'])} ratings")
        
        print("🎉 Data import completed successfully!")
        print("⚠️  Note: All imported users have temporary password 'TempPassword123!'")
        print("   Users should reset their passwords on first login.")
        
    except Exception as e:
        print(f"❌ Error importing data: {e}")

def main():
    """Main function"""
    print("🔄 PinIt Data Migration Tool")
    print("=" * 40)
    
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python migrate_to_production.py export    # Export local data")
        print("  python migrate_to_production.py import    # Import to production")
        print("  python migrate_to_production.py full      # Export then import")
        sys.exit(1)
    
    command = sys.argv[1].lower()
    
    # Change to the Django project directory
    if os.path.exists('StudyCon'):
        os.chdir('StudyCon')
    
    if command == 'export':
        export_file = export_local_data()
        if export_file:
            print(f"\n📁 Export completed: {export_file}")
            print("   Next: Run 'python migrate_to_production.py import' on your production server")
    
    elif command == 'import':
        export_file = Path(__file__).parent / 'local_data_export.json'
        if not export_file.exists():
            print(f"❌ Export file not found: {export_file}")
            print("   Run 'python migrate_to_production.py export' first")
            sys.exit(1)
        
        import_to_production(export_file)
    
    elif command == 'full':
        export_file = export_local_data()
        if export_file:
            print("\n" + "="*40)
            import_to_production(export_file)
    
    else:
        print(f"❌ Unknown command: {command}")
        sys.exit(1)

if __name__ == "__main__":
    main()




