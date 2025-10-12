#!/usr/bin/env python3
"""
Test script to verify that EventJoinRequest model can be created properly
after adding the missing id field.
"""

import os
import sys
import django
from django.conf import settings

# Add the project directory to Python path
sys.path.append('/Users/tombesinger/Desktop/PinItApp')

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from django.contrib.auth.models import User
from myapp.models import StudyEvent, EventJoinRequest
import uuid

def test_eventjoinrequest_creation():
    """Test that EventJoinRequest can be created with proper id field"""
    print("Testing EventJoinRequest creation...")
    
    try:
        # Create a test user if it doesn't exist
        user, created = User.objects.get_or_create(
            username='test_user_eventjoin',
            defaults={'email': 'test@example.com'}
        )
        if created:
            print(f"Created test user: {user.username}")
        else:
            print(f"Using existing test user: {user.username}")
        
        # Create a test event if it doesn't exist
        event, created = StudyEvent.objects.get_or_create(
            title='Test Event for Join Request',
            defaults={
                'host': user,
                'latitude': 40.7128,
                'longitude': -74.0060,
                'time': '2024-01-01 12:00:00+00:00',
                'end_time': '2024-01-01 14:00:00+00:00',
                'is_public': True,
                'event_type': 'study'
            }
        )
        if created:
            print(f"Created test event: {event.title}")
        else:
            print(f"Using existing test event: {event.title}")
        
        # Test creating an EventJoinRequest
        join_request = EventJoinRequest.objects.create(
            event=event,
            user=user,
            status='pending',
            message='Test join request'
        )
        
        print(f"✅ Successfully created EventJoinRequest with ID: {join_request.id}")
        print(f"   - Event: {join_request.event.title}")
        print(f"   - User: {join_request.user.username}")
        print(f"   - Status: {join_request.status}")
        print(f"   - Message: {join_request.message}")
        print(f"   - Created at: {join_request.created_at}")
        
        # Verify the id field is properly set
        assert join_request.id is not None, "ID field should not be None"
        assert isinstance(join_request.id, uuid.UUID), "ID should be a UUID instance"
        print(f"✅ ID field validation passed: {join_request.id}")
        
        # Clean up test data
        join_request.delete()
        print("✅ Test data cleaned up successfully")
        
        return True
        
    except Exception as e:
        print(f"❌ Error during test: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == '__main__':
    print("=" * 60)
    print("EventJoinRequest Model Fix Test")
    print("=" * 60)
    
    success = test_eventjoinrequest_creation()
    
    if success:
        print("\n🎉 All tests passed! EventJoinRequest model is working correctly.")
    else:
        print("\n💥 Tests failed! There may still be issues with the model.")
    
    print("=" * 60)
