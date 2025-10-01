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
]

