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

/// Mark Attendance Page - Interactive calendar for marking attendance
class MarkAttendancePage extends StatelessWidget {
  const MarkAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AttendanceBloc>(),
      child: const _MarkAttendanceContent(),
    );
  }
}

class _MarkAttendanceContent extends StatefulWidget {
  const _MarkAttendanceContent();

  @override
  State<_MarkAttendanceContent> createState() => _MarkAttendanceContentState();
}

class _MarkAttendanceContentState extends State<_MarkAttendanceContent> {
  String _personType = 'STAFF';
  String? _selectedPersonId;
  String? _selectedPersonName;
  DateTime _selectedMonth = DateTime.now();
  final Set<DateTime> _selectedDates = {};
  String _bulkStatus = 'PRESENT';

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
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          _buildHeader(context, isMobile),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilters(context, isMobile),
                  const SizedBox(height: 24),
                  Expanded(child: _buildContent(context, isMobile)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.edit_calendar,
            size: 28,
            color: AppTheme.primaryCobalt,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mark Attendance',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Mark or update attendance for staff and officials',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            Row(
              children: [
                Expanded(
                  child: _buildPersonTypeCard('STAFF', 'Staff', Icons.person),
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
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryCobalt,
                          width: 2,
                        ),
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
                        _selectedDates.clear();
                      });
                      if (value != null) {
                        _loadAttendance();
                      }
                    },
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryCobalt,
                  ),
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
          _selectedDates.clear();
        });
        context.read<AttendanceBloc>().add(LoadPersonsEvent(personType: type));
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryCobalt.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryCobalt : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryCobalt : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primaryCobalt : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isMobile) {
    if (_selectedPersonId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Select a person to mark attendance',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(state.message),
                ],
              ),
              backgroundColor: AppTheme.success,
            ),
          );
          _loadAttendance();
          setState(() => _selectedDates.clear());
        } else if (state is AttendanceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is AttendanceLoading ||
            state is AttendanceOperationInProgress) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryCobalt),
          );
        }

        if (state is AttendanceCalendarLoaded) {
          return Column(
            children: [
              if (_selectedDates.isNotEmpty) _buildBulkActions(),
              if (_selectedDates.isNotEmpty) const SizedBox(height: 16),
              Expanded(child: _buildCalendarView(state, isMobile)),
            ],
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildBulkActions() {
    return Card(
      color: AppTheme.primaryCobalt.withOpacity(0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.primaryCobalt.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.checklist, color: AppTheme.primaryCobalt),
            const SizedBox(width: 12),
            Text(
              '${_selectedDates.length} date(s) selected',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryCobalt,
              ),
            ),
            const Spacer(),
            DropdownButton<String>(
              value: _bulkStatus,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'PRESENT', child: Text('Present')),
                DropdownMenuItem(value: 'ABSENT', child: Text('Absent')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _bulkStatus = value);
                }
              },
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _handleBulkMark,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Mark Selected'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryCobalt,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => setState(() => _selectedDates.clear()),
              icon: const Icon(Icons.close),
              tooltip: 'Clear selection',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView(AttendanceCalendarLoaded state, bool isMobile) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildCalendarHeader(),
            const SizedBox(height: 16),
            _buildInstructions(),
            const SizedBox(height: 16),
            _buildLegend(),
            const SizedBox(height: 16),
            Expanded(
              child: SfCalendar(
                view: CalendarView.month,
                initialDisplayDate: _selectedMonth,
                dataSource: _AttendanceDataSource(
                  state.calendarData.records,
                  _selectedDates,
                ),
                monthViewSettings: const MonthViewSettings(
                  showAgenda: false,
                  appointmentDisplayMode:
                      MonthAppointmentDisplayMode.appointment,
                ),
                headerHeight: 0,
                cellBorderColor: Colors.grey[200],
                todayHighlightColor: AppTheme.primaryCobalt,
                selectionDecoration: BoxDecoration(
                  color: AppTheme.primaryCobalt.withOpacity(0.2),
                  border: Border.all(color: AppTheme.primaryCobalt, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                onTap: (details) {
                  if (details.date != null) {
                    _handleDateTap(details.date!, state.calendarData.records);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedPersonName ?? 'Unknown',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              _personType == 'STAFF' ? 'Staff Member' : 'Official',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
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
                  _selectedDates.clear();
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
                color: Colors.black87,
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
                  _selectedDates.clear();
                });
                _loadAttendance();
              },
              color: AppTheme.primaryCobalt,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tap a date to mark single attendance • Long press to select multiple dates',
              style: TextStyle(fontSize: 12, color: Colors.blue[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem(AppTheme.success, 'Present'),
        _buildLegendItem(AppTheme.error, 'Absent'),
        _buildLegendItem(AppTheme.primaryCobalt, 'Selected'),
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
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  void _handleDateTap(DateTime date, List<AttendanceRecord> records) {
    // Check if date is valid
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot mark attendance for past dates'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (date.weekday == DateTime.saturday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot mark attendance on Saturday'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    // Check if multi-select mode
    if (_selectedDates.isNotEmpty) {
      setState(() {
        if (_selectedDates.contains(date)) {
          _selectedDates.remove(date);
        } else {
          _selectedDates.add(date);
        }
      });
      return;
    }

    // Single date marking - show dialog
    final existingRecord = records.firstWhere(
      (r) =>
          r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day,
      orElse: () => AttendanceRecord(
        id: '',
        personId: '',
        personType: PersonType.staff,
        personName: '',
        date: date,
        status: AttendanceStatus.present,
        isSaturday: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AttendanceBloc>(),
        child: MarkAttendanceDialog(
          date: date,
          personType: _personType,
          personId: _selectedPersonId!,
          personName: _selectedPersonName!,
          existingRecord: existingRecord.id.isNotEmpty ? existingRecord : null,
        ),
      ),
    );
  }

  void _handleBulkMark() {
    if (_selectedDates.isEmpty || _selectedPersonId == null) return;

    final attendanceData = _selectedDates.map((date) {
      return {
        'person_type': _personType,
        'person_id': _selectedPersonId!,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'status': _bulkStatus,
      };
    }).toList();

    context.read<AttendanceBloc>().add(
      BulkMarkAttendanceEvent(attendanceData: attendanceData),
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
}

class _AttendanceDataSource extends CalendarDataSource {
  _AttendanceDataSource(
    List<AttendanceRecord> records,
    Set<DateTime> selectedDates,
  ) {
    appointments = [
      ...records.map((record) {
        final isPresent = record.status.value == 'PRESENT';
        return Appointment(
          startTime: record.date,
          endTime: record.date.add(const Duration(hours: 1)),
          subject: isPresent ? 'P' : 'A',
          color: isPresent
              ? AppTheme.success.withOpacity(0.7)
              : AppTheme.error.withOpacity(0.7),
          isAllDay: true,
        );
      }),
      ...selectedDates.map((date) {
        return Appointment(
          startTime: date,
          endTime: date.add(const Duration(hours: 1)),
          subject: 'Selected',
          color: AppTheme.primaryCobalt.withOpacity(0.3),
          isAllDay: true,
        );
      }),
    ];
  }
}
