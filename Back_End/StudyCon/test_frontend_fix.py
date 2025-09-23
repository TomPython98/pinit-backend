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

def test_frontend_fix(username):
    """Test if the frontend fix is working by checking API response"""
    try:
        user = User.objects.get(username=username)
        print(f"=== Testing Frontend Fix for: {username} ===")
        
        # Simulate the API call
        factory = RequestFactory()
        request = factory.get(f'/api/get_study_events/{username}/')
        
        # Call the view function directly
        response = get_study_events(request, username)
        
        if response.status_code == 200:
            events_data = json.loads(response.content)
            events = events_data.get('events', [])
            
            print(f"Total events returned: {len(events)}")
            
            # Count auto-matched events
            auto_matched_count = sum(1 for event in events if event.get('isAutoMatched', False))
            own_events_count = sum(1 for event in events if event['host'] == username)
            public_events_count = sum(1 for event in events if event.get('isPublic', False) and event['host'] != username and not event.get('isAutoMatched', False))
            
            print(f"\n📊 Event Counts:")
            print(f"  - Auto-matched events: {auto_matched_count}")
            print(f"  - Own events: {own_events_count}")
            print(f"  - Public events: {public_events_count}")
            
            # Show some auto-matched events
            auto_matched_events = [event for event in events if event.get('isAutoMatched', False)]
            print(f"\n🎯 Auto-Matched Events (showing first 5):")
            for event in auto_matched_events[:5]:
                print(f"  - {event['title']} (Host: {event['host']})")
                print(f"    Interests: {event.get('interest_tags', [])}")
                print(f"    Auto-matched: {event.get('isAutoMatched', False)}")
                print()
            
            # Check if user is in invited_friends for auto-matched events
            print(f"🔍 Verifying invited_friends for auto-matched events:")
            auto_invitations = EventInvitation.objects.filter(user=user, is_auto_matched=True)
            for inv in auto_invitations[:3]:
                event = inv.event
                is_in_invited_friends = event.invited_friends.filter(username=username).exists()
                print(f"  - Event: {event.title}")
                print(f"    Auto-matched invitation: ✓")
                print(f"    In invited_friends: {'✓' if is_in_invited_friends else '✗'}")
                print(f"    Event is_public: {event.is_public}")
                print()
            
            # Test the fix
            if auto_matched_count > 0:
                print("✅ SUCCESS: Auto-matched events are being returned by the API!")
                print("   The frontend should now display these events.")
            else:
                print("❌ ISSUE: No auto-matched events found in API response")
                
        else:
            print(f"❌ API returned status code: {response.status_code}")
            
    except User.DoesNotExist:
        print(f"User {username} not found")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_frontend_fix("Anna_Hoffmann_501") 