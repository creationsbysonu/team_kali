import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_calendar_data.dart';
import 'package:sewa_web/features/attendance/domain/repositories/attendance_repository.dart';

class GetAttendanceCalendarParams {
  final String personType;
  final String personId;
  final DateTime startDate;
  final DateTime endDate;

  const GetAttendanceCalendarParams({
    required this.personType,
    required this.personId,
    required this.startDate,
    required this.endDate,
  });
}

class GetAttendanceCalendarUseCase
    implements UseCase<AttendanceCalendarData, GetAttendanceCalendarParams> {
  final AttendanceRepository repository;

  GetAttendanceCalendarUseCase(this.repository);

  @override
  Future<Either<Failure, AttendanceCalendarData>> call(
    GetAttendanceCalendarParams params,
  ) async {
    if (params.personId.isEmpty) {
      return const Left(ValidationFailure(message: 'Person ID is required'));
    }

    if (params.startDate.isAfter(params.endDate)) {
      return const Left(
        ValidationFailure(message: 'Start date must be before end date'),
      );
    }

    return await repository.getAttendanceCalendar(
      personType: params.personType,
      personId: params.personId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}
