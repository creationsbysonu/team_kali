"""
Business logic for Unified Attendance Management (Staff + Officials).

This service handles:
- Marking attendance for staff and officials for future dates
- Retrieving attendance calendars with holiday integration
- Validating attendance rules (Saturday auto-absent, future dates only)
- Checking person availability for queue/progress operations
"""

import logging
from typing import Union
from datetime import timedelta
from django.db import transaction
from django.core.cache import cache

from .models import AttendanceRecord
from holidays.models import Holiday
from ministry.models import StaffService
from officials.models import MinistryOfficial
from core.utils.nepal_time import (
    get_nepal_today,
    is_saturday,
    get_nepal_date_range,
    is_future_date,
    is_today_or_future
)

logger = logging.getLogger(__name__)


class AttendanceService:
    """Service class for handling unified attendance business logic."""
    
    @staticmethod
    def mark_attendance(person_type, person_id, date, status, reason="", marked_by=None):
        """
        Mark attendance for a person (staff or official) for a specific future date.
        
        Args:
            person_type: 'STAFF' or 'OFFICIAL'
            person_id: UUID of staff service or ministry official
            date: Date object
            status: PRESENT or ABSENT
            reason: Optional reason for the status
            marked_by: User who is marking the attendance
            
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Validate person exists and is active
            person: Union[StaffService, MinistryOfficial]
            if person_type == AttendanceRecord.PersonType.STAFF:
                try:
                    person = StaffService.objects.get(id=person_id, is_active=True)
                    staff = person
                    official = None
                except StaffService.DoesNotExist:
                    return False, {
                        "success": False,
                        "error": "Staff service not found or inactive."
                    }, 404
            else:
                try:
                    person = MinistryOfficial.objects.get(id=person_id, is_active=True)
                    staff = None
                    official = person
                except MinistryOfficial.DoesNotExist:
                    return False, {
                        "success": False,
                        "error": "Ministry official not found or inactive."
                    }, 404
            
            # Validate today or future date (allow marking today's attendance)
            if not is_today_or_future(date):
                return False, {
                    "success": False,
                    "error": "Attendance can only be marked for today or future dates"
                }, 400
            
            # Saturday validation
            if is_saturday(date) and status == AttendanceRecord.Status.PRESENT:
                return False, {
                    "success": False,
                    "error": "Saturday is a weekly holiday. Status must be ABSENT"
                }, 400
            
            # Auto-set ABSENT for Saturdays
            if is_saturday(date):
                status = AttendanceRecord.Status.ABSENT
                if not reason:
                    reason = "Saturday - Weekly Holiday"
            
            with transaction.atomic():
                # Build filter and defaults based on person type
                filter_kwargs = {'date': date, 'person_type': person_type}
                if person_type == AttendanceRecord.PersonType.STAFF:
                    filter_kwargs['staff'] = staff
                else:
                    filter_kwargs['official'] = official
                
                # Update or create attendance record
                attendance, created = AttendanceRecord.objects.update_or_create(
                    **filter_kwargs,
                    defaults={
                        'status': status,
                        'reason': reason,
                        'marked_by': marked_by,
                    }
                )
                
                # Invalidate cache
                cache_key = f"attendance_calendar_{person_type}_{person_id}"
                cache.delete(cache_key)
            
            action = "created" if created else "updated"
            
            # Get person name based on type (use type assertion for clarity)
            if person_type == AttendanceRecord.PersonType.STAFF:
                from ministry.models import StaffService as StaffServiceType
                person_name = person.staff_name  # type: ignore[union-attr]
            else:
                from officials.models import MinistryOfficial as OfficialType
                person_name = person.name  # type: ignore[union-attr]
                
            logger.info(
                f"Attendance {action} for {person_type} {person_name} "
                f"on {date}: {status}"
            )
            
            return True, {
                "success": True,
                "data": {
                    "id": str(attendance.id),
                    "date": str(date),
                    "status": status,
                    "reason": reason,
                },
                "message": f"Attendance {action} successfully"
            }, 201 if created else 200
            
        except Exception as e:
            logger.error(f"Error marking attendance: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to mark attendance"
            }, 500
    
    @staticmethod
    def bulk_mark_attendance(person_type, person_id, start_date, end_date, status, reason="", marked_by=None):
        """
        Mark attendance for a date range.
        
        Args:
            person_type: 'STAFF' or 'OFFICIAL'
            person_id: UUID of staff service or ministry official
            start_date: Start date
            end_date: End date
            status: PRESENT or ABSENT
            reason: Optional reason
            marked_by: User marking the attendance
            
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Validate person exists and is active
            person: Union[StaffService, MinistryOfficial]
            if person_type == AttendanceRecord.PersonType.STAFF:
                try:
                    person = StaffService.objects.get(id=person_id, is_active=True)
                    staff = person
                    official = None
                except StaffService.DoesNotExist:
                    return False, {
                        "success": False,
                        "error": "Staff service not found or inactive"
                    }, 404
            else:
                try:
                    person = MinistryOfficial.objects.get(id=person_id, is_active=True)
                    staff = None
                    official = person
                except MinistryOfficial.DoesNotExist:
                    return False, {
                        "success": False,
                        "error": "Ministry official not found or inactive"
                    }, 404
            
            # Validate future date
            if not is_future_date(start_date):
                return False, {
                    "success": False,
                    "error": "Start date must be in the future"
                }, 400
            
            if end_date < start_date:
                return False, {
                    "success": False,
                    "error": "End date must be after start date"
                }, 400
            
            # Limit to prevent abuse (max 90 days)
            if (end_date - start_date).days > 90:
                return False, {
                    "success": False,
                    "error": "Date range cannot exceed 90 days"
                }, 400
            
            created_count = 0
            updated_count = 0
            
            with transaction.atomic():
                # Generate date range
                date_list = get_nepal_date_range(start_date, end_date)
                
                for current_date in date_list:
                    # Auto-set ABSENT for Saturdays
                    final_status = AttendanceRecord.Status.ABSENT if is_saturday(current_date) else status
                    final_reason = "Saturday - Weekly Holiday" if is_saturday(current_date) and not reason else reason
                    
                    # Build filter kwargs
                    filter_kwargs = {'date': current_date, 'person_type': person_type}
                    if person_type == AttendanceRecord.PersonType.STAFF:
                        filter_kwargs['staff'] = staff
                    else:
                        filter_kwargs['official'] = official
                    
                    attendance, created = AttendanceRecord.objects.update_or_create(
                        **filter_kwargs,
                        defaults={
                            'status': final_status,
                            'reason': final_reason,
                            'marked_by': marked_by,
                        }
                    )
                    
                    if created:
                        created_count += 1
                    else:
                        updated_count += 1
                
                # Invalidate cache
                cache_key = f"attendance_calendar_{person_type}_{person_id}"
                cache.delete(cache_key)
            
            # Get person name based on type (use type assertion for clarity)
            if person_type == AttendanceRecord.PersonType.STAFF:
                person_name = person.staff_name  # type: ignore[union-attr]
            else:
                person_name = person.name  # type: ignore[union-attr]
                
            logger.info(
                f"Bulk attendance marked for {person_name}: "
                f"{created_count} created, {updated_count} updated"
            )
            
            return True, {
                "success": True,
                "data": {
                    "created_count": created_count,
                    "updated_count": updated_count,
                    "total": created_count + updated_count,
                    "start_date": str(start_date),
                    "end_date": str(end_date),
                },
                "message": "Bulk attendance marked successfully"
            }, 200
            
        except Exception as e:
            logger.error(f"Error marking bulk attendance: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to mark bulk attendance"
            }, 500
    
    @staticmethod
    def get_attendance_calendar(person_type, person_id, start_date, end_date):
        """
        Get attendance calendar for a person with holiday integration.
        
        Args:
            person_type: 'STAFF' or 'OFFICIAL'
            person_id: UUID of staff service or ministry official
            start_date: Start date
            end_date: End date
            
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Validate person exists
            if person_type == AttendanceRecord.PersonType.STAFF:
                try:
                    person = StaffService.objects.get(id=person_id)
                except StaffService.DoesNotExist:
                    return False, {
                        "success": False,
                        "error": "Staff service not found"
                    }, 404
            else:
                try:
                    person = MinistryOfficial.objects.get(id=person_id)
                except MinistryOfficial.DoesNotExist:
                    return False, {
                        "success": False,
                        "error": "Ministry official not found"
                    }, 404
            
            # Check cache
            cache_key = f"attendance_calendar_{person_type}_{person_id}_{start_date}_{end_date}"
            cached_data = cache.get(cache_key)
            if cached_data:
                return True, {
                    "success": True,
                    "data": cached_data
                }, 200
            
            # Generate date range
            date_list = get_nepal_date_range(start_date, end_date)
            
            # Get attendance records for this period
            filter_kwargs = {
                'person_type': person_type,
                'date__gte': start_date,
                'date__lte': end_date
            }
            if person_type == AttendanceRecord.PersonType.STAFF:
                filter_kwargs['staff'] = person
            else:
                filter_kwargs['official'] = person
            
            attendance_records = AttendanceRecord.objects.filter(
                **filter_kwargs
            ).select_related('marked_by')
            
            attendance_dict = {record.date: record for record in attendance_records}
            
            calendar_data = []
            
            for current_date in date_list:
                # Check if it's Saturday
                is_sat = is_saturday(current_date)
                
                # Check if it's a holiday (simplified - no ministry parameter)
                is_hol, holiday_name = Holiday.is_holiday(current_date)
                
                # Get attendance record or determine default status
                attendance_record = attendance_dict.get(current_date)
                
                if attendance_record:
                    status = attendance_record.status
                    reason = attendance_record.reason
                else:
                    # Default logic: Saturday = ABSENT, else PRESENT
                    status = AttendanceRecord.Status.ABSENT if is_sat else AttendanceRecord.Status.PRESENT
                    reason = "Saturday - Weekly Holiday" if is_sat else ""
                
                calendar_data.append({
                    "date": str(current_date),
                    "status": status,
                    "status_display": "Present" if status == AttendanceRecord.Status.PRESENT else "Absent",
                    "is_saturday": is_sat,
                    "is_holiday": is_hol,
                    "holiday_name": holiday_name,
                    "reason": reason,
                    "is_available": (
                        status == AttendanceRecord.Status.PRESENT and not is_hol
                    ),
                })
            
            # Cache for 5 minutes
            cache.set(cache_key, calendar_data, timeout=300)
            
            return True, {
                "success": True,
                "data": calendar_data
            }, 200
            
        except Exception as e:
            logger.error(f"Error fetching attendance calendar: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch attendance calendar"
            }, 500
    
    @staticmethod
    def check_person_availability(person, date, person_type):
        """
        Check if a person is available on a given date.
        
        Args:
            person: StaffService or MinistryOfficial instance
            date: Date object
            person_type: AttendanceRecord.PersonType.STAFF or .OFFICIAL
            
        Returns:
            tuple: (is_available: bool, reason: str)
        """
        # Saturday check
        if is_saturday(date):
            return False, "Saturday - Weekly Holiday"
        
        # Holiday check (simplified - no ministry parameter)
        is_hol, holiday_name = Holiday.is_holiday(date)
        if is_hol:
            return False, f"Holiday: {holiday_name}"
        
        # Attendance check
        is_available = AttendanceRecord.is_person_available(person, date, person_type)
        if not is_available:
            return False, "Person marked as absent"
        
        return True, "Person available"
    
    @staticmethod
    def delete_attendance(attendance_id, user):
        """
        Delete a future attendance record.
        
        Args:
            attendance_id: UUID of attendance record
            user: User performing the deletion
            
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            try:
                attendance = AttendanceRecord.objects.get(id=attendance_id)
            except AttendanceRecord.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Attendance record not found"
                }, 404
            
            # Validate it's a future date
            if not is_future_date(attendance.date):
                return False, {
                    "success": False,
                    "error": "Cannot delete attendance for past or today's date"
                }, 400
            
            person_type = attendance.person_type
            
            # Get person_id with None checks
            if person_type == AttendanceRecord.PersonType.STAFF and attendance.staff:
                person_id = attendance.staff.id
            elif person_type == AttendanceRecord.PersonType.OFFICIAL and attendance.official:
                person_id = attendance.official.id
            else:
                return False, {
                    "success": False,
                    "error": "Invalid attendance record - missing person reference"
                }, 400
            
            with transaction.atomic():
                attendance.delete()
                
                # Invalidate cache
                cache_key = f"attendance_calendar_{person_type}_{person_id}"
                cache.delete(cache_key)
            
            logger.info(f"Attendance deleted for date {attendance.date} by {user.email}")
            
            return True, {
                "success": True,
                "message": "Attendance record deleted successfully"
            }, 200
            
        except Exception as e:
            logger.error(f"Error deleting attendance: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to delete attendance"
            }, 500
