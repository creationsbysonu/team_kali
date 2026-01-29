import 'package:sewa_sathi/features/get_token/domain/entities/staff_service_entity.dart';

/// Staff Service model with JSON serialization.
/// Follows Citizen API v1 ServiceListItem structure.
class StaffServiceModel extends StaffServiceEntity {
  const StaffServiceModel({
    required super.id,
    required super.serviceName,
    super.serviceLogoUrl,
    required super.staffName,
    super.staffImageUrl,
    required super.isAvailableToday,
    super.availabilityReason,
    super.availabilityCode,
    super.tokensAvailable,
    super.currentQueuePosition,
  });

  /// Create from JSON response following Citizen API v1 format.
  ///
  /// Expected JSON structure:
  /// ```json
  /// {
  ///   "id": "7e9ef9ca-932e-4843-87f6-566c740ba4e2",
  ///   "service_name": "Citizenship Certificate",
  ///   "service_logo_url": "https://...",
  ///   "staff_name": "Ram Bahadur",
  ///   "staff_image_url": "https://...",
  ///   "is_available_today": true,
  ///   "availability_reason": null,
  ///   "availability_code": "AVAILABLE",
  ///   "tokens_available": 15,
  ///   "current_queue_position": 3
  /// }
  /// ```
  factory StaffServiceModel.fromJson(Map<String, dynamic> json) {
    return StaffServiceModel(
      id: json['id']?.toString() ?? '',
      serviceName: json['service_name'] ?? '',
      serviceLogoUrl: json['service_logo_url'],
      staffName: json['staff_name'] ?? '',
      staffImageUrl: json['staff_image_url'],
      isAvailableToday: json['is_available_today'] ?? false,
      availabilityReason: json['availability_reason'],
      availabilityCode: json['availability_code'],
      tokensAvailable: json['tokens_available'] ?? 0,
      currentQueuePosition: json['current_queue_position'],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_name': serviceName,
      'service_logo_url': serviceLogoUrl,
      'staff_name': staffName,
      'staff_image_url': staffImageUrl,
      'is_available_today': isAvailableToday,
      'availability_reason': availabilityReason,
      'availability_code': availabilityCode,
      'tokens_available': tokensAvailable,
      'current_queue_position': currentQueuePosition,
    };
  }

  /// Create from entity.
  factory StaffServiceModel.fromEntity(StaffServiceEntity entity) {
    return StaffServiceModel(
      id: entity.id,
      serviceName: entity.serviceName,
      serviceLogoUrl: entity.serviceLogoUrl,
      staffName: entity.staffName,
      staffImageUrl: entity.staffImageUrl,
      isAvailableToday: entity.isAvailableToday,
      availabilityReason: entity.availabilityReason,
      availabilityCode: entity.availabilityCode,
      tokensAvailable: entity.tokensAvailable,
      currentQueuePosition: entity.currentQueuePosition,
    );
  }
}
