"""
Ministry Admin Configuration

Django admin for managing ministries, members, and staff services.
"""
from django.contrib import admin
from .models import Ministry, MinistryMember, MinistryInvitation, StaffService


@admin.register(Ministry)
class MinistryAdmin(admin.ModelAdmin):
    list_display = ['name', 'place', 'slug', 'status', 'is_deleted', 'created_at']
    list_filter = ['status', 'is_deleted', 'place', 'created_at']
    search_fields = ['name', 'slug', 'description']
    readonly_fields = ['id', 'created_at', 'updated_at', 'deleted_at']
    ordering = ['place', '-created_at']
    
    fieldsets = (
        (None, {
            'fields': ('id', 'place', 'name', 'slug', 'description', 'logo')
        }),
        ('Contact', {
            'fields': ('email', 'phone', 'address', 'website'),
        }),
        ('Status', {
            'fields': ('status', 'is_deleted', 'deleted_at', 'deleted_by')
        }),
        ('Settings', {
            'fields': ('settings',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(MinistryMember)
class MinistryMemberAdmin(admin.ModelAdmin):
    list_display = ['user', 'ministry', 'is_active', 'joined_at']
    list_filter = ['is_active', 'joined_at', 'ministry']
    search_fields = ['user__email', 'ministry__name']
    readonly_fields = ['id', 'joined_at']
    raw_id_fields = ['user', 'ministry']
    ordering = ['-joined_at']


@admin.register(MinistryInvitation)
class MinistryInvitationAdmin(admin.ModelAdmin):
    list_display = ['email', 'ministry', 'status', 'expires_at', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['email', 'ministry__name']
    readonly_fields = ['id', 'token', 'created_at']
    raw_id_fields = ['ministry', 'invited_by', 'accepted_by']
    ordering = ['-created_at']


@admin.register(StaffService)
class StaffServiceAdmin(admin.ModelAdmin):
    """Admin for Staff Services (staff login accounts with service control)"""
    list_display = ['service_name', 'staff_name', 'email', 'ministry', 'status', 'is_active', 'created_at']
    list_filter = ['status', 'is_active', 'ministry', 'created_at']
    search_fields = ['service_name', 'staff_name', 'email', 'ministry__name']
    readonly_fields = ['id', 'created_at', 'updated_at', 'password']
    raw_id_fields = ['ministry']
    ordering = ['-created_at']
    
    fieldsets = (
        ('Service Information', {
            'fields': ('id', 'ministry', 'service_name', 'service_logo')
        }),
        ('Staff Information', {
            'fields': ('staff_name', 'staff_image', 'email')
        }),
        ('Authentication', {
            'fields': ('password',),
            'description': 'Password is hashed. Use reset password in management panel.'
        }),
        ('Status Control', {
            'fields': ('status', 'is_active'),
            'description': 'Status: Ministry controls (active/paused). is_active: System-level enable/disable.'
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        return qs.select_related('ministry', 'ministry__place')
