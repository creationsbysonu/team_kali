import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_day.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_month_data.dart';

/// Production-grade Attendance Calendar using Syncfusion Calendar
/// Features: Month view, appointments, agenda, navigation, tap handling
class AttendanceSyncfusionCalendar extends StatefulWidget {
  final AttendanceMonthData monthData;
  final Function(DateTime date, AttendanceDay day) onDayTapped;
  final Function(int year, int month) onMonthChanged;

  const AttendanceSyncfusionCalendar({
    super.key,
    required this.monthData,
    required this.onDayTapped,
    required this.onMonthChanged,
  });

  @override
  State<AttendanceSyncfusionCalendar> createState() =>
      _AttendanceSyncfusionCalendarState();
}

class _AttendanceSyncfusionCalendarState
    extends State<AttendanceSyncfusionCalendar> {
  late CalendarController _calendarController;

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    _calendarController.displayDate = DateTime(
      widget.monthData.year,
      widget.monthData.month,
      1,
    );
  }

  @override
  void didUpdateWidget(covariant AttendanceSyncfusionCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.monthData.year != widget.monthData.year ||
        oldWidget.monthData.month != widget.monthData.month) {
      _calendarController.displayDate = DateTime(
        widget.monthData.year,
        widget.monthData.month,
        1,
      );
    }
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        Expanded(child: _buildCalendar()),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  Widget _buildHeader() {
    final displayMonth = DateFormat(
      'MMMM yyyy',
    ).format(DateTime(widget.monthData.year, widget.monthData.month));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _navigateMonth(-1),
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
          ),
          Column(
            children: [
              Text(
                displayMonth,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${widget.monthData.personName} • ${widget.monthData.totalWorkingDays} working days',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _navigateMonth(1),
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SfCalendar(
          controller: _calendarController,
          view: CalendarView.month,
          dataSource: _AttendanceDataSource(widget.monthData),
          headerHeight: 0,
          viewHeaderHeight: 40,
          viewHeaderStyle: ViewHeaderStyle(
            backgroundColor: AppTheme.primaryCobalt.withOpacity(0.05),
            dayTextStyle: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          monthViewSettings: MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
            appointmentDisplayCount: 1,
            showAgenda: true,
            agendaViewHeight: 140,
            agendaStyle: AgendaStyle(
              backgroundColor: Colors.grey.shade50,
              dayTextStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              dateTextStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryCobalt,
              ),
              appointmentTextStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            monthCellStyle: MonthCellStyle(
              textStyle: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
              trailingDatesTextStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
              leadingDatesTextStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
            numberOfWeeksInView: 6,
            showTrailingAndLeadingDates: true,
          ),
          todayHighlightColor: AppTheme.primaryCobalt,
          selectionDecoration: BoxDecoration(
            border: Border.all(color: AppTheme.primaryCobalt, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          cellBorderColor: Colors.grey.shade200,
          onTap: _handleCalendarTap,
          onViewChanged: (ViewChangedDetails details) {
            if (details.visibleDates.isNotEmpty) {
              final middleDate =
                  details.visibleDates[details.visibleDates.length ~/ 2];
              if (middleDate.month != widget.monthData.month ||
                  middleDate.year != widget.monthData.year) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onMonthChanged(middleDate.year, middleDate.month);
                });
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(
            'Present',
            _AttendanceColors.present,
            widget.monthData.totalPresentDays,
          ),
          _buildLegendItem(
            'Absent',
            _AttendanceColors.absent,
            widget.monthData.totalAbsentDays,
          ),
          _buildLegendItem(
            'Saturday',
            _AttendanceColors.saturday,
            widget.monthData.totalSaturdays,
          ),
          _buildLegendItem(
            'Holiday',
            _AttendanceColors.holiday,
            widget.monthData.totalHolidays,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($count)',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  void _navigateMonth(int delta) {
    final newDate = DateTime(
      widget.monthData.year,
      widget.monthData.month + delta,
      1,
    );
    widget.onMonthChanged(newDate.year, newDate.month);
  }

  void _handleCalendarTap(CalendarTapDetails details) {
    if (details.date == null) return;

    final tappedDate = details.date!;

    if (tappedDate.month != widget.monthData.month ||
        tappedDate.year != widget.monthData.year) {
      return;
    }

    final day = widget.monthData.getDayForDate(tappedDate);
    if (day != null) {
      widget.onDayTapped(tappedDate, day);
    }
  }
}

class _AttendanceColors {
  static const Color present = Color(0xFF4CAF50);
  static const Color absent = Color(0xFFE53935);
  static const Color saturday = Color(0xFF78909C);
  static const Color holiday = Color(0xFFFF9800);
}

class _AttendanceDataSource extends CalendarDataSource {
  _AttendanceDataSource(AttendanceMonthData monthData) {
    appointments = monthData.days.map((day) {
      return Appointment(
        startTime: day.date,
        endTime: day.date.add(const Duration(hours: 23, minutes: 59)),
        subject: _getSubject(day),
        color: _getColor(day.type),
        isAllDay: true,
        notes: day.reason ?? day.holiday?.name ?? '',
      );
    }).toList();
  }

  static String _getSubject(AttendanceDay day) {
    switch (day.type) {
      case AttendanceDayType.present:
        return '✓ Present';
      case AttendanceDayType.absent:
        return '✗ Absent${day.reason != null ? ': ${day.reason}' : ''}';
      case AttendanceDayType.saturday:
        return '◐ Saturday';
      case AttendanceDayType.holiday:
        return '★ ${day.holiday?.name ?? 'Holiday'}';
    }
  }

  static Color _getColor(AttendanceDayType type) {
    switch (type) {
      case AttendanceDayType.present:
        return _AttendanceColors.present;
      case AttendanceDayType.absent:
        return _AttendanceColors.absent;
      case AttendanceDayType.saturday:
        return _AttendanceColors.saturday;
      case AttendanceDayType.holiday:
        return _AttendanceColors.holiday;
    }
  }
}
