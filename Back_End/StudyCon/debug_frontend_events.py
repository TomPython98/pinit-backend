import os
import sys
import django
import json

# Set up Django environment
sys.path.append('/Users/tombesinger/Desktop/Full_App/Back_End/StudyCon/StudyCon')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from myapp.models import User, StudyEvent, EventInvitation
from myapp.views import get_study_events
from django.test import RequestFactory
from django.http import JsonResponse

def debug_frontend_events(username):
    """Debug what events are being returned by the backend API"""
    try:
        user = User.objects.get(username=username)
        print(f"=== Debug Frontend Events for: {username} ===")
        
        # Simulate the API call
        factory = RequestFactory()
        request = factory.get(f'/api/get_study_events/{username}/')
        
        # Call the view function directly
        response = get_study_events(request, username)
        
        if response.status_code == 200:
            events_data = json.loads(response.content)
            events = events_data.get('events', [])
            
            print(f"Total events returned: {len(events)}")
            
            # Categorize events
            own_events = []
            auto_matched_events = []
            public_events = []
            friend_events = []
            
            for event in events:
                if event['host'] == username:
                    own_events.append(event)
                elif event.get('isAutoMatched', False):
                    auto_matched_events.append(event)
                elif event.get('isPublic', False):
                    public_events.append(event)
                else:
                    friend_events.append(event)
            
            print(f"\n📊 Event Breakdown:")
            print(f"  - Own events: {len(own_events)}")
            print(f"  - Auto-matched events: {len(auto_matched_events)}")
            print(f"  - Public events: {len(public_events)}")
            print(f"  - Friend events: {len(friend_events)}")
            
            print(f"\n🏠 Own Events:")
            for event in own_events[:3]:
                print(f"  - {event['title']} (ID: {event['id']})")
            
            print(f"\n🎯 Auto-Matched Events:")
            for event in auto_matched_events[:5]:
                print(f"  - {event['title']} (Host: {event['host']}, ID: {event['id']})")
                print(f"    Interests: {event.get('interest_tags', [])}")
                print(f"    Auto-matched: {event.get('isAutoMatched', False)}")
            
            print(f"\n🌍 Public Events:")
            for event in public_events[:3]:
                print(f"  - {event['title']} (Host: {event['host']}, ID: {event['id']})")
            
            # Check if user is in invited_friends for auto-matched events
            print(f"\n🔍 Checking invited_friends for auto-matched events:")
            auto_invitations = EventInvitation.objects.filter(user=user, is_auto_matched=True)
            for inv in auto_invitations[:3]:
                event = inv.event
                is_in_invited_friends = event.invited_friends.filter(username=username).exists()
                print(f"  - Event: {event.title}")
                print(f"    Auto-matched invitation: ✓")
                print(f"    In invited_friends: {'✓' if is_in_invited_friends else '✗'}")
                print(f"    Event is_public: {event.is_public}")
            
        else:
            print(f"❌ API returned status code: {response.status_code}")
            print(f"Response: {response.content}")
            
    except User.DoesNotExist:
        print(f"User {username} not found")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    debug_frontend_events("Anna_Hoffmann_501") 