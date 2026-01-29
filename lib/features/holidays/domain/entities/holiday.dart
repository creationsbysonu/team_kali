import 'package:equatable/equatable.dart';

/// Holiday entity
class Holiday extends Equatable {
  final String id;
  final String name;
  final DateTime date;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Holiday({
    required this.id,
    required this.name,
    required this.date,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    date,
    description,
    createdAt,
    updatedAt,
  ];

  /// Get formatted date string
  String get formattedDate {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Check if holiday is in the future
  bool get isFuture => date.isAfter(DateTime.now());

  /// Check if holiday is today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Holiday copyWith({
    String? id,
    String? name,
    DateTime? date,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Holiday(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
