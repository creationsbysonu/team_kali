import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:sewa_web/core/di/injection_container.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/core/utils/responsive_helper.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance.dart';
import 'package:sewa_web/features/attendance/presentation/bloc/attendance_bloc.dart';

/// View Attendance Page - Read-only calendar view for viewing attendance records
class ViewAttendancePage extends StatelessWidget {
  const ViewAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AttendanceBloc>(),
      child: const _ViewAttendanceContent(),
    );
  }
}

class _ViewAttendanceContent extends StatefulWidget {
  const _ViewAttendanceContent();

  @override
  State<_ViewAttendanceContent> createState() => _ViewAttendanceContentState();
}

class _ViewAttendanceContentState extends State<_ViewAttendanceContent> {
  String _personType = 'STAFF';
  String? _selectedPersonId;
  String? _selectedPersonName;
  DateTime _selectedMonth = DateTime.now();
  String _viewMode = 'calendar'; // calendar or list

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
                  if (_selectedPersonId != null) ...[
                    _buildViewToggle(isMobile),
                    const SizedBox(height: 16),
                  ],
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
            Icons.calendar_view_month,
            size: 28,
            color: AppTheme.primaryCobalt,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'View Attendance',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'View attendance records for staff and officials',
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

  Widget _buildViewToggle(bool isMobile) {
    return Row(
      children: [
        _buildViewButton(
          'calendar',
          'Calendar',
          Icons.calendar_month,
          isMobile,
        ),
        const SizedBox(width: 12),
        _buildViewButton('list', 'List', Icons.list, isMobile),
      ],
    );
  }

  Widget _buildViewButton(
    String mode,
    String label,
    IconData icon,
    bool isMobile,
  ) {
    final isSelected = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryCobalt : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryCobalt : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
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
            Icon(
              Icons.calendar_month_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Select a person to view attendance',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        if (state is AttendanceLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryCobalt),
          );
        }

        if (state is AttendanceCalendarLoaded) {
          return _viewMode == 'calendar'
              ? _buildCalendarView(state, isMobile)
              : _buildListView(state, isMobile);
        }

        if (state is AttendanceError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(fontSize: 16, color: AppTheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadAttendance,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCobalt,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox();
      },
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
            _buildCalendarHeader(state),
            const SizedBox(height: 16),
            _buildStatistics(state),
            const SizedBox(height: 16),
            _buildLegend(),
            const SizedBox(height: 16),
            Expanded(
              child: SfCalendar(
                view: CalendarView.month,
                initialDisplayDate: _selectedMonth,
                dataSource: _AttendanceDataSource(state.calendarData.records),
                monthViewSettings: const MonthViewSettings(
                  showAgenda: false,
                  appointmentDisplayMode:
                      MonthAppointmentDisplayMode.appointment,
                ),
                headerHeight: 0,
                cellBorderColor: Colors.grey[200],
                todayHighlightColor: AppTheme.primaryCobalt,
                onTap: (details) {
                  if (details.date != null) {
                    _showDayDetails(
                      context,
                      details.date!,
                      state.calendarData.records,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader(AttendanceCalendarLoaded state) {
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

  Widget _buildStatistics(AttendanceCalendarLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryCobalt.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Days',
              state.calendarData.totalDays.toString(),
              Icons.calendar_today,
              AppTheme.primaryCobalt,
            ),
          ),
          Expanded(
            child: _buildStatCard(
              'Present',
              state.calendarData.presentDays.toString(),
              Icons.check_circle,
              AppTheme.success,
            ),
          ),
          Expanded(
            child: _buildStatCard(
              'Absent',
              state.calendarData.absentDays.toString(),
              Icons.cancel,
              AppTheme.error,
            ),
          ),
          Expanded(
            child: _buildStatCard(
              'Attendance',
              '${state.calendarData.attendancePercentage.toStringAsFixed(1)}%',
              Icons.pie_chart,
              AppTheme.primaryCobalt,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem(AppTheme.success, 'Present'),
        _buildLegendItem(AppTheme.error, 'Absent'),
        _buildLegendItem(Colors.grey, 'Saturday'),
        _buildLegendItem(Colors.orange, 'Holiday'),
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

  Widget _buildListView(AttendanceCalendarLoaded state, bool isMobile) {
    final records = state.calendarData.records;

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildCalendarHeader(state),
                const SizedBox(height: 16),
                _buildStatistics(state),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No attendance records for this month',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: records.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return _buildListItem(record);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(AttendanceRecord record) {
    final isPresent = record.status.value == 'PRESENT';
    final color = isPresent ? AppTheme.success : AppTheme.error;

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isPresent ? Icons.check_circle : Icons.cancel,
          color: color,
        ),
      ),
      title: Text(
        DateFormat('EEEE, MMMM d, yyyy').format(record.date),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: record.reason != null
          ? Text(record.reason!, style: TextStyle(color: Colors.grey[600]))
          : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isPresent ? 'Present' : 'Absent',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
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

  void _showDayDetails(
    BuildContext context,
    DateTime date,
    List<AttendanceRecord> records,
  ) {
    final record = records.firstWhere(
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

    if (record.id.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(
              record.status.value == 'PRESENT'
                  ? Icons.check_circle
                  : Icons.cancel,
              color: record.status.value == 'PRESENT'
                  ? AppTheme.success
                  : AppTheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('MMMM d, yyyy').format(date),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${record.status.value}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            if (record.reason != null) ...[
              const SizedBox(height: 12),
              Text(
                'Reason:',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
              Text(record.reason!, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _AttendanceDataSource extends CalendarDataSource {
  _AttendanceDataSource(List<AttendanceRecord> records) {
    appointments = records.map((record) {
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
    }).toList();
  }
}