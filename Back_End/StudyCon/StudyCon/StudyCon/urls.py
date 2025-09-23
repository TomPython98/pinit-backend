from django.urls import path
from myapp import views
from django.contrib import admin


urlpatterns = [
    # User endpoints
    path("api/register/", views.register_user, name="register"),
    path("api/login/", views.login_user, name="login"),
    path("api/logout/", views.logout_user, name="logout"),
    path("api/get_all_users/", views.get_all_users, name="get_all_users"),
    
    # Friend requests
    path("api/send_friend_request/", views.send_friend_request, name="send_friend_request"),
    path("api/accept_friend_request/", views.accept_friend_request, name="accept_friend_request"),
    path("api/get_pending_requests/<str:username>/", views.get_pending_requests, name="get_pending_requests"),
    path("api/get_sent_requests/<str:username>/", views.get_sent_requests, name="get_sent_requests"),
    path("api/get_friends/<str:username>/", views.get_friends, name="get_friends"),
    
    # StudyEvent endpoints
    path("api/create_study_event/", views.create_study_event, name="create_study_event"),
    path("api/get_study_events/<str:username>/", views.get_study_events, name="get_study_events"),
    path("api/rsvp_study_event/", views.rsvp_study_event, name="rsvp_study_event"),
    path("api/delete_study_event/", views.delete_study_event, name="delete_study_event"),
    
    # Invitation endpoints
    path("api/decline_invitation/", views.decline_invitation, name="decline_invitation"),
    path("api/get_invitations/<str:username>/", views.get_invitations, name="get_invitations"),
    
    # User profile and certification
    path("api/get_user_profile/<str:username>/", views.get_user_profile, name="get_user_profile"),
    path("api/certify_user/", views.certify_user, name="certify_user"),
    
    # Event search
    path("api/search_events/", views.search_events, name="search_events"),
    path('api/enhanced_search_events/', views.enhanced_search_events, name='enhanced_search_events'),
 
    # Event social interactions - UPDATED to match Swift implementation
    path("api/events/comment/", views.add_event_comment, name="add_event_comment"),
    path("api/events/like/", views.toggle_event_like, name="toggle_event_like"),
    path("api/events/share/", views.record_event_share, name="record_event_share"),
    path("api/events/interactions/<str:event_id>/", views.get_event_interactions, name="get_event_interactions"),
    
    # NEW: Feed endpoint to match Swift implementation
    path("api/events/feed/<str:event_id>/", views.get_event_feed, name="get_event_feed"),
    
    # Admin and Chat endpoints
    path("admin/", admin.site.urls),
    path("chat/<str:room_name>/", views.chat_room, name="chat_room"),


    path('api/get_user_profile/<str:username>/', views.get_user_profile, name='get_user_profile'),
    
    path('api/update_user_interests/', views.update_user_interests, name='update_user_interests'),
    #path('api/auto_match_event/', views.auto_match_event, name='auto_match_event'),
    path('api/advanced_auto_match/', views.advanced_auto_match, name='advanced_auto_match'),

    path('invite_to_event/', views.invite_to_event, name='invite_to_event'),
     path('api/get_auto_matched_users/<str:event_id>/', views.get_auto_matched_users, name='get_auto_matched_users'),

    # NEW: User Rating and Reputation endpoints for Bandura's social learning theory implementation
    path('api/submit_user_rating/', views.submit_user_rating, name='submit_user_rating'),
    path('api/get_user_reputation/<str:username>/', views.get_user_reputation, name='get_user_reputation'),
    path('api/get_user_ratings/<str:username>/', views.get_user_ratings, name='get_user_ratings'),
    path('api/get_trust_levels/', views.get_trust_levels, name='get_trust_levels'),
    path('api/schedule_rating_reminder/', views.schedule_rating_reminder, name='schedule_rating_reminder'),
    
    # NEW: Profile completion endpoint
    path('api/profile_completion/<str:username>/', views.get_profile_completion, name='profile_completion'),
]




