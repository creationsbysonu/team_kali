from django.contrib import admin
from .models import AttendanceRecord


@admin.register(AttendanceRecord)
class AttendanceRecordAdmin(admin.ModelAdmin):
    list_display = ['get_person_name', 'person_type', 'date', 'status', 'marked_by', 'created_at']
    list_filter = ['person_type', 'status', 'date']
    search_fields = ['staff__staff_name', 'official__name']
    readonly_fields = ['created_at', 'updated_at']
    date_hierarchy = 'date'
    
    def get_person_name(self, obj):
        if obj.person_type == AttendanceRecord.PersonType.STAFF:
            return obj.staff.staff_name if obj.staff else 'N/A'
        return obj.official.name if obj.official else 'N/A'
    get_person_name.short_description = 'Person'

