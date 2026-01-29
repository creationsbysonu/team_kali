import 'package:equatable/equatable.dart';

/// Represents a source/reference entity for chat responses.
/// Contains notice metadata for deep linking to notice details.
class SourceEntity extends Equatable {
  /// UUID of the referenced notice
  final String noticeId;

  /// Name of the ministry that issued the notice
  final String? ministryName;

  /// Name of the related service (optional)
  final String? serviceName;

  /// Relevant text snippet from the notice
  final String? excerpt;

  const SourceEntity({
    required this.noticeId,
    this.ministryName,
    this.serviceName,
    this.excerpt,
  });

  /// Display name for the source chip
  String get displayName => serviceName ?? ministryName ?? 'View Notice';

  @override
  List<Object?> get props => [noticeId, ministryName, serviceName, excerpt];

  @override
  String toString() =>
      'SourceEntity(noticeId: $noticeId, ministry: $ministryName, service: $serviceName)';
}
