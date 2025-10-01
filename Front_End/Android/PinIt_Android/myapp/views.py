def get_invitations(request, username):
    """
    Returns events where the user was invited but has not yet accepted
    Includes is_auto_matched flag to differentiate direct invites from potential matches
    """
    try:
        print(f"🔍 [get_invitations] Processing invitations request for user: {username}")
        user = User.objects.get(username=username)
        
        # Get all events where user is directly invited
        direct_events = StudyEvent.objects.filter(invited_friends=user) \
                                     .exclude(attendees=user) \
                                     .exclude(host=user)
        
        print(f"📋 [get_invitations] Direct events found: {direct_events.count()}")
        for event in direct_events:
            print(f"  - Direct Invite: {event.id}: {event.title}, host: {event.host}")
        
        # Get all auto-matched events (that may not have user in invited_friends)
        auto_matched_invitations = EventInvitation.objects.filter(user=user, is_auto_matched=True)
        print(f"📋 [get_invitations] Auto-matched invitation records found: {auto_matched_invitations.count()}")
        
        for inv in auto_matched_invitations:
            print(f"  - Auto-matched Invite: {inv.event.id}: {inv.event.title}, host: {inv.event.host}")
        
        auto_matched_event_ids = [inv.event_id for inv in auto_matched_invitations]
        auto_matched_events = StudyEvent.objects.filter(id__in=auto_matched_event_ids) \
                                         .exclude(attendees=user) \
                                         .exclude(host=user)
        
        # Combine both event sets to get all events
        all_event_ids = set(direct_events.values_list('id', flat=True)) | set(auto_matched_events.values_list('id', flat=True))
        all_events = StudyEvent.objects.filter(id__in=all_event_ids)
        
        # Check for any EventInvitation records for this user that might not be included
        all_invitations = EventInvitation.objects.filter(user=user)
        print(f"📋 [get_invitations] Total invitation records found: {all_invitations.count()}")
        
        # Check EventInvitation table for this specific user
        all_invitation_records = EventInvitation.objects.filter(user=user)
        print(f"👤 [get_invitations] All invitation records for {username}:")
        for inv in all_invitation_records:
            print(f"  • Event ID: {inv.event.id}, Title: '{inv.event.title}', AutoMatched: {inv.is_auto_matched}")
        
        print(f"✅ [get_invitations] Final count: {direct_events.count()} direct invitations and {auto_matched_events.count()} auto-matched invitations for {username}")
        
        invitation_data = []
        for event in all_events:
            # Check if this is an auto-matched invitation
            try:
                invitation = EventInvitation.objects.get(event=event, user=user)
                is_auto_matched = invitation.is_auto_matched
                print(f"✓ Found invitation record for event '{event.title}', auto-matched: {is_auto_matched}")
            except EventInvitation.DoesNotExist:
                # If no invitation record exists, it's a direct invite
                is_auto_matched = False
                print(f"⚠️ No invitation record for event '{event.title}', assuming direct invite")
                
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
        print(f"❌ [get_invitations] User not found: {username}")
        return JsonResponse({"error": "User not found"}, status=404)
    except Exception as e:
        print(f"❌ [get_invitations] Error getting invitations: {str(e)}")
        import traceback
        traceback.print_exc()
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
def invite_to_event(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            event_id = data.get("event_id")
            username = data.get("username")
            is_auto_matched = data.get("mark_as_auto_matched", False)  # Get auto-matched flag
            
            print(f"🔍 [invite_to_event] Processing invitation: username={username}, event_id={event_id}, auto-matched={is_auto_matched}")
            
            # Get the event and user
            try:
                event = StudyEvent.objects.get(id=uuid.UUID(event_id))
                user = User.objects.get(username=username)
            except StudyEvent.DoesNotExist:
                print(f"❌ [invite_to_event] Event not found: {event_id}")
                return JsonResponse({"error": "Event not found"}, status=404)
            except User.DoesNotExist:
                print(f"❌ [invite_to_event] User not found: {username}")
                return JsonResponse({"error": "User not found"}, status=404)
            except ValueError:
                print(f"❌ [invite_to_event] Invalid event ID format: {event_id}")
                return JsonResponse({"error": "Invalid event ID format"}, status=400)
            
            # Check if the user is already invited
            already_invited = event.invited_friends.filter(username=username).exists()
            if already_invited:
                print(f"ℹ️ [invite_to_event] User {username} is already in invited_friends for event: {event.title}")
            
            # Check if an invitation record already exists
            invitation_exists = EventInvitation.objects.filter(event=event, user=user).exists()
            if invitation_exists:
                print(f"ℹ️ [invite_to_event] EventInvitation record already exists for {username} to event: {event.title}")
            
            # Use the convenience method to invite
            event.invite_user(user, is_auto_matched)
            print(f"✅ [invite_to_event] Added {username} to invited_friends for event: {event.title}")
            
            # Double-check that the invitation was created correctly
            # This is a verification step to ensure the invitation was properly saved
            verified = event.invited_friends.filter(username=username).exists()
            invitation_record = EventInvitation.objects.filter(event=event, user=user).exists()
            
            print(f"✓ [invite_to_event] Verification: User in invited_friends? {verified}")
            print(f"✓ [invite_to_event] Verification: EventInvitation record exists? {invitation_record}")
            
            return JsonResponse({
                "success": True,
                "message": f"User {username} invited to event successfully",
                "is_auto_matched": is_auto_matched,
                "verification": {
                    "in_invited_friends": verified,
                    "has_invitation_record": invitation_record
                }
            })
            
        except json.JSONDecodeError:
            print("❌ [invite_to_event] Invalid JSON in request body")
            return JsonResponse({"error": "Invalid JSON"}, status=400)
        except Exception as e:
            print(f"❌ [invite_to_event] Error: {str(e)}")
            import traceback
            traceback.print_exc()
            return JsonResponse({"error": str(e)}, status=500)
    
    return JsonResponse({"error": "Invalid request method"}, status=405) 