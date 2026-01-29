import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/features/ministry/domain/entities/holiday.dart';

/// Abstract repository for Holidays operations
abstract class HolidaysRepository {
  /// List holidays (with optional filters)
  Future<Either<Failure, List<Holiday>>> getHolidays({int? year, int? month});

  /// Get holiday by ID
  Future<Either<Failure, Holiday>> getHolidayById(String id);

  /// Create new holiday
  Future<Either<Failure, Holiday>> createHoliday({
    required String name,
    required DateTime date,
    String? description,
  });

  /// Update holiday (only name and description, date is immutable)
  Future<Either<Failure, Holiday>> updateHoliday({
    required String id,
    String? name,
    String? description,
  });

  /// Delete holiday
  Future<Either<Failure, void>> deleteHoliday(String id);
}
