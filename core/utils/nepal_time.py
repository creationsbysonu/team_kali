"""
Nepal timezone utilities for handling local time operations.

Nepal follows a UTC+5:45 offset and Saturday is the weekly holiday.
"""

import pytz
from datetime import datetime, date, time, timedelta
from django.utils import timezone


# Nepal timezone constant
NEPAL_TZ = pytz.timezone('Asia/Kathmandu')


def get_nepal_now():
    """
    Get current datetime in Nepal timezone.
    
    Returns:
        datetime: Current datetime with Nepal timezone
    """
    return timezone.now().astimezone(NEPAL_TZ)


def get_nepal_today():
    """
    Get today's date in Nepal timezone.
    
    Returns:
        date: Today's date in Nepal
    """
    return get_nepal_now().date()


def convert_to_nepal_tz(dt):
    """
    Convert a datetime to Nepal timezone.
    
    Args:
        dt: datetime object (can be naive or timezone-aware)
        
    Returns:
        datetime: Datetime converted to Nepal timezone
    """
    if dt is None:
        return None
    
    # If naive, assume it's in UTC
    if timezone.is_naive(dt):
        dt = timezone.make_aware(dt, timezone=pytz.UTC)
    
    return dt.astimezone(NEPAL_TZ)


def nepal_datetime_combine(date_obj, time_obj):
    """
    Combine date and time objects into a Nepal timezone datetime.
    
    Args:
        date_obj: date object
        time_obj: time object
        
    Returns:
        datetime: Timezone-aware datetime in Nepal timezone
    """
    # Create naive datetime
    naive_dt = datetime.combine(date_obj, time_obj)
    
    # Localize to Nepal timezone
    return NEPAL_TZ.localize(naive_dt)


def is_saturday(date_obj):
    """
    Check if a given date is Saturday (Nepal's weekly holiday).
    
    Args:
        date_obj: date object
        
    Returns:
        bool: True if Saturday, False otherwise
    """
    return date_obj.weekday() == 5  # 5 = Saturday


def get_next_working_day(start_date):
    """
    Get the next working day (excluding Saturdays).
    Does not check for holidays - use HolidayService for complete validation.
    
    Args:
        start_date: date object to start from
        
    Returns:
        date: Next working day
    """
    next_day = start_date + timedelta(days=1)
    
    # Skip Saturdays
    while is_saturday(next_day):
        next_day += timedelta(days=1)
    
    return next_day


def format_nepal_datetime(dt, include_time=True):
    """
    Format datetime for Nepal timezone display.
    
    Args:
        dt: datetime object
        include_time: Whether to include time in output
        
    Returns:
        str: Formatted datetime string
    """
    if dt is None:
        return ""
    
    nepal_dt = convert_to_nepal_tz(dt)
    
    if include_time:
        return nepal_dt.strftime("%Y-%m-%d %I:%M %p")  # type: ignore[union-attr]  # 2025-01-15 02:30 PM
    else:
        return nepal_dt.strftime("%Y-%m-%d")  # type: ignore[union-attr]


def get_nepal_date_range(start_date, end_date):
    """
    Generate list of dates between start and end (inclusive).
    
    Args:
        start_date: Start date
        end_date: End date
        
    Returns:
        list: List of date objects
    """
    date_list = []
    current_date = start_date
    
    while current_date <= end_date:
        date_list.append(current_date)
        current_date += timedelta(days=1)
    
    return date_list


def parse_nepal_time(time_str):
    """
    Parse time string in HH:MM format.
    
    Args:
        time_str: Time string like "09:00" or "14:30"
        
    Returns:
        time: time object
        
    Raises:
        ValueError: If time string is invalid
    """
    try:
        return datetime.strptime(time_str, "%H:%M").time()
    except ValueError:
        raise ValueError(f"Invalid time format: {time_str}. Expected HH:MM format.")


def calculate_time_slots(start_time, end_time, slot_duration_minutes, exclude_periods=None):
    """
    Calculate available time slots between start and end time.
    
    Args:
        start_time: time object for start
        end_time: time object for end
        slot_duration_minutes: Duration of each slot in minutes
        exclude_periods: List of (start_time, end_time) tuples to exclude (e.g., lunch)
        
    Returns:
        list: List of (slot_start, slot_end) time tuples
    """
    if exclude_periods is None:
        exclude_periods = []
    
    slots = []
    current_time = start_time
    
    # Convert to datetime for easier calculation
    base_date = date.today()
    current_dt = datetime.combine(base_date, current_time)
    end_dt = datetime.combine(base_date, end_time)
    slot_delta = timedelta(minutes=slot_duration_minutes)
    
    while current_dt < end_dt:
        slot_end_dt = current_dt + slot_delta
        
        # Check if this slot overlaps with any excluded period
        is_excluded = False
        for exclude_start, exclude_end in exclude_periods:
            exclude_start_dt = datetime.combine(base_date, exclude_start)
            exclude_end_dt = datetime.combine(base_date, exclude_end)
            
            # Check overlap
            if not (slot_end_dt <= exclude_start_dt or current_dt >= exclude_end_dt):
                is_excluded = True
                break
        
        if not is_excluded and slot_end_dt <= end_dt:
            slots.append((current_dt.time(), slot_end_dt.time()))
        
        current_dt += slot_delta
    
    return slots


def is_future_date(date_obj):
    """
    Check if date is in the future (compared to Nepal today).
    
    Args:
        date_obj: date object
        
    Returns:
        bool: True if date is in future, False otherwise
    """
    return date_obj > get_nepal_today()


def is_today_or_future(date_obj):
    """
    Check if date is today or in the future (compared to Nepal today).
    
    Args:
        date_obj: date object
        
    Returns:
        bool: True if date is today or future, False if past
    """
    return date_obj >= get_nepal_today()
