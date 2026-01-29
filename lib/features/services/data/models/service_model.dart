import 'package:sewa_web/features/services/domain/entities/service.dart';

/// Service Model - matches backend spec exactly
class ServiceModel extends Service {
  const ServiceModel({
    required super.id,
    required super.name,
    required super.slug,
    super.shortDescription,
    super.description,
    super.serviceType,
    super.processingTime,
    required super.feeAmount,
    super.feeDescription,
    super.isActive,
    super.isPublished,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      shortDescription: json['short_description'] as String?,
      description: json['description'] as String?,
      serviceType: ServiceType.fromString(json['service_type'] ?? 'offline'),
      processingTime: ProcessingTime.fromString(json['processing_time']),
      feeAmount: json['fee_amount']?.toString() ?? '0',
      feeDescription: json['fee_description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isPublished: json['is_published'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'short_description': shortDescription,
      'description': description,
      'service_type': serviceType.value,
      'processing_time': processingTime.value,
      'fee_amount': feeAmount,
      'fee_description': feeDescription,
      'is_active': isActive,
      'is_published': isPublished,
    };
  }

  factory ServiceModel.fromEntity(Service entity) {
    return ServiceModel(
      id: entity.id,
      name: entity.name,
      slug: entity.slug,
      shortDescription: entity.shortDescription,
      description: entity.description,
      serviceType: entity.serviceType,
      processingTime: entity.processingTime,
      feeAmount: entity.feeAmount,
      feeDescription: entity.feeDescription,
      isActive: entity.isActive,
      isPublished: entity.isPublished,
    );
  }
}
