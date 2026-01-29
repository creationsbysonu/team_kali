import 'package:equatable/equatable.dart';

/// Place Filter Option Entity (Domain Layer)
/// Represents a place option for filtering ministries in dropdown
class PlaceFilterOption extends Equatable {
  final String id;
  final String name;
  final String slug;
  final int ministryCount;

  const PlaceFilterOption({
    required this.id,
    required this.name,
    required this.slug,
    required this.ministryCount,
  });

  /// Display text for dropdown: "Place Name (count)"
  String get displayText => '$name ($ministryCount)';

  @override
  List<Object?> get props => [id, name, slug, ministryCount];

  @override
  String toString() =>
      'PlaceFilterOption(id: $id, name: $name, slug: $slug, ministryCount: $ministryCount)';
}
