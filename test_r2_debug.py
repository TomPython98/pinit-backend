#!/usr/bin/env python3
"""
Debug R2 Configuration
"""
import requests
import json

def test_r2_debug():
    """Test R2 configuration and debug issues"""
    
    print("🔍 Debugging R2 Configuration")
    print("=" * 50)
    
    # Test 1: Check if the server is running
    print("1. Testing server connection...")
    try:
        response = requests.get("https://pinit-backend-production.up.railway.app/health/", timeout=10)
        if response.status_code == 200:
            print("✅ Server is running")
        else:
            print(f"❌ Server returned status {response.status_code}")
    except Exception as e:
        print(f"❌ Server connection failed: {e}")
        return
    
    # Test 2: Check current image data
    print("\n2. Checking current image data...")
    try:
        response = requests.get("https://pinit-backend-production.up.railway.app/api/user_images/tom/", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print("✅ API is working")
            print(f"Images found: {data.get('count', 0)}")
            
            if data.get('images'):
                image = data['images'][0]
                print(f"Image URL: {image.get('url')}")
                print(f"Has width: {'width' in image}")
                print(f"Has height: {'height' in image}")
                print(f"Has public_url: {'public_url' in image}")
                print(f"Has storage_key: {'storage_key' in image}")
                
                # Check if it's an R2 URL
                url = image.get('url', '')
                if url.startswith('https://da76c95301856b7cd9fee0a8f758097a.r2.cloudflarestorage.com'):
                    print("✅ Image is stored in R2!")
                elif url.startswith('/media/'):
                    print("❌ Image is stored locally (not R2)")
                else:
                    print(f"❓ Unknown URL format: {url}")
            else:
                print("❌ No images found")
        else:
            print(f"❌ API returned status {response.status_code}")
    except Exception as e:
        print(f"❌ API test failed: {e}")
    
    # Test 3: Test R2 bucket access
    print("\n3. Testing R2 bucket access...")
    try:
        # Test if we can access the bucket
        r2_url = "https://da76c95301856b7cd9fee0a8f758097a.r2.cloudflarestorage.com/pinit-images/"
        response = requests.head(r2_url, timeout=10)
        print(f"R2 bucket response: {response.status_code}")
        if response.status_code == 200:
            print("✅ R2 bucket is accessible")
        elif response.status_code == 400:
            print("❌ R2 bucket returned 400 - might need authentication")
        else:
            print(f"❓ R2 bucket returned {response.status_code}")
    except Exception as e:
        print(f"❌ R2 bucket test failed: {e}")
    
    print("\n" + "=" * 50)
    print("🔧 Debug Summary:")
    print("- Check if migration was applied (new fields in API response)")
    print("- Check if R2 storage is actually being used")
    print("- Check server logs for R2 configuration messages")

if __name__ == "__main__":
    test_r2_debug()
