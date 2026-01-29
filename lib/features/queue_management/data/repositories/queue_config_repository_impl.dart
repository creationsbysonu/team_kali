import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/network/network_info.dart';
import 'package:sewa_web/features/queue_management/data/data_sources/queue_config_remote_data_source.dart';
import 'package:sewa_web/features/queue_management/domain/entities/queue_configuration.dart';
import 'package:sewa_web/features/queue_management/domain/repositories/queue_config_repository.dart';

class QueueConfigRepositoryImpl implements QueueConfigRepository {
  final QueueConfigRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  QueueConfigRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAllServicesWithConfigs(
    String ministryId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getAllServicesWithConfigStatus(
          ministryId,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, QueueConfiguration?>> getConfigByService(
    String staffServiceId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final config = await remoteDataSource.getConfigByService(
          staffServiceId,
        );
        return Right(config);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, QueueConfiguration>> createConfig(
    Map<String, dynamic> configData,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final config = await remoteDataSource.createConfig(configData);
        return Right(config);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, QueueConfiguration>> updateConfig(
    String configId,
    Map<String, dynamic> configData,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final config = await remoteDataSource.updateConfig(
          configId,
          configData,
        );
        return Right(config);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteConfig(String configId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteConfig(configId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
