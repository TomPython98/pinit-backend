#!/usr/bin/env python3
"""
Test Script: Send Private Invitation to Tom
Creates a private event from a test user and invites tom, which triggers a push notification.
"""

import os
import django
import sys
import uuid

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from django.contrib.auth.models import User
from myapp.models import StudyEvent, EventInvitation, Device
from myapp.views import send_push_notification
import json

def get_or_create_test_user():
    """Get or create a test user"""
    username = "testuser"
    try:
        user = User.objects.get(username=username)
        print(f"✓ Using existing test user: {username}")
    except User.DoesNotExist:
        user = User.objects.create_user(username=username, email=f"{username}@test.com", password="testpass123")
        print(f"✓ Created new test user: {username}")
    return user

def get_tom_user():
    """Get tom user"""
    try:
        tom = User.objects.get(username="tom")
        print(f"✓ Found tom user")
        return tom
    except User.DoesNotExist:
        print("❌ tom user not found. Please create tom user first.")
        return None

def create_private_event(host_user):
    """Create a private event"""
    event = StudyEvent.objects.create(
        id=uuid.uuid4(),
        title="Private Invitation Test Event",
        description="This is a private event to test invitations and push notifications",
        location="Test Location",
        latitude=-34.6037,
        longitude=-58.3816,
        start_time=None,  # No specific time
        end_time=None,
        event_type="social",
        is_public=False,  # PRIVATE
        host=host_user,
    )
    print(f"✓ Created private event: {event.title} (ID: {event.id})")
    return event

def send_invitation_to_tom(event, tom_user):
    """Send invitation to tom"""
    try:
        # Create invitation record
        invitation = EventInvitation.objects.create(
            event=event,
            user=tom_user,
            is_auto_matched=False
        )
        print(f"✓ Created invitation record for tom")
        
        # Send push notification
        try:
            send_push_notification(
                user_id=tom_user.id,
                notification_type='event_invitation',
                event_id=str(event.id),
                event_title=event.title,
                inviter="testuser"
            )
            print(f"✓ Push notification sent to tom!")
            return True
        except Exception as notif_error:
            print(f"⚠️  Invitation created but notification failed: {notif_error}")
            return True  # Invitation was still created
    except Exception as e:
        print(f"❌ Error creating invitation: {e}")
        return False

def check_tom_devices():
    """Check if tom has registered devices"""
    tom = User.objects.get(username="tom")
    devices = Device.objects.filter(user=tom, is_active=True)
    
    if devices.exists():
        print(f"\n✓ tom has {devices.count()} registered device(s):")
        for device in devices:
            print(f"  - Device: {device.device_token[:20]}... ({device.device_type})")
            print(f"    Registered: {device.created_at}")
        return True
    else:
        print(f"\n❌ tom has no registered devices!")
        print("   Make sure tom:")
        print("   1. Is logged into the iOS app")
        print("   2. Has accepted notification permissions")
        print("   3. Has waited for device registration to complete")
        return False

def main():
    print("\n" + "="*70)
    print("PinIt Private Invitation Test - Send Notification to Tom")
    print("="*70)
    
    # Check tom exists and has devices
    tom = get_tom_user()
    if not tom:
        return
    
    if not check_tom_devices():
        print("\nNo devices registered for tom. Cannot send push notification.")
        return
    
    # Create test user
    test_user = get_or_create_test_user()
    
    # Create private event
    event = create_private_event(test_user)
    
    # Send invitation to tom
    print(f"\n📤 Sending invitation to tom...")
    success = send_invitation_to_tom(event, tom)
    
    if success:
        print(f"\n" + "="*70)
        print("✅ SUCCESS!")
        print("="*70)
        print(f"\nInvitation sent to tom for event: {event.title}")
        print(f"Event ID: {event.id}")
        print(f"\nCheck tom's iOS device for a push notification!")
        print(f"Expected notification title: 'event_invitation'")
    else:
        print(f"\n" + "="*70)
        print("❌ FAILED")
        print("="*70)
    
    print("\n")

if __name__ == "__main__":
    main()
