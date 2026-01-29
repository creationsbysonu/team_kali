import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/super_admin/domain/entities/place_filter_option.dart';
import 'package:sewa_web/features/super_admin/domain/repositories/ministry_repository.dart';

/// Use case for getting places for filter dropdown
/// API: GET /ministry/admin/places/
class GetPlacesForFilterUseCase
    implements UseCase<List<PlaceFilterOption>, NoParams> {
  final MinistryRepository repository;

  GetPlacesForFilterUseCase(this.repository);

  @override
  Future<Either<Failure, List<PlaceFilterOption>>> call(NoParams params) {
    return repository.getPlacesForFilter();
  }
}
