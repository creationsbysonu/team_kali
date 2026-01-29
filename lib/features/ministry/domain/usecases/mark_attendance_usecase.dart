import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/ministry/domain/entities/attendance_record.dart';
import 'package:sewa_web/features/ministry/domain/repositories/attendance_repository.dart';

class MarkAttendanceParams extends Equatable {
  final PersonType personType;
  final String personId;
  final DateTime date;
  final AttendanceStatus status;
  final String? reason;

  const MarkAttendanceParams({
    required this.personType,
    required this.personId,
    required this.date,
    required this.status,
    this.reason,
  });

  @override
  List<Object?> get props => [personType, personId, date, status, reason];
}

/// Mark attendance for a single date
class MarkAttendanceUseCase
    implements UseCase<AttendanceRecord, MarkAttendanceParams> {
  final AttendanceRepository repository;

  MarkAttendanceUseCase(this.repository);

  @override
  Future<Either<Failure, AttendanceRecord>> call(
    MarkAttendanceParams params,
  ) async {
    // Business validation
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(
      params.date.year,
      params.date.month,
      params.date.day,
    );

    // Cannot mark attendance for past dates
    if (targetDate.isBefore(today)) {
      return const Left(
        ValidationFailure(message: "Cannot mark attendance for past dates"),
      );
    }

    // Check if date is Saturday
    if (params.date.weekday == DateTime.saturday) {
      return const Left(
        ValidationFailure(message: "Cannot mark attendance on Saturdays"),
      );
    }

    return await repository.markAttendance(
      personType: params.personType,
      personId: params.personId,
      date: params.date,
      status: params.status,
      reason: params.reason,
    );
  }
}
