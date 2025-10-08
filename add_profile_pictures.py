#!/usr/bin/env python3
"""
Add profile pictures to test users
"""

import requests
import json
import base64
import io
from PIL import Image, ImageDraw, ImageFont
import random

# Backend URL
BASE_URL = "https://pinit-backend-production.up.railway.app/api"

# All test users
TEST_USERS = [
    {"username": "alex_student", "full_name": "Alex Johnson"},
    {"username": "sarah_med", "full_name": "Sarah Chen"},
    {"username": "mike_business", "full_name": "Mike Rodriguez"},
    {"username": "emma_arts", "full_name": "Emma Wilson"},
    {"username": "david_engineering", "full_name": "David Kim"},
    {"username": "anna_physics", "full_name": "Anna Schmidt"},
    {"username": "james_law", "full_name": "James Wilson"},
    {"username": "sophie_psychology", "full_name": "Sophie Martinez"},
    {"username": "carlos_medicine", "full_name": "Carlos Rodriguez"},
    {"username": "lisa_engineering", "full_name": "Lisa Chen"}
]

def generate_profile_picture(username, full_name):
    """Generate a simple profile picture with initials"""
    # Create a 200x200 image with a random background color
    colors = [
        (52, 152, 219),   # Blue
        (46, 204, 113),   # Green
        (155, 89, 182),   # Purple
        (241, 196, 15),   # Yellow
        (230, 126, 34),   # Orange
        (231, 76, 60),    # Red
        (26, 188, 156),   # Turquoise
        (142, 68, 173),   # Dark Purple
        (39, 174, 96),    # Dark Green
        (211, 84, 0),     # Dark Orange
    ]
    bg_color = random.choice(colors)
    
    img = Image.new('RGB', (200, 200), bg_color)
    draw = ImageDraw.Draw(img)
    
    # Get initials
    initials = ''.join([name[0].upper() for name in full_name.split()[:2]])
    
    # Try to use a font, fallback to default
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 60)
    except:
        font = ImageFont.load_default()
    
    # Draw initials in white
    bbox = draw.textbbox((0, 0), initials, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    x = (200 - text_width) // 2
    y = (200 - text_height) // 2
    
    draw.text((x, y), initials, fill='white', font=font)
    
    # Convert to base64
    buffer = io.BytesIO()
    img.save(buffer, format='PNG')
    img_str = base64.b64encode(buffer.getvalue()).decode()
    
    return img_str

def login_user(username, password):
    """Login user and get token"""
    url = f"{BASE_URL}/login/"
    data = {
        "username": username,
        "password": password
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            return response.json().get('access')
        else:
            print(f"❌ Failed to login {username}: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Error logging in {username}: {e}")
        return None

def upload_profile_picture(username, image_data):
    """Upload profile picture using form data"""
    url = f"{BASE_URL}/upload_user_image/"
    
    # Convert base64 to bytes
    image_bytes = base64.b64decode(image_data)
    
    # Create a file-like object
    image_file = io.BytesIO(image_bytes)
    
    # Prepare form data
    files = {
        'image': ('profile.jpg', image_file, 'image/jpeg')
    }
    
    data = {
        'username': username,
        'image_type': 'profile',
        'is_primary': 'true',
        'caption': ''
    }
    
    try:
        response = requests.post(url, files=files, data=data)
        if response.status_code == 200:
            print(f"✅ Uploaded profile picture for: {username}")
            return True
        else:
            print(f"❌ Failed to upload picture for {username}: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error uploading picture for {username}: {e}")
        return False

def main():
    print("🚀 Adding profile pictures to test users...")
    
    success_count = 0
    
    for user_data in TEST_USERS:
        username = user_data["username"]
        full_name = user_data["full_name"]
        
        print(f"\n📸 Processing {username} ({full_name})...")
        
        # Generate profile picture
        image_data = generate_profile_picture(username, full_name)
        
        # Upload profile picture (no authentication needed)
        if upload_profile_picture(username, image_data):
            success_count += 1
    
    print(f"\n✅ Successfully added profile pictures to {success_count}/{len(TEST_USERS)} users")
    
    if success_count > 0:
        print("\n🎯 Test users now have profile pictures!")
        print("   - Each user has a unique colored background with their initials")
        print("   - You can now test image loading and display in the app")
    else:
        print("\n❌ No profile pictures were uploaded successfully")

if __name__ == "__main__":
    main()
