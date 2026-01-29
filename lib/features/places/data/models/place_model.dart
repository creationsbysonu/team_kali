import 'package:sewa_web/features/places/domain/entities/place.dart';

/// Place Model - Data layer representation
class PlaceModel extends Place {
  const PlaceModel({
    required super.id,
    required super.name,
    required super.slug,
    super.isActive,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      slug: json['slug'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug, 'is_active': isActive};
  }

  factory PlaceModel.fromEntity(Place entity) {
    return PlaceModel(
      id: entity.id,
      name: entity.name,
      slug: entity.slug,
      isActive: entity.isActive,
    );
  }
}
