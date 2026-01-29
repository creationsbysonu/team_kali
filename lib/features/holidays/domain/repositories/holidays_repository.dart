import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/features/holidays/domain/entities/holiday.dart';

/// Holidays Repository Interface
abstract class HolidaysRepository {
  Future<Either<Failure, List<Holiday>>> getHolidays({int? year, int? month});
  Future<Either<Failure, Holiday>> getHolidayById(String holidayId);
  Future<Either<Failure, Holiday>> createHoliday({
    required String name,
    required DateTime date,
    String? description,
  });
  Future<Either<Failure, Holiday>> updateHoliday({
    required String holidayId,
    required String name,
    required DateTime date,
    String? description,
  });
  Future<Either<Failure, void>> deleteHoliday(String holidayId);
}
