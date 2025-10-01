import json
# from channels.generic.websocket import AsyncWebsocketConsumer  # Removed for Railway deployment
import re

def sanitize_username(username):
    """Sanitize username for WebSocket group names by removing special characters"""
    # Remove or replace special characters that cause WebSocket group name validation errors
    sanitized = re.sub(r'[^a-zA-Z0-9_-]', '_', username)
    return sanitized

# class ChatConsumer(AsyncWebsocketConsumer):  # Disabled for Railway deployment
    async def connect(self):
        self.sender = self.scope["url_route"]["kwargs"]["sender"]
        self.receiver = self.scope["url_route"]["kwargs"]["receiver"]
        self.room_name = f"private_chat_{self.sender}_{self.receiver}"
        
        # ✅ Join WebSocket group for private chat
        await self.channel_layer.group_add(self.room_name, self.channel_name)
        await self.accept()
        print(f"✅ WebSocket CONNECTED: {self.sender} chatting with {self.receiver}")

    async def disconnect(self, close_code):
        # ✅ Leave WebSocket group
        await self.channel_layer.group_discard(self.room_name, self.channel_name)
        print(f"❌ WebSocket DISCONNECTED: {self.sender} left chat with {self.receiver}")

    async def receive(self, text_data):
        data = json.loads(text_data)
        sender = data.get("sender")
        receiver = data.get("receiver")
        message = data.get("message")

        if sender and receiver and message:
            print(f"📩 Message Received from {sender} to {receiver}: {message}")

            # ✅ Send message to group (so only sender & receiver get it)
            await self.channel_layer.group_send(
                self.room_name,
                {
                    "type": "chat_message",
                    "sender": sender,
                    "message": message
                }
            )

    async def chat_message(self, event):
        sender = event["sender"]
        message = event["message"]

        # ✅ Send message to WebSocket clients
        await self.send(text_data=json.dumps({
            "sender": sender,
            "message": message
        }))

# myapp/consumers.py
import json
from channels.generic.websocket import AsyncWebsocketConsumer
import json
from channels.generic.websocket import AsyncWebsocketConsumer

class GroupChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        # The URL route supplies event_id in the path, e.g. ws://127.0.0.1:8000/ws/group_chat/<event_id>/
        self.event_id = self.scope["url_route"]["kwargs"]["event_id"]
        self.room_group_name = f"group_chat_{self.event_id}"
        
        # Join the group
        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()
        
        print(f"✅ CONNECTED to group chat: {self.room_group_name}")

    async def disconnect(self, close_code):
        # Leave the group
        await self.channel_layer.group_discard(self.room_group_name, self.channel_name)
        print(f"❌ DISCONNECTED from group chat: {self.room_group_name}")

    async def receive(self, text_data=None, bytes_data=None):
        # Handle both text and binary messages
        var_data = None
        if text_data is not None:
            var_data = json.loads(text_data)
        elif bytes_data is not None:
            var_data = json.loads(bytes_data.decode('utf-8'))
        if var_data is None:
            return

        sender = var_data.get("sender", "Unknown")
        message = var_data.get("message", "")

        # Broadcast the message to the group
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "groupchat.message",
                "sender": sender,
                "message": message,
            }
        )

    async def groupchat_message(self, event):
        sender = event["sender"]
        message = event["message"]

        # Send the message to WebSocket clients
        await self.send(text_data=json.dumps({
            "sender": sender,
            "message": message,
        }))

class EventsConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for real-time event updates.
    
    This consumer allows clients to subscribe to event changes 
    for a specific user. It will notify when events are created,
    updated, or deleted.
    """
    async def connect(self):
        # Get the username from the URL
        self.username = self.scope["url_route"]["kwargs"]["username"]
        # Sanitize username for WebSocket group name
        sanitized_username = sanitize_username(self.username)
        self.user_events_group = f"events_{sanitized_username}"
        
        # Join the events group for this user
        await self.channel_layer.group_add(self.user_events_group, self.channel_name)
        await self.accept()
        
        print(f"✅ WebSocket CONNECTED: User {self.username} subscribed to event updates")

    async def disconnect(self, close_code):
        # Leave the events group
        await self.channel_layer.group_discard(self.user_events_group, self.channel_name)
        print(f"❌ WebSocket DISCONNECTED: User {self.username} unsubscribed from event updates")

    async def receive(self, text_data=None, bytes_data=None):
        # We don't expect to receive messages from clients for event updates,
        # but we'll implement a basic handler just in case
        print(f"📩 Unexpected message received from client: {self.username}")
        pass

    # Handler for event_update message type
    async def event_update(self, event):
        event_id = event["event_id"]
        
        # Send the event update to the WebSocket client
        await self.send(text_data=json.dumps({
            "type": "update",
            "event_id": str(event_id)
        }))
        print(f"📤 Sent event UPDATE notification to {self.username} for event: {event_id}")

    # Handler for event_create message type
    async def event_create(self, event):
        event_id = event["event_id"]
        
        # Send the event creation to the WebSocket client
        await self.send(text_data=json.dumps({
            "type": "create",
            "event_id": str(event_id)
        }))
        print(f"📤 Sent event CREATE notification to {self.username} for event: {event_id}")

    # Handler for event_delete message type
    async def event_delete(self, event):
        event_id = event["event_id"]
        
        # Send the event deletion to the WebSocket client
        await self.send(text_data=json.dumps({
            "type": "delete",
            "event_id": str(event_id)
        }))
        print(f"📤 Sent event DELETE notification to {self.username} for event: {event_id}")