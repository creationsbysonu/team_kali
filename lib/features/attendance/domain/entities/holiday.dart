import 'package:equatable/equatable.dart';

/// Holiday entity for attendance calendar
class Holiday extends Equatable {
  final String id;
  final String name;
  final DateTime date;
  final String? description;
  final bool isRecurring;

  const Holiday({
    required this.id,
    required this.name,
    required this.date,
    this.description,
    this.isRecurring = false,
  });

  @override
  List<Object?> get props => [id, name, date, description, isRecurring];

  /// Check if this holiday falls on a specific date
  bool fallsOn(DateTime checkDate) {
    return date.year == checkDate.year &&
        date.month == checkDate.month &&
        date.day == checkDate.day;
  }
}
