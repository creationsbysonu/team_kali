import 'package:equatable/equatable.dart';

/// Staff Entity - matches backend spec exactly
/// Fields:
/// - id (UUID) ✅ required
/// - name (String) ✅ required
/// - email (String) ✅ required - Read-only (from user)
/// - contact (String) ✅ required
/// - image_url (String) ❌ optional - Full Cloudinary URL, nullable
/// - service (UUID) ✅ required - Service ID
/// - service_name (String) ✅ required - Read-only
/// - ministry_name (String) ✅ required - Read-only
/// - is_active (bool) ✅ required
/// - created_at (String) ✅ required
/// - updated_at (String) ✅ required
class StaffMember extends Equatable {
  final String id;
  final String name;
  final String email;
  final String contact;
  final String? imageUrl;
  final String service; // Service ID (UUID)
  final String serviceName;
  final String ministryName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.contact,
    this.imageUrl,
    required this.service,
    required this.serviceName,
    required this.ministryName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    contact,
    imageUrl,
    service,
    serviceName,
    ministryName,
    isActive,
    createdAt,
    updatedAt,
  ];

  StaffMember copyWith({
    String? id,
    String? name,
    String? email,
    String? contact,
    String? imageUrl,
    String? service,
    String? serviceName,
    String? ministryName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      contact: contact ?? this.contact,
      imageUrl: imageUrl ?? this.imageUrl,
      service: service ?? this.service,
      serviceName: serviceName ?? this.serviceName,
      ministryName: ministryName ?? this.ministryName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'StaffMember(id: $id, name: $name, email: $email)';
}
