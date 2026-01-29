from django.contrib import admin
from .models import MinistryOfficial


@admin.register(MinistryOfficial)
class MinistryOfficialAdmin(admin.ModelAdmin):
    list_display = ['name', 'role', 'ministry', 'is_active', 'created_at']
    list_filter = ['is_active', 'role', 'ministry']
    search_fields = ['name', 'role', 'ministry__name']
    readonly_fields = ['created_at', 'updated_at']
    list_per_page = 50

