import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/features/auth/data/data_sources/public_ministry_data_source.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/auth/domain/repositories/public_ministry_repository.dart';

/// Implementation of PublicMinistryRepository
class PublicMinistryRepositoryImpl implements PublicMinistryRepository {
  final PublicMinistryDataSource publicMinistryDataSource;

  PublicMinistryRepositoryImpl({required this.publicMinistryDataSource});

  @override
  Future<Either<Failure, List<Ministry>>> getMinistriesByPlace(
    String placeSlug,
  ) async {
    try {
      final ministries = await publicMinistryDataSource.getMinistriesByPlace(
        placeSlug,
      );
      return Right(ministries);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Ministry>> getMinistryDetail(
    String placeSlug,
    String ministrySlug,
  ) async {
    try {
      final ministry = await publicMinistryDataSource.getMinistryDetail(
        placeSlug,
        ministrySlug,
      );
      return Right(ministry);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }
}
