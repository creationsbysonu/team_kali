import 'package:equatable/equatable.dart';
import 'package:sewa_sathi/features/notice/domain/entities/ministry_entity.dart';
import 'package:sewa_sathi/features/notice/domain/entities/service_entity.dart';

/// Entity representing detailed notice information.
class NoticeDetailEntity extends Equatable {
  final String id;
  final String title;
  final MinistryEntity? ministry;
  final ServiceEntity? service;
  final String fileUrl;
  final String fileType;
  final String? ingestionStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoticeDetailEntity({
    required this.id,
    required this.title,
    this.ministry,
    this.service,
    required this.fileUrl,
    required this.fileType,
    this.ingestionStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    ministry,
    service,
    fileUrl,
    fileType,
    ingestionStatus,
    createdAt,
    updatedAt,
  ];
}
