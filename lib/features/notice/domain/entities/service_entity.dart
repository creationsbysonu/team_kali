import 'package:equatable/equatable.dart';
import 'package:sewa_sathi/features/notice/domain/entities/ministry_entity.dart';

/// Entity representing a service.
class ServiceEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? shortDescription;
  final MinistryEntity? ministry;
  final String? ministryId;
  final int? noticeCount;

  const ServiceEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.shortDescription,
    this.ministry,
    this.ministryId,
    this.noticeCount,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    shortDescription,
    ministry,
    ministryId,
    noticeCount,
  ];
}
