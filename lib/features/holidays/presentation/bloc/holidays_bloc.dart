import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/features/holidays/domain/entities/holiday.dart';
import 'package:sewa_web/features/holidays/domain/usecases/holidays_usecases.dart';

part 'holidays_event.dart';
part 'holidays_state.dart';

class HolidaysBloc extends Bloc<HolidaysEvent, HolidaysState> {
  final GetHolidaysUseCase getHolidays;
  final CreateHolidayUseCase createHoliday;
  final UpdateHolidayUseCase updateHoliday;
  final DeleteHolidayUseCase deleteHoliday;

  HolidaysBloc({
    required this.getHolidays,
    required this.createHoliday,
    required this.updateHoliday,
    required this.deleteHoliday,
  }) : super(HolidaysInitial()) {
    on<LoadHolidaysEvent>(_onLoadHolidays);
    on<CreateHolidayEvent>(_onCreateHoliday);
    on<UpdateHolidayEvent>(_onUpdateHoliday);
    on<DeleteHolidayEvent>(_onDeleteHoliday);
  }

  Future<void> _onLoadHolidays(
    LoadHolidaysEvent event,
    Emitter<HolidaysState> emit,
  ) async {
    emit(HolidaysLoading());

    final result = await getHolidays(
      GetHolidaysParams(year: event.year, month: event.month),
    );

    result.fold(
      (failure) => emit(HolidaysError(message: failure.message)),
      (holidays) => emit(HolidaysLoaded(holidays: holidays)),
    );
  }

  Future<void> _onCreateHoliday(
    CreateHolidayEvent event,
    Emitter<HolidaysState> emit,
  ) async {
    if (state is HolidaysLoaded) {
      final currentState = state as HolidaysLoaded;
      emit(HolidaysOperationInProgress(holidays: currentState.holidays));

      final result = await createHoliday(
        CreateHolidayParams(
          name: event.name,
          date: event.date,
          description: event.description,
        ),
      );

      result.fold(
        (failure) => emit(
          HolidaysOperationError(
            message: failure.message,
            holidays: currentState.holidays,
          ),
        ),
        (newHoliday) {
          final updatedHolidays = [...currentState.holidays, newHoliday];
          emit(
            HolidaysOperationSuccess(
              message: 'Holiday created successfully',
              holidays: updatedHolidays,
            ),
          );
          emit(HolidaysLoaded(holidays: updatedHolidays));
        },
      );
    }
  }

  Future<void> _onUpdateHoliday(
    UpdateHolidayEvent event,
    Emitter<HolidaysState> emit,
  ) async {
    if (state is HolidaysLoaded) {
      final currentState = state as HolidaysLoaded;
      emit(HolidaysOperationInProgress(holidays: currentState.holidays));

      final result = await updateHoliday(
        UpdateHolidayParams(
          holidayId: event.holidayId,
          name: event.name,
          date: event.date,
          description: event.description,
        ),
      );

      result.fold(
        (failure) => emit(
          HolidaysOperationError(
            message: failure.message,
            holidays: currentState.holidays,
          ),
        ),
        (updatedHoliday) {
          final updatedHolidays = currentState.holidays.map((holiday) {
            return holiday.id == updatedHoliday.id ? updatedHoliday : holiday;
          }).toList();
          emit(
            HolidaysOperationSuccess(
              message: 'Holiday updated successfully',
              holidays: updatedHolidays,
            ),
          );
          emit(HolidaysLoaded(holidays: updatedHolidays));
        },
      );
    }
  }

  Future<void> _onDeleteHoliday(
    DeleteHolidayEvent event,
    Emitter<HolidaysState> emit,
  ) async {
    if (state is HolidaysLoaded) {
      final currentState = state as HolidaysLoaded;
      emit(HolidaysOperationInProgress(holidays: currentState.holidays));

      final result = await deleteHoliday(
        DeleteHolidayParams(holidayId: event.holidayId),
      );

      result.fold(
        (failure) => emit(
          HolidaysOperationError(
            message: failure.message,
            holidays: currentState.holidays,
          ),
        ),
        (_) {
          final updatedHolidays = currentState.holidays
              .where((holiday) => holiday.id != event.holidayId)
              .toList();
          emit(
            HolidaysOperationSuccess(
              message: 'Holiday deleted successfully',
              holidays: updatedHolidays,
            ),
          );
          emit(HolidaysLoaded(holidays: updatedHolidays));
        },
      );
    }
  }
}
