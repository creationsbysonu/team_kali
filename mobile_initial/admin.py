"""
Django Admin Configuration for Mobile Initial App
"""
from django.contrib import admin
from .models import CitizenProfile


@admin.register(CitizenProfile)
class CitizenProfileAdmin(admin.ModelAdmin):
    """Admin interface for Citizen Profiles"""
    
    list_display = [
        'full_name',
        'user_email',
        'place',
        'is_profile_complete',
        'created_at'
    ]
    
    list_filter = [
        'is_profile_complete',
        'place',
        'created_at'
    ]
    
    search_fields = [
        'full_name',
        'user__email',
        'place__name'
    ]
    
    readonly_fields = [
        'id',
        'created_at',
        'updated_at',
        'is_profile_complete'
    ]
    
    fieldsets = (
        ('User Information', {
            'fields': ('user', 'full_name')
        }),
        ('Location', {
            'fields': ('place',)
        }),
        ('Status', {
            'fields': ('is_profile_complete',)
        }),
        ('Metadata', {
            'fields': ('id', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def user_email(self, obj):
        return obj.user.email
    user_email.short_description = 'Email'
    user_email.admin_order_field = 'user__email'
