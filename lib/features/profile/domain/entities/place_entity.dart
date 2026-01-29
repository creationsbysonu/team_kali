import 'package:equatable/equatable.dart';

/// Represents a place/location entity in the domain layer.
class PlaceEntity extends Equatable {
  final String id;
  final String name;
  final String slug;

  const PlaceEntity({required this.id, required this.name, required this.slug});

  @override
  List<Object?> get props => [id, name, slug];

  @override
  String toString() => 'PlaceEntity(id: $id, name: $name, slug: $slug)';
}
