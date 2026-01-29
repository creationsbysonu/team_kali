import 'package:equatable/equatable.dart';

/// Entity representing a ministry.
class MinistryEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final int? noticeCount;

  const MinistryEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.noticeCount,
  });

  @override
  List<Object?> get props => [id, name, slug, logoUrl, noticeCount];
}
