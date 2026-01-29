import 'package:equatable/equatable.dart';
import 'package:sewa_sathi/features/notice/domain/entities/ministry_entity.dart';
import 'package:sewa_sathi/features/notice/domain/entities/service_entity.dart';

/// Entity containing all filter options.
class FilterOptionsEntity extends Equatable {
  final List<MinistryEntity> ministries;
  final List<ServiceEntity> services;
  final List<String> fileTypes;

  const FilterOptionsEntity({
    required this.ministries,
    required this.services,
    required this.fileTypes,
  });

  @override
  List<Object?> get props => [ministries, services, fileTypes];
}
