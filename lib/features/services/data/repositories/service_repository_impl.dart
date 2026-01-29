import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/network/network_info.dart';
import 'package:sewa_web/features/services/data/data_sources/service_remote_data_source.dart';
import 'package:sewa_web/features/services/domain/entities/service.dart';
import 'package:sewa_web/features/services/domain/repositories/service_repository.dart';

/// Implementation of ServiceRepository
class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ServiceRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Service>>> getPublicServices({
    required String placeSlug,
    required String ministrySlug,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final services = await remoteDataSource.getPublicServices(
          placeSlug: placeSlug,
          ministrySlug: ministrySlug,
        );
        return Right(services);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<Service>>> getMinistryServices() async {
    if (await networkInfo.isConnected) {
      try {
        final services = await remoteDataSource.getMinistryServices();
        return Right(services);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Service>> getServiceById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final service = await remoteDataSource.getServiceById(id);
        return Right(service);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Service>> createService({
    required String name,
    required String slug,
    String? description,
    ServiceType? serviceType,
    double? feeAmount,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final service = await remoteDataSource.createService(
          name: name,
          slug: slug,
          description: description,
          serviceType: serviceType,
          feeAmount: feeAmount,
        );
        return Right(service);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Service>> updateService({
    required String id,
    String? name,
    String? slug,
    String? description,
    ServiceType? serviceType,
    double? feeAmount,
    bool? isActive,
    bool? isPublished,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final service = await remoteDataSource.updateService(
          id: id,
          name: name,
          slug: slug,
          description: description,
          serviceType: serviceType,
          feeAmount: feeAmount,
          isActive: isActive,
          isPublished: isPublished,
        );
        return Right(service);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteService(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteService(id);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
