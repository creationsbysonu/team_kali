import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sewa_web/core/di/injection_container.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/core/utils/responsive_helper.dart';
import 'package:sewa_web/features/holidays/domain/entities/holiday.dart';
import 'package:sewa_web/features/holidays/presentation/bloc/holidays_bloc.dart';
import 'package:sewa_web/features/holidays/presentation/widgets/holiday_form_dialog.dart';

/// Holidays Management Page - Ministry Admin manages universal holidays
/// Simple list view showing holiday name and date
class HolidaysPage extends StatelessWidget {
  const HolidaysPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return BlocProvider(
      create: (context) =>
          sl<HolidaysBloc>()
            ..add(LoadHolidaysEvent(year: now.year, month: now.month)),
      child: const _HolidaysPageContent(),
    );
  }
}

class _HolidaysPageContent extends StatelessWidget {
  const _HolidaysPageContent();

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return BlocSelector<HolidaysBloc, HolidaysState, bool>(
      selector: (state) => state is HolidaysOperationInProgress,
      builder: (context, isOperationInProgress) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppTheme.background,
              body: Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, isMobile),
                    const SizedBox(height: 24),
                    Expanded(child: _buildHolidaysList(context, isMobile)),
                  ],
                ),
              ),
            ),
            // Blur loading overlay for operations
            if (isOperationInProgress)
              Positioned.fill(
                child: ClipRect(
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
                              SizedBox(height: 12),
                              Text(
                                'Processing...',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF374151),
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

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Government Holidays',
              style: TextStyle(
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage holidays - these will appear in attendance calendar',
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showHolidayDialog(context),
          icon: const Icon(Icons.add),
          label: Text(isMobile ? 'Add' : 'Add Holiday'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryCobalt,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 12 : 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHolidaysList(BuildContext context, bool isMobile) {
    return BlocConsumer<HolidaysBloc, HolidaysState>(
      listener: (context, state) {
        if (state is HolidaysOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.success,
            ),
          );
        } else if (state is HolidaysOperationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is HolidaysLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryCobalt),
          );
        }

        if (state is HolidaysError) {
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
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final now = DateTime.now();
                    context.read<HolidaysBloc>().add(
                      LoadHolidaysEvent(year: now.year, month: now.month),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Get holidays from any loaded state
        List<Holiday> holidays = [];
        if (state is HolidaysLoaded) {
          holidays = state.holidays;
        } else if (state is HolidaysOperationInProgress) {
          holidays = state.holidays;
        } else if (state is HolidaysOperationSuccess) {
          holidays = state.holidays;
        } else if (state is HolidaysOperationError) {
          holidays = state.holidays;
        }

        if (holidays.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No holidays found',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add your first holiday to get started',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }

        // Sort holidays by date
        final sortedHolidays = List<Holiday>.from(holidays)
          ..sort((a, b) => a.date.compareTo(b.date));

        return Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCobalt.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Holiday Name',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryCobalt,
                          fontSize: isMobile ? 13 : 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Date',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryCobalt,
                          fontSize: isMobile ? 13 : 14,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 100,
                      child: Text(
                        'Actions',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryCobalt,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              // Table Body
              Expanded(
                child: ListView.separated(
                  itemCount: sortedHolidays.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final holiday = sortedHolidays[index];
                    return _buildHolidayRow(
                      context,
                      holiday,
                      isMobile,
                      state is HolidaysOperationInProgress,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHolidayRow(
    BuildContext context,
    Holiday holiday,
    bool isMobile,
    bool isOperationInProgress,
  ) {
    // Check if the holiday is past
    final isPast = holiday.date.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: isPast ? Colors.grey[50] : Colors.white,
      child: Row(
        children: [
          // Holiday icon
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isPast
                  ? Colors.grey[200]
                  : AppTheme.primaryCobalt.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.celebration,
              color: isPast ? Colors.grey[500] : AppTheme.primaryCobalt,
              size: 20,
            ),
          ),
          // Holiday name
          Expanded(
            flex: 3,
            child: Text(
              holiday.name,
              style: TextStyle(
                color: isPast ? Colors.grey[600] : Colors.black87,
                fontSize: isMobile ? 13 : 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Date
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMM yyyy').format(holiday.date),
                  style: TextStyle(
                    color: isPast ? Colors.grey[500] : Colors.grey[700],
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('EEEE').format(holiday.date),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: isMobile ? 10 : 12,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppTheme.info,
                  onPressed: isOperationInProgress
                      ? null
                      : () => _showHolidayDialog(context, holiday: holiday),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppTheme.error,
                  onPressed: isOperationInProgress
                      ? null
                      : () => _showDeleteConfirmation(context, holiday),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHolidayDialog(BuildContext context, {Holiday? holiday}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<HolidaysBloc>(),
        child: HolidayFormDialog(holiday: holiday),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Holiday holiday) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error),
            SizedBox(width: 12),
            Text(
              'Delete Holiday',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${holiday.name}"?\n\nThis will also remove it from the attendance calendar.',
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black87),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<HolidaysBloc>().add(
                DeleteHolidayEvent(holidayId: holiday.id),
              );
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
