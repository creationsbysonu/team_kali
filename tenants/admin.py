"""
Tenants Admin Configuration

Django admin for managing ministries and staff.
"""
from django.contrib import admin
from .models import Tenant, TenantMember, TenantInvitation


@admin.register(Tenant)
class TenantAdmin(admin.ModelAdmin):
    list_display = ['name', 'slug', 'status', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['name', 'slug', 'description']
    readonly_fields = ['id', 'created_at', 'updated_at']
    ordering = ['-created_at']
    
    fieldsets = (
        (None, {
            'fields': ('id', 'name', 'slug', 'description', 'logo')
        }),
        ('Status', {
            'fields': ('status',)
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


@admin.register(TenantMember)
class TenantMemberAdmin(admin.ModelAdmin):
    list_display = ['user', 'tenant', 'is_active', 'joined_at']
    list_filter = ['is_active', 'joined_at']
    search_fields = ['user__email', 'tenant__name']
    readonly_fields = ['id', 'joined_at']
    raw_id_fields = ['user', 'tenant']
    ordering = ['-joined_at']


@admin.register(TenantInvitation)
class TenantInvitationAdmin(admin.ModelAdmin):
    list_display = ['email', 'tenant', 'status', 'expires_at', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['email', 'tenant__name']
    readonly_fields = ['id', 'token', 'created_at']
    raw_id_fields = ['tenant', 'invited_by', 'accepted_by']
    ordering = ['-created_at']
