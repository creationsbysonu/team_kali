import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/ministry/domain/entities/staff_service_entity.dart';
import 'package:sewa_web/features/ministry/domain/repositories/staff_service_repository.dart';

/// Use case to create a new staff service
class CreateStaffServiceUseCase
    implements UseCase<StaffService, CreateStaffServiceParams> {
  final StaffServiceRepository repository;

  CreateStaffServiceUseCase(this.repository);

  @override
  Future<Either<Failure, StaffService>> call(
    CreateStaffServiceParams params,
  ) async {
    // Validation
    if (params.serviceName.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Service name cannot be empty'),
      );
    }

    if (params.staffName.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Staff name cannot be empty'),
      );
    }

    if (params.email.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Email cannot be empty'));
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(params.email.trim())) {
      return const Left(ValidationFailure(message: 'Invalid email format'));
    }

    if (params.password.isEmpty) {
      return const Left(ValidationFailure(message: 'Password cannot be empty'));
    }

    if (params.password.length < 6) {
      return const Left(
        ValidationFailure(message: 'Password must be at least 6 characters'),
      );
    }

    return repository.createStaffService(
      serviceName: params.serviceName.trim(),
      staffName: params.staffName.trim(),
      email: params.email.trim(),
      password: params.password,
      serviceLogoBytes: params.serviceLogoBytes,
      serviceLogoFileName: params.serviceLogoFileName,
      staffImageBytes: params.staffImageBytes,
      staffImageFileName: params.staffImageFileName,
    );
  }
}

class CreateStaffServiceParams extends Equatable {
  final String serviceName;
  final String staffName;
  final String email;
  final String password;
  final Uint8List? serviceLogoBytes;
  final String? serviceLogoFileName;
  final Uint8List? staffImageBytes;
  final String? staffImageFileName;

  const CreateStaffServiceParams({
    required this.serviceName,
    required this.staffName,
    required this.email,
    required this.password,
    this.serviceLogoBytes,
    this.serviceLogoFileName,
    this.staffImageBytes,
    this.staffImageFileName,
  });

  @override
  List<Object?> get props => [
    serviceName,
    staffName,
    email,
    password,
    serviceLogoBytes,
    serviceLogoFileName,
    staffImageBytes,
    staffImageFileName,
  ];
}
