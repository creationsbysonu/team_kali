import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/ministry/domain/entities/staff_service_entity.dart';
import 'package:sewa_web/features/ministry/domain/repositories/staff_service_repository.dart';

/// Use case to update an existing staff service
class UpdateStaffServiceUseCase
    implements UseCase<StaffService, UpdateStaffServiceParams> {
  final StaffServiceRepository repository;

  UpdateStaffServiceUseCase(this.repository);

  @override
  Future<Either<Failure, StaffService>> call(
    UpdateStaffServiceParams params,
  ) async {
    // Validation
    if (params.id.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Service ID cannot be empty'),
      );
    }

    if (params.serviceName != null && params.serviceName!.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Service name cannot be empty'),
      );
    }

    if (params.staffName != null && params.staffName!.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Staff name cannot be empty'),
      );
    }

    return repository.updateStaffService(
      id: params.id.trim(),
      serviceName: params.serviceName?.trim(),
      staffName: params.staffName?.trim(),
      serviceLogoBytes: params.serviceLogoBytes,
      serviceLogoFileName: params.serviceLogoFileName,
      staffImageBytes: params.staffImageBytes,
      staffImageFileName: params.staffImageFileName,
    );
  }
}

class UpdateStaffServiceParams extends Equatable {
  final String id;
  final String? serviceName;
  final String? staffName;
  final Uint8List? serviceLogoBytes;
  final String? serviceLogoFileName;
  final Uint8List? staffImageBytes;
  final String? staffImageFileName;

  const UpdateStaffServiceParams({
    required this.id,
    this.serviceName,
    this.staffName,
    this.serviceLogoBytes,
    this.serviceLogoFileName,
    this.staffImageBytes,
    this.staffImageFileName,
  });

  @override
  List<Object?> get props => [
    id,
    serviceName,
    staffName,
    serviceLogoBytes,
    serviceLogoFileName,
    staffImageBytes,
    staffImageFileName,
  ];
}
