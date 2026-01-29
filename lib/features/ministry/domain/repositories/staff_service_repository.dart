import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/features/ministry/domain/entities/staff_service_entity.dart';

/// Repository interface for StaffService operations
abstract class StaffServiceRepository {
  /// Fetch all staff-services
  Future<Either<Failure, List<StaffService>>> getStaffServices();

  /// Get staff-service by ID
  Future<Either<Failure, StaffService>> getStaffServiceById(String id);

  /// Create a new staff-service
  Future<Either<Failure, StaffService>> createStaffService({
    required String serviceName,
    required String staffName,
    required String email,
    required String password,
    Uint8List? serviceLogoBytes,
    String? serviceLogoFileName,
    Uint8List? staffImageBytes,
    String? staffImageFileName,
  });

  /// Update staff-service
  Future<Either<Failure, StaffService>> updateStaffService({
    required String id,
    String? serviceName,
    String? staffName,
    Uint8List? serviceLogoBytes,
    String? serviceLogoFileName,
    Uint8List? staffImageBytes,
    String? staffImageFileName,
  });

  /// Delete staff-service
  Future<Either<Failure, void>> deleteStaffService(String id);

  /// Reset staff password
  Future<Either<Failure, void>> resetStaffPassword(
    String id,
    String newPassword,
  );

  /// Toggle staff-service status
  Future<Either<Failure, StaffService>> toggleStaffServiceStatus(String id);
}
