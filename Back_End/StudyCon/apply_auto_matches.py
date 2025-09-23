import os
import sys
import django

# Set up Django environment
sys.path.append('/Users/tombesinger/Desktop/App/StudyCon/StudyCon')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from myapp.models import StudyEvent, User, UserProfile, EventInvitation

print("Applying auto-matching for all events...\n")

# Get all events with interest tags
events = StudyEvent.objects.all()
print(f"Found {events.count()} total events in database")

# Get all users 
users = User.objects.all()
users_with_interests = []

for user in users:
    try:
        profile = UserProfile.objects.get(user=user)
        user_interests = profile.get_interests()
        if user_interests:
            users_with_interests.append((user, user_interests))
            print(f"User {user.username} has interests: {user_interests}")
    except UserProfile.DoesNotExist:
        continue

print(f"\nFound {len(users_with_interests)} users with defined interests\n")

# Clear existing auto-matched invitations first
print("Clearing existing auto-matched invitations...")
EventInvitation.objects.filter(is_auto_matched=True).delete()
print("Done.")

# Threshold score for considering a match
MATCH_THRESHOLD = 10

# Counter for matches
total_matches = 0
events_with_matches = 0

# Apply matching process
for event in events:
    print(f"\n*** Event: {event.title} (ID: {event.id}) ***")
    print(f"  - Host: {event.host.username}")
    print(f"  - Type: {event.event_type}")
    
    event_tags = event.get_interest_tags()
    print(f"  - Tags: {event_tags}")
    
    if not event_tags:
        print("  No interest tags defined for this event, skipping matching")
        continue
    
    print("  Creating auto-matches:")
    matches_for_event = 0
    
    for user, interests in users_with_interests:
        # Skip the host - don't match users to their own events
        if user == event.host:
            continue
            
        # Check interest overlap
        matching_interests = set(interests).intersection(set(event_tags))
        
        if matching_interests:
            match_score = len(matching_interests) * 10  # Simple scoring
            
            if match_score >= MATCH_THRESHOLD:
                # Create auto-match invitation
                invitation, created = EventInvitation.objects.get_or_create(
                    event=event,
                    user=user,
                    defaults={'is_auto_matched': True}
                )
                
                if created:
                    matches_for_event += 1
                    total_matches += 1
                    print(f"  ✓ Created match for {user.username} - Matching interests: {matching_interests} (Score: {match_score})")
                else:
                    # Make sure it's marked as auto-matched
                    if not invitation.is_auto_matched:
                        invitation.is_auto_matched = True
                        invitation.save()
                        print(f"  ✓ Updated existing invitation for {user.username} to auto-matched")
                    else:
                        print(f"  ✓ Match already existed for {user.username}")
    
    if matches_for_event > 0:
        events_with_matches += 1
    
    if matches_for_event == 0:
        print("  No matches created for this event")

print(f"\nAuto-matching complete. Created {total_matches} matches for {events_with_matches} events.") 