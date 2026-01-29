import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/super_admin/domain/repositories/ministry_repository.dart';

/// Use case to create a new ministry (Super Admin only)
class CreateMinistryUseCase implements UseCase<Ministry, CreateMinistryParams> {
  final MinistryRepository repository;

  CreateMinistryUseCase(this.repository);

  @override
  Future<Either<Failure, Ministry>> call(CreateMinistryParams params) async {
    return await repository.createMinistry(
      placeId: params.placeId,
      name: params.name,
      email: params.email,
      password: params.password,
      description: params.description,
      phone: params.phone,
      address: params.address,
      website: params.website,
      logoBytes: params.logoBytes,
      logoFileName: params.logoFileName,
    );
  }
}

class CreateMinistryParams extends Equatable {
  final String placeId; // Required - ministry must belong to a place
  final String name;
  final String email;
  final String password;
  final String? description;
  final String? phone;
  final String? address;
  final String? website;
  final Uint8List? logoBytes;
  final String? logoFileName;

  const CreateMinistryParams({
    required this.placeId,
    required this.name,
    required this.email,
    required this.password,
    this.description,
    this.phone,
    this.address,
    this.website,
    this.logoBytes,
    this.logoFileName,
  });

  @override
  List<Object?> get props => [
    placeId,
    name,
    email,
    password,
    description,
    phone,
    address,
    website,
    logoBytes,
    logoFileName,
  ];
}
