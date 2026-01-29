import 'package:sewa_web/features/super_admin/domain/entities/place_filter_option.dart';

/// Place Filter Option Model (Data Layer)
/// Extends the domain entity and adds JSON serialization
class PlaceFilterOptionModel extends PlaceFilterOption {
  const PlaceFilterOptionModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.ministryCount,
  });

  /// Create model from JSON response
  /// Expected JSON structure from GET /ministry/admin/places/:
  /// {
  ///   "id": "uuid",
  ///   "name": "Kathmandu",
  ///   "slug": "kathmandu",
  ///   "ministry_count": 5
  /// }
  factory PlaceFilterOptionModel.fromJson(Map<String, dynamic> json) {
    return PlaceFilterOptionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      ministryCount: json['ministry_count'] as int,
    );
  }

  /// Convert model to JSON (for potential future use)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'ministry_count': ministryCount,
    };
  }

  /// Create model from entity
  factory PlaceFilterOptionModel.fromEntity(PlaceFilterOption entity) {
    return PlaceFilterOptionModel(
      id: entity.id,
      name: entity.name,
      slug: entity.slug,
      ministryCount: entity.ministryCount,
    );
  }
}
