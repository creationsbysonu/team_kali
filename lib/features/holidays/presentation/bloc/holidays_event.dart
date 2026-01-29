part of 'holidays_bloc.dart';

abstract class HolidaysEvent extends Equatable {
  const HolidaysEvent();

  @override
  List<Object?> get props => [];
}

class LoadHolidaysEvent extends HolidaysEvent {
  final int? year;
  final int? month;

  const LoadHolidaysEvent({this.year, this.month});

  @override
  List<Object?> get props => [year, month];
}

class CreateHolidayEvent extends HolidaysEvent {
  final String name;
  final DateTime date;
  final String? description;

  const CreateHolidayEvent({
    required this.name,
    required this.date,
    this.description,
  });

  @override
  List<Object?> get props => [name, date, description];
}

class UpdateHolidayEvent extends HolidaysEvent {
  final String holidayId;
  final String name;
  final DateTime date;
  final String? description;

  const UpdateHolidayEvent({
    required this.holidayId,
    required this.name,
    required this.date,
    this.description,
  });

  @override
  List<Object?> get props => [holidayId, name, date, description];
}

class DeleteHolidayEvent extends HolidaysEvent {
  final String holidayId;

  const DeleteHolidayEvent({required this.holidayId});

  @override
  List<Object?> get props => [holidayId];
}
