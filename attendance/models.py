"""
Unified Attendance Models

Tracks attendance for both staff and ministry officials.
Controls whether services can operate and whether progress steps can advance.
"""
import uuid
from django.db import models
from django.core.exceptions import ValidationError
from django.utils import timezone
import pytz

NEPAL_TZ = pytz.timezone('Asia/Kathmandu')


class AttendanceRecord(models.Model):
    """
    Unified attendance tracking for STAFF and OFFICIALS.
    
    Purpose:
    - Track who is present/absent on any given day
    - Control service queue availability (staff)
    - Control progress step advancement (officials)
    
    Rules:
    - Only FUTURE dates can be edited
    - Same day & past dates LOCKED
    - Default = PRESENT if no record exists
    - Saturday = system-defined ABSENT
    - Bulk absence supported (date ranges)
    
    Authority: Ministry Admin ONLY
    """
    
    class PersonType(models.TextChoices):
        STAFF = 'STAFF', 'Staff'
        OFFICIAL = 'OFFICIAL', 'Official'
    
    class Status(models.TextChoices):
        PRESENT = 'PRESENT', 'Present'
        ABSENT = 'ABSENT', 'Absent'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Date
    date = models.DateField(
        help_text="Date for which attendance is being marked"
    )
    
    # Person type
    person_type = models.CharField(
        max_length=10,
        choices=PersonType.choices,
        help_text="Whether this record is for staff or official"
    )
    
    # Foreign keys (one must be filled based on person_type)
    staff = models.ForeignKey(
        'ministry.StaffService',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='attendance_records',
        help_text="Staff member (if person_type=STAFF)"
    )
    
    official = models.ForeignKey(
        'officials.MinistryOfficial',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='attendance_records',
        help_text="Official (if person_type=OFFICIAL)"
    )
    
    # Status
    status = models.CharField(
        max_length=10,
        choices=Status.choices,
        default=Status.PRESENT,
        help_text="Attendance status"
    )
    
    # Audit fields
    marked_by = models.ForeignKey(
        'authentication.CustomUser',
        on_delete=models.SET_NULL,
        null=True,
        related_name='marked_attendance_records',
        help_text="Ministry admin who marked this attendance"
    )
    
    reason = models.TextField(
        blank=True,
        default='',
        help_text="Optional reason for absence"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Attendance Record'
        verbose_name_plural = 'Attendance Records'
        ordering = ['-date']
        indexes = [
            models.Index(fields=['date', 'person_type']),
            models.Index(fields=['staff', 'date']),
            models.Index(fields=['official', 'date']),
            models.Index(fields=['date', 'status']),
        ]
        # One record per person per date
        constraints = [
            models.UniqueConstraint(
                fields=['staff', 'date'],
                condition=models.Q(person_type='STAFF'),
                name='unique_staff_date'
            ),
            models.UniqueConstraint(
                fields=['official', 'date'],
                condition=models.Q(person_type='OFFICIAL'),
                name='unique_official_date'
            ),
        ]
    
    def clean(self):
        """Validate attendance record."""
        super().clean()
        
        if not self.date:
            return
        
        # Get today's date in Nepal timezone
        nepal_now = timezone.now().astimezone(NEPAL_TZ)
        today = nepal_now.date()
        
        # Rule: Only future dates allowed
        if self.date <= today:
            raise ValidationError({
                'date': 'Cannot mark attendance for past or current date. Only future dates allowed.'
            })
        
        # Rule: Saturday is day 5 (Saturday) in Python's weekday()
        if self.date.weekday() == 5:  # Saturday
            raise ValidationError({
                'date': 'Saturdays are automatically treated as ABSENT. No need to mark attendance.'
            })
        
        # Validate person_type matches FK
        if self.person_type == self.PersonType.STAFF:
            if not self.staff:
                raise ValidationError({
                    'staff': 'Staff must be specified when person_type is STAFF'
                })
            if self.official:
                raise ValidationError({
                    'official': 'Official should be null when person_type is STAFF'
                })
        elif self.person_type == self.PersonType.OFFICIAL:
            if not self.official:
                raise ValidationError({
                    'official': 'Official must be specified when person_type is OFFICIAL'
                })
            if self.staff:
                raise ValidationError({
                    'staff': 'Staff should be null when person_type is OFFICIAL'
                })
    
    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)
    
    def __str__(self):
        if self.person_type == self.PersonType.STAFF and self.staff:
            person_name = self.staff.staff_name
        elif self.person_type == self.PersonType.OFFICIAL and self.official:
            person_name = self.official.name
        else:
            person_name = "Unknown"
        return f"{person_name} - {self.date} - {self.status}"
    
    @staticmethod
    def is_person_available(person, date, person_type):
        """
        Check if a person is available on a given date.
        
        Rules:
        - Saturday → ABSENT
        - Has ABSENT record → ABSENT
        - No record → PRESENT (default)
        - Has PRESENT record → PRESENT
        
        Args:
            person: StaffService or MinistryOfficial instance
            date: date object
            person_type: PersonType.STAFF or PersonType.OFFICIAL
            
        Returns:
            bool: True if available, False otherwise
        """
        # Saturday is always ABSENT
        if date.weekday() == 5:  # Saturday
            return False
        
        # Check for explicit attendance record
        try:
            if person_type == AttendanceRecord.PersonType.STAFF:
                attendance = AttendanceRecord.objects.get(
                    staff=person,
                    date=date,
                    person_type=person_type
                )
            else:
                attendance = AttendanceRecord.objects.get(
                    official=person,
                    date=date,
                    person_type=person_type
                )
            return attendance.status == AttendanceRecord.Status.PRESENT
        except AttendanceRecord.DoesNotExist:
            # Default: PRESENT
            return True
