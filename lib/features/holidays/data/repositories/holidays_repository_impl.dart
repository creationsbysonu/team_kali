import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/network/network_info.dart';
import 'package:sewa_web/features/holidays/data/data_sources/holidays_remote_data_source.dart';
import 'package:sewa_web/features/holidays/domain/entities/holiday.dart';
import 'package:sewa_web/features/holidays/domain/repositories/holidays_repository.dart';

class HolidaysRepositoryImpl implements HolidaysRepository {
  final HolidaysRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  HolidaysRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Holiday>>> getHolidays({
    int? year,
    int? month,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final holidays = await remoteDataSource.getHolidays(
          year: year,
          month: month,
        );
        return Right(holidays);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: "No internet connection"));
    }
  }

  @override
  Future<Either<Failure, Holiday>> getHolidayById(String holidayId) async {
    if (await networkInfo.isConnected) {
      try {
        final holiday = await remoteDataSource.getHolidayById(holidayId);
        return Right(holiday);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: "No internet connection"));
    }
  }

  @override
  Future<Either<Failure, Holiday>> createHoliday({
    required String name,
    required DateTime date,
    String? description,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final holidayData = {
          'name': name,
          'date': date.toIso8601String().split('T')[0],
          'description': description ?? '',
        };
        final holiday = await remoteDataSource.createHoliday(holidayData);
        return Right(holiday);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: "No internet connection"));
    }
  }

  @override
  Future<Either<Failure, Holiday>> updateHoliday({
    required String holidayId,
    required String name,
    required DateTime date,
    String? description,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final holidayData = {
          'name': name,
          'date': date.toIso8601String().split('T')[0],
          'description': description ?? '',
        };
        final holiday = await remoteDataSource.updateHoliday(
          holidayId,
          holidayData,
        );
        return Right(holiday);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: "No internet connection"));
    }
  }

  @override
  Future<Either<Failure, void>> deleteHoliday(String holidayId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteHoliday(holidayId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: "No internet connection"));
    }
  }
}
