import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/exceptions.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/network/network_info.dart';
import 'package:sewa_sathi/features/notice/data/data_sources/notice_remote_data_source.dart';
import 'package:sewa_sathi/features/notice/domain/entities/filter_options_entity.dart';
import 'package:sewa_sathi/features/notice/domain/entities/notice_detail_entity.dart';
import 'package:sewa_sathi/features/notice/domain/entities/notice_list_response_entity.dart';
import 'package:sewa_sathi/features/notice/domain/repositories/notice_repository.dart';

/// Implementation of NoticeRepository.
class NoticeRepositoryImpl implements NoticeRepository {
  final NoticeRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  NoticeRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, NoticeListResponseEntity>> getNotices({
    String? ministryId,
    String? serviceId,
    String? fileType,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getNotices(
          ministryId: ministryId,
          serviceId: serviceId,
          fileType: fileType,
          search: search,
          limit: limit,
          offset: offset,
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
  Future<Either<Failure, NoticeDetailEntity>> getNoticeDetail(
    String noticeId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getNoticeDetail(noticeId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, FilterOptionsEntity>> getFilterOptions() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getFilterOptions();
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
