"""
Citizen Chat Admin
"""

from django.contrib import admin
from .models import ChatSession, ChatMessage


@admin.register(ChatSession)
class ChatSessionAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'status', 'message_count', 'created_at', 'last_activity']
    list_filter = ['status', 'created_at']
    search_fields = ['user__email', 'id']
    ordering = ['-last_activity']
    readonly_fields = ['id', 'created_at', 'last_activity', 'closed_at']
    
    def has_add_permission(self, request):
        return False


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display = ['session', 'role', 'short_content', 'created_at']
    list_filter = ['role', 'created_at']
    search_fields = ['content', 'session__id']
    ordering = ['-created_at']
    readonly_fields = ['id', 'session', 'role', 'content', 'metadata', 'created_at']
    
    def short_content(self, obj):
        return obj.content[:100] + '...' if len(obj.content) > 100 else obj.content
    short_content.short_description = 'Content'
    
    def has_add_permission(self, request):
        return False
    
    def has_change_permission(self, request, obj=None):
        return False
