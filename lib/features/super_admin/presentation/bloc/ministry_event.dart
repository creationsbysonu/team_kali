part of 'ministry_bloc.dart';

abstract class MinistryEvent extends Equatable {
  const MinistryEvent();

  @override
  List<Object?> get props => [];
}

/// Load places for filter dropdown
class LoadPlacesForFilterEvent extends MinistryEvent {}

/// Load ministries with optional filters
class LoadMinistriesEvent extends MinistryEvent {
  final String? placeId;
  final String? status;
  final String? search;

  const LoadMinistriesEvent({this.placeId, this.status, this.search});

  @override
  List<Object?> get props => [placeId, status, search];
}

/// Load deleted ministries
class LoadDeletedMinistriesEvent extends MinistryEvent {}

/// Refresh ministries (keeps current data while loading)
class RefreshMinistriesEvent extends MinistryEvent {}

/// Create a new ministry
class CreateMinistryEvent extends MinistryEvent {
  final String placeId; // Required - ministry must belong to a place
  final String name;
  final String email;
  final String password;
  final String? description;
  final String? phone;
  final String? address;
  final String? website;
  final Uint8List? logoBytes;
  final String? logoFileName;

  const CreateMinistryEvent({
    required this.placeId,
    required this.name,
    required this.email,
    required this.password,
    this.description,
    this.phone,
    this.address,
    this.website,
    this.logoBytes,
    this.logoFileName,
  });

  @override
  List<Object?> get props => [
    placeId,
    name,
    email,
    password,
    description,
    phone,
    address,
    website,
    logoBytes,
    logoFileName,
  ];
}

/// Update an existing ministry
class UpdateMinistryEvent extends MinistryEvent {
  final String ministryId;
  final String? name;
  final String? description;
  final String? phone;
  final String? address;
  final String? website;
  final Uint8List? logoBytes;
  final String? logoFileName;

  const UpdateMinistryEvent({
    required this.ministryId,
    this.name,
    this.description,
    this.phone,
    this.address,
    this.website,
    this.logoBytes,
    this.logoFileName,
  });

  @override
  List<Object?> get props => [
    ministryId,
    name,
    description,
    phone,
    address,
    website,
    logoBytes,
    logoFileName,
  ];
}

/// Activate a ministry
class ActivateMinistryEvent extends MinistryEvent {
  final String ministryId;

  const ActivateMinistryEvent({required this.ministryId});

  @override
  List<Object?> get props => [ministryId];
}

/// Suspend a ministry
class SuspendMinistryEvent extends MinistryEvent {
  final String ministryId;
  final String? reason;

  const SuspendMinistryEvent({required this.ministryId, this.reason});

  @override
  List<Object?> get props => [ministryId, reason];
}

/// Soft delete a ministry
class DeleteMinistryEvent extends MinistryEvent {
  final String ministryId;

  const DeleteMinistryEvent({required this.ministryId});

  @override
  List<Object?> get props => [ministryId];
}

/// Restore a soft-deleted ministry
class RestoreMinistryEvent extends MinistryEvent {
  final String ministryId;

  const RestoreMinistryEvent({required this.ministryId});

  @override
  List<Object?> get props => [ministryId];
}

/// Permanently delete a ministry (hard delete)
class HardDeleteMinistryEvent extends MinistryEvent {
  final String ministryId;

  const HardDeleteMinistryEvent({required this.ministryId});

  @override
  List<Object?> get props => [ministryId];
}

/// Reset ministry admin password
class ResetMinistryPasswordEvent extends MinistryEvent {
  final String ministryId;
  final String newPassword;

  const ResetMinistryPasswordEvent({
    required this.ministryId,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [ministryId, newPassword];
}

/// Refresh all ministries (active + deleted) in sequence
/// Use this instead of firing LoadMinistriesEvent and LoadDeletedMinistriesEvent separately
class RefreshAllMinistriesEvent extends MinistryEvent {
  const RefreshAllMinistriesEvent();
}
