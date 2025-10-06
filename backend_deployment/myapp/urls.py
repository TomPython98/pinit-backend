from django.contrib import admin
from django.urls import path
from . import views

urlpatterns = [
    path("admin/", admin.site.urls),
    path('api/register-device/', views.register_device, name='register_device'),
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
    path('api/user_image/<str:image_id>/serve/', views.serve_image, name='serve_image'),
    path('api/debug/r2-status/', views.debug_r2_status, name='debug_r2_status'),
    path('api/run-migration/', views.run_migration, name='run_migration'),
]

