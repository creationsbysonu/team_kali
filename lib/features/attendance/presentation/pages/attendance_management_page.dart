import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:sewa_web/core/di/injection_container.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/core/utils/responsive_helper.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance.dart';
import 'package:sewa_web/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:sewa_web/features/attendance/presentation/widgets/mark_attendance_dialog.dart';

/// Attendance Management Page - Ministry Admin marks attendance for staff and officials
class AttendanceManagementPage extends StatelessWidget {
  const AttendanceManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AttendanceBloc>(),
      child: const _AttendancePageContent(),
    );
  }
}

class _AttendancePageContent extends StatefulWidget {
  const _AttendancePageContent();

  @override
  State<_AttendancePageContent> createState() => _AttendancePageContentState();
}

class _AttendancePageContentState extends State<_AttendancePageContent> {
  String _personType = 'STAFF'; // STAFF or OFFICIAL
  String? _selectedPersonId;
  String? _selectedPersonName;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(
      LoadPersonsEvent(personType: _personType),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isMobile),
            const SizedBox(height: 24),
            _buildFilters(context, isMobile),
            const SizedBox(height: 24),
            Expanded(child: _buildCalendarView(context, isMobile)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Management',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mark or view attendance for staff and officials',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (!isMobile)
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/ministry/attendance/view');
                },
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('View Attendance'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/ministry/attendance/mark');
                },
                icon: const Icon(Icons.edit_calendar, size: 18),
                label: const Text('Mark Attendance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCobalt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, bool isMobile) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Person Type Selector
            Row(
              children: [
                Expanded(
                  child: _buildPersonTypeCard(
                    'STAFF',
                    'Staff Members',
                    Icons.person,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPersonTypeCard(
                    'OFFICIAL',
                    'Officials',
                    Icons.admin_panel_settings,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Person Selector
            BlocBuilder<AttendanceBloc, AttendanceState>(
              builder: (context, state) {
                if (state is PersonsLoaded) {
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedPersonId,
                    decoration: InputDecoration(
                      labelText:
                          'Select ${_personType == 'STAFF' ? 'Staff' : 'Official'}',
                      prefixIcon: Icon(
                        _personType == 'STAFF'
                            ? Icons.person
                            : Icons.admin_panel_settings,
                        color: AppTheme.primaryCobalt,
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: state.persons.map((person) {
                      return DropdownMenuItem<String>(
                        value: person['id'],
                        child: Text(person['name'] ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPersonId = value;
                        _selectedPersonName =
                            state.persons.firstWhere(
                              (p) => p['id'] == value,
                            )['name'] ??
                            'Unknown';
                      });
                      if (value != null) {
                        _loadAttendance();
                      }
                    },
                  );
                }
                return const CircularProgressIndicator(
                  color: AppTheme.secondary,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonTypeCard(String type, String label, IconData icon) {
    final isSelected = _personType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _personType = type;
          _selectedPersonId = null;
          _selectedPersonName = null;
        });
        context.read<AttendanceBloc>().add(LoadPersonsEvent(personType: type));
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryCobalt.withOpacity(0.1)
              : AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? AppTheme.primaryCobalt : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primaryCobalt
                  : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppTheme.primaryCobalt
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView(BuildContext context, bool isMobile) {
    if (_selectedPersonId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 64,
              color: AppTheme.textMuted,
            ),
            SizedBox(height: 16),
            Text(
              'Select a person to view attendance',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.success,
            ),
          );
          _loadAttendance();
        } else if (state is AttendanceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is AttendanceLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.secondary),
          );
        }

        if (state is AttendanceCalendarLoaded) {
          return Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Calendar Header with Month Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attendance Calendar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                _selectedMonth = DateTime(
                                  _selectedMonth.year,
                                  _selectedMonth.month - 1,
                                );
                              });
                              _loadAttendance();
                            },
                            color: AppTheme.primaryCobalt,
                          ),
                          Text(
                            DateFormat('MMMM yyyy').format(_selectedMonth),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() {
                                _selectedMonth = DateTime(
                                  _selectedMonth.year,
                                  _selectedMonth.month + 1,
                                );
                              });
                              _loadAttendance();
                            },
                            color: AppTheme.primaryCobalt,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Legend
                  _buildLegend(),
                  const SizedBox(height: 16),

                  // Syncfusion Calendar
                  Expanded(
                    child: SfCalendar(
                      view: CalendarView.month,
                      initialDisplayDate: _selectedMonth,
                      minDate: DateTime.now().subtract(const Duration(days: 1)),
                      dataSource: _AttendanceDataSource(
                        state.calendarData.records,
                      ),
                      monthViewSettings: const MonthViewSettings(
                        showAgenda: false,
                        appointmentDisplayMode:
                            MonthAppointmentDisplayMode.appointment,
                      ),
                      headerHeight: 0, // Hide default header (using custom)
                      onTap: (details) {
                        if (details.date != null) {
                          _showMarkAttendanceDialog(
                            context,
                            details.date!,
                            state.calendarData.records,
                          );
                        }
                      },
                      cellBorderColor: AppTheme.borderColor,
                      todayHighlightColor: AppTheme.primaryCobalt,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem(Colors.green, 'Present'),
        _buildLegendItem(Colors.red, 'Absent'),
        _buildLegendItem(Colors.grey, 'Saturday'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  void _loadAttendance() {
    if (_selectedPersonId != null) {
      final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endDate = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        0,
      );

      context.read<AttendanceBloc>().add(
        LoadAttendanceCalendarEvent(
          personType: _personType,
          personId: _selectedPersonId!,
          startDate: startDate,
          endDate: endDate,
        ),
      );
    }
  }

  void _showMarkAttendanceDialog(
    BuildContext context,
    DateTime date,
    List<AttendanceRecord> records,
  ) {
    // Check if it's Saturday
    if (date.weekday == DateTime.saturday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot mark attendance on Saturday (weekly holiday)'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    // Check if date is in the past
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot mark attendance for past dates'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    // Find existing record
    final existingRecord = records
        .where(
          (r) =>
              r.date.day == date.day &&
              r.date.month == date.month &&
              r.date.year == date.year,
        )
        .firstOrNull;

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AttendanceBloc>(),
        child: MarkAttendanceDialog(
          date: date,
          personType: _personType,
          personId: _selectedPersonId!,
          personName: _selectedPersonName!,
          existingRecord: existingRecord,
        ),
      ),
    );
  }
}

// Custom Data Source for Syncfusion Calendar
class _AttendanceDataSource extends CalendarDataSource {
  _AttendanceDataSource(List<AttendanceRecord> attendanceRecords) {
    appointments = _generateAppointments(attendanceRecords);
  }

  List<Appointment> _generateAppointments(List<AttendanceRecord> records) {
    final List<Appointment> appointments = [];

    // Add attendance records
    for (final record in records) {
      final isPresent = record.status.value == 'PRESENT';
      appointments.add(
        Appointment(
          startTime: record.date,
          endTime: record.date.add(const Duration(hours: 1)),
          subject: isPresent ? 'Present' : 'Absent',
          color: isPresent
              ? Colors.green.withOpacity(0.7)
              : Colors.red.withOpacity(0.7),
          isAllDay: true,
        ),
      );
    }

    return appointments;
  }
}
