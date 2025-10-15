from django.contrib import admin
from django.urls import path
from . import views

urlpatterns = [
    path("admin/", admin.site.urls),
    path("health/", views.health_check, name='health_check'),
    
    # Push Notification Endpoints
    path('api/register-device/', views.register_device, name='register_device'),
    path('api/test-push/', views.test_push_notification, name='test_push_notification'),
    path('api/user-devices/', views.get_user_devices, name='get_user_devices'),
    path('api/delete-device/<str:device_id>/', views.delete_device, name='delete_device'),
    path('api/debug-apns/', views.debug_apns_config, name='debug_apns_config'),
    
    path('api/profile_completion/<str:username>/', views.get_profile_completion, name='profile_completion'),
    
    # Moderation and account management
    path('change_password/', views.change_password, name='change_password'),
    path('report_content/', views.report_content, name='report_content'),
    path('block_user/', views.block_user, name='block_user'),
    path('unblock_user/', views.unblock_user, name='unblock_user'),
    path('api/delete_account/', views.delete_account, name='delete_account'),
    
    # PinIt User Preferences and Settings API Endpoints
    path('api/user_preferences/<str:username>/', views.get_user_preferences, name='get_user_preferences'),
    path('api/update_user_preferences/<str:username>/', views.update_user_preferences, name='update_user_preferences'),
    path('api/matching_preferences/<str:username>/', views.get_matching_preferences, name='get_matching_preferences'),
    path('api/update_matching_preferences/<str:username>/', views.update_matching_preferences, name='update_matching_preferences'),
    
    # Professional Image Upload Endpoints
    path('api/upload_user_image/', views.upload_user_image, name='upload_user_image'),
    path('api/user_images/<str:username>/', views.get_user_images, name='get_user_images'),
    path('api/multiple_user_images/', views.get_multiple_user_images, name='get_multiple_user_images'),
    path('api/user_image/<str:image_id>/delete/', views.delete_user_image, name='delete_user_image'),
    path('api/user_image/<str:image_id>/set_primary/', views.set_primary_image, name='set_primary_image'),
    path('api/update-existing-images/', views.update_existing_images, name='update_existing_images'),
    
    # Event Management Endpoints
    path('api/create_study_event/', views.create_study_event, name='create_study_event'),
    path('api/update_study_event/', views.update_study_event, name='update_study_event'),
    path('api/delete_study_event/', views.delete_study_event, name='delete_study_event'),
    path('api/get_study_events/<str:username>/', views.get_study_events, name='get_study_events'),
    path('api/get_event/<str:event_id>/', views.get_event_by_id, name='get_event_by_id'),
    path('api/rsvp_study_event/', views.rsvp_study_event, name='rsvp_study_event'),
    path('api/search_events/', views.search_events, name='search_events'),
    path('api/enhanced_search_events/', views.enhanced_search_events, name='enhanced_search_events'),
    
    # Event Join Request Management Endpoints
    path('api/request_to_join_event/', views.request_to_join_event, name='request_to_join_event'),
    path('api/get_event_join_requests/<str:event_id>/', views.get_event_join_requests, name='get_event_join_requests'),
    path('api/approve_join_request/', views.approve_join_request, name='approve_join_request'),
    path('api/reject_join_request/', views.reject_join_request, name='reject_join_request'),
    path('api/get_user_join_requests/<str:username>/', views.get_user_join_requests, name='get_user_join_requests'),
    
    # Chat History Endpoint
    path('api/get_chat_history/<str:username1>/<str:username2>/', views.get_chat_history, name='get_chat_history'),
]

