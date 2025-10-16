import json
from channels.generic.websocket import AsyncWebsocketConsumer
import re
from channels.db import database_sync_to_async

def sanitize_username(username):
    """Sanitize username for WebSocket group names by removing special characters"""
    # Remove or replace special characters that cause WebSocket group name validation errors
    sanitized = re.sub(r'[^a-zA-Z0-9_-]', '_', username)
    return sanitized

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.sender = self.scope["url_route"]["kwargs"]["sender"]
        self.receiver = self.scope["url_route"]["kwargs"]["receiver"]
        
        # ✅ SECURITY: Validate usernames to prevent injection attacks
        if not self.sender or not self.receiver:
            await self.close(code=4000)
            return
        
        # Validate username format (alphanumeric + underscore/hyphen only)
        import re
        username_pattern = re.compile(r'^[a-zA-Z0-9_-]+$')
        if not username_pattern.match(self.sender) or not username_pattern.match(self.receiver):
            await self.close(code=4000)
            return
        
        # ✅ SECURITY: Verify users exist and are authenticated
        if not await self.verify_users_exist():
            await self.close(code=4001)
            return
        
        # ✅ Create consistent room name regardless of sender/receiver order
        # Sort usernames to ensure both users join the same room
        participants = sorted([self.sender, self.receiver])
        self.room_name = f"private_chat_{participants[0]}_{participants[1]}"
        
        # ✅ Join WebSocket group for private chat
        await self.channel_layer.group_add(self.room_name, self.channel_name)
        await self.accept()
        print(f"✅ WebSocket CONNECTED: {self.sender} chatting with {self.receiver} in room {self.room_name}")

    @database_sync_to_async
    def verify_users_exist(self):
        """Verify that both users exist in the database"""
        try:
            from django.contrib.auth.models import User
            sender_exists = User.objects.filter(username=self.sender).exists()
            receiver_exists = User.objects.filter(username=self.receiver).exists()
            return sender_exists and receiver_exists
        except Exception as e:
            print(f"❌ Error verifying users: {e}")
            return False

    async def disconnect(self, close_code):
        # ✅ Leave WebSocket group
        await self.channel_layer.group_discard(self.room_name, self.channel_name)
        print(f"❌ WebSocket DISCONNECTED: {self.sender} left chat with {self.receiver}")

    @database_sync_to_async
    def save_message_to_db(self, sender_username, receiver_username, message_text):
        """Save chat message to database"""
        try:
            from django.contrib.auth.models import User
            from myapp.models import ChatMessage
            
            sender_user = User.objects.get(username=sender_username)
            receiver_user = User.objects.get(username=receiver_username)
            ChatMessage.objects.create(
                sender=sender_user,
                receiver=receiver_user,
                message=message_text
            )
            print(f"💾 Message saved to database: {sender_username} → {receiver_username}")
        except User.DoesNotExist as e:
            print(f"❌ User not found when saving message: {e}")
        except Exception as e:
            print(f"❌ Error saving message to database: {e}")

    async def receive(self, text_data):
        try:
            data = json.loads(text_data)
            sender = data.get("sender", "").strip()
            receiver = data.get("receiver", "").strip()
            message = data.get("message", "").strip()

            # ✅ SECURITY: Validate message data
            if not sender or not receiver or not message:
                print(f"❌ Invalid message data: sender={sender}, receiver={receiver}, message_length={len(message)}")
                # ✅ ERROR HANDLING: Send error back to client
                await self.send(text_data=json.dumps({
                    "type": "error",
                    "message": "Missing sender, receiver, or message"
                }))
                return
            
            # Validate sender matches the connection
            if sender != self.sender:
                print(f"❌ Message sender {sender} doesn't match connection sender {self.sender}")
                # ✅ ERROR HANDLING: Send error back to client
                await self.send(text_data=json.dumps({
                    "type": "error",
                    "message": "Message sender mismatch"
                }))
                return
            
            # Validate receiver matches the connection
            if receiver != self.receiver:
                print(f"❌ Message receiver {receiver} doesn't match connection receiver {self.receiver}")
                # ✅ ERROR HANDLING: Send error back to client
                await self.send(text_data=json.dumps({
                    "type": "error",
                    "message": "Message receiver mismatch"
                }))
                return
            
            # Validate message length (prevent spam)
            if len(message) > 1000:
                print(f"❌ Message too long: {len(message)} characters")
                # ✅ ERROR HANDLING: Send error back to client
                await self.send(text_data=json.dumps({
                    "type": "error",
                    "message": "Message too long (max 1000 characters)"
                }))
                return
            
            # Validate message content (basic sanitization)
            if not message or message.isspace():
                print(f"❌ Empty or whitespace-only message")
                # ✅ ERROR HANDLING: Send error back to client
                await self.send(text_data=json.dumps({
                    "type": "error",
                    "message": "Empty message"
                }))
                return

            print(f"📩 Message Received from {sender} to {receiver}: {message[:50]}...")

            # ✅ Save message to database
            await self.save_message_to_db(sender, receiver, message)

            # ✅ Send message to group (so only sender & receiver get it)
            await self.channel_layer.group_send(
                self.room_name,
                {
                    "type": "chat_message",
                    "sender": sender,
                    "message": message
                }
            )
            
        except json.JSONDecodeError:
            print(f"❌ Invalid JSON in WebSocket message")
            # Send error back to client
            await self.send(text_data=json.dumps({
                "type": "error",
                "message": "Invalid message format"
            }))
        except Exception as e:
            print(f"❌ Error processing WebSocket message: {e}")
            import traceback
            traceback.print_exc()
            # Send error back to client
            await self.send(text_data=json.dumps({
                "type": "error", 
                "message": "Message processing failed"
            }))

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
        try:
            # ✅ ERROR HANDLING: Handle both text and binary messages with proper validation
            var_data = None
            if text_data is not None:
                var_data = json.loads(text_data)
            elif bytes_data is not None:
                var_data = json.loads(bytes_data.decode('utf-8'))
            
            if var_data is None:
                await self.send(text_data=json.dumps({
                    "type": "error",
                    "message": "Invalid message format"
                }))
                return

            sender = var_data.get("sender", "").strip()
            message = var_data.get("message", "").strip()

            # ✅ VALIDATION: Validate message data
            if not sender or not message:
                await self.send(text_data=json.dumps({
                    "type": "error",
                    "message": "Missing sender or message"
                }))
                return
            
            if len(message) > 1000:
                await self.send(text_data=json.dumps({
                    "type": "error",
                    "message": "Message too long (max 1000 characters)"
                }))
                return
            
            if message.isspace():
                await self.send(text_data=json.dumps({
                    "type": "error",
                    "message": "Empty message"
                }))
                return

            # ✅ SECURITY: Sanitize sender name
            import re
            sender = re.sub(r'[^a-zA-Z0-9_-]', '_', sender)

            # Broadcast the message to the group
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    "type": "groupchat.message",
                    "sender": sender,
                    "message": message,
                }
            )
            
        except json.JSONDecodeError:
            await self.send(text_data=json.dumps({
                "type": "error",
                "message": "Invalid JSON format"
            }))
        except Exception as e:
            print(f"❌ Error processing group chat message: {e}")
            await self.send(text_data=json.dumps({
                "type": "error",
                "message": "Message processing failed"
            }))

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