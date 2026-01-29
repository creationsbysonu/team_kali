import 'package:equatable/equatable.dart';
import 'place_entity.dart';

/// Represents a citizen profile entity in the domain layer.
class ProfileEntity extends Equatable {
  final String id;
  final String userEmail;
  final String fullName;
  final String placeId;
  final PlaceEntity? placeDetails;
  final bool isProfileComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileEntity({
    required this.id,
    required this.userEmail,
    required this.fullName,
    required this.placeId,
    this.placeDetails,
    required this.isProfileComplete,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userEmail,
    fullName,
    placeId,
    placeDetails,
    isProfileComplete,
    createdAt,
    updatedAt,
  ];

  /// Create a copy with updated fields
  ProfileEntity copyWith({
    String? id,
    String? userEmail,
    String? fullName,
    String? placeId,
    PlaceEntity? placeDetails,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileEntity(
      id: id ?? this.id,
      userEmail: userEmail ?? this.userEmail,
      fullName: fullName ?? this.fullName,
      placeId: placeId ?? this.placeId,
      placeDetails: placeDetails ?? this.placeDetails,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'ProfileEntity(id: $id, email: $userEmail, name: $fullName, place: ${placeDetails?.name})';
}
