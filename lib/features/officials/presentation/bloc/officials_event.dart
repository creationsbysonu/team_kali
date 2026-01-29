part of 'officials_bloc.dart';

/// Base event class for Officials feature
abstract class OfficialsEvent extends Equatable {
  const OfficialsEvent();

  @override
  List<Object?> get props => [];
}

/// Load all officials for a ministry
class LoadOfficialsEvent extends OfficialsEvent {
  final String ministryId;

  const LoadOfficialsEvent({required this.ministryId});

  @override
  List<Object?> get props => [ministryId];
}

/// Load a single official by ID
class LoadOfficialByIdEvent extends OfficialsEvent {
  final String officialId;

  const LoadOfficialByIdEvent({required this.officialId});

  @override
  List<Object?> get props => [officialId];
}

/// Create a new official
class CreateOfficialEvent extends OfficialsEvent {
  final String ministryId;
  final String name;
  final String role;

  const CreateOfficialEvent({
    required this.ministryId,
    required this.name,
    required this.role,
  });

  @override
  List<Object?> get props => [ministryId, name, role];
}

/// Update an existing official
class UpdateOfficialEvent extends OfficialsEvent {
  final String ministryId;
  final String officialId;
  final String name;
  final String role;
  final bool isActive;

  const UpdateOfficialEvent({
    required this.ministryId,
    required this.officialId,
    required this.name,
    required this.role,
    required this.isActive,
  });

  @override
  List<Object?> get props => [ministryId, officialId, name, role, isActive];
}

/// Delete an official
class DeleteOfficialEvent extends OfficialsEvent {
  final String ministryId;
  final String officialId;

  const DeleteOfficialEvent({
    required this.ministryId,
    required this.officialId,
  });

  @override
  List<Object?> get props => [ministryId, officialId];
}
