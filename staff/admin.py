from django.contrib import admin
from .models import Staff


@admin.register(Staff)
class StaffAdmin(admin.ModelAdmin):
    list_display = ['name', 'email', 'service', 'get_ministry', 'is_active', 'created_at']
    list_filter = ['is_active', 'is_deleted', 'service__ministry']
    search_fields = ['name', 'user__email', 'contact']
    readonly_fields = ['id', 'created_at', 'updated_at']
    
    def email(self, obj):
        return obj.user.email
    email.short_description = 'Email'
    
    def get_ministry(self, obj):
        return obj.service.ministry.name
    get_ministry.short_description = 'Ministry'
