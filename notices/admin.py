"""
Notices Admin Configuration

Admin interface for Notice model.
Ministry and Service models are managed in their respective apps.
"""

from django.contrib import admin
from .models import Notice


@admin.register(Notice)
class NoticeAdmin(admin.ModelAdmin):
    list_display = [
        'title', 'ministry', 'service', 'file_type',
        'ingestion_status', 'is_active', 'created_by', 'created_at'
    ]
    list_filter = ['ministry', 'service', 'file_type', 'ingestion_status', 'is_active']
    search_fields = ['title', 'ministry__name', 'service__name']
    ordering = ['-created_at']
    readonly_fields = [
        'id', 'file_type', 'ingestion_status', 'ingestion_error',
        'ingested_at', 'created_at', 'updated_at'
    ]
    raw_id_fields = ['ministry', 'service', 'created_by']
    
    fieldsets = (
        ('Notice Information', {
            'fields': ('title', 'ministry', 'service', 'file', 'file_type')
        }),
        ('Status', {
            'fields': ('is_active', 'created_by')
        }),
        ('RAG Ingestion', {
            'fields': ('ingestion_status', 'ingestion_error', 'ingested_at'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('id', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'ministry', 'service', 'created_by'
        )
