from django.contrib import admin
from .models import QueueConfiguration, DailyQueue, QueueToken, QueueEventLog, ServiceProgressStep, TokenProgress


@admin.register(QueueConfiguration)
class QueueConfigurationAdmin(admin.ModelAdmin):
    list_display = ['staff_service', 'office_start_time', 'office_end_time', 'average_service_time_minutes', 'calculated_daily_capacity', 'enable_progress_tracking', 'active']
    list_filter = ['active', 'enable_progress_tracking', 'prebooking_allowed', 'emergency_allowed']
    search_fields = ['staff_service__service_name', 'staff_service__ministry__name']
    readonly_fields = ['created_at', 'updated_at', 'calculated_daily_capacity']
    fieldsets = (
        ('Service', {
            'fields': ('staff_service', 'ministry', 'active')
        }),
        ('Office Hours', {
            'fields': ('office_start_time', 'office_end_time', 'lunch_start_time', 'lunch_end_time', 'average_service_time_minutes', 'calculated_daily_capacity')
        }),
        ('Documents', {
            'fields': ('documents_required',)
        }),
        ('Prebooking', {
            'fields': ('prebooking_allowed', 'prebooking_lead_hours', 'prebooking_quota_per_day')
        }),
        ('Emergency Booking', {
            'fields': ('emergency_allowed', 'emergency_fee', 'emergency_quota_per_day')
        }),
        ('Officials & Progress', {
            'fields': ('higher_officials', 'enable_progress_tracking')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )
    
    def calculated_daily_capacity(self, obj):
        """Display calculated daily capacity"""
        return obj.calculate_daily_capacity()
    calculated_daily_capacity.short_description = 'Daily Capacity'


@admin.register(DailyQueue)
class DailyQueueAdmin(admin.ModelAdmin):
    list_display = ['queue_config', 'date', 'next_token_number', 'created_at']
    list_filter = ['date']
    search_fields = ['queue_config__staff_service__service_name']
    readonly_fields = ['created_at']
    date_hierarchy = 'date'


@admin.register(QueueToken)
class QueueTokenAdmin(admin.ModelAdmin):
    list_display = ['token_number', 'booking_type', 'daily_queue', 'citizen', 'expected_service_time', 'emergency_fee_paid', 'no_show_count', 'active', 'created_at']
    list_filter = ['active', 'booking_type', 'no_show_count']
    search_fields = ['citizen__email', 'token_number']
    readonly_fields = ['created_at']
    date_hierarchy = 'created_at'


@admin.register(QueueEventLog)
class QueueEventLogAdmin(admin.ModelAdmin):
    list_display = ['event', 'token', 'performed_by', 'created_at']
    list_filter = ['event', 'created_at']
    search_fields = ['token__token_number', 'performed_by__email']
    readonly_fields = ['created_at']
    date_hierarchy = 'created_at'
    
    def has_add_permission(self, request):
        # Prevent manual creation
        return False
    
    def has_change_permission(self, request, obj=None):
        # Prevent modification (immutable audit log)
        return False
    
    def has_delete_permission(self, request, obj=None):
        # Prevent deletion (immutable audit log)
        return False


@admin.register(ServiceProgressStep)
class ServiceProgressStepAdmin(admin.ModelAdmin):
    list_display = ['step_order', 'title', 'queue_config', 'created_at']
    list_filter = ['queue_config']
    search_fields = ['title', 'queue_config__staff_service__service_name']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(TokenProgress)
class TokenProgressAdmin(admin.ModelAdmin):
    list_display = ['token', 'step', 'completed', 'completed_at', 'created_at']
    list_filter = ['completed', 'step']
    search_fields = ['token__token_number', 'step__title']
    readonly_fields = ['created_at']

