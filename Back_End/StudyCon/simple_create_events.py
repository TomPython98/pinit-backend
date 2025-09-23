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
                 interest_tags=None, is_public=True, auto_matching_enabled=True):
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
    
    print(f"Created event: {event.title} (ID: {event.id})")
    print(f"  - Host: {host_username}")
    print(f"  - Type: {event_type}")
    print(f"  - Tags: {interest_tags}")
    return event

# Vienna coordinates (roughly central Vienna)
vienna_center_lat = 48.2082
vienna_center_lng = 16.3738

# Create Piano/Music events
print("\nCreating Piano/Music events...")
events = [
    create_event("Classical Piano Concert", "Evening of classical piano music", "user1", 
                 48.2017, 16.3721, "study", interest_tags=[PIANO_TAG, MUSIC_TAG]),
    create_event("Piano Lessons for Beginners", "Learn piano basics", "techuser1", 
                 48.2134, 16.3497, "study", interest_tags=[PIANO_TAG, MUSIC_TAG]),
    create_event("Vienna Music Festival", "Various music performances", "user3", 
                 48.2103, 16.3757, "party", interest_tags=[MUSIC_TAG]),
]

# Create Gym/Fitness events
print("\nCreating Gym/Fitness events...")
events.extend([
    create_event("Morning Gym Workout", "Daily fitness routine", "user2", 
                 48.1936, 16.3588, "study", interest_tags=[GYM_TAG, FITNESS_TAG]),
    create_event("HIIT Training Session", "High intensity workout", "user5", 
                 48.2057, 16.3809, "other", interest_tags=[GYM_TAG, FITNESS_TAG]),
    create_event("CrossFit Challenge", "Test your fitness", "user4", 
                 48.1985, 16.3910, "party", interest_tags=[GYM_TAG, FITNESS_TAG]),
])

# Create Spanish/Language events
print("\nCreating Spanish/Language events...")
events.extend([
    create_event("Spanish Conversation Group", "Practice speaking Spanish", "user3", 
                 48.2204, 16.3698, "study", interest_tags=[SPANISH_TAG, LANGUAGE_TAG]),
    create_event("Spanish Cultural Night", "Experience Spanish culture", "user4", 
                 48.2057, 16.3520, "party", interest_tags=[SPANISH_TAG]),
    create_event("Language Exchange Meetup", "Practice multiple languages", "techuser1", 
                 48.2261, 16.3580, "other", interest_tags=[SPANISH_TAG, LANGUAGE_TAG]),
])

print(f"\nCreated {len(events)} new events. The server will auto-match them based on user interests.")
print("Database reset complete.") 