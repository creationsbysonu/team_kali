import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/super_admin/domain/repositories/ministry_repository.dart';

/// Use case to update ministry details (Super Admin only)
class UpdateMinistryUseCase implements UseCase<Ministry, UpdateMinistryParams> {
  final MinistryRepository repository;

  UpdateMinistryUseCase(this.repository);

  @override
  Future<Either<Failure, Ministry>> call(UpdateMinistryParams params) async {
    return await repository.updateMinistry(
      id: params.id,
      name: params.name,
      description: params.description,
      email: params.email,
      phone: params.phone,
      address: params.address,
      website: params.website,
      logoBytes: params.logoBytes,
      logoFileName: params.logoFileName,
    );
  }
}

class UpdateMinistryParams extends Equatable {
  final String id;
  final String? name;
  final String? description;
  final String? email;
  final String? phone;
  final String? address;
  final String? website;
  final Uint8List? logoBytes;
  final String? logoFileName;

  const UpdateMinistryParams({
    required this.id,
    this.name,
    this.description,
    this.email,
    this.phone,
    this.address,
    this.website,
    this.logoBytes,
    this.logoFileName,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    email,
    phone,
    address,
    website,
    logoBytes,
    logoFileName,
  ];
}
