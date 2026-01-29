"""
RAG Bridge Admin
"""

from django.contrib import admin
from .models import IngestionLog


@admin.register(IngestionLog)
class IngestionLogAdmin(admin.ModelAdmin):
    list_display = [
        'notice', 'status', 'attempt_number', 
        'started_at', 'completed_at', 'created_at'
    ]
    list_filter = ['status', 'created_at']
    search_fields = ['notice__title', 'notice__id']
    ordering = ['-created_at']
    readonly_fields = [
        'id', 'notice', 'status', 'attempt_number',
        'started_at', 'completed_at', 'error_message',
        'error_code', 'fastapi_response', 'created_at'
    ]
    
    def has_add_permission(self, request):
        return False
    
    def has_change_permission(self, request, obj=None):
        return False
