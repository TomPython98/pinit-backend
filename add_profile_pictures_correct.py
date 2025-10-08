#!/usr/bin/env python3
"""
Add profile pictures to the correct test users
"""

import requests
import json
import random
from datetime import datetime, timedelta
import time
import uuid
from PIL import Image, ImageDraw, ImageFont
import io
import base64

# Backend URL
BASE_URL = "https://pinit-backend-production.up.railway.app"

# Correct usernames from our data generation
TEST_USERS = [
    {"username": "alex_cs_stanford", "full_name": "Alex Chen"},
    {"username": "sarah_med_harvard", "full_name": "Sarah Johnson"},
    {"username": "mike_business_wharton", "full_name": "Mike Rodriguez"},
    {"username": "emma_arts_nyu", "full_name": "Emma Williams"},
    {"username": "david_eng_mit", "full_name": "David Kim"},
    {"username": "anna_physics_mit", "full_name": "Anna Schmidt"},
    {"username": "james_law_yale", "full_name": "James Thompson"},
    {"username": "sophie_psych_stanford", "full_name": "Sophie Davis"},
    {"username": "carlos_med_johns_hopkins", "full_name": "Carlos Martinez"},
    {"username": "lisa_eng_caltech", "full_name": "Lisa Wang"},
    {"username": "maya_comp_sci_berkeley", "full_name": "Maya Patel"},
    {"username": "ryan_business_harvard", "full_name": "Ryan O'Connor"},
    {"username": "zoe_arts_risd", "full_name": "Zoe Anderson"},
    {"username": "kevin_eng_georgia_tech", "full_name": "Kevin Lee"},
    {"username": "priya_med_ucsf", "full_name": "Priya Sharma"},
    {"username": "tom_physics_princeton", "full_name": "Tom Wilson"},
    {"username": "martina_psych_ucla", "full_name": "Martina Garcia"}
]

def generate_profile_picture(username, full_name):
    """Generate a profile picture with user initials"""
    # Create a 200x200 image
    size = (200, 200)
    image = Image.new('RGB', size, color='white')
    draw = ImageDraw.Draw(image)
    
    # Generate a consistent color based on username
    random.seed(hash(username))
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
        (41, 128, 185)    # Dark Blue
    ]
    bg_color = random.choice(colors)
    
    # Fill background with gradient effect
    for y in range(size[1]):
        color_intensity = int(bg_color[0] * (1 - y / size[1] * 0.3))
        draw.rectangle([(0, y), (size[0], y + 1)], fill=(color_intensity, bg_color[1], bg_color[2]))
    
    # Get initials
    initials = ''.join([name[0].upper() for name in full_name.split()[:2]])
    
    # Try to use a default font, fallback to basic if not available
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 60)
    except:
        try:
            font = ImageFont.load_default()
        except:
            font = None
    
    # Draw initials
    if font:
        # Get text bounding box
        bbox = draw.textbbox((0, 0), initials, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        
        # Center the text
        x = (size[0] - text_width) // 2
        y = (size[1] - text_height) // 2
        
        # Draw white text with shadow
        draw.text((x + 2, y + 2), initials, fill=(0, 0, 0, 128), font=font)  # Shadow
        draw.text((x, y), initials, fill='white', font=font)  # Main text
    else:
        # Fallback: draw simple text
        draw.text((size[0]//2 - 20, size[1]//2 - 20), initials, fill='white')
    
    # Convert to base64
    buffer = io.BytesIO()
    image.save(buffer, format='JPEG', quality=85)
    image_data = buffer.getvalue()
    return base64.b64encode(image_data).decode()

def upload_profile_picture(username, image_data):
    """Upload profile picture using form data"""
    url = f"{BASE_URL}/api/upload_user_image/"
    
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
            result = response.json()
            if result.get("success"):
                print(f"✅ Uploaded profile picture for: {username}")
                return True
            else:
                print(f"❌ Failed to upload picture for {username}: {result.get('message', 'Unknown error')}")
                return False
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
        
        # Upload profile picture
        if upload_profile_picture(username, image_data):
            success_count += 1
        
        time.sleep(0.5)  # Rate limiting
    
    print(f"\n✅ Successfully added profile pictures to {success_count}/{len(TEST_USERS)} users")
    
    if success_count > 0:
        print("\n🎯 Test users now have profile pictures!")
        print("   - Each user has a unique colored background with their initials")
        print("   - You can now test image loading and display in the app")

if __name__ == "__main__":
    main()
