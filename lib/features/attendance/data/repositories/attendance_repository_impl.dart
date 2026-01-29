import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/network/network_info.dart';
import 'package:sewa_web/features/attendance/data/data_sources/attendance_remote_data_source.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_calendar_data.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_record.dart';
import 'package:sewa_web/features/attendance/domain/repositories/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AttendanceRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Map<String, String>>>> getPersons({
    required String personType,
    String? ministryId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final persons = await remoteDataSource.getPersons(
          personType: personType,
          ministryId: ministryId,
        );
        return Right(persons);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, AttendanceCalendarData>> getAttendanceCalendar({
    required String personType,
    required String personId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final calendarData = await remoteDataSource.getAttendanceCalendar(
        personType: personType,
        personId: personId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(calendarData);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to fetch attendance: $e'));
    }
  }

  @override
  Future<Either<Failure, AttendanceRecord>> markAttendance({
    required String personType,
    required String personId,
    required DateTime date,
    required String status,
    String? reason,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final record = await remoteDataSource.markAttendance(
        personType: personType,
        personId: personId,
        date: date,
        status: status,
        reason: reason,
      );
      return Right(record);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to mark attendance: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AttendanceRecord>>> bulkMarkAttendance({
    required List<Map<String, dynamic>> attendanceData,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final records = await remoteDataSource.bulkMarkAttendance(
        attendanceData: attendanceData,
      );
      return Right(records);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to bulk mark attendance: $e'));
    }
  }
}
