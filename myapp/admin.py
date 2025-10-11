from django.contrib import admin
from django.contrib.auth.models import User

from django.contrib import admin
from .models import StudyEvent, UserRating, UserTrustLevel, UserReputationStats, EventReviewReminder

@admin.register(StudyEvent)
class StudyEventAdmin(admin.ModelAdmin):
    list_display = ('title', 'time', 'id')  # or whichever fields you want

@admin.register(UserRating)
class UserRatingAdmin(admin.ModelAdmin):
    list_display = ('from_user', 'to_user', 'rating', 'event', 'created_at')
    list_filter = ('rating', 'created_at')
    search_fields = ('from_user__username', 'to_user__username', 'reference')
    date_hierarchy = 'created_at'

@admin.register(UserTrustLevel)
class UserTrustLevelAdmin(admin.ModelAdmin):
    list_display = ('level', 'title', 'required_ratings', 'min_average_rating')
    list_editable = ('title', 'required_ratings', 'min_average_rating')
    ordering = ('level',)

@admin.register(UserReputationStats)
class UserReputationStatsAdmin(admin.ModelAdmin):
    list_display = ('user', 'average_rating', 'total_ratings', 'trust_level', 'last_updated')
    list_filter = ('trust_level',)
    search_fields = ('user__username',)
    readonly_fields = ('average_rating', 'total_ratings', 'last_updated')
    date_hierarchy = 'last_updated'

@admin.register(EventReviewReminder)
class EventReviewReminderAdmin(admin.ModelAdmin):
    list_display = ('user', 'event', 'sent_at')
    list_filter = ('sent_at',)
    search_fields = ('user__username', 'event__title')
    readonly_fields = ('sent_at',)
    date_hierarchy = 'sent_at'