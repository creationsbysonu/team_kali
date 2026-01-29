import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_record.dart';
import 'package:sewa_web/features/attendance/domain/repositories/attendance_repository.dart';

class BulkMarkAttendanceParams {
  final List<Map<String, dynamic>> attendanceData;

  const BulkMarkAttendanceParams({required this.attendanceData});
}

class BulkMarkAttendanceUseCase
    implements UseCase<List<AttendanceRecord>, BulkMarkAttendanceParams> {
  final AttendanceRepository repository;

  BulkMarkAttendanceUseCase(this.repository);

  @override
  Future<Either<Failure, List<AttendanceRecord>>> call(
    BulkMarkAttendanceParams params,
  ) async {
    if (params.attendanceData.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Attendance data cannot be empty'),
      );
    }

    return await repository.bulkMarkAttendance(
      attendanceData: params.attendanceData,
    );
  }
}
