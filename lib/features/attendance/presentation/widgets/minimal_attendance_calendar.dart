import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_day.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_month_data.dart';

/// Minimal, fast-loading attendance calendar
/// - No heavy libraries, pure Flutter
/// - Simple color-coded cells
/// - Lightweight for smooth UX
class MinimalAttendanceCalendar extends StatelessWidget {
  final AttendanceMonthData monthData;
  final Function(DateTime date, AttendanceDay day) onDayTapped;
  final Function(int year, int month) onMonthChanged;

  const MinimalAttendanceCalendar({
    super.key,
    required this.monthData,
    required this.onDayTapped,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildWeekDays(),
          _buildCalendarGrid(),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final displayMonth = DateFormat(
      'MMMM yyyy',
    ).format(DateTime(monthData.year, monthData.month));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryCobalt.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _navigateMonth(-1),
            icon: const Icon(Icons.chevron_left, size: 24),
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Text(
            displayMonth,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () => _navigateMonth(1),
            icon: const Icon(Icons.chevron_right, size: 24),
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDays() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: days.map((day) {
          final isSaturday = day == 'Sat';
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSaturday
                      ? _StatusColors.saturday
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(monthData.year, monthData.month, 1);
    final lastDayOfMonth = DateTime(monthData.year, monthData.month + 1, 0);
    final startingWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
    final daysInMonth = lastDayOfMonth.day;

    // Build cells: empty cells for days before month starts + actual days
    final cells = <Widget>[];

    // Empty cells before first day
    for (int i = 0; i < startingWeekday; i++) {
      cells.add(const SizedBox());
    }

    // Actual day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(monthData.year, monthData.month, day);
      final attendanceDay = monthData.getDayForDate(date);
      cells.add(_buildDayCell(date, attendanceDay));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(6),
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      childAspectRatio: 1.2,
      children: cells,
    );
  }

  Widget _buildDayCell(DateTime date, AttendanceDay? day) {
    if (day == null) {
      return _buildEmptyCell(date);
    }

    final isToday = _isToday(date);
    final color = _getStatusColor(day.type);
    final icon = _getStatusIcon(day.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onDayTapped(date, day),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: isToday
                ? Border.all(color: AppTheme.primaryCobalt, width: 2)
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                    color: isToday
                        ? AppTheme.primaryCobalt
                        : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(icon, size: 12, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCell(DateTime date) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '${date.day}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(
            'Present',
            _StatusColors.present,
            monthData.totalPresentDays,
          ),
          _buildLegendItem(
            'Absent',
            _StatusColors.absent,
            monthData.totalAbsentDays,
          ),
          _buildLegendItem(
            'Saturday',
            _StatusColors.saturday,
            monthData.totalSaturdays,
          ),
          _buildLegendItem(
            'Holiday',
            _StatusColors.holiday,
            monthData.totalHolidays,
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  void _navigateMonth(int delta) {
    final newDate = DateTime(monthData.year, monthData.month + delta, 1);
    onMonthChanged(newDate.year, newDate.month);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Color _getStatusColor(AttendanceDayType type) {
    switch (type) {
      case AttendanceDayType.present:
        return _StatusColors.present;
      case AttendanceDayType.absent:
        return _StatusColors.absent;
      case AttendanceDayType.saturday:
        return _StatusColors.saturday;
      case AttendanceDayType.holiday:
        return _StatusColors.holiday;
    }
  }

  IconData _getStatusIcon(AttendanceDayType type) {
    switch (type) {
      case AttendanceDayType.present:
        return Icons.check_circle_outline;
      case AttendanceDayType.absent:
        return Icons.cancel_outlined;
      case AttendanceDayType.saturday:
        return Icons.weekend_outlined;
      case AttendanceDayType.holiday:
        return Icons.celebration_outlined;
    }
  }
}

class _StatusColors {
  static const Color present = Color(0xFF4CAF50); // Green - working & present
  static const Color absent = Color(0xFFE53935); // Red - absent
  static const Color saturday = Color(0xFFE53935); // Red - non-working day
  static const Color holiday = Color(0xFFE53935); // Red - non-working day
}
