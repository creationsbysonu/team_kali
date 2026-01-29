import 'package:equatable/equatable.dart';

/// Entity representing a notice in list view.
class NoticeEntity extends Equatable {
  final String id;
  final String title;
  final String? ministry;
  final String? ministryName;
  final String? ministrySlug;
  final String? service;
  final String? serviceName;
  final String? serviceSlug;
  final String fileUrl;
  final String fileType;
  final DateTime createdAt;

  const NoticeEntity({
    required this.id,
    required this.title,
    this.ministry,
    this.ministryName,
    this.ministrySlug,
    this.service,
    this.serviceName,
    this.serviceSlug,
    required this.fileUrl,
    required this.fileType,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    ministry,
    ministryName,
    ministrySlug,
    service,
    serviceName,
    serviceSlug,
    fileUrl,
    fileType,
    createdAt,
  ];
}
