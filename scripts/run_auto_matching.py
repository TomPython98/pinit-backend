#!/usr/bin/env python3
"""
Run auto-matching for all events to create auto-matched invitations
"""

import os
import sys
import django

# Add the Django project directory to the Python path
sys.path.append('/Users/tombesinger/Desktop/Full_App Kopie/Back_End/StudyCon/StudyCon')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from myapp.models import StudyEvent, User, EventInvitation, UserProfile
from django.db.models import Q

def run_auto_matching():
    """Run auto-matching for all events with auto-matching enabled"""
    
    # Get all events with auto-matching enabled
    auto_events = StudyEvent.objects.filter(auto_matching_enabled=True, is_public=True)
    print(f"Found {auto_events.count()} events with auto-matching enabled")
    
    total_matches = 0
    
    for event in auto_events:
        print(f"\n=== Processing event: {event.title} ===")
        print(f"Event interests: {event.interest_tags}")
        
        # Get users who have auto-invite enabled and are not already involved
        already_involved = set()
        already_involved.add(event.host.id)
        already_involved.update(event.invited_friends.values_list('id', flat=True))
        already_involved.update(event.attendees.values_list('id', flat=True))
        
        # Find users with matching interests
        potential_users = UserProfile.objects.filter(
            auto_invite_enabled=True
        ).exclude(
            user__id__in=already_involved
        ).select_related('user')
        
        matched_users = []
        for profile in potential_users:
            user_interests = profile.interests
            if user_interests:
                # Check for interest matches
                matches = [interest for interest in event.interest_tags if interest in user_interests]
                if len(matches) >= 1:  # At least 1 matching interest
                    matched_users.append(profile.user)
                    print(f"  Matched user: {profile.user.username} - Interests: {user_interests} - Matches: {matches}")
        
        # Create auto-match invitations for the first 5 matches
        for user in matched_users[:5]:
            invitation, created = EventInvitation.objects.get_or_create(
                event=event,
                user=user,
                defaults={'is_auto_matched': True}
            )
            if created:
                total_matches += 1
                print(f"  ✅ Created auto-match invitation for {user.username}")
            else:
                print(f"  ⚠️  Invitation already exists for {user.username}")
    
    print(f"\n✅ Total auto-match invitations created: {total_matches}")

if __name__ == "__main__":
    run_auto_matching()