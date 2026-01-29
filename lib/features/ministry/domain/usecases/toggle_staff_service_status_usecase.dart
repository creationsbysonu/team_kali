import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/ministry/domain/entities/staff_service_entity.dart';
import 'package:sewa_web/features/ministry/domain/repositories/staff_service_repository.dart';

/// Use case to toggle staff service status (active/paused)
class ToggleStaffServiceStatusUseCase
    implements UseCase<StaffService, ToggleStaffServiceStatusParams> {
  final StaffServiceRepository repository;

  ToggleStaffServiceStatusUseCase(this.repository);

  @override
  Future<Either<Failure, StaffService>> call(
    ToggleStaffServiceStatusParams params,
  ) {
    if (params.id.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Service ID cannot be empty')),
      );
    }
    return repository.toggleStaffServiceStatus(params.id.trim());
  }
}

class ToggleStaffServiceStatusParams extends Equatable {
  final String id;

  const ToggleStaffServiceStatusParams({required this.id});

  @override
  List<Object?> get props => [id];
}
