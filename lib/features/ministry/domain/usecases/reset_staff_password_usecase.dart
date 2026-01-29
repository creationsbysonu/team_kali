import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/ministry/domain/repositories/staff_service_repository.dart';

/// Use case to reset staff password
class ResetStaffPasswordUseCase
    implements UseCase<void, ResetStaffPasswordParams> {
  final StaffServiceRepository repository;

  ResetStaffPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ResetStaffPasswordParams params) {
    // Validation
    if (params.id.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Service ID cannot be empty')),
      );
    }

    if (params.newPassword.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Password cannot be empty')),
      );
    }

    if (params.newPassword.length < 6) {
      return Future.value(
        const Left(
          ValidationFailure(message: 'Password must be at least 6 characters'),
        ),
      );
    }

    return repository.resetStaffPassword(params.id.trim(), params.newPassword);
  }
}

class ResetStaffPasswordParams extends Equatable {
  final String id;
  final String newPassword;

  const ResetStaffPasswordParams({required this.id, required this.newPassword});

  @override
  List<Object?> get props => [id, newPassword];
}
