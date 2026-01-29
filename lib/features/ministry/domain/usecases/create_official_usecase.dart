import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/ministry/domain/entities/ministry_official.dart';
import 'package:sewa_web/features/ministry/domain/repositories/officials_repository.dart';

class CreateOfficialParams extends Equatable {
  final String ministryId;
  final String name;
  final String role;
  final bool isActive;

  const CreateOfficialParams({
    required this.ministryId,
    required this.name,
    required this.role,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [ministryId, name, role, isActive];
}

/// Create new official
class CreateOfficialUseCase
    implements UseCase<MinistryOfficial, CreateOfficialParams> {
  final OfficialsRepository repository;

  CreateOfficialUseCase(this.repository);

  @override
  Future<Either<Failure, MinistryOfficial>> call(
    CreateOfficialParams params,
  ) async {
    // Business validation
    if (params.name.trim().isEmpty) {
      return const Left(ValidationFailure(message: "Name cannot be empty"));
    }

    if (params.role.trim().isEmpty) {
      return const Left(ValidationFailure(message: "Role cannot be empty"));
    }

    if (params.name.length > 100) {
      return const Left(
        ValidationFailure(message: "Name cannot exceed 100 characters"),
      );
    }

    if (params.role.length > 100) {
      return const Left(
        ValidationFailure(message: "Role cannot exceed 100 characters"),
      );
    }

    return await repository.createOfficial(
      ministryId: params.ministryId,
      name: params.name.trim(),
      role: params.role.trim(),
      isActive: params.isActive,
    );
  }
}
