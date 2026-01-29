import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/staff/domain/entities/staff_member.dart';
import 'package:sewa_web/features/staff/domain/repositories/staff_repository.dart';

/// Get all staff in ministry
class GetMinistryStaffUseCase implements UseCase<List<StaffMember>, NoParams> {
  final StaffRepository repository;

  GetMinistryStaffUseCase(this.repository);

  @override
  Future<Either<Failure, List<StaffMember>>> call(NoParams params) {
    return repository.getMinistryStaff();
  }
}

/// Get staff by ID
class GetStaffByIdUseCase implements UseCase<StaffMember, String> {
  final StaffRepository repository;

  GetStaffByIdUseCase(this.repository);

  @override
  Future<Either<Failure, StaffMember>> call(String id) {
    return repository.getStaffById(id);
  }
}

/// Create staff params
class CreateStaffParams {
  final String name;
  final String email;
  final String password;
  final String serviceId;
  final String? contact;
  final String? imagePath;

  const CreateStaffParams({
    required this.name,
    required this.email,
    required this.password,
    required this.serviceId,
    this.contact,
    this.imagePath,
  });
}

/// Create staff
class CreateStaffUseCase implements UseCase<StaffMember, CreateStaffParams> {
  final StaffRepository repository;

  CreateStaffUseCase(this.repository);

  @override
  Future<Either<Failure, StaffMember>> call(CreateStaffParams params) {
    return repository.createStaff(
      name: params.name,
      email: params.email,
      password: params.password,
      serviceId: params.serviceId,
      contact: params.contact,
      imagePath: params.imagePath,
    );
  }
}

/// Update staff params
class UpdateStaffParams {
  final String id;
  final String? name;
  final String? contact;
  final String? password;
  final bool? isActive;

  const UpdateStaffParams({
    required this.id,
    this.name,
    this.contact,
    this.password,
    this.isActive,
  });
}

/// Update staff
class UpdateStaffUseCase implements UseCase<StaffMember, UpdateStaffParams> {
  final StaffRepository repository;

  UpdateStaffUseCase(this.repository);

  @override
  Future<Either<Failure, StaffMember>> call(UpdateStaffParams params) {
    return repository.updateStaff(
      id: params.id,
      name: params.name,
      contact: params.contact,
      password: params.password,
      isActive: params.isActive,
    );
  }
}

/// Delete staff
class DeleteStaffUseCase implements UseCase<void, String> {
  final StaffRepository repository;

  DeleteStaffUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return repository.deleteStaff(id);
  }
}

/// Reset password params
class ResetStaffPasswordParams {
  final String staffId;
  final String newPassword;

  const ResetStaffPasswordParams({
    required this.staffId,
    required this.newPassword,
  });
}

/// Reset staff password
class ResetStaffPasswordUseCase
    implements UseCase<void, ResetStaffPasswordParams> {
  final StaffRepository repository;

  ResetStaffPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ResetStaffPasswordParams params) {
    return repository.resetStaffPassword(
      staffId: params.staffId,
      newPassword: params.newPassword,
    );
  }
}
