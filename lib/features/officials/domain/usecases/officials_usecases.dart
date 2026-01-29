import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/officials/domain/entities/official.dart';
import 'package:sewa_web/features/officials/domain/repositories/officials_repository.dart';

/// Get all officials for a ministry
class GetOfficialsUseCase implements UseCase<List<Official>, String> {
  final OfficialsRepository repository;

  GetOfficialsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Official>>> call(String ministryId) async {
    if (ministryId.isEmpty) {
      return const Left(
        ValidationFailure(message: "Ministry ID cannot be empty"),
      );
    }
    return repository.getOfficials(ministryId);
  }
}

/// Get a single official by ID
class GetOfficialByIdUseCase implements UseCase<Official, String> {
  final OfficialsRepository repository;

  GetOfficialByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Official>> call(String officialId) async {
    if (officialId.isEmpty) {
      return const Left(
        ValidationFailure(message: "Official ID cannot be empty"),
      );
    }
    return repository.getOfficialById(officialId);
  }
}

/// Parameters for creating an official
class CreateOfficialParams {
  final String ministryId;
  final String name;
  final String role;

  const CreateOfficialParams({
    required this.ministryId,
    required this.name,
    required this.role,
  });
}

/// Create a new official
class CreateOfficialUseCase implements UseCase<Official, CreateOfficialParams> {
  final OfficialsRepository repository;

  CreateOfficialUseCase(this.repository);

  @override
  Future<Either<Failure, Official>> call(CreateOfficialParams params) async {
    // Validate params
    if (params.ministryId.isEmpty) {
      return const Left(
        ValidationFailure(message: "Ministry ID cannot be empty"),
      );
    }

    if (params.name.trim().isEmpty) {
      return const Left(ValidationFailure(message: "Name cannot be empty"));
    }

    if (params.role.trim().isEmpty) {
      return const Left(ValidationFailure(message: "Role cannot be empty"));
    }

    return repository.createOfficial(
      ministryId: params.ministryId,
      name: params.name,
      role: params.role,
    );
  }
}

/// Parameters for updating an official
class UpdateOfficialParams {
  final String officialId;
  final String name;
  final String role;
  final bool isActive;

  const UpdateOfficialParams({
    required this.officialId,
    required this.name,
    required this.role,
    required this.isActive,
  });
}

/// Update an existing official
class UpdateOfficialUseCase implements UseCase<Official, UpdateOfficialParams> {
  final OfficialsRepository repository;

  UpdateOfficialUseCase(this.repository);

  @override
  Future<Either<Failure, Official>> call(UpdateOfficialParams params) async {
    // Validate params
    if (params.officialId.isEmpty) {
      return const Left(
        ValidationFailure(message: "Official ID cannot be empty"),
      );
    }

    if (params.name.trim().isEmpty) {
      return const Left(ValidationFailure(message: "Name cannot be empty"));
    }

    if (params.role.trim().isEmpty) {
      return const Left(ValidationFailure(message: "Role cannot be empty"));
    }

    return repository.updateOfficial(
      officialId: params.officialId,
      name: params.name,
      role: params.role,
      isActive: params.isActive,
    );
  }
}

/// Delete an official
class DeleteOfficialUseCase implements UseCase<void, String> {
  final OfficialsRepository repository;

  DeleteOfficialUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String officialId) async {
    if (officialId.isEmpty) {
      return const Left(
        ValidationFailure(message: "Official ID cannot be empty"),
      );
    }
    return repository.deleteOfficial(officialId);
  }
}
