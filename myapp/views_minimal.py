"""
Minimal views.py for Railway deployment - removes push notifications and channels dependencies
"""
import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.db import transaction
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

# Import models
from .models import UserProfile, StudyEvent, EventInvitation, UserRating, UserReputationStats, UserTrustLevel

def health_check(request):
    """Simple health check endpoint that doesn't require database"""
    return JsonResponse({"status": "healthy", "message": "PinIt API is running - Railway deployment test"}, status=200)

@csrf_exempt
def register_user(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            username = data.get("username")
            password = data.get("password")
            
            if not username or not password:
                return JsonResponse({"success": False, "message": "Username and password are required"}, status=400)
            
            if User.objects.filter(username=username).exists():
                return JsonResponse({"success": False, "message": "Username already exists"}, status=400)
            
            user = User.objects.create_user(username=username, password=password)
            UserProfile.objects.create(user=user)
            
            return JsonResponse({"success": True, "message": "User created successfully", "user_id": user.id}, status=201)
            
        except Exception as e:
            return JsonResponse({"success": False, "message": str(e)}, status=500)
    
    return JsonResponse({"success": False, "message": "Method not allowed"}, status=405)

@csrf_exempt
def login_user(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            username = data.get("username")
            password = data.get("password")
            
            user = authenticate(username=username, password=password)
            if user:
                return JsonResponse({"success": True, "message": "Login successful", "user_id": user.id}, status=200)
            else:
                return JsonResponse({"success": False, "message": "Invalid credentials"}, status=401)
                
        except Exception as e:
            return JsonResponse({"success": False, "message": str(e)}, status=500)
    
    return JsonResponse({"success": False, "message": "Method not allowed"}, status=405)

@csrf_exempt
def get_all_users(request):
    if request.method == "GET":
        try:
            users = User.objects.all().values('id', 'username', 'date_joined')
            return JsonResponse({"success": True, "users": list(users)}, status=200)
        except Exception as e:
            return JsonResponse({"success": False, "message": str(e)}, status=500)
    
    return JsonResponse({"success": False, "message": "Method not allowed"}, status=405)

# Add other essential endpoints here as needed...
