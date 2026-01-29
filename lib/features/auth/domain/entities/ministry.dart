import 'package:equatable/equatable.dart';

/// Ministry Entity - matches backend spec exactly
/// Fields:
/// - id (UUID) ✅ required
/// - place (String) ✅ required - UUID of the place this ministry belongs to
/// - place_id (String) ✅ required - Same as place (for convenience)
/// - place_name (String) ✅ required - Display name of the place
/// - place_slug (String) ✅ required - URL slug of the place
/// - name (String) ✅ required
/// - slug (String) ✅ required - Use for login
/// - description (String) ❌ optional
/// - email (String) ✅ required
/// - phone (String) ❌ optional
/// - address (String) ❌ optional
/// - website (String) ❌ optional
/// - logo_url (String) ❌ optional - Full Cloudinary URL, nullable
/// - status (String) ✅ required - active, suspended, pending
/// - member_count (int) ❌ optional
/// - created_at (String) ✅ required
/// - updated_at (String) ✅ required
class Ministry extends Equatable {
  final String id;
  final String? placeId;
  final String? placeName;
  final String? placeSlug;
  final String name;
  final String slug;
  final String? description;
  final String email;
  final String? phone;
  final String? address;
  final String? website;
  final String? logoUrl;
  final String status;
  final int memberCount;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Ministry({
    required this.id,
    this.placeId,
    this.placeName,
    this.placeSlug,
    required this.name,
    required this.slug,
    this.description,
    String? email,
    this.phone,
    this.address,
    this.website,
    this.logoUrl,
    String? status,
    this.memberCount = 0,
    this.isDeleted = false,
    this.deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : email = email ?? '',
       status = status ?? 'active',
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  @override
  List<Object?> get props => [
    id,
    placeId,
    placeName,
    placeSlug,
    name,
    slug,
    description,
    email,
    phone,
    address,
    website,
    logoUrl,
    status,
    memberCount,
    isDeleted,
    deletedAt,
    createdAt,
    updatedAt,
  ];

  /// Check if ministry is active
  bool get isActive => status == 'active';

  /// Check if ministry is suspended
  bool get isSuspended => status == 'suspended';

  /// Check if ministry is pending
  bool get isPending => status == 'pending';

  /// Check if ministry has logo
  bool get hasLogo => logoUrl != null && logoUrl!.isNotEmpty;

  /// Check if ministry is linked to a place
  bool get hasPlace => placeId != null && placeId!.isNotEmpty;

  Ministry copyWith({
    String? id,
    String? placeId,
    String? placeName,
    String? placeSlug,
    String? name,
    String? slug,
    String? description,
    String? email,
    String? phone,
    String? address,
    String? website,
    String? logoUrl,
    String? status,
    int? memberCount,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ministry(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      placeSlug: placeSlug ?? this.placeSlug,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      status: status ?? this.status,
      memberCount: memberCount ?? this.memberCount,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Ministry(id: $id, name: $name, place: $placeName)';
}
