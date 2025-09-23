import os
import django
import random
from datetime import datetime, timedelta

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from django.contrib.auth.models import User
from myapp.models import StudyEvent, EventInvitation, UserInterest, UserProfile

# Interest categories for better matching
INTERESTS = {
    'academic': ['Programming', 'Math', 'Physics', 'Chemistry', 'Biology', 
                'History', 'Geography', 'Literature', 'Computer Science',
                'Data Science', 'Machine Learning', 'Algorithms'],
    'arts': ['Art', 'Music', 'Photography', 'Design', 'Drawing', 'Poetry',
             'Theater', 'Dance', 'Film', 'Creative Writing'],
    'tech': ['Web Development', 'Mobile Development', 'Game Development', 
            'Database Design', 'AI', 'Blockchain', 'Cloud Computing', 
            'Cybersecurity', 'DevOps', 'UI/UX'],
    'languages': ['German', 'English', 'French', 'Spanish', 'Italian', 
                 'Russian', 'Chinese', 'Japanese', 'Korean'],
    'business': ['Marketing', 'Finance', 'Entrepreneurship', 'Management',
                'Economics', 'Accounting', 'Business Strategy', 'Sales']
}

# Vienna districts with coordinates
VIENNA_DISTRICTS = [
    {"name": "Innere Stadt", "lat": 48.2082, "lng": 16.3738},
    {"name": "Leopoldstadt", "lat": 48.2167, "lng": 16.3833},
    {"name": "Landstraße", "lat": 48.2000, "lng": 16.3917},
    {"name": "Wieden", "lat": 48.1917, "lng": 16.3722},
    {"name": "Margareten", "lat": 48.1861, "lng": 16.3583},
    {"name": "Mariahilf", "lat": 48.1972, "lng": 16.3500},
    {"name": "Neubau", "lat": 48.2028, "lng": 16.3444},
    {"name": "Josefstadt", "lat": 48.2111, "lng": 16.3500},
    {"name": "Alsergrund", "lat": 48.2250, "lng": 16.3583},
    {"name": "Favoriten", "lat": 48.1667, "lng": 16.3833},
    {"name": "Floridsdorf", "lat": 48.2583, "lng": 16.4000},
    {"name": "Donaustadt", "lat": 48.2417, "lng": 16.5083},
]

def assign_interests_to_users():
    """Assign varied interests to users"""
    print("Assigning interests to users...")
    
    # Get all users
    users = User.objects.all()
    
    # Clear existing interests
    UserInterest.objects.all().delete()
    
    for user in users:
        # Make sure user has a profile
        user_profile, created = UserProfile.objects.get_or_create(user=user)
        
        # Enable auto-matching for all users
        user_profile.auto_invite_enabled = True
        user_profile.preferred_radius = random.uniform(1.0, 10.0)
        user_profile.save()
        
        # Choose 2-3 interest categories for this user
        categories = random.sample(list(INTERESTS.keys()), random.randint(2, 3))
        user_interests = []
        
        # From each category, choose 1-3 interests
        for category in categories:
            interests_in_category = random.sample(INTERESTS[category], 
                                                min(random.randint(1, 3), len(INTERESTS[category])))
            user_interests.extend(interests_in_category)
        
        # Create UserInterest objects
        for interest in user_interests:
            UserInterest.objects.create(user_profile=user_profile, interest=interest)
        
        # Also store interests directly in the user profile
        user_profile.interests = ','.join(user_interests)
        user_profile.save()
        
        print(f"Assigned {len(user_interests)} interests to {user.username}: {', '.join(user_interests)}")
    
    return users

def create_events_with_interests():
    """Create events with specific interest tags in Vienna"""
    print("Creating events with interest tags...")
    
    # Delete existing events and invitations
    StudyEvent.objects.all().delete()
    EventInvitation.objects.all().delete()
    
    users = list(User.objects.all())
    events = []
    
    # Create 30 events across Vienna
    for i in range(30):
        # Select random host
        host = random.choice(users)
        
        # Select random district
        district = random.choice(VIENNA_DISTRICTS)
        
        # Add some randomness to location within district
        lat = district["lat"] + random.uniform(-0.01, 0.01)
        lng = district["lng"] + random.uniform(-0.01, 0.01)
        
        # Random event type
        event_type = random.choice(["study", "party", "business", "other"])
        
        # Select interest categories based on event type
        if event_type == "study":
            categories = ["academic", "languages"]
        elif event_type == "party":
            categories = ["arts", "languages"]
        elif event_type == "business":
            categories = ["business", "tech"]
        else:
            categories = random.sample(list(INTERESTS.keys()), 1)
        
        # Select 2-4 interests from these categories
        event_interests = []
        for category in categories:
            interests_count = min(random.randint(1, 3), len(INTERESTS[category]))
            event_interests.extend(random.sample(INTERESTS[category], interests_count))
        
        # Create random start time in the next 7 days
        start_time = datetime.now() + timedelta(
            days=random.randint(0, 7),
            hours=random.randint(0, 23),
            minutes=random.randint(0, 59)
        )
        
        # End time is 1-4 hours after start time
        end_time = start_time + timedelta(hours=random.randint(1, 4))
        
        # Create the event
        event = StudyEvent.objects.create(
            title=f"{event_type.capitalize()} session in {district['name']} - {', '.join(event_interests[:2])}",
            description=f"Join us for a {event_type} session focusing on {', '.join(event_interests)}",
            host=host,
            latitude=lat,
            longitude=lng,
            time=start_time,
            end_time=end_time,
            is_public=random.choice([True, False]),
            event_type=event_type,
            max_participants=random.randint(5, 20),
            auto_matching_enabled=True,
            interest_tags=','.join(event_interests)
        )
        
        events.append(event)
        print(f"Created event: {event.title}")
        print(f"  Location: {district['name']} ({lat}, {lng})")
        print(f"  Type: {event_type}")
        print(f"  Interests: {', '.join(event_interests)}")
    
    return events

def create_potential_matches(events, match_threshold=1):
    """Create potential matches between users and events based on interest overlap"""
    print("Creating potential matches...")
    
    # Delete existing invitations
    EventInvitation.objects.filter(is_auto_matched=True).delete()
    
    match_count = 0
    users = User.objects.all()
    
    for event in events:
        # Get event interests
        event_interests = event.interest_tags.split(',')
        print(f"Processing event: {event.title}")
        print(f"  Interests: {', '.join(event_interests)}")
        
        # Find users with matching interests
        for user in users:
            # Skip if user is the host
            if user == event.host:
                continue
            
            try:
                # Get user profile and interests
                user_profile = UserProfile.objects.get(user=user)
                
                # Skip users with auto-matching disabled
                if not user_profile.auto_invite_enabled:
                    continue
                
                # Get user interests (from both places)
                profile_interests = user_profile.interests.split(',') if user_profile.interests else []
                interest_objects = [ui.interest for ui in UserInterest.objects.filter(user_profile=user_profile)]
                
                user_interests = list(set(profile_interests + interest_objects))
                
                # Find matching interests
                matching_interests = set(user_interests).intersection(set(event_interests))
                
                # Create invitation if there are enough matching interests
                if len(matching_interests) >= match_threshold:
                    EventInvitation.objects.create(
                        event=event,
                        user=user,
                        is_auto_matched=True
                    )
                    match_count += 1
                    print(f"  Created match with {user.username}")
                    print(f"    User interests: {', '.join(user_interests)}")
                    print(f"    Matching interests: {', '.join(matching_interests)}")
            except UserProfile.DoesNotExist:
                # Skip users without profiles
                continue
    
    print(f"Created {match_count} potential matches")
    return match_count

def main():
    """Main function to run the script"""
    print("Starting potential match generation...")
    
    # Assign interests to all users
    users = assign_interests_to_users()
    print(f"Updated interests for {len(users)} users")
    
    # Create events with interests
    events = create_events_with_interests()
    print(f"Created {len(events)} events")
    
    # Create matches
    match_count = create_potential_matches(events)
    
    # Summary
    print("\nSummary:")
    print(f"  Users: {User.objects.count()}")
    print(f"  Events: {StudyEvent.objects.count()}")
    print(f"  Auto-matched invitations: {EventInvitation.objects.filter(is_auto_matched=True).count()}")
    
    # Show top users with most matches
    print("\nTop users with most potential matches:")
    top_users = User.objects.annotate(
        match_count=django.db.models.Count('eventinvitation', filter=django.db.models.Q(eventinvitation__is_auto_matched=True))
    ).order_by('-match_count')[:5]
    
    for user in top_users:
        match_count = EventInvitation.objects.filter(user=user, is_auto_matched=True).count()
        try:
            user_profile = UserProfile.objects.get(user=user)
            profile_interests = user_profile.interests.split(',') if user_profile.interests else []
            interest_objects = [ui.interest for ui in UserInterest.objects.filter(user_profile=user_profile)]
            user_interests = list(set(profile_interests + interest_objects))
        except:
            user_interests = []
            
        print(f"  {user.username}: {match_count} matches")
        print(f"  Interests: {', '.join(user_interests)}")
    
    print("\nPotential match generation complete!")

if __name__ == "__main__":
    main()
