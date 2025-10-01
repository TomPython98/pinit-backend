

from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json
from .models import FriendRequest
from .models import UserProfile



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
        print(f"🔍 Fetching friends for user: {username}")
        
        # Get the user
        user = User.objects.get(username=username)
        
        # Get the user's friends
        friends = list(user.userprofile.friends.values_list("user__username", flat=True))
        
        # Log the found friends
        print(f"✅ Found {len(friends)} friends for {username}: {friends}")
        
        return JsonResponse({"friends": friends})
    except User.DoesNotExist:
        print(f"❌ User not found: {username}")
        return JsonResponse({"friends": []})
    except Exception as e:
        print(f"❌ Error fetching friends for {username}: {str(e)}")
        return JsonResponse({"error": str(e)}, status=500)
        
from django.http import JsonResponse
from django.contrib.auth.models import User
from myapp.models import FriendRequest

def get_pending_requests(request, username):
    try:
        user = User.objects.get(username=username)

        # ✅ Filter only requests that are **still pending**
        pending_requests = FriendRequest.objects.filter(to_user=user).values_list("from_user__username", flat=True)
        print("Pending Requests",pending_requests)
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
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            from_username = data.get("from_user")
            to_username = data.get("to_user")

            print(f"🔍 Processing friend request acceptance: {from_username} -> {to_username}")

            # ✅ Fetch users
            from_user = User.objects.get(username=from_username)
            to_user = User.objects.get(username=to_username)

            # ✅ Fetch friend request
            friend_request = FriendRequest.objects.filter(from_user=from_user, to_user=to_user).first()
            if not friend_request:
                print(f"❌ Friend request not found from {from_username} to {to_username}")
                return JsonResponse({"error": "Friend request not found"}, status=404)

            # ✅ Fetch or create user profiles
            from_user_profile, _ = UserProfile.objects.get_or_create(user=from_user)
            to_user_profile, _ = UserProfile.objects.get_or_create(user=to_user)

            # ✅ Add to friends list (both directions)
            from_user_profile.friends.add(to_user_profile)
            to_user_profile.friends.add(from_user_profile)

            # ✅ Verify the friendship was created correctly
            from_friends = list(from_user_profile.friends.all().values_list('user__username', flat=True))
            to_friends = list(to_user_profile.friends.all().values_list('user__username', flat=True))
            
            print(f"✅ {from_username}'s friends: {from_friends}")
            print(f"✅ {to_username}'s friends: {to_friends}")

            # ✅ Confirm database save
            from_user_profile.save()
            to_user_profile.save()

            # ✅ Delete friend request and confirm deletion
            friend_request.delete()
            if not FriendRequest.objects.filter(from_user=from_user, to_user=to_user).exists():
                print(f"✅ Friend request deleted successfully for {from_username} -> {to_username}")

            return JsonResponse({
                "success": True, 
                "message": f"{from_username} and {to_username} are now friends.",
                "from_user_friends": from_friends,
                "to_user_friends": to_friends
            }, status=200)

        except User.DoesNotExist as e:
            print(f"❌ User not found error: {str(e)}")
            return JsonResponse({"error": "User not found"}, status=404)
        except json.JSONDecodeError:
            print("❌ Invalid JSON data")
            return JsonResponse({"error": "Invalid JSON data"}, status=400)
        except Exception as e:
            print(f"❌ Unexpected error: {str(e)}")
            return JsonResponse({"error": str(e)}, status=500)

    return JsonResponse({"error": "Invalid request method."}, status=405)



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
# ✅ Create a new study event
@csrf_exempt
def create_study_event(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            host = get_object_or_404(User, username=data.get("host"))

            if data.get("is_public", True) and not host.userprofile.is_certified:
                return JsonResponse({"error": "Only certified users can create public events."}, status=403)
            
            event = StudyEvent.objects.create(
                title=data.get("title"),
                description=data.get("description", ""),
                host=host,
                latitude=data.get("latitude"),
                longitude=data.get("longitude"),
                time=datetime.fromisoformat(data.get("time")),
                end_time=datetime.fromisoformat(data.get("end_time")),
                is_public=data.get("is_public", True),
                event_type=data.get("event_type", "other"),
            )

            invited_friends = data.get("invited_friends", [])
            for friend in invited_friends:
                friend_user = User.objects.get(username=friend)
                event.invited_friends.add(friend_user)

            event.save()
            return JsonResponse({"success": True, "event_id": str(event.id)}, status=201)

        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)


from django.contrib.auth.models import User
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone  # Add this import
from .models import StudyEvent, DeclinedInvitation  # Add DeclinedInvitation

@csrf_exempt
def get_study_events(request, username):
    try:
        user = User.objects.get(username=username)
        friend_list = list(user.userprofile.friends.values_list("user__username", flat=True))
        
        # Get the basic sets of events
        public_events = StudyEvent.objects.filter(is_public=True)
        friend_events = StudyEvent.objects.filter(host__username__in=friend_list)
        user_events = StudyEvent.objects.filter(host=user)
        
        # Combine events
        events = (public_events | friend_events | user_events).distinct()
        
        # Get IDs of events that the user has declined
        declined_event_ids = DeclinedInvitation.objects.filter(user=user).values_list('event_id', flat=True)
        
        # Exclude events that have been declined
        events = events.exclude(id__in=declined_event_ids)
        
        # Exclude events where the user is only invited but has not accepted
        filtered_events = []
        for event in events:
            # Skip events where user is only invited but not attending and not the host
            if event.invited_friends.filter(username=username).exists() and \
               not event.attendees.filter(username=username).exists() and \
               event.host.username != username:
                continue
                
            # Also skip events that have already ended
            if event.end_time <= timezone.now():
                continue
                
            filtered_events.append(event)
        
        # Format event data for response
        event_data = []
        for event in filtered_events:
            # Check if event_type is None and provide a default
            event_type = event.event_type
            if event_type is None or event_type == "":
                event_type = "other"
            
            print(f"DEBUG: Processing event {event.id} - Type: {event_type}")
            
            event_data.append({
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
                "event_type": event_type.lower(),  # Ensure it's always lowercase
                "invitedFriends": list(event.invited_friends.values_list("username", flat=True)),
                "attendees": list(event.attendees.values_list("username", flat=True)),
            })
        return JsonResponse({"events": event_data}, safe=False)
    except User.DoesNotExist:
        return JsonResponse({"error": "User not found"}, status=404)
    except Exception as e:
        print(f"ERROR in get_study_events: {str(e)}")
        return JsonResponse({"error": str(e)}, status=500)

        
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
        print("Request Body:", request.body.decode('utf-8'))
        try:
            data = json.loads(request.body)
            username = data.get("username")
            event_id = data.get("event_id")

            # Convert the event_id to lowercase and ensure it's a valid UUID
            try:
                event_uuid = uuid.UUID(event_id.lower())
                print(f"Converted event_id: {event_uuid}")
            except ValueError:
                print("Invalid event_id format")
                return JsonResponse({"error": "Invalid event_id format"}, status=400)

            # Try to fetch the event using the UUID
            try:
                event = StudyEvent.objects.get(id=event_uuid)
                print(f"Fetched event: {event}")
                print(f"Event type: {event.event_type}")  # Add this debug line
            except StudyEvent.DoesNotExist:
                print(f"StudyEvent with ID {event_uuid} not found.")
                return JsonResponse({"error": "Event not found"}, status=404)

            # Fetch user
            user = User.objects.get(username=username)
            print(f"Fetched user: {user.username}")

            # Check if the user is already an attendee
            if user in event.attendees.all():
                print(f"{user.username} is already attending the event, removing...")
                event.attendees.remove(user)  # Leave event
                event_data = {
                    "id": str(event.id),
                    "title": event.title,
                    "event_type": event.event_type.lower(),  # Ensure lowercase
                    # Include other relevant fields
                }
                return JsonResponse({
                    "success": True, 
                    "message": "Left the event",
                    "event": event_data
                }, status=200)
            else:
                print(f"{user.username} is not attending the event, adding...")
                event.attendees.add(user)  # Join event
                
                # IMPORTANT FIX: Remove user from invited_friends when they join
                if user in event.invited_friends.all():
                    print(f"Also removing {user.username} from invited_friends since they've accepted")
                    event.invited_friends.remove(user)
                
                event_data = {
                    "id": str(event.id),
                    "title": event.title,
                    "event_type": event.event_type.lower(),  # Ensure lowercase
                    # Include other relevant fields
                }
                return JsonResponse({
                    "success": True, 
                    "message": "Joined the event",
                    "event": event_data
                }, status=200)

        except User.DoesNotExist:
            print("User not found.")
            return JsonResponse({"error": "User not found"}, status=404)
        except ValueError:
            print("Invalid event_id format.")
            return JsonResponse({"error": "Invalid event_id format"}, status=400)

    return JsonResponse({"error": "Invalid request method"}, status=405)

@csrf_exempt
def delete_study_event(request):
    """
    POST request with JSON:
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

        event.delete()
        return JsonResponse({"success": True, "message": "Event deleted successfully"}, status=200)

    return JsonResponse({"error": "Invalid request method"}, status=405)


def get_user_profile(request, username):
    try:
        user = User.objects.get(username=username)
        certified = user.userprofile.is_certified
        return JsonResponse({
            "username": user.username,
            "is_certified": certified
        })
    except User.DoesNotExist:
        return JsonResponse({"error": "User not found"}, status=404)

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


from sentence_transformers import SentenceTransformer
import numpy as np

def semantic_search(query, events):
    model = SentenceTransformer('all-MiniLM-L6-v2')
    
    # Embed query and events
    query_embedding = model.encode(query)
    event_embeddings = [model.encode(event.title + " " + (event.description or "")) for event in events]
    
    # Compute similarities
    similarities = [np.dot(query_embedding, emb) for emb in event_embeddings]
    
    # Rank events by similarity
    ranked_events = sorted(zip(events, similarities), key=lambda x: x[1], reverse=True)
    
    return [event for event, _ in ranked_events[:5]]  # Top 5 semantically similar events


from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
import json
from django.contrib.auth.models import User

from django.core.cache import cache
from django.db.models import Q
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import StudyEvent
import json
import uuid
import numpy as np
from sentence_transformers import SentenceTransformer

# Load the model once at the module level
MODEL = SentenceTransformer('all-MiniLM-L6-v2')

def get_event_embedding(event):
    """
    Returns the embedding for an event's title and description.
    Caches the embedding to avoid re-computation.
    """
    cache_key = f'event_embedding_{event.id}'
    embedding = cache.get(cache_key)
    if embedding is None:
        text = f"{event.title} {event.description or ''}"
        embedding = MODEL.encode(text, convert_to_numpy=True)
        cache.set(cache_key, embedding, timeout=3600)  # Cache for 1 hour
    return embedding

def semantic_search(query, events):
    """
    Performs semantic search over the given events based on the query.
    Returns the top 5 events ranked by cosine similarity.
    """
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

        # Use semantic search if enabled and no basic results found
        if use_semantic and query and qs.count() == 0:
            try:
                events_list = list(StudyEvent.objects.all())
                semantic_results = semantic_search(query, events_list)
                if semantic_results:
                    semantic_ids = [str(event.id) for event in semantic_results]
                    qs = StudyEvent.objects.filter(id__in=semantic_ids)
            except Exception as e:
                print(f"Semantic search error: {e}")

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
            
            print(f"🔍 Processing decline request: username={username}, event_id={event_id}")
            
            user = User.objects.get(username=username)
            event = StudyEvent.objects.get(id=event_id)
            
            # First, remove the user from invited_friends
            if user in event.invited_friends.all():
                event.invited_friends.remove(user)
                print(f"✅ Removed {username} from invited_friends")
            else:
                print(f"⚠️ {username} was not in invited_friends for this event")
            
            # Then, create a DeclinedInvitation record
            declined, created = DeclinedInvitation.objects.get_or_create(user=user, event=event)
            if created:
                print(f"✅ Created new decline record for {username} on event {event.id}")
            else:
                print(f"ℹ️ {username} had already declined event {event.id}")
                
            event.save()
            
            return JsonResponse({
                "success": True, 
                "message": "Invitation declined",
                "event_id": str(event.id)
            }, status=200)
        except User.DoesNotExist:
            print(f"❌ User not found: {username}")
            return JsonResponse({"error": "User not found"}, status=404)
        except StudyEvent.DoesNotExist:
            print(f"❌ Event not found: {event_id}")
            return JsonResponse({"error": "Event not found"}, status=404)
        except Exception as e:
            print(f"❌ Error processing decline: {str(e)}")
            return JsonResponse({"error": str(e)}, status=500)
    return JsonResponse({"error": "Invalid request method"}, status=405)


@csrf_exempt
def get_invitations(request, username):
    """
    Returns events where the user was invited but has not yet accepted (i.e. not in attendees) and is not the host.
    """
    try:
        user = User.objects.get(username=username)
        invitations = StudyEvent.objects.filter(invited_friends__username=username) \
                                        .exclude(attendees__username=username) \
                                        .exclude(host__username=username)
        invitation_data = []
        for event in invitations:
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
        print(f"RAW REQUEST BODY: {raw_body}")
        
        try:
            # Parse JSON with error handling
            try:
                data = json.loads(raw_body)
            except json.JSONDecodeError as e:
                print(f"JSON Parse Error: {e}")
                return JsonResponse({"error": f"Invalid JSON: {str(e)}"}, status=400)
                
            # Extract and validate required fields
            username = data.get("username")
            event_id = data.get("event_id")
            text = data.get("text")
            parent_id = data.get("parent_id")
            
            print(f"Comment data: username={username}, event_id={event_id}, text={text}, parent_id={parent_id}")
            
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
                print(f"User not found: {username}")
                return JsonResponse({"error": f"User '{username}' not found"}, status=404)
            
            # Parse event UUID
            try:
                event_uuid = uuid.UUID(event_id)
            except ValueError:
                print(f"Invalid UUID format: {event_id}")
                return JsonResponse({"error": f"Invalid event ID format: {event_id}"}, status=400)
            
            # Find event
            try:
                event = StudyEvent.objects.get(id=event_uuid)
            except StudyEvent.DoesNotExist:
                print(f"Event not found: {event_uuid}")
                return JsonResponse({"error": f"Event with ID {event_id} not found"}, status=404)
            
            # Handle parent comment if provided
            parent = None
            if parent_id:
                try:
                    parent = EventComment.objects.get(id=parent_id)
                except EventComment.DoesNotExist:
                    print(f"Parent comment not found: {parent_id}")
                    return JsonResponse({"error": f"Parent comment {parent_id} not found"}, status=404)
                except ValueError:
                    print(f"Invalid parent ID format: {parent_id}")
                    return JsonResponse({"error": f"Invalid parent ID format: {parent_id}"}, status=400)
            
            # Create the comment
            try:
                comment = EventComment.objects.create(
                    event=event,
                    user=user,
                    text=text,
                    parent=parent
                )
                print(f"Created comment with ID: {comment.id}")
            except Exception as e:
                print(f"Error creating comment: {e}")
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
            print(f"Unexpected error in add_event_comment: {e}")
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
        print(f"🔍 FULL LIKE REQUEST: {raw_body}")
        
        try:
            data = json.loads(raw_body)
            username = data.get("username")
            event_id = data.get("event_id")
            post_id = data.get("post_id")  # Optional

            # Comprehensive input validation
            if not username or not event_id:
                print("❌ Missing required username or event_id")
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
                print(f"❌ User not found: {username}")
                return JsonResponse({"error": "User not found"}, status=404)
            except StudyEvent.DoesNotExist:
                print(f"❌ Event not found: {event_id}")
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
                    
                    print(f"✅ Comment Like: liked={liked}, total_likes={total_likes}")
                    
                except EventComment.DoesNotExist:
                    print(f"❌ Comment not found: {post_id}")
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
                
                print(f"✅ Event Like: liked={liked}, total_likes={total_likes}")

            # Detailed response with likes information
            return JsonResponse({
                "success": True,
                "liked": liked,  # Boolean indicating if user now likes
                "total_likes": total_likes,  # Total number of likes
                "event_id": str(event_id),  # Echo back event ID for frontend reference
                "username": username  # Echo back username
            })

        except json.JSONDecodeError:
            print("❌ Invalid JSON data")
            return JsonResponse({"error": "Invalid JSON data"}, status=400)
        except Exception as e:
            print(f"❌ Unexpected error in toggle_event_like: {e}")
            import traceback
            traceback.print_exc()
            return JsonResponse({"error": str(e)}, status=500)
    
    return JsonResponse({"error": "Invalid request method"}, status=405)

@csrf_exempt
def record_event_share(request):
    """
    Record an event share
    Expected JSON:
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
                print(f"🔍 Comment {comment.id} Likes: {comment_likes}")
                
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
        print(f"🌟 Event {event_id} Total Likes: {event_likes}")

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
        print("📊 Likes Breakdown:")
        for username, likes in likes_by_user.items():
            print(f"   {username}: Event Likes = {likes['event_likes']}, Comment Likes = {likes['comment_likes']}")

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
        print(f"❌ Error in get_event_interactions: {str(e)}")
        return JsonResponse({"error": str(e)}, status=500)

# Add these functions to your views.py file

def get_event_feed(request, event_id):
    """
    Retrieve event feed data (posts, likes, shares) in the format expected by the new Swift implementation.
    This combines comments, likes, and shares into the new Posts structure.
    """
    try:
        # Convert string ID to UUID
        event = StudyEvent.objects.get(id=uuid.UUID(event_id))
        
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
            # Check if the current user liked this comment (if passed in request)
            current_user = request.GET.get('current_user', None)
            is_liked = False
            
            if current_user:
                try:
                    user = User.objects.get(username=current_user)
                    is_liked = EventLike.objects.filter(
                        user=user, 
                        event=event, 
                        comment_id=comment.id
                    ).exists()
                except User.DoesNotExist:
                    pass
            
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