import os
import sys
import django

# Set up Django environment
sys.path.append('/Users/tombesinger/Desktop/Full_App/Back_End/StudyCon/StudyCon')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from myapp.models import StudyEvent, UserProfile, EventInvitation

print("Running auto-matching for all events...")

# Get all events with auto-matching enabled
events = StudyEvent.objects.filter(auto_matching_enabled=True)
print(f"Found {events.count()} events with auto-matching enabled")

# Get all users with auto-invite enabled
users = UserProfile.objects.filter(auto_invite_enabled=True)
print(f"Found {users.count()} users with auto-invite enabled")

# Clear existing auto-matched invitations
EventInvitation.objects.filter(is_auto_matched=True).delete()
print("Cleared existing auto-matched invitations")

matches = 0

for event in events:
    event_tags = event.get_interest_tags()
    if not event_tags:
        continue
        
    for profile in users:
        if profile.user == event.host:
            continue
            
        user_interests = profile.get_interests()
        if not user_interests:
            continue
            
        matching_interests = set(user_interests).intersection(set(event_tags))
        
        if matching_interests:
            try:
                EventInvitation.objects.get_or_create(
                    event=event,
                    user=profile.user,
                    defaults={'is_auto_matched': True}
                )
                matches += 1
            except Exception as e:
                print(f"Error creating invitation: {e}")

print(f"✅ Created {matches} auto-matched invitations!") 