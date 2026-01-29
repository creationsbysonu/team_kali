import 'package:sewa_sathi/features/profile/domain/entities/place_entity.dart';

/// Model class for Place with JSON serialization.
class PlaceModel extends PlaceEntity {
  const PlaceModel({
    required super.id,
    required super.name,
    required super.slug,
  });

  /// Create a PlaceModel from JSON.
  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }

  /// Convert PlaceModel to JSON.
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug};
  }

  /// Create PlaceModel from entity.
  factory PlaceModel.fromEntity(PlaceEntity entity) {
    return PlaceModel(id: entity.id, name: entity.name, slug: entity.slug);
  }
}
