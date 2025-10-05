from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.http import JsonResponse, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.db import transaction
import json
from .models import FriendRequest, UserProfile, StudyEvent, EventInvitation, DeclinedInvitation, Device, UserRating, UserReputationStats, UserTrustLevel
from django.utils import timezone
from myapp.utils import broadcast_event_created, broadcast_event_updated, broadcast_event_deleted
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from push_notifications.models import APNSDevice



@csrf_exempt
def register_user(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            username = data.get("username")
            password = data.get("password")

            # ✅ Ensure we no longer check for email
            if not username or not password:
                return JsonResponse({"success": False, "message": "Username and Password required."}, status=400)

            if User.objects.filter(username=username).exists():
                return JsonResponse({"success": False, "message": "Username already exists."}, status=400)

            # ✅ Create user without email
            user = User.objects.create_user(username=username, password=password)
            return JsonResponse({"success": True, "message": "User registered successfully."}, status=201)

        except json.JSONDecodeError:
            return JsonResponse({"success": False, "message": "Invalid JSON data."}, status=400)

    return JsonResponse({"success": False, "message": "Invalid request method."}, status=405)

# ✅ Login User
@csrf_exempt  # Remove in production
def login_user(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            username = data.get("username")
            password = data.get("password")

            if not username or not password:
                return JsonResponse({"success": False, "message": "Username and password are required."}, status=400)

            user = authenticate(username=username, password=password)

            if user is not None:
                return JsonResponse({"success": True, "message": "Login successful."}, status=200)
            else:
                return JsonResponse({"success": False, "message": "Invalid credentials."}, status=401)

        except json.JSONDecodeError:
            return JsonResponse({"success": False, "message": "Invalid JSON data."}, status=400)

    return JsonResponse({"success": False, "message": "Invalid request method."}, status=405)

# ✅ Change Password
@csrf_exempt  # Remove in production
def change_password(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            username = data.get("username")
            current_password = data.get("current_password")
            new_password = data.get("new_password")

            if not username or not current_password or not new_password:
                return JsonResponse({"success": False, "message": "Username, current password, and new password are required."}, status=400)

            # Validate new password length
            if len(new_password) < 6:
                return JsonResponse({"success": False, "message": "New password must be at least 6 characters long."}, status=400)

            # Authenticate user with current password
            user = authenticate(username=username, password=current_password)
            if user is None:
                return JsonResponse({"success": False, "message": "Invalid current password."}, status=401)

            # Change the password
            user.set_password(new_password)
            user.save()

            return JsonResponse({"success": True, "message": "Password changed successfully."}, status=200)

        except User.DoesNotExist:
            return JsonResponse({"success": False, "message": "User not found."}, status=404)
        except json.JSONDecodeError:
            return JsonResponse({"success": False, "message": "Invalid JSON data."}, status=400)

    return JsonResponse({"success": False, "message": "Invalid request method."}, status=405)


# ✅ Send Friend Request
@csrf_exempt  # Remove in production
def send_friend_request(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            from_username = data.get("from_user")
            to_username = data.get("to_user")

            if not from_username or not to_username:
                return JsonResponse({"success": False, "message": "Both usernames required"}, status=400)

            from_user = User.objects.get(username=from_username)
            to_user = User.objects.get(username=to_username)

            if from_user == to_user:
                return JsonResponse({"success": False, "message": "Cannot send request to yourself"}, status=400)

            if FriendRequest.objects.filter(from_user=from_user, to_user=to_user).exists():
                return JsonResponse({"success": False, "message": "Friend request already sent"}, status=400)

            FriendRequest.objects.create(from_user=from_user, to_user=to_user)
            return JsonResponse({"success": True, "message": "Friend request sent successfully"}, status=201)

        except User.DoesNotExist:
            return JsonResponse({"success": False, "message": "User not found"}, status=404)
        except json.JSONDecodeError:
            return JsonResponse({"success": False, "message": "Invalid JSON format"}, status=400)

    return JsonResponse({"success": False, "message": "Invalid request method."}, status=405)

@csrf_exempt
def logout_user(request):
    if request.method == "POST":
        return JsonResponse({"success": True, "message": "Logout successful."}, status=200)

    return JsonResponse({"success": False, "message": "Invalid request method."}, status=405)


from django.contrib.auth.models import User


def health_check(request):
    """Simple health check endpoint that doesn't require database"""
    return JsonResponse({"status": "healthy", "message": "PinIt API is running - Railway deployment test"}, status=200)


@csrf_exempt
def get_all_users(request):
    if request.method == "GET":
        users = list(User.objects.values_list("username", flat=True))  # Get all usernames
        return JsonResponse(users, safe=False)
    
    return JsonResponse({"error": "Invalid request method"}, status=405)

from django.http import JsonResponse
from .models import FriendRequest



from django.http import JsonResponse
from django.contrib.auth.models import User
from .models import UserProfile

from django.http import JsonResponse
from django.shortcuts import get_object_or_404
from django.contrib.auth.models import User

from django.http import JsonResponse
from django.contrib.auth.models import User
from django.shortcuts import get_object_or_404
from myapp.models import UserProfile

from django.http import JsonResponse
from django.contrib.auth.models import User

from django.http import JsonResponse
from django.contrib.auth.models import User

def get_friends(request, username):
    try:
        # Log the request
        
        # Get the user
        user = User.objects.get(username=username)
        
        # Get the user's friends
        friends = list(user.userprofile.friends.values_list("user__username", flat=True))
        
        # Log the found friends
        
        return JsonResponse({"friends": friends})
    except User.DoesNotExist:
        return JsonResponse({"friends": []})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)
        
from django.http import JsonResponse
from django.contrib.auth.models import User
from myapp.models import FriendRequest

def get_pending_requests(request, username):
    try:
        user = User.objects.get(username=username)

        # ✅ Filter only requests that are **still pending**
        pending_requests = FriendRequest.objects.filter(to_user=user).values_list("from_user__username", flat=True)
        return JsonResponse({"pending_requests": list(pending_requests)})
    except User.DoesNotExist:
        return JsonResponse({"error": "User not found."}, status=404)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

# ✅ Fetch Sent Friend Requests (Requests you have sent)
from django.http import JsonResponse
from django.contrib.auth.models import User
from myapp.models import FriendRequest

def get_sent_requests(request, username):
    try:
        print(f"📩 Fetching sent friend requests for: {username}")  # ✅ Debugging Line
        user = User.objects.get(username=username)
        sent_requests = FriendRequest.objects.filter(from_user=user).values_list("to_user__username", flat=True)
        
        print(f"✅ Sent Friend Requests Found: {list(sent_requests)}")  # ✅ Debugging Line
        
        return JsonResponse({"sent_requests": list(sent_requests)})
    except User.DoesNotExist:
        print(f"❌ Error: User {username} not found.")  # ✅ Debugging Line
        return JsonResponse({"error": "User not found."}, status=404)
    except Exception as e:
        print(f"❌ Server Error: {str(e)}")  # ✅ Debugging Line
        return JsonResponse({"error": str(e)}, status=500)

import json
from django.http import JsonResponse
from django.contrib.auth.models import User
from django.views.decorators.csrf import csrf_exempt
from myapp.models import FriendRequest, UserProfile

import json
from django.http import JsonResponse
from django.contrib.auth.models import User
from django.views.decorators.csrf import csrf_exempt
from myapp.models import FriendRequest, UserProfile

@csrf_exempt
def accept_friend_request(request):
    """
    🔧 IMPROVED: Better error handling and reliability
    """
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            from_username = data.get("from_user")
            to_username = data.get("to_user")


            # Validate input
            if not from_username or not to_username:
                return JsonResponse({"success": False, "message": "Both usernames are required"}, status=400)

            # Get users
            try:
                from_user = User.objects.get(username=from_username)
                to_user = User.objects.get(username=to_username)
            except User.DoesNotExist as e:
                return JsonResponse({"success": False, "message": "User not found"}, status=404)

            # Check if friend request exists
            try:
                friend_request = FriendRequest.objects.get(from_user=from_user, to_user=to_user)
            except FriendRequest.DoesNotExist:
                return JsonResponse({"success": False, "message": "Friend request not found"}, status=404)

            # Create or get user profiles
            from_profile, created = UserProfile.objects.get_or_create(user=from_user)
            to_profile, created = UserProfile.objects.get_or_create(user=to_user)

            # Add each other as friends (bidirectional)
            from_profile.friends.add(to_profile)
            to_profile.friends.add(from_profile)

            # Delete the friend request
            friend_request.delete()


            return JsonResponse({
                "success": True, 
                "message": f"{from_username} and {to_username} are now friends!"
            }, status=200)

        except json.JSONDecodeError:
            return JsonResponse({"success": False, "message": "Invalid JSON format"}, status=400)
        except Exception as e:
            return JsonResponse({"success": False, "message": f"Server error: {str(e)}"}, status=500)

    return JsonResponse({"success": False, "message": "Invalid request method"}, status=405)



def chat_room(request, room_name):
    return render(request, "chat/chat.html", {"room_name": room_name})


from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.models import User
from .models import StudyEvent
import json
from datetime import datetime

import json
from datetime import datetime
from django.http import JsonResponse
from django.contrib.auth.models import User
from .models import StudyEvent

@csrf_exempt
def create_study_event(request):
    """Modified to include intelligent auto-matching in the same transaction"""
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            host = get_object_or_404(User, username=data.get("host"))

            # Extract fields for auto-matching
            interest_tags = data.get("interest_tags", [])
            max_participants = data.get("max_participants", 10)
            auto_matching_enabled = data.get("auto_matching_enabled", False)
            
            # Create the event
            event = StudyEvent.objects.create(
                title=data.get("title") or "Untitled Event",  # Ensure title is never None
                description=data.get("description", ""),
                host=host,
                latitude=data.get("latitude"),
                longitude=data.get("longitude"),
                time=datetime.fromisoformat(data.get("time")),
                end_time=datetime.fromisoformat(data.get("end_time")),
                is_public=data.get("is_public", True) if not auto_matching_enabled else True,
                event_type=data.get("event_type", "other"),
                max_participants=max_participants,
                auto_matching_enabled=auto_matching_enabled,
            )
            
            # Set interest tags
            if hasattr(event, 'set_interest_tags'):
                event.set_interest_tags(interest_tags)
            
            # IMPORTANT: Add the host to attendees automatically
            event.attendees.add(host)
            
            # Add invited friends
            invited_friends = data.get("invited_friends", [])
            for friend in invited_friends:
                friend_user = User.objects.get(username=friend)
                # Add to M2M field
                event.invited_friends.add(friend_user)
                # Create direct invitation record
                EventInvitation.objects.create(
                    event=event,
                    user=friend_user,
                    is_auto_matched=False
                )

            event.save()
            
            # IMPORTANT: Log the created event ID for verification
            
            # Broadcast event creation to WebSocket clients
            broadcast_event_created(
                event_id=event.id,
                host_username=host.username,
                invited_friends=invited_friends
            )
            
            # If auto-matching is enabled, do it now in the same transaction
            matched_users = []
            invites_sent = 0
            
            if auto_matching_enabled:
                try:
                    # Use the enhanced auto-matching algorithm for better results
                    # Define scoring weights for different factors
                    WEIGHTS = {
                        'interest_match': 25.0,        # Points per matching interest (increased from 10.0)
                        'interest_ratio': 30.0,        # Max points for high interest match ratio (increased from 15.0)
                        'content_similarity': 20.0,    # Max points for content similarity (increased from 10.0)
                        'location': 15.0,              # Max points for location proximity (increased from 5.0)
                        'social': 20.0,                # Max points for social relevance (increased from 10.0)
                        'academic_similarity': 25.0,   # NEW: University, degree, year matching
                        'skill_relevance': 20.0,       # NEW: Skill matching for relevant events
                        'bio_similarity': 15.0,        # NEW: Bio content similarity
                        'reputation_boost': 15.0,      # NEW: User reputation/trust level
                        'event_type_preference': 10.0, # NEW: Event type preferences
                        'time_compatibility': 10.0,    # NEW: Time pattern compatibility
                        'activity_level': 10.0,        # NEW: User activity level
                    }
                    
                    # Event details needed for matching
                    event_title = event.title
                    event_description = event.description or ""
                    event_content = f"{event_title} {event_description}"
                    event_lat = event.latitude
                    event_lon = event.longitude
                    event_type = event.event_type
                    event_time = event.time
                    
                    # Get the host's friends for social relevance matching
                    host_friends = set(host.userprofile.friends.values_list('user_id', flat=True))
                    
                    # Get potential matches (exclude host and already invited friends)
                    potential_users = User.objects.filter(
                        userprofile__auto_invite_enabled=True
                    ).exclude(
                        id=host.id
                    ).exclude(
                        id__in=[u.id for u in event.invited_friends.all()]
                    ).select_related(
                        'userprofile'
                    ).prefetch_related(
                        'userprofile__friends'
                    )
                    
                    # Calculate match scores in batches (100 users at a time)
                    batch_size = 100
                    matched_profiles = []
                    
                    for i in range(0, potential_users.count(), batch_size):
                        batch = potential_users[i:i+batch_size]
                        
                        for user in batch:
                            profile = user.userprofile
                            
                            # Initialize score components
                            score_components = {
                                'interest_match': 0,
                                'interest_ratio': 0,
                                'content_similarity': 0,
                                'location': 0,
                                'social': 0,
                                'academic_similarity': 0,
                                'skill_relevance': 0,
                                'bio_similarity': 0,
                                'reputation_boost': 0,
                                'event_type_preference': 0,
                                'time_compatibility': 0,
                                'activity_level': 0
                            }
                            
                            # Get user interests
                            user_interests = profile.get_interests()
                            
                            # Skip users with no interests if the event has interest tags
                            if not user_interests and interest_tags:
                                continue
                            
                            # 1. INTEREST MATCHING (Enhanced)
                            # Calculate both raw count and ratio of match
                            matching_interests = set(user_interests).intersection(set(interest_tags))
                            
                            if interest_tags:
                                interest_match_count = len(matching_interests)
                                interest_match_ratio = interest_match_count / len(interest_tags)
                                
                                score_components['interest_match'] = interest_match_count * WEIGHTS['interest_match']
                                score_components['interest_ratio'] = interest_match_ratio * WEIGHTS['interest_ratio']
                            
                            # 2. CONTENT SIMILARITY - semantic matching between descriptions and interests
                            user_content = " ".join(user_interests)
                            
                            if event_content and user_content:
                                content_similarity_score = text_similarity(event_content, user_content)
                                score_components['content_similarity'] = content_similarity_score * WEIGHTS['content_similarity']
                            
                            # 3. LOCATION RELEVANCE - based on distance (Enhanced)
                            if hasattr(profile, 'preferred_radius'):
                                user_location = get_user_recent_location(user)
                                
                                if user_location:
                                    distance_km = calculate_distance(
                                        event_lat, event_lon, 
                                        user_location['lat'], user_location['lon']
                                    )
                                    
                                    # Enhanced distance scoring with better scaling
                                    max_distance = profile.preferred_radius * 3  # Increased range
                                    if distance_km <= profile.preferred_radius:
                                        location_score = 1.0  # Full score if within preferred radius
                                    elif distance_km <= max_distance:
                                        # Exponential decline for better distance sensitivity
                                        location_score = 1.0 - ((distance_km - profile.preferred_radius) / (max_distance - profile.preferred_radius)) ** 2
                                    else:
                                        location_score = 0.0
                                        
                                    score_components['location'] = location_score * WEIGHTS['location']
                            
                            # 4. SOCIAL RELEVANCE - friendship connections (Enhanced)
                            user_friends = set(profile.friends.values_list('user_id', flat=True))
                            
                            # Calculate social relevance score
                            if user.id in host_friends:
                                # Direct friend of host gets full score
                                social_score = 1.0
                            else:
                                # Calculate mutual friends with host
                                mutual_friends = len(user_friends.intersection(host_friends))
                                
                                if mutual_friends > 0:
                                    # Enhanced scaling by number of mutual friends
                                    social_score = min(1.0, (mutual_friends / 3.0) ** 0.5)  # Square root scaling
                                else:
                                    social_score = 0.0
                            
                            score_components['social'] = social_score * WEIGHTS['social']
                            
                            # 5. ACADEMIC SIMILARITY - NEW
                            # Match based on university, degree, and year
                            academic_score = 0.0
                            
                            # University matching (exact match gets full points)
                            if profile.university and host.userprofile.university:
                                if profile.university.lower() == host.userprofile.university.lower():
                                    academic_score += 0.4
                                elif any(word in profile.university.lower() for word in host.userprofile.university.lower().split()):
                                    academic_score += 0.2
                            
                            # Degree matching (similar fields get points)
                            if profile.degree and host.userprofile.degree:
                                degree_similarity = text_similarity(profile.degree.lower(), host.userprofile.degree.lower())
                                academic_score += degree_similarity * 0.3
                            
                            # Year matching (same year gets bonus, close years get partial)
                            if profile.year and host.userprofile.year:
                                try:
                                    user_year = int(profile.year.split()[0])  # Extract year number
                                    host_year = int(host.userprofile.year.split()[0])
                                    year_diff = abs(user_year - host_year)
                                    
                                    if year_diff == 0:
                                        academic_score += 0.3
                                    elif year_diff == 1:
                                        academic_score += 0.2
                                    elif year_diff == 2:
                                        academic_score += 0.1
                                except:
                                    pass  # Skip if year parsing fails
                            
                            score_components['academic_similarity'] = academic_score * WEIGHTS['academic_similarity']
                            
                            # 6. SKILL RELEVANCE - NEW
                            # Match user skills with event requirements
                            skill_score = 0.0
                            user_skills = profile.get_skills()
                            
                            if user_skills and event_content:
                                # Check if user has skills relevant to the event
                                event_words = set(event_content.lower().split())
                                
                                for skill_name, skill_level in user_skills.items():
                                    skill_words = skill_name.lower().split()
                                    
                                    # Check if skill is mentioned in event
                                    if any(word in event_words for word in skill_words):
                                        # Score based on skill level
                                        level_scores = {
                                            'BEGINNER': 0.3,
                                            'INTERMEDIATE': 0.6,
                                            'ADVANCED': 0.8,
                                            'EXPERT': 1.0
                                        }
                                        skill_score += level_scores.get(skill_level, 0.3)
                                
                                # Normalize skill score
                                skill_score = min(1.0, skill_score / 3.0)  # Cap at 3 relevant skills
                            
                            score_components['skill_relevance'] = skill_score * WEIGHTS['skill_relevance']
                            
                            # 7. BIO SIMILARITY - NEW
                            # Match bio content with event description
                            bio_score = 0.0
                            if profile.bio and event_content:
                                bio_similarity = text_similarity(profile.bio.lower(), event_content.lower())
                                bio_score = bio_similarity
                            
                            score_components['bio_similarity'] = bio_score * WEIGHTS['bio_similarity']
                            
                            # 8. REPUTATION BOOST - NEW
                            # Boost score based on user reputation and trust level
                            reputation_score = 0.0
                            try:
                                reputation_stats = user.reputation_stats
                                if reputation_stats:
                                    # Trust level boost
                                    if reputation_stats.trust_level:
                                        level_boost = min(1.0, reputation_stats.trust_level.level / 5.0)
                                        reputation_score += level_boost * 0.5
                                    
                                    # Rating boost
                                    if reputation_stats.average_rating > 0:
                                        rating_boost = min(1.0, (reputation_stats.average_rating - 3.0) / 2.0)
                                        reputation_score += max(0, rating_boost) * 0.3
                                    
                                    # Activity boost
                                    total_events = reputation_stats.events_hosted + reputation_stats.events_attended
                                    activity_boost = min(1.0, total_events / 10.0)
                                    reputation_score += activity_boost * 0.2
                            except:
                                pass  # Skip if reputation data not available
                            
                            score_components['reputation_boost'] = reputation_score * WEIGHTS['reputation_boost']
                            
                            # 9. EVENT TYPE PREFERENCE - NEW
                            # Analyze user's event history to determine preferences
                            event_type_score = 0.0
                            try:
                                # Get user's event history
                                hosted_events = StudyEvent.objects.filter(host=user)
                                attended_events = StudyEvent.objects.filter(attendees=user)
                                
                                # Count event types
                                type_counts = {}
                                for evt in list(hosted_events) + list(attended_events):
                                    evt_type = evt.event_type
                                    type_counts[evt_type] = type_counts.get(evt_type, 0) + 1
                                
                                # Calculate preference for current event type
                                total_events = sum(type_counts.values())
                                if total_events > 0:
                                    current_type_count = type_counts.get(event_type, 0)
                                    event_type_score = current_type_count / total_events
                            except:
                                pass  # Skip if event history not available
                            
                            score_components['event_type_preference'] = event_type_score * WEIGHTS['event_type_preference']
                            
                            # 10. TIME COMPATIBILITY - NEW
                            # Check if user typically attends events at similar times
                            time_score = 0.0
                            try:
                                # Get user's event history
                                user_events = StudyEvent.objects.filter(
                                    models.Q(host=user) | models.Q(attendees=user)
                                ).order_by('-time')[:10]  # Last 10 events
                                
                                if user_events:
                                    # Check time of day compatibility
                                    event_hour = event_time.hour
                                    compatible_events = 0
                                    
                                    for evt in user_events:
                                        evt_hour = evt.time.hour
                                        # Consider events within 3 hours as compatible
                                        if abs(evt_hour - event_hour) <= 3:
                                            compatible_events += 1
                                    
                                    time_score = compatible_events / len(user_events)
                            except:
                                pass  # Skip if time analysis fails
                            
                            score_components['time_compatibility'] = time_score * WEIGHTS['time_compatibility']
                            
                            # 11. ACTIVITY LEVEL - NEW
                            # Boost active users who regularly participate
                            activity_score = 0.0
                            try:
                                # Count recent activity (last 30 days)
                                from datetime import timedelta
                                thirty_days_ago = timezone.now() - timedelta(days=30)
                                
                                recent_hosted = StudyEvent.objects.filter(
                                    host=user, time__gte=thirty_days_ago
                                ).count()
                                
                                recent_attended = StudyEvent.objects.filter(
                                    attendees=user, time__gte=thirty_days_ago
                                ).count()
                                
                                total_recent = recent_hosted + recent_attended
                                activity_score = min(1.0, total_recent / 5.0)  # Cap at 5 events
                            except:
                                pass  # Skip if activity analysis fails
                            
                            score_components['activity_level'] = activity_score * WEIGHTS['activity_level']
                            
                            # Calculate total match score
                            total_score = sum(score_components.values())
                            
                            # Only consider users with a minimum score
                            min_score = 30.0  # Increased minimum threshold for better quality matches
                            if total_score >= min_score:
                                matched_profiles.append({
                                    "user": user,
                                    "score": total_score,
                                    "matching_interests": list(matching_interests) if 'matching_interests' in locals() else [],
                                    "score_breakdown": {k: round(v, 2) for k, v in score_components.items()}
                                })
                    
                    # Sort by match score (highest first) and limit to max_participants
                    matched_profiles.sort(key=lambda x: x["score"], reverse=True)
                    top_matches = matched_profiles[:max_participants]
                    
                    # Create invitations for top matches
                    invitation_objs = []
                    users_to_invite = []
                    
                    for match in top_matches:
                        user = match["user"]
                        users_to_invite.append(user)
                        invitation_objs.append(
                            EventInvitation(
                                event=event,
                                user=user,
                                is_auto_matched=True
                            )
                        )
                        
                        matched_users.append({
                            "username": user.username,
                            "score": round(match["score"], 2),
                            "matching_interests": match["matching_interests"],
                            "score_breakdown": match["score_breakdown"]
                        })
                    
                    # Bulk add users to invited_friends
                    if users_to_invite:
                        event.invited_friends.add(*users_to_invite)
                        
                        # Bulk create invitation records
                        EventInvitation.objects.bulk_create(
                            invitation_objs,
                            ignore_conflicts=True
                        )
                        
                        invites_sent = len(users_to_invite)
                        
                        # Optional: Send batch notifications
                        if invites_sent > 0:
                            try:
                                user_ids = [user.id for user in users_to_invite]
                                send_bulk_invitation_notifications(user_ids, event)
                            except Exception as e:
                                pass
                    
                except Exception as e:
                    import traceback
                    traceback.print_exc()
            
            return JsonResponse({
                "success": True, 
                "event_id": str(event.id),
                "auto_matching_results": {
                    "enabled": auto_matching_enabled,
                    "invites_sent": invites_sent,
                    "matched_users": matched_users
                }
            }, status=201)

        except Exception as e:
            import traceback
            traceback.print_exc()
            return JsonResponse({"error": str(e)}, status=500)

    return JsonResponse({"error": "Invalid method"}, status=405)


from django.contrib.auth.models import User
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone  # Add this import
from .models import StudyEvent, DeclinedInvitation  # Add DeclinedInvitation

@csrf_exempt
def get_study_events(request, username):
    """
    🔧 FIXED: Simplified event fetching for better consistency
    Returns all events that the user should see (hosted, public, friends', auto-matched)
    """
    try:
        # Get the user
        user = User.objects.get(username=username)
        
        # Get current time to exclude past events
        now = timezone.now()
        
        # Get basic info we need
        friend_list = list(user.userprofile.friends.values_list("user__username", flat=True))
        
        # Get declined event IDs to exclude
        declined_event_ids = DeclinedInvitation.objects.filter(user=user).values_list('event_id', flat=True)
        
        # Build a comprehensive query to get all relevant events
        # Use Q objects for complex filtering
        from django.db.models import Q
        
        # Get events that the user should see:
        # 1. Public events (not declined, not expired)
        # 2. Events hosted by user
        # 3. Events hosted by friends
        # 4. Events where user is explicitly invited
        # 5. Events where user has auto-matched invitations
        
        events = StudyEvent.objects.select_related('host', 'host__userprofile').prefetch_related(
            'invited_friends', 'attendees', 'invitation_records'
        ).filter(
            # Only future events
            end_time__gt=now
        ).filter(
            # Include events that match at least one of these criteria
            Q(is_public=True) |                                    # Public events
            Q(host=user) |                                         # User's own events
            Q(host__username__in=friend_list) |                    # Friends' events
            Q(invited_friends=user) |                              # Directly invited
            Q(invitation_records__user=user)                       # Auto-matched invitations
        ).exclude(
            # Exclude declined events
            id__in=declined_event_ids
        ).distinct()
        
        # Format the events for response
        event_data = []
        for event in events:
            # Get auto-matched users for this event
            auto_matched_users = list(
                event.invitation_records.filter(is_auto_matched=True).values_list('user__username', flat=True)
            )
            
            # Check if this user is auto-matched to this event
            is_user_auto_matched = user.username in auto_matched_users
            
            # Build the event data
            event_info = {
                "id": str(event.id),
                "title": event.title,
                "description": event.description or "",
                "latitude": event.latitude,
                "longitude": event.longitude,
                "time": event.time.isoformat(),
                "end_time": event.end_time.isoformat(),
                "host": event.host.username,
                "hostIsCertified": event.host.userprofile.is_certified,
                "isPublic": event.is_public,
                "event_type": (event.event_type or "other").lower(),
                "invitedFriends": list(event.invited_friends.values_list("username", flat=True)),
                "attendees": list(event.attendees.values_list("username", flat=True)),
                "max_participants": event.max_participants,
                "auto_matching_enabled": event.auto_matching_enabled,
                "isAutoMatched": is_user_auto_matched,
                "matchedUsers": auto_matched_users,
                "interest_tags": event.get_interest_tags() if hasattr(event, 'get_interest_tags') else []
            }
            
            event_data.append(event_info)
        
        # Sort events by time (nearest first)
        event_data.sort(key=lambda x: x['time'])
        
        
        return JsonResponse({"events": event_data}, safe=False)
        
    except User.DoesNotExist:
        return JsonResponse({"error": "User not found"}, status=404)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

def _should_include_event(event, user, username):
    """Helper function to determine if an event should be included"""
    # Check if this is an auto-matched event for this user
    is_auto_matched_for_user = any(
        inv.user_id == user.id and inv.is_auto_matched 
        for inv in event.invitation_records.all()
    )
    
    # If this is an auto-matched event AND user is not matched or a host/attendee, skip
    if (event.auto_matching_enabled and
        not is_auto_matched_for_user and
        event.host.username != username and
        not any(att.username == username for att in event.attendees.all())):
        # For auto-matched events, user must be explicitly matched
        matched_usernames = [
            inv.user.username for inv in event.invitation_records.all() 
            if inv.is_auto_matched
        ]
        if username not in matched_usernames:
            return False
    
    # For standard events, apply regular filtering
    if (event.invited_friends.filter(username=username).exists() and 
        not event.attendees.filter(username=username).exists() and 
        event.host.username != username and 
        not any(inv.user_id == user.id for inv in event.invitation_records.all()) and
        not is_auto_matched_for_user):
        return False
        
    return True

        
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json

import json
import uuid
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from uuid import UUID
from .models import User, StudyEvent

import uuid
import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import User, StudyEvent

import uuid
import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import User, StudyEvent  # Assuming you have a User and StudyEvent model.
import uuid
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import StudyEvent, User

@csrf_exempt
def rsvp_study_event(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            username = data.get("username")
            event_id = data.get("event_id")

            # Convert the event_id to lowercase and ensure it's a valid UUID
            try:
                event_uuid = uuid.UUID(event_id.lower())
            except ValueError:
                return JsonResponse({"error": "Invalid event_id format"}, status=400)

            # Try to fetch the event using the UUID
            try:
                event = StudyEvent.objects.get(id=event_uuid)
            except StudyEvent.DoesNotExist:
                return JsonResponse({"error": "Event not found"}, status=404)

            # Fetch user
            user = User.objects.get(username=username)

            # Check if the user is already an attendee
            if user in event.attendees.all():
                event.attendees.remove(user)  # Leave event
                event.save() # ADDED: Explicitly save the event after removing attendee
                event_data = {
                    "id": str(event.id),
                    "title": event.title,
                    "event_type": event.event_type.lower(),  # Ensure lowercase
                }
                
                # Broadcast event update (user left the event)
                broadcast_event_updated(
                    event_id=event.id,
                    host_username=event.host.username,
                    attendees=[u.username for u in event.attendees.all()],
                    invited_friends=[u.username for u in event.invited_friends.all()]
                )
                
                return JsonResponse({
                    "success": True,
                    "action": "left",
                    "event": event_data
                })
            else:
                # Join event
                event.attendees.add(user)
                
                # If there was an invitation, mark it as accepted
                try:
                    invitation = EventInvitation.objects.get(event=event, user=user)
                    invitation.accepted = True
                    invitation.save()
                except EventInvitation.DoesNotExist:
                    # No invitation exists, which is fine
                    pass
                
                event.save()
                event_data = {
                    "id": str(event.id),
                    "title": event.title,
                    "event_type": event.event_type.lower(),  # Ensure lowercase
                }
                
                # Broadcast event update (user joined the event)
                broadcast_event_updated(
                    event_id=event.id,
                    host_username=event.host.username,
                    attendees=[u.username for u in event.attendees.all()],
                    invited_friends=[u.username for u in event.invited_friends.all()]
                )
                
                return JsonResponse({
                    "success": True,
                    "action": "joined",
                    "event": event_data
                })

        except User.DoesNotExist:
            return JsonResponse({"error": "User not found"}, status=404)
        except ValueError:
            return JsonResponse({"error": "Invalid event_id format"}, status=400)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)

    return JsonResponse({"error": "Invalid request method"}, status=405)

@csrf_exempt
def update_study_event(request):
    """
    PUT/POST request with JSON:
        pass
    {
      "username": "Alice",
      "event_id": "<UUID-string>",
      "title": "Updated Event Title",
      "description": "Updated description",
      "latitude": 40.7128,
      "longitude": -74.0060,
      "time": "2025-01-15T18:00:00",
      "end_time": "2025-01-15T20:00:00",
      "is_public": true,
      "event_type": "study",
      "max_participants": 15,
      "interest_tags": ["programming", "networking"]
    }
    Only the host of the event can update it.
    """
    if request.method in ["PUT", "POST"]:
        try:
            data = json.loads(request.body)
            username = data.get("username")
            event_id = data.get("event_id")

            try:
                event_uuid = uuid.UUID(event_id)
            except ValueError:
                return JsonResponse({"error": "Invalid event_id format"}, status=400)

            try:
                event = StudyEvent.objects.get(id=event_uuid)
            except StudyEvent.DoesNotExist:
                return JsonResponse({"error": "Event not found"}, status=404)

            # Check if the user is actually the host
            if event.host.username != username:
                return JsonResponse({"error": "Only the host can update this event"}, status=403)

            # Store old values for notification
            old_title = event.title
            old_time = event.time
            old_location = f"{event.latitude},{event.longitude}"
            
            # Update event fields
            if "title" in data:
                event.title = data.get("title", event.title)
            if "description" in data:
                event.description = data.get("description", event.description)
            if "latitude" in data:
                event.latitude = data.get("latitude", event.latitude)
            if "longitude" in data:
                event.longitude = data.get("longitude", event.longitude)
            if "time" in data:
                event.time = datetime.fromisoformat(data.get("time"))
            if "end_time" in data:
                event.end_time = datetime.fromisoformat(data.get("end_time"))
            if "is_public" in data:
                event.is_public = data.get("is_public", event.is_public)
            if "event_type" in data:
                event.event_type = data.get("event_type", event.event_type)
            if "max_participants" in data:
                event.max_participants = data.get("max_participants", event.max_participants)
            if "interest_tags" in data:
                event.set_interest_tags(data.get("interest_tags", []))

            # Save the updated event
            event.save()
            
            # Get all users to notify (attendees + invited friends)
            attendees = [u.username for u in event.attendees.all()]
            invited_friends = [u.username for u in event.invited_friends.all()]
            all_notified_users = list(set(attendees + invited_friends))
            
            # Broadcast event update to all relevant users
            broadcast_event_update(
                event_id=str(event.id),
                event_type="update",
                usernames=all_notified_users
            )
            
            # Send push notifications about the changes
            send_event_update_notifications(
                event=event,
                old_title=old_title,
                old_time=old_time,
                old_location=old_location,
                notified_users=all_notified_users
            )
            
            return JsonResponse({
                "success": True, 
                "message": "Event updated successfully",
                "event_id": str(event.id)
            }, status=200)

        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON"}, status=400)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)

    return JsonResponse({"error": "Invalid request method"}, status=405)

def send_event_update_notifications(event, old_title, old_time, old_location, notified_users):
    """Send push notifications about event updates"""
    try:
        from myapp.views import send_push_notification
        
        # Determine what changed
        changes = []
        if event.title != old_title:
            changes.append(f"Title: '{old_title}' → '{event.title}'")
        if event.time != old_time:
            changes.append(f"Time: {old_time} → {event.time}")
        if f"{event.latitude},{event.longitude}" != old_location:
            changes.append("Location changed")
        
        if changes:
            change_text = "; ".join(changes)
            message = f"Event '{event.title}' was updated: {change_text}"
            
            for username in notified_users:
                if username != event.host.username:  # Don't notify the host
                    send_push_notification(
                        user_id=User.objects.get(username=username).id,
                        notification_type="event_updated",
                        event_id=str(event.id),
                        event_title=event.title,
                        message=message
                    )
    except Exception as e:
        pass

@csrf_exempt
def delete_study_event(request):
    """
    POST request with JSON:
        pass
    {
      "username": "Alice",
      "event_id": "<UUID-string>"
    }
    Only the host of the event can delete it.
    """
    if request.method == "POST":
        data = json.loads(request.body)
        username = data.get("username")
        event_id = data.get("event_id")

        try:
            event_uuid = uuid.UUID(event_id)
        except ValueError:
            return JsonResponse({"error": "Invalid event_id format"}, status=400)

        try:
            event = StudyEvent.objects.get(id=event_uuid)
        except StudyEvent.DoesNotExist:
            return JsonResponse({"error": "Event not found"}, status=404)

        # Check if the user is actually the host
        if event.host.username != username:
            return JsonResponse({"error": "Only the host can delete this event"}, status=403)

        # Store attendees and invited friends before deleting the event
        host_username = event.host.username
        attendees = [u.username for u in event.attendees.all()]
        invited_friends = [u.username for u in event.invited_friends.all()]
        
        # Delete the event
        event.delete()
        
        # Broadcast event deletion to WebSocket clients
        broadcast_event_deleted(
            event_id=event_uuid,
            host_username=host_username,
            attendees=attendees,
            invited_friends=invited_friends
        )
        
        return JsonResponse({"success": True, "message": "Event deleted successfully"}, status=200)

    return JsonResponse({"error": "Invalid request method"}, status=405)


def get_user_profile(request, username):
    try:
        user = User.objects.get(username=username)
        userprofile = user.userprofile
        
        # Get basic profile information
        full_name = getattr(userprofile, 'full_name', '')
        university = getattr(userprofile, 'university', '')
        degree = getattr(userprofile, 'degree', '')
        year = getattr(userprofile, 'year', '')
        bio = getattr(userprofile, 'bio', '')
        
        # Get interests if available or provide empty list
        interests = []
        if hasattr(userprofile, 'get_interests'):
            interests = userprofile.get_interests()
        
        # Get skills if available or provide empty map  
        skills = {}
        if hasattr(userprofile, 'get_skills'):
            skills = userprofile.get_skills()
        
        # Get auto invite preference with default
        auto_invite_enabled = getattr(userprofile, 'auto_invite_enabled', True)
        
        # Get preferred radius with default
        preferred_radius = getattr(userprofile, 'preferred_radius', 10.0)
        
        return JsonResponse({
            "username": user.username,
            "full_name": full_name,
            "university": university,
            "degree": degree,
            "year": year,
            "bio": bio,
            "is_certified": userprofile.is_certified,
            "interests": interests,
            "skills": skills,
            "auto_invite_enabled": auto_invite_enabled,
            "preferred_radius": preferred_radius
        })
    except User.DoesNotExist:
        return JsonResponse({"error": "User not found"}, status=404)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
def search_events(request):
    if request.method == "GET":
        query = request.GET.get("query", "")
        public_only = request.GET.get("public_only", "false").lower() == "true"
        certified_only = request.GET.get("certified_only", "false").lower() == "true"

        qs = StudyEvent.objects.all()

        # If user typed a text query, match event titles
        if query:
            from django.db.models import Q
            qs = qs.filter(Q(title__icontains=query))

        # If user wants only public events
        if public_only:
            qs = qs.filter(is_public=True)

        # If user wants events from certified hosts
        if certified_only:
            qs = qs.filter(host__userprofile__is_certified=True)

        # Build JSON
        data = []
        for event in qs:
            data.append({
                "id": str(event.id),
                "title": event.title,
                "latitude": event.latitude,
                "longitude": event.longitude,
                "time": event.time.isoformat(),
                "end_time": event.end_time.isoformat(),
                "host": event.host.username,
                "isPublic": event.is_public,
                # ...
            })

        return JsonResponse({"events": data}, safe=False)

    return JsonResponse({"error": "Invalid request method"}, status=405)


# Try to import SentenceTransformer, but make it optional
try:
    from sentence_transformers import SentenceTransformer
    import numpy as np
    SEMANTIC_SEARCH_AVAILABLE = True
    MODEL = None
except ImportError:
    SEMANTIC_SEARCH_AVAILABLE = False
    MODEL = None

def semantic_search(query, events):
    """
    Performs semantic search over the given events based on the query.
    Returns the top 5 events ranked by cosine similarity.
    """
    if not SEMANTIC_SEARCH_AVAILABLE:
        return events[:5]
    
    global MODEL
    if MODEL is None:
        MODEL = SentenceTransformer('all-MiniLM-L6-v2')
        
    # Compute embedding for the query
    query_embedding = MODEL.encode(query, convert_to_numpy=True)
    similarities = []
    
    for event in events:
        emb = get_event_embedding(event)
        # Calculate cosine similarity
        sim = np.dot(query_embedding, emb) / (np.linalg.norm(query_embedding) * np.linalg.norm(emb))
        similarities.append(sim)
    
    # Sort events by similarity score (highest first)
    ranked_events = sorted(zip(events, similarities), key=lambda x: x[1], reverse=True)
    top_events = [event for event, sim in ranked_events[:5]]
    return top_events

def get_event_embedding(event):
    """
    Returns the embedding for an event's title and description.
    Caches the embedding to avoid re-computation.
    """
    if not SEMANTIC_SEARCH_AVAILABLE:
        return None
    
    global MODEL
    if MODEL is None:
        MODEL = SentenceTransformer('all-MiniLM-L6-v2')
        
    cache_key = f'event_embedding_{event.id}'
    embedding = cache.get(cache_key)
    if embedding is None:
        text = f"{event.title} {event.description or ''}"
        embedding = MODEL.encode(text, convert_to_numpy=True)
        cache.set(cache_key, embedding, timeout=3600)  # Cache for 1 hour
    return embedding

@csrf_exempt
def enhanced_search_events(request):
    if request.method == "GET":
        query = request.GET.get("query", "")
        public_only = request.GET.get("public_only", "false").lower() == "true"
        certified_only = request.GET.get("certified_only", "false").lower() == "true"
        event_type = request.GET.get("event_type", "").lower()
        use_semantic = request.GET.get("semantic", "false").lower() == "true"

        qs = StudyEvent.objects.all()

        # Basic search filtering
        if query:
            qs = qs.filter(Q(title__icontains=query) | Q(description__icontains=query))
        if public_only:
            qs = qs.filter(is_public=True)
        if certified_only:
            qs = qs.filter(host__userprofile__is_certified=True)
        if event_type:
            qs = qs.filter(event_type__iexact=event_type)

        # Use semantic search if enabled, available, and no basic results found
        if use_semantic and SEMANTIC_SEARCH_AVAILABLE and query and qs.count() == 0:
            try:
                events_list = list(StudyEvent.objects.all())
                semantic_results = semantic_search(query, events_list)
                if semantic_results:
                    semantic_ids = [str(event.id) for event in semantic_results]
                    qs = StudyEvent.objects.filter(id__in=semantic_ids)
            except Exception as e:
                pass

        # Build JSON response data
        data = []
        for event in qs:
            data.append({
                "id": str(event.id),
                "title": event.title,
                "description": event.description or "",
                "latitude": event.latitude,
                "longitude": event.longitude,
                "time": event.time.isoformat(),
                "end_time": event.end_time.isoformat(),
                "host": event.host.username,
                "hostIsCertified": event.host.userprofile.is_certified,
                "isPublic": event.is_public,
                "event_type": event.event_type.lower() if event.event_type else "other",
                "invitedFriends": list(event.invited_friends.values_list("username", flat=True)),
                "attendees": list(event.attendees.values_list("username", flat=True)),
            })

        return JsonResponse({"events": data}, safe=False)
    return JsonResponse({"error": "Invalid request method"}, status=405)

@csrf_exempt
def certify_user(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            username = data.get("username")
            # You can add extra verification here (like an admin secret or document verification)
            user = User.objects.get(username=username)
            user.userprofile.is_certified = True
            user.userprofile.save()
            return JsonResponse({"success": True, "message": f"User {username} certified."}, status=200)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)
    return JsonResponse({"error": "Invalid request method."}, status=405)



# -----------------------------
# Invitation Endpoints
# -----------------------------

@csrf_exempt
def decline_invitation(request):
    """
    Declines an invitation and records it in the DeclinedInvitation model.
    Expected JSON:
        pass
    {
      "username": "invitedUser",
      "event_id": "<UUID-string>"
    }
    """
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            username = data.get("username")
            event_id = data.get("event_id")
            
            
            user = User.objects.get(username=username)
            event = StudyEvent.objects.get(id=event_id)
            
            # First, remove the user from invited_friends
            if user in event.invited_friends.all():
                event.invited_friends.remove(user)
            else:
                pass
            
            # Then, create a DeclinedInvitation record
            declined, created = DeclinedInvitation.objects.get_or_create(user=user, event=event)
            if created:
                pass
            else:
                pass
                
            event.save()
            
            return JsonResponse({
                "success": True, 
                "message": "Invitation declined",
                "event_id": str(event.id)
            }, status=200)
        except User.DoesNotExist:
            return JsonResponse({"error": "User not found"}, status=404)
        except StudyEvent.DoesNotExist:
            return JsonResponse({"error": "Event not found"}, status=404)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)
    return JsonResponse({"error": "Invalid request method"}, status=405)


@csrf_exempt
def get_invitations(request, username):
    """
    Returns events where the user was invited but has not yet accepted
    Includes is_auto_matched flag to differentiate direct invites from potential matches
    """
    try:
        user = User.objects.get(username=username)
        
        # Get all events where user is directly invited
        direct_events = StudyEvent.objects.filter(invited_friends=user) \
                                     .exclude(attendees=user) \
                                     .exclude(host=user)
        
        # Get all auto-matched events (that may not have user in invited_friends)
        auto_matched_invitations = EventInvitation.objects.filter(user=user, is_auto_matched=True)
        auto_matched_event_ids = [inv.event_id for inv in auto_matched_invitations]
        auto_matched_events = StudyEvent.objects.filter(id__in=auto_matched_event_ids) \
                                         .exclude(attendees=user) \
                                         .exclude(host=user)
        
        # Combine both event sets to get all events
        all_event_ids = set(direct_events.values_list('id', flat=True)) | set(auto_matched_events.values_list('id', flat=True))
        all_events = StudyEvent.objects.filter(id__in=all_event_ids)
        
        
        invitation_data = []
        for event in all_events:
            # Check if this is an auto-matched invitation
            try:
                invitation = EventInvitation.objects.get(event=event, user=user)
                is_auto_matched = invitation.is_auto_matched
            except EventInvitation.DoesNotExist:
                # If no invitation record exists, it's a direct invite
                is_auto_matched = False
                
            invitation_data.append({
                "id": str(event.id),
                "title": event.title,
                "description": event.description or "",
                "latitude": event.latitude,
                "longitude": event.longitude,
                "time": event.time.isoformat(),
                "end_time": event.end_time.isoformat(),
                "host": event.host.username,
                "hostIsCertified": event.host.userprofile.is_certified,
                "isPublic": event.is_public,
                "event_type": event.event_type,
                "isAutoMatched": is_auto_matched,  # Changed to camelCase to match Android expectation
                "invitedFriends": list(event.invited_friends.values_list("username", flat=True)),
                "attendees": list(event.attendees.values_list("username", flat=True)),
            })
        
        return JsonResponse({"invitations": invitation_data}, safe=False)
    except User.DoesNotExist:
        return JsonResponse({"error": "User not found"}, status=404)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)



from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.models import User
from .models import StudyEvent, EventComment, EventLike, EventShare
import json
import uuid

# Simplified and debug-focused version of add_event_comment

from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
import json
import uuid
import traceback
from django.contrib.auth.models import User
from .models import StudyEvent, EventComment

@csrf_exempt
def add_event_comment(request):
    """
    Simplified comment endpoint with extensive error tracking
    """
    if request.method == "POST":
        # Log the raw request body for debugging
        raw_body = request.body.decode('utf-8')
        
        try:
            # Parse JSON with error handling
            try:
                data = json.loads(raw_body)
            except json.JSONDecodeError as e:
                return JsonResponse({"error": f"Invalid JSON: {str(e)}"}, status=400)
                
            # Extract and validate required fields
            username = data.get("username")
            event_id = data.get("event_id")
            text = data.get("text")
            parent_id = data.get("parent_id")
            
            
            if not all([username, event_id, text]):
                return JsonResponse({
                    "error": "Missing required fields",
                    "fields": {
                        "username": bool(username),
                        "event_id": bool(event_id),
                        "text": bool(text)
                    }
                }, status=400)
            
            # Find user
            try:
                user = User.objects.get(username=username)
            except User.DoesNotExist:
                return JsonResponse({"error": f"User '{username}' not found"}, status=404)
            
            # Parse event UUID
            try:
                event_uuid = uuid.UUID(event_id)
            except ValueError:
                return JsonResponse({"error": f"Invalid event ID format: {event_id}"}, status=400)
            
            # Find event
            try:
                event = StudyEvent.objects.get(id=event_uuid)
            except StudyEvent.DoesNotExist:
                return JsonResponse({"error": f"Event with ID {event_id} not found"}, status=404)
            
            # Handle parent comment if provided
            parent = None
            if parent_id:
                try:
                    parent = EventComment.objects.get(id=parent_id)
                except EventComment.DoesNotExist:
                    return JsonResponse({"error": f"Parent comment {parent_id} not found"}, status=404)
                except ValueError:
                    return JsonResponse({"error": f"Invalid parent ID format: {parent_id}"}, status=400)
            
            # Create the comment
            try:
                comment = EventComment.objects.create(
                    event=event,
                    user=user,
                    text=text,
                    parent=parent
                )
            except Exception as e:
                traceback.print_exc()
                return JsonResponse({"error": f"Error creating comment: {str(e)}"}, status=500)
            
            # Return the successful response
            return JsonResponse({
                "success": True,
                "post": {
                    "id": comment.id,
                    "text": comment.text,
                    "username": user.username,
                    "created_at": comment.created_at.isoformat(),
                    "imageURLs": None,
                    "likes": 0,
                    "isLikedByCurrentUser": False,
                    "replies": []
                }
            })
        
        except Exception as e:
            # Catch-all for any other errors
            traceback.print_exc()
            return JsonResponse({"error": f"Server error: {str(e)}"}, status=500)
    
    # Handle non-POST requests
    return JsonResponse({"error": f"Method {request.method} not allowed"}, status=405)

@csrf_exempt
def toggle_event_like(request):
    """
    Like or unlike an event or post with comprehensive error handling and logging
    """
    if request.method == "POST":
        # Enhanced logging of raw request
        raw_body = request.body.decode('utf-8')
        
        try:
            data = json.loads(raw_body)
            username = data.get("username")
            event_id = data.get("event_id")
            post_id = data.get("post_id")  # Optional

            # Comprehensive input validation
            if not username or not event_id:
                return JsonResponse({
                    "error": "Missing required fields", 
                    "details": {
                        "username": bool(username),
                        "event_id": bool(event_id)
                    }
                }, status=400)

            # Fetch user and event with error handling
            try:
                user = User.objects.get(username=username)
                event = StudyEvent.objects.get(id=uuid.UUID(event_id))
            except User.DoesNotExist:
                return JsonResponse({"error": "User not found"}, status=404)
            except StudyEvent.DoesNotExist:
                return JsonResponse({"error": "Event not found"}, status=404)

            # Like/Unlike Logic
            if post_id:
                # Post/Comment Like Logic
                try:
                    comment = EventComment.objects.get(id=post_id)
                    like_query = EventLike.objects.filter(
                        user=user, 
                        event=event,
                        comment=comment
                    )
                    
                    if like_query.exists():
                        # Unlike
                        like_query.delete()
                        liked = False
                    else:
                        # Like
                        EventLike.objects.create(
                            user=user, 
                            event=event,
                            comment=comment
                        )
                        liked = True
                        
                    # Comprehensive likes calculation
                    total_likes = EventLike.objects.filter(
                        event=event,
                        comment=comment
                    ).count()
                    
                    
                except EventComment.DoesNotExist:
                    return JsonResponse({"error": "Comment not found"}, status=404)
                
            else:
                # Event Like Logic
                like_query = EventLike.objects.filter(
                    user=user, 
                    event=event,
                    comment__isnull=True
                )

                if like_query.exists():
                    # Unlike
                    like_query.delete()
                    liked = False
                else:
                    # Like
                    EventLike.objects.create(
                        user=user, 
                        event=event
                    )
                    liked = True
                
                # Event-level likes calculation
                total_likes = EventLike.objects.filter(
                    event=event,
                    comment__isnull=True
                ).count()
                

            # Detailed response with likes information
            return JsonResponse({
                "success": True,
                "liked": liked,  # Boolean indicating if user now likes
                "total_likes": total_likes,  # Total number of likes
                "event_id": str(event_id),  # Echo back event ID for frontend reference
                "username": username  # Echo back username
            })

        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON data"}, status=400)
        except Exception as e:
            import traceback
            traceback.print_exc()
            return JsonResponse({"error": str(e)}, status=500)
    
    return JsonResponse({"error": "Invalid request method"}, status=405)

@csrf_exempt
def record_event_share(request):
    """
    Record an event share
    Expected JSON:
        pass
    {
        "username": "johndoe",
        "event_id": "<event-uuid>",
        "platform": "whatsapp"  # whatsapp, facebook, twitter, instagram, other
    }
    """
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            username = data.get("username")
            event_id = data.get("event_id")
            platform = data.get("platform", "other")

            # Validate input
            if not username or not event_id:
                return JsonResponse({"error": "Missing required fields"}, status=400)

            # Fetch user and event
            user = User.objects.get(username=username)
            event = StudyEvent.objects.get(id=uuid.UUID(event_id))

            # Create share record
            share = EventShare.objects.create(
                user=user,
                event=event,
                shared_platform=platform
            )

            # Get total shares
            total_shares = EventShare.objects.filter(event=event).count()

            return JsonResponse({
                "success": True,
                "total_shares": total_shares
            })

        except User.DoesNotExist:
            return JsonResponse({"error": "User not found"}, status=404)
        except StudyEvent.DoesNotExist:
            return JsonResponse({"error": "Event not found"}, status=404)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)
    
    return JsonResponse({"error": "Invalid request method"}, status=405)

def get_event_interactions(request, event_id):
    """
    Retrieve all interactions (comments, likes, shares) for a specific event
    with detailed like tracking
    """
    try:
        event = StudyEvent.objects.get(id=uuid.UUID(event_id))

        # Detailed comment like tracking
        def get_nested_comments(parent=None):
            base_comments = EventComment.objects.filter(
                event=event, 
                parent=parent
            ).order_by('created_at')
            
            comments_data = []
            for comment in base_comments:
                # Count likes for this specific comment
                comment_likes = EventLike.objects.filter(
                    event=event, 
                    comment=comment
                ).count()
                
                # Debug print for comment likes
                
                comment_data = {
                    "id": comment.id,
                    "text": comment.text,
                    "username": comment.user.username,
                    "created_at": comment.created_at.isoformat(),
                    "likes": comment_likes,  # Add like count
                    "replies": get_nested_comments(comment)
                }
                comments_data.append(comment_data)
            
            return comments_data

        # Root level comments with likes
        comments = get_nested_comments()

        # Event-level likes (without comments)
        event_likes = EventLike.objects.filter(event=event, comment__isnull=True).count()

        # Detailed likes tracking
        likes_by_user = {}
        for like in EventLike.objects.filter(event=event):
            username = like.user.username
            if like.comment:
                # Comment-specific like
                if username not in likes_by_user:
                    likes_by_user[username] = {"event_likes": 0, "comment_likes": 0}
                likes_by_user[username]["comment_likes"] += 1
            else:
                # Event-level like
                if username not in likes_by_user:
                    likes_by_user[username] = {"event_likes": 0, "comment_likes": 0}
                likes_by_user[username]["event_likes"] += 1

        # Debug print for likes breakdown
        for username, likes in likes_by_user.items():
            pass

        # Shares breakdown
        shares_breakdown = {}
        shares = EventShare.objects.filter(event=event)
        for platform in ['whatsapp', 'facebook', 'twitter', 'instagram', 'other']:
            shares_breakdown[platform] = shares.filter(shared_platform=platform).count()

        return JsonResponse({
            "comments": comments,
            "likes": {
                "total": event_likes,
                "users": list(likes_by_user.keys()),
                "detailed_breakdown": likes_by_user
            },
            "shares": {
                "total": shares.count(),
                "breakdown": shares_breakdown
            }
        })

    except StudyEvent.DoesNotExist:
        return JsonResponse({"error": "Event not found"}, status=404)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

# Add these functions to your views.py file

def get_event_feed(request, event_id):
    """
    Retrieve event feed data (posts, likes, shares) in the format expected by the new Swift implementation.
    This combines comments, likes, and shares into the new Posts structure.
    """
    try:
        # Get current user from the query parameter
        current_username = request.GET.get('current_user', None)
        if not current_username:
            return JsonResponse({"error": "current_user parameter is required"}, status=400)
            
        # Try to get the current user
        try:
            current_user = User.objects.get(username=current_username)
        except User.DoesNotExist:
            return JsonResponse({"error": "User not found"}, status=404)
            
        # Convert string ID to UUID
        event = StudyEvent.objects.get(id=uuid.UUID(event_id))
        
        # IMPORTANT: Check if the user should be able to see this event
        # Similar to the filtering logic in get_study_events
        
        # Check if this is an auto-matched event
        if event.auto_matching_enabled:
            
            # Get the list of matched users for this event
            auto_matched_invitations = EventInvitation.objects.filter(
                event=event,
                is_auto_matched=True
            )
            matched_users = [invitation.user.username for invitation in auto_matched_invitations]
            
            # Check if the current user is in the matched users list
            is_matched = current_username in matched_users
            
            # Check if the user is the host, an attendee, or directly invited
            is_host = event.host.username == current_username
            is_attendee = event.attendees.filter(username=current_username).exists()
            is_invited = event.invited_friends.filter(username=current_username).exists()
            
            # If this is an auto-matched event AND user is not in matched_users list,
            # AND user is not host, attendee, or directly invited, then deny access
            if (not is_matched and not is_host and not is_attendee and not is_invited):
                return JsonResponse({"error": "You do not have access to this event"}, status=403)
            else:
                if is_matched:
                    pass
                elif is_host:
                    pass
                elif is_attendee:
                    pass
                elif is_invited:
                    pass
        
        # Get all comments (sorted by newest first)
        comments = EventComment.objects.filter(event=event, parent=None).order_by('-created_at')
        
        # Get likes data
        likes_total = EventLike.objects.filter(event=event).count()
        likes_users = list(EventLike.objects.filter(event=event).values_list('user__username', flat=True))
        
        # Get shares data
        shares_total = EventShare.objects.filter(event=event).count()
        
        # Build shares breakdown
        shares_breakdown = {}
        for platform in ['whatsapp', 'facebook', 'twitter', 'instagram', 'other']:
            shares_breakdown[platform] = EventShare.objects.filter(
                event=event, 
                shared_platform=platform
            ).count()
        
        # Format posts data in the format expected by the Swift implementation
        posts_data = []
        for comment in comments:
            # Check if the current user liked this comment
            is_liked = EventLike.objects.filter(
                user=current_user, 
                event=event, 
                comment_id=comment.id
            ).exists()
            
            # Get replies for this comment
            replies = []
            for reply in EventComment.objects.filter(parent=comment).order_by('created_at'):
                replies.append({
                    "id": reply.id,
                    "text": reply.text,
                    "username": reply.user.username,
                    "created_at": reply.created_at.isoformat(),
                    "imageURLs": None,  # Add image handling if needed
                    "likes": 0,  # Add likes count for replies if implementing
                    "isLikedByCurrentUser": False,  # Add current user like check if implementing
                    "replies": []  # We don't support nested replies beyond 1 level
                })
            
            # Build the post structure
            post = {
                "id": comment.id,
                "text": comment.text,
                "username": comment.user.username,
                "created_at": comment.created_at.isoformat(),
                "imageURLs": None,  # Add image handling if needed
                "likes": 0,  # Add like count for each post if implementing 
                "isLikedByCurrentUser": is_liked,
                "replies": replies
            }
            posts_data.append(post)
        
        # Return the event feed data
        return JsonResponse({
            "posts": posts_data,
            "likes": {
                "total": likes_total,
                "users": likes_users
            },
            "shares": {
                "total": shares_total,
                "breakdown": shares_breakdown
            }
        })
        
    except StudyEvent.DoesNotExist:
        return JsonResponse({"error": "Event not found"}, status=404)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

# Update the add_event_comment function to support post creation with images
@csrf_exempt
def add_event_comment(request):
    """
    Add a comment/post to an event, possibly with images
    Expected JSON:
        pass
    {
        "username": "johndoe",
        "event_id": "<event-uuid>",
        "text": "Great event!",
        "parent_id": null,  # optional, for replies
        "image_urls": []    # optional, for posts with images
    }
    """
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            username = data.get("username")
            event_id = data.get("event_id")
            text = data.get("text")
            parent_id = data.get("parent_id")
            image_urls = data.get("image_urls", [])  # List of image URLs if any

            # Validate input
            if not username or not event_id or not text:
                return JsonResponse({"error": "Missing required fields"}, status=400)

            # Fetch user and event
            user = User.objects.get(username=username)
            event = StudyEvent.objects.get(id=uuid.UUID(event_id))

            # Create comment/post
            if parent_id:
                # This is a reply
                parent_comment = EventComment.objects.get(id=parent_id)
                comment = EventComment.objects.create(
                    event=event,
                    user=user,
                    text=text,
                    parent=parent_comment
                )
            else:
                # This is a top-level post
                comment = EventComment.objects.create(
                    event=event,
                    user=user,
                    text=text
                )
            
            # If the post has images, store them
            # Note: You need to implement image storage if needed
            # This is just a placeholder for how you might handle it
            if image_urls and len(image_urls) > 0:
                # Store image URLs in a related model or as JSON in a field
                # Example: EventImage.objects.create(comment=comment, image_url=url)
                pass

            # Return the created post data
            return JsonResponse({
                "success": True,
                "post": {
                    "id": comment.id,
                    "text": comment.text,
                    "username": comment.user.username,
                    "created_at": comment.created_at.isoformat(),
                    "imageURLs": image_urls if image_urls else None,
                    "likes": 0,
                    "isLikedByCurrentUser": False,
                    "replies": []
                }
            }, status=201)

        except User.DoesNotExist:
            return JsonResponse({"error": "User not found"}, status=404)
        except StudyEvent.DoesNotExist:
            return JsonResponse({"error": "Event not found"}, status=404)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)
    
    return JsonResponse({"error": "Invalid request method"}, status=405)

# Update the event like function to handle post likes
@csrf_exempt
def toggle_event_like(request):
    """
    Like or unlike an event or post
    Expected JSON:
        pass
    {
        "username": "johndoe",
        "event_id": "<event-uuid>",
        "post_id": null  # optional, if liking a specific post rather than the event
    }
    """
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            username = data.get("username")
            event_id = data.get("event_id")
            post_id = data.get("post_id")  # This is optional

            # Validate input
            if not username or not event_id:
                return JsonResponse({"error": "Missing required fields"}, status=400)

            # Fetch user and event
            user = User.objects.get(username=username)
            event = StudyEvent.objects.get(id=uuid.UUID(event_id))

            # Check if this is a post like or an event like
            if post_id:
                # This is a post like - modify this to fit your models
                # For simplicity, we're just assuming there's a CommentLike model
                try:
                    comment = EventComment.objects.get(id=post_id)
                    existing_like = EventLike.objects.filter(
                        user=user, 
                        event=event,
                        comment=comment
                    )
                    
                    if existing_like.exists():
                        # Unlike
                        existing_like.delete()
                        liked = False
                    else:
                        # Like
                        EventLike.objects.create(
                            user=user, 
                            event=event,
                            comment=comment
                        )
                        liked = True
                        
                    # Get total likes for this post
                    total_likes = EventLike.objects.filter(
                        event=event,
                        comment=comment
                    ).count()
                    
                except EventComment.DoesNotExist:
                    return JsonResponse({"error": "Post not found"}, status=404)
                
            else:
                # This is an event like
                existing_like = EventLike.objects.filter(
                    user=user, 
                    event=event,
                    comment__isnull=True
                )

                if existing_like.exists():
                    # Unlike
                    existing_like.delete()
                    liked = False
                else:
                    # Like
                    EventLike.objects.create(
                        user=user, 
                        event=event
                    )
                    liked = True
                
                # Get total likes for the event
                total_likes = EventLike.objects.filter(
                    event=event,
                    comment__isnull=True
                ).count()

            return JsonResponse({
                "success": True,
                "liked": liked,
                "total_likes": total_likes
            })

        except User.DoesNotExist:
            return JsonResponse({"error": "User not found"}, status=404)
        except StudyEvent.DoesNotExist:
            return JsonResponse({"error": "Event not found"}, status=404)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)
    
    return JsonResponse({"error": "Invalid request method"}, status=405)


from django.http import JsonResponse
from django.contrib.auth.models import User

def perform_auto_matching(event_id, max_invites=10, radius_km=10.0, min_interest_match=1):
    """Helper function to perform auto-matching logic with better performance"""
    from myapp.models import StudyEvent, UserProfile, EventInvitation
    from django.db.models import Q, F
    
    try:
        # Get the event with a prefetch for existing invitations
        event = StudyEvent.objects.select_related('host').prefetch_related(
            'invited_friends', 'attendees'
        ).get(id=event_id)
    except StudyEvent.DoesNotExist:
        return {"error": "Event not found"}, 404
    
    # Get event details needed for matching
    event_host = event.host
    event_interests = event.get_interest_tags()
    
    if not event_interests:
        return {"error": "Event has no interest tags for matching"}, 400
    
    # Get the IDs of users who are already invited or attending
    already_involved_ids = set()
    already_involved_ids.add(event_host.id)
    already_involved_ids.update(event.invited_friends.values_list('id', flat=True))
    already_involved_ids.update(event.attendees.values_list('id', flat=True))
    
    # Find all potential users in one query - this avoids multiple queries in a loop
    potential_users = UserProfile.objects.filter(
        auto_invite_enabled=True
    ).exclude(
        user__id__in=already_involved_ids
    ).select_related('user').prefetch_related('interest_items')
    
    # Filter to matching profiles with at least one common interest
    matched_profiles = []
    
    # Use batch processing for better performance
    batch_size = 100
    for i in range(0, potential_users.count(), batch_size):
        batch = potential_users[i:i+batch_size]
        for profile in batch:
            user_interests = profile.get_interests()
            
            # Skip users with no interests
            if not user_interests:
                continue
            
            # Calculate interest overlap - this is still in Python but on a smaller set
            matching_interests = set(user_interests).intersection(set(event_interests))
            
            # Skip if not enough match
            if len(matching_interests) < min_interest_match:
                continue
            
            # Calculate match score - more matching interests = higher score
            match_score = len(matching_interests) * 10
            
            matched_profiles.append({
                "profile": profile,
                "user": profile.user,
                "match_score": match_score,
                "matching_interests": list(matching_interests)
            })
    
    # Sort by match score
    matched_profiles.sort(key=lambda x: x["match_score"], reverse=True)
    
    # Limit to max_invites
    matched_profiles = matched_profiles[:max_invites]
    
    # Process invitations in a single transaction for performance
    invites_sent = 0
    matched_users = []
    
    with transaction.atomic():
        # Bulk create the invitations
        invitation_objs = []
        user_ids_to_invite = []
        
        for match in matched_profiles:
            user = match["user"]
            user_ids_to_invite.append(user.id)
            invitation_objs.append(
                EventInvitation(
                    event=event,
                    user=user,
                    is_auto_matched=True
                )
            )
            
            matched_users.append({
                "username": user.username,
                "match_score": match["match_score"],
                "matching_interests": match["matching_interests"],
                "invited": True
            })
            invites_sent += 1
        
        # Bulk add to M2M relationship
        if user_ids_to_invite:
            # Add all users to invited_friends in one operation
            event.invited_friends.add(*user_ids_to_invite)
            
            # Bulk create invitations
            if invitation_objs:
                # Skip any that would violate constraints
                EventInvitation.objects.bulk_create(
                    invitation_objs, 
                    ignore_conflicts=True
                )
    
    return {
        "success": True,
        "matched_users": matched_users,
        "total_invites_sent": invites_sent,
        "message": f"Successfully matched and invited {invites_sent} users"
    }, 200


import json
import uuid
import logging
from datetime import timedelta
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.models import User
from django.utils import timezone
from django.db.models import Count, Q
from .models import StudyEvent, UserProfile

# Configure logging
logger = logging.getLogger(__name__)

def text_similarity(text1, text2):
    """Simple text similarity based on word overlap"""
    if not text1 or not text2:
        return 0.0
    
    # Convert to lowercase and split by spaces
    words1 = set(text1.lower().split())
    words2 = set(text2.lower().split())
    
    # Calculate Jaccard similarity
    intersection = len(words1.intersection(words2))
    union = len(words1.union(words2))
    
    if union == 0:
        return 0.0
    return intersection / union

def calculate_distance(lat1, lon1, lat2, lon2):
    """
    Calculate distance between two coordinates using Haversine formula
    Returns distance in kilometers
    """
    from math import radians, sin, cos, sqrt, atan2
    
    # Convert to radians
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    
    # Haversine formula
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * atan2(sqrt(a), sqrt(1-a))
    r = 6371  # Radius of Earth in kilometers
    
    return r * c

@csrf_exempt
def advanced_auto_match(request):
    """
    🔧 ENHANCED: Sophisticated auto-matching system using all available user data
    Matches users based on interests, skills, bio, academic info, reputation, and more
    """
    if request.method != "POST":
        return JsonResponse({"error": "Method not allowed"}, status=405)
    
    try:
        # Parse input
        data = json.loads(request.body)
        event_id = data.get("event_id")
        max_invites = int(data.get("max_invites", 10))
        min_score = float(data.get("min_score", 30.0))  # Increased default minimum
        potentials_only = data.get("potentials_only", False)
        
        
        if not event_id:
            return JsonResponse({"error": "Event ID is required"}, status=400)
        
        # Get the event with all related data
        try:
            event = StudyEvent.objects.select_related('host', 'host__userprofile').prefetch_related(
                'invited_friends', 'attendees', 'invitation_records'
            ).get(id=uuid.UUID(event_id))
        except (StudyEvent.DoesNotExist, ValueError):
            return JsonResponse({"error": "Event not found"}, status=404)
        
        # Get event details for enhanced matching
        event_interests = event.get_interest_tags() if hasattr(event, 'get_interest_tags') else []
        event_title = event.title
        event_description = event.description or ""
        event_content = f"{event_title} {event_description}"
        event_type = event.event_type
        event_time = event.time
        event_lat = event.latitude
        event_lon = event.longitude
        
        if not event_interests:
            return JsonResponse({
                "success": False,
                "message": "Event has no interest tags for matching",
                "matched_users": []
            })
        
        # Get users to exclude (host, already invited, attendees, declined)
        excluded_user_ids = set()
        excluded_user_ids.add(event.host.id)
        excluded_user_ids.update(event.invited_friends.values_list('id', flat=True))
        excluded_user_ids.update(event.attendees.values_list('id', flat=True))
        excluded_user_ids.update(
            DeclinedInvitation.objects.filter(event=event).values_list('user_id', flat=True)
        )
        
        # Get potential users with auto-invite enabled and all related data
        potential_users = User.objects.filter(
            userprofile__auto_invite_enabled=True
        ).exclude(
            id__in=excluded_user_ids
        ).select_related(
            'userprofile', 'reputation_stats', 'reputation_stats__trust_level'
        ).prefetch_related(
            'userprofile__friends'
        )
        
        # Define enhanced scoring weights
        WEIGHTS = {
            'interest_match': 25.0,
            'interest_ratio': 30.0,
            'content_similarity': 20.0,
            'location': 15.0,
            'social': 20.0,
            'academic_similarity': 25.0,
            'skill_relevance': 20.0,
            'bio_similarity': 15.0,
            'reputation_boost': 15.0,
            'event_type_preference': 10.0,
            'time_compatibility': 10.0,
            'activity_level': 10.0,
        }
        
        # Get host's friends for social relevance
        host_friends = set(event.host.userprofile.friends.values_list('user_id', flat=True))
        
        # Calculate enhanced matches
        matched_users = []
        
        for user in potential_users:
            try:
                profile = user.userprofile
                
                # Initialize score components
                score_components = {
                    'interest_match': 0,
                    'interest_ratio': 0,
                    'content_similarity': 0,
                    'location': 0,
                    'social': 0,
                    'academic_similarity': 0,
                    'skill_relevance': 0,
                    'bio_similarity': 0,
                    'reputation_boost': 0,
                    'event_type_preference': 0,
                    'time_compatibility': 0,
                    'activity_level': 0
                }
                
                # Get user interests
                user_interests = profile.get_interests()
                
                if not user_interests:
                    continue
                
                # 1. INTEREST MATCHING (Enhanced)
                matching_interests = set(user_interests).intersection(set(event_interests))
                
                if event_interests:
                    interest_match_count = len(matching_interests)
                    interest_match_ratio = interest_match_count / len(event_interests)
                    
                    score_components['interest_match'] = interest_match_count * WEIGHTS['interest_match']
                    score_components['interest_ratio'] = interest_match_ratio * WEIGHTS['interest_ratio']
                
                # 2. CONTENT SIMILARITY
                user_content = " ".join(user_interests)
                if event_content and user_content:
                    content_similarity_score = text_similarity(event_content, user_content)
                    score_components['content_similarity'] = content_similarity_score * WEIGHTS['content_similarity']
                
                # 3. LOCATION RELEVANCE
                if hasattr(profile, 'preferred_radius'):
                    user_location = get_user_recent_location(user)
                    if user_location:
                        distance_km = calculate_distance(
                            event_lat, event_lon, 
                            user_location['lat'], user_location['lon']
                        )
                        
                        max_distance = profile.preferred_radius * 3
                        if distance_km <= profile.preferred_radius:
                            location_score = 1.0
                        elif distance_km <= max_distance:
                            location_score = 1.0 - ((distance_km - profile.preferred_radius) / (max_distance - profile.preferred_radius)) ** 2
                        else:
                            location_score = 0.0
                            
                        score_components['location'] = location_score * WEIGHTS['location']
                
                # 4. SOCIAL RELEVANCE
                user_friends = set(profile.friends.values_list('user_id', flat=True))
                
                if user.id in host_friends:
                    social_score = 1.0
                else:
                    mutual_friends = len(user_friends.intersection(host_friends))
                    if mutual_friends > 0:
                        social_score = min(1.0, (mutual_friends / 3.0) ** 0.5)
                    else:
                        social_score = 0.0
                
                score_components['social'] = social_score * WEIGHTS['social']
                
                # 5. ACADEMIC SIMILARITY
                academic_score = 0.0
                
                if profile.university and event.host.userprofile.university:
                    if profile.university.lower() == event.host.userprofile.university.lower():
                        academic_score += 0.4
                    elif any(word in profile.university.lower() for word in event.host.userprofile.university.lower().split()):
                        academic_score += 0.2
                
                if profile.degree and event.host.userprofile.degree:
                    degree_similarity = text_similarity(profile.degree.lower(), event.host.userprofile.degree.lower())
                    academic_score += degree_similarity * 0.3
                
                if profile.year and event.host.userprofile.year:
                    try:
                        user_year = int(profile.year.split()[0])
                        host_year = int(event.host.userprofile.year.split()[0])
                        year_diff = abs(user_year - host_year)
                        
                        if year_diff == 0:
                            academic_score += 0.3
                        elif year_diff == 1:
                            academic_score += 0.2
                        elif year_diff == 2:
                            academic_score += 0.1
                    except:
                        pass
                
                score_components['academic_similarity'] = academic_score * WEIGHTS['academic_similarity']
                
                # 6. SKILL RELEVANCE
                skill_score = 0.0
                user_skills = profile.get_skills()
                
                if user_skills and event_content:
                    event_words = set(event_content.lower().split())
                    
                    for skill_name, skill_level in user_skills.items():
                        skill_words = skill_name.lower().split()
                        
                        if any(word in event_words for word in skill_words):
                            level_scores = {
                                'BEGINNER': 0.3,
                                'INTERMEDIATE': 0.6,
                                'ADVANCED': 0.8,
                                'EXPERT': 1.0
                            }
                            skill_score += level_scores.get(skill_level, 0.3)
                    
                    skill_score = min(1.0, skill_score / 3.0)
                
                score_components['skill_relevance'] = skill_score * WEIGHTS['skill_relevance']
                
                # 7. BIO SIMILARITY
                bio_score = 0.0
                if profile.bio and event_content:
                    bio_similarity = text_similarity(profile.bio.lower(), event_content.lower())
                    bio_score = bio_similarity
                
                score_components['bio_similarity'] = bio_score * WEIGHTS['bio_similarity']
                
                # 8. REPUTATION BOOST
                reputation_score = 0.0
                try:
                    reputation_stats = user.reputation_stats
                    if reputation_stats:
                        if reputation_stats.trust_level:
                            level_boost = min(1.0, reputation_stats.trust_level.level / 5.0)
                            reputation_score += level_boost * 0.5
                        
                        if reputation_stats.average_rating > 0:
                            rating_boost = min(1.0, (reputation_stats.average_rating - 3.0) / 2.0)
                            reputation_score += max(0, rating_boost) * 0.3
                        
                        total_events = reputation_stats.events_hosted + reputation_stats.events_attended
                        activity_boost = min(1.0, total_events / 10.0)
                        reputation_score += activity_boost * 0.2
                except:
                    pass
                
                score_components['reputation_boost'] = reputation_score * WEIGHTS['reputation_boost']
                
                # 9. EVENT TYPE PREFERENCE
                event_type_score = 0.0
                try:
                    hosted_events = StudyEvent.objects.filter(host=user)
                    attended_events = StudyEvent.objects.filter(attendees=user)
                    
                    type_counts = {}
                    for evt in list(hosted_events) + list(attended_events):
                        evt_type = evt.event_type
                        type_counts[evt_type] = type_counts.get(evt_type, 0) + 1
                    
                    total_events = sum(type_counts.values())
                    if total_events > 0:
                        current_type_count = type_counts.get(event_type, 0)
                        event_type_score = current_type_count / total_events
                except:
                    pass
                
                score_components['event_type_preference'] = event_type_score * WEIGHTS['event_type_preference']
                
                # 10. TIME COMPATIBILITY
                time_score = 0.0
                try:
                    user_events = StudyEvent.objects.filter(
                        models.Q(host=user) | models.Q(attendees=user)
                    ).order_by('-time')[:10]
                    
                    if user_events:
                        event_hour = event_time.hour
                        compatible_events = 0
                        
                        for evt in user_events:
                            evt_hour = evt.time.hour
                            if abs(evt_hour - event_hour) <= 3:
                                compatible_events += 1
                        
                        time_score = compatible_events / len(user_events)
                except:
                    pass
                
                score_components['time_compatibility'] = time_score * WEIGHTS['time_compatibility']
                
                # 11. ACTIVITY LEVEL
                activity_score = 0.0
                try:
                    from datetime import timedelta
                    thirty_days_ago = timezone.now() - timedelta(days=30)
                    
                    recent_hosted = StudyEvent.objects.filter(
                        host=user, time__gte=thirty_days_ago
                    ).count()
                    
                    recent_attended = StudyEvent.objects.filter(
                        attendees=user, time__gte=thirty_days_ago
                    ).count()
                    
                    total_recent = recent_hosted + recent_attended
                    activity_score = min(1.0, total_recent / 5.0)
                except:
                    pass
                
                score_components['activity_level'] = activity_score * WEIGHTS['activity_level']
                
                # Calculate total match score
                total_score = sum(score_components.values())
                
                # Only include if score meets minimum
                if total_score >= min_score:
                    matched_users.append({
                        "user_id": user.id,
                        "username": user.username,
                        "match_score": round(total_score, 2),
                        "matching_interests": list(matching_interests),
                        "interest_ratio": round(interest_match_ratio, 2) if 'interest_match_ratio' in locals() else 0.0,
                        "score_breakdown": {k: round(v, 2) for k, v in score_components.items()},
                        "invited": False
                    })
                    
            except Exception as e:
                continue
        
        # Sort by match score (highest first)
        matched_users.sort(key=lambda x: x["match_score"], reverse=True)
        
        # Limit to max_invites
        top_matches = matched_users[:max_invites]
        
        
        # If potentials_only, just return the matches
        if potentials_only:
            return JsonResponse({
                "success": True,
                "potential_matches": top_matches,
                "total_potential_matches": len(matched_users),
                "event_id": str(event.id),
                "event_title": event.title
            })
        
        # Send invitations
        successful_invites = 0
        
        try:
            with transaction.atomic():
                for match in top_matches:
                    try:
                        user = User.objects.get(id=match["user_id"])
                        
                        # Add to invited friends
                        event.invited_friends.add(user)
                        
                        # Create invitation record
                        EventInvitation.objects.create(
                            event=event,
                            user=user,
                            is_auto_matched=True
                        )
                        
                        match["invited"] = True
                        successful_invites += 1
                        
                    except Exception as e:
                        match["invited"] = False
                        match["error"] = str(e)
                
        except Exception as e:
            return JsonResponse({"error": f"Failed to process invitations: {str(e)}"}, status=500)
        
        return JsonResponse({
            "success": True,
            "message": f"Enhanced auto-matching completed. Sent {successful_invites} invitations.",
            "matched_users": top_matches,
            "total_invites_sent": successful_invites,
            "event_id": str(event.id),
            "event_title": event.title
        })
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


def get_user_recent_location(user):
    """Get a user's recent location based on their event attendance history"""
    # Try to get location from most recent event created by user
    recent_host_event = StudyEvent.objects.filter(
        host=user
    ).order_by('-time').first()
    
    if recent_host_event:
        return {
            'lat': recent_host_event.latitude,
            'lon': recent_host_event.longitude
        }
    
    # Try to get location from most recent event attended by user
    recent_attended_event = user.attending_study_events.order_by('-time').first()
    
    if recent_attended_event:
        return {
            'lat': recent_attended_event.latitude,
            'lon': recent_attended_event.longitude
        }
    
    # Default to None if no location data is available
    return None


def send_bulk_invitation_notifications(user_ids, event):
    """Send invitation notifications to multiple users efficiently"""
    try:
        # Get all devices for the users in one query
        devices = Device.objects.filter(
            user_id__in=user_ids, 
            is_active=True
        ).select_related('user')
        
        # Group devices by user
        devices_by_user = {}
        for device in devices:
            if device.user_id not in devices_by_user:
                devices_by_user[device.user_id] = []
            devices_by_user[device.user_id].append(device)
        
        # Prepare notification data
        notification_data = {
            'event_id': str(event.id),
            'event_title': event.title,
            'host': event.host.username
        }
        
        # Send notifications (in reality, you would batch these through a message queue)
        for user_id, user_devices in devices_by_user.items():
            try:
                send_push_notification(
                    user_id=user_id,
                    notification_type='event_invitation',
                    **notification_data
                )
            except Exception as e:
                pass
                
    except Exception as e:
        # Continue execution even if notifications fail
        pass


"""
Auto-matched users endpoint for the PinIt app.
Add this function to your Django backend's views.py file.
"""
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import User, StudyEvent, EventInvitation

def get_auto_matched_users(request, event_id):
    """
    Get users who were auto-matched for a specific event.
    
    Parameters:
        pass
    - event_id: The UUID of the event to check
    
    Returns:
        pass
    JSON response with a list of usernames that were auto-matched.
    """
    try:
        # Get the event
        event = StudyEvent.objects.get(id=event_id)
        
        # Get all auto-matched invitations for this event
        auto_matched_invitations = EventInvitation.objects.filter(
            event=event,
            is_auto_matched=True
        )
        
        # Extract the usernames
        auto_matched_users = [invitation.user.username for invitation in auto_matched_invitations]
        
        return JsonResponse({
            'success': True,
            'event_id': event_id,
            'auto_matched_users': auto_matched_users,
            'count': len(auto_matched_users)
        })
        
    except StudyEvent.DoesNotExist:
        return JsonResponse({
            'success': False,
            'error': f'Event with ID {event_id} not found'
        }, status=404)
        
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)

# Add this to your urls.py file:
    pass
"""
Add this code to your Django view function that gets invitations to debug the auto-matching issue.
Insert it at the beginning of the get_invitations function.
"""

# Push Notification Views
@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def register_device(request):
    """
    Register a device for push notifications
    """
    try:
        token = request.data.get('device_token')
        device_type = request.data.get('device_type')
        
        if not token or not device_type:
            return Response({'error': 'Missing device token or type'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Update or create device record
        device, created = Device.objects.update_or_create(
            token=token,
            defaults={
                'user': request.user,
                'device_type': device_type,
                'is_active': True
            }
        )
        
        return Response({'message': 'Device registered successfully'}, status=status.HTTP_201_CREATED)
    
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# Function to send push notifications
def send_push_notification(user_id, notification_type, **kwargs):
    """
    Send push notification to a specific user
    
    Parameters:
        pass
    - user_id: User ID to send notification to
    - notification_type: Type of notification (event_invitation, event_update, etc.)
    - **kwargs: Additional data for notification
    """
    try:
        # Get user's devices
        devices = Device.objects.filter(user_id=user_id, is_active=True)
        
        if not devices.exists():
            return
        
        # Prepare notification payload
        payload = {
            'type': notification_type,
            **kwargs
        }
        
        # Send to each device based on type
        for device in devices:
            if device.device_type == 'ios':
                try:
                    # APNSDevice is already imported at the top
                    apns_device, created = APNSDevice.objects.get_or_create(
                        registration_id=device.token,
                        defaults={'user_id': user_id}
                    )
                    
                    # Create appropriate title and message based on notification type
                    title = "StudyCon"
                    message = "You have a new notification"
                    
                    if notification_type == 'event_invitation':
                        event_title = kwargs.get('event_title', 'an event')
                        message = f"You've been invited to {event_title}"
                    elif notification_type == 'event_update':
                        event_title = kwargs.get('event_title', 'an event')
                        message = f"{event_title} has been updated"
                    elif notification_type == 'event_cancellation':
                        event_title = kwargs.get('event_title', 'an event')
                        message = f"{event_title} has been cancelled"
                    elif notification_type == 'new_attendee':
                        event_title = kwargs.get('event_title', 'your event')
                        attendee_name = kwargs.get('attendee_name', 'Someone')
                        message = f"{attendee_name} joined your event: {event_title}"
                    
                    # Send notification
                    apns_device.send_message(
                        message=message,
                        extra=payload,
                        sound="default",
                        badge=1
                    )
                    
                except Exception as e:
                    pass
            
            elif device.device_type == 'android':
                # Implementation for FCM (Android) would go here
                pass
                
    except Exception as e:
        pass

# Update the accept_invitation function to send notification to event host

def accept_invitation(request, invitation_id):
    try:
        invitation = EventInvitation.objects.get(id=invitation_id)
        
        # Make sure the invitation is for the user making the request
        if invitation.user != request.user:
            return JsonResponse({
                'success': False,
                'message': 'You are not authorized to accept this invitation'
            }, status=403)
        
        # Accept the invitation
        invitation.status = 'accepted'
        invitation.save()
        
        # Add the user to the event's attendees
        event = invitation.event
        event.add_attendee(request.user)
        
        # Send a push notification to the event host
        try:
            host = event.host  # Get the event host user
            send_push_notification(
                user_id=host.id,
                notification_type='new_attendee',
                event_id=str(event.id),
                event_title=event.title,
                attendee_name=request.user.username
            )
        except Exception as e:
            pass
        
        return JsonResponse({
            'success': True,
            'message': 'Invitation accepted'
        })
    except EventInvitation.DoesNotExist:
        return JsonResponse({
            'success': False,
            'message': 'Invitation not found'
        }, status=404)
    except Exception as e:
        return JsonResponse({
            'success': False,
            'message': str(e)
        }, status=400)

@csrf_exempt
def invite_to_event(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            event_id = data.get("event_id")
            username = data.get("username")
            is_auto_matched = data.get("mark_as_auto_matched", False)  # Get auto-matched flag
            
            
            # Get the event and user
            try:
                event = StudyEvent.objects.get(id=uuid.UUID(event_id))
                user = User.objects.get(username=username)
            except StudyEvent.DoesNotExist:
                return JsonResponse({"error": "Event not found"}, status=404)
            except User.DoesNotExist:
                return JsonResponse({"error": "User not found"}, status=404)
            except ValueError:
                return JsonResponse({"error": "Invalid event ID format"}, status=400)
            
            # Use the convenience method to invite
            event.invite_user(user, is_auto_matched)
            
            # Create invitation
            invitation = EventInvitation.objects.create(
                event=event,
                user=user,
                inviter=request.user
            )
            
            # Send a push notification about the invitation
            try:
                send_push_notification(
                    user_id=user.id,
                    notification_type='event_invitation',
                    event_id=str(event.id),
                    event_title=event.title,
                    inviter=request.user.username
                )
            except Exception as e:
                pass
            
            return JsonResponse({
                "success": True,
                "message": f"User {username} invited to event successfully",
                "is_auto_matched": is_auto_matched
            })
            
        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON data"}, status=400)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)
    
    return JsonResponse({"error": "Invalid request method"}, status=405)

@csrf_exempt
def update_user_interests(request):
    """
    Update a user's profile with basic info, interests, skills, and preferences
    
    Expected JSON payload:
        pass
    {
        "username": "username",
        "full_name": "Full Name",
        "university": "University Name",
        "degree": "Degree Program",
        "year": "Academic Year",
        "bio": "User bio description",
        "interests": ["interest1", "interest2", ...],
        "skills": {"skill1": "BEGINNER", "skill2": "ADVANCED", ...},
        "auto_invite_preference": true,
        "preferred_radius": 10.0
    }
    """
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            username = data.get("username")
            
            # Basic profile information
            full_name = data.get("full_name", "")
            university = data.get("university", "")
            degree = data.get("degree", "")
            year = data.get("year", "")
            bio = data.get("bio", "")
            
            # Smart matching preferences
            interests = data.get("interests", [])
            skills = data.get("skills", {})
            auto_invite_preference = data.get("auto_invite_preference", True)
            preferred_radius = data.get("preferred_radius", 10.0)
            
            
            # Find the user
            try:
                user = User.objects.get(username=username)
            except User.DoesNotExist:
                return JsonResponse({"error": "User not found"}, status=404)
            
            # Get or create the user profile
            profile, created = UserProfile.objects.get_or_create(user=user)
            
            # Update basic profile information
            profile.full_name = full_name
            profile.university = university
            profile.degree = degree
            profile.year = year
            profile.bio = bio
            
            # Update smart matching preferences
            if hasattr(profile, 'set_interests'):
                profile.set_interests(interests)
            
            if hasattr(profile, 'set_skills'):
                profile.set_skills(skills)
            
            if hasattr(profile, 'auto_invite_enabled'):
                profile.auto_invite_enabled = auto_invite_preference
            
            if hasattr(profile, 'preferred_radius'):
                profile.preferred_radius = preferred_radius
            
            # Save the profile
            profile.save()
            
            
            return JsonResponse({
                "success": True,
                "message": "User profile updated successfully"
            })
            
        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON data"}, status=400)
        except Exception as e:
            import traceback
            traceback.print_exc()
            return JsonResponse({"error": str(e)}, status=500)
    
    return JsonResponse({"error": "Invalid request method"}, status=405)

@csrf_exempt
def submit_user_rating(request):
    """
    Submit a rating for another user based on Bandura's social learning theory.
    
    Expected JSON payload:
        pass
    {
        "from_username": "username",
        "to_username": "username",
        "event_id": "optional-event-id",  # Optional UUID of the study event
        "rating": 5,  # Integer between 1-5
        "reference": "Optional reference text"  # Optional feedback
    }
    """
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            from_username = data.get("from_username")
            to_username = data.get("to_username")
            event_id = data.get("event_id")
            rating = data.get("rating")
            reference = data.get("reference", "")
            
            
            # Validate required fields
            if not from_username or not to_username or rating is None:
                return JsonResponse({"error": "Missing required fields"}, status=400)
            
            # Validate rating value
            try:
                rating = int(rating)
                if rating < 1 or rating > 5:
                    raise ValueError("Rating must be between 1 and 5")
            except (ValueError, TypeError):
                return JsonResponse({"error": "Rating must be a number between 1 and 5"}, status=400)
            
            # Find the users
            try:
                from_user = User.objects.get(username=from_username)
                to_user = User.objects.get(username=to_username)
            except User.DoesNotExist:
                return JsonResponse({"error": "User not found"}, status=404)
            
            # Prevent self-rating
            if from_user == to_user:
                return JsonResponse({"error": "You cannot rate yourself"}, status=400)
            
            # Find the event if an ID was provided
            event = None
            if event_id:
                try:
                    event = StudyEvent.objects.get(id=event_id)
                except StudyEvent.DoesNotExist:
                    return JsonResponse({"error": "Event not found"}, status=404)
            
            # Create or update the rating
            try:
                user_rating, created = UserRating.objects.update_or_create(
                    from_user=from_user,
                    to_user=to_user,
                    event=event,
                    defaults={
                        'rating': rating,
                        'reference': reference
                    }
                )
                
                # The save method in UserRating will handle stat updates
                
                return JsonResponse({
                    "success": True,
                    "message": f"Rating {'submitted' if created else 'updated'} successfully",
                    "rating_id": str(user_rating.id)
                })
                
            except Exception as e:
                import traceback
                traceback.print_exc()
                return JsonResponse({"error": str(e)}, status=500)
        
        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON data"}, status=400)
        except Exception as e:
            import traceback
            traceback.print_exc()
            return JsonResponse({"error": str(e)}, status=500)
    
    return JsonResponse({"error": "Invalid request method"}, status=405)

def get_user_reputation(request, username):
    """
    Get reputation statistics for a user including trust level and rating average.
    This supports Bandura's social learning theory by providing visible feedback.
    """
    try:
        user = User.objects.get(username=username)
        
        # Get or create reputation stats
        reputation, created = UserReputationStats.objects.get_or_create(user=user)
        
        # Always update stats to ensure they're current
        reputation.update_event_counts()
        reputation.update_trust_level()
        
            
        # Build response data
        data = {
            "username": user.username,
            "total_ratings": reputation.total_ratings,
            "average_rating": float(round(reputation.average_rating, 2)),
            "events_hosted": reputation.events_hosted,
            "events_attended": reputation.events_attended,
            "trust_level": {
                "level": reputation.trust_level.level if reputation.trust_level else 0,
                "title": reputation.trust_level.title if reputation.trust_level else "Unrated"
            }
        }
        
        return JsonResponse(data)
        
    except User.DoesNotExist:
        return JsonResponse({"error": "User not found"}, status=404)
    except Exception as e:
        import traceback
        traceback.print_exc()
        return JsonResponse({"error": str(e)}, status=500)

def get_user_ratings(request, username):
    """
    Get detailed ratings for a user, both given and received.
    This supports Bandura's social learning theory by providing feedback and modeling.
    """
    try:
        user = User.objects.get(username=username)
        
        # Get ratings received and given by the user
        from myapp.models import UserRating
        ratings_received = UserRating.objects.filter(to_user=user).order_by('-created_at')
        ratings_given = UserRating.objects.filter(from_user=user).order_by('-created_at')
        
        # Format ratings data
        def format_rating(rating):
            return {
                "id": str(rating.id),
                "from_username": rating.from_user.username,
                "to_username": rating.to_user.username,
                "rating": rating.rating,
                "reference": rating.reference if rating.reference else "",
                "event_id": str(rating.event.id) if rating.event else None,
                "event_title": rating.event.title if rating.event else None,
                "created_at": rating.created_at.isoformat()
            }
        
        data = {
            "username": user.username,
            "ratings_received": [format_rating(r) for r in ratings_received[:10]],  # Limit to 10 most recent
            "ratings_given": [format_rating(r) for r in ratings_given[:10]],  # Limit to 10 most recent
            "total_received": ratings_received.count(),
            "total_given": ratings_given.count()
        }
        
        return JsonResponse(data)
        
    except User.DoesNotExist:
        return JsonResponse({"error": "User not found"}, status=404)
    except Exception as e:
        import traceback
        traceback.print_exc()
        return JsonResponse({"error": str(e)}, status=500)

def get_trust_levels(request):
    """
    Get all available trust levels in the system.
    This provides visibility to Bandura's social learning reinforcement mechanism.
    """
    try:
        trust_levels = UserTrustLevel.objects.all().order_by('level')
        
        data = [{
            "level": level.level,
            "title": level.title,
            "required_ratings": level.required_ratings,
            "min_average_rating": level.min_average_rating
        } for level in trust_levels]
        
        return JsonResponse({"trust_levels": data})
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
def schedule_rating_reminder(request):
    """
    Schedule a reminder for a user to rate another user after an event.
    This supports Bandura's social learning theory by encouraging feedback.
    
    Expected JSON payload:
        pass
    {
        "event_id": "event-uuid",
        "username": "username"
    }
    """
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            event_id = data.get("event_id")
            username = data.get("username")
            
            
            # Validate required fields
            if not event_id or not username:
                return JsonResponse({"error": "Missing required fields"}, status=400)
            
            # Find the user and event
            try:
                user = User.objects.get(username=username)
                event = StudyEvent.objects.get(id=event_id)
            except (User.DoesNotExist, StudyEvent.DoesNotExist):
                return JsonResponse({"error": "User or event not found"}, status=404)
            
            # In a real implementation, this would schedule a delayed notification
            # For now, we'll just log it and pretend it's scheduled
            
            # Simulate sending a notification right away (for demo purposes)
            # In production, this would be handled by a task scheduler
            message = f"Please rate the participants from your event: {event.title}"
            send_push_notification(user.id, 'rating_reminder', event_id=str(event.id), message=message)
            
            return JsonResponse({
                "success": True,
                "message": "Rating reminder scheduled"
            })
            
        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON data"}, status=400)
        except Exception as e:
            import traceback
            traceback.print_exc()
            return JsonResponse({"error": str(e)}, status=500)
    
    return JsonResponse({"error": "Invalid request method"}, status=405)

@csrf_exempt
def get_profile_completion(request, username):
    """
    Get detailed profile completion information for a user
    
    Returns:
        pass
    {
        "completion_percentage": 75.0,
        "total_items": 12,
        "completed_items": 9,
        "missing_items": ["Bio (at least 21 characters)", "2 more skill(s)", "1 more interest(s)"],
        "category_breakdown": {
            "basic_info": {"completed": 3, "total": 4, "percentage": 75.0},
            "bio": {"completed": 0, "total": 1, "percentage": 0.0},
            "skills": {"completed": 1, "total": 3, "percentage": 33.3},
            "interests": {"completed": 2, "total": 3, "percentage": 66.7}
        },
        "benefits_message": "You're making great progress! A complete profile helps you find more relevant study partners.",
        "completion_level": "progress" // "low", "progress", "good", "complete"
    }
    """
    try:
        user = User.objects.get(username=username)
        userprofile = user.userprofile
        
        # Get profile data
        full_name = getattr(userprofile, 'full_name', '')
        university = getattr(userprofile, 'university', '')
        degree = getattr(userprofile, 'degree', '')
        year = getattr(userprofile, 'year', '')
        bio = getattr(userprofile, 'bio', '')
        interests = userprofile.get_interests() if hasattr(userprofile, 'get_interests') else []
        skills = userprofile.get_skills() if hasattr(userprofile, 'get_skills') else {}
        
        # Calculate completion metrics - simplified and intuitive
        # 4 categories, each worth 25% of total completion
        
        # Basic info (25% - all 4 fields must be complete)
        basic_info_completed = 0
        if full_name: basic_info_completed += 1
        if university: basic_info_completed += 1
        if degree: basic_info_completed += 1
        if year: basic_info_completed += 1
        basic_info_percentage = (basic_info_completed / 4.0) * 25  # 25% max
        
        # Bio (25% - must be >20 characters)
        bio_percentage = 25 if len(bio) > 20 else 0
        
        # Skills (25% - up to 3 skills, each worth ~8.33%)
        skills_count = len(skills)
        capped_skills_count = min(skills_count, 3)
        skills_percentage = (capped_skills_count / 3.0) * 25
        
        # Interests (25% - up to 3 interests, each worth ~8.33%)
        interests_count = len(interests)
        capped_interests_count = min(interests_count, 3)
        interests_percentage = (capped_interests_count / 3.0) * 25
        
        # Total completion percentage (max 100%)
        completion_percentage = basic_info_percentage + bio_percentage + skills_percentage + interests_percentage
        if completion_percentage > 100:
            completion_percentage = 100.0
        
        # Determine completion level
        if completion_percentage < 30:
            completion_level = "low"
        elif completion_percentage < 60:
            completion_level = "progress"
        elif completion_percentage < 90:
            completion_level = "good"
        else:
            completion_level = "complete"
        
        # Generate missing items list
        missing_items = []
        if not full_name: missing_items.append("Full Name")
        if not university: missing_items.append("University")
        if not degree: missing_items.append("Degree Program")
        if not year: missing_items.append("Academic Year")
        if len(bio) <= 20: missing_items.append("Bio (at least 21 characters)")
        if skills_count < 3: missing_items.append(f"{3 - skills_count} more skill(s)")
        if interests_count < 3: missing_items.append(f"{3 - interests_count} more interest(s)")
        
        # Generate benefits message
        if completion_percentage < 30:
            benefits_message = "Complete your profile to unlock better auto-matching and build trust with other students!"
        elif completion_percentage < 60:
            benefits_message = "You're making great progress! A complete profile helps you find more relevant study partners."
        elif completion_percentage < 90:
            benefits_message = "Almost there! A complete profile increases your matching accuracy and event recommendations."
        else:
            benefits_message = "Excellent! Your complete profile ensures optimal auto-matching and event suggestions."
        
        # Category breakdown (cap at 100%)
        category_breakdown = {
            "basic_info": {
                "completed": basic_info_completed,
                "total": 4,
                "percentage": min((basic_info_completed / 4.0) * 100, 100)
            },
            "bio": {
                "completed": 1 if bio_percentage > 0 else 0,
                "total": 1,
                "percentage": 100 if bio_percentage > 0 else 0
            },
            "skills": {
                "completed": skills_count,
                "total": 3,
                "percentage": min((skills_count / 3.0) * 100, 100)
            },
            "interests": {
                "completed": interests_count,
                "total": 3,
                "percentage": min((interests_count / 3.0) * 100, 100)
            }
        }
        
        return JsonResponse({
            "completion_percentage": round(completion_percentage, 1),
            "total_items": 12,
            "completed_items": basic_info_completed + (bio_percentage > 0) + (skills_percentage > 0) + (interests_percentage > 0),
            "missing_items": missing_items,
            "category_breakdown": category_breakdown,
            "benefits_message": benefits_message,
            "completion_level": completion_level
        })
        
    except User.DoesNotExist:
        return JsonResponse({"error": "User not found"}, status=404)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# MARK: - PinIt User Preferences and Settings API Endpoints

@csrf_exempt
def get_user_preferences(request, username):
    """
    Get user preferences and settings for PinIt
    
    Returns:
        pass
    {
        "matching_preferences": {
            "allow_auto_matching": true,
            "preferred_radius": 10.0,
            "interests": ["Study Groups", "Language Exchange"],
            "skills": ["Programming", "Design"],
            "preferred_event_types": ["study", "cultural"],
            "age_range": "18-25",
            "university": "University of Buenos Aires",
            "degree": "Computer Science",
            "year": "Junior"
        },
        "privacy_settings": {
            "show_online_status": true,
            "allow_tagging": true,
            "allow_direct_messages": true,
            "show_activity_status": true
        },
        "notification_settings": {
            "enable_notifications": true,
            "event_reminders": true,
            "friend_requests": true,
            "event_invitations": true,
            "rating_notifications": true
        },
        "app_settings": {
            "dark_mode": false,
            "accent_color": "Blue",
            "font_size": "Medium",
            "language": "English"
        }
    }
    """
    try:
        user = User.objects.get(username=username)
        userprofile = user.userprofile
        
        # Get matching preferences
        matching_preferences = {
            "allow_auto_matching": getattr(userprofile, 'auto_invite_enabled', True),
            "preferred_radius": getattr(userprofile, 'preferred_radius', 10.0),
            "interests": userprofile.get_interests() if hasattr(userprofile, 'get_interests') else [],
            "skills": list(userprofile.get_skills().keys()) if hasattr(userprofile, 'get_skills') else [],
            "preferred_event_types": [],  # This would need to be added to the model
            "age_range": "18-25",  # This would need to be added to the model
            "university": getattr(userprofile, 'university', ''),
            "degree": getattr(userprofile, 'degree', ''),
            "year": getattr(userprofile, 'year', '')
        }
        
        # Get privacy settings (these would be stored in a separate model or JSON field)
        privacy_settings = {
            "show_online_status": True,
            "allow_tagging": True,
            "allow_direct_messages": True,
            "show_activity_status": True
        }
        
        # Get notification settings (these would be stored in a separate model or JSON field)
        notification_settings = {
            "enable_notifications": True,
            "event_reminders": True,
            "friend_requests": True,
            "event_invitations": True,
            "rating_notifications": True
        }
        
        # Get app settings (these would be stored in a separate model or JSON field)
        app_settings = {
            "dark_mode": False,
            "accent_color": "Blue",
            "font_size": "Medium",
            "language": "English"
        }
        
        return JsonResponse({
            "matching_preferences": matching_preferences,
            "privacy_settings": privacy_settings,
            "notification_settings": notification_settings,
            "app_settings": app_settings
        })
        
    except User.DoesNotExist:
        return JsonResponse({"error": "User not found"}, status=404)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
def update_user_preferences(request, username):
    """
    Update user preferences and settings for PinIt
    
    Expected JSON payload:
        pass
    {
        "matching_preferences": {
            "allow_auto_matching": true,
            "preferred_radius": 10.0,
            "interests": ["Study Groups", "Language Exchange"],
            "skills": ["Programming", "Design"],
            "preferred_event_types": ["study", "cultural"],
            "age_range": "18-25",
            "university": "University of Buenos Aires",
            "degree": "Computer Science",
            "year": "Junior"
        },
        "privacy_settings": {
            "show_online_status": true,
            "allow_tagging": true,
            "allow_direct_messages": true,
            "show_activity_status": true
        },
        "notification_settings": {
            "enable_notifications": true,
            "event_reminders": true,
            "friend_requests": true,
            "event_invitations": true,
            "rating_notifications": true
        },
        "app_settings": {
            "dark_mode": false,
            "accent_color": "Blue",
            "font_size": "Medium",
            "language": "English"
        }
    }
    """
    try:
        user = User.objects.get(username=username)
        userprofile = user.userprofile
        
        if request.method != 'POST':
            return JsonResponse({"error": "Only POST method allowed"}, status=405)
        
        data = json.loads(request.body)
        
        # Update matching preferences
        if 'matching_preferences' in data:
            prefs = data['matching_preferences']
            
            if 'allow_auto_matching' in prefs:
                userprofile.auto_invite_enabled = prefs['allow_auto_matching']
            
            if 'preferred_radius' in prefs:
                userprofile.preferred_radius = float(prefs['preferred_radius'])
            
            if 'interests' in prefs:
                userprofile.set_interests(prefs['interests'])
            
            if 'skills' in prefs:
                # Convert list to dict with default skill level
                skills_dict = {skill: 'INTERMEDIATE' for skill in prefs['skills']}
                userprofile.set_skills(skills_dict)
            
            if 'university' in prefs:
                userprofile.university = prefs['university']
            
            if 'degree' in prefs:
                userprofile.degree = prefs['degree']
            
            if 'year' in prefs:
                userprofile.year = prefs['year']
        
        # Save the profile
        userprofile.save()
        
        return JsonResponse({
            "message": "Preferences updated successfully",
            "status": "success"
        })
        
    except User.DoesNotExist:
        return JsonResponse({"error": "User not found"}, status=404)
    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
def get_matching_preferences(request, username):
    """
    Get detailed matching preferences for PinIt auto-matching
    
    Returns:
        pass
    {
        "allow_auto_matching": true,
        "preferred_radius": 10.0,
        "interests": ["Study Groups", "Language Exchange"],
        "skills": ["Programming", "Design"],
        "preferred_event_types": ["study", "cultural"],
        "age_range": "18-25",
        "university": "University of Buenos Aires",
        "degree": "Computer Science",
        "year": "Junior",
        "matching_score_threshold": 0.7
    }
    """
    try:
        user = User.objects.get(username=username)
        userprofile = user.userprofile
        
        return JsonResponse({
            "allow_auto_matching": getattr(userprofile, 'auto_invite_enabled', True),
            "preferred_radius": getattr(userprofile, 'preferred_radius', 10.0),
            "interests": userprofile.get_interests() if hasattr(userprofile, 'get_interests') else [],
            "skills": list(userprofile.get_skills().keys()) if hasattr(userprofile, 'get_skills') else [],
            "preferred_event_types": [],  # This would need to be added to the model
            "age_range": "18-25",  # This would need to be added to the model
            "university": getattr(userprofile, 'university', ''),
            "degree": getattr(userprofile, 'degree', ''),
            "year": getattr(userprofile, 'year', ''),
            "matching_score_threshold": 0.7  # This would need to be added to the model
        })
        
    except User.DoesNotExist:
        return JsonResponse({"error": "User not found"}, status=404)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
def update_matching_preferences(request, username):
    """
    Update matching preferences for PinIt auto-matching
    
    Expected JSON payload:
        pass
    {
        "allow_auto_matching": true,
        "preferred_radius": 10.0,
        "interests": ["Study Groups", "Language Exchange"],
        "skills": ["Programming", "Design"],
        "preferred_event_types": ["study", "cultural"],
        "age_range": "18-25",
        "university": "University of Buenos Aires",
        "degree": "Computer Science",
        "year": "Junior",
        "matching_score_threshold": 0.7
    }
    """
    try:
        user = User.objects.get(username=username)
        userprofile = user.userprofile
        
        if request.method != 'POST':
            return JsonResponse({"error": "Only POST method allowed"}, status=405)
        
        data = json.loads(request.body)
        
        # Update matching preferences
        if 'allow_auto_matching' in data:
            userprofile.auto_invite_enabled = data['allow_auto_matching']
        
        if 'preferred_radius' in data:
            userprofile.preferred_radius = float(data['preferred_radius'])
        
        if 'interests' in data:
            userprofile.set_interests(data['interests'])
        
        if 'skills' in data:
            # Convert list to dict with default skill level
            skills_dict = {skill: 'INTERMEDIATE' for skill in data['skills']}
            userprofile.set_skills(skills_dict)
        
        if 'university' in data:
            userprofile.university = data['university']
        
        if 'degree' in data:
            userprofile.degree = data['degree']
        
        if 'year' in data:
            userprofile.year = data['year']
        
        # Save the profile
        userprofile.save()
        
        return JsonResponse({
            "message": "Matching preferences updated successfully",
            "status": "success"
        })
        
    except User.DoesNotExist:
        return JsonResponse({"error": "User not found"}, status=404)
    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

# Auto-matching fix deployed Wed Oct  1 12:27:33 -03 2025
