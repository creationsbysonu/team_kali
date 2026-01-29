part of 'staff_bloc.dart';

/// Base class for all staff events
abstract class StaffEvent extends Equatable {
  const StaffEvent();

  @override
  List<Object?> get props => [];
}

/// Load staff list
class LoadStaffEvent extends StaffEvent {}

/// Create staff member
class CreateStaffEvent extends StaffEvent {
  final String name;
  final String email;
  final String password;
  final String serviceId;
  final String? contact;
  final String? imagePath;

  const CreateStaffEvent({
    required this.name,
    required this.email,
    required this.password,
    required this.serviceId,
    this.contact,
    this.imagePath,
  });

  @override
  List<Object?> get props => [
    name,
    email,
    password,
    serviceId,
    contact,
    imagePath,
  ];
}

/// Update staff member
class UpdateStaffEvent extends StaffEvent {
  final String id;
  final String? name;
  final String? contact;
  final String? password;
  final bool? isActive;

  const UpdateStaffEvent({
    required this.id,
    this.name,
    this.contact,
    this.password,
    this.isActive,
  });

  @override
  List<Object?> get props => [id, name, contact, password, isActive];
}

/// Delete staff member
class DeleteStaffEvent extends StaffEvent {
  final String id;

  const DeleteStaffEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Reset staff password
class ResetStaffPasswordEvent extends StaffEvent {
  final String staffId;
  final String newPassword;

  const ResetStaffPasswordEvent({
    required this.staffId,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [staffId, newPassword];
}
