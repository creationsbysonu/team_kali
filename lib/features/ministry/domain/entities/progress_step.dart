import 'package:equatable/equatable.dart';

/// Progress Step for tracking service progress
class ProgressStep extends Equatable {
  final String id;
  final String title;
  final int stepOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProgressStep({
    required this.id,
    required this.title,
    required this.stepOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, title, stepOrder, createdAt, updatedAt];

  ProgressStep copyWith({
    String? id,
    String? title,
    int? stepOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProgressStep(
      id: id ?? this.id,
      title: title ?? this.title,
      stepOrder: stepOrder ?? this.stepOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
