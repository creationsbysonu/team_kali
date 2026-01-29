import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/profile/domain/entities/place_entity.dart';
import 'package:sewa_sathi/features/profile/domain/repositories/profile_repository.dart';

/// Use case to get the list of available places.
class GetPlacesUseCase implements UseCase<List<PlaceEntity>, NoParams> {
  final ProfileRepository repository;

  GetPlacesUseCase(this.repository);

  @override
  Future<Either<Failure, List<PlaceEntity>>> call(NoParams params) async {
    return await repository.getPlaces();
  }
}
