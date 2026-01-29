import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/profile/domain/entities/profile_entity.dart';
import 'package:sewa_sathi/features/profile/domain/repositories/profile_repository.dart';

/// Use case to setup a new profile with full name and place.
class SetupProfileUseCase
    implements UseCase<ProfileEntity, SetupProfileParams> {
  final ProfileRepository repository;

  SetupProfileUseCase(this.repository);

  @override
  Future<Either<Failure, ProfileEntity>> call(SetupProfileParams params) async {
    // Validate full name
    if (params.fullName.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Please enter your full name'),
      );
    }

    if (params.fullName.trim().length < 2) {
      return const Left(
        ValidationFailure(message: 'Name must be at least 2 characters'),
      );
    }

    // Validate place ID
    if (params.placeId.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Please select a place'));
    }

    return await repository.setupProfile(
      fullName: params.fullName.trim(),
      placeId: params.placeId.trim(),
    );
  }
}

/// Parameters for setting up a profile.
class SetupProfileParams extends Equatable {
  final String fullName;
  final String placeId;

  const SetupProfileParams({required this.fullName, required this.placeId});

  @override
  List<Object?> get props => [fullName, placeId];
}
