"""
Utility functions for the myapp Django application.
"""
import json
import asyncio
# from channels.layers import get_channel_layer  # Removed for Railway deployment
# from asgiref.sync import async_to_sync  # Removed for Railway deployment

def broadcast_event_update(event_id, event_type, usernames):
    """
    Broadcast an event update to all connected WebSocket clients
    who are subscribed to this event.
    
    Args:
        event_id (str): The UUID of the event
        event_type (str): Type of update: 'create', 'update', or 'delete'
        usernames (list): List of usernames to notify
    """
    # Function disabled for Railway deployment - channels removed
    pass

def broadcast_event_created(event_id, host_username, invited_friends=[]):
    """Notify the host and any invited friends that a new event was created"""
    # Create list of users to notify: host + invited friends
    users_to_notify = [host_username] + invited_friends
    broadcast_event_update(event_id, 'create', users_to_notify)

def broadcast_event_updated(event_id, host_username, attendees=[], invited_friends=[]):
    """Notify the host, attendees, and invited friends that an event was updated"""
    # Create list of users to notify: host + attendees + invited friends
    users_to_notify = [host_username] + attendees + invited_friends
    broadcast_event_update(event_id, 'update', users_to_notify)

def broadcast_event_deleted(event_id, host_username, attendees=[], invited_friends=[]):
    """Notify the host, attendees, and invited friends that an event was deleted"""
    # Create list of users to notify: host + attendees + invited friends
    users_to_notify = [host_username] + attendees + invited_friends
    broadcast_event_update(event_id, 'delete', users_to_notify) 