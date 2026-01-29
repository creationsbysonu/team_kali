import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/profile/domain/entities/profile_entity.dart';
import 'package:sewa_sathi/features/profile/domain/repositories/profile_repository.dart';

/// Use case to update an existing profile.
class UpdateProfileUseCase
    implements UseCase<ProfileEntity, UpdateProfileParams> {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, ProfileEntity>> call(
    UpdateProfileParams params,
  ) async {
    // Validate if at least one field is provided
    if (params.fullName == null && params.placeId == null) {
      return const Left(
        ValidationFailure(
          message: 'Please provide at least one field to update',
        ),
      );
    }

    // Validate full name if provided
    if (params.fullName != null) {
      if (params.fullName!.trim().isEmpty) {
        return const Left(
          ValidationFailure(message: 'Full name cannot be empty'),
        );
      }

      if (params.fullName!.trim().length < 2) {
        return const Left(
          ValidationFailure(message: 'Name must be at least 2 characters'),
        );
      }
    }

    return await repository.updateProfile(
      fullName: params.fullName?.trim(),
      placeId: params.placeId?.trim(),
    );
  }
}

/// Parameters for updating a profile.
class UpdateProfileParams extends Equatable {
  final String? fullName;
  final String? placeId;

  const UpdateProfileParams({this.fullName, this.placeId});

  @override
  List<Object?> get props => [fullName, placeId];
}
