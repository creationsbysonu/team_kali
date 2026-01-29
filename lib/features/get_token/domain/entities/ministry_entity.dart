import 'package:equatable/equatable.dart';

/// Ministry entity representing a government ministry.
class MinistryEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? address;
  final String? phone;
  final int servicesCount;

  const MinistryEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.address,
    this.phone,
    this.servicesCount = 0,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    description,
    logoUrl,
    address,
    phone,
    servicesCount,
  ];

  /// Check if ministry has a logo.
  bool get hasLogo => logoUrl != null && logoUrl!.isNotEmpty;

  /// Check if ministry has contact info.
  bool get hasContact => phone != null && phone!.isNotEmpty;
}
