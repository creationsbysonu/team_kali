import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/places/domain/entities/place.dart';
import 'package:sewa_web/features/places/domain/repositories/place_repository.dart';

/// Get all public places for selection
class GetPublicPlacesUseCase implements UseCase<List<Place>, NoParams> {
  final PlaceRepository repository;

  GetPublicPlacesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Place>>> call(NoParams params) {
    return repository.getPublicPlaces();
  }
}

/// Get place by slug
class GetPlaceBySlugUseCase implements UseCase<Place, String> {
  final PlaceRepository repository;

  GetPlaceBySlugUseCase(this.repository);

  @override
  Future<Either<Failure, Place>> call(String slug) {
    return repository.getPlaceBySlug(slug);
  }
}

/// Get all places (admin)
class GetAllPlacesUseCase implements UseCase<List<Place>, NoParams> {
  final PlaceRepository repository;

  GetAllPlacesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Place>>> call(NoParams params) {
    return repository.getAllPlaces();
  }
}

/// Create place params
class CreatePlaceParams {
  final String name;
  final String slug;

  const CreatePlaceParams({required this.name, required this.slug});
}

/// Create place (super admin)
class CreatePlaceUseCase implements UseCase<Place, CreatePlaceParams> {
  final PlaceRepository repository;

  CreatePlaceUseCase(this.repository);

  @override
  Future<Either<Failure, Place>> call(CreatePlaceParams params) {
    return repository.createPlace(name: params.name, slug: params.slug);
  }
}

/// Update place params
class UpdatePlaceParams {
  final String id;
  final String? name;
  final String? slug;
  final bool? isActive;

  const UpdatePlaceParams({
    required this.id,
    this.name,
    this.slug,
    this.isActive,
  });
}

/// Update place
class UpdatePlaceUseCase implements UseCase<Place, UpdatePlaceParams> {
  final PlaceRepository repository;

  UpdatePlaceUseCase(this.repository);

  @override
  Future<Either<Failure, Place>> call(UpdatePlaceParams params) {
    return repository.updatePlace(
      id: params.id,
      name: params.name,
      slug: params.slug,
      isActive: params.isActive,
    );
  }
}

/// Delete place
class DeletePlaceUseCase implements UseCase<void, String> {
  final PlaceRepository repository;

  DeletePlaceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return repository.deletePlace(id);
  }
}
