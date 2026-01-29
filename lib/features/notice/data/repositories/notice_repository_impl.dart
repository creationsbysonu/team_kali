import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/network/network_info.dart';
import 'package:sewa_web/features/notice/data/data_sources/notice_remote_data_source.dart';
import 'package:sewa_web/features/notice/domain/entities/notice_entity.dart';
import 'package:sewa_web/features/notice/domain/repositories/notice_repository.dart';

/// Notice Repository Implementation
class NoticeRepositoryImpl implements NoticeRepository {
  final NoticeRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  NoticeRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, NoticeListResponse>> getNotices(
    GetNoticesParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getNotices(params);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, NoticeEntity>> getNoticeById(String noticeId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getNoticeById(noticeId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, NoticeEntity>> uploadNotice(
    UploadNoticeParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.uploadNotice(
          title: params.title,
          fileBytes: params.fileBytes,
          fileName: params.fileName,
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
  Future<Either<Failure, NoticeEntity>> updateNotice(
    UpdateNoticeParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updateNotice(
          noticeId: params.noticeId,
          title: params.title,
          serviceId: params.serviceId,
          isActive: params.isActive,
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
  Future<Either<Failure, void>> deleteNotice(String noticeId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteNotice(noticeId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, NoticeStatsEntity>> getStats() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getStats();
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> retryIngestion(String noticeId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.retryIngestion(noticeId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<NoticeServiceEntity>>> getServices() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getServices();
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
