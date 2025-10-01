import os
import django
import random

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from django.contrib.auth.models import User
from myapp.models import StudyEvent, EventInvitation

# Script to create potential matches 
def create_potential_matches():
    # Get all existing events with auto-matching enabled
    events = StudyEvent.objects.filter(auto_matching_enabled=True)
    print(f'Found {events.count()} events with auto-matching enabled')
    
    # Get all users
    users = User.objects.all()
    print(f'Found {users.count()} users')
    
    # Create potential matches
    match_count = 0
    
    for event in events[:10]:  # Process first 10 events
        print(f'Processing event {event.id}: {event.title}')
        
        # Get host
        host = event.host
        print(f'  Host: {host.username}')
        
        # Get random users to invite (exclude host)
        potential_users = [u for u in users if u != host]
        invite_users = random.sample(potential_users, min(5, len(potential_users)))
        
        for user in invite_users:
            # Create or get EventInvitation
            invitation, created = EventInvitation.objects.get_or_create(
                event=event,
                user=user,
                defaults={'is_auto_matched': True}
            )
            
            if created:
                match_count += 1
                print(f'  Created potential match: {user.username}')
            else:
                print(f'  Match already exists for: {user.username}')
    
    print(f'Created {match_count} new potential matches')
    print(f'Total auto-matched invitations: {EventInvitation.objects.filter(is_auto_matched=True).count()}')

create_potential_matches() 