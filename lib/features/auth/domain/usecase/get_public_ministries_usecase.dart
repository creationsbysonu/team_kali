import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/auth/data/data_sources/public_ministry_data_source.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';

/// Use case to fetch public ministry list for login dropdown
class GetPublicMinistriesUseCase implements UseCase<List<Ministry>, NoParams> {
  final PublicMinistryDataSource dataSource;

  GetPublicMinistriesUseCase(this.dataSource);

  @override
  Future<Either<Failure, List<Ministry>>> call(NoParams params) async {
    try {
      final ministries = await dataSource.getPublicMinistries();
      return Right(ministries);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
