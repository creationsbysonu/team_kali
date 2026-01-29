import 'package:sewa_sathi/features/profile/data/models/place_model.dart';
import 'package:sewa_sathi/features/profile/domain/entities/profile_entity.dart';

/// Model class for Profile with JSON serialization.
class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.userEmail,
    required super.fullName,
    required super.placeId,
    super.placeDetails,
    required super.isProfileComplete,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create a ProfileModel from JSON.
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'].toString(),
      userEmail: json['user_email'] as String,
      fullName: json['full_name'] as String,
      placeId: json['place'].toString(),
      placeDetails: json['place_details'] != null
          ? PlaceModel.fromJson(json['place_details'] as Map<String, dynamic>)
          : null,
      isProfileComplete: json['is_profile_complete'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert ProfileModel to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_email': userEmail,
      'full_name': fullName,
      'place': placeId,
      'place_details': placeDetails != null
          ? PlaceModel.fromEntity(placeDetails!).toJson()
          : null,
      'is_profile_complete': isProfileComplete,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create ProfileModel from entity.
  factory ProfileModel.fromEntity(ProfileEntity entity) {
    return ProfileModel(
      id: entity.id,
      userEmail: entity.userEmail,
      fullName: entity.fullName,
      placeId: entity.placeId,
      placeDetails: entity.placeDetails,
      isProfileComplete: entity.isProfileComplete,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
