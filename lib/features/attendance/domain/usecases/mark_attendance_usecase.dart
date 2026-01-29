import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_record.dart';
import 'package:sewa_web/features/attendance/domain/repositories/attendance_repository.dart';

class MarkAttendanceParams {
  final String personType;
  final String personId;
  final DateTime date;
  final String status;
  final String? reason;

  const MarkAttendanceParams({
    required this.personType,
    required this.personId,
    required this.date,
    required this.status,
    this.reason,
  });
}

class MarkAttendanceUseCase
    implements UseCase<AttendanceRecord, MarkAttendanceParams> {
  final AttendanceRepository repository;

  MarkAttendanceUseCase(this.repository);

  @override
  Future<Either<Failure, AttendanceRecord>> call(
    MarkAttendanceParams params,
  ) async {
    if (params.personId.isEmpty) {
      return const Left(ValidationFailure(message: 'Person ID is required'));
    }

    if (params.status.toUpperCase() != 'PRESENT' &&
        params.status.toUpperCase() != 'ABSENT') {
      return const Left(
        ValidationFailure(message: 'Invalid attendance status'),
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
