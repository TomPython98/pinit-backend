#!/usr/bin/env python3
"""
Test script to check backend servers for data
"""

import requests
import json
import sys
from urllib.parse import urljoin

# Backend URLs to test
BACKEND_URLS = [
    "https://pinit-backend-production.up.railway.app/api",
    "https://pin-it.net/api", 
    "https://api.pin-it.net/api",
    "http://127.0.0.1:8000/api",
    "http://localhost:8000/api"
]

def test_backend(base_url):
    """Test a backend server for data"""
    print(f"\n🔍 Testing: {base_url}")
    print("=" * 60)
    
    # Test endpoints
    endpoints = [
        "get_all_users/",
        "get_study_events/ana_cruz/",
        "get_user_profile/ana_cruz/",
        "get_friends/ana_cruz/"
    ]
    
    results = {}
    
    for endpoint in endpoints:
        url = urljoin(base_url, endpoint)
        try:
            print(f"📡 Testing: {endpoint}")
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                try:
                    data = response.json()
                    if isinstance(data, list):
                        count = len(data)
                        print(f"✅ {endpoint}: {count} items")
                        results[endpoint] = count
                    elif isinstance(data, dict):
                        print(f"✅ {endpoint}: JSON object received")
                        results[endpoint] = "object"
                    else:
                        print(f"✅ {endpoint}: Response received")
                        results[endpoint] = "response"
                except json.JSONDecodeError:
                    print(f"⚠️  {endpoint}: Non-JSON response")
                    results[endpoint] = "non-json"
            else:
                print(f"❌ {endpoint}: HTTP {response.status_code}")
                results[endpoint] = f"error_{response.status_code}"
                
        except requests.exceptions.RequestException as e:
            print(f"❌ {endpoint}: Connection error - {str(e)}")
            results[endpoint] = "connection_error"
    
    return results

def main():
    print("🚀 PinIt Backend Data Checker")
    print("=" * 60)
    
    working_backends = []
    
    for base_url in BACKEND_URLS:
        try:
            results = test_backend(base_url)
            
            # Check if this backend has any working endpoints
            working_endpoints = [k for k, v in results.items() if isinstance(v, int) and v > 0]
            
            if working_endpoints:
                print(f"\n✅ {base_url} - WORKING with data!")
                print(f"   Working endpoints: {working_endpoints}")
                working_backends.append((base_url, results))
            else:
                print(f"\n⚠️  {base_url} - Responding but no data")
                
        except Exception as e:
            print(f"\n❌ {base_url} - Failed to test: {str(e)}")
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 SUMMARY")
    print("=" * 60)
    
    if working_backends:
        print(f"✅ Found {len(working_backends)} working backend(s) with data:")
        for base_url, results in working_backends:
            print(f"   🌐 {base_url}")
            for endpoint, count in results.items():
                if isinstance(count, int) and count > 0:
                    print(f"      - {endpoint}: {count} items")
    else:
        print("❌ No working backends found with data")
        print("\n💡 Next steps:")
        print("   1. Deploy backend to Railway")
        print("   2. Run data population script")
        print("   3. Update iOS app configuration")

if __name__ == "__main__":
    main()
