#!/usr/bin/env python3
"""
Missing Endpoints Implementation Script
This script provides code examples for implementing the missing API endpoints
"""

def generate_health_endpoint():
    """Generate health check endpoint code"""
    return '''
# Health Check Endpoint
@api_view(['GET'])
def health_check(request):
    """
    Health check endpoint to verify server status
    """
    try:
        # Check database connection
        from django.db import connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        
        # Check if we can query basic models
        from .models import User, StudyEvent
        user_count = User.objects.count()
        event_count = StudyEvent.objects.count()
        
        return Response({
            'status': 'healthy',
            'database': 'connected',
            'users': user_count,
            'events': event_count,
            'timestamp': timezone.now().isoformat()
        }, status=200)
    except Exception as e:
        return Response({
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': timezone.now().isoformat()
        }, status=500)
'''

def generate_events_list_endpoint():
    """Generate events list endpoint code"""
    return '''
# Events List Endpoint
@api_view(['GET'])
def list_events(request):
    """
    Get list of all events with optional filtering
    """
    try:
        # Get query parameters
        event_type = request.GET.get('type')
        latitude = request.GET.get('lat')
        longitude = request.GET.get('lng')
        radius = request.GET.get('radius', 10)  # Default 10km radius
        limit = int(request.GET.get('limit', 50))  # Default 50 events
        offset = int(request.GET.get('offset', 0))
        
        # Start with all events
        events = StudyEvent.objects.all()
        
        # Filter by type if specified
        if event_type:
            events = events.filter(event_type=event_type)
        
        # Filter by location if coordinates provided
        if latitude and longitude:
            try:
                lat = float(latitude)
                lng = float(longitude)
                rad = float(radius)
                
                # Simple distance filtering (you might want to use PostGIS for better performance)
                events = events.extra(
                    where=[
                        "6371 * acos(cos(radians(%s)) * cos(radians(latitude)) * cos(radians(longitude) - radians(%s)) + sin(radians(%s)) * sin(radians(latitude))) <= %s"
                    ],
                    params=[lat, lng, lat, rad]
                )
            except ValueError:
                return Response({'error': 'Invalid coordinates'}, status=400)
        
        # Order by creation date (newest first)
        events = events.order_by('-created_at')
        
        # Apply pagination
        events = events[offset:offset + limit]
        
        # Serialize events
        event_data = []
        for event in events:
            event_data.append({
                'id': str(event.id),
                'title': event.title,
                'description': event.description,
                'host': event.host.username,
                'latitude': float(event.latitude),
                'longitude': float(event.longitude),
                'time': event.time.isoformat(),
                'end_time': event.end_time.isoformat(),
                'max_participants': event.max_participants,
                'current_participants': event.participants.count(),
                'event_type': event.event_type,
                'interest_tags': event.interest_tags,
                'auto_matching_enabled': event.auto_matching_enabled,
                'created_at': event.created_at.isoformat()
            })
        
        return Response({
            'events': event_data,
            'total': events.count(),
            'limit': limit,
            'offset': offset
        }, status=200)
        
    except Exception as e:
        return Response({'error': str(e)}, status=500)
'''

def generate_users_list_endpoint():
    """Generate users list endpoint code"""
    return '''
# Users List Endpoint
@api_view(['GET'])
def list_users(request):
    """
    Get list of all users with optional filtering
    """
    try:
        # Get query parameters
        university = request.GET.get('university')
        degree = request.GET.get('degree')
        country = request.GET.get('country')
        limit = int(request.GET.get('limit', 50))
        offset = int(request.GET.get('offset', 0))
        
        # Start with all users
        users = User.objects.all()
        
        # Filter by university if specified
        if university:
            users = users.filter(university__icontains=university)
        
        # Filter by degree if specified
        if degree:
            users = users.filter(degree__icontains=degree)
        
        # Filter by country if specified
        if country:
            users = users.filter(country__icontains=country)
        
        # Order by username
        users = users.order_by('username')
        
        # Apply pagination
        users = users[offset:offset + limit]
        
        # Serialize users (exclude sensitive info)
        user_data = []
        for user in users:
            user_data.append({
                'username': user.username,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'university': user.university,
                'degree': user.degree,
                'year': user.year,
                'country': user.country,
                'bio': user.bio,
                'interests': user.interests,
                'skills': user.skills,
                'created_at': user.date_joined.isoformat()
            })
        
        return Response({
            'users': user_data,
            'total': users.count(),
            'limit': limit,
            'offset': offset
        }, status=200)
        
    except Exception as e:
        return Response({'error': str(e)}, status=500)
'''

def generate_friends_list_endpoint():
    """Generate friends list endpoint code"""
    return '''
# Friends List Endpoint
@api_view(['GET'])
def list_friends(request, username):
    """
    Get list of friends for a specific user
    """
    try:
        # Get user
        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=404)
        
        # Get accepted friend connections
        friends = user.friends.all()
        
        # Serialize friends
        friend_data = []
        for friend in friends:
            friend_data.append({
                'username': friend.username,
                'first_name': friend.first_name,
                'last_name': friend.last_name,
                'university': friend.university,
                'degree': friend.degree,
                'year': friend.year,
                'country': friend.country,
                'bio': friend.bio,
                'interests': friend.interests,
                'skills': friend.skills
            })
        
        return Response({
            'username': username,
            'friends': friend_data,
            'total': len(friend_data)
        }, status=200)
        
    except Exception as e:
        return Response({'error': str(e)}, status=500)
'''

def generate_invite_user_endpoint():
    """Generate invite user to event endpoint code"""
    return '''
# Invite User to Event Endpoint
@api_view(['POST'])
def invite_user_to_event(request):
    """
    Send a direct invitation to a user for an event
    """
    try:
        username = request.data.get('username')
        event_id = request.data.get('event_id')
        inviter = request.data.get('inviter')
        
        if not all([username, event_id, inviter]):
            return Response({
                'error': 'Missing required fields: username, event_id, inviter'
            }, status=400)
        
        # Get user and event
        try:
            user = User.objects.get(username=username)
            event = StudyEvent.objects.get(id=event_id)
            inviter_user = User.objects.get(username=inviter)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=404)
        except StudyEvent.DoesNotExist:
            return Response({'error': 'Event not found'}, status=404)
        
        # Check if user is already invited or RSVP'd
        if event.participants.filter(username=username).exists():
            return Response({
                'error': 'User is already participating in this event'
            }, status=400)
        
        # Create invitation (you'll need to create an Invitation model)
        invitation, created = EventInvitation.objects.get_or_create(
            event=event,
            user=user,
            inviter=inviter_user,
            defaults={'status': 'pending'}
        )
        
        if not created:
            return Response({
                'error': 'Invitation already exists'
            }, status=400)
        
        # Send notification (implement your notification system)
        # send_notification(user, f"You've been invited to {event.title} by {inviter}")
        
        return Response({
            'success': True,
            'message': f'Invitation sent to {username}',
            'invitation_id': str(invitation.id)
        }, status=201)
        
    except Exception as e:
        return Response({'error': str(e)}, status=500)
'''

def generate_auto_matching_endpoint():
    """Generate auto-matching endpoint code"""
    return '''
# Auto-Matching Endpoint
@api_view(['POST'])
def run_auto_matching(request):
    """
    Run auto-matching for events with matching enabled
    """
    try:
        event_id = request.data.get('event_id')
        
        if not event_id:
            return Response({'error': 'event_id is required'}, status=400)
        
        try:
            event = StudyEvent.objects.get(id=event_id)
        except StudyEvent.DoesNotExist:
            return Response({'error': 'Event not found'}, status=404)
        
        if not event.auto_matching_enabled:
            return Response({
                'error': 'Auto-matching is not enabled for this event'
            }, status=400)
        
        # Get potential matches based on interests and location
        matches_found = 0
        
        # Find users with matching interests
        matching_users = User.objects.filter(
            interests__overlap=event.interest_tags
        ).exclude(
            username=event.host.username
        ).exclude(
            id__in=event.participants.values_list('id', flat=True)
        )
        
        # Filter by location if specified
        if event.latitude and event.longitude:
            # Simple distance filtering (consider using PostGIS for better performance)
            matching_users = matching_users.extra(
                where=[
                    "6371 * acos(cos(radians(%s)) * cos(radians(latitude)) * cos(radians(longitude) - radians(%s)) + sin(radians(%s)) * sin(radians(latitude))) <= %s"
                ],
                params=[event.latitude, event.longitude, event.latitude, 10]  # 10km radius
            )
        
        # Limit to available spots
        available_spots = event.max_participants - event.participants.count()
        matching_users = matching_users[:available_spots]
        
        # Add matches to event
        for user in matching_users:
            if user.auto_invite_preference:
                event.participants.add(user)
                matches_found += 1
                
                # Send notification
                # send_notification(user, f"You've been auto-matched to {event.title}")
        
        return Response({
            'success': True,
            'matches_found': matches_found,
            'event_id': str(event.id),
            'message': f'Auto-matched {matches_found} users to the event'
        }, status=200)
        
    except Exception as e:
        return Response({'error': str(e)}, status=500)
'''

def generate_notifications_endpoint():
    """Generate notifications endpoint code"""
    return '''
# Notifications Endpoint
@api_view(['GET'])
def get_notifications(request, username):
    """
    Get notifications for a specific user
    """
    try:
        # Get user
        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=404)
        
        # Get notifications (you'll need to create a Notification model)
        notifications = Notification.objects.filter(user=user).order_by('-created_at')
        
        # Serialize notifications
        notification_data = []
        for notification in notifications:
            notification_data.append({
                'id': str(notification.id),
                'type': notification.type,
                'title': notification.title,
                'message': notification.message,
                'read': notification.read,
                'created_at': notification.created_at.isoformat(),
                'data': notification.data  # Additional data as JSON
            })
        
        return Response({
            'username': username,
            'notifications': notification_data,
            'unread_count': notifications.filter(read=False).count()
        }, status=200)
        
    except Exception as e:
        return Response({'error': str(e)}, status=500)
'''

def generate_url_patterns():
    """Generate URL patterns for the new endpoints"""
    return '''
# Add these to your urls.py file

urlpatterns = [
    # ... existing patterns ...
    
    # New endpoints
    path('health/', health_check, name='health_check'),
    path('events/', list_events, name='list_events'),
    path('users/', list_users, name='list_users'),
    path('users/<str:username>/friends/', list_friends, name='list_friends'),
    path('invite_user_to_event/', invite_user_to_event, name='invite_user_to_event'),
    path('run_auto_matching/', run_auto_matching, name='run_auto_matching'),
    path('users/<str:username>/notifications/', get_notifications, name='get_notifications'),
]
'''

def generate_models():
    """Generate additional models needed for new endpoints"""
    return '''
# Add these models to your models.py file

class EventInvitation(models.Model):
    event = models.ForeignKey(StudyEvent, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    inviter = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_invitations')
    status = models.CharField(max_length=20, choices=[
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('declined', 'Declined')
    ], default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['event', 'user']

class Notification(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    type = models.CharField(max_length=50)  # 'friend_request', 'event_invitation', 'event_reminder', etc.
    title = models.CharField(max_length=200)
    message = models.TextField()
    read = models.BooleanField(default=False)
    data = models.JSONField(default=dict, blank=True)  # Additional data
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
'''

def main():
    """Generate all the missing endpoint code"""
    print("🛠️ Generating Missing API Endpoints")
    print("=" * 50)
    
    endpoints = [
        ("Health Check", generate_health_endpoint()),
        ("Events List", generate_events_list_endpoint()),
        ("Users List", generate_users_list_endpoint()),
        ("Friends List", generate_friends_list_endpoint()),
        ("Invite User to Event", generate_invite_user_endpoint()),
        ("Auto-Matching", generate_auto_matching_endpoint()),
        ("Notifications", generate_notifications_endpoint()),
    ]
    
    print("\n📝 ENDPOINT IMPLEMENTATIONS:")
    print("=" * 50)
    
    for name, code in endpoints:
        print(f"\n### {name}")
        print(code)
    
    print("\n🔗 URL PATTERNS:")
    print("=" * 50)
    print(generate_url_patterns())
    
    print("\n📊 ADDITIONAL MODELS:")
    print("=" * 50)
    print(generate_models())
    
    print("\n✅ IMPLEMENTATION COMPLETE!")
    print("Copy the code above into your Django views.py, urls.py, and models.py files")
    print("Don't forget to run migrations after adding the new models!")

if __name__ == "__main__":
    main()
