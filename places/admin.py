"""
Places Admin Configuration

Django admin registration for Place model.
"""
from django.contrib import admin
from .models import Place


@admin.register(Place)
class PlaceAdmin(admin.ModelAdmin):
    list_display = ['name', 'slug', 'is_active', 'ministry_count', 'created_at']
    list_filter = ['is_active', 'is_deleted', 'created_at']
    search_fields = ['name', 'slug']
    prepopulated_fields = {'slug': ('name',)}
    ordering = ['name']
    readonly_fields = ['created_at', 'updated_at', 'deleted_at', 'deleted_by']
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('name', 'slug', 'is_active')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
        ('Deletion Info', {
            'fields': ('is_deleted', 'deleted_at', 'deleted_by'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return Place.all_objects.all()
    
    def ministry_count(self, obj):
        return obj.ministry_count
    ministry_count.short_description = 'Ministries'
