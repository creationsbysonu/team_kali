import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/super_admin/domain/repositories/ministry_repository.dart';

/// Use case to update current ministry's own profile
/// For ministry staff users to update their ministry details
/// Note: Limited fields can be updated (description, phone, address, website, logo)
class UpdateMyMinistryUseCase
    implements UseCase<Ministry, UpdateMyMinistryParams> {
  final MinistryRepository repository;

  UpdateMyMinistryUseCase(this.repository);

  @override
  Future<Either<Failure, Ministry>> call(UpdateMyMinistryParams params) async {
    return await repository.updateMyMinistry(
      description: params.description,
      phone: params.phone,
      address: params.address,
      website: params.website,
      logoBytes: params.logoBytes,
      logoFileName: params.logoFileName,
    );
  }
}

class UpdateMyMinistryParams extends Equatable {
  final String? description;
  final String? phone;
  final String? address;
  final String? website;
  final Uint8List? logoBytes;
  final String? logoFileName;

  const UpdateMyMinistryParams({
    this.description,
    this.phone,
    this.address,
    this.website,
    this.logoBytes,
    this.logoFileName,
  });

  @override
  List<Object?> get props => [
    description,
    phone,
    address,
    website,
    logoBytes,
    logoFileName,
  ];
}
