"""
Utility functions for the myapp Django application.
"""
import json
import asyncio
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
import re

def _sanitize_group_name(name: str) -> str:
    """Sanitize string for Channels group names (alnum, dash, underscore)."""
    return re.sub(r'[^a-zA-Z0-9_-]', '_', name or '')

def broadcast_event_update(event_id, event_type, usernames):
    """
    Broadcast an event update to all connected WebSocket clients
    who are subscribed to this event.
    
    Args:
        event_id (str): The UUID of the event
        event_type (str): Type of update: 'create', 'update', or 'delete'
        usernames (list): List of usernames to notify
    """
    # Get the channel layer
    channel_layer = get_channel_layer()
    
    # Make sure we have usernames to notify
    if not usernames:
        return
    
    # Map event_type to consumer handler method
    handler_map = {
        'create': 'event_create',
        'update': 'event_update',
        'delete': 'event_delete'
    }
    
    # Default to update if event_type is not recognized
    handler = handler_map.get(event_type, 'event_update')
    
    # Notify each user of the event change
    for username in usernames:
        group_name = f"events_{_sanitize_group_name(username)}"
        print(f"📢 Broadcasting {event_type} for event {event_id} to user: {username}")
        
        # Send the message to the group
        async_to_sync(channel_layer.group_send)(
            group_name,
            {
                "type": handler,
                "event_id": str(event_id)
            }
        )

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