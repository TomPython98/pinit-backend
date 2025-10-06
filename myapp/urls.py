from django.contrib import admin
from django.urls import path
from . import views

urlpatterns = [
    path("admin/", admin.site.urls),
    path('api/register-device/', views.register_device, name='register_device'),
    
    # Basic Profile Endpoints (what frontend expects)
    path('api/get_user_profile/<str:username>/', views.get_user_profile, name='get_user_profile'),
    path('api/update_user_profile/', views.update_user_profile, name='update_user_profile'),
    path('api/update_user_interests/', views.update_user_interests, name='update_user_interests'),
    
    # Profile Completion
    path('api/profile_completion/<str:username>/', views.get_profile_completion, name='profile_completion'),
    
    # PinIt User Preferences and Settings API Endpoints
    path('api/user_preferences/<str:username>/', views.get_user_preferences, name='get_user_preferences'),
    path('api/update_user_preferences/<str:username>/', views.update_user_preferences, name='update_user_preferences'),
    path('api/matching_preferences/<str:username>/', views.get_matching_preferences, name='get_matching_preferences'),
    path('api/update_matching_preferences/<str:username>/', views.update_matching_preferences, name='update_matching_preferences'),
    
    # Professional Image Upload Endpoints
    path('api/upload_user_image/', views.upload_user_image, name='upload_user_image'),
    path('api/user_images/<str:username>/', views.get_user_images, name='get_user_images'),
    path('api/user_image/<str:image_id>/delete/', views.delete_user_image, name='delete_user_image'),
    path('api/user_image/<str:image_id>/set_primary/', views.set_primary_image, name='set_primary_image'),
]

