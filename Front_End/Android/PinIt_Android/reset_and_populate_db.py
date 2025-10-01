import os
import sys
import random
import string
import django
import traceback
from datetime import datetime, timedelta

print("Script starting...")
sys.stdout.flush()

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
print("Setting up Django...")
sys.stdout.flush()
django.setup()
print("Django setup complete!")
sys.stdout.flush()

from django.contrib.auth.models import User
from myapp.models import UserProfile, StudyEvent, EventInvitation, UserInterest

print("Imports complete!")
sys.stdout.flush()

# Reset relevant tables
def reset_database():
    try:
        print("Resetting database...")
        # Delete all events and related data
        event_count = StudyEvent.objects.count()
        invitation_count = EventInvitation.objects.count()
        
        print(f"Before reset: {event_count} events, {invitation_count} invitations")
        
        StudyEvent.objects.all().delete()
        EventInvitation.objects.all().delete()
        
        # Delete all users except for admin/superuser accounts
        user_count = User.objects.filter(is_superuser=False).count()
        print(f"Before reset: {user_count} non-superuser users")
        
        User.objects.filter(is_superuser=False).delete()
        
        print(f"After reset: {StudyEvent.objects.count()} events, {EventInvitation.objects.count()} invitations, {User.objects.filter(is_superuser=False).count()} non-superuser users")
        print("Database reset complete.")
    except Exception as e:
        print(f"Error resetting database: {str(e)}")
        traceback.print_exc()

# Create test users
def create_users(num_users=20):
    try:
        print(f"Creating {num_users} users...")
        users = []
        
        # Define some interests
        interests = [
            "Programming", "Math", "Physics", "Chemistry", "Biology", 
            "History", "Geography", "Literature", "Art", "Music",
            "Data Science", "Machine Learning", "Web Development", 
            "Mobile Development", "Game Development", "Database Design"
        ]
        
        for i in range(num_users):
            username = f"testuser{i+1}"
            email = f"testuser{i+1}@example.com"
            
            # Check if user already exists and delete if needed
            try:
                existing_user = User.objects.get(username=username)
                existing_user.delete()
                print(f"Deleted existing user: {username}")
            except User.DoesNotExist:
                pass
            
            # Create the user
            user = User.objects.create_user(
                username=username,
                email=email,
                password="password123"
            )
            
            # Create or update user profile
            profile, created = UserProfile.objects.get_or_create(user=user)
            profile.auto_invite_enabled = True
            profile.preferred_radius = random.uniform(1.0, 10.0)
            profile.save()
            
            # Assign 2-5 random interests to each user
            user_interests = random.sample(interests, random.randint(2, 5))
            for interest in user_interests:
                UserInterest.objects.create(user=user, interest=interest)
            
            users.append(user)
            print(f"Created user: {username} with interests: {', '.join(user_interests)}")
        
        return users
    except Exception as e:
        print(f"Error creating users: {str(e)}")
        traceback.print_exc()
        return []

# Create events
def create_events(users, num_events=15):
    try:
        print(f"Creating {num_events} events...")
        events = []
        
        # Vienna coordinates (approximately)
        vienna_lat, vienna_lng = 48.2082, 16.3738
        
        event_types = ["study", "party", "business", "other"]
        
        # Define some interests for events
        interests = [
            "Programming", "Math", "Physics", "Chemistry", "Biology", 
            "History", "Geography", "Literature", "Art", "Music",
            "Data Science", "Machine Learning", "Web Development", 
            "Mobile Development", "Game Development", "Database Design"
        ]
        
        for i in range(num_events):
            try:
                # Select random host
                host = random.choice(users)
                
                # Generate random coordinates near Vienna
                lat = vienna_lat + random.uniform(-0.05, 0.05)
                lng = vienna_lng + random.uniform(-0.05, 0.05)
                
                # Create random start time in the next 7 days
                start_time = datetime.now() + timedelta(
                    days=random.randint(0, 7),
                    hours=random.randint(0, 23),
                    minutes=random.randint(0, 59)
                )
                
                # End time is 1-4 hours after start time
                end_time = start_time + timedelta(hours=random.randint(1, 4))
                
                # Random event type
                event_type = random.choice(event_types)
                
                # Random interests for the event
                event_interests = ','.join(random.sample(interests, random.randint(2, 4)))
                
                print(f"Creating event with interests: {event_interests}")
                
                # Create the event with auto-matching enabled
                event = StudyEvent.objects.create(
                    title=f"Test Event {i+1} by {host.username}",
                    description=f"This is a test event created by {host.username}",
                    host=host,
                    latitude=lat,
                    longitude=lng,
                    time=start_time,
                    end_time=end_time,
                    is_public=random.choice([True, False]),
                    event_type=event_type,
                    max_participants=random.randint(5, 20),
                    auto_matching_enabled=True,
                    interest_tags=event_interests
                )
                
                # Invite some random direct friends (non-auto-matched)
                num_direct_invites = random.randint(1, 3)
                direct_invitees = random.sample([u for u in users if u != host], min(num_direct_invites, len(users)-1))
                
                for invitee in direct_invitees:
                    try:
                        event.invite_user(invitee, is_auto_matched=False)
                        print(f"  Invited {invitee.username} directly")
                    except Exception as e:
                        print(f"  Error inviting {invitee.username}: {str(e)}")
                
                events.append(event)
                print(f"Created event: {event.title} (ID: {event.id}) with type: {event_type}")
                print(f"  Host: {host.username}")
                print(f"  Coordinates: {lat}, {lng}")
                print(f"  Time: {start_time} to {end_time}")
                print(f"  Interest tags: {event.interest_tags}")
                print(f"  Direct invites: {[u.username for u in direct_invitees]}")
                
            except Exception as e:
                print(f"Error creating event {i+1}: {str(e)}")
                traceback.print_exc()
                continue
                
        return events
    except Exception as e:
        print(f"Error creating events: {str(e)}")
        traceback.print_exc()
        return []

# Perform auto-matching for events
def run_auto_matching(events):
    try:
        print("Running auto-matching for events...")
        
        # Import the auto-matching function
        from myapp.views import perform_auto_matching
        
        for event in events:
            try:
                print(f"Auto-matching for event: {event.title} (ID: {event.id})")
                
                # Skip if auto-matching is not enabled
                if not event.auto_matching_enabled:
                    print(f"  Auto-matching not enabled for this event. Skipping.")
                    continue
                    
                # Run the auto-matching function
                results, status_code = perform_auto_matching(
                    event_id=event.id,
                    max_invites=5,
                    radius_km=10.0,
                    min_interest_match=1
                )
                
                if status_code == 200:
                    print(f"  Success: {results['message']}")
                    for user in results.get("matched_users", []):
                        print(f"    Matched: {user['username']} (Score: {user['match_score']}, Invited: {user['invited']})")
                        print(f"    Matching interests: {', '.join(user['matching_interests'])}")
                else:
                    print(f"  Error: {results.get('error', 'Unknown error')}")
            except Exception as e:
                print(f"Error auto-matching for event {event.id}: {str(e)}")
                traceback.print_exc()
                continue
        
        # Print summary of auto-matched invitations
        auto_matched_count = EventInvitation.objects.filter(is_auto_matched=True).count()
        print(f"Total auto-matched invitations created: {auto_matched_count}")
    except Exception as e:
        print(f"Error running auto-matching: {str(e)}")
        traceback.print_exc()

# Main function
def main():
    try:
        # Reset the database
        reset_database()
        
        # Create test users
        users = create_users(num_users=20)
        
        # Create events with auto-matching enabled
        events = create_events(users, num_events=15)
        
        # Run auto-matching for all events
        run_auto_matching(events)
        
        print("Database population complete!")
    except Exception as e:
        print(f"Error in main function: {str(e)}")
        traceback.print_exc()

if __name__ == "__main__":
    main() 