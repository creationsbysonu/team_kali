import 'package:equatable/equatable.dart';

/// Official entity
class Official extends Equatable {
  final String id;
  final String ministryId;
  final String ministryName;
  final String name;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Official({
    required this.id,
    required this.ministryId,
    required this.ministryName,
    required this.name,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    ministryId,
    ministryName,
    name,
    role,
    isActive,
    createdAt,
    updatedAt,
  ];

  /// Display format for dropdowns: "Name - Role"
  String get displayName => '$name - $role';

  Official copyWith({
    String? id,
    String? ministryId,
    String? ministryName,
    String? name,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Official(
      id: id ?? this.id,
      ministryId: ministryId ?? this.ministryId,
      ministryName: ministryName ?? this.ministryName,
      name: name ?? this.name,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
