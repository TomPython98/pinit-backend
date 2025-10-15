#!/usr/bin/env python3
"""
Test Push Notifications Script

This script helps you test push notifications for PinIt.
Run this script to verify that push notifications are working correctly.

Usage:
    python test_push_notifications.py

Requirements:
    - Django environment configured
    - User must be logged in on the iOS app
    - Device must be registered
"""

import os
import django
import sys

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from django.contrib.auth.models import User
from myapp.models import Device
from myapp.views import send_push_notification
from push_notifications.models import APNSDevice


def test_device_registration():
    """Test 1: Check if devices are registered"""
    print("\n" + "="*60)
    print("TEST 1: Device Registration Check")
    print("="*60)
    
    total_devices = Device.objects.filter(is_active=True).count()
    ios_devices = Device.objects.filter(is_active=True, device_type='ios').count()
    android_devices = Device.objects.filter(is_active=True, device_type='android').count()
    
    print(f"✓ Total active devices: {total_devices}")
    print(f"  - iOS devices: {ios_devices}")
    print(f"  - Android devices: {android_devices}")
    
    if total_devices == 0:
        print("\n❌ WARNING: No devices registered!")
        print("   Make sure you:")
        print("   1. Log into the iOS app")
        print("   2. Accept notification permissions")
        print("   3. Wait for device registration")
        return False
    
    # Check APNSDevice registration
    apns_devices = APNSDevice.objects.filter(active=True).count()
    print(f"✓ APNs devices registered: {apns_devices}")
    
    if ios_devices > 0 and apns_devices == 0:
        print("\n⚠️  WARNING: iOS devices registered but no APNs devices found")
        print("   This might cause issues with push notifications")
    
    return True


def test_apns_configuration():
    """Test 2: Check APNs configuration"""
    print("\n" + "="*60)
    print("TEST 2: APNs Configuration Check")
    print("="*60)
    
    from django.conf import settings
    
    config = settings.PUSH_NOTIFICATIONS_SETTINGS
    
    # Check for modern token-based auth
    auth_key_path = config.get('APNS_AUTH_KEY_PATH', '')
    auth_key_id = config.get('APNS_AUTH_KEY_ID', '')
    team_id = config.get('APNS_TEAM_ID', '')
    topic = config.get('APNS_TOPIC', '')
    use_sandbox = config.get('APNS_USE_SANDBOX', True)
    
    print(f"APNS_AUTH_KEY_PATH: {'✓ Set' if auth_key_path else '❌ Not set'}")
    print(f"APNS_AUTH_KEY_ID: {'✓ Set' if auth_key_id else '❌ Not set'}")
    print(f"APNS_TEAM_ID: {'✓ Set' if team_id else '❌ Not set'}")
    print(f"APNS_TOPIC: {topic if topic else '❌ Not set'}")
    print(f"APNS_USE_SANDBOX: {use_sandbox}")
    
    if not auth_key_path and not config.get('APNS_CERTIFICATE', ''):
        print("\n❌ ERROR: No APNs authentication configured!")
        print("   You need to set either:")
        print("   - Token-based: APNS_AUTH_KEY_PATH, APNS_AUTH_KEY_ID, APNS_TEAM_ID")
        print("   - Certificate-based: APNS_CERTIFICATE")
        print("\n   See PUSH_NOTIFICATION_SETUP_GUIDE.md for details")
        return False
    
    return True


def test_send_notification(username=None):
    """Test 3: Send a test notification"""
    print("\n" + "="*60)
    print("TEST 3: Send Test Notification")
    print("="*60)
    
    if username:
        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            print(f"❌ User '{username}' not found")
            return False
    else:
        # Get first user with a registered device
        devices = Device.objects.filter(is_active=True).select_related('user')
        if not devices.exists():
            print("❌ No devices registered")
            return False
        user = devices.first().user
    
    print(f"Sending test notification to: {user.username}")
    
    try:
        send_push_notification(
            user_id=user.id,
            notification_type='event_invitation',
            event_title='Test Event from Script',
            from_user='Test System',
            event_id='test-12345'
        )
        print("✓ Test notification sent successfully!")
        print("\n  Check your iOS device for the notification.")
        print("  If you don't see it:")
        print("  1. Check that notifications are enabled for PinIt")
        print("  2. Verify APNS_USE_SANDBOX matches your build type")
        print("  3. Check the Django server logs for errors")
        return True
    except Exception as e:
        print(f"❌ Error sending notification: {e}")
        import traceback
        traceback.print_exc()
        return False


def list_users_with_devices():
    """List all users with registered devices"""
    print("\n" + "="*60)
    print("Users with Registered Devices")
    print("="*60)
    
    devices = Device.objects.filter(is_active=True).select_related('user')
    
    if not devices.exists():
        print("No users with registered devices found")
        return
    
    users_seen = set()
    for device in devices:
        if device.user.username not in users_seen:
            users_seen.add(device.user.username)
            device_count = Device.objects.filter(user=device.user, is_active=True).count()
            print(f"  • {device.user.username} ({device_count} device(s))")


def main():
    """Main test runner"""
    print("\n" + "="*60)
    print("PinIt Push Notification Test Suite")
    print("="*60)
    
    # Run tests
    test1_passed = test_device_registration()
    test2_passed = test_apns_configuration()
    
    if not test1_passed or not test2_passed:
        print("\n" + "="*60)
        print("⚠️  Tests failed. Fix the issues above before continuing.")
        print("="*60)
        return
    
    # List users
    list_users_with_devices()
    
    # Ask if user wants to send test notification
    print("\n" + "="*60)
    response = input("\nDo you want to send a test notification? (y/n): ")
    
    if response.lower() in ['y', 'yes']:
        username = input("Enter username (or press Enter for first available user): ").strip()
        test_send_notification(username if username else None)
    
    print("\n" + "="*60)
    print("Test suite completed!")
    print("="*60)
    print("\nFor more information, see:")
    print("  - PUSH_NOTIFICATION_SETUP_GUIDE.md")
    print("  - Django admin: http://your-server/admin/")
    print("\n")


if __name__ == "__main__":
    main()

