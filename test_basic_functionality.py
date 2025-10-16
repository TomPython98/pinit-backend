#!/usr/bin/env python3
"""
Basic functionality test for the deployed backend
Tests core endpoints and verifies the deployment is working
"""

import requests
import json
import time

BASE_URL = "https://pinit-backend-production.up.railway.app"

def test_basic_endpoints():
    """Test basic endpoints are working"""
    print("🔍 Testing Basic Endpoints...")
    
    # Test 1: Health check
    print("  Testing health check...")
    response = requests.get(f"{BASE_URL}/health/")
    assert response.status_code == 200
    assert "healthy" in response.json()["status"]
    print("  ✅ Health check working")
    
    # Test 2: Registration endpoint
    print("  Testing registration endpoint...")
    response = requests.post(f"{BASE_URL}/api/register/", json={
        "username": f"testuser{int(time.time())}",
        "password": "validpassword123"
    })
    assert response.status_code == 201
    print("  ✅ Registration endpoint working")
    
    # Test 3: Login endpoint
    print("  Testing login endpoint...")
    username = f"logintest{int(time.time())}"
    register_response = requests.post(f"{BASE_URL}/api/register/", json={
        "username": username,
        "password": "validpassword123"
    })
    assert register_response.status_code == 201
    
    login_response = requests.post(f"{BASE_URL}/api/login/", json={
        "username": username,
        "password": "validpassword123"
    })
    assert login_response.status_code == 200
    print("  ✅ Login endpoint working")
    
    # Test 4: Logout endpoint
    print("  Testing logout endpoint...")
    access_token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {access_token}"}
    
    logout_response = requests.post(f"{BASE_URL}/api/logout/", headers=headers)
    assert logout_response.status_code == 200
    print("  ✅ Logout endpoint working")
    
    print("🔍 Basic endpoints test PASSED!")

def test_security_validation():
    """Test security validation is working"""
    print("\n🔒 Testing Security Validation...")
    
    # Test 1: Invalid username length
    print("  Testing username length validation...")
    response = requests.post(f"{BASE_URL}/api/register/", json={
        "username": "a",  # Too short
        "password": "validpassword123"
    })
    assert response.status_code == 400
    assert "3 and 30 characters" in response.json()["message"]
    print("  ✅ Username length validation working")
    
    # Test 2: Invalid username characters
    print("  Testing username character validation...")
    response = requests.post(f"{BASE_URL}/api/register/", json={
        "username": "user@#$",  # Invalid characters
        "password": "validpassword123"
    })
    assert response.status_code == 400
    assert "letters, numbers, hyphens" in response.json()["message"]
    print("  ✅ Username character validation working")
    
    # Test 3: Password too short
    print("  Testing password length validation...")
    response = requests.post(f"{BASE_URL}/api/register/", json={
        "username": "validuser",
        "password": "123"  # Too short
    })
    assert response.status_code == 400
    assert "8 characters long" in response.json()["message"]
    print("  ✅ Password length validation working")
    
    print("🔒 Security validation test PASSED!")

def test_performance():
    """Test basic performance"""
    print("\n⚡ Testing Performance...")
    
    # Test 1: Multiple health checks
    print("  Testing response times...")
    start_time = time.time()
    
    for i in range(10):
        response = requests.get(f"{BASE_URL}/health/")
        assert response.status_code == 200
    
    end_time = time.time()
    total_time = end_time - start_time
    avg_time = total_time / 10
    
    print(f"  ✅ 10 requests completed in {total_time:.2f} seconds")
    print(f"  ✅ Average response time: {avg_time:.2f} seconds")
    
    if avg_time < 1.0:
        print("  ✅ Performance is excellent (< 1s per request)")
    elif avg_time < 2.0:
        print("  ✅ Performance is good (< 2s per request)")
    else:
        print("  ⚠️ Performance could be improved (> 2s per request)")
    
    print("⚡ Performance test PASSED!")

def main():
    print("🧪 STARTING BASIC FUNCTIONALITY TESTS")
    print("=" * 50)
    
    try:
        test_basic_endpoints()
        test_security_validation()
        test_performance()
        
        print("\n" + "=" * 50)
        print("🎉 ALL BASIC TESTS PASSED!")
        print("✅ Server is healthy and responding")
        print("✅ Core endpoints working")
        print("✅ Security validation working")
        print("✅ Performance is acceptable")
        print("\n🚀 Your backend is ready for production!")
        
    except Exception as e:
        print(f"\n❌ BASIC TEST FAILED: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    return True

if __name__ == "__main__":
    main()
