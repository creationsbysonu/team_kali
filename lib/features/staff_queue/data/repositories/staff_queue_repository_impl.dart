import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/network/network_info.dart';
import 'package:sewa_web/features/staff_queue/data/data_sources/staff_queue_data_source.dart';
import 'package:sewa_web/features/staff_queue/domain/entities/staff_token.dart';
import 'package:sewa_web/features/staff_queue/domain/repositories/staff_queue_repository.dart';

/// Staff Queue Repository Implementation (New Queue System)
class StaffQueueRepositoryImpl implements StaffQueueRepository {
  final StaffQueueRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  StaffQueueRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, ActiveTokensData>> getActiveTokens(
    String staffServiceId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getActiveTokens(staffServiceId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: "No internet connection"));
    }
  }

  @override
  Future<Either<Failure, AllTokensData>> getAllTokens(
    String staffServiceId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getAllTokens(staffServiceId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: "No internet connection"));
    }
  }

  @override
  Future<Either<Failure, PendingTokensData>> getPendingTokens(
    String staffServiceId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPendingTokens(staffServiceId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: "No internet connection"));
    }
  }

  @override
  Future<Either<Failure, StartServiceResult>> startService(
    String tokenId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.startService(tokenId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: "No internet connection"));
    }
  }

  @override
  Future<Either<Failure, NoShowResult>> markNoShow(String tokenId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.markNoShow(tokenId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: "No internet connection"));
    }
  }

  @override
  Future<Either<Failure, MarkPendingResult>> markPending(
    String tokenId,
    String reason,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.markPending(tokenId, reason);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: "No internet connection"));
    }
  }

  @override
  Future<Either<Failure, void>> sendPendingEmail(String tokenId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sendPendingEmail(tokenId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: "No internet connection"));
    }
  }

  @override
  Future<Either<Failure, MarkPendingServedResult>> markPendingServed(
    String tokenId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.markPendingServed(tokenId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: "No internet connection"));
    }
  }
}
