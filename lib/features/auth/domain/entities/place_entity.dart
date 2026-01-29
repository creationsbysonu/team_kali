import 'package:equatable/equatable.dart';

/// Place Entity - Top level in hierarchy
/// Represents a geographical location (e.g., Kathmandu, Pokhara)
class PlaceEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final bool isActive;

  const PlaceEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, slug, isActive];

  PlaceEntity copyWith({
    String? id,
    String? name,
    String? slug,
    bool? isActive,
  }) {
    return PlaceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      isActive: isActive ?? this.isActive,
    );
  }
}
