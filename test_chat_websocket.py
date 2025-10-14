#!/usr/bin/env python3
"""
Test script to verify WebSocket chat functionality between two users.
This script simulates two users connecting to the same chat room and sending messages.
"""

import asyncio
import websockets
import json
import sys
import os

# Add the project root to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Configuration
WEBSOCKET_BASE_URL = "wss://pinit-backend-production.up.railway.app"
USER1 = "testuser1"
USER2 = "testuser2"

async def test_chat_functionality():
    """Test chat functionality between two users"""
    print("🧪 Testing WebSocket Chat Functionality")
    print("=" * 50)
    
    # Create consistent room name (same as backend logic)
    participants = sorted([USER1, USER2])
    room_name = f"{participants[0]}/{participants[1]}"
    
    print(f"📱 Room name: {room_name}")
    print(f"👤 User 1: {USER1}")
    print(f"👤 User 2: {USER2}")
    print()
    
    # WebSocket URLs
    url1 = f"{WEBSOCKET_BASE_URL}/ws/chat/{USER1}/{USER2}/"
    url2 = f"{WEBSOCKET_BASE_URL}/ws/chat/{USER2}/{USER1}/"
    
    print(f"🔗 User 1 WebSocket URL: {url1}")
    print(f"🔗 User 2 WebSocket URL: {url2}")
    print()
    
    # Test messages
    messages_to_send = [
        {"sender": USER1, "receiver": USER2, "message": "Hello from User 1!"},
        {"sender": USER2, "receiver": USER1, "message": "Hi User 1, how are you?"},
        {"sender": USER1, "receiver": USER2, "message": "I'm doing great! Thanks for asking."},
        {"sender": USER2, "receiver": USER1, "message": "That's wonderful to hear!"},
    ]
    
    received_messages = []
    
    async def user1_handler(websocket, path):
        """Handle messages for User 1"""
        print(f"✅ User 1 connected to WebSocket")
        
        # Send first message
        await websocket.send(json.dumps(messages_to_send[0]))
        print(f"📤 User 1 sent: {messages_to_send[0]['message']}")
        
        # Wait for response and send another message
        await asyncio.sleep(1)
        await websocket.send(json.dumps(messages_to_send[2]))
        print(f"📤 User 1 sent: {messages_to_send[2]['message']}")
        
        # Listen for incoming messages
        try:
            while True:
                message = await websocket.recv()
                data = json.loads(message)
                received_messages.append(("user1", data))
                print(f"📥 User 1 received: {data['message']} (from {data['sender']})")
                
                # Close after receiving expected messages
                if len([m for m in received_messages if m[0] == "user1"]) >= 2:
                    break
                    
        except websockets.exceptions.ConnectionClosed:
            print("❌ User 1 WebSocket connection closed")
    
    async def user2_handler(websocket, path):
        """Handle messages for User 2"""
        print(f"✅ User 2 connected to WebSocket")
        
        # Wait a bit then send response
        await asyncio.sleep(0.5)
        await websocket.send(json.dumps(messages_to_send[1]))
        print(f"📤 User 2 sent: {messages_to_send[1]['message']}")
        
        # Wait and send another message
        await asyncio.sleep(1)
        await websocket.send(json.dumps(messages_to_send[3]))
        print(f"📤 User 2 sent: {messages_to_send[3]['message']}")
        
        # Listen for incoming messages
        try:
            while True:
                message = await websocket.recv()
                data = json.loads(message)
                received_messages.append(("user2", data))
                print(f"📥 User 2 received: {data['message']} (from {data['sender']})")
                
                # Close after receiving expected messages
                if len([m for m in received_messages if m[0] == "user2"]) >= 2:
                    break
                    
        except websockets.exceptions.ConnectionClosed:
            print("❌ User 2 WebSocket connection closed")
    
    # Start both WebSocket connections concurrently
    print("🚀 Starting WebSocket connections...")
    
    try:
        # Connect both users simultaneously
        async with websockets.connect(url1) as ws1, websockets.connect(url2) as ws2:
            print("✅ Both users connected successfully!")
            
            # Create tasks for both users
            task1 = asyncio.create_task(user1_handler(ws1, ""))
            task2 = asyncio.create_task(user2_handler(ws2, ""))
            
            # Wait for both tasks to complete
            await asyncio.gather(task1, task2)
            
    except Exception as e:
        print(f"❌ WebSocket connection failed: {e}")
        return False
    
    # Analyze results
    print("\n📊 Test Results:")
    print("=" * 30)
    
    user1_received = [m for m in received_messages if m[0] == "user1"]
    user2_received = [m for m in received_messages if m[0] == "user2"]
    
    print(f"📥 User 1 received {len(user1_received)} messages:")
    for _, data in user1_received:
        print(f"   - '{data['message']}' from {data['sender']}")
    
    print(f"📥 User 2 received {len(user2_received)} messages:")
    for _, data in user2_received:
        print(f"   - '{data['message']}' from {data['sender']}")
    
    # Check if both users received messages
    success = len(user1_received) >= 2 and len(user2_received) >= 2
    
    if success:
        print("\n✅ Chat functionality test PASSED!")
        print("   Both users successfully sent and received messages.")
    else:
        print("\n❌ Chat functionality test FAILED!")
        print("   One or both users did not receive expected messages.")
    
    return success

async def main():
    """Main test function"""
    print("🔧 WebSocket Chat Test")
    print("This script tests if messages can be sent between two users via WebSocket.")
    print()
    
    try:
        success = await test_chat_functionality()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n⏹️  Test interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n💥 Test failed with error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
