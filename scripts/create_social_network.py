#!/usr/bin/env python3
"""
Create comprehensive social network for Buenos Aires users
- Friend connections
- Friend requests
- User reviews and ratings
- Private events with friend invitations
"""

import os
import sys
import django
import random
import uuid
from datetime import datetime, timedelta

# Add the Django project directory to the Python path
sys.path.append('/Users/tombesinger/Desktop/Full_App Kopie/Back_End/StudyCon/StudyCon')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from myapp.models import User, UserProfile, StudyEvent, EventInvitation, UserRating, UserReputationStats, FriendRequest
from django.contrib.auth.hashers import make_password

def create_social_network():
    """Create a comprehensive social network for Buenos Aires users"""
    
    # Get all Buenos Aires users (those with auto_invite_enabled=True)
    users = User.objects.filter(userprofile__auto_invite_enabled=True).select_related('userprofile')
    print(f"Found {users.count()} Buenos Aires users")
    
    # 1. CREATE FRIEND CONNECTIONS
    print("\n=== Creating Friend Connections ===")
    friend_connections = 0
    
    for user in users:
        # Each user gets 3-8 friends
        num_friends = random.randint(3, 8)
        
        # Get potential friends (not already friends, not self)
        current_friends = set(user.userprofile.friends.values_list('id', flat=True))
        potential_friends = users.exclude(id=user.id).exclude(id__in=current_friends)
        
        # Select random friends
        selected_friends = random.sample(list(potential_friends), min(num_friends, potential_friends.count()))
        
        # Add friends (bidirectional)
        for friend in selected_friends:
            user.userprofile.friends.add(friend.userprofile)
            friend.userprofile.friends.add(user.userprofile)
            friend_connections += 1
    
    print(f"✅ Created {friend_connections} friend connections")
    
    # 2. CREATE FRIEND REQUESTS
    print("\n=== Creating Friend Requests ===")
    friend_requests = 0
    
    for user in users:
        # Each user gets 1-3 pending friend requests
        num_requests = random.randint(1, 3)
        
        # Get users who are not already friends or have pending requests
        current_friends = set(user.userprofile.friends.values_list('id', flat=True))
        sent_requests = set(FriendRequest.objects.filter(from_user=user).values_list('to_user_id', flat=True))
        received_requests = set(FriendRequest.objects.filter(to_user=user).values_list('from_user_id', flat=True))
        
        excluded_users = current_friends | sent_requests | received_requests
        potential_requests = users.exclude(id=user.id).exclude(id__in=excluded_users)
        
        # Create friend requests
        for _ in range(min(num_requests, potential_requests.count())):
            to_user = random.choice(list(potential_requests))
            FriendRequest.objects.create(
                from_user=user,
                to_user=to_user
            )
            friend_requests += 1
            potential_requests = potential_requests.exclude(id=to_user.id)
    
    print(f"✅ Created {friend_requests} friend requests")
    
    # 3. CREATE USER REVIEWS AND RATINGS
    print("\n=== Creating User Reviews ===")
    reviews_created = 0
    
    for user in users:
        # Each user gets 2-5 reviews from other users
        num_reviews = random.randint(2, 5)
        
        # Get users who are not the current user
        potential_reviewers = users.exclude(id=user.id)
        
        for _ in range(min(num_reviews, potential_reviewers.count())):
            reviewer = random.choice(list(potential_reviewers))
            
            # Create review
            UserRating.objects.create(
                from_user=reviewer,
                to_user=user,
                rating=random.randint(3, 5),  # Mostly positive ratings
                reference=f"Great study partner! Very knowledgeable in {random.choice(['Environmental Studies', 'Gender Studies', 'Architecture', 'Philosophy'])}."
            )
            reviews_created += 1
            potential_reviewers = potential_reviewers.exclude(id=reviewer.id)
    
    print(f"✅ Created {reviews_created} user reviews")
    
    # 4. UPDATE REPUTATION STATS
    print("\n=== Updating Reputation Stats ===")
    reputation_updated = 0
    
    for user in users:
        # Get user's ratings
        ratings = UserRating.objects.filter(to_user=user)
        total_ratings = ratings.count()
        
        if total_ratings > 0:
            avg_rating = sum(r.rating for r in ratings) / total_ratings
            positive_ratings = ratings.filter(rating__gte=4).count()
            negative_ratings = ratings.filter(rating__lt=3).count()
            
            # Update or create reputation stats
            reputation, created = UserReputationStats.objects.get_or_create(
                user=user,
                defaults={
                    'total_ratings': total_ratings,
                    'average_rating': round(avg_rating, 2),
                    'positive_ratings': positive_ratings,
                    'negative_ratings': negative_ratings,
                    'events_hosted': random.randint(0, 3),
                    'events_attended': random.randint(1, 8)
                }
            )
            
            if not created:
                reputation.total_ratings = total_ratings
                reputation.average_rating = round(avg_rating, 2)
                reputation.positive_ratings = positive_ratings
                reputation.negative_ratings = negative_ratings
                reputation.save()
            
            reputation_updated += 1
    
    print(f"✅ Updated {reputation_updated} reputation stats")
    
    # 5. CREATE PRIVATE EVENTS WITH FRIEND INVITATIONS
    print("\n=== Creating Private Events ===")
    private_events = 0
    
    # Create 20 private events
    for _ in range(20):
        # Select a random host
        host = random.choice(list(users))
        
        # Create private event
        event = StudyEvent.objects.create(
            id=str(uuid.uuid4()),
            title=f"Private {random.choice(['Study Session', 'Language Exchange', 'Cultural Dinner', 'Study Group'])} - {host.first_name}",
            description=f"Exclusive private event for friends. {random.choice(['Bring your notes!', 'We\'ll practice Spanish together', 'Cultural exchange and food', 'Focused study session'])}",
            event_type=random.choice(['study_group', 'language_exchange', 'cultural', 'academic']),
            latitude=-34.6037 + random.uniform(-0.05, 0.05),  # Buenos Aires area
            longitude=-58.3816 + random.uniform(-0.05, 0.05),
            time=datetime.now() + timedelta(days=random.randint(1, 30), hours=random.randint(9, 20)),
            end_time=datetime.now() + timedelta(days=random.randint(1, 30), hours=random.randint(11, 22)),
            host=host,
            max_participants=random.randint(4, 12),
            auto_matching_enabled=False,
            is_public=False,  # Private event
            interest_tags=random.sample(['Environmental Studies', 'Gender Studies', 'Architecture', 'Philosophy', 'Spanish Language', 'Cultural Exchange'], random.randint(2, 4))
        )
        
        # Invite 2-5 friends
        friends = list(host.userprofile.friends.all()[:5])
        invited_friends = random.sample(friends, min(random.randint(2, 5), len(friends)))
        
        for friend in invited_friends:
            event.invited_friends.add(friend.user)
            # Create invitation record
            EventInvitation.objects.create(
                event=event,
                user=friend.user,
                is_auto_matched=False
            )
        
        private_events += 1
    
    print(f"✅ Created {private_events} private events with friend invitations")
    
    # 6. SUMMARY
    print(f"\n🎉 Social Network Creation Complete!")
    print(f"📊 Summary:")
    print(f"   - Friend connections: {friend_connections}")
    print(f"   - Friend requests: {friend_requests}")
    print(f"   - User reviews: {reviews_created}")
    print(f"   - Reputation stats updated: {reputation_updated}")
    print(f"   - Private events: {private_events}")

if __name__ == "__main__":
    create_social_network()
