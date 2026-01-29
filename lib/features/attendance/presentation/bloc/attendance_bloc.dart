import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_calendar_data.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_record.dart';
import 'package:sewa_web/features/attendance/domain/usecases/attendance_usecases.dart';

part 'attendance_event.dart';
part 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final GetPersonsUseCase getPersons;
  final GetAttendanceCalendarUseCase getAttendanceCalendar;
  final MarkAttendanceUseCase markAttendance;
  final BulkMarkAttendanceUseCase bulkMarkAttendance;

  AttendanceBloc({
    required this.getPersons,
    required this.getAttendanceCalendar,
    required this.markAttendance,
    required this.bulkMarkAttendance,
  }) : super(AttendanceInitial()) {
    on<LoadPersonsEvent>(_onLoadPersons);
    on<MarkAttendanceEvent>(_onMarkAttendance);
    on<LoadAttendanceCalendarEvent>(_onLoadAttendanceCalendar);
    on<MarkSingleAttendanceEvent>(_onMarkSingleAttendance);
    on<BulkMarkAttendanceEvent>(_onBulkMarkAttendance);
  }

  Future<void> _onLoadPersons(
    LoadPersonsEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());

    final result = await getPersons(
      GetPersonsParams(
        personType: event.personType,
        ministryId: null, // Will be added from auth context if needed
      ),
    );

    result.fold(
      (failure) => emit(AttendanceError(message: failure.message)),
      (persons) => emit(PersonsLoaded(persons: persons)),
    );
  }

  Future<void> _onMarkAttendance(
    MarkAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    // Delegate to MarkSingleAttendanceEvent
    add(
      MarkSingleAttendanceEvent(
        personType: event.personType,
        personId: event.personId,
        date: event.date,
        status: event.status,
        reason: event.reason,
      ),
    );
  }

  Future<void> _onLoadAttendanceCalendar(
    LoadAttendanceCalendarEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());

    final result = await getAttendanceCalendar(
      GetAttendanceCalendarParams(
        personType: event.personType,
        personId: event.personId,
        startDate: event.startDate,
        endDate: event.endDate,
      ),
    );

    result.fold(
      (failure) => emit(AttendanceError(message: failure.message)),
      (calendarData) =>
          emit(AttendanceCalendarLoaded(calendarData: calendarData)),
    );
  }

  Future<void> _onMarkSingleAttendance(
    MarkSingleAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state is AttendanceCalendarLoaded) {
      final currentState = state as AttendanceCalendarLoaded;
      emit(
        AttendanceOperationInProgress(calendarData: currentState.calendarData),
      );

      final result = await markAttendance(
        MarkAttendanceParams(
          personType: event.personType,
          personId: event.personId,
          date: event.date,
          status: event.status,
          reason: event.reason,
        ),
      );

      result.fold(
        (failure) => emit(
          AttendanceOperationError(
            message: failure.message,
            calendarData: currentState.calendarData,
          ),
        ),
        (record) {
          // Update calendar data with new record
          final updatedRecords =
              currentState.calendarData.records
                  .where((r) => r.date != record.date)
                  .toList()
                ..add(record);

          final updatedCalendarData = currentState.calendarData.copyWith(
            records: updatedRecords,
          );

          emit(
            AttendanceOperationSuccess(
              message: 'Attendance marked successfully',
              calendarData: updatedCalendarData,
            ),
          );
          emit(AttendanceCalendarLoaded(calendarData: updatedCalendarData));
        },
      );
    }
  }

  Future<void> _onBulkMarkAttendance(
    BulkMarkAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state is AttendanceCalendarLoaded) {
      final currentState = state as AttendanceCalendarLoaded;
      emit(
        AttendanceOperationInProgress(calendarData: currentState.calendarData),
      );

      final result = await bulkMarkAttendance(
        BulkMarkAttendanceParams(attendanceData: event.attendanceData),
      );

      result.fold(
        (failure) => emit(
          AttendanceOperationError(
            message: failure.message,
            calendarData: currentState.calendarData,
          ),
        ),
        (records) {
          emit(
            AttendanceOperationSuccess(
              message: 'Bulk attendance marked successfully',
              calendarData: currentState.calendarData,
            ),
          );
          // Reload calendar to get updated data
          add(
            LoadAttendanceCalendarEvent(
              personType: currentState.calendarData.personType.value,
              personId: currentState.calendarData.personId,
              startDate: currentState.calendarData.startDate,
              endDate: currentState.calendarData.endDate,
            ),
          );
        },
      );
    }
  }
}
