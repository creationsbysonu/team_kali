import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/features/staff/domain/entities/staff_member.dart';

/// Abstract repository for Staff operations
abstract class StaffRepository {
  /// Get all staff in ministry (ministry admin)
  Future<Either<Failure, List<StaffMember>>> getMinistryStaff();

  /// Get staff by ID
  Future<Either<Failure, StaffMember>> getStaffById(String id);

  /// Create new staff member
  Future<Either<Failure, StaffMember>> createStaff({
    required String name,
    required String email,
    required String password,
    required String serviceId,
    String? contact,
    String? imagePath,
  });

  /// Update staff member
  Future<Either<Failure, StaffMember>> updateStaff({
    required String id,
    String? name,
    String? contact,
    String? password,
    bool? isActive,
  });

  /// Delete staff member
  Future<Either<Failure, void>> deleteStaff(String id);

  /// Reset staff password
  Future<Either<Failure, void>> resetStaffPassword({
    required String staffId,
    required String newPassword,
  });
}
