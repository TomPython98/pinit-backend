import os
import sys
import django
import uuid
import datetime

# Set up Django environment
sys.path.append('/Users/tombesinger/Desktop/App/StudyCon/StudyCon')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from myapp.models import StudyEvent, User, UserProfile, EventInvitation

# Clear existing events
print("Clearing existing events...")
StudyEvent.objects.all().delete()
EventInvitation.objects.all().delete()
print("All events and invitations deleted.")

# Define our interest tags
MUSIC_TAG = "music"
PIANO_TAG = "piano"
GYM_TAG = "gym"
FITNESS_TAG = "fitness"
SPANISH_TAG = "spanish"
LANGUAGE_TAG = "language"

# Get user5 or create if not exists
try:
    user5 = User.objects.get(username='user5')
    print(f"Found user: {user5.username}")
except User.DoesNotExist:
    print("User5 not found! Creating user5...")
    user5 = User.objects.create_user(username='user5', password='password')
    UserProfile.objects.create(user=user5)
    print(f"Created user: {user5.username}")

# Create other test users if needed
test_users = ['user1', 'user2', 'user3', 'user4', 'techuser1']
users = {}
users['user5'] = user5

for username in test_users:
    try:
        user = User.objects.get(username=username)
        users[username] = user
        print(f"Found user: {username}")
    except User.DoesNotExist:
        user = User.objects.create_user(username=username, password='password')
        UserProfile.objects.create(user=user)
        users[username] = user
        print(f"Created user: {username}")

# Set user interests
def set_user_interests(username, interests):
    if username in users:
        user_profile = UserProfile.objects.get(user=users[username])
        user_profile.interests = interests
        user_profile.save()
        print(f"Set interests for {username}: {interests}")

# Set user interests based on requirements
set_user_interests('user1', [MUSIC_TAG, PIANO_TAG])  # Music/piano enthusiast
set_user_interests('user2', [GYM_TAG, FITNESS_TAG])  # Gym/fitness enthusiast 
set_user_interests('user3', [SPANISH_TAG, LANGUAGE_TAG])  # Spanish language learner
set_user_interests('user5', [MUSIC_TAG, GYM_TAG, SPANISH_TAG])  # User5 has all three interests

# Create new events
print("\nCreating new events...")

def create_event(title, description, host_username, lat, lng, event_type, 
                 interest_tags=None, is_public=True, matched_users=None, auto_matching_enabled=True):
    if matched_users is None:
        matched_users = []
    if interest_tags is None:
        interest_tags = []
    
    event = StudyEvent.objects.create(
        id=uuid.uuid4(),
        title=title,
        description=description,
        host=users[host_username],
        latitude=lat,
        longitude=lng,
        time=datetime.datetime.now() + datetime.timedelta(days=1),
        end_time=datetime.datetime.now() + datetime.timedelta(days=1, hours=2),
        is_public=is_public,
        event_type=event_type,
        auto_matching_enabled=auto_matching_enabled,
        interest_tags=interest_tags
    )
    
    # Add matched users via EventInvitation
    for username in matched_users:
        if username in users:
            EventInvitation.objects.create(
                event=event,
                user=users[username],
                is_auto_matched=True
            )
    
    print(f"Created event: {event.title} (ID: {event.id})")
    print(f"  - Host: {host_username}")
    print(f"  - Type: {event_type}")
    print(f"  - Tags: {interest_tags}")
    print(f"  - Auto-matched users: {matched_users}")
    return event

# Vienna coordinates (roughly central Vienna)
vienna_center_lat = 48.2082
vienna_center_lng = 16.3738

# Create a variety of events with different types, locations in Vienna, and interest tags
events = [
    # Music/Piano Events
    create_event("Piano Recital at Musikverein", "Join us for an evening of classical piano", "user5", 
                 48.2006, 16.3731, "study", interest_tags=[MUSIC_TAG, PIANO_TAG], 
                 matched_users=["user1"]),
    create_event("Piano Lessons for Beginners", "Learn piano basics in a group setting", "user1", 
                 48.2134, 16.3497, "study", interest_tags=[MUSIC_TAG, PIANO_TAG], 
                 matched_users=[]),
    create_event("Vienna Jazz Piano Night", "Live jazz piano performances by local artists", "user3", 
                 48.2103, 16.3757, "party", interest_tags=[MUSIC_TAG, PIANO_TAG], 
                 matched_users=[]),
    create_event("Piano Masterclass with Professor Schmidt", "Advanced techniques for experienced pianists", "techuser1", 
                 48.1957, 16.3673, "study", interest_tags=[MUSIC_TAG, PIANO_TAG], 
                 matched_users=[]),
    create_event("Music Theory Workshop", "Understanding harmony and composition", "user2", 
                 48.2089, 16.3813, "study", interest_tags=[MUSIC_TAG], 
                 matched_users=[]),
    
    # Gym/Fitness Events
    create_event("Strength Training Workshop", "Learn proper form for weightlifting", "user2", 
                 48.1936, 16.3588, "study", interest_tags=[GYM_TAG, FITNESS_TAG], 
                 matched_users=[]),
    create_event("HIIT Training in Stadtpark", "High-intensity interval training for all levels", "user5", 
                 48.2057, 16.3809, "other", interest_tags=[GYM_TAG, FITNESS_TAG], 
                 matched_users=[]),
    create_event("Yoga for Bodybuilders", "Flexibility training for gym enthusiasts", "user4", 
                 48.2124, 16.3678, "study", interest_tags=[GYM_TAG, FITNESS_TAG], 
                 matched_users=[]),
    create_event("Nutrition for Muscle Building", "Diet planning for fitness goals", "techuser1", 
                 48.2183, 16.3583, "business", interest_tags=[GYM_TAG, FITNESS_TAG], 
                 matched_users=[]),
    create_event("CrossFit Challenge", "Test your abilities in this friendly competition", "user3", 
                 48.1985, 16.3910, "party", interest_tags=[GYM_TAG, FITNESS_TAG], 
                 matched_users=[]),
    
    # Spanish Language Events
    create_event("Spanish for Beginners", "Learn the basics of Spanish conversation", "user3", 
                 48.2204, 16.3698, "study", interest_tags=[SPANISH_TAG, LANGUAGE_TAG], 
                 matched_users=[]),
    create_event("Spanish Film Night", "Watch and discuss a Spanish movie with subtitles", "user4", 
                 48.2057, 16.3520, "party", interest_tags=[SPANISH_TAG, LANGUAGE_TAG], 
                 matched_users=[]),
    create_event("Spanish Cooking Class", "Learn to make authentic tapas", "user5", 
                 48.1911, 16.3829, "other", interest_tags=[SPANISH_TAG], 
                 matched_users=[]),
    create_event("Business Spanish Workshop", "Spanish for professional contexts", "techuser1", 
                 48.2261, 16.3580, "business", interest_tags=[SPANISH_TAG, LANGUAGE_TAG], 
                 matched_users=[]),
    create_event("Spanish-Austrian Cultural Exchange", "Practice Spanish with native speakers", "user1", 
                 48.2132, 16.3869, "study", interest_tags=[SPANISH_TAG, LANGUAGE_TAG], 
                 matched_users=[]),
    
    # Mixed interest events
    create_event("Vienna International Student Meetup", "Meet students from around the world", "user5", 
                 48.2099, 16.3625, "other", interest_tags=[LANGUAGE_TAG, MUSIC_TAG], 
                 matched_users=[]),
    create_event("Mind and Body Wellness", "Combine fitness and relaxation techniques", "user2", 
                 48.2018, 16.3701, "study", interest_tags=[FITNESS_TAG, MUSIC_TAG], 
                 matched_users=[]),
    create_event("Language Exchange Party", "Practice languages in a fun setting", "user3", 
                 48.2154, 16.3577, "party", interest_tags=[LANGUAGE_TAG, SPANISH_TAG], 
                 matched_users=[]),
    create_event("International Dance Workshop", "Learn dance styles from around the world", "user4", 
                 48.2033, 16.3912, "study", interest_tags=[MUSIC_TAG, FITNESS_TAG], 
                 matched_users=[]),
    create_event("Networking for Expats", "Connect with internationals in Vienna", "techuser1", 
                 48.2112, 16.3761, "business", interest_tags=[LANGUAGE_TAG, PIANO_TAG], 
                 matched_users=[])
]

print(f"\nCreated {len(events)} new events successfully!")
print("Database reset complete.") 