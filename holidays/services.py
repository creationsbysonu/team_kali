"""
Business logic for Holiday Management (Universal).

This service handles:
- Creating universal holidays
- Checking if a date is a holiday
- Holiday calendar generation
"""

import logging
from django.db import transaction
from django.core.cache import cache

from .models import Holiday
from core.utils.nepal_time import (
    get_nepal_today,
    get_nepal_date_range,
    is_future_date
)
from authentication.models import CustomUser

logger = logging.getLogger(__name__)


class HolidayService:
    """Service class for handling universal holiday business logic."""
    
    @staticmethod
    def create_holiday(name, date, description="", created_by=None):
        """
        Create a new universal holiday.
        
        Args:
            name: Holiday name
            date: Date object
            description: Optional description
            created_by: User creating the holiday (CustomUser, Ministry, or StaffService)
            
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Validate future date
            if not is_future_date(date):
                return False, {
                    "success": False,
                    "error": "Holidays can only be created for future dates"
                }, 400
            
            # Check if holiday already exists for this date
            existing = Holiday.objects.filter(date=date).first()
            if existing:
                return False, {
                    "success": False,
                    "error": "A holiday already exists on this date"
                }, 400
            
            # Only set created_by if it's a CustomUser instance
            # Ministry and StaffService objects are not compatible with the ForeignKey
            actual_created_by = created_by if isinstance(created_by, CustomUser) else None
            
            with transaction.atomic():
                holiday = Holiday.objects.create(
                    name=name,
                    date=date,
                    description=description,
                    created_by=actual_created_by,
                )
                
                # Invalidate holiday cache
                HolidayService._invalidate_holiday_cache()
            
            logger.info(f"Holiday created: {name} on {date}")
            
            return True, {
                "success": True,
                "data": {
                    "id": str(holiday.id),
                    "name": name,
                    "date": str(date),
                },
                "message": "Holiday created successfully"
            }, 201
            
        except Exception as e:
            logger.error(f"Error creating holiday: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to create holiday"
            }, 500
    
    @staticmethod
    def update_holiday(holiday_id, name=None, description=None, user=None):
        """
        Update a holiday (only name and description can be updated).
        Date is immutable.
        
        Args:
            holiday_id: UUID of holiday
            name: New name (optional)
            description: New description (optional)
            user: User performing the update
            
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            try:
                holiday = Holiday.objects.get(id=holiday_id)
            except Holiday.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Holiday not found"
                }, 404
            
            # Validate it's a future date
            if not is_future_date(holiday.date):
                return False, {
                    "success": False,
                    "error": "Cannot update holidays that have already occurred"
                }, 400
            
            with transaction.atomic():
                if name:
                    holiday.name = name
                if description is not None:  # Allow empty string
                    holiday.description = description
                
                holiday.save()
                
                # Invalidate cache
                HolidayService._invalidate_holiday_cache()
            
            logger.info(f"Holiday updated: {holiday.name} by {getattr(user, 'email', str(user)) if user else 'System'}")
            
            return True, {
                "success": True,
                "data": {
                    "id": str(holiday.id),
                    "name": holiday.name,
                    "description": holiday.description,
                },
                "message": "Holiday updated successfully"
            }, 200
            
        except Exception as e:
            logger.error(f"Error updating holiday: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to update holiday"
            }, 500
    
    @staticmethod
    def delete_holiday(holiday_id, user):
        """
        Delete a future holiday.
        
        Args:
            holiday_id: UUID of holiday
            user: User performing the deletion
            
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            try:
                holiday = Holiday.objects.get(id=holiday_id)
            except Holiday.DoesNotExist:
                return False, {
                    "success": False,
                    "error": "Holiday not found"
                }, 404
            
            # Validate it's a future date
            if not is_future_date(holiday.date):
                return False, {
                    "success": False,
                    "error": "Cannot delete holidays that have already occurred"
                }, 400
            
            holiday_name = holiday.name
            
            with transaction.atomic():
                holiday.delete()
                
                # Invalidate cache
                HolidayService._invalidate_holiday_cache()
            
            logger.info(f"Holiday deleted: {holiday_name} by {getattr(user, 'email', str(user))}")
            
            return True, {
                "success": True,
                "message": "Holiday deleted successfully"
            }, 200
            
        except Exception as e:
            logger.error(f"Error deleting holiday: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to delete holiday"
            }, 500
    
    @staticmethod
    def get_holidays(year=None, month=None, start_date=None, end_date=None):
        """
        Get list of holidays with optional filtering.
        
        Args:
            year: Filter by year
            month: Filter by month
            start_date: Filter by start date
            end_date: Filter by end date
            
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Build query
            queryset = Holiday.objects.select_related('created_by')
            
            if year:
                queryset = queryset.filter(date__year=year)
            
            if month:
                queryset = queryset.filter(date__month=month)
            
            if start_date:
                queryset = queryset.filter(date__gte=start_date)
            
            if end_date:
                queryset = queryset.filter(date__lte=end_date)
            
            queryset = queryset.order_by('date')
            
            holidays_data = []
            for holiday in queryset:
                holidays_data.append({
                    "id": str(holiday.id),
                    "name": holiday.name,
                    "date": str(holiday.date),
                    "description": holiday.description,
                })
            
            return True, {
                "success": True,
                "data": holidays_data,
                "count": len(holidays_data)
            }, 200
            
        except Exception as e:
            logger.error(f"Error fetching holidays: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch holidays"
            }, 500
    
    @staticmethod
    def get_holiday_calendar(start_date, end_date):
        """
        Get calendar view of holidays for a date range.
        
        Args:
            start_date: Start date
            end_date: End date
            
        Returns:
            tuple: (success: bool, response_data: dict, status_code: int)
        """
        try:
            # Generate date range
            date_list = get_nepal_date_range(start_date, end_date)
            
            # Get holidays for this period
            queryset = Holiday.objects.filter(
                date__gte=start_date,
                date__lte=end_date
            )
            
            # Group holidays by date
            holidays_by_date = {}
            for holiday in queryset:
                date_str = str(holiday.date)
                if date_str not in holidays_by_date:
                    holidays_by_date[date_str] = []
                
                holidays_by_date[date_str].append({
                    "id": str(holiday.id),
                    "name": holiday.name,
                    "description": holiday.description,
                })
            
            calendar_data = []
            for current_date in date_list:
                date_str = str(current_date)
                holidays = holidays_by_date.get(date_str, [])
                
                calendar_data.append({
                    "date": date_str,
                    "is_holiday": len(holidays) > 0,
                    "holidays": holidays,
                })
            
            return True, {
                "success": True,
                "data": calendar_data
            }, 200
            
        except Exception as e:
            logger.error(f"Error fetching holiday calendar: {str(e)}")
            return False, {
                "success": False,
                "error": "Failed to fetch holiday calendar"
            }, 500
    
    @staticmethod
    def _invalidate_holiday_cache():
        """Invalidate holiday cache globally."""
        cache.delete("holidays_all")
