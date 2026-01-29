import 'package:equatable/equatable.dart';

/// Service types - matches backend spec
enum ServiceType {
  online('online'),
  offline('offline'),
  hybrid('hybrid');

  final String value;
  const ServiceType(this.value);

  static ServiceType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'online':
        return ServiceType.online;
      case 'offline':
        return ServiceType.offline;
      case 'hybrid':
        return ServiceType.hybrid;
      default:
        return ServiceType.offline;
    }
  }
}

/// Processing time options - matches backend spec
enum ProcessingTime {
  instant('instant'),
  sameDay('same_day'),
  oneToThreeDays('1_3_days'),
  oneWeek('1_week'),
  twoWeeks('2_weeks'),
  oneMonth('1_month'),
  variable('variable');

  final String value;
  const ProcessingTime(this.value);

  static ProcessingTime fromString(String? value) {
    if (value == null) return ProcessingTime.variable;
    switch (value.toLowerCase()) {
      case 'instant':
        return ProcessingTime.instant;
      case 'same_day':
        return ProcessingTime.sameDay;
      case '1_3_days':
        return ProcessingTime.oneToThreeDays;
      case '1_week':
        return ProcessingTime.oneWeek;
      case '2_weeks':
        return ProcessingTime.twoWeeks;
      case '1_month':
        return ProcessingTime.oneMonth;
      default:
        return ProcessingTime.variable;
    }
  }

  String get displayName {
    switch (this) {
      case ProcessingTime.instant:
        return 'Instant';
      case ProcessingTime.sameDay:
        return 'Same Day';
      case ProcessingTime.oneToThreeDays:
        return '1-3 Days';
      case ProcessingTime.oneWeek:
        return '1 Week';
      case ProcessingTime.twoWeeks:
        return '2 Weeks';
      case ProcessingTime.oneMonth:
        return '1 Month';
      case ProcessingTime.variable:
        return 'Variable';
    }
  }
}

/// Service Entity - Matches backend spec exactly
/// Fields from backend:
/// - id (UUID)
/// - name (String)
/// - slug (String)
/// - short_description (String, optional)
/// - description (String, optional)
/// - service_type (online/offline/hybrid)
/// - processing_time (instant/same_day/1_3_days/1_week/2_weeks/1_month/variable)
/// - fee_amount (Decimal as String)
/// - fee_description (String, optional)
/// - is_active (bool)
/// - is_published (bool)
class Service extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? shortDescription;
  final String? description;
  final ServiceType serviceType;
  final ProcessingTime processingTime;
  final String feeAmount; // Decimal as String per backend spec
  final String? feeDescription;
  final bool isActive;
  final bool isPublished;

  const Service({
    required this.id,
    required this.name,
    required this.slug,
    this.shortDescription,
    this.description,
    this.serviceType = ServiceType.offline,
    this.processingTime = ProcessingTime.variable,
    required this.feeAmount,
    this.feeDescription,
    this.isActive = true,
    this.isPublished = false,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    shortDescription,
    description,
    serviceType,
    processingTime,
    feeAmount,
    feeDescription,
    isActive,
    isPublished,
  ];

  Service copyWith({
    String? id,
    String? name,
    String? slug,
    String? shortDescription,
    String? description,
    ServiceType? serviceType,
    ProcessingTime? processingTime,
    String? feeAmount,
    String? feeDescription,
    bool? isActive,
    bool? isPublished,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      serviceType: serviceType ?? this.serviceType,
      processingTime: processingTime ?? this.processingTime,
      feeAmount: feeAmount ?? this.feeAmount,
      feeDescription: feeDescription ?? this.feeDescription,
      isActive: isActive ?? this.isActive,
      isPublished: isPublished ?? this.isPublished,
    );
  }

  @override
  String toString() => 'Service(id: $id, name: $name, slug: $slug)';
}
