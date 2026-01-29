import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_day.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_month_data.dart';

/// Clean Syncfusion Calendar widget - minimal UI, no overflow
class AttendanceCalendarWidget extends StatelessWidget {
  final AttendanceMonthData monthData;
  final Function(DateTime, AttendanceDay) onDayTapped;

  const AttendanceCalendarWidget({
    super.key,
    required this.monthData,
    required this.onDayTapped,
  });

  /// Get color for attendance type
  Color _getColor(AttendanceDayType type) {
    switch (type) {
      case AttendanceDayType.present:
        return const Color(0xFF4CAF50); // Green
      case AttendanceDayType.absent:
        return const Color(0xFFE53935); // Red
      case AttendanceDayType.saturday:
        return const Color(0xFF757575); // Gray
      case AttendanceDayType.holiday:
        return const Color(0xFFFF9800); // Orange
    }
  }

  @override
  Widget build(BuildContext context) {
    return SfCalendar(
      view: CalendarView.month,
      initialDisplayDate: DateTime(monthData.year, monthData.month, 1),
      headerHeight: 0, // Hide default header - we use custom
      showNavigationArrow: false,
      showDatePickerButton: false,
      cellBorderColor: Colors.grey[300],
      selectionDecoration: const BoxDecoration(),

      // Simple month view
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.none,
        showAgenda: false,
        numberOfWeeksInView: 6,
      ),

      // Tap to select day
      onTap: (details) {
        if (details.targetElement == CalendarElement.calendarCell &&
            details.date != null) {
          final day = monthData.getDayForDate(details.date!);
          if (day != null) {
            onDayTapped(details.date!, day);
          }
        }
      },

      // Custom cell builder - clean and simple
      monthCellBuilder: (context, details) {
        final date = details.date;
        final day = monthData.getDayForDate(date);
        final isCurrentMonth = date.month == monthData.month;
        final isToday = _isSameDay(date, DateTime.now());

        // For dates outside month or no data
        if (!isCurrentMonth || day == null) {
          return Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ),
          );
        }

        final bgColor = _getColor(day.type);

        return Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: isToday
                ? Border.all(color: AppTheme.primaryCobalt, width: 2)
                : null,
          ),
          child: InkWell(
            onTap: () => onDayTapped(date, day),
            borderRadius: BorderRadius.circular(4),
            child: Center(
              child: Text(
                '${date.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
