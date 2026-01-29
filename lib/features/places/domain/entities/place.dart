import 'package:equatable/equatable.dart';

/// Place Entity - Top level in hierarchy
/// Represents a geographical location (e.g., Kathmandu, Pokhara)
class Place extends Equatable {
  final String id;
  final String name;
  final String slug;
  final bool isActive;

  const Place({
    required this.id,
    required this.name,
    required this.slug,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, slug, isActive];

  Place copyWith({String? id, String? name, String? slug, bool? isActive}) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() => 'Place(id: $id, name: $name, slug: $slug)';
}
