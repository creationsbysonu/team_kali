from django.contrib import admin
from .models import ServiceCategory, Service, ServiceStaff


@admin.register(ServiceCategory)
class ServiceCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'ministry', 'is_active', 'display_order', 'service_count']
    list_filter = ['is_active', 'ministry']
    search_fields = ['name', 'slug']
    prepopulated_fields = {'slug': ('name',)}


@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = ['name', 'ministry', 'category', 'service_type', 'is_active', 'is_published']
    list_filter = ['is_active', 'is_published', 'service_type', 'ministry']
    search_fields = ['name', 'slug', 'description']
    prepopulated_fields = {'slug': ('name',)}


@admin.register(ServiceStaff)
class ServiceStaffAdmin(admin.ModelAdmin):
    list_display = ['user', 'service', 'get_ministry', 'is_active', 'created_at']
    list_filter = ['is_active', 'service__ministry']
    search_fields = ['user__email', 'service__name']
    
    def get_ministry(self, obj):
        return obj.service.ministry.name
    get_ministry.short_description = 'Ministry'
