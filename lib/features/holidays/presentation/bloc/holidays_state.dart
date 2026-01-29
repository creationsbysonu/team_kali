part of 'holidays_bloc.dart';

abstract class HolidaysState extends Equatable {
  const HolidaysState();

  @override
  List<Object?> get props => [];
}

class HolidaysInitial extends HolidaysState {}

class HolidaysLoading extends HolidaysState {}

class HolidaysLoaded extends HolidaysState {
  final List<Holiday> holidays;

  const HolidaysLoaded({required this.holidays});

  @override
  List<Object?> get props => [holidays];
}

class HolidaysError extends HolidaysState {
  final String message;

  const HolidaysError({required this.message});

  @override
  List<Object?> get props => [message];
}

class HolidaysOperationInProgress extends HolidaysState {
  final List<Holiday> holidays;

  const HolidaysOperationInProgress({required this.holidays});

  @override
  List<Object?> get props => [holidays];
}

class HolidaysOperationSuccess extends HolidaysState {
  final String message;
  final List<Holiday> holidays;

  const HolidaysOperationSuccess({
    required this.message,
    required this.holidays,
  });

  @override
  List<Object?> get props => [message, holidays];
}

class HolidaysOperationError extends HolidaysState {
  final String message;
  final List<Holiday> holidays;

  const HolidaysOperationError({required this.message, required this.holidays});

  @override
  List<Object?> get props => [message, holidays];
}
