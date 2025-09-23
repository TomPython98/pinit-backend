import os
import sys
import django
import random
from datetime import datetime, timedelta
from django.utils import timezone

# Set up Django environment
sys.path.append('/Users/tombesinger/Desktop/Full_App/Back_End/StudyCon/StudyCon')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from django.contrib.auth.models import User
from myapp.models import StudyEvent, UserProfile, EventInvitation, UserTrustLevel, UserReputationStats, FriendRequest
from django.db import transaction

# Vienna universities
VIENNA_UNIVERSITIES = [
    "University of Vienna",
    "Vienna University of Technology (TU Wien)",
    "Medical University of Vienna",
    "Vienna University of Economics and Business (WU)",
    "University of Natural Resources and Life Sciences (BOKU)"
]

# Vienna locations
VIENNA_LOCATIONS = [
    {"name": "Innere Stadt", "lat": 48.2082, "lon": 16.3738},
    {"name": "Leopoldstadt", "lat": 48.2148, "lon": 16.3785},
    {"name": "Landstraße", "lat": 48.1987, "lon": 16.3833},
    {"name": "Wieden", "lat": 48.1925, "lon": 16.3667},
    {"name": "Mariahilf", "lat": 48.1983, "lon": 16.3583},
    {"name": "Neubau", "lat": 48.2050, "lon": 16.3583},
    {"name": "Josefstadt", "lat": 48.2117, "lon": 16.3583},
    {"name": "Alsergrund", "lat": 48.2183, "lon": 16.3583}
]

# Popular interests
VIENNA_INTERESTS = [
    "Computer Science", "Mathematics", "Physics", "Medicine", "Economics", "Law", "Psychology", "History", "Philosophy",
    "Classical Music", "Opera", "Jazz", "Contemporary Art", "Museums", "Theater", "Film", "Photography",
    "Vienna Coffee Culture", "Austrian Cuisine", "Wine Tasting", "Café Culture", "Historical Sites",
    "Hiking", "Cycling", "Soccer", "Tennis", "Swimming", "Yoga", "Meditation", "Cooking", "Baking",
    "Networking", "Startups", "Entrepreneurship", "Marketing", "Finance", "Consulting", "Research",
    "German", "English", "French", "Italian", "Spanish", "Russian", "Chinese", "Japanese",
    "Language Exchange", "Cultural Exchange", "International Students", "Study Abroad",
    "Sustainability", "Climate Change", "Social Justice", "Volunteering", "Community Service"
]

def create_trust_levels():
    """Create default trust levels"""
    levels = [
        {"level": 1, "title": "Newcomer", "required_ratings": 0, "min_average_rating": 0.0},
        {"level": 2, "title": "Active Member", "required_ratings": 3, "min_average_rating": 3.5},
        {"level": 3, "title": "Trusted Member", "required_ratings": 10, "min_average_rating": 4.0},
        {"level": 4, "title": "Community Leader", "required_ratings": 25, "min_average_rating": 4.2},
        {"level": 5, "title": "Vienna Expert", "required_ratings": 50, "min_average_rating": 4.5}
    ]
    
    for level_data in levels:
        UserTrustLevel.objects.get_or_create(
            level=level_data["level"],
            defaults=level_data
        )

def generate_unique_username():
    """Generate a unique username"""
    first_names = ["Alex", "Anna", "Ben", "Clara", "David", "Emma", "Felix", "Greta", "Hans", "Iris", "Jan", "Kara", "Lars", "Mia", "Nils", "Ola", "Pia", "Quinn", "Rosa", "Sam", "Tina", "Uwe", "Vera", "Will", "Yara", "Zoe"]
    last_names = ["Bauer", "Müller", "Schmidt", "Weber", "Wagner", "Fischer", "Meyer", "Becker", "Schulz", "Hoffmann", "Koch", "Richter", "Klein", "Wolf", "Schröder", "Neumann", "Schwarz", "Zimmermann", "Braun", "Krüger"]
    
    while True:
        username = f"{random.choice(first_names)}_{random.choice(last_names)}_{random.randint(100, 999)}"
        if not User.objects.filter(username=username).exists():
            return username

def create_vienna_users(num_users=50):
    """Create Vienna users"""
    print(f"Creating {num_users} Vienna users...")
    
    create_trust_levels()
    users_created = []  # List of dicts for credentials
    user_objs = []      # List of Django User objects
    
    for i in range(num_users):
        try:
            username = generate_unique_username()
            email = f"{username.lower()}@vienna.edu"
            password = "vienna123"
            
            user = User.objects.create_user(
                username=username,
                email=email,
                password=password,
                first_name=username.split('_')[0],
                last_name=username.split('_')[1]
            )
            
            # Profile data
            university = random.choice(VIENNA_UNIVERSITIES)
            degrees = ["Computer Science", "Mathematics", "Physics", "Medicine", "Economics", "Law", "Psychology", "History", "Philosophy", "Engineering", "Business Administration"]
            degree = random.choice(degrees)
            year = random.choice(["1st Year", "2nd Year", "3rd Year", "Master's", "PhD"])
            
            interests = random.sample(VIENNA_INTERESTS, random.randint(3, 6))
            skills = {
                random.choice(["Python", "Java", "JavaScript", "German", "English", "French", "Cooking", "Photography", "Music"]): 
                random.choice(["BEGINNER", "INTERMEDIATE", "ADVANCED"])
            }
            
            bio = f"Student at {university} studying {degree}. Love {', '.join(interests[:2])} and exploring Vienna!"
            
            profile = UserProfile.objects.get(user=user)
            profile.full_name = f"{user.first_name} {user.last_name}"
            profile.university = university
            profile.degree = degree
            profile.year = year
            profile.bio = bio
            profile.interests = interests
            profile.skills = skills
            profile.auto_invite_enabled = random.choice([True, True, True, False])
            profile.preferred_radius = random.uniform(5.0, 15.0)
            profile.save()
            
            # Reputation stats
            trust_level = UserTrustLevel.objects.get(level=random.choices([1, 2, 3], weights=[0.5, 0.3, 0.2])[0])
            UserReputationStats.objects.create(
                user=user,
                total_ratings=random.randint(0, 15),
                average_rating=random.uniform(3.0, 5.0),
                trust_level=trust_level,
                events_hosted=random.randint(0, 3),
                events_attended=random.randint(0, 10)
            )
            
            users_created.append({
                "username": username,
                "password": password,
                "email": email,
                "university": university,
                "degree": degree,
                "interests": interests
            })
            user_objs.append(user)
            
        except Exception as e:
            print(f"Error creating user {i}: {str(e)}")
            continue
    
    print(f"✅ Created {len(users_created)} Vienna users!")
    return user_objs, users_created

def create_vienna_events(num_events=30):
    """Create Vienna events with auto-matching"""
    print(f"Creating {num_events} Vienna events...")
    
    users = list(User.objects.all())
    if not users:
        print("❌ No users found!")
        return []
    
    events_created = []
    
    event_templates = {
        "study": [
            "Study Group: {subject}",
            "{subject} Review Session",
            "Group Project: {subject}",
            "Exam Prep: {subject}",
            "Research Meeting: {subject}"
        ],
        "party": [
            "Vienna Night Out",
            "International Student Meetup",
            "Cultural Exchange Party",
            "Music & Dance Night",
            "Game Night"
        ],
        "business": [
            "Networking Event",
            "Startup Meetup",
            "Career Development Workshop",
            "Business Pitch Night",
            "Professional Networking"
        ],
        "other": [
            "Vienna Walking Tour",
            "Cooking Class: {cuisine}",
            "Language Exchange",
            "Photography Workshop",
            "Museum Visit"
        ]
    }
    
    study_subjects = ["Computer Science", "Mathematics", "Physics", "Medicine", "Economics", "Law", "Psychology", "History", "Philosophy"]
    cuisines = ["Austrian", "Italian", "Asian", "Mediterranean"]
    
    for i in range(num_events):
        try:
            host = random.choice(users)
            event_type = random.choice(list(event_templates.keys()))
            template = random.choice(event_templates[event_type])
            
            # Generate interests
            if event_type == "study":
                event_interests = random.sample(study_subjects, random.randint(2, 4))
            elif event_type == "party":
                event_interests = ["Classical Music", "Jazz", "Dancing", "Socializing", "Cultural Exchange"]
            elif event_type == "business":
                event_interests = ["Networking", "Startups", "Entrepreneurship", "Marketing", "Finance"]
            else:
                event_interests = ["Hiking", "Cycling", "Cooking", "Photography", "Travel", "Museums"]
            
            # Generate title
            if "{subject}" in template:
                subject = random.choice(event_interests)
                title = template.format(subject=subject)
            elif "{cuisine}" in template:
                cuisine = random.choice(cuisines)
                title = template.format(cuisine=cuisine)
            else:
                title = template
            
            # Location and time
            location = random.choice(VIENNA_LOCATIONS)
            event_time = timezone.now() + timedelta(days=random.randint(1, 14), hours=random.randint(9, 20))
            end_time = event_time + timedelta(hours=random.randint(1, 3))
            
            # Create event
            event = StudyEvent.objects.create(
                title=title,
                description=f"Join us for an amazing {event_type} event in Vienna! Perfect for meeting new people and having a great time.",
                host=host,
                latitude=location["lat"] + random.uniform(-0.005, 0.005),
                longitude=location["lon"] + random.uniform(-0.005, 0.005),
                time=event_time,
                end_time=end_time,
                is_public=True,
                event_type=event_type,
                max_participants=random.randint(5, 15),
                auto_matching_enabled=random.choice([True, True, True, False]),  # 75% enable auto-matching
                interest_tags=event_interests
            )
            
            events_created.append({
                "id": str(event.id),
                "title": title,
                "host": host.username,
                "type": event_type,
                "interests": event_interests,
                "location": location["name"],
                "time": event_time.strftime("%Y-%m-%d %H:%M"),
                "auto_matching": event.auto_matching_enabled
            })
            
        except Exception as e:
            print(f"Error creating event {i}: {str(e)}")
            continue
    
    print(f"✅ Created {len(events_created)} Vienna events!")
    return events_created

def create_friendships(users, connection_density=0.15):
    """Create realistic friendships between users"""
    print(f"Creating friendships with {connection_density*100}% connection density...")
    
    friendships_created = 0
    friend_requests_created = 0
    
    for user in users:
        # Each user connects with ~15% of other users
        num_connections = int(len(users) * connection_density)
        potential_friends = [u for u in users if u != user and u.userprofile not in user.userprofile.friends.all()]
        
        if potential_friends:
            # Randomly select friends
            friends_to_add = random.sample(potential_friends, min(num_connections, len(potential_friends)))
            
            for friend in friends_to_add:
                # 80% chance of established friendship, 20% chance of pending request
                if random.random() < 0.8:
                    # Create mutual friendship
                    user.userprofile.friends.add(friend.userprofile)
                    friend.userprofile.friends.add(user.userprofile)
                    friendships_created += 1
                else:
                    # Create a friend request (if none exists)
                    if not FriendRequest.objects.filter(from_user=user, to_user=friend).exists() and \
                       not FriendRequest.objects.filter(from_user=friend, to_user=user).exists():
                        FriendRequest.objects.create(from_user=user, to_user=friend)
                        friend_requests_created += 1
    
    print(f"✅ Created {friendships_created} friendships and {friend_requests_created} pending friend requests!")
    return friendships_created, friend_requests_created

def save_credentials(users, events):
    """Save credentials to file"""
    with open("vienna_simulation_credentials.txt", "w") as f:
        f.write("VIENNA SIMULATION CREDENTIALS\n")
        f.write("=" * 50 + "\n\n")
        
        f.write("USER ACCOUNTS (Username: Password)\n")
        f.write("-" * 30 + "\n")
        for user in users:
            f.write(f"{user['username']}: {user['password']}\n")
        
        f.write(f"\nSAMPLE EVENTS WITH AUTO-MATCHING\n")
        f.write("-" * 35 + "\n")
        auto_matched_events = [e for e in events if e['auto_matching']]
        for event in auto_matched_events[:10]:
            f.write(f"ID: {event['id']}\n")
            f.write(f"Title: {event['title']}\n")
            f.write(f"Host: {event['host']}\n")
            f.write(f"Type: {event['type']}\n")
            f.write(f"Interests: {', '.join(event['interests'])}\n")
            f.write(f"Location: {event['location']}\n")
            f.write(f"Time: {event['time']}\n")
            f.write("-" * 20 + "\n")
        
        f.write(f"\nTotal users: {len(users)}\n")
        f.write(f"Total events: {len(events)}\n")
        f.write(f"Auto-matched events: {len(auto_matched_events)}\n")
        
        f.write("\nTESTING INSTRUCTIONS:\n")
        f.write("-" * 20 + "\n")
        f.write("1. Use any username:password combination above to log in\n")
        f.write("2. Create events with interest tags to test auto-matching\n")
        f.write("3. Check the auto-matched events filter in the app\n")
        f.write("4. Use the event IDs above to test the enhanced matching API\n")
    
    print("✅ Credentials saved to 'vienna_simulation_credentials.txt'")

def main():
    """Main function"""
    print("🏛️ Creating Vienna Simulation Database (Large Version)")
    print("=" * 60)
    
    # Create users
    user_objs, users_created = create_vienna_users(100)  # Increased from 50 to 100
    
    # Create friendships
    friendships, requests = create_friendships(user_objs, connection_density=0.15)
    
    # Create events
    events = create_vienna_events(80)  # Increased from 30 to 80
    
    # Save credentials
    save_credentials(users_created, events)
    
    print("\n🎉 Vienna Simulation Complete!")
    print("=" * 30)
    print(f"✅ Created {len(users_created)} users")
    print(f"✅ Created {friendships} friendships and {requests} pending requests")
    print(f"✅ Created {len(events)} events")
    print(f"✅ {len([e for e in events if e['auto_matching']])} events have auto-matching enabled")
    print("✅ Credentials saved to 'vienna_simulation_credentials.txt'")
    print("\n🔍 Test the enhanced automatching system:")
    print("1. Log in with any user from the credentials file")
    print("2. Create events with interest tags")
    print("3. Check auto-matched events in the app")
    print("4. Use the API to test matching algorithms")
    print("5. Test friend requests and social connections")

if __name__ == "__main__":
    main() 