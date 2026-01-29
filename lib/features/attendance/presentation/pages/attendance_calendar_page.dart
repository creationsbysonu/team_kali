import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sewa_web/core/di/injection_container.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_day.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_month_data.dart';
import 'package:sewa_web/features/attendance/presentation/bloc/attendance_calendar_bloc.dart';
import 'package:sewa_web/features/attendance/presentation/widgets/minimal_attendance_calendar.dart';
import 'package:sewa_web/features/attendance/presentation/widgets/mark_absent_dialog.dart';
import 'package:sewa_web/features/attendance/presentation/widgets/non_editable_day_dialog.dart';
import 'package:sewa_web/features/attendance/presentation/widgets/view_absence_dialog.dart';

/// Optimized attendance calendar page with proper state management
/// - Uses BlocSelector for granular rebuilds
/// - Sidebar doesn't rebuild on month change
/// - Only calendar section refreshes
class AttendanceCalendarPage extends StatelessWidget {
  const AttendanceCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AttendanceCalendarBloc>(),
      child: const _AttendanceCalendarContent(),
    );
  }
}

class _AttendanceCalendarContent extends StatefulWidget {
  const _AttendanceCalendarContent();

  @override
  State<_AttendanceCalendarContent> createState() =>
      _AttendanceCalendarContentState();
}

class _AttendanceCalendarContentState
    extends State<_AttendanceCalendarContent> {
  String _personType = 'STAFF';
  String? _selectedPersonId;
  String? _selectedPersonName;
  String? _selectedPersonImage;

  @override
  void initState() {
    super.initState();
    context.read<AttendanceCalendarBloc>().add(
      LoadPersonsListEvent(personType: _personType),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: BlocListener<AttendanceCalendarBloc, AttendanceCalendarState>(
        listener: _handleStateChanges,
        child: BlocBuilder<AttendanceCalendarBloc, AttendanceCalendarState>(
          buildWhen: (previous, current) {
            // Only rebuild for major state changes, not for loading within calendar
            return previous.runtimeType != current.runtimeType ||
                (current is PersonsListLoaded) ||
                (current is MonthDataLoaded && previous is! MonthDataLoaded) ||
                (current is AttendanceCalendarError &&
                    current.currentData == null);
          },
          builder: (context, state) {
            // Initial / Loading persons
            if (state is AttendanceCalendarInitial ||
                state is LoadingPersonsList) {
              return _buildCenteredLoading('Loading...');
            }

            // Person selector
            if (state is PersonsListLoaded) {
              return _buildPersonSelector(context, state.persons);
            }

            // Calendar view - handles all calendar-related states
            if (state is LoadingMonthData ||
                state is MonthDataLoaded ||
                state is ProcessingAction ||
                state is ActionCompleted ||
                (state is AttendanceCalendarError &&
                    state.currentData != null)) {
              return _buildCalendarView(context);
            }

            // Error without data
            if (state is AttendanceCalendarError) {
              return _buildError(state.message);
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildCenteredLoading(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => context.read<AttendanceCalendarBloc>().add(
              LoadPersonsListEvent(personType: _personType),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonSelector(
    BuildContext context,
    List<Map<String, String>> persons,
  ) {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCobalt.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: AppTheme.primaryCobalt,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Select person to view',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Person type toggle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'STAFF', label: Text('Staff')),
                ButtonSegment(value: 'OFFICIAL', label: Text('Official')),
              ],
              selected: {_personType},
              onSelectionChanged: (selection) {
                setState(() {
                  _personType = selection.first;
                  _selectedPersonId = null;
                  _selectedPersonName = null;
                  _selectedPersonImage = null;
                });
                context.read<AttendanceCalendarBloc>().add(
                  LoadPersonsListEvent(personType: _personType),
                );
              },
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),

            const SizedBox(height: 16),

            // Person dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedPersonId,
              decoration: InputDecoration(
                hintText: 'Choose person...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: persons
                  .map(
                    (p) => DropdownMenuItem(
                      value: p['id'],
                      child: Text(p['name']!, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                final person = persons.firstWhere((p) => p['id'] == value);
                setState(() {
                  _selectedPersonId = value;
                  _selectedPersonName = person['name'];
                  _selectedPersonImage = person['image'];
                });
              },
            ),

            const SizedBox(height: 20),

            // Load button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedPersonId == null ? null : _loadAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCobalt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Attendance',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadAttendance() {
    final now = DateTime.now();
    context.read<AttendanceCalendarBloc>().add(
      LoadAttendanceMonthEvent(
        personType: _personType,
        personId: _selectedPersonId!,
        year: now.year,
        month: now.month,
      ),
    );
  }

  /// Main calendar view with optimized rebuilds
  Widget _buildCalendarView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Static sidebar - doesn't rebuild on month change
          SizedBox(width: 260, child: _buildSidebar()),
          const SizedBox(width: 20),

          // Calendar section - only this rebuilds on month change
          Expanded(child: _buildCalendarSection()),
        ],
      ),
    );
  }

  /// Sidebar with person info and stats
  /// Uses BlocSelector to only rebuild when stats change
  Widget _buildSidebar() {
    return Column(
      children: [
        // Person info card - static after selection
        _buildPersonCard(),
        const SizedBox(height: 12),

        // Stats card - uses BlocSelector
        _buildStatsCard(),
        const SizedBox(height: 12),

        // Actions card - static
        _buildActionsCard(),
      ],
    );
  }

  Widget _buildPersonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          // Profile image with CachedNetworkImage
          _buildProfileAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedPersonName ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _personType,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    if (_selectedPersonImage != null && _selectedPersonImage!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: _selectedPersonImage!,
        imageBuilder: (context, imageProvider) =>
            CircleAvatar(radius: 24, backgroundImage: imageProvider),
        placeholder: (context, url) => CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryCobalt.withOpacity(0.1),
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackAvatar(),
      );
    }
    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
    final initial = (_selectedPersonName?.isNotEmpty == true)
        ? _selectedPersonName![0].toUpperCase()
        : '?';
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.primaryCobalt,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  /// Stats card - only rebuilds when monthData changes
  Widget _buildStatsCard() {
    return BlocSelector<
      AttendanceCalendarBloc,
      AttendanceCalendarState,
      AttendanceMonthData?
    >(
      selector: (state) {
        if (state is MonthDataLoaded) return state.monthData;
        if (state is ProcessingAction) return state.currentData;
        if (state is ActionCompleted) return state.updatedData;
        if (state is LoadingMonthData) return state.previousData;
        if (state is AttendanceCalendarError) return state.currentData;
        return null;
      },
      builder: (context, monthData) {
        if (monthData == null) {
          return const SizedBox();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statistics',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                'Working',
                monthData.totalWorkingDays,
                AppTheme.primaryCobalt,
              ),
              _buildStatRow(
                'Present',
                monthData.totalPresentDays,
                const Color(0xFF4CAF50),
              ),
              _buildStatRow(
                'Absent',
                monthData.totalAbsentDays,
                const Color(0xFFE53935),
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Rate', style: TextStyle(fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getAttendanceColor(
                        monthData.attendancePercentage,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${monthData.attendancePercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _getAttendanceColor(
                          monthData.attendancePercentage,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) return const Color(0xFF4CAF50);
    if (percentage >= 75) return const Color(0xFFFF9800);
    return const Color(0xFFE53935);
  }

  Widget _buildActionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.read<AttendanceCalendarBloc>().add(
                LoadPersonsListEvent(personType: _personType),
              ),
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Change Person'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calendar section - uses BlocBuilder with buildWhen for optimization
  Widget _buildCalendarSection() {
    return BlocBuilder<AttendanceCalendarBloc, AttendanceCalendarState>(
      buildWhen: (previous, current) {
        // Only rebuild calendar when data changes
        return current is MonthDataLoaded ||
            current is LoadingMonthData ||
            current is ProcessingAction ||
            current is ActionCompleted ||
            (current is AttendanceCalendarError && current.currentData != null);
      },
      builder: (context, state) {
        AttendanceMonthData? monthData;
        bool isLoading = false;
        String? loadingMessage;

        if (state is MonthDataLoaded) {
          monthData = state.monthData;
        } else if (state is LoadingMonthData) {
          monthData = state.previousData;
          isLoading = state.previousData != null;
        } else if (state is ProcessingAction) {
          monthData = state.currentData;
          isLoading = true;
          loadingMessage = state.message;
        } else if (state is ActionCompleted) {
          monthData = state.updatedData;
        } else if (state is AttendanceCalendarError &&
            state.currentData != null) {
          monthData = state.currentData;
        }

        if (monthData == null) {
          return _buildCenteredLoading('Loading calendar...');
        }

        return Stack(
          children: [
            MinimalAttendanceCalendar(
              monthData: monthData,
              onDayTapped: (date, day) => _handleDayTapped(context, date, day),
              onMonthChanged: (year, month) {
                context.read<AttendanceCalendarBloc>().add(
                  ChangeMonthEvent(year: year, month: month),
                );
              },
            ),

            // Blur loading overlay - professional UX
            if (isLoading)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(
                      color: Colors.white.withOpacity(0.3),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryCobalt,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _handleDayTapped(
    BuildContext context,
    DateTime date,
    AttendanceDay day,
  ) {
    // Non-editable days
    if (!day.isEditable) {
      showDialog(
        context: context,
        builder: (ctx) => NonEditableDayDialog(
          date: date,
          type: day.isSaturday ? 'Saturday' : 'Holiday',
          holidayName: day.holiday?.name,
        ),
      );
      return;
    }

    // Present - mark absent
    if (day.isPresent) {
      showDialog(
        context: context,
        builder: (ctx) => MarkAbsentDialog(
          date: date,
          onConfirm: (reason) {
            context.read<AttendanceCalendarBloc>().add(
              MarkDayAbsentEvent(date: date, reason: reason),
            );
          },
        ),
      );
      return;
    }

    // Absent - view only (cannot be removed)
    if (day.isAbsent) {
      showDialog(
        context: context,
        builder: (ctx) => ViewAbsenceDialog(
          date: date,
          reason: day.reason ?? 'No reason provided',
        ),
      );
    }
  }

  void _handleStateChanges(
    BuildContext context,
    AttendanceCalendarState state,
  ) {
    if (state is ActionCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (state is AttendanceCalendarError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
