import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:sewa_sathi/core/errors/exceptions.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/network/network_info.dart';
import 'package:sewa_sathi/features/get_token/data/data_sources/get_token_remote_data_source.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/get_token_entities.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/paginated_response.dart';
import 'package:sewa_sathi/features/get_token/domain/repositories/get_token_repository.dart';

/// Implementation of GetTokenRepository.
/// Supports cursor-based pagination following Citizen API v1.
class GetTokenRepositoryImpl implements GetTokenRepository {
  final GetTokenRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  GetTokenRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, PaginatedMinistriesResponse<MinistryEntity>>>
  getMinistriesByPlace({
    required String placeId,
    String? cursor,
    int pageSize = 20,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getMinistriesByPlace(
          placeId: placeId,
          cursor: cursor,
          pageSize: pageSize,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        debugPrint('❌ Repository error (getMinistriesByPlace): $e');
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, PaginatedServicesResponse<StaffServiceEntity>>>
  getServicesByMinistry({
    required String ministryId,
    String? cursor,
    int pageSize = 20,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getServicesByMinistry(
          ministryId: ministryId,
          cursor: cursor,
          pageSize: pageSize,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        debugPrint('❌ Repository error (getServicesByMinistry): $e');
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, QueueConfigEntity>> getServiceDetails(
    String serviceId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final details = await remoteDataSource.getServiceDetails(serviceId);
        return Right(details);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        debugPrint('❌ Repository error (getServiceDetails): $e');
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, QueueTokenEntity>> bookToken({
    required String serviceId,
    required String bookingType,
    String? bookingDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final token = await remoteDataSource.bookToken(
          serviceId: serviceId,
          bookingType: bookingType,
          bookingDate: bookingDate,
        );
        return Right(token);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        debugPrint('❌ Repository error (bookToken): $e');
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<QueueTokenEntity>>> getMyTokens({
    String? status,
    String? cursor,
    int pageSize = 20,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getMyTokens(
          status: status,
          cursor: cursor,
          pageSize: pageSize,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        debugPrint('❌ Repository error (getMyTokens): $e');
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelToken(String tokenId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.cancelToken(tokenId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        debugPrint('❌ Repository error (cancelToken): $e');
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
