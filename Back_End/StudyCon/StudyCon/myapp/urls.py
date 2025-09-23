from django.contrib import admin
from django.urls import path
from . import views

urlpatterns = [
    path("admin/", admin.site.urls),
    path('api/register-device/', views.register_device, name='register_device'),
    path('api/profile_completion/<str:username>/', views.get_profile_completion, name='profile_completion'),
]

