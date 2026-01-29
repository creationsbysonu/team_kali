import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/features/attendance/data/data_sources/attendance_remote_data_source_v2.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_record.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_day.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_month_data.dart';
import 'package:sewa_web/features/attendance/domain/services/attendance_month_builder.dart';

part 'attendance_calendar_event.dart';
part 'attendance_calendar_state.dart';

/// BLoC for attendance calendar - proper state management
class AttendanceCalendarBloc
    extends Bloc<AttendanceCalendarEvent, AttendanceCalendarState> {
  final AttendanceRemoteDataSource remoteDataSource;

  // Current context
  String? _currentPersonType;
  String? _currentPersonId;

  AttendanceCalendarBloc({required this.remoteDataSource})
    : super(AttendanceCalendarInitial()) {
    on<LoadPersonsListEvent>(_onLoadPersonsList);
    on<LoadAttendanceMonthEvent>(_onLoadAttendanceMonth);
    on<MarkDayAbsentEvent>(_onMarkDayAbsent);
    on<RemoveAbsenceEvent>(_onRemoveAbsence);
    on<ChangePersonEvent>(_onChangePerson);
    on<ChangeMonthEvent>(_onChangeMonth);
  }

  Future<void> _onLoadPersonsList(
    LoadPersonsListEvent event,
    Emitter<AttendanceCalendarState> emit,
  ) async {
    emit(LoadingPersonsList());

    try {
      final persons = await remoteDataSource.getPersons(
        personType: event.personType,
      );

      emit(PersonsListLoaded(persons: persons));
    } catch (e) {
      emit(AttendanceCalendarError(message: 'Failed to load persons: $e'));
    }
  }

  Future<void> _onLoadAttendanceMonth(
    LoadAttendanceMonthEvent event,
    Emitter<AttendanceCalendarState> emit,
  ) async {
    // Store current context
    _currentPersonType = event.personType;
    _currentPersonId = event.personId;

    // Show loading (with previous data if exists)
    final previousData = state is MonthDataLoaded
        ? (state as MonthDataLoaded).monthData
        : null;
    emit(LoadingMonthData(previousData: previousData));

    try {
      // Calculate date range for the month
      final startDate = DateTime(event.year, event.month, 1);
      final endDate = DateTime(event.year, event.month + 1, 0);

      // Load data in parallel
      final results = await Future.wait([
        remoteDataSource.getAbsenceRecords(
          personType: event.personType,
          personId: event.personId,
          startDate: startDate,
          endDate: endDate,
        ),
        remoteDataSource.getHolidays(year: event.year, month: event.month),
      ]);

      final absenceRecords = results[0] as List;
      final holidays = results[1] as List;

      // Build month data with proper logic
      final monthData = AttendanceMonthBuilder.buildMonth(
        personId: event.personId,
        personName: remoteDataSource.getPersonName(event.personId),
        personType: _parsePersonType(event.personType),
        year: event.year,
        month: event.month,
        absenceRecords: absenceRecords.cast(),
        holidays: holidays.cast(),
      );

      emit(MonthDataLoaded(monthData: monthData));
    } catch (e) {
      emit(
        AttendanceCalendarError(
          message: 'Failed to load attendance: $e',
          currentData: previousData,
        ),
      );
    }
  }

  Future<void> _onMarkDayAbsent(
    MarkDayAbsentEvent event,
    Emitter<AttendanceCalendarState> emit,
  ) async {
    if (state is! MonthDataLoaded) return;

    final currentData = (state as MonthDataLoaded).monthData;

    emit(
      ProcessingAction(
        currentData: currentData,
        message: 'Marking as absent...',
      ),
    );

    try {
      // Call API to mark absent
      final record = await remoteDataSource.markAbsent(
        personType: _currentPersonType!,
        personId: _currentPersonId!,
        date: event.date,
        reason: event.reason,
      );

      // Update the day in month data
      final updatedDay = AttendanceDay(
        date: event.date,
        type: AttendanceDayType.absent,
        recordId: record.id,
        reason: event.reason,
        isEditable: true,
      );

      final updatedData = AttendanceMonthBuilder.updateDay(
        monthData: currentData,
        updatedDay: updatedDay,
      );

      emit(
        ActionCompleted(
          updatedData: updatedData,
          message: 'Marked as absent successfully',
        ),
      );

      // Return to loaded state
      emit(MonthDataLoaded(monthData: updatedData));
    } catch (e) {
      // Provide user-friendly error messages
      String errorMsg = e.toString();
      if (errorMsg.contains('unique set') ||
          errorMsg.contains('already exists')) {
        errorMsg =
            'This day is already marked as absent. Please refresh the calendar.';
      } else if (errorMsg.contains('ServerException')) {
        errorMsg = errorMsg.replaceAll('ServerException: ', '');
      }

      emit(
        AttendanceCalendarError(message: errorMsg, currentData: currentData),
      );

      // Return to previous state
      emit(MonthDataLoaded(monthData: currentData));
    }
  }

  Future<void> _onRemoveAbsence(
    RemoveAbsenceEvent event,
    Emitter<AttendanceCalendarState> emit,
  ) async {
    if (state is! MonthDataLoaded) return;

    final currentData = (state as MonthDataLoaded).monthData;

    emit(
      ProcessingAction(
        currentData: currentData,
        message: 'Removing absence...',
      ),
    );

    try {
      // Call API to remove absence
      await remoteDataSource.removeAbsence(recordId: event.recordId);

      // Check if the day is Saturday or Holiday (shouldn't happen, but handle it)
      final originalDay = currentData.getDayForDate(event.date);
      if (originalDay == null) return;

      // Update the day back to PRESENT
      final updatedDay = AttendanceDay(
        date: event.date,
        type: AttendanceDayType.present,
        isEditable: true,
      );

      final updatedData = AttendanceMonthBuilder.updateDay(
        monthData: currentData,
        updatedDay: updatedDay,
      );

      emit(
        ActionCompleted(
          updatedData: updatedData,
          message: 'Absence removed successfully',
        ),
      );

      // Return to loaded state
      emit(MonthDataLoaded(monthData: updatedData));
    } catch (e) {
      emit(
        AttendanceCalendarError(
          message: 'Failed to remove absence: $e',
          currentData: currentData,
        ),
      );

      // Return to previous state
      emit(MonthDataLoaded(monthData: currentData));
    }
  }

  Future<void> _onChangePerson(
    ChangePersonEvent event,
    Emitter<AttendanceCalendarState> emit,
  ) async {
    _currentPersonId = event.personId;

    // If we have a month loaded, reload with new person
    if (state is MonthDataLoaded) {
      final currentData = (state as MonthDataLoaded).monthData;
      add(
        LoadAttendanceMonthEvent(
          personType: _currentPersonType!,
          personId: event.personId,
          year: currentData.year,
          month: currentData.month,
        ),
      );
    }
  }

  Future<void> _onChangeMonth(
    ChangeMonthEvent event,
    Emitter<AttendanceCalendarState> emit,
  ) async {
    // Reload attendance with new month
    if (_currentPersonType != null && _currentPersonId != null) {
      add(
        LoadAttendanceMonthEvent(
          personType: _currentPersonType!,
          personId: _currentPersonId!,
          year: event.year,
          month: event.month,
        ),
      );
    }
  }

  // Helper to parse person type
  PersonType _parsePersonType(String type) {
    return type.toUpperCase() == 'STAFF'
        ? PersonType.staff
        : PersonType.official;
  }
}
