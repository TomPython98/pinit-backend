#!/usr/bin/env python3
"""
Debug script to test host attendance directly in Django.
"""

import os
import sys
import django
from datetime import datetime, timedelta

# Setup Django
sys.path.append('StudyCon')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from myapp.models import User, StudyEvent

def debug_host_attendance():
    """Debug the host attendance issue directly in Django."""
    
    try:
        # Get the test user
        user = User.objects.get(username="Tatalia")
        print(f"✅ Found user: {user.username}")
        
        # Create a test event directly
        event = StudyEvent.objects.create(
            title="Debug Test Event",
            description="Testing host attendance directly",
            host=user,
            latitude=48.2082,
            longitude=16.3738,
            time=datetime.now() + timedelta(hours=1),
            end_time=datetime.now() + timedelta(hours=2),
            is_public=True,
            event_type="study",
            max_participants=10,
            auto_matching_enabled=False
        )
        
        print(f"✅ Created event: {event.id}")
        print(f"   Host: {event.host.username}")
        print(f"   Attendees before: {list(event.attendees.all())}")
        
        # Add host to attendees
        event.attendees.add(user)
        print(f"✅ Added host to attendees")
        
        # Save the event
        event.save()
        print(f"✅ Saved event")
        
        # Refresh from database
        event.refresh_from_db()
        print(f"   Attendees after: {list(event.attendees.all())}")
        
        # Check if host is in attendees
        if user in event.attendees.all():
            print("✅ SUCCESS: Host is in attendees!")
        else:
            print("❌ FAILURE: Host is NOT in attendees")
        
        # Clean up
        event.delete()
        print("🧹 Cleaned up test event")
        
        return True
        
    except User.DoesNotExist:
        print("❌ User 'Tatalia' not found")
        return False
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("🔍 Debugging host attendance directly in Django...")
    success = debug_host_attendance()
    
    if success:
        print("\n🎉 Database operations work correctly!")
    else:
        print("\n💥 Database operations failed!") 