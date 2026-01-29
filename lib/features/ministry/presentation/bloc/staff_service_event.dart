part of 'staff_service_bloc.dart';

abstract class StaffServiceEvent extends Equatable {
  const StaffServiceEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all staff services
class LoadStaffServicesEvent extends StaffServiceEvent {}

/// Event to create a new staff service
class CreateStaffServiceEvent extends StaffServiceEvent {
  final String serviceName;
  final String staffName;
  final String email;
  final String password;
  final Uint8List? serviceLogoBytes;
  final String? serviceLogoFileName;
  final Uint8List? staffImageBytes;
  final String? staffImageFileName;

  const CreateStaffServiceEvent({
    required this.serviceName,
    required this.staffName,
    required this.email,
    required this.password,
    this.serviceLogoBytes,
    this.serviceLogoFileName,
    this.staffImageBytes,
    this.staffImageFileName,
  });

  @override
  List<Object?> get props => [
    serviceName,
    staffName,
    email,
    password,
    serviceLogoBytes,
    serviceLogoFileName,
    staffImageBytes,
    staffImageFileName,
  ];
}

/// Event to update an existing staff service
class UpdateStaffServiceEvent extends StaffServiceEvent {
  final String id;
  final String? serviceName;
  final String? staffName;
  final Uint8List? serviceLogoBytes;
  final String? serviceLogoFileName;
  final Uint8List? staffImageBytes;
  final String? staffImageFileName;

  const UpdateStaffServiceEvent({
    required this.id,
    this.serviceName,
    this.staffName,
    this.serviceLogoBytes,
    this.serviceLogoFileName,
    this.staffImageBytes,
    this.staffImageFileName,
  });

  @override
  List<Object?> get props => [
    id,
    serviceName,
    staffName,
    serviceLogoBytes,
    serviceLogoFileName,
    staffImageBytes,
    staffImageFileName,
  ];
}

/// Event to delete a staff service
class DeleteStaffServiceEvent extends StaffServiceEvent {
  final String id;

  const DeleteStaffServiceEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Event to reset staff password
class ResetStaffPasswordEvent extends StaffServiceEvent {
  final String id;
  final String newPassword;

  const ResetStaffPasswordEvent({required this.id, required this.newPassword});

  @override
  List<Object?> get props => [id, newPassword];
}

/// Event to toggle staff service status
class ToggleStaffServiceStatusEvent extends StaffServiceEvent {
  final String id;

  const ToggleStaffServiceStatusEvent({required this.id});

  @override
  List<Object?> get props => [id];
}
