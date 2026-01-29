import 'package:equatable/equatable.dart';

/// StaffService Entity for Ministry Admin Management
/// Represents a service with its assigned staff member
/// Backend endpoint: /ministry/management/staff-services/
class StaffService extends Equatable {
  final String id;
  final String serviceName;
  final String? serviceLogo; // Cloudinary URL
  final String staffName;
  final String? staffImage; // Cloudinary URL
  final String email;
  final String status; // 'active' or 'paused'
  final DateTime createdAt;
  final DateTime updatedAt;

  const StaffService({
    required this.id,
    required this.serviceName,
    this.serviceLogo,
    required this.staffName,
    this.staffImage,
    required this.email,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if service is active
  bool get isActive => status.toLowerCase() == 'active';

  /// Check if service is paused
  bool get isPaused => status.toLowerCase() == 'paused';

  /// Check if service has logo
  bool get hasLogo => serviceLogo != null && serviceLogo!.isNotEmpty;

  /// Check if staff has image
  bool get hasStaffImage => staffImage != null && staffImage!.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    serviceName,
    serviceLogo,
    staffName,
    staffImage,
    email,
    status,
    createdAt,
    updatedAt,
  ];

  StaffService copyWith({
    String? id,
    String? serviceName,
    String? serviceLogo,
    String? staffName,
    String? staffImage,
    String? email,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffService(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      serviceLogo: serviceLogo ?? this.serviceLogo,
      staffName: staffName ?? this.staffName,
      staffImage: staffImage ?? this.staffImage,
      email: email ?? this.email,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'StaffService(id: $id, serviceName: $serviceName, staffName: $staffName, email: $email, status: $status)';
  }
}
